---
layout: default
category: platform
tags: platform solaris
title: "Platform Notes: Solaris"
---
# Solaris Notes


## Determining CPU speed, memory, etc
```
/usr/platform/`uname -m`/sbin/prtdiag
```

## Booting into Single-User Mode
```
ok boot -s
```

## Booting into Single-User Mode from CD-ROM
```
ok boot cdrom -s
```

## Checking Applied Patches
```
showrev -p
```

## Display Disk Partitions/Slices

To list all of the disks in the system along with their sizes, use the
following `iostat` command. The **-n** causes it to print the disk names as
**cXtXdX** instead of **sdX** (which does not seem to correspond with anything
obvious).

```
# iostat -nE
```

This is actually kinda lousy if you need to know about multiple disks. You also have to convert sectors to bytes (by dividing by two) to see the actual size.

```
prtvtoc /dev/rdsk/c0t0d0s0
```

Make sure to use the **rdsk** device file and slice 0.

## Mounting Loopback Filesystem Images

Particularly useful for ISO-9660 (CD) images.  The `lofiadm` tool is similar to
the `losetup` utility in Linux--it connects a file (which is presumeably a
filesystem image) with a block device, so that it can be mounted, mkfs'd, etc.

```
# lofiadm -a foo.iso
/dev/lofi/1
# mount -F hsfs -o ro /dev/lofi/1 /mnt
```

Or in one step:

```
# mount -F hsfs -o ro $(lofiadm -a foo.iso) /mnt
```

## Installing Packages

### One-shot mode
```
pkgadd -d <pkgfile>
```
### Spool-install

This method is useful for installing into an NFS export, for easy installation
on other systems.

1. Install the package into `/var/spool/pkg`:

    ```
    pkgadd -s /var/spool/pkg -d <pkgfile>
    ```
1. Install the package from the listing:

    ```
    pkgadd
    # Follow prompts
    ```

## Upgrading Packages

Generally, you cannot install a package over an existing package, because the
default file `/var/sadm/install/admin/default` has the parameter `instance` set
to *unique*. If you make a copy of this file and change *unique* to *ask*, you
will be prompted to overwrite the installed package if you run `pkgadd` with
the option `-a admin-pkgupgrade`.
