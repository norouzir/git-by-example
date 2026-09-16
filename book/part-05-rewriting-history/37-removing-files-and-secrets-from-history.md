# Chapter 37. Removing Files and Secrets from History

## What it is

A file that was committed once is in the repository for ever, even after a
later commit deletes it. Every clone has it. This chapter is about getting it
out, and about how much of "out" is actually achievable.

It answers one question: *I committed something that should never have been
committed. How do I make it not be there?*

The honest answer has two halves. Inside your own repository the file can be
removed completely, and this chapter shows how. Outside it — on the server, in
other people's clones, in a fork, in a build cache — it cannot, and the only
real remedy is to make the secret worthless.

| Term | Means |
|---|---|
| *rewriting every commit* | replacing the whole history with commits that never had the file, which changes every hash after the first affected one |
| *`git filter-branch`* | Git's own tool for that, shipped with Git and marked as not recommended by its own documentation |
| *`git filter-repo`* | the tool Git's documentation points at instead; a separate program, not part of Git |
| *`refs/original/`* | where `filter-branch` keeps the pre-rewrite refs |
| *unreachable* | an object nothing points at; still present until it is pruned (Chapter 28) |
| *rotate* | replace a secret with a new one, so the old value no longer opens anything |

> **Careful.** This is the most destructive chapter in the book. Every
> technique here rewrites published history, which is the thing Chapter 28 is
> about. Read that first if you have not, and make a copy of the repository
> before you start: `cp -r project project-backup` costs nothing and has saved
> a lot of people.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [I committed a password. What are my options?](#what-it-is)
- [Why is deleting the file in a new commit not enough?](#what-it-is)

**[Before anything else](#before-anything-else)**

- [The secret is in a commit I already pushed. What is the first thing to do?](#before-anything-else)
- [If I rewrite history fast enough, do I still have to change the password?](#before-anything-else)

**[Which case are you in](#which-case-are-you-in)**

- [Which of these methods applies to my situation?](#which-case-are-you-in)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)
- [How do I see that the file is still there after it was deleted?](#the-file-is-still-in-every-clone)

**[It is not committed yet](#it-is-not-committed-yet)**

- [The file is staged but not committed. How do I get it out?](#it-is-not-committed-yet)

**[It is in the last commit](#it-is-in-the-last-commit)**

- [How do I remove a file from the commit I just made?](#it-is-in-the-last-commit)

**[It is everywhere: filter-branch](#it-is-everywhere-filter-branch)**

- [How do I remove a file from every commit in the repository?](#it-is-everywhere-filter-branch)
- [What is `--index-filter`, and why not `--tree-filter`?](#it-is-everywhere-filter-branch)
- [What would `--tree-filter` have looked like?](#the-slow-way)
- [Why does my filter fail on the commits where the file does not exist?](#it-is-everywhere-filter-branch)
- [Do tags and other branches get rewritten too?](#it-is-everywhere-filter-branch)
- [What is this warning it prints before it starts?](#what-filter-branch-says-before-it-starts)

**[The original refs](#the-original-refs)**

- [The rewrite finished but the old commits are still reachable. Why?](#the-original-refs)
- [What is `refs/original/` and do I delete it?](#the-original-refs)

**[Making the old objects go away](#making-the-old-objects-go-away)**

- [Which commands actually delete the old objects?](#making-the-old-objects-go-away)
- [Why does `git gc` keep them anyway?](#making-the-old-objects-go-away)

**[Checking it is really gone](#checking-it-is-really-gone)**

- [How do I prove the file is no longer in any commit?](#checking-it-is-really-gone)
- [How do I search every object in the repository for a string?](#checking-it-is-really-gone)

**[The same thing with filter-repo](#the-same-thing-with-filter-repo)**

- [Git's documentation tells me to use `git filter-repo`. What is it and where does it come from?](#the-same-thing-with-filter-repo)
- [What does it do that `filter-branch` does not?](#the-same-thing-with-filter-repo)
- [Why did it delete my `origin` remote?](#the-same-thing-with-filter-repo)
- [How do I remove a string rather than a whole file?](#removing-by-content-rather-than-by-name)
- [How do I find out what is big or what is in there before I decide?](#analysing-first)

**[Other filters](#other-filters)**

- [How do I change an email address in every commit?](#other-filters)
- [How do I edit every commit message?](#other-filters)
- [How do I make a subdirectory into the root of the repository?](#other-filters)

**[What the rewrite does not reach](#what-the-rewrite-does-not-reach)**

- [I rewrote and force-pushed. Why is the secret still on the server?](#what-the-rewrite-does-not-reach)
- [What about forks, open pull requests, and people's clones?](#what-the-rewrite-does-not-reach)

**[Pushing the rewrite](#pushing-the-rewrite)**

- [How do I push a rewritten history, and what do I tell everyone else?](#pushing-the-rewrite)

**[Keeping it from happening again](#keeping-it-from-happening-again)**

- [How do I stop the next secret being committed?](#keeping-it-from-happening-again)
- [Why did `git add` refuse, and how did `-f` get past it?](#keeping-it-from-happening-again)

**[Which tool for which job](#which-tool-for-which-job)**

- [One table: my situation, the command, and what it costs.](#which-tool-for-which-job)

**[The settings](#the-settings)**

- [Which settings and environment variables matter here?](#the-settings)

</details>

## Before anything else

**Change the secret.** Not after the rewrite; now, before you read the rest of
this chapter.

A key that has been in a repository for even a minute must be treated as known.
It has been on a server, in fetches, in backups, in build logs, in editors, in
the caches of anything that mirrors the repository, and — if the repository is
public — in the databases of the people who scan public repositories for keys,
which is a thing that happens within seconds and automatically.

Rewriting history is worth doing afterwards: it stops the secret spreading
further, and it stops the next person who clones from finding it. It is not a
containment measure, because you cannot know who already has it.

| Secret | What "rotate" means |
|---|---|
| A password | change it |
| An API token or deploy key | revoke it and issue a new one |
| A private key | generate a new pair and replace the public half everywhere |
| A database credential | change it, and check the logs for use you did not make |
| Customer data | this is a different kind of problem; tell whoever handles that |

Everything below assumes that has been done.

## Which case are you in

| Where the file is | What to do | Cost |
|---|---|---|
| Staged, not committed | `git rm --cached` | nothing |
| In the last commit only | `git rm --cached` and `git commit --amend` | one commit changes |
| In the last few commits, not pushed | `git rebase -i` and edit those commits | those commits change |
| Anywhere else, or pushed | rewrite every commit | every hash changes; everyone re-clones |

The last row is the expensive one, and the rest of this chapter is about it.
The cost is not the command — it is that every commit after the first affected
one gets a new hash, so every clone, every open pull request and every
reference to a commit by hash becomes wrong (Chapter 28).

## The example repository

```console
$ git log --oneline --decorate
c8e3f88 (HEAD -> main, origin/main) Add some notes
64e2fcf Remove the deploy key
e856524 (tag: v1.0) Add the documentation
915fbf9 Add the deploy script
01e1692 Add the deploy key
05dc719 Add the config
939a3a4 Start the service
$ ls
README.md
config.yml
deploy.sh
docs
notes.md
```

A small service. `deploy.pem`, a private key, was committed in `Add the deploy
key`, noticed later, and deleted in `Remove the deploy key`. The working tree
is clean: `ls` does not show it.

There is a tag, `v1.0`, on a commit that still contains the key, and an
`origin` — a bare repository the whole thing has been pushed to.

### The file is still in every clone

```console
$ git log --oneline --all -- deploy.pem
64e2fcf Remove the deploy key
01e1692 Add the deploy key
$ git show v1.0:deploy.pem
-----BEGIN PRIVATE KEY-----
s3cret-do-not-share
-----END PRIVATE KEY-----

# The file is still in every clone
$ git rev-list --objects --all | grep deploy.pem
091428c353e20bd3c5896e55aa3b5951796fce7e deploy.pem
```

Three ways to see the same thing. `git log -- <path>` lists the commits that
touched it, deletion included. `git show <commit>:<path>` prints the file as it
was, and anyone with the repository can run it. `git rev-list --objects --all`
walks every object every ref reaches and names the blob.

That last command is the one to remember: it is how you check, later, whether
the removal worked.

## It is not committed yet

```console
$ git add secret.env && git status --short
A  secret.env
$ git rm --cached -q secret.env && git status --short
?? secret.env
$ git add .gitignore && git status --short
A  .gitignore
```

The easy case. `git rm --cached` takes the file out of the index and leaves it
on disk (Chapter 15), so nothing was ever committed and there is nothing to
rewrite. `git restore --staged secret.env` does the same job (Chapter 14).

Adding it to `.gitignore` in the same breath is what stops it coming back with
the next `git add -A`.

## It is in the last commit

```console
$ git add -A && git commit -q -m 'Add the settings' && git show --stat --oneline HEAD
556efa3 Add the settings
 secret.env  | 1 +
 settings.md | 1 +
 2 files changed, 2 insertions(+)
$ git rm --cached -q secret.env && git commit -q --amend --no-edit && git show --stat --oneline HEAD
dac6897 Add the settings
 settings.md | 1 +
 1 file changed, 1 insertion(+)
$ git log --all --oneline -- secret.env
```

Remove it from the index, amend, and the commit no longer contains it
(Chapter 29). `git log -- secret.env` finds nothing: no commit in the
repository mentions the file.

The *blob* is still there, unreferenced, until it is pruned — see [Making the
old objects go away](#making-the-old-objects-go-away) — and that is enough to
worry about only if the repository has already been pushed. If it has,
amending is a rewrite like any other and Chapter 28 applies.

> **Careful.** If the commit has been pushed, stop and read
> [Before anything else](#before-anything-else) again. The file was on the
> server.

## It is everywhere: filter-branch

```console
$ git filter-branch --index-filter 'git rm --cached --ignore-unmatch deploy.pem' --prune-empty --tag-name-filter cat -- --all
WARNING: git-filter-branch has a glut of gotchas generating mangled history
	 rewrites.  Hit Ctrl-C before proceeding to abort, then use an
	 alternative filtering tool such as 'git filter-repo'
	 (https://github.com/newren/git-filter-repo/) instead.  See the
	 filter-branch manual page for more details; to squelch this warning,
	 set FILTER_BRANCH_SQUELCH_WARNING=1.
Proceeding with filter-branch...

...
Ref 'refs/heads/main' was rewritten
Ref 'refs/remotes/origin/main' was rewritten
WARNING: Ref 'refs/remotes/origin/main' is unchanged
Ref 'refs/tags/v1.0' was rewritten
v1.0 -> v1.0 (e856524879a286570f80639d075b56aa5fde2980 -> 476acd87abf7c71928867930c0138f3277c58839)
$ git log --oneline --decorate
54faa62 (HEAD -> main, origin/main, origin/HEAD) Add some notes
476acd8 (tag: v1.0) Add the documentation
dbb23c5 Add the deploy script
05dc719 Add the config
939a3a4 Start the service
$ git log --oneline --all -- deploy.pem
64e2fcf Remove the deploy key
01e1692 Add the deploy key
$ git show v1.0:deploy.pem
fatal: path 'deploy.pem' does not exist in 'v1.0'
```

One command, and every commit in the repository is rebuilt without the file.
Seven commits became five: `Remove the deploy key` had nothing left to do once
the key was never added, and `--prune-empty` dropped it.

`git log --all -- deploy.pem` still finds two commits, and that is not a
failure: `--all` includes the old refs `filter-branch` keeps, which the next
section is about.

The progress lines are cut here with `...`; they name each commit as it is
rewritten and include a time estimate, which is why they are not reproduced.

Reading the command from the inside out:

| Part | Does |
|---|---|
| `--index-filter '<command>'` | run `<command>` against the index of each commit |
| `git rm --cached` | remove the file from that index (Chapter 15) |
| `--ignore-unmatch` | do not fail on the commits where the file is not there |
| `--prune-empty` | drop commits that end up changing nothing |
| `--tag-name-filter cat` | rewrite tags too, keeping their names |
| `-- --all` | everything after `--` goes to `git rev-list`; `--all` means every ref |

**`--index-filter` rather than `--tree-filter`.** Both can remove a file.
`--tree-filter` checks out every commit into a temporary directory, runs your
shell command there, and commits the result, which is correct and extremely
slow. `--index-filter` works on the index alone and never touches the working
tree, which is why Git's documentation calls it "significantly faster" and why
it is the form everyone uses for this job.

**`--ignore-unmatch` is not optional.** Without it, `git rm` fails on the
commits from before the file existed, and a filter that exits non-zero aborts
the whole run.

**`--tag-name-filter cat` is easy to forget.** Without it the rewrite happens
and the tag still points at the old commit — which keeps that commit, and the
file in it, alive and reachable for ever. `cat` as the filter means "use the
same name". Git's documentation warns that tag objects are rewritten but any
signature on them is stripped, because a signature cannot survive.

### The slow way

```console
$ git filter-branch --tree-filter 'rm -f deploy.pem' --prune-empty -- --all 2>&1 | tail -3
Ref 'refs/tags/v1.0' was rewritten
WARNING: You said to rewrite tagged commits, but not the corresponding tag.
WARNING: Perhaps use '--tag-name-filter cat' to rewrite the tag.
$ git log --oneline --all -- deploy.pem
64e2fcf Remove the deploy key
01e1692 Add the deploy key
$ git log --oneline
54faa62 Add some notes
476acd8 Add the documentation
dbb23c5 Add the deploy script
05dc719 Add the config
939a3a4 Start the service
```

`--tree-filter` does the same job with an ordinary `rm`, because the command
runs in a checkout of each commit: no `git rm --cached`, no `--ignore-unmatch`,
because `rm -f` does not mind a file that is not there. It is the easier form
to write and the one to avoid, because checking out every commit is slow — on a
repository with years of history that is the difference between a minute and an
afternoon.

Note what `git log --all` still finds. The rewrite worked — the current history
has five commits and none of them has the file — but `--all` includes
`refs/original`, which is still holding the old commits. That is
[The original refs](#the-original-refs) again, and it is why the check that
matters is the one run *after* they are deleted.

### What filter-branch says before it starts

```console
$ git filter-branch --index-filter 'git rm --cached --ignore-unmatch nothing.txt' HEAD 2>&1 | head -12
WARNING: git-filter-branch has a glut of gotchas generating mangled history
	 rewrites.  Hit Ctrl-C before proceeding to abort, then use an
	 alternative filtering tool such as 'git filter-repo'
	 (https://github.com/newren/git-filter-repo/) instead.  See the
	 filter-branch manual page for more details; to squelch this warning,
	 set FILTER_BRANCH_SQUELCH_WARNING=1.
Proceeding with filter-branch...

...
```

Git prints this before every run and waits a few seconds, so that you have a
chance to stop. It is not boilerplate: the manual page has a whole SAFETY
section listing the ways `filter-branch` produces a history that is subtly
wrong, and the command is effectively deprecated in favour of `filter-repo`.

`FILTER_BRANCH_SQUELCH_WARNING=1` in the environment turns it off, which is for
scripts that have already accepted the risk.

## The original refs

```console
$ git for-each-ref refs/original
c8e3f88d6dd2399842a6405dfd28e8775c362bdf commit	refs/original/refs/heads/main
c8e3f88d6dd2399842a6405dfd28e8775c362bdf commit	refs/original/refs/remotes/origin/main
e856524879a286570f80639d075b56aa5fde2980 commit	refs/original/refs/tags/v1.0
$ git log --oneline -1 refs/original/refs/heads/main
c8e3f88 Add some notes
$ git show refs/original/refs/heads/main~2:deploy.pem
-----BEGIN PRIVATE KEY-----
s3cret-do-not-share
-----END PRIVATE KEY-----
```

The rewrite is done and the key is still readable, because `filter-branch`
keeps every original ref under `refs/original/`. Git's documentation presents
that as a feature — "always verify that the rewritten version is correct" — and
it is, right up to the moment you think you are finished.

Until those refs are deleted, nothing has been removed from the repository at
all. The same is true of the reflog, which still names the old commits
(Chapter 36).

## Making the old objects go away

```console
$ git for-each-ref --format='%(refname)' refs/original | xargs -n 1 git update-ref -d
$ git reflog expire --expire=now --all
$ git gc --prune=now --quiet
$ git cat-file -t $(git rev-parse v1.0) 2>&1 | head -2
tag
$ git rev-list --objects --all | grep deploy.pem || echo 'not in any object'
not in any object
```

Three commands, in this order, and each is necessary:

1. **Delete `refs/original`.** `git for-each-ref` lists them and
   `git update-ref -d` deletes each one (Chapter 74). While they exist, every
   old commit is reachable.
2. **Expire the reflog.** `--expire=now --all` empties every reflog in the
   repository, so nothing the old commits were is remembered (Chapter 36).
3. **Garbage-collect.** `git gc --prune=now` deletes objects nothing reaches.
   Without `--prune=now` it keeps anything less than two weeks old, which means
   everything you have just unreferenced (Chapter 77).

After that, the blob is gone: `git rev-list --objects --all` finds no
`deploy.pem` anywhere. The tag still exists and still resolves — it points at
the rewritten commit now.

> **Careful.** `git gc --prune=now` deletes unreachable objects of every kind,
> including anything else you had lost and not yet rescued. Rescue first
> (Chapter 36), prune after.

## Checking it is really gone

```console
$ git log --all --oneline -- deploy.pem
$ git grep -q 's3cret' $(git rev-list --all) -- deploy.pem || echo 'no match in any commit'
no match in any commit
```

Two checks worth running before believing it worked. The first finds no commit
that touches the path. The second searches the *content* of every commit for
the secret itself — `git rev-list --all` lists every commit and `git grep`
searches each one (Chapter 21).

The second is the one that matters, because a secret often appears in more than
one file: in a config file, in a test fixture, in a script that echoes it.
Removing `deploy.pem` does nothing about a copy of the same key in
`deploy.sh`, and only a content search finds that.

Drop the `-- deploy.pem` to search everything:
`git grep -q 's3cret' $(git rev-list --all)`.

## The same thing with filter-repo

```console
$ git filter-repo --path deploy.pem --invert-paths --force
NOTICE: Removing 'origin' remote; see 'Why is my origin removed?'
        in the manual if you want to push back there.
        (was /home/ada/service)
...
$ git log --oneline --decorate
54faa62 (HEAD -> main) Add some notes
476acd8 (tag: v1.0) Add the documentation
dbb23c5 Add the deploy script
05dc719 Add the config
939a3a4 Start the service
$ git log --oneline --all -- deploy.pem
$ git rev-list --objects --all | grep deploy.pem || echo 'not in any object'
not in any object
$ git remote -v
$ ls .git/filter-repo
already_ran
changed-refs
commit-map
first-changed-commits
ref-map
suboptimal-issues
```

The same job in one command, with no aftercare. `--path` names a path and
`--invert-paths` means "everything except", so the two together mean "remove
this path". Tags were rewritten without being asked, the empty commit was
dropped without being asked, `refs/original` does not exist, the reflogs were
expired and the objects were repacked: `git rev-list --objects --all` finds
nothing straight away.

**`git filter-repo` is not part of Git.** It is a separate program — a single
Python script — that Git's own documentation recommends in place of
`filter-branch`. It has to be installed: from your system's package manager, or
by downloading the script and putting it on your `PATH`. A reader who cannot
install anything has `filter-branch`, which is why this chapter shows both.

**Why `origin` disappeared.** `filter-repo` removes the remote on purpose, and
says so. The reasoning is that a rewritten repository must never be pushed back
to the same place by accident; you are meant to check the result, then add the
remote again deliberately. It also expects a fresh clone, and refuses to run on
a repository with uncommitted changes or extra state unless `--force` is given —
which the example passes because it runs on a clone made moments before.

`.git/filter-repo/` holds the record of what it did. `commit-map` maps every
old hash to its new one, which is what you need to translate a hash from an
issue or a changelog after the rewrite.

### Removing by content rather than by name

```console
$ git filter-repo --replace-text ../filter-repo-text/replacements.txt --force
NOTICE: Removing 'origin' remote; see 'Why is my origin removed?'
        in the manual if you want to push back there.
        (was /home/ada/service)
...
$ git show v1.0:deploy.pem
-----BEGIN PRIVATE KEY-----
REMOVED
-----END PRIVATE KEY-----
$ git log --oneline
00baba2 Add some notes
16febe1 Remove the deploy key
b41670a Add the documentation
6013384 Add the deploy script
083c511 Add the deploy key
05dc719 Add the config
939a3a4 Start the service
```

`--replace-text <file>` replaces strings everywhere they appear, in every
commit, whatever file they are in. The file holds one rule per line; the one
used here is:

```
s3cret-do-not-share==>REMOVED
```

A line with no `==>` replaces the text with `***REMOVED***`, and a line
starting with `regex:` or `glob:` matches that way instead.

This is the tool for the case [Checking it is really
gone](#checking-it-is-really-gone) warns about: a secret that appears in
several files, or in a file you still need. The file stays, the history stays,
and only the string is gone.

### Analysing first

```console
$ git filter-repo --analyze
...
Writing reports to .git\filter-repo\analysis...done.
$ ls .git/filter-repo/analysis
README
blob-shas-and-paths.txt
directories-all-sizes.txt
directories-deleted-sizes.txt
extensions-all-sizes.txt
extensions-deleted-sizes.txt
path-all-sizes.txt
path-deleted-sizes.txt
renames.txt
$ head -12 .git/filter-repo/analysis/path-all-sizes.txt
=== All paths by reverse accumulated size ===
Format: unpacked size, packed size, date deleted, path name
          74         61 2026-01-05 deploy.pem
          25         35 <present>  deploy.sh
          23         33 <present>  docs/guide.md
          20         30 <present>  notes.md
          17         27 <present>  docs/faq.md
          11         20 <present>  config.yml
          10         19 <present>  README.md
```

`--analyze` changes nothing and writes a set of reports instead. The one above
lists every path that has ever existed, by how much space it accounts for,
with the date it was deleted if it was — `deploy.pem` is top of the list and
marked as deleted on the 5th.

That answers the other question this chapter's machinery is used for: not "how
do I remove a secret" but "why is this repository four gigabytes". The
`extensions-` and `directories-` reports group the same data differently, and
`renames.txt` says which paths are the same file under another name.

> **Windows.** The `Writing reports to` line prints a backslash path on
> Windows and a forward-slash one elsewhere; it is the same directory.

## Other filters

```console
$ git filter-branch --msg-filter 'sed s/deploy/DEPLOY/' -- --all 2>&1 | tail -3
Ref 'refs/tags/v1.0' was rewritten
WARNING: You said to rewrite tagged commits, but not the corresponding tag.
WARNING: Perhaps use '--tag-name-filter cat' to rewrite the tag.
$ git log --oneline
99ad6fa Add some notes
f214fb1 Remove the DEPLOY key
32e207e Add the documentation
95b8d91 Add the DEPLOY script
c4c2f9f Add the DEPLOY key
05dc719 Add the config
939a3a4 Start the service
```

`--msg-filter` runs a command with each commit message on its standard input
and takes the new message from its standard output. It is how a mistaken word,
a wrong issue number or a leaked hostname is taken out of every message.

The two warnings are the tag problem again, in the form Git prints when the
rewrite touched a tagged commit and no `--tag-name-filter` was given.

```console
$ git filter-branch --env-filter 'GIT_AUTHOR_EMAIL=ada@new.example; export GIT_AUTHOR_EMAIL' -- --all 2>&1 | tail -3
Ref 'refs/tags/v1.0' was rewritten
WARNING: You said to rewrite tagged commits, but not the corresponding tag.
WARNING: Perhaps use '--tag-name-filter cat' to rewrite the tag.
$ git log -1 --format='%an <%ae>'
Ada Lovelace <ada@new.example>
```

`--env-filter` runs a command whose only job is to set environment variables,
so it can change authorship: `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`,
`GIT_AUTHOR_DATE` and their `COMMITTER` equivalents (Chapter 12). A real one
would test `$GIT_AUTHOR_EMAIL` first and change only the addresses that need
it; this one changes them all.

`git filter-repo --mailmap <file>` does the same job from a mailmap file, which
is easier to get right (Chapter 22).

```console
$ git filter-branch --subdirectory-filter docs -- --all 2>&1 | tail -3
Ref 'refs/tags/v1.0' was rewritten
WARNING: You said to rewrite tagged commits, but not the corresponding tag.
WARNING: Perhaps use '--tag-name-filter cat' to rewrite the tag.
$ ls && git log --oneline
faq.md
guide.md
f0599ed Add the documentation
```

`--subdirectory-filter <dir>` throws away everything outside a directory and
makes that directory the root. Seven commits become the one that touched
`docs`, and the files that were `docs/guide.md` and `docs/faq.md` are now at
the top.

That is how a subdirectory becomes a repository of its own, keeping its
history — `git filter-repo --subdirectory-filter docs` does the same. The other
half of splitting a project up is Chapter 58.

| Filter | Runs a command | Useful for |
|---|---|---|
| `--index-filter` | against each commit's index, no checkout | removing a file from every commit |
| `--tree-filter` | in a checkout of each commit | anything that needs the real files; very slow ([The slow way](#the-slow-way)) |
| `--msg-filter` | with the message on standard input | rewriting messages |
| `--env-filter` | to set environment variables | changing authors and dates |
| `--parent-filter` | with the parent list on standard input | grafting histories together (Chapter 38) |
| `--commit-filter` | instead of `git commit-tree` | dropping commits, or anything the others cannot do |
| `--subdirectory-filter` | not a command: names a directory | making a subdirectory the root |
| `--setup` | once, before the loop | defining shell functions the other filters use |
| `--tag-name-filter` | with each tag name on standard input | keeping tags pointing at the right commits |
| `--prune-empty` | not a command: drops commits that change nothing | tidying up after a removal |
| `--original <namespace>` | not a command: names where the old refs are kept | a second run, when `refs/original` already exists |
| `-d <directory>`, `--state-branch <branch>` | not commands: where the temporary checkout and the old-to-new map live | very large repositories |
| `-f`, `--force` | not a command: run although `refs/original` exists | a second run |

<!-- no-example: -d  it moves filter-branch's temporary checkout directory,
     which only matters for speed on a large repository; the output is the same
     wherever the directory is -->
<!-- no-example: -f  it lets a second run start when refs/original already
     exists from a first one; the chapter deletes refs/original instead, which
     is what a reader should do before running again -->
<!-- no-example: --parent-filter  the one thing it is for, joining two
     histories, is Chapter 38's --graft with a shorter command and no rewrite;
     showing it here would teach the harder way to do something the next
     chapter does properly -->
<!-- no-example: --commit-filter  it replaces git commit-tree for every commit,
     so a demonstration needs a shell function over commit-tree's plumbing
     (Chapter 75) to show anything the filters above do not; --prune-empty,
     which is demonstrated, is the one thing most people want it for -->
<!-- no-example: --setup  it defines shell functions for the other filters and
     produces no output of its own; a transcript would show the same result as
     the filter that used it -->
<!-- no-example: --original  it renames the refs/original namespace, which is
     shown under its default name in "The original refs"; the only visible
     difference would be a different directory in for-each-ref output -->
<!-- no-example: --state-branch  it saves the old-to-new mapping so that a
     second run can continue where the first stopped, which matters only on a
     repository too large to filter in one go; the example repository filters
     in under a second -->

## What the rewrite does not reach

```console
$ git -C /home/ada/origin.git log --oneline --all -- deploy.pem
64e2fcf Remove the deploy key
01e1692 Add the deploy key
$ git -C /home/ada/origin.git show v1.0:deploy.pem
-----BEGIN PRIVATE KEY-----
s3cret-do-not-share
-----END PRIVATE KEY-----
$ git -C /home/ada/service log --oneline --all -- deploy.pem
64e2fcf Remove the deploy key
01e1692 Add the deploy key
```

The rewrite was thorough, and the key is still there twice: on the server, and
in the original repository the rewritten copy was cloned from.

Nothing about a local rewrite reaches anywhere else. Every one of these has its
own copy and has to be dealt with, or accepted:

| Where | What it takes |
|---|---|
| the server | a force-push, and then the server's own garbage collection, on its schedule |
| a colleague's clone | they re-clone, or run the rewrite themselves |
| a fork on a forge | the fork's owner does the same; a forge will not do it for you |
| an open pull request | the old commits stay attached to it, often for ever; close it |
| a build server's cache | it re-clones, eventually |
| a backup, a mirror, a tarball | whatever those take |
| a search engine or a scanner | nothing you can do |

GitHub and GitLab both keep unreachable commits reachable by URL for a while,
and both have a documented process for asking them to remove them. That process
is worth starting, and it is not a substitute for rotating the secret.

## Pushing the rewrite

Once the local repository is right, the rewrite has to go out:

```
git push --force-with-lease --all
git push --force-with-lease --tags
```

`--force-with-lease` refuses if the branch moved since your last fetch, which
is the safety catch Chapter 28 explains; `--all` and `--tags` are needed
because a rewrite touches every branch and every tag, not the current one.
Chapter 43 covers both.

**What to tell everyone else.** Their clones still have the old history, and a
plain `git pull` will merge it back in — which would put the file back. The
message to send is short:

> I rewrote the history of `<repo>` to remove a leaked key. Do not pull. Please
> re-clone, or if you have unpushed work: `git fetch`, then
> `git rebase --onto origin/main <your first commit>~1`.

Chapter 28 goes through that recovery properly.

**Then check the server.** After the force-push the old objects are still in
the hosted repository until it garbage-collects, which on a forge you do not
control. The old commits usually stay reachable by URL for a while; that is
what the forge's removal process is for.

## Keeping it from happening again

```console
$ git add .gitignore && git commit -q -m 'Ignore keys and environment files'
$ git status --short
$ git add new.pem
The following paths are ignored by one of your .gitignore files:
new.pem
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
$ git add -f new.pem && git status --short
A  new.pem
```

`.gitignore` is the first line of defence, and the transcript shows both its
strength and its limit. `git status` does not mention `new.pem` at all, and
`git add` refuses it with an explanation — but `git add -f` gets past it in one
word, and `git add -f` is exactly what someone does when they are in a hurry
and the file "should" be there.

Patterns worth having from the first commit: `*.pem`, `*.key`, `*.p12`, `.env`,
`*.env`, `id_rsa`, `credentials.json`, and whatever your language's secret
store is called (Chapter 16).

```console
$ git add -f new.pem && git commit -m 'Add another key'
pre-commit: refusing to commit a .pem file
```

A `pre-commit` hook is the second line, and the one that stops `-f`. The hook
here is four lines:

```sh
#!/bin/sh
if git diff --cached --name-only | grep -q '\.pem$'
then
	echo "pre-commit: refusing to commit a .pem file"
	exit 1
fi
```

Any non-zero exit stops the commit. Real ones match a list of patterns, or run
a scanner over the staged content looking for things shaped like keys.
Chapter 67 covers hooks, including the fact that a hook lives in `.git/hooks`
and is therefore not cloned — so a team wants `core.hooksPath` and a checked-in
directory, or a tool that installs them.

The third line is on the server: a pre-receive hook or the forge's own secret
scanning, which rejects a push that contains something that looks like a
credential. That is the only one that cannot be bypassed by the person
committing, and Chapter 50 and Chapter 51 cover what the forges offer.

## Which tool for which job

| Situation | Command | Chapter |
|---|---|---|
| Staged, not committed | `git rm --cached <file>` | Chapter 15 |
| In the last commit | `git rm --cached <file>` then `git commit --amend` | Chapter 29 |
| In the last few, not pushed | `git rebase -i <commit>^`, `edit` each one | Chapter 34 |
| In every commit, and you can install a tool | `git filter-repo --path <file> --invert-paths` | this chapter |
| In every commit, and you cannot | `git filter-branch --index-filter 'git rm --cached --ignore-unmatch <file>' --prune-empty --tag-name-filter cat -- --all` | this chapter |
| A string rather than a file | `git filter-repo --replace-text <rules>` | this chapter |
| A huge file rather than a secret | either of the above; then `git gc` | Chapter 82 |
| A subdirectory to be its own repository | `git filter-repo --subdirectory-filter <dir>` | Chapter 58 |
| Working out what is in there first | `git filter-repo --analyze` | this chapter |

**The BFG Repo-Cleaner** is the third tool people mention. It is a Java program,
not part of Git, and it is fast and good at exactly two jobs: deleting files by
name and replacing text. It always protects the commits your branch tips point
at, so the current version of a file is kept while every historical copy is
removed — which is either exactly what you want or a surprise, depending on
whether you read that first. Everything it does, `git filter-repo` also does.
It is not shown here because it is not Git and needs a Java runtime.

## The settings

| Setting or variable | Does |
|---|---|
| `FILTER_BRANCH_SQUELCH_WARNING=1` | Turn off the warning `filter-branch` prints before it starts |
| `gc.pruneExpire` | How old an unreachable object must be before `git gc` deletes it, two weeks by default; `--prune=now` overrides it (Chapter 77) |
| `gc.reflogExpire`, `gc.reflogExpireUnreachable` | How long reflog entries keep old commits reachable (Chapter 36) |
| `core.hooksPath` | Where hooks live, so a team can share a `pre-commit` hook (Chapter 67) |
| `advice.addIgnoredFile` | Whether `git add` explains itself when it refuses an ignored file |
| `transfer.fsckObjects`, `receive.fsckObjects` | Checks on what is pushed; not about secrets, but the same place a server-side policy lives (Chapter 43) |
