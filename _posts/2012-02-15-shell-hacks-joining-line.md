---
layout: default
tags: shell
category: "shell hacks"
title: "Joining Line-Delimited Data"
---
Joining Line-Delimited Data
========================================

The Perl **join** function is nice, because you can join a list to create a
scalar value with a delimiter. For example, if I have a line-delimited list of
names:

```
bob
joe
mary
```

I might want to have a comma-separated list, which I can do with **sed**:

```
$ sed -e ':a; N; s/\n/,/; ta' <<EOF
> bob
> joe
> mary
> EOF
bob,joe,mary
```

In general, where **DELIM** is your desired delimiter:

```
sed -e ':a; N; s/\n/DELIM/; ta'
```

