---
tags: shell
category: "shell hacks"
title: "Redirection"
---
Redirection
========================

Redirecting I/O Script-wide
---------------------------

The `exec` command can be used to redirect I/O script-wide. If `exec`
is not given a command to execute, it applies whatever I/O redirections are
specified to the current shell itself.

For example, instead of appending `>/tmp/logfile` to capture the output of
every command to a file, use this to redirect **stdout**:

```
exec >/tmp/logfile
```

To direct **stderr** to **stdout**, use:

```
exec 2>&1
```

Or the reverse, **stdout** to **stderr**:

```
exec 1>&2
```

### Logging and Monitoring with Tee

Sometimes you want to capture all standard output to a log file while
monitoring the output yourself. We can use the `exec` I/O redirection to do
this also along with [process substitution][2]:

[2]: http://tldp.org/LDP/abs/html/process-sub.html

```
exec > >(tee -a ${0##*/}.log)
```

If you wanted to redirect **stderr** to a different file:

```
exec 2> >(tee -a ${0##*/}.err)
```

Printing and Logging to Syslog
------------------------------

Let's make use of the `exec` to log the output of the script to syslog
instead of a file. We have the `logger` command, which will take a
message either on the command line or from standard input and write it to
syslog. The `-s` option instructs it to also write the log messages to
standard error. And if we did not know about
[process substitution][2], we could
use a named FIFO to have `logger` read from and standard output and
error to write to.

```
prog=${0##*/}

if [[ -z "$FIFO" ]]; then
    export FIFO="/tmp/${prog}.$RANDOM"
fi

if [[ ! -e "$FIFO" ]]; then
    mkfifo -m 666 "$FIFO"
    trap "rm $FIFO" ERR EXIT
    logger -t "${prog}:" -i -s <"$FIFO" &
fi

exec >"$FIFO" 2>&1
```

Trace-visible Comments
----------------------

Sometimes when debugging shell scripts, it's nice to be able to tell where you
are.  It's not always clear, even when running in trace-mode (`set -x`).
Usually this is accomplished by inserting `echo` statements that tell you
where you are.  When you're finished debugging, you have to remove or
comment-out these (and how many times have you discovered one you forgot to
remove?)  Instead, you can use the colon-builtin to provide "traceable"
comments.  The colon command is one of those little-used commands that does
nothing other than provide a true value, so it's often used in `while`
loops that you expect to exit in ways other than the conditional or to ensure
that some particular line always returns true (frequently seen in RPM spec
files, for example).  The colon command ignores any parameters given to it, so
you can add a comment after the colon and it will be visible when run with
tracing turned on and invisible otherwise.  Note that it is actually a command
and not a comment so it cannot be used exactly as a comment would, such as at
the end of a statement (although you can use the semi-colon statement
separator, as you'd expect with any other).  `true` and `false` also
ignore any supplied parameters, but it seems less obvious than not.

Here's an example script:

```
#!/bin/bash
: This is an invisible traced comment
set -x
# This is an untraced comment
: This is a traced comment
```

Which produces the following output:

```
$ ./test.sh
+ : This is a traced comment
```

Redirecting To stderr
---------------------

Under `bash`, `/dev/stderr` is an internally-recognized device that,
when redirected to, writes the output to **stderr**.  Under Linux and Solaris,
`/dev/stderr` exists as a character device for the current process's
**stderr**. (It's actually a symlink to a character device, but
the effect is the same.)  So writing to `/dev/stderr` in a shell that
didn't provide an internal `/dev/stderr` should work just fine.  But that's
not true with `ksh` on AIX.  With `ksh`, one might be inclined to use
"`print -u 2`", but that doesn't work in `bash`.

If you have to worry about portability, use the obscure redirection to redirect
**stdout** to **stderr**:

```
$ echo "this writes to stderr" 1>&2
```

Test it:

```
$ echo "this writes to stderr" 1>&2 |cat >/dev/null
this writes to stderr
```

(Usually one redirects **stderr** to **stdout** using "`2>&1`"--this is
just the reverse.)
