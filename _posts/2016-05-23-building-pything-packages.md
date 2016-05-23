---
tags: python
category: python
title: "Building Python Packages"
---

### Building Wheels as Tagged Pre-releases

It's obvious if you actually [read the docs](
https://pythonhosted.org/setuptools/setuptools.html#tagging-and-daily-build-or-snapshot-releases),
but if you tend to skim when you hit a wall of text when you really need to do
something else:


```python
setup.py egg_info --tag-build="$(git describe --long)" bdist_wheel
```

What is not obvious, to me anyway, is that `setup.py` can have multiple
commands on a single invocation.
