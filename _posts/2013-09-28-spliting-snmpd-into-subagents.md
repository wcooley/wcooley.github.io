---
layout: default
tags: snmp agentx
category: snmp
title: Splitting `snmpd` into AgentX Subagents
---

Background
----------

In a network with NFS, a hanging mount can cause the entire `snmpd` to hang. If
using SNMP for service monitoring, this can result in potentially misleading or
excess alerts.

To limit the scope of the damage, it might be useful to run multiple instances
of `snmpd` -- one as the master, which provides most of the MIBs, and one or
more AgentX subagents, which handle the potentially hang-prone branch of the
MIBs. This is done by enabling and disabling the various modules `snmpd` has
available. For example, let's move the `dskTable` and `diskIOTable` under the
*ucdavis* private enterprise subtree to a subagent.

Baseline
--------

To get started, ensure `snmpd.conf` has at least one `disk` directive, restart
`snmpd`, and view the `dskTable`:

```
$ snmptable -Of localhost dskTable
SNMP table: .iso.org.dod.internet.private.enterprises.ucdavis.dskTable

 dskIndex dskPath dskDevice dskMinimum dskMinPercent dskTotal dskAvail dskUsed dskPercent dskPercentNode dskTotalLow dskTotalHigh dskAvailLow dskAvailHigh dskUsedLow dskUsedHigh dskErrorFlag dskErrorMsg
        1       / /dev/sda3      10000            -1  7611636   206856 7018052         97             17     7611636            0      206820            0    7018052           0            0
```

Setting up the master
---------------------

First of all, the AgentX needs to be enabled in the master. Add to `snmpd.conf`:

```
master agentx
```

Then, the command-line for the master `snmpd` needs to be changed to disable
loading the modules. On RHEL5 for example, edit `/etc/sysconfig/snmpd.options`
and add `-I -disk,diskio` to `OPTIONS` and restart:

```
OPTIONS="-Lsd -Lf /dev/null -p /var/run/snmpd.pid -a -I -disk,diskio"
```

Now to check we've turned it off:

```
$ snmptable -Of localhost dskTable
.iso.org.dod.internet.private.enterprises.ucdavis.dskTable: No entries
```

Setting up the subagent
-----------------------

Now to start the AgentX subagent, add `-X` to run as an AgentX subprocess and
load the modules that had been disabled in the master with nearly the same `-I`
option: `-I disk,diskio`.

To confirm that it's working, we will run keep `snmpd` attached to the terminal
with `-f` and symbolically print SNMP transactions with `-V`:

```
# snmpd -V -f -Le -Lf /dev/null -p /var/run/snmpdiskd.pid -a -X -I disk,diskio
```

Now let's look at the table (on a different terminal, of course):

```
$ snmptable -Of localhost dskTable
SNMP table: .iso.org.dod.internet.private.enterprises.ucdavis.dskTable

 dskIndex dskPath dskDevice dskMinimum dskMinPercent dskTotal dskAvail dskUsed dskPercent dskPercentNode dskTotalLow dskTotalHigh dskAvailLow dskAvailHigh dskUsedLow dskUsedHigh dskErrorFlag dskErrorMsg
        1       / /dev/sda3      10000            -1  7611636   206856 7018052         97             17     7611636            0      206820            0    7018052           0            0
```

And check back where the `snmpdiskd` subagent is running, we should see output like:

```
NET-SNMP version 5.3.2.2 AgentX subagent connected
NET-SNMP version 5.3.2.2
Received SNMP packet(s) from callback: 1 on fd 4
  GETNEXT message
    -- .iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskIndex
Received SNMP packet(s) from callback: 1 on fd 4
  GETNEXT message
    -- .iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskIndex.1
…
```

### Confirming the failure case

This all works under normal circumstances, but our goal is to make `snmpd` more
robust in the face of failures -- How do we know that the master won't simply
hang if the subagent does too? We need to test a running but unresponsive
subagent; fortunately this is easy with `snmpd` still attached to the terminal
-- we can hit CTRL-Z to suspend the process with a `SIGSTOP`.

Before we break the subagent, however, let's first walk the *ucdavis* subtree
and confirm that both our disk-related information and the other information
appear together as expected:

```
$ snmpwalk -Of localhost ucdavis |less
.iso.org.dod.internet.private.enterprises.ucdavis.memory.memIndex.0 = INTEGER: 0
…
.iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskIndex.1 = INTEGER: 1
.iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskPath.1 = STRING: /
…
.iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskDevice.1 = STRING: /dev/sda3
…
.iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskErrorMsg.1 = STRING:
.iso.org.dod.internet.private.enterprises.ucdavis.laTable.laEntry.laIndex.1 = INTEGER: 1
```

And let's check getting a particular entry:

```
$ snmpget -Of localhost ucdavis.dskTable.dskEntry.dskPath.1
.iso.org.dod.internet.private.enterprises.ucdavis.dskTable.dskEntry.dskPath.1 = STRING: /
```

Now we suspend the `snmpdiskd` with CTRL-Z:

```
[1]+  Stopped                 snmpd -n snmpdiskd -V -f -Le -Lf /dev/null -p /var/run/snmpdiskd.pid -a -X -I disk,diskio
```

And now let's check getting a particular entry:

```
$ snmpget localhost ucdavis.dskTable.dskEntry.dskPath.1
Timeout: No Response from localhost.
```

That returns after a brief time-out. Now let's check walking the *ucdavis* subtree:

```
.iso.org.dod.internet.private.enterprises.ucdavis.memory.memIndex.0 = INTEGER: 0
...
.iso.org.dod.internet.private.enterprises.ucdavis.memory.memSwapErrorMsg.0 = STRING:
.iso.org.dod.internet.private.enterprises.ucdavis.laTable.laEntry.laIndex.1 = INTEGER: 1
.iso.org.dod.internet.private.enterprises.ucdavis.laTable.laEntry.laIndex.2 = INTEGER: 2
…
```

Notice now no `dskTable` and the other *ucdavis* subtrees worked just fine!

Splitting up configuration
--------------------------

So far, so good -- it's finishings from here on out.

First of all, you might notice in your *syslog* events like the following:

```
/etc/snmp/snmpd.conf: line xxx: Warning: Unknown token: disk.
```

This is because without the `disk` module, the `disk` directive is unknown; the
subagent will print many more complaints, since it knows even less than the
master. The solution is to move the `disk` directives to a new config file
`/etc/snmp/snmpdiskd.conf` and set "*snmpdiskd*" as the alternative application
name with `-n`, which causes `snmpd` to look for `snmpdiskd.conf` in the 8 or
so places it looks for configuration files (see snmp_config(5) for details):

```
# snmpd -n snmpdiskd -V -f -Le -Lf /dev/null -p /var/run/snmpdiskd.pid -a -X -I disk,d
```

Init script
-----------

The final task, left as an exercise for the reader, is to create an init script
to start up the subagent with the desired parameters.

Other MIBs
----------

It is also possible to move data from the host resources MIB to the subagent.
It does not, however, appear to be possible to move *only* the storage and
filesystem tables, so all of the managed host resourced have to move. Doing so
is simply a matter of finding the right modules -- Run `snmpd -Dmib_init -H
2>&1 |grep ^mib_init:|sort` and add all of the `hr_*`, `hrh_*` and `hw_*`
modules to the exclusion and inclusion lists.

Other good candidates for moving to a subagent are the modules providing
various directives for running external commands for output, such as `extend`,
`pass`, and `exec`.

Posted: {{ page.date | date_to_string }}
