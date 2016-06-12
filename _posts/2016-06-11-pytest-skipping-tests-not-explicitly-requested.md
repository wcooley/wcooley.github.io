---
tags: python pytest
category: python
title: "Skipping tests not explicitly requested with pytest"
---

### Problem

_Pytest_ has nice facilities for running subsets of tests based on test names
or markers added to tests. The one downside, however, is that to exclude a
test a keyword or marker must *always* be given. What I would like, however,
is to be able to run certain tests *only* if explicitly requested. The
[documentation][1] shows using a custom command-line parameter to create a
marker that does this, but it feels redundant with the existing `-k` keyword
and `-m` marker facilities.

### Solution (Partial)

With a helper function and ad-hoc parsing of the marker expression, I have been able to
create a mark permits a test to run only if the marker is requested:

```python

from collections import defaultdict

import pytest


def marker_requested(marker, markexpr=None):
    markexpr = markexpr or pytest.config.getoption('markexpr')
    # Ensure that we have a mark expression and that our marker is in it --
    #  otherwise marker_requested(marker="foo", markexpr="not bar") == True
    if not markexpr or marker not in markexpr.split():
        return False
    # This is essentially what _pytest.mark.matchmark does
    return eval(markexpr, {}, defaultdict(lambda: False, {marker: True}))
    

def skip_unless_mark_requested(marker):
    return pytest.mark.skipif(
            not marker_requested('foo'),
            reason='Marker "{}" required'.format(marker)
        )


skip_unless_foo_requested = skip_unless_mark_requested('foo')

@pytest.mark.foo
@skip_unless_foo_requested
def test_foo_really_foo():
    ...

```

What is missing, however, is automatically adding the requested marker itself
to the test; this has to be done in addition to the `skip_unless_...` marker,
which seems redundant.


[1]: http://pytest.org/latest/example/simple.html#control-skipping-of-tests-according-to-command-line-option
