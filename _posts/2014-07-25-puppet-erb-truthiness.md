---
tags: puppet erb ruby
category: puppet
title: "Puppet: Truthiness in ERB Templates"
---

Conversion between Puppet variables and Ruby variables in ERB is not always
obvious and, in one notable way, inconsistent. Notably, an empty string is
*false* in the Puppet language, but *true* in Ruby (and ERB).

The following is a Puppet manifest that can be "run" with `puppet apply xxx/puppet-truthiness.pp`:

``` puppet
{% include source/puppet-truthiness.pp %}
```

And the following is the resulting output:

```
{% include source/puppet-truthiness-output.txt %}
```
