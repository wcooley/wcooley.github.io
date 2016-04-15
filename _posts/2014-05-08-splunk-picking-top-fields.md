---
tags: splunk
category: splunk
title: Picking top fields for reporting
---
Background
----------

While working with events from my [Puppet cimlog report processor]
(https://github.com/wcooley/puppet-cimlog), I wanted to graph the average times
that the various resources took to apply. The events look like this:

```
May  8 13:16:22 hera puppet-master[22740]: [cimlog/metrics] dest=zeus
event_id=1399580198 category="time" units="seconds"
rtime_augeas="0.020" rtime_config_retrieval="5.370" rtime_cron="0.002"
rtime_exec="2.334" rtime_file="3.180" rtime_file_line="0.000"
rtime_filebucket="0.000" rtime_group="0.028" rtime_name_service="0.001"
rtime_package="0.082" rtime_service="0.888" rtime_ssh_authorized_key="0.010"
total="11.974" rtime_user="0.040" rtime_yumrepo="0.016"
```

There is an `rtime_` field for every managed resource type plus config
retrieval. As this is just a single event from a single node, there are only
just over a dozen resource types. Across all of my systems, however, there are
more than twice as many.

Twelve fields on a timechart is verging on unusable and at some point
`timechart` truncates data based on limits, so what is really wanted is the
ability to select just the top *N* fields for `timechart` to graph. This could
be done manually, of course, but it seems better to let the computers do the
work.

To solve this problem, there are several steps to go through:

1. Find the desired events.
1. Figure out the top fields to graph.
1. Extract the field names.
1. Parameterize `timechart` with those fields.

Step 1: Find desired events
===========================

We start with a base search that finds events like the one above:

    eventtype=puppet_cimlog_metrics category=time

This uses an *eventtype* defined in my [Puppet Pulse Splunk app]
(https://github.com/wcooley/splunk-puppet); there is nothing special about it,
searching for "puppet-master cimlog/metrics" would work as well.  As these
searches build upon one another and as it gets fairly long, I will not
reproduce them in full, instead relying upon "...".

Step 2: Figure out top fields
=============================

We could use either `sum` or `avg` to order the fields (or others, depending on
what characteristic is important); which we choose is not important for the
general technique. In this example, we will use `sum` with a wildcard parameter
and rename:

```
... | stats sum(rtime_*) AS rtime_*
```

The wildcard parameter expands to *sum(rtime_anchor) sum(rtime_augeas) ...* and
the field rename just works as you would hope.

This results in a single row, with each column the sum of the values for a field:

```
   rtime_anchor rtime_augeas    rtime_class ...
1   0.191       670.672         0.037       ...
```

To get the top 5 fields, we use the `transpose` command, `sort` the results
descending, and take the `head` 5:

```
... | transpose | sort - "row 1" | head 5
```

This results in a 2-column, 5-row table with the event fields in the column
labeled **column** and the sums in the column labeled **row 1**:

```
    column                  row 1
1   rtime_file              191435.696
2   rtime_config_retrieval  21584.646
3   rtime_exec              7539.561
4   rtime_service           7375.801
5   rtime_vcsrepo           999.498
```

Step 3: Extract the field names
===============================

It would seem that now we would just need to throw away "row 1" with the
`fields` command and feed the result to a timechart from a subsearch, but
things are a little more complicated than that. A subsearch performs an
implicit `format` on the results, so that the column name becomes a field name
and the row data becomes possible values, all ORed together. If we try it, we
get the following:

```
...  | fields column | format

    column  search
1           ( ( column="rtime_file" ) OR ( column="rtime_config_retrieval" ) OR
                ( column="rtime_exec" ) OR ( column="rtime_service" ) OR
                ( column="rtime_vcsrepo" ) )
```


We want to get rid of the "column" as a field and use the values directly as
search parameters and to do that we rename "column" to "query" (this is magical
but it is in the docs, somewhere):

```
... | fields column | rename column AS query | format

    query   search
1           ( ( rtime_file ) OR ( rtime_config_retrieval ) OR ( rtime_exec ) OR
                ( rtime_service ) OR ( rtime_vcsrepo ) )
```

Now we want to get rid of the parentheses and ORs, which we can do by
overriding `format` with 6 empty strings:

```
... | format "" "" "" "" "" ""

    query   search
1           rtime_file rtime_config_retrieval rtime_exec rtime_service rtime_vcsrepo
```

We now have just the field names, but we cannot feed these directly to
`timechart` -- `timechart` requires a function around each of these. To do
that, we must go back a few steps to take advantage of our wildcard renaming.
Instead of renaming the fields to be just the field names, we will rename them
to be the field names with "**avg(**" and "**)**" around them:

```
... | stats sum(rtime_*) AS avg(rtime_*) | ...

    query   search
1           "avg(rtime_file)" "avg(rtime_config_retrieval)" "avg(rtime_exec)"
                "avg(rtime_service)" "avg(rtime_vcsrepo)"
```

Now we have results that can be fed to `timechart` to get useful values!

Here is the complete final search after all of the afforementioned
transformations:

```
eventtype=puppet_cimlog_metrics category=time \
| stats sum(rtime_*) AS avg(rtime_*) \
| transpose \
| sort - "row 1" \
| head 5 \
| fields column \
| rename column AS query \
| format "" "" "" "" "" ""
```

Step 4: Parameterize timechart with the fields
==============================================

Finally, we use the previous search in a subsearch as the parameters to
`timechart`, fed by the same search that we used in the subsearch:

```
eventtype=puppet_cimlog_metrics category=time \
| timechart [ search eventtype=puppet_cimlog_metrics category=time \
            | stats sum(rtime_*) AS avg(rtime_*) \
            | transpose \
            | sort - "row 1" \
            | head 5 \
            | fields column \
            | rename column AS query \
            | format "" "" "" "" "" "" \
            ]
```

Further work
============

Instead of performing the same search twice, one might want to use a summary
index to calculate the top fields or use a scheduled search writing out the top
fields to a CSV.

Initially I thought that `format` could be used to wrap "**avg(...)**" around
the field names, but it puts spaces between the values and the parentheses and
`timechart` does not appear to trim whitespace from the variable names, so this
does not work. One could possibly use `eval` to remove the extra spaces, but
the rename seems cleaner.

Of course, if you do not use a different function for `stats` and `timechart`,
it can pass through without any renaming.
