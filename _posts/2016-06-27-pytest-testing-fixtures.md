---
tags: python pytest
category: python
title: Testing Pytest Fixtures
---

For test fixtures of much complexity (particularly ones intended to be
shared and packaged as a plug-in), testing is essential. The short ["Testing
plugins"](http://pytest.org/latest/writing_plugins.html#testing-plugins)
section of the "Writing plugins" chapter of the pytest manual is
mostly adequate, but could be improved upon.

For example, it might be easier to understand failures of a fixture test by
running it as a normal test, rather than through `testdir.runpytest`, so we
might first just write a normal test:


```python
import uuid as uuid

def test_uuid_pattern(uuid_pattern):
    """Test :func:`uuid_pattern`."""
    good_uuid = str(uuid.uuid1())
    assert uuid_pattern.match(good_uuid)
    ...
```

Now the fixture should be tested by running it with `testdir.runpytest` but
rather than re-writing the test as a string for `testdir.makepyfile`, use the
built-in `inspect` module to get the source of the test as a string with the
`getsource` function:

```python
import inspect

pytest_plugins = 'pytester'

def test_uuid_pattern_fixture(testdir):
    """Test :func:`uuid_pattern`."""
    testdir.makepyfile(inspect.getsource(test_uuid_pattern))
    result = testdir.runpytest('--verbose', plugins=['no:sugar'])
    result.stdout.fnmatch_lines([
        '*::test_uuid_pattern PASSED',
    ])
    assert result.ret == 0
```

Note that I have expressly disabled the _pytest-sugar_ plugin; because it
changes the test report output, it messes up this test. It seems like it
should be able to detect situations like this and disable itself but it does
not. If _pytest-sugar_ is not used, this can be elided. (A better solution
might be to examine a structured report of the test run, such as the JUnit XML
or `--report-log=xxx`, or perhaps use _RunResult.assert\_outcomes_).
