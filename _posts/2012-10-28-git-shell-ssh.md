---
tags: git ssh git-shell
category: git
title: Using git-shell within SSH authorized_keys
---
I was wanting to use an existing account to provide access to Git repos via
SSH. The account was already used to provide Subversion access, so the
`~/.ssh/authorized_keys` already had a number of entries with :

    command="svnserve -t -R -r /path/to/svnrepo",from=...

So I thought I would use `git-shell` to provide restricted access to Git
repositories. After a little trial and error (which I probably could have
avoided if I had thought more carefully about what I was doing), I came up with
the following:

    command="/usr/bin/git-shell -c \"$SSH_ORIGINAL_COMMAND\"",from=...

When a `command=".."` like this is present, the client command is ignored and
the configured command is run, with the original client command being provided
through the environment variable `$SSH_ORIGINAL_COMMAND`.

That seems to work, although it does not restrict access to any particular
repository. For that, I will probably have to look in to gitosis or gitolite.

Posted: {{ page.date | date_to_string }}

