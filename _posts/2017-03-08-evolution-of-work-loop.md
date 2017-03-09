---
tags: python
category: python
title: Evolution of a Work Loop
---

I have a number of agents that poll for work, sleep and then repeat. They are
structured something like this:

```python
class Agent:
    def run_once(self):
        """Do all the work for a single iteration."""

    def run_loop(self):
        while True:
            self.run_once()
            time.sleep(self.interval)
```

I like to have a command-line option to run through a single iteration and
stop. This is handy for testing, catching up after scheduled downtime, etc.
My first attempt went something like this:

```python
class Agent:
    ...
    def run(self):
        args = self.parse_arguments(sys.argv)
        if args.run_once:
            self.run_once()
        else:
            self.run()
```

Fairly straightforward design -- switch on the command-line argument and then
call either `run_loop` or `run_once`. The problem, though, is that `run_once`
is called from two different places, so all the error handling, logging,
clean-up and other stuff that `run_loop` does has to be pushed up to `run`,
either wholesale or within the `args.run_once` conditional block. It would be
preferable to have `run_loop` run either infinitely or just once. Also,
depending on which, it should sleep at the end or not.

An obvious solution is to implement another function which handles the
conditional iteration, calling `run_once` and sleeping, leaving the error
handling and clean-up in `run_loop`.

A better solution is to use `itertools.repeat` from the Python standard
library. It has two parameters: what value to return repeatedly and how many
times to do it (`None` means repeat infinitely), which conveniently enough,
are the two things that need to be different in our run modes.

Now `run` and `run_loop` look like this, without the need for an intermediate
function:

```python
class Agent:
    ...

    def run(self):
        args = sef.parse_arguments(sys.argv)
        self.run_loop(run_only_once=args.run_once)

    def run_loop(self, run_only_once=None):
        once_or_delay = (0, 1) if run_only_once else (self.interval,)

        for delay in repeat(*once_or_delay):
            self.run_once()
            time.sleep(delay)
```

That's pretty good -- our arguments for `repeat` in the "run only once" case
are 0 delay (sleep) and repeat once; for the "run endlessly" case they are the
delay interval and nothing, which means repeat infinitely.

(There is a difference in sleeping for 0 seconds and not calling sleep at all,
in terms of process scheduling with the operating system, but the distinction
is not important for this case.)

The tuple arguments of `repeat` are not particuarly obvious or
self-documenting; using keyword arguments would be better for that. So for our final revision, let's instead make a `dict`:

```python
class Agent:
    ...

    def run_loop(self, run_only_once=None):
        once_or_delay = {'object': 0, 'times': 1} if run_only_once \
            else {'object': self.interval, 'times': None}

        for delay in repeat(**once_or_delay):
            self.run_once()
            time.sleep(delay)
```

This, I believe, is nearly as concise as the previous version, but the meaning
of the values is more obvious. Compared with the first version, the call to
`run_once` happens in only one place, so there are fewer branches to test and
understand.

Putting it all together, the code ends up looking something like this:

```python
class Agent:
    ...
    def run(self):
        """Initialize agent and start work loop."""
        args = sef.parse_arguments(sys.argv)
        self.run_loop(run_only_once=args.run_once)

    def run_loop(self, run_only_once=None):
        """Run infinitely, handle errors, delay between runs."""
        once_or_delay = {'object': 0, 'times': 1} if run_only_once \
            else {'object': self.interval, 'times': None}

        for delay in repeat(**once_or_delay):
            try:
                self.run_once()
            except:  # More specific exception handling goes here
                log.exception(...)
            time.sleep(delay)

    def run_once(self):
        """Do all the work for a single iteration."""
```
