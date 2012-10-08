---
title: Keeping Rolling State
category: splunk
tags: splunk state inputlookup outputlookup
layout: default
---

Having been inspired by the Splunk blog post [Maintaining State of the
Union][splunk_state], I have been following this pattern of running frequent
searches with short time-bounds, merging the results with a stored table and
writing the table back out again. One of the interesting but less
broadly-applicable bits of that article is keeping track of open connections
and removing them when a close event is logged.

{% highlight bash linenos %}
    eventtype=sendmail_message_sent OR eventtype=postfix_message_sent
    | eval recip_domain=lower(recip_domain)
    | eval relay_name=lower(relay_name)
    | dedup relay_name, recip_domain
    | eval last_seen=_time
    | inputlookup append=t smtp_relays.csv
    | where last_seen > relative_time(now(), "-24h")
    | sort -last_seen
    | dedup relay_name, recip_domain
    | table relay_name, recip_domain, last_seen
    | outputlookup smtp_relays.csv
{% endhighlight %}

[splunk_state]: http://blogs.splunk.com/2011/01/11/maintaining-state-of-the-union/
