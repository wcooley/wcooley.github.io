---
tags: platform wispdist soekris
category: platform
title: "WISP-Dist on Soekris"
---
# WISP-Dist on Soekris

Notes on setting up a wireless access point using [http://www.leaf-project.org/mod.php?mod=userpage&menu=908&page_id=27 WISP-Dist] on a [http://www.soekris.com Soekris] 4521.


## Setting Up the Serial Console
* Edit `syslinux.cfg` and:
   1. Change references to `hda` to `hda1`.
   1. Add `console=ttyS0,19200n8` so the kernel will output boot messages to the serial console.
   1. Don't use the `serial` parameter in `syslinux.cfg`, since the Soekris' serial console emulates a standard PC keyboard/video interface.

When you first boot, you'll see lots of line noise after init starts.  This is
because the Soekris uses 19200bps for the console, but the `getty` that
WISP-Dist starts is 9600bps.  When you see this, change your terminal settings
to 9600bps and login.

When using `vi` at 9600bps, scroll by page and not by line, because it's
**really slow**.

Okay, so you've got it up and running.  Now you probably want to change the
serial console speed so it's not such a PITA.  On your development host, where
you've unzipped WISP-Dist, create a directory which we'll call `root` here.
Change into this directory and un-tgz the `root.lrp` file here.  Edit
`etc/inittab` and change the *T1* line from 9600 to 19200.  Re-tgz the files in
the `root/` directory and rename the tarball `root.lrp` (taking care to backup
your original `root.lrp`).  Re-generate the `root.md5` with

```
find . -type f | sed -e 's#^\./##' |xargs md5sum > ../root.md5
```

and then copy these to your packages directory on your flash.

## Cleaning Up Boot

 1. Un-gzip `initrd.lrp` (`zcat initrd.lrp > initrd.lrp.ungz`); this is a compressed Minix file system.
 1. Mount in a temporary location:

    ```
    mount -o loop initrd.lrp.ungz /mnt/tmp2
    ```

 1. Edit `boot/etc/modules` and remove: mtdcore, doc2000, docecc, docprobe,
 nftl.  We're not using DiskOnChip here, and it just clutters boot and probably
 makes it slower.
 1. Unmount `/mnt/tmp2`.
 1. Re-compresss: `gzip -c9 initrd.lrp.ungz > initrd.lrp`.

### Disable inetd
 1. In the `root.lrp` package, edit etc/init.d/inetd and comment out **RCDLINKS**

### Enable dhcpd
 1. In the `root.lrp` package, edit etc/init.d/dhcpd and uncomment **RCDLINKS**
