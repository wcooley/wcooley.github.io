---
tags: python pytest
category: python
title: "Dynamic Fixtures with pytest"
---

### Problem

While developing software using test-driven development (or at least, tightly
integrating development of tests with production code), mocks/stubs are often
used with unit tests for isolation and rapid iteration. Removing the overhead
of the setup and tear-down of running an external database or other expensive
resource makes it bearable to run tests frequently enough to write
confidently.

Once enough of the software works, however, it should be integration-tested
with live (ideally local and rebuilt for every test) resources to ensure that
assumptions made in implementing mocks are valid.

The [_pytest_](http://pytest.org) documentation shows [an example][2] of
simply skipping slow tests based on a command-line parameter (which could
easily be extended to switch between two sets of tests) but having two sets of
tests and fixtures is not very DRY (since the tests themselves are likely the
same or very nearly the same).

### Solution

A better solution, however, would be to switch between using live and mocked
fixture resources. With _pytest_, this is not only possible but fairly easy
(although some digging is required to to figure out) -- the chain of fixtures
can be computed at runtime simply by manipulating the list `fixturenames`,
which is an attribute of the `request` fixture, thereby switching between
using live resources and mocked resources. Making the switch based on a
command-line parameter is also easy.

For example, let's say we have a `mock_database` fixture and a `live_database`
fixture:

```python

import pytest

@pytest.fixture
def mock_database():
    ...

@pytest.fixture
def live_database():
    ...

```

We will also need to add a command-line parameter (which needs to be in the
[top-most `conftest.py`][1]:

```python

def pytest_addoption(parser):
    parser.addoption("--online", action="store_true", default=False,
        help="run tests on-line with live resources")

```

What we need now is a fixture to be the "switch", which is what tests or other
fixtures will use (probably the a more generic name like `database`):

```python

@pytest.fixture
def database(request):
    if request.config.getoption('online'):
        request.fixturenames.append('live_database')
    else:
        request.fixturenames.append('mock_database')

```

And then our tests will use the generic `database` fixture:

```python

def test_lookup(database):
    ...

```



[1]: http://pytest.org/latest/writing_plugins.html#_pytest.hookspec.pytest_addoption

[2]: http://pytest.org/latest/example/simple.html#control-skipping-of-tests-according-to-command-line-option
