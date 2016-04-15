---
tags: aix
category: platform
title: "Platform Notes: AIX"
---

Platform Notes: AIX
===================

Lots of good information on AIX and RS/6000/pSeries systems is at
[rootvg.net][1].  I've put together an IbmGlossary for all
the strange acronyms that IBM uses; it used to be here, but there's a lot of
overlap with ../ZseriesNotes.

[1]: http://www.rootvg.net

Questions (and Possibly Answers)
--------------------------------

 0. '''Q:''' Why are there a lot of extra routes in the routing table?

 '''A:''' This is an artifact of path MTU discovery.  Discovered path MTUs are
 stored in the routing table.  These routes are temporary and usually have
 flags of ''UGHW''.

Hints and Tips
--------------

Feel free to add to this list or fix mistakes.

### Finding the Size of a Physical Volume

You can determine the size of a physical volume without first importing it into
a volume group with the undocumented `bootinfo` command:

```
# bootinfo -s <disk>
```

This returns the size in megabytes.  It works for SCSI drives, VIO vSCSI
volumes, SAN LUNs, etc.

### LVM Commands

#### Determine which LVs are mirrored

```
lsvg -l <vgname>
```

Compare the counts of LPs to PPs.  A mirrored LV will have 2 times as many PPs
as LPs.

#### List logicial volumes in a volume group

```
lsvg -l <vgname>
```

### Find a system's serial number

```
lscfg -pv |grep Cabinet
```

### Info about ethernet devices

```
lscfg -vpl ent0
```

This shows MAC address, physical location, etc.

### ODM-Configured Static Routes

Routes tend to be added to the ODM when added through SMIT but the cannot be
likewise removed from the ODM with SMIT. To query the route entries in the ODM:

```
# lsattr -El inet0 -a route
```

Or:

```
$ odmget -q "name=inet0" CuAt

CuAt:
        name = "inet0"
        attribute = "hostname"
        value = "zeus.example.com"
        type = "R"
        generic = "DU"
        rep = "s"
        nls_index = 24

CuAt:
        name = "inet0"
        attribute = "route"
        value = "net,-hopcount,0,,0,192.168.10.1"
        type = "R"
        generic = "DU"
        rep = "s"
        nls_index = 0

CuAt:
        name = "inet0"
        attribute = "route"
        value = "net,-hopcount,0,-netmask,255.255.255.0,,,10.11.12.0,192.168.10.2"
        type = "R"
        generic = "DU"
        rep = "s"
        nls_index = 0
```

The entries with ''attribute = "route"'' are static routing table entries added
automatically at boot.  Routes can be deleted using the ''`chdev`'' command
or by manipulating the ODM directly.    Using ''`chdev`'':

```
# chdev -l inet0 -a delroute=net,-hopcount,0,-netmask,255.255.255.0,,,10.11.12.0,192.168.10.2
```

To delete an entry using the ODM, it must be identified by it's ''value'' seen
in the ''`odmget`'' command above:

```
# odmdelete -o CuAt -q "name=inet0 and value=net,-hopcount,0,-netmask,255.255.255.0,,,10.11.12.0,192.168.10.2"
```

### Upgrade firmware from floppy

(This might be incomplete or wrong.  I don't remember; it's been a long time since I did it.)

```
restore /dev/fd0
/usr/lpp/diagnostics/bin/update_flash -f
```

### Package Management

See PackageManagerCheatsheet


OS Update
---------

The "`oslevel`" command can be used to determine what filesets need to be
installed to bring a system to a given technology level or service pack.  This
information is from the ''bos.rte.install'' fileset, although I have never
actually find where it is listed; it may be in the binary itself.  The
'''`-g`''' option shows filesets '''newer''' than the requested level and
the '''`-l`''' shows filesets that are '''older'''.  To determine what is
needed to upgrade from one technology level to another, use the '''-r''' option
and the 6-digit technology level.  

For a service pack, use the '''`-s`''' and the 8-digit service pack level.

First, install the current ''bos.rte.install'' for the level you want to
upgrade to.  If your system is behind at the technology level, use "`oslevel
-rl 5300-0X`" to show you what updates are required.  Similarly, if your
system requires service pack updates, use "`oslevel -sl 5300-0X-0Y`".

Here's an example from one of my recent upgrades, going from 5300-05-04 to
5300-05-05.  First, check the current service pack level:

```
$ oslevel -s
5300-05-04
```

Then check what's newer than 5300-05-04:

```
$ oslevel -sg 5300-05-04
Fileset                                 Actual Level       Service Pack Level
-----------------------------------------------------------------------------
bos.rte.install                         5.3.0.55           5.3.0.54       
```

As you can see, I have already updated ''bos.rte.install''.  Now check what
fileset versions are required for the service pack update:

```
$ oslevel -sl 5300-05-05
Fileset                                 Actual Level       Service Pack Level
-----------------------------------------------------------------------------
bos.adt.include                         5.3.0.53           5.3.0.54       
bos.mp64                                5.3.0.54           5.3.0.55       
bos.mp                                  5.3.0.54           5.3.0.55       
...
```

These are particularly handy if you have applied updates but find that
''oslevel''

Also, to determine which Technology Levels and Service Packs your ''oslevel''
command knows about, you can use the ''-q'' option:

```
$ oslevel -sq
Known Service Packs
-------------------
5300-05-05
5300-05-04
...
$ oslevel -rq
Known Recommended Maintenance Levels
------------------------------------
5300-05
5300-04
5300-03
```

ODM
---

### ODM Object Classes

Ever wondered what all of those file names are you have to use with
"`odmget`"?  Here's a table from [Technical Reference: Kernel and
Subsystems, Volume 2][2]:

```
PdDv         Predefined Devices
PdCn         Predefined Connection
PdAt         Predefined Attribute
Config_Rules Configuration Rules
CuDv         Customized Devices
CuDep        Customized Dependency
CuAt         Customized Attribute
CuDvDr       Customized Device Driver
CuVPD        Customized Vital Product Data
```

[2]: http://publib.boulder.ibm.com/infocenter/pseries/v5r3/index.jsp?topic=/com.ibm.aix.kerneltechref/doc/ktechrf2/ODM.htm

General
-------

### Maximum User Processes

AIX has a global hard limit on the number of processes an individual user may
have, which can cause mysterious "fork: Resource temporarily unavailable"
message when a user it.  The limit even applies to root.  You can find out what
your limit is set to with "`lsattr`":

```
$ lsattr -HEl sys0 -a maxuproc
attribute value description                                  user_settable

maxuproc  128   Maximum number of PROCESSES allowed per user True
```

It can then be changed with "`chdev`":

```
# chdev -l sys0 -a maxuproc=200
sys0 changed
```


HMC Configuration
-----------------

### Enable Remote Syslog

Logged in to the HMC via SSH :

```
$ chhmc -c syslog -s add -h loghost.example.com
```

### Enable and Add NTP Servers

Logged in to the HMC via SSH :

```
$ chhmc -c xntp -s add -h ntpserver.example.com
```

Undocumented Commands
---------------------

### lqueryvg

```
$ for X in $(perl -e 'for (a..z,A..Z){print $_," ";}'); do echo $X ":"; lqueryvg -t$X -g 00ce23da00004c00000001099df94648 2>&1; done

a :
Max LVs:      	256
PP Size:      	27
Free PPs:     	4
LV count:     	2
PV count:     	3
Total VGDAs:  	3
Conc Allowed: 	0
MAX PPs per PV	1016
MAX PVs:      	32
Conc Autovaryo	0
Varied on Conc	0
Total PPs:    	239
LTG size:     	128
HOT SPARE:    	0
AUTO SYNC:    	1
VG PERMISSION:	0
SNAPSHOT VG:  	0
IS_PRIMARY VG:	0
PSNFSTPP:     	4352
VG Type:      	0
Max PPs:      	32512
b :
SNAPSHOT VG:  	0
c :
PV count:     	3
d :
lqueryvg: illegal option -- d
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
e :
lqueryvg: illegal option -- e
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
f :
MAX PPs per PV	1016
g :
0516-010 lqueryvg: Volume group must be varied on; use varyonvg command.
h :
HOT SPARE:    	0
i :
IS_PRIMARY VG:	0
j :
VG Type:      	0
k :
Max PPs:      	32512
l :
LTG size:     	128
m :
MAX PVs:      	32
n :
LV count:     	2
o :
Total PPs:    	239
p :
0516-082 lqueryvg: Unable to access a special device file.
	 Execute redefinevg and synclvodm to build correct environment.
q :
r :
VG version:   	30
s :
PP Size:      	27
t :
Max LVs:      	256
PP Size:      	27
Free PPs:     	4
LV count:     	2
PV count:     	3
Total VGDAs:  	3
Conc Allowed: 	0
MAX PPs per PV	1016
MAX PVs:      	32
Conc Autovaryo	0
Varied on Conc	0
Total PPs:    	239
LTG size:     	128
HOT SPARE:    	0
AUTO SYNC:    	1
VG PERMISSION:	0
SNAPSHOT VG:  	0
IS_PRIMARY VG:	0
PSNFSTPP:     	4352
VG Type:      	0
Max PPs:      	32512
u :
lqueryvg: illegal option -- u
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
v :
w :
lqueryvg: illegal option -- w
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
x :
Conc Autovaryo	0
y :
AUTO SYNC:    	1
z :
lqueryvg: illegal option -- z
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
A :
Max LVs:      	256
PP Size:      	27
Free PPs:     	4
LV count:     	2
PV count:     	3
Total VGDAs:  	3
Conc Allowed: 	0
MAX PPs per PV	1016
MAX PVs:      	32
Conc Autovaryo	0
Varied on Conc	0
Logical:      	00ce23da00004c00000001099df94648.3   installlv 1  
              	00ce23da00004c00000001099df94648.4   fslv01 1  
Physical:     	00ce23da6409b93f                1   1  
              	00ce23da6409bb88                1   1  
              	00ce23daeca0fb0a                1   1  
Total PPs:    	239
LTG size:     	128
HOT SPARE:    	0
AUTO SYNC:    	1
VG PERMISSION:	0
SNAPSHOT VG:  	0
IS_PRIMARY VG:	0
PSNFSTPP:     	4352
VARYON MODE:  	0
VG Type:      	0
Max PPs:      	32512
B :
Max LVs:      	256
PP Size:      	27
Free PPs:     	4
LV count:     	2
PV count:     	3
Total VGDAs:  	3
Conc Allowed: 	0
MAX PPs per PV	1016
MAX PVs:      	32
Conc Autovaryo	0
Varied on Conc	0
Total PPs:    	239
LTG size:     	128
HOT SPARE:    	0
AUTO SYNC:    	1
VG PERMISSION:	0
SNAPSHOT VG:  	0
IS_PRIMARY VG:	0
PSNFSTPP:     	4352
VG Type:      	0
Max PPs:      	32512
C :
Varied on Conc	0
D :
Total VGDAs:  	3
E :
lqueryvg: illegal option -- E
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
F :
Free PPs:     	4
G :
lqueryvg: illegal option -- G
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
H :
VARYON MODE:  	0
I :
lqueryvg: illegal option -- I
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
J :
lqueryvg: illegal option -- J
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
K :
lqueryvg: illegal option -- K
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
L :
Logical:      	00ce23da00004c00000001099df94648.3   installlv 1  
              	00ce23da00004c00000001099df94648.4   fslv01 1  
M :
Max LVs:      	256
PP Size:      	128
Free PPs:     	512
LV count:     	2
PV count:     	3
Total VGDAs:  	3
Conc Allowed: 	0
MAX PPs per PV	1016
MAX PVs:      	32
Conc Autovaryo	0
Varied on Conc	0
Total PPs:    	30592
LTG size:     	128
HOT SPARE:    	0
AUTO SYNC:    	1
VG PERMISSION:	0
SNAPSHOT VG:  	0
IS_PRIMARY VG:	0
PSNFSTPP:     	4352
VG Type:      	0
Max PPs:      	32512
N :
Max LVs:      	256
O :
lqueryvg: illegal option -- O
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
P :
Physical:     	00ce23da6409b93f                1   1  
              	00ce23da6409bb88                1   1  
              	00ce23daeca0fb0a                1   1  
Q :
lqueryvg: illegal option -- Q
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
R :
VG PERMISSION:	0
S :
VGDA size:    	2098
T :
Time Stamp:   	47cb69910d21db31
U :
lqueryvg: illegal option -- U
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
V :
W :
lqueryvg: illegal option -- W
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
X :
Conc Allowed: 	0
Y :
lqueryvg: illegal option -- Y
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]
Z :
lqueryvg: illegal option -- Z
Usage: lqueryvg [-g VGid | -p PVname] [-NsFncDaLPAvt]

```
