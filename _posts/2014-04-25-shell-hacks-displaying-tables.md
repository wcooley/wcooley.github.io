---
tags: shell
category: "shell hacks"
title: "Displaying Tables"
---
Displaying Tables
==============================

Previously I used `awk` when I had data in a tabular format that I wanted to print in aligned columns:

    head -n5 /etc/passwd|awk -F: '{printf "%-10s %3s %8d %8d %10s %16s %10s\n", $1, $2, $3, $4, $5, $6, $7}'
    root         x        0        0       root            /root  /bin/bash
    bin          x        1        1        bin             /bin /sbin/nologin
    daemon       x        2        2     daemon            /sbin /sbin/nologin
    adm          x        3        4        adm         /var/adm /sbin/nologin
    lp           x        4        7         lp   /var/spool/lpd /sbin/nologin

This requires a good deal of fiddling to get column widths correct, the
right number of format strings, etc. A better way to quickly format
output like this is with the `column` command, included with the
*util-linux* package:

    head -n5 /etc/passwd|column -s: -t
    root    x  0  0  root    /root           /bin/bash
    bin     x  1  1  bin     /bin            /sbin/nologin
    daemon  x  2  2  daemon  /sbin           /sbin/nologin
    adm     x  3  4  adm     /var/adm        /sbin/nologin
    lp      x  4  7  lp      /var/spool/lpd  /sbin/nologin

This lacks the level of formatting control that one has with the `awk`
command above and it has to read all of the input before displaying it
(so, for example, formatting output from `tail -f` will not work), but
for a lot of cases this should be just fine.
