---
tags: git
category: git
title: Git Tricks and Notes
---

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
