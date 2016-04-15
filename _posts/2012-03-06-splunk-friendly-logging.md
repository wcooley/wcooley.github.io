---
tags: splunk
category: splunk
title: Splunk-Friendly Logging
---
# Splunk-Friendly Logging

One of Splunk's built-in field extraction rules creates fields where it finds
**key=value** pairs. As you might expect, log events with such data result in a
field called **key** with value **value**.

A few points to keep in mind:

* Take care to not name any of your extracted fields in the body of the event
with the same name as the built-in fields, such as **host** or **source**.
**node** and **fqdn** are good choices for the short and fully-qualified
names of hosts, for example.  Depending on the situation, **client** or
**clientip** might be a good choice.

* If **value** has neither whitespace nor any of the following delimiters: ```
 , ; $ |``` then it can be used as-is. Using other punctuation seems to be ok and
does not result in the value being split at the character.

* If there any of the characters mentioned in the previous, enclose them in
**double** quotes. Enclosing them in double quotes results in a field value
that is the string without the quotes; enclosing them in single quotes
results in a field value that includes the single quotes.

* The usual "container" punctuation is extracted as a unit if possible;
 otherwise it does not cause segmentation of the value.

* Everything that I have said above could be rendered untrue with changes to
the configuration. Probably best to be as safe as possible and enclose any
obviously non-word in double quotes.

* I have not found a built-in separator to automatically make a multivalued
field; however, it is easy to use the [***makemv***][1] command to do so. For
example, given data like **list="one,two,three"**, the following will results
in three **list** fields:

  ```
  list="one,two,three" | makemv delim="," list
  ```

* Splunk has a document about the **Common Information Model**; it is perhaps
more detailed than necessary, but you get the idea: [Understand and use the
Common Information Model][2].

[1]: http://docs.splunk.com/Documentation/Splunk/latest/SearchReference/Makemv
[2]: http://docs.splunk.com/Documentation/Splunk/latest/Knowledge/UnderstandandusetheCommonInformationModel
