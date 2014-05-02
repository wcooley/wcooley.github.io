---
layout: default
tags: application
category: application
title: "Application Notes: amavisd-new"
---
# Amavisd-new Notes

 * See our paper, [http://nakedape.cc/products/packages/maildefender/paper Defending E-mail Users from Spam and Viruses]

## Disable SpamAssassin

Should you want to disable SpamAssassin, uncomment the line in `amavisd.conf`:

```
@bypass_spam_checks_acl  = qw( . );  # uncomment to DISABLE anti-spam code
```


## Virus Notifications

Mark posted a recipe for a `$viruses_that_fake_sender_re` that only sends
notifications for the few viruses that *don't* fake the sending address.

```
$viruses_that_fake_sender_re = new_RE(
    qr'@mm',  # mass mailing viruses as labeled by f-prot
    [qr'^(EICAR\.COM|Joke\.|Junk\.)'i     => 0],
    [qr'^(WM97|OF97|W95/CIH-|JS/Fort)'i   => 0],
    [qr/.*/ => 1],   # true by default!
);
```

## Nano-HOWTO for Regular Expressions

Some comments about regular expressions I wrote up while explaining to a
customer how to modify the `$banned_filename_re`.

```
$banned_filename_re = new_RE(
  qr'\.[a-zA-Z][a-zA-Z0-9]{0,3}\.(vbs|pif|scr|bat|com|exe|dll)$'i, # double extension
  qr'.\.(ade|adp|bas|bat|chm|cmd|com|cpl|crt|exe|hlp|hta|inf|ins|isp|js|
         jse|lnk|mdb|mde|msc|msi|msp|mst|pcd|pif|reg|scr|sct|shs|shb|vb|
         vbe|vbs|wsc|wsf|wsh)$'ix,                  # banned extension - long
  qr'^\.(exe|lha|tnef)$'i,                      # banned file(1) types
  qr'^application/x-msdownload$'i,                  # banned MIME types
  qr'^message/partial$'i, qr'^message/external-body$'i, # rfc2046
);
```

* Each line is a Perl *quoted regular expression*, delimited by `qr'` and ending with `'`.
* The list of patterns are a logical *OR*--if any line matches, the whole thing matches.
* *Regular expressions* are a pattern-matching mini-language, like DOS or UNIX
  wildcards but more powerful.
* The `i` and `x` at the end of some of the patterns are flags; the `i` makes
  the match case-insensitive and the `x` lets you put in whitespace that's not
  matched.
* A group of things to match any one of is done with:

    ```
    (foo|bar|baz)
    ```

* If you want to add 'bat' to the group to match, it would be something like
 this, although you don't have to put it at the end:

    ```
    (foo|bar|baz|bat)
    ```

* A dot `.` matches any single character; to match only a dot, escape it with a
backslash: `\.`.
* A caret `^` anchors the pattern at the beginning and a dollar-sign `$`
anchors it at the end.

* Brackets `[` and `]` indicate a *character class*, which may be a range such
as `[A-Z]` or a list of characters such as `[xyz]`.  A character class
matches **one** character without a count qualification.

* Braces `{` and `}` indicate a count of the previous pattern to match; it can
be a comma-delimited range such as `{0,3}` or a single number `{2}`.  For
example, the following matches 1 or 2 combinations of *A* or *B*:

    ```
    [AB]{1,2}
    ```
