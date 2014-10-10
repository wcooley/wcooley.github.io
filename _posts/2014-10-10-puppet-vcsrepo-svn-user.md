---
layout: default
tags: puppet vcsrepo svn
category: puppet
title: "Managing Subversion w/vcsrepo with Non-root Remote Users"
---

Goal
----

We wish to use `vcsrepo` in Puppet to check out a Subversion repository with a
non-root remote user and custom SSH key pair.

Trouble
-------

Despite the fact that `vcsrepo` happily accepts the `user` parameter (and does
not complain about the `identity` parameter except in debug), it does not
actually *use* either, so the `svn` command runs as *root* and uses root's SSH
keys.

Solution
--------

All is not lost, however; Subversion allows for custom protocol tunnel schemes
in `~/.subversion/config`, which allow us to specify the SSH command, with
which we can specify the remote user and identity file:

```ini
[tunnels]
ssh_user_<remote_user> = $SVN_SSH ssh -q -l <remote_user> -o IdentityFile=<ssh_identity_file>
```

Now when specifying the `source` parameter to the `vcsrepo` resource, we can
use **`svn+ssh_user_<remote_user>`** as the protocol part of the repository
URL.

If we want to keep this under the account of a different local user, we can
use `vcsrepo`'s `configuration` parameter to point to `~/.subversion`:

```puppet
vcsrepo { '<local_repo>':
  ensure        => 'latest',
  provider      => 'svn',
  owner         => '<local_user>',
  group         => '<local_group>',
  user          => '<local_user>',
  source        => 'svn+ssh_user_<remote_user>://<svn_host>/<repo_path>',
  configuration => '/home/<local_user>/.subversion/config',
}
```

In Puppet
---------

Since the `~/.subversion/config` file is an *ini*-format file, we can use the
`ini_setting` type from
[*puppetlabs/inifile*](https://forge.puppetlabs.com/puppetlabs/inifile)
module to put it into place.

```puppet
ini_setting { '/home/<local_user>/.subversion/config/tunnels/ssh_user_<remote_user>':
  path    =>  '/home/<local_user>/.subversion/config',
  section => 'tunnels',
  setting => 'ssh_user_svn',
  value   => '$SVN_SSH ssh -q -l svn -o IdentityFile=/home/<local_user>/.ssh/id_rsa',
}
```

We also want to ensure that the `ini_setting` is in place before the `vcsrepo`
is applied. We could use either the `require` or `before` metaparameters or
resource chaining, but if we have multiple `vcsrepos`, explicitly listing each
one would be tedious; applying to all repos would also catch `git` repos,
which is unnecessary. Instead, we can use [resource
collectors](https://docs.puppetlabs.com/puppet/latest/reference/lang_collectors.html)
to select just the appropriate `vcsrepo` resources:

```puppet
Ini_setting['/home/<local_user>/.subversion/config/tunnels/ssh_user_<remote_user>']
 -> Vcsrepo <| user == '<remote_user>' and provider == 'svn' |>
```

Migration
---------

If the working copy already exists (for example, perhaps it was being managed
with an `exec` resource), then the URL of the working copy will be different
and `vcsrepo` won't fix it. A simple `svn switch --relocate` with the
repository root will fix it:

```bash
local_user$ svn info |grep Root
Repository Root: svn+ssh://<svn_host>/<repo_path>
$ svn switch --relocate 'svn+ssh://<svn_host>/<repo_path>' \
        'svn+ssh_user_<remote_user>://<svn_host>/<repo_path>'
```
