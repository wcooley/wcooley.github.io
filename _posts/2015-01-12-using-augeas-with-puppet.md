---
layout: default
tags: puppet augeas
category: puppet
title: "Using Augeas with Puppet"
---

There is now a [good guide](https://docs.puppetlabs.com/guides/augeas.html) to
using Augeas with Puppet in the official Puppet docs, but there are a few
points that are either not present or that should be emphasized.

Always use `lens` and `incl`, which makes `context` unnecessary. Performance
is abysmal otherwise.

To imitate this with `augtool`, disable automatic loading of lenses and files
into the tree on startup with the options *`--noautoload`* and *`--noload`*
and then manually specify the lens and file pattern; see also the Augeas wiki
page "[Loading specific files]
(https://github.com/hercules-team/augeas/wiki/Loading-specific-files)":

```
    augtool --noautoload --noload
    > set /augeas/load/Foo/lens "Foo.lns"
    > set /augeas/load/Foo/incl "/etc/foo"
    > load
```

To find out what lens to use for a file with an existing lens, run with
autoloading enabled and view the `/augeas/files/**file/path**` to find the
lens, and then view `/augeas/load/**Lensname**` to see the len's list of
`incl` and `excl` file patterns. If there is no existing lens, either find the
lens for a similar file or try one of the generic lenses listed in the Puppet
guide.

```
    augtool augtool> print /augeas/files/etc/sysconfig/autofs
    /augeas/files/etc/sysconfig/autofs
    /augeas/files/etc/sysconfig/autofs/path = "/files/etc/sysconfig/autofs"
    /augeas/files/etc/sysconfig/autofs/mtime = "1371594833"
    /augeas/files/etc/sysconfig/autofs/lens = "@Shellvars"
    /augeas/files/etc/sysconfig/autofs/lens/info = "/usr/share/augeas/lenses/dist/shellvars.aug:167.12-.99:"

    augtool> print /augeas/load/Shellvars
    /augeas/load/Shellvars
    ...
    /augeas/load/Shellvars/excl[15] = "/etc/sysconfig/bootloader"
    /augeas/load/Shellvars/incl[16] = "/etc/sysconfig/*"
    /augeas/load/Shellvars/excl[16] = "/etc/default/whoopsie"
    /augeas/load/Shellvars/excl[17] = "/etc/default/grub_installdevice*"
    /augeas/load/Shellvars/incl[17] = "/etc/default/*"
    ...
    /augeas/load/Shellvars/excl[18] = "#*#"
    /augeas/load/Shellvars/excl[19] = "*.old"
    /augeas/load/Shellvars/excl[20] = "*.bak"
    /augeas/load/Shellvars/excl[21] = "*.augnew"
    /augeas/load/Shellvars/excl[22] = "*.augsave"
    /augeas/load/Shellvars/excl[23] = "*.dpkg-dist"
    /augeas/load/Shellvars/excl[24] = "*.dpkg-bak"
    /augeas/load/Shellvars/excl[25] = "*.dpkg-new"
    /augeas/load/Shellvars/excl[26] = "*.dpkg-old"
    /augeas/load/Shellvars/excl[27] = "*.rpmsave"
    /augeas/load/Shellvars/excl[28] = "*.rpmnew"
    /augeas/load/Shellvars/excl[29] = "*~"
```

