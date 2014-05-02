[[TableOfContents(3)]]

= Linux Notes =

== See Also ==
 * FedoraNotes
 * RedHatLinux Notes
 * DebianGnuLinux Notes
 * SuseLinuxNotes

 * RaidRecovery

== ext3 Filesystem ==

=== Stalls or Hangs ===

A source of stalls or hangs with ext3 doing many writes is that the journal is too small--the journal has to be flushed more frequently than optimal while other writes are happening.  According to Ted Ts'o, the new versions of ''e2fsprogs'' creates a larger journal by default--128M--than previously, 32M.

See http://lopsa.org/pipermail/discuss/2006-February/000810.html

=== Determining Journal Size ===

Given the above problem of journal size, the next logical question is "How big is my journal?"  Finding the answer is non-obvious, so I am documenting it here for posterity.

==== New Way ====

Thanks to Michael Dean for pointing out that there is an easier way than the one described below in the ''Old Way'' section.  It is much easier to use the {{{dumpe2fs}}} command to view the superblock information: {{{
# dumpe2fs -h /dev/XXX|grep Journal
dumpe2fs 1.39 (29-May-2006)
Journal inode:            8
Journal backup:           inode blocks
Journal size:             8M
}}}

Note that this way works with ''e2fsprogs'' version 1.39, but not before.

==== Old Way ====
 0. Verify the journal inode.  It seems to be '''8''' by default, but one should verify:{{{
# tune2fs -l /dev/XXX |grep "^Journal inode"
Journal inode:            8
}}}

 0. Use the {{{debugfs}}} utility to stat the journal file by inode:{{{
# debugfs -R 'stat <8>' /dev/storagedev
Inode: 8   Type: regular    Mode:  0600   Flags: 0x0   Generation: 0
User:     0   Group:     0   Size: 33554432
...
}}}

 My journal, in this case, is 32MB ( == 33554432B).


=== Increasing Journal Size ===

Increasing (or shrinking) the journal size is straightforward but tricky.  You'll need to unmount the filesystem in question, so if this is the root filesystem, it's easiest to boot from a utility disk (or disk image from GRUB).

Here I've created a ''testvg'' volume group with an ext3 filesystem on a ''testlv'' logical volume and am mounting it on {{{/mnt/test}}}.  The ''testlv'' volume is 512M, so the default journal size was 16M (due to it having a 1k block size).

 0. First we must unmount: {{{
# umount /mnt/test
}}}

 0. Then remove the journal: {{{
# tune2fs -O^has_journal /dev/testvg/testlv
tune2fs 1.38 (30-Jun-2005)
}}}

 0. Then create a new journal with the desired size: {{{
# tune2fs -j -J size=100 /dev/testvg/testlv
tune2fs 1.38 (30-Jun-2005)
Creating journal inode: done
This filesystem will be automatically checked every -1 mounts or
0 days, whichever comes first.  Use tune2fs -c or -i to override.
}}}

 0. Then I remount the filesystem and check the free space.  This is an otherwize empty filesystem, so the only space taken is by the hidden journal file: {{{
# mount /dev/testvg/testlv /mnt/test
# df -h /mnt/test
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/testvg-testlv
                      496M  103M  368M  22% /mnt/test
}}}


=== Enabling Indexed Directories ===

Directory indexing is a feature of ext3 that appeared in the 2.5/2.6 kernel and was back-ported to the 2.4 kernel by vendors such as Red Hat.  This feature increases performance of directories with many files by using a hash rather than a simple array to store the directory entries.  According to [http://lwn.net/Articles/11481/ Ted Tso]: "Creating 100,000 files in a single directory took 38 minutes without directory indexing... and 11 seconds with the directory indexing turned on."  One expects performance gains from listing such directories and looking up individual files.

There was a brief period where {{{mke2fs}}} enabled the ''dir_index'' option by default, but most of the time you will find it not enabled.  It is, however, simple to enable: {{{
# tune2fs -O dir_index /dev/device
}}}

This can be done while the filesystem is mounted, since it only sets a flag in the filesystem superblock.  (Question: Does it start creating directories with indexes immediately, or does the filesystem have to be remounted first?)  On a new filesystem or one with few files, this is all that really needs to be done.  However, with existing filesystems, they should be unmounted and {{{e2fsck -D}}} run, which re-indexes the existing directories: {{{
# e2fsck -D -f /dev/rootvg/optlv
e2fsck 1.38 (30-Jun-2005)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information

/opt: ***** FILE SYSTEM WAS MODIFIED *****
/opt: 4375/122880 files (1.3% non-contiguous), 231226/491520 blocks
}}}

Notice the addition of the {{{-f}}} flag; since the filesystem was cleanly umounted, the fsck had to be forced.

=== Correcting a Missing External Journal Device ===

After moving disks and logical volumes around, I discovered that I was unable to mount the ext3 file system that I had created with an external journal. The journal, in this case, was a separate LV, that in the process of moving volumes around, had gotten a different minor number.

''{{{mount}}}'' failed with no explanation other than to check ''{{{dmesg}}}'', which was similarly uninformative: {{{
$ dmesg |tail
...
EXT3: failed to claim external journal device.
}}}

Searching the Internet was similarly unhelpful; I was able to find only '''1''' mailing list reference to this particular error message: http://thread.gmane.org/gmane.comp.file-systems.ext3.user/2631. (There were patches, of course, but those are just noise in this case.)

Indeed, the journal device in the superblock was different than the minor number of the LV: {{{
# tune2fs -l /dev/my-ext3-filesystem | grep '^Journal device'
...
Journal device:           0xfc01
...
$ printf "%d %d\n" 0xfc 0x01
252 1
$ ls -l /dev/my-external-journal-device
brw-rw---- 1 root disk 252, 4 2010-06-09 14:23 /dev/my-external-journal-device
}}}

The problem then was to figure out how to use the correct device. Minor 1 was already taken and would have been a pain to shuffle around. I attempted to use the "{{{-o journal_dev=/dev/my-external-journal-device}}}" mount parameter to no avail. I attempted similarly to use the UUID, which matched between file system and journal. I tried to use ''tune2fs'' to change the journal device, but I could not do that without removing the existing journal, which was risky in case it had not unmounted cleanly.

Finally, I was re-reading the ''e2fsck(8)'' man page and noticed that there was an ''-j'' option that would, at least, allow ''fsck'' to check the filesystem, after which I could removing the existing journal and add it back. What I had not expected, however, is that the ''fsck'' would actually update the superblock with the correct minor number.

The solution was: {{{
# e2fsck -j /dev/my-external-journal-device /dev/my-ext3-filesystem
...
Superblock hint for external superblock should be 0xfc04.  Fix? yes
...
}}}

Perhaps I should also make the minor number of the journal LV persistent, which I can do with ''lvchange''.


== autofs ==

=== Using bind mounts with autofs ===

It is possible with ''autofs'' to use "bind mounts", which mount an existing path to another. In fact, ''autofs'' already uses a bind mount to handle a request for a local NFS export, thereby avoiding the overhead of NFS when unnecessary.

The non-obvious trick is to use ''{{{bind}}}'' as the ''{{{-fstype=}}}'' in the options column and start the location on the right-hand side with a colon, just as you would for any other local share (such as in ''{{{auto.misc}}}''). Like this: {{{
/nfs/bjensen  -fstype=bind  :/net/zeus/home/bjensen
}}}

== LVM ==

=== Creating Nested Volume Groups ===

You can initialize a logical volume (LV) as a physical volume (PV) and use that physical volume as the basis for another volume group (VG):

{{{
# lvcreate -L 1G -n testpvlv rootvg
# pvcreate /dev/rootvg/testpvlv
# vgcreate testvg /dev/rootvg/testpvlv
}}}

Sanity checks prevent adding the new PV-on-LV to the original VG:
{{{
# vgextend rootvg /dev/rootvg/testpvlv
  Physical volume /dev/rootvg/testpvlv might be constructed from same volume group rootvg
  Unable to add physical volume '/dev/rootvg/testpvlv' to volume group 'rootvg'.
}}}

== Misc Storage ==

=== "Un-ejecting" USB Drive ===

When a USB drive is ejected in GNOME/Nautilus, SCSI eject commands are sent to the device after unmounting the file system. The Nautilus context menu has an "Open" option which might lead one to believe that it can then re-mounted and opened, but that does not work. In fact, other than showing that the presence of the device, once it has been ejected, there is nothing useful that can be done within Nautilus.

It is possible, however, to "un-eject" the device (usually "un-eject" is written as "close the CD/DVD-ROM tray", but the operation is more general than optical media). The trick is to use the ''{{{eject}}}'' command, with the '''''-t''''' to "un-eject" and the '''''-s''''' to use SCSI commands:{{{
# eject -s -t /dev/sdX
}}}

You will then find that the device re-appears in {{{/proc/partitions}}} and the volume manager in GNOME remounts the device.
