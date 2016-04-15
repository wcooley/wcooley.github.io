---
title: Keeping Rolling State
category: splunk
tags: splunk state inputlookup outputlookup
---
Having been inspired by the Splunk blog post [Maintaining State of the
Union][splunk_state], I have been following this pattern of running frequent
searches with short time-bounds, merging the results with a stored table and
writing the table back out again. One of the interesting but less
broadly-applicable bits of that article is keeping track of open connections
and removing them when a close event is logged. A more general example might
have been to expire old entries based on a stored timestamp.

The following search does just that--it retains the relay name & recipient
domain pair for 24 hours. This is a search I have recently put into use.

{% highlight bash linenos %}
    eventtype=sendmail_message_sent OR eventtype=postfix_message_sent
    | eval recip_domain=lower(recip_domain)
    | eval relay_name=lower(relay_name)
    | dedup relay_name, recip_domain
    | eval last_seen=_time
    | inputlookup append=t smtp_relays.csv
    | where last_seen > relative_time(now(), "-24h")
    | dedup relay_name, recip_domain sortby -last_seen
    | fields relay_name, recip_domain, last_seen
    | fields - _*
    | outputlookup smtp_relays.csv
{% endhighlight %}

This is a more complex search than necessary for pedagogical purposes, so let's
try one a little simpler that should also work out of the box, without my
defined eventtypes and field extractions. This one will just maintain a list of
hosts and sourcetypes that have been seen with those sourcetypes.

{% highlight bash linenos %}
    host=* sourcetype=*
    | dedup host, sourcetype
    | eval last_seen=_time
    | inputlookup append=t host_sourcetypes.csv
    | where last_seen > relative_time(now(), "-24h")
    | dedup host, sourcetype sortby -last_seen
    | fields host, sourcetype, last_seen
    | fields - _*
    | outputlookup host_sourcetypes.csv
{% endhighlight %}

Let's walk through this line by line. The first line obviously finds all events
that have both host and sourcetype (which should be all events, since Splunk
add those at index time). The _dedup_ removes all but the latest unique pairs
of &lt;host, sourcetype&gt;. While not strictly necessary, this dedup helps
performance considerably as it gives us a small working set of data, so that
later when we merge, sort and dedup again, we're only doing it over the handful
of unique pairs instead of all of the events.

The fourth line loads the data from *host\_sourcetypes.csv*; this will cause a
warning the first time it is run because the input file does not exist yet.
Next the _where_ removes all events that are older than 24 hours. Finally, we
dedup sort and dedup the results again. Any pairs that have newer events are
updated, any pairs that were older than 24 hours are dropped and any pairs that
were new are added.

On the third line we copied the *\_time* to *last_seen*, so that in line 8 we
could throw away all fields that start with underscore because they are
retained by default with the *fields* command on line 7.

Finally, we write it all back out to the lookup file *host_sourcetypes.csv*.

Posted: {{ page.date | date_to_string }}

[splunk_state]: http://blogs.splunk.com/2011/01/11/maintaining-state-of-the-union/
