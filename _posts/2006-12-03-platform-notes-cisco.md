---
category: platform
tags: platform cisco
title: "Platform Notes: Cisco"
---
# Cisco Notes

## Logging to vty Session
To enable logging on a vty session, enable monitor logging with:

```
# conf t
(config)# logging monitor
(config)# ^Z
```

Next, configure it to copy debug output to the current terminal:

```
# terminal monitor
```

To turn it off:

```
# terminal no monitor
```

## Cisco 675/678 Notes

Little DSL routers; I've got one--they used to be all over the place.  These
notes are for the serial console.

### Enter ROM Montor

CTRL-X 3 times at boot

### Reboot From ROM Monitor

```
=> rb
```

### Erase Configuration
```
=> es 6
```

### Recover from Faulty Firmware Upgrade

**Do not use minicom/lrzsz -- It will fail and cause you to have to do this!**
(Current as of 1999.)

```
=> df 10008000
Make note of file size
=> es 0
=> es 1
=> es 2
=> es 3
=> es 4
=> pb 10008000 fe00000 <file size>
=> rb
```
