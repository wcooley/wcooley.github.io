---
tags: shell
category: "shell hacks"
title: Shell Hacks
---
# Shell Hacks

This page is for quick shell hacks. More complete **bash**-scripting
documentation is available from the [Advanced Bash-Scripting Guide][1].

[1]: http://tldp.org/LDP/abs/html/

In case it isn't obvious, these are all only tested on **bash**. **ksh** might
work but I only rarely use it and I don't test in it.

## Listing Non-System Users

```awk``` is a word-splitter.  ```/etc/passwd``` is a colon-delimited list of
words.  Ergo:

```
$ awk -F: '{if ($3 >= 500) { print $1 }}' /etc/passwd
```

Replace **500** with the beginning UID for non-system users for your system.
Red Hat uses 500; Solaris uses 1000.  If you're using NIS, LDAP, or other
NameServiceSwitch back-end, use the ```getent``` command (which, conveniently
outputs the same format as ```/etc/passwd```):

```
getent passwd | awk -F: '{if ($3 >= 500) {print $1}}'
```

Neither of these commands will work on AIX, but on AIX you've got ```lsusers```
already.  Note that you can also list only the system users by reversing the
comparison operator.  You will likely have a user **nfsnobody** that is UID
65534 (which corresponds to -1 in signed 16-bit integers) which is also a
system user.

## Display Meat of Config File

This removes empty lines and lines that start with a '#', usually used as a
comment character.

```
grep -vE '^($|#)' <foo.conf>
```

This one is better; it strips comments and whitespace-only lines, whereas the
previous only strips comments starting at the beginning of the line and blank
lines:

```
alias nocomment="sed -e 's/\([^#]*\)#.*$/\1/; /^[[:space:]]*$/d; /^#/d;'"
```

## Find Empty Directories

This is the magic for ```find``` that finds empty directories in the current
working directory.

```
find . -empty -maxdepth 1 -type d
```


## Hourly Statistics from Log Files

This extracts the hour from the syslog timestamps and shows how many log
entries occured in each hour.  This is most useful if you pre-process
\<logfile\>, or you remove log file and feed it with a pipe.

```
awk '{print $3}' <logfile> |awk -F: '{print $1 ":00"}' |sort -n |uniq -c
```

## Getting the Script Name

I used to use ```prog=$(basename $0)``` to get the script's basename (which is
good for help output, temp files, etc).  However, I've picked up a tip from
SUSE's init scripts which uses the parameter expansion available in bash and
ksh:

```prog=${0##*/} ```

It's a little more succinct (if perhaps obscure) and obviates an exec.

## Function Template: **usage**

```
usage() {
    # Default to 0
    local exitval="${1:-0}"

    if [[ $exitval -eq 1 ]]; then
        # Redirect stdout to stderr
        exec 1>&2
    fi

    echo "Usage: ${0##*/} [-h] [-x]"
    echo "Do something or other."
    echo "  -x          - Set 'x' to true."
    echo "  -h          - show this help screen."

    exit "$exitval"
}

```

## Generate Sequence of Integers without Using 'seq'

Brace expansion can be use with a range:

```
$ echo {1..10}
1 2 3 4 5 6 7 8 9 10
```

Also supports a non-1 increment:

```
$ echo {1..10..2}
1 3 5 7 9
```

Descending increment:

```
$ echo {10..1}
10 9 8 7 6 5 4 3 2 1
```

Zero-padding:

```
$ echo {01..10}
01 02 03 04 05 06 07 08 09 10
```

## Iterate Over $PATH

Use the pattern-substitution parameter expansion. Note that you must also not
quote the variable (which I usually do as a good practice):

```
$ for p in ${PATH//:/ }; do echo $p; done
/usr/sbin
/usr/bin
/sbin
/bin
```

### Improved pathmunge

Red Hat's ```/etc/profile``` defines a shell function called ```pathmunge``` to
conditionally add directories to ```$PATH``` The problem with this
implementation is that it runs ```egrep```, which involves forking a process
and incurs a modicum of overhead. Generally that's not a big deal--the overhead
is minimal on modern processors. But if the host is in a state of distress due
to swapping or a fork-bomb or such, these extra processes become a burdensome
overhead.

Here's my implementation, which also adds a **force** parameter (which
unfortunately means it is not idempotent) and changes the **after** to
**before**, since **after** is what I usually want.

```
pathmunge () {
    newpath="$1"

    if [[ ! -d "$newpath" ]]; then return 1; fi
    if [[ "$2" = "force" || "$3" = "force" ]]; then force=1; else force=0; fi

    if [[ $force -ne 1 ]]; then
        for p in ${PATH//:/ }; do
            if [[ "$p" = "$newpath" ]]; then
                : $newpath exists - aborting early
                return 1
            fi
        done
    fi

    : adding $newpath - $LINENO
    if [[ "$2" = "before" ]] ; then
        PATH="$newpath:$PATH"
    else
        PATH="$PATH:$newpath"
    fi
}
```
