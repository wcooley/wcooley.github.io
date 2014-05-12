---
layout: default
tags: shell
category: "shell hacks"
title: "Cleaning Up on Exit"
---
Cleaning Up on Exit
================================

You can automatically clean up on exit using the "```trap```" built-in command.
This command allows commands to be run when signals are received or on certain
other condition, such as exit.

Let's say you have a temporary file in the shell variable ```$tmpfile``` that
should be removed on exit.

```
trap "rm -f $tmpfile" EXIT
```
