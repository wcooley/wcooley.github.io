---
layout: default
tags: naming directory
category: platform
title: Name Service Switch (NSS)
---
# Name Service Switch (NSS)

## Description

The Name Service Switch is a System V UNIX facility which abstracts the mapping
between names and numbers into a set of library calls and makes the back-end
pluggable (hence "switch").  For a stand-alone server, this is used to provide
access to the various file databases for users, groups, hostnames, services and
protocols.  The backend is selected with the ```/etc/nsswitch.conf``` file.  In
a networked environment, it is used to distribute this information through the
network, such as with NIS and LDAP.  The database types are often called
''maps''.

## Availability

As this is a System V facility, it is available on almost any platform that is
SysV-based, such as Solaris.  It is likely available on IRIX, HP-UX, and SCO,
but I cannot verify this.  It is not, however, available on AIX and BSD-based
systems, such as FreeBSD, NetBSD, OpenBSD, and MacOS X.  It is also available
on Linux distributions since it is included with the GNU ```glibc```.

## Back-Ends

Back-end selection is done through the ```/etc/nsswitch.conf``` file.  Included
stock with GNU ```glibc``` are the following back-ends:

 * nisplus
 * nis
 * dns
 * files
 * db
 * compat
 * hesiod

An LDAP back-end is also available from PADL at
http://www.padl.com/OSS/nss_ldap.html.  The [Samba
project](http://www.samba.org) also makes a daemon called ```winbindd``` that
is able to retrieve information for users and groups from a Windows Domain
Controller, although it internally has to map Windows UUIDs to user and group
IDs, since the Windows protocols use an alphanumeric string instead of just a
number to ennumerate users and groups.

The ```dns``` back-end is used only for hostname resolution, as you might
expect.  The ```hesiod``` back-end also uses DNS with special record types, but
it isn't used widely outside of a few large university campuses.  The
```files``` back-end is the default for most databases, and uses
```/etc/passwd``` for users, ```/etc/groups``` for groups, ```/etc/hosts``` for
hostnames, ```/etc/services``` for service to port/protocol (mostly TCP and
UDP) mappings, and ```/etc/protocols``` for protocols.  The ```db``` back-end
is a Berkeley-style database built from map files with the same formats as the
```files``` back-end.  On Linux systems, these are usually located in
```/var/db```.  The ```compat``` back-end is for some NIS compatibility,
although I'm not entirely sure what.  The ```nis``` and ```nisplus``` back-ends
are, obviously, for NIS and NIS+.

Also included is ```nscd```, the name-service cache daemon.  For network
back-ends, this provides a considerable speed-up by caching information.  Load
is also considerably decreased on the server.  It is configured in
```/etc/nscd.conf```, which lets you set various server options, and time-outs
and other parameters for the various maps.

### External Back-Ends

As of ''glibc'' 2.2, ''nss_db'' has been moved into a separate package.  There
are also a number of other external or third-party NSS providers, including the
following:

 * db
 * [winbind][6] Samba component for mapping Windows SIDs into UNIX UIDs and GIDs
 * [ldap](http://www.padl.com/OSS/nss_ldap.html), PADL's ''nss_ldap''
 * [mdns](http://0pointer.de/lennart/projects/nss-mdns/), multicast DNS (aka,
   ''Rendezous'' or ''Zeroconf'')
 * MySQL (several)
 * Postgres (several)

[6]: http://us1.samba.org/samba/docs/man/Samba-HOWTO-Collection/winbind.html

## Programming

Various programming languages provide interfaces for accessing data in the
maps.  The simplest is the shell command ```getent```.  If you issue the
command with a map name it will list all entries in that map:

```
$ getent passwd |head
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:
daemon:x:2:2:daemon:/sbin:
adm:x:3:4:adm:/var/adm:
lp:x:4:7:lp:/var/spool/lpd:
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:
news:x:9:13:news:/var/spool/news:
```

If you supply a key, it will retrieve only the record with that key; for the
''passwd'' map, available keys are username and UID:

```
$ getent passwd 0
root:x:0:0:root:/root:/bin/bash

$ getent passwd root
root:x:0:0:root:/root:/bin/bash
```

You can also use it on to look up host names without caring about whether it's
coming from DNS or ```/etc/hosts``` or whatever back-ends you have configured:

```
$ getent hosts www.nakedape.cc
192.216.215.10  www.nakedape.cc
```

If you write shell scripts that access this data, you can do it more portably
by using this interface instead of reading the files directly.  An example is
on my ShellHacks page.

Of course, C, Perl, Python and probably Ruby also provide similar interfaces.
However, with these interfaces, you usually go through a ```setXXent```, loop
over ```getXXent```, ```endXXent``` pattern to retrieve data one record at a
time.  The ''XX'' means there are separate calls for the various maps, for the
''passwd'' map the ''XX'' is ''pw''.  You can see the Perl interface in action
in my [migrate-pw-to-cyrus2.pl](http://nakedape.cc/src/migrate-pw-to-cyrus2.pl)
script.
