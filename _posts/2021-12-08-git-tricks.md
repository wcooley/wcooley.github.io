---
tags: git
category: git
title: Git Tricks and Notes
---
## Retrieve Bitbucket and Github Pull Requests

Pull requests aren’t fetched automatically, because they are in a
separate namespace than `refs/heads` – `refs/pull-requests` for
Bitbucket and `refs/pull` for Github. Both also include additional bits
after the PR number; `/from` for Bitbucket and `/head` for Github
(Github also includes a `/merge`, which is the merge commit from merging
`/head` with the branching commit.)

They can be retrieved once with `git fetch` (I am also calling the local
namespace “pr”):

```sh
$ git fetch origin '+refs/pull-requests/*/from:refs/remotes/origin/pr/*'
```

Or they can be added to the remote’s configuration and retrieved with git fetch <remote>:

```sh
$ git config --add remote.origin.fetch '+refs/pull-requests/*/from:refs/remotes/origin/pr/*'
$ git config --local --get-all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
+refs/pull-requests/*/from:refs/remotes/origin/pr/*
```

Then a `git fetch <remote>` will pull down all of the new refs:

```sh
$ git fetch origin
remote: Enumerating objects: 10, done.
remote: Counting objects: 100% (10/10), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 7 (delta 4), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (7/7), 8.07 KiB | 917.00 KiB/s, done.
From ssh://git.oit.pdx.edu:7999/iam/iamportal
 * [new ref]               refs/pull-requests/32/from -> origin/pr/32
 * [new ref]               refs/pull-requests/40/from -> origin/pr/40
```

And `git branch -r` will show the PRs:

```sh
$ git branch -rv
  origin/HEAD                          -> origin/master
...
  origin/master                        2d46e750db Merge branch 'release/2.59.4'
  origin/pr/32                         8b55c09a10 ABC-2260: Remove redundant check
  origin/pr/40                         de50cc18da ABC-2585 Fix tests
```

## Explore Remote Refs Namespace

How can you tell if there are other namespaces in a remote repository, like the `pull-requests`/`pull` from the above section?  The `git ls-remote --refs` command will tell you:

```sh
$ git ls-remote --refs  git@github.com:git/git.git
c6bb019724237deb91ba4a9185fd04507aadeb6a	refs/heads/jch
43c8a30d150ecede9709c1f2527c8fba92c65f40	refs/heads/maint
d0e8084c65cbf949038ae4cc344ac2c2efd77415	refs/heads/master
e5a48246094068e47fb83256e852f17b8c58c7a0	refs/heads/next
7052c9b54d8ffd5fc371e63f9bc280daea1926c1	refs/heads/seen
c6657dee71fda3b9ad48317f304977c70b2af303	refs/heads/todo
d3d558e9824282479562a721e2a2a1cbbcf7c016	refs/notes/amlog
f0d0fd3a5985d5e588da1e1d11c85fba0ae132f8	refs/pull/10/head
c8198f6c2c9fc529b25988dfaf5865bae5320cb5	refs/pull/10/merge
...
```

Tags are included in this list, but you can also list just the tags:

```sh
$ git ls-remote --refs --tags  git@github.com:git/git.git|head
d5aef6e4d58cfe1549adef5b436f3ace984e8c86	refs/tags/gitgui-0.10.0
33682a5e98adfd8ba4ce0e21363c443bd273eb77	refs/tags/gitgui-0.10.1
ca9b793bda20c7d011c96895e9407fac2df9648b	refs/tags/gitgui-0.10.2
8c178f72b54f387b84388d093a920ae45b8659dd	refs/tags/gitgui-0.11.0
...
```

## One-shot Pull Request / Branch Import

(Tested with version 2.31.0.)

If a repository is hosted where you cannot open a pull request directly, your branch can be imported directly without setting up an additional remote using `git fetch` like this:

```sh
    git fetch <url> <remoteref>:<localref>
```

Note that both refs are required for some reason.

Example:

```sh
    git fetch https://github.com/wcooley/docker-grouper.git feature/cleanup-shibd-ld_library_path-r2:wcooley/feature/cleanup-shibd-ld_library_path-r2
```

## Excluding Paths During Search

To exclude files by name or path when doing a `git grep` or `git log` or other similar commands, use `':^<glob>'`

For example, to _not_ match any CSS, JS or SVG files while searching repo history for "foo":

```sh
    git log -Gfoo -- ':^*.css' ':^*.js' ':^*.svg'
```

See [gitglossary(7)](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefpathspecapathspec) for the definition of _pathspec_.
