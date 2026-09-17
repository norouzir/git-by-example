# Chapter 43. push

## What it is

`git push` sends commits from your repository to another one, and moves that
repository's branches or tags to point at them. It is the only everyday command
that changes a repository other than your own. On its own it answers one
question: *can the server have my commits now?*

A push never merges. The server's branch is simply moved to your commit, and by
default only if that loses nothing: your commit must contain the one the branch
points at now, a *fast-forward*. When someone else has pushed in the meantime,
your push is *rejected*, and you have to bring their work into yours first,
with `git pull` (Chapter 42), and push again. Forcing past that check is
possible and throws their commits off the branch, which is why this chapter
spends as long on doing it safely as on doing it at all.

| Term | Means |
|---|---|
| *fast-forward* | an update where the new commit contains the old one in its history, so nothing is lost |
| *rejected* | refused by your own Git before anything is sent, usually because the update is not a fast-forward |
| *remote rejected* | refused by the receiving repository, because of its settings or a hook |
| *force push* | a push that moves a branch to a commit that does not contain the old one |
| *lease* | the condition `--force-with-lease` sets: force only if the branch is still where you last saw it |
| *upstream* | the branch a local branch is compared with and pulls from (Chapter 23) |
| *push remote* | the remote a plain `git push` sends to; usually the upstream's remote, but it can be another |
| *refspec* | a rule `<source>:<destination>` saying which local ref updates which remote ref; Chapter 44 has the full syntax |
| *bare repository* | a repository with no working tree, the usual kind on a server (Chapter 9) |
| *hook* | a program a repository runs at a fixed moment, which can refuse what is happening (Chapter 67) |
| *mirror* | a repository kept identical to another, every ref included |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git push` do, and does it ever merge on the server?](#what-it-is)
- [Why would a push be refused?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git push`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repositories do the examples use?](#the-example-repository)

**[Reading the output](#reading-the-output)**

- [What do the lines `git push` prints mean?](#reading-the-output)
- [What does "Everything up-to-date" mean?](#reading-the-output)
- [What do `[new branch]`, `(forced update)` and `[remote rejected]` mean?](#reading-the-output)

**[What a push changes here](#what-a-push-changes-here)**

- [Does a push change anything in my own repository?](#what-a-push-changes-here)

**[Which branch a plain push sends](#which-branch-a-plain-push-sends)**

- [Git says "The current branch has no upstream branch". What should I type?](#which-branch-a-plain-push-sends)
- [How do I stop having to type `--set-upstream` for every new branch?](#which-branch-a-plain-push-sends)
- [Git says the upstream branch "does not match the name of your current branch". Why won't it push?](#push-default)
- [What does each value of `push.default` do?](#push-default)

**[Which remote](#which-remote)**

- [How do I pull from one remote and push to another?](#which-remote)
- [Why does `@{push}` say "cannot resolve 'simple' push to a single destination"?](#which-remote)
- [How do I make one branch push somewhere else?](#which-remote)
- [Can one `git push` send to several remotes?](#several-remotes-at-once)
- [What is `--repo` for?](#several-remotes-at-once)

**[Naming what to push](#naming-what-to-push)**

- [How do I push a branch under a different name?](#naming-what-to-push)
- [How do I push a commit that is not the tip of a branch?](#naming-what-to-push)
- [What does "The destination you provided is not a full refname" mean?](#naming-what-to-push)
- [What does "src refspec ... does not match any" mean?](#naming-what-to-push)
- [How do I push all my branches at once?](#naming-what-to-push)
- [How do I push from a detached HEAD?](#detached-head)

**[Tags](#tags)**

- [Does `git push` send my tags?](#tags)
- [What is the difference between `--tags` and `--follow-tags`?](#tags)
- [Can I push tags and all branches in one command?](#tags)
- [I moved a tag and the push says "already exists". What now?](#a-tag-that-moved)

**[Deleting and renaming on the server](#deleting-and-renaming-on-the-server)**

- [How do I delete a branch or a tag on the server?](#deleting-and-renaming-on-the-server)
- [What does `git push origin :review` do?](#deleting-and-renaming-on-the-server)
- [One of my deletions was wrong. Were the others made?](#deleting-and-renaming-on-the-server)
- [How do I rename a branch on the server?](#renaming-a-branch-on-the-server)

**[Rejected pushes](#rejected-pushes)**

- [My push was rejected with "fetch first". What happened?](#rejected-pushes)
- [What is the difference between "fetch first" and "non-fast-forward"?](#rejected-pushes)
- [I pushed two branches and one was rejected. Was the other pushed?](#several-branches-in-one-push)
- [How do I push several branches so that either all go or none do?](#several-branches-in-one-push)

**[Forcing a push](#forcing-a-push)**

- [I amended a commit I had already pushed. How do I push it?](#forcing-a-push)
- [What is the difference between `--force` and a `+` before the branch name?](#forcing-a-push)
- [How do I force-push without destroying work someone else pushed?](#a-lease)
- [What does "stale info" mean?](#a-lease)
- [`--force-with-lease` let me overwrite a commit I had never looked at. How?](#a-lease)
- [What does `--force-if-includes` add, and what is "remote ref updated since checkout"?](#a-lease)
- [How do I push a new branch only if nobody has created it yet?](#a-lease)

**[Mirrors and pruning](#mirrors-and-pruning)**

- [How do I make a backup repository identical to mine?](#mirrors-and-pruning)
- [How do I delete branches on the server that I no longer have?](#mirrors-and-pruning)

**[What the server can refuse](#what-the-server-can-refuse)**

- [Why can't I push to a repository that has files checked out?](#pushing-to-a-repository-with-a-working-tree)
- [How do I deploy a web site by pushing to it?](#pushing-to-a-repository-with-a-working-tree)
- [I used `--force` and the server still refused. Why?](#rules-the-server-sets)
- [The server is set to refuse deletions, but my tag was deleted. Why?](#rules-the-server-sets)
- [What are the `remote:` lines, and what does "pre-receive hook declined" mean?](#hooks-on-the-server)
- [What does "the receiving end does not support push options" mean?](#push-options)

**[The pre-push hook](#the-pre-push-hook)**

- [Something on my side stopped the push, with no reason given. What was it?](#the-pre-push-hook)
- [How do I push without running my own hooks?](#the-pre-push-hook)

**[Dry runs and output for scripts](#dry-runs-and-output-for-scripts)**

- [How do I see what a push would do without doing it?](#dry-runs-and-output-for-scripts)
- [What output should a script read?](#dry-runs-and-output-for-scripts)
- [Why don't I see "Writing objects" when I redirect the output?](#dry-runs-and-output-for-scripts)

**[Publishing a new repository](#publishing-a-new-repository)**

- [How do I put a project that exists only on my computer onto a server?](#publishing-a-new-repository)
- [Why does my first push say "src refspec main does not match any"?](#publishing-a-new-repository)

**[The conversation](#the-conversation)**

- [What do Git and the server say to each other during a push?](#the-conversation)
- [What does `push.negotiate` change?](#the-conversation)
- [What is a thin pack?](#thin-packs)
- [What are `--receive-pack` and `--exec` for?](#the-program-on-the-other-end)

**[push and its neighbours](#push-and-its-neighbours)**

- [How does `git push` compare with fetch, and with ways of sending work that do not push?](#push-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what push does, on my side and on the server?](#the-settings)

</details>

## Synopsis

```
git push [<options>] [<repository> [<refspec>...]]
```

| Part | Means |
|---|---|
| `<repository>` | A remote's name, a URL, or a group of remotes; left out, the current branch's push remote, or `origin` |
| `<refspec>` | What to push and where: `main`, `main:review`, `HEAD`, `:old-branch`, `tag v1.0`; left out, what `push.default` says. The full syntax is Chapter 44 |

| Command | Does |
|---|---|
| `git push` | Push the current branch to its push remote, as `push.default` says |
| `git push -u origin topic` | Push `topic` to `origin`, and make `origin/topic` its upstream |
| `git push origin main:review` | Update or create the server's `review` with your `main` |
| `git push origin --delete topic` | Delete the server's `topic` |
| `git push origin v1.0` | Push one tag |
| `git push --tags` | Push every tag |
| `git push --force-with-lease` | Force, but only if nobody has pushed since your last fetch |
| `git push --mirror <url>` | Make the other repository's refs identical to yours |

## Options at a glance

### What to push

| Option | Does | Covered in |
|---|---|---|
| `--all`, `--branches` | Every local branch | [Naming what to push](#naming-what-to-push) |
| `--tags` | Every tag, as well as what the command line names | [Tags](#tags) |
| `--follow-tags`, `--no-follow-tags` | Also annotated tags that point into what is pushed | [Tags](#tags) |
| `-d`, `--delete` | Delete the named refs on the server | [Deleting and renaming on the server](#deleting-and-renaming-on-the-server) |
| `--mirror` | Every ref under `refs/`, forced, with deletions | [Mirrors and pruning](#mirrors-and-pruning) |
| `--prune`, `--no-prune` | Delete server refs the refspecs cover and you do not have | [Mirrors and pruning](#mirrors-and-pruning) |
| `--repo=<repository>` | The repository, if none is given as an argument | [Several remotes at once](#several-remotes-at-once) |
| `-u`, `--set-upstream` | Make what is pushed the upstream of each branch | [Which branch a plain push sends](#which-branch-a-plain-push-sends) |

> **Since Git 2.41.** `--branches`, another name for `--all`.

### Safety and forcing

| Option | Does | Covered in |
|---|---|---|
| `-f`, `--force` | Allow updates that are not fast-forwards, for every ref pushed | [Forcing a push](#forcing-a-push) |
| `--force-with-lease` | Force, if each ref is where its remote-tracking branch says | [A lease](#a-lease) |
| `--force-with-lease=<refname>` | The same, for that ref only | [A lease](#a-lease) |
| `--force-with-lease=<refname>:<expect>` | Force that ref only if it is at `<expect>`; empty means it must not exist | [A lease](#a-lease) |
| `--no-force-with-lease` | Cancel earlier `--force-with-lease` options | [A lease](#a-lease) |
| `--force-if-includes`, `--no-force-if-includes` | With a lease, also require the remote-tracking branch's tip to be in your branch's reflog | [A lease](#a-lease) |
| `--atomic`, `--no-atomic` | Update every ref or none | [Several branches in one push](#several-branches-in-one-push) |
| `--no-verify`, `--verify` | Skip the `pre-push` hook, or run it | [The pre-push hook](#the-pre-push-hook) |

> **Since Git 2.30.** `--force-if-includes`.

### Output

| Option | Does | Covered in |
|---|---|---|
| `-n`, `--dry-run` | Do everything except send the updates | [Dry runs and output for scripts](#dry-runs-and-output-for-scripts) |
| `--porcelain` | One tab-separated line per ref, on standard output | [Dry runs and output for scripts](#dry-runs-and-output-for-scripts) |
| `-v`, `--verbose` | Also list refs that did not change | [Reading the output](#reading-the-output) |
| `-q`, `--quiet` | Print nothing but errors | [What a push changes here](#what-a-push-changes-here) |
| `--progress` | Show progress even when not on a terminal | [Dry runs and output for scripts](#dry-runs-and-output-for-scripts) |

### The server

| Option | Does | Covered in |
|---|---|---|
| `-o <option>`, `--push-option=<option>` | Send a string to the server's hooks | [Push options](#push-options) |
| `--receive-pack=<program>`, `--exec=<program>` | The program to run on the server | [The program on the other end](#the-program-on-the-other-end) |
| `--thin`, `--no-thin` | Send a thin pack, the default, or a complete one | [Thin packs](#thin-packs) |

### Covered in other chapters

| Option | Does | Covered in |
|---|---|---|
| `--signed`, `--no-signed`, `--signed=true`, `--signed=false`, `--signed=if-asked` | Sign the push request with GPG | Chapter 68 |
| `--recurse-submodules=check`, `--recurse-submodules=on-demand`, `--recurse-submodules=only`, `--recurse-submodules=no`, `--no-recurse-submodules` | What to do about submodule commits that are not pushed | Chapter 57 |
| `-4`, `-6` | Use only IPv4, or only IPv6; also `--ipv4`, `--ipv6` | Chapter 40 |

## The example repository

```console
$ git remote -v
origin	../server/atlas.git (fetch)
origin	../server/atlas.git (push)
$ git log --oneline --graph --all --decorate
* 0fe19df (HEAD -> main, origin/main, origin/HEAD) Add Europe
* 0dd6887 Start the atlas
```

Ada has just cloned the team's atlas from a bare repository on the "server",
which her clone reaches by the relative path `../server/atlas.git`
(Chapter 39). Bob has a clone too, and pushes to the same repository out of
sight; each section says what he pushed. Every command runs in Ada's clone
unless the section says otherwise.

## Reading the output

Ada committed "Add Africa":

```console
$ git push
To ../server/atlas.git
   0fe19df..70029e9  main -> main
$ git push
Everything up-to-date
$ git push -v
Pushing to ../server/atlas.git
To ../server/atlas.git
 = [up to date]      main -> main
updating local tracking ref 'refs/remotes/origin/main'
Everything up-to-date
```

`To` names the repository pushed to. Then there is a line per ref: a flag, a
summary, the local ref, an arrow, and the ref it updated on the server. Here
`main` moved from `0fe19df` to `70029e9`, a fast-forward. The second push had
nothing to send, "Everything up-to-date". `-v` lists refs that did not change as
well, and says where it is pushing and which of your remote-tracking branches
it set (the next section).

Ada made a branch `deserts` with a commit:

```console
$ git push origin deserts
To ../server/atlas.git
 * [new branch]      deserts -> deserts
```

Git's documentation defines the flags and the summaries:

| Flag | Means |
|---|---|
| ` ` (space) | a fast-forward, pushed |
| `+` | a forced update, pushed |
| `-` | a ref deleted |
| `*` | a new ref, pushed |
| `!` | a ref rejected, or that failed to push |
| `=` | a ref already up to date; listed only with `-v` or `--porcelain` |

| Summary | Means |
|---|---|
| `<old>..<new>` | the range of a fast-forward, usable with `git log` |
| `<old>...<new>` | the two sides of a forced update |
| `[new branch]`, `[new tag]`, `[new reference]` | created; a reference is a ref that is neither a branch nor a tag |
| `[deleted]` | deleted |
| `[rejected]` | your Git did not send it, with the reason in brackets |
| `[remote rejected]` | the server refused it, usually through a setting or a hook |
| `[remote failure]` | the server did not confirm the update, for example because the connection broke |

The reasons in brackets are shown in the sections below where each happens.

## What a push changes here

Ada committed "Add Asia":

```console
$ git status -sb && git push -q && git status -sb && git reflog -1 origin/main
## main...origin/main [ahead 1]
## main...origin/main
c244fff refs/remotes/origin/main@{0}: update by push
```

A push changes no branch of yours, but it does update your record of the
server: once the server has accepted `main`, Git moves `origin/main` to the same
commit, as if it had fetched, and `git status` stops counting the commit as
ahead. The reflog of `origin/main` says who moved it (Chapter 36). `-q` kept the
push silent.

## Which branch a plain push sends

Ada made a branch `rivers` with a commit:

```console
$ git push; echo "exit $?"
fatal: The current branch rivers has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin rivers

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

exit 128
$ git push -u origin rivers
To ../server/atlas.git
 * [new branch]      rivers -> rivers
branch 'rivers' set up to track 'origin/rivers'.
$ git push
Everything up-to-date
```

A plain `git push` needs to know where the branch goes, and a new branch has no
upstream to say so. `-u`, or `--set-upstream`, pushes it and records
`origin/rivers` as its upstream, as `git branch -u` would (Chapter 23), after
which a plain `git push` and `git pull` both know what to do.

Ada made a branch `lakes` with a commit:

```console
$ git config set push.autoSetupRemote true && git push
To ../server/atlas.git
 * [new branch]      lakes -> lakes
branch 'lakes' set up to track 'origin/lakes'.
```

`push.autoSetupRemote=true` makes a plain push of a branch with no upstream act
as `-u` did, to the branch of the same name, which is why Chapter 3 suggests it.

> **Since Git 2.37.** `push.autoSetupRemote`.

### push.default

Ada made a branch `maps` from `origin/main`, so its upstream is the server's
`main` (Chapter 24), and committed on it:

```console
$ git branch -vv --list maps && git push; echo "exit $?"
* maps 6a2e980 [origin/main: ahead 1] Add Oceania
fatal: The upstream branch of your current branch does not match
the name of your current branch.  To push to the upstream branch
on the remote, use

    git push origin HEAD:main

To push to the branch of the same name on the remote, use

    git push origin HEAD

To choose either option permanently, see push.default in 'git help config'.

To avoid automatically configuring an upstream branch when its name
won't match the local branch, see option 'simple' of branch.autoSetupMerge
in 'git help config'.

exit 128
```

`push.default` decides what a plain push sends, and its default, `simple`,
pushes a branch only to a branch of the same name. `maps` pulls from `main`, so
Git cannot tell which one Ada means, and asks. The other values, each tried with
`--dry-run`, which reports without pushing:

```console
$ git -c push.default=upstream push --dry-run
To ../server/atlas.git
   c244fff..6a2e980  maps -> main
$ git -c push.default=current push --dry-run
To ../server/atlas.git
 * [new branch]      maps -> maps
$ git -c push.default=matching push --dry-run -v
Pushing to ../server/atlas.git
To ../server/atlas.git
 = [up to date]      deserts -> deserts
 = [up to date]      lakes -> lakes
 = [up to date]      main -> main
 = [up to date]      rivers -> rivers
Everything up-to-date
$ git -c push.default=nothing push; echo "exit $?"
fatal: You didn't specify any refspecs to push, and push.default is "nothing".
exit 128
```

`git -c <name>=<value>` sets a configuration value for one command (Chapter 62).
`upstream` pushed `maps` into the server's `main`; `current` into a new `maps`.
`matching` pushed every local branch whose name also exists on the server, and
`maps`, which does not, was left out. `nothing` pushes nothing unless told.

| Value of `push.default` | A plain `git push` sends | Refuses when |
|---|---|---|
| `push.default=simple`, the default | the current branch, to the same name | the branch has no upstream, or an upstream with another name, on the remote pushed to |
| `push.default=current` | the current branch, to the same name, created if missing | never |
| `push.default=upstream` | the current branch, to its upstream, whatever its name | there is no upstream, or the push goes to another remote |
| `push.default=matching` | every branch whose name exists on both sides | never |
| `push.default=nothing` | nothing | always, unless you name what to push |
| `push.default=tracking` | the same as `upstream`, under a deprecated name | as `upstream` |

Git's documentation calls `simple` the safest choice for beginners, and it has
been the default since Git 2.0; `matching` was the default before, and it pushes
branches you may not have finished. The rules for the "refuses" column are in
`builtin/push.c` of Git's source, which is also where the next section's
exception comes from.

## Which remote

Ada has her own copy of the atlas, `ada-atlas.git`, and wants her `deserts` work
to go there while still pulling from the team's repository. `deserts` has
`origin/deserts` as its upstream. She committed "Add the Gobi":

```console
$ git remote add fork ../server/ada-atlas.git && git config set remote.pushDefault fork
$ git push && git status -sb
To ../server/ada-atlas.git
 * [new branch]      deserts -> deserts
## deserts...origin/deserts [ahead 1]
$ git rev-parse --abbrev-ref @{upstream} && git rev-parse --abbrev-ref @{push}
origin/deserts
fatal: cannot resolve 'simple' push to a single destination
$ git -c push.default=current rev-parse --abbrev-ref @{push}
fork/deserts
```

`remote.pushDefault` names the remote every plain push goes to, while fetches
and pulls still use `origin`. So the push went to the fork, and `git status`,
which compares with the upstream, still counts the commit as not on `origin`.

`simple` did not refuse, although `deserts` pushed to a remote that is not its
upstream's: Git's source applies the name check only when pushing to the same
remote the branch pulls from, and otherwise behaves like `current`. But
`@{push}`, the revision naming where a plain push would go (Chapter 18), refuses
to guess under `simple` in this setup, and works with `push.default=current`,
the setting Chapter 18 uses. `fork/deserts` exists because the push updated it.

```console
$ git remote add backup ../server/backup.git && git config set branch.deserts.pushRemote backup && git push
To ../server/backup.git
 * [new branch]      deserts -> deserts
$ git push origin
To ../server/atlas.git
   5f18e93..5adff1f  deserts -> deserts
```

`branch.<name>.pushRemote` sends one branch somewhere else again, and wins over
`remote.pushDefault`. A remote named on the command line wins over both; to
`origin`, the branch's own remote, `simple` checked the upstream's name, which
matched.

| The remote a plain push uses | Set by |
|---|---|
| the one named on the command line | `git push <remote>` |
| else the branch's push remote | `branch.<name>.pushRemote` |
| else the default push remote | `remote.pushDefault` |
| else the branch's remote | `branch.<name>.remote`, the upstream's |
| else | `origin` |

### Several remotes at once

```console
$ git config set remotes.everywhere 'fork backup' && git push everywhere deserts main
Pushing to fork
To ../server/ada-atlas.git
 * [new branch]      main -> main
Pushing to backup
To ../server/backup.git
 * [new branch]      main -> main
$ git push --atomic everywhere deserts; echo "exit $?"
fatal: --atomic can only be used when pushing to one remote
exit 128
```

A group defined by `remotes.<group>` pushes to each member in turn, as if the
command had been typed once per remote; Git's documentation says so, and adds
that a failure at one member does not stop the others and makes the exit status
non-zero. `deserts` was already on both, so only `main` was listed.
[`--atomic`](#several-branches-in-one-push) cannot span separate repositories,
and is refused.

> **Since Git 2.55.** Pushing to a group of remotes.

Ada committed "Add the Atacama":

```console
$ git push --repo=fork && git push --repo=fork deserts; echo "exit $?"
To ../server/ada-atlas.git
   5adff1f..dfb90d7  deserts -> deserts
fatal: 'deserts' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
exit 128
```

`--repo` names the repository, and Git's documentation says an argument wins
over it. So a refspec after `--repo` is not a refspec: `deserts` was taken for
the repository. The option is for scripts that build the rest of the command
separately; typing the remote as the first argument does the same.

## Naming what to push

Ada committed "Add the Americas" on `main`:

```console
$ git push origin HEAD
To ../server/atlas.git
   c244fff..608c519  HEAD -> main
$ git push origin main:review
To ../server/atlas.git
 * [new branch]      main -> review
$ git push origin main~1:refs/heads/before-americas
To ../server/atlas.git
 * [new branch]      main~1 -> before-americas
```

After the remote come refspecs. `HEAD` is the current branch, pushed to the same
name. `main:review` pushes the local `main` into a branch called `review` on the
server, created here. The left side can be any commit, `main~1` included
(Chapter 18), and then the right side has to be written in full, as
`refs/heads/<name>`:

```console
$ git push origin main~1:snapshot; echo "exit $?"
error: The destination you provided is not a full refname (i.e.,
starting with "refs/"). We tried to guess what you meant by:

- Looking for a ref that matches 'snapshot' on the remote side.
- Checking if the <src> being pushed ('main~1')
  is a ref in "refs/{heads,tags}/". If so we add a corresponding
  refs/{heads,tags}/ prefix on the remote side.

Neither worked, so we gave up. You must fully qualify the ref.
hint: The <src> part of the refspec is a commit object.
hint: Did you mean to create a new branch by pushing to
hint: 'main~1:refs/heads/snapshot'?
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git push origin nosuch; echo "exit $?"
error: src refspec nosuch does not match any
error: failed to push some refs to '../server/atlas.git'
exit 1
```

A short destination such as `snapshot` could be a branch or a tag. Git guesses
from the server, where no ref of that name exists, and from the source, which is
a commit rather than a branch, and gives up, with the full name in the hint.
"src refspec does not match any" means the left side names nothing in your
repository, usually a misspelt branch. Chapter 44 has every rule by which short
names are expanded.

Ada has a local branch `mountains` that she never pushed:

```console
$ git push --all origin
To ../server/atlas.git
   5adff1f..dfb90d7  deserts -> deserts
 * [new branch]      mountains -> mountains
$ git ls-remote --branches origin
c244fff89197fc5d9fe429223af3435458f130d5	refs/heads/before-americas
dfb90d7ed5b43dd629cd4834fc7d19eda5979f42	refs/heads/deserts
3e06073b90b6b59caa488af22eb12eae014965ec	refs/heads/lakes
608c519f78606988e7e254650d93bfb920a8ad5f	refs/heads/main
70029e9608800b8a679fc60f97bc23e9530459fd	refs/heads/mountains
608c519f78606988e7e254650d93bfb920a8ad5f	refs/heads/review
3108eb0fdd3cebf66409e35c806e490169ea85cb	refs/heads/rivers
```

`--all`, or `--branches`, pushes every local branch to the same name, creating
the missing ones. `git ls-remote` shows the server's branches (Chapter 39).

### Detached HEAD

Ada checked out `main~1` with a detached `HEAD` (Chapter 24):

```console
$ git push; echo "exit $?"
fatal: You are not currently on a branch.
To push the history leading to the current (detached HEAD)
state now, use

    git push origin HEAD:<name-of-remote-branch>

exit 128
$ git push origin HEAD; echo "exit $?"
error: The destination you provided is not a full refname (i.e.,
starting with "refs/"). We tried to guess what you meant by:

- Looking for a ref that matches 'HEAD' on the remote side.
- Checking if the <src> being pushed ('HEAD')
  is a ref in "refs/{heads,tags}/". If so we add a corresponding
  refs/{heads,tags}/ prefix on the remote side.

Neither worked, so we gave up. You must fully qualify the ref.
hint: The <src> part of the refspec is a commit object.
hint: Did you mean to create a new branch by pushing to
hint: 'HEAD:refs/heads/HEAD'?
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git push origin HEAD:refs/heads/experiment
To ../server/atlas.git
 * [new branch]      HEAD -> experiment
```

With no branch there is no name to push to, so `HEAD` alone fails the same way
`main~1` did, and a full destination works.

## Tags

A plain push sends no tags:

```console
$ git tag -a v1.0 -m 'First edition' && git tag draft && git push --follow-tags
To ../server/atlas.git
 * [new tag]         v1.0 -> v1.0
$ git push origin draft
To ../server/atlas.git
 * [new tag]         draft -> draft
$ git tag v1.1-rc && git push origin tag v1.1-rc
To ../server/atlas.git
 * [new tag]         v1.1-rc -> v1.1-rc
```

`--follow-tags` sends, with what is pushed, the *annotated* tags that point into
it and that the server lacks; `v1.0` went, and `draft`, a lightweight tag
(Chapter 47), did not, although it points at the same commit. Naming a tag
pushes it whatever its kind, and `tag <name>` is the explicit form, which Git's
documentation expands to `refs/tags/<name>:refs/tags/<name>`.

Ada committed "Add the Arctic" and tagged it `v1.1`, annotated, and `checked`,
lightweight; then committed "Add islands" and tagged it `v1.2`:

```console
$ git push --tags
To ../server/atlas.git
 * [new tag]         checked -> checked
 * [new tag]         v1.1 -> v1.1
$ git config set push.followTags true && git push
To ../server/atlas.git
   608c519..a6303e5  main -> main
 * [new tag]         v1.2 -> v1.2
$ git push --all --tags origin; echo "exit $?"
fatal: options '--tags' and '--all/--branches' cannot be used together
exit 128
```

`--tags` pushes every tag, of both kinds, and not the branch: the objects
`v1.1` needs went with it, but `main` on the server did not move.
`push.followTags=true` makes every push behave as `--follow-tags`, so `main`
and `v1.2` went together. `--all` and `--tags` cannot be combined; push the
branches and then the tags.

| Command | Tags pushed |
|---|---|
| `git push` | none |
| `git push --follow-tags`, or `push.followTags=true` | annotated tags pointing into what is pushed, missing on the server |
| `git push --tags` | every tag, and no branch unless named too |
| `git push origin <tag>`, `git push origin tag <tag>` | that tag |

### A tag that moved

```console
$ git tag -f draft HEAD~1 && git push origin draft; echo "exit $?"
Updated tag 'draft' (was 608c519)
To ../server/atlas.git
 ! [rejected]        draft -> draft (already exists)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tag already exists in the remote.
exit 1
$ git push origin +draft
To ../server/atlas.git
 + 608c519...7c0f468 draft -> draft (forced update)
```

A branch on the server accepts a fast-forward; a tag accepts no change at all,
Git's documentation says, because a tag is meant to stay where it was put.
`already exists` is that refusal. `+` before the name forces it, for this ref
only. Everyone who fetched the old tag keeps it until they force a fetch
(Chapter 41), which is why Chapter 47 advises against moving published tags.

## Deleting and renaming on the server

```console
$ git push origin --delete before-americas experiment
To ../server/atlas.git
 - [deleted]         before-americas
 - [deleted]         experiment
$ git push origin :review
To ../server/atlas.git
 - [deleted]         review
$ git push origin --delete draft checked
To ../server/atlas.git
 - [deleted]         checked
 - [deleted]         draft
```

`--delete`, or `-d`, deletes each ref named, branches and tags alike. A refspec
with nothing before the colon means the same, and Git's documentation describes
`--delete` as prefixing every ref with a colon: push nothing into `review`.

```console
$ git push origin --delete v1.1-rc nosuch; echo "exit $?"; git ls-remote --tags origin v1.1-rc
error: unable to delete 'nosuch': remote ref does not exist
error: failed to push some refs to '../server/atlas.git'
exit 1
608c519f78606988e7e254650d93bfb920a8ad5f	refs/tags/v1.1-rc
$ git push --delete origin; echo "exit $?"
fatal: --delete doesn't make sense without any refs
exit 128
$ git push --delete origin main:main; echo "exit $?"
fatal: --delete only accepts plain target ref names
exit 128
```

A name the server does not have stops the whole push before anything is sent,
so `v1.1-rc`, which does exist, was not deleted either. `--delete` also needs at
least one name, and names only, not `<source>:<destination>`.

### Renaming a branch on the server

There is no rename on the server; it is a push under the new name and a
deletion of the old one:

```console
$ git branch -m lakes seas && git push -u origin seas && git push origin --delete lakes
To ../server/atlas.git
 * [new branch]      seas -> seas
branch 'seas' set up to track 'origin/seas'.
To ../server/atlas.git
 - [deleted]         lakes
$ git branch -vv --list seas
  seas 3e06073 [origin/seas] List lakes
```

`git branch -m` renamed the local branch (Chapter 23), `-u` pushed the new name
and made it the upstream, and the deletion removed the old one. Other clones
still have `origin/lakes` until they prune (Chapter 41), and their local
branches still name it as upstream, so tell them.

## Rejected pushes

Bob pushed "Add Antarctica", and Ada committed a note without fetching:

```console
$ git push; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git fetch && git push; echo "exit $?"
From ../server/atlas
   a6303e5..5eb30d5  main       -> origin/main
To ../server/atlas.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git pull -q --rebase && git push
To ../server/atlas.git
   5eb30d5..811e3ff  main -> main
```

Both are the same situation seen with different knowledge. `fetch first`: the
server's `main` points at a commit Ada's repository does not even have, so Git
cannot tell whether her push would be a fast-forward and refuses. After the
fetch she has Bob's commit, Git can see her `main` does not contain it, and the
reason becomes `non-fast-forward`. Nothing was sent either time, and nothing
was lost. Bringing Bob's commit in, here with `git pull --rebase`
(Chapter 42), made the push a fast-forward. Chapter 45 is about this situation
in full: every way out, and how to avoid it.

### Several branches in one push

Bob pushed a commit to `rivers`. Ada committed on `main` and on `rivers`:

```console
$ git push origin main rivers; echo "exit $?"
To ../server/atlas.git
   811e3ff..1baae4f  main -> main
 ! [rejected]        rivers -> rivers (fetch first)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
```

Each ref is decided on its own: `main` went, `rivers` was rejected, and the exit
status says that something failed.

Ada committed on `main` again:

```console
$ git push --atomic origin main rivers; echo "exit $?"
error: atomic push failed for ref refs/heads/rivers. status: 5
To ../server/atlas.git
 ! [rejected]        main -> main (atomic push failed)
 ! [rejected]        rivers -> rivers (fetch first)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git ls-remote origin main && git rev-parse main origin/main
1baae4f97c32ba49ad975c1eaa8780f877eaff1a	refs/heads/main
bd3cc5d5db3fd9b341358a2b672e7908873cd1e9
1baae4f97c32ba49ad975c1eaa8780f877eaff1a
```

With `--atomic`, one rejection rejects everything: `main` is marked
`atomic push failed`, the server's `main` did not move, and neither did
`origin/main`. The `status: 5` in the first line is an internal code, not
something to act on. Git's documentation says the server must support atomic
pushes, and Git's own does. Use it when refs belong together, such as a branch
and the tag of its release.

## Forcing a push

Ada made a branch `drafts`, committed "Draft an idea", and pushed it with `-u`.
Then she reworded the commit, which replaces it (Chapter 29):

```console
$ git commit -q --amend -m 'Draft a better idea' && git push; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        drafts -> drafts (non-fast-forward)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git push --force
To ../server/atlas.git
 + 3998a23...9a5f602 drafts -> drafts (forced update)
$ git commit -q --amend -m 'Draft the best idea' && git push origin +drafts
To ../server/atlas.git
 + 9a5f602...c01d7f6 drafts -> drafts (forced update)
```

The amended commit does not contain the pushed one, so the push is rejected,
and the hint's advice to pull would be wrong here: it would merge the old commit
back in (Chapter 28). `--force`, or `-f`, pushes anyway, and the old commit is
no longer on the server's branch.

A `+` before a refspec forces that ref alone. Git's documentation warns that
`--force` applies to every ref a push sends, which matters when a push sends
several: with `push.default=matching` or several push refspecs, it can move
branches you did not mean to, back to older commits. `+<branch>` cannot.

> **Careful.** A force push removes from the branch every commit the server had
> that your branch lacks, including commits someone else pushed a minute ago.
> Chapter 28 decides when rewriting a shared branch is acceptable at all; the
> next section is how to force without losing work you have not seen.

### A lease

Bob fetched `drafts` and pushed a comment on top of "Draft the best idea". Ada,
without fetching, reworded her commit once more:

```console
$ git commit -q --amend -m 'Draft the final idea' && git push --force-with-lease; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        drafts -> drafts (stale info)
error: failed to push some refs to '../server/atlas.git'
exit 1
```

`--force-with-lease` forces only if the server's branch is still where your
remote-tracking branch says it is. Ada's `origin/drafts` still said
`c01d7f6`; the server's `drafts` had moved to Bob's commit, so the lease had
expired and nothing was pushed. `stale info` means Ada's information about the
branch is out of date. A plain `--force` would have thrown Bob's comment away.

```console
$ git fetch && git push --force-with-lease --dry-run
From ../server/atlas
   c01d7f6..c54a8e3  drafts     -> origin/drafts
To ../server/atlas.git
 + c54a8e3...9e88b84 drafts -> drafts (forced update)
```

After a fetch, the same push would go through, as the dry run shows: the lease
checks the server against `origin/drafts`, and the fetch had just moved
`origin/drafts` to Bob's commit, without Ada looking at it. Git's documentation
warns about exactly this, and about editors and scheduled jobs that fetch in the
background for you.

```console
$ git push --force-with-lease --force-if-includes; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        drafts -> drafts (remote ref updated since checkout)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git -c push.useForceIfIncludes=true push --force-with-lease; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        drafts -> drafts (remote ref updated since checkout)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git log --oneline drafts..origin/drafts
c54a8e3 Comment on the idea
c01d7f6 Draft the best idea
```

`--force-if-includes` closes that hole. Git's documentation says it checks that
the tip of the remote-tracking branch is reachable from an entry in the reflog
of your branch: that at some point your branch contained it, because you
rebased onto it, merged it or reset to it. Bob's commit arrived by fetch and was
never in Ada's `drafts`, so the push was refused. `push.useForceIfIncludes=true`
turns it on for every push with a lease. `git log` shows what the force would
have removed: Bob's commit, and the older version of Ada's own.

```console
$ git push --force-with-lease=drafts:$(git rev-parse origin/drafts~1) --dry-run; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        drafts -> drafts (stale info)
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git push --force-with-lease=drafts:origin/drafts --dry-run
To ../server/atlas.git
 + c54a8e3...9e88b84 drafts -> drafts (forced update)
$ git push --force-with-lease --no-force-with-lease --dry-run; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        drafts -> drafts (non-fast-forward)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git push --force-with-lease=ideas: origin drafts:ideas && git push --force-with-lease=ideas: origin main:ideas; echo "exit $?"
To ../server/atlas.git
 * [new branch]      drafts -> ideas
To ../server/atlas.git
 ! [rejected]        main -> ideas (stale info)
error: failed to push some refs to '../server/atlas.git'
exit 1
```

With `<refname>:<expect>`, the lease names the commit the branch must be at,
instead of reading it from the remote-tracking branch; Git's documentation says
this is the one form whose meaning is settled, and the others are still
experimental. An expected commit the branch is no longer at is refused. An empty
`<expect>` means the ref must not exist: the first push created `ideas`, and the
second, trying to create it again with different content, was refused.
`--no-force-with-lease` cancels the lease, and without it the push is an
ordinary one, rejected as a non-fast-forward.

| Form | Forces the update only if the server's ref is |
|---|---|
| `git push --force-with-lease` | where the matching remote-tracking branch says, for every ref pushed |
| `git push --force-with-lease=<refname>` | where the remote-tracking branch says, for that ref only |
| `git push --force-with-lease=<refname>:<expect>` | at the commit `<expect>` |
| `git push --force-with-lease=<refname>:` | missing |
| `git push --force-with-lease --force-if-includes` | where the remote-tracking branch says, and that commit was once in your branch |
| `git push --force` | anywhere at all |

> **Since Git 2.30.** `push.useForceIfIncludes`.

## Mirrors and pruning

```console
$ git push --mirror ../server/mirror.git
To ../server/mirror.git
 * [new branch]      deserts -> deserts
 * [new branch]      drafts -> drafts
 * [new branch]      main -> main
 * [new branch]      mountains -> mountains
 * [new branch]      rivers -> rivers
 * [new branch]      seas -> seas
 * [new reference]   backup/deserts -> backup/deserts
 * [new reference]   backup/main -> backup/main
 * [new reference]   fork/deserts -> fork/deserts
 * [new reference]   fork/main -> fork/main
 * [new reference]   origin/HEAD -> origin/HEAD
 * [new reference]   origin/deserts -> origin/deserts
 * [new reference]   origin/drafts -> origin/drafts
 * [new reference]   origin/ideas -> origin/ideas
 * [new reference]   origin/main -> origin/main
 * [new reference]   origin/mountains -> origin/mountains
 * [new reference]   origin/rivers -> origin/rivers
 * [new reference]   origin/seas -> origin/seas
 * [new tag]         checked -> checked
 * [new tag]         draft -> draft
 * [new tag]         v1.0 -> v1.0
 * [new tag]         v1.1 -> v1.1
 * [new tag]         v1.1-rc -> v1.1-rc
 * [new tag]         v1.2 -> v1.2
$ git branch -D mountains && git push --mirror ../server/mirror.git
Deleted branch mountains (was 70029e9).
To ../server/mirror.git
 - [deleted]         mountains
$ git push --mirror ../server/mirror.git main; echo "exit $?"
fatal: --mirror can't be combined with refspecs
exit 128
```

`--mirror` pushes every ref under `refs/`: branches, tags, and Ada's
remote-tracking branches too, as `[new reference]`. Git's documentation adds
that updates are forced, and a ref deleted here is deleted there, as `mountains`
was. It is for a backup that should match this repository exactly, and a remote
set up with `git remote add --mirror=push` does it on every push (Chapter 39).
It takes no refspecs, because it has already chosen all of them.

The backup repository had a branch `old-backup-branch` that Ada does not have:

```console
$ git ls-remote --branches backup && git push --prune backup 'refs/heads/*:refs/heads/*'
5adff1fc793f1f92a492da15912f592e4a725df0	refs/heads/deserts
c244fff89197fc5d9fe429223af3435458f130d5	refs/heads/main
bd3cc5d5db3fd9b341358a2b672e7908873cd1e9	refs/heads/old-backup-branch
To ../server/backup.git
   5adff1f..dfb90d7  deserts -> deserts
   c244fff..bd3cc5d  main -> main
 - [deleted]         old-backup-branch
 * [new branch]      drafts -> drafts
 * [new branch]      rivers -> rivers
 * [new branch]      seas -> seas
```

The refspec `refs/heads/*:refs/heads/*` pushes every branch (Chapter 44), and
`--prune` deletes, among the refs the refspec's right side covers, those with no
counterpart here. Unlike `--mirror`, it leaves tags and everything else alone,
and does not force.

> **Careful.** `--prune` and `--mirror` delete on the server whatever you do not
> have. On a shared repository that includes everyone else's branches.

## What the server can refuse

### Pushing to a repository with a working tree

A site is served from a non-bare repository, `website`, with `main` checked out.
Ada cloned it into `site-work` and committed a subtitle. In `site-work`:

```console
$ git push; echo "exit $?"
remote: error: refusing to update checked out branch: refs/heads/main        
remote: error: By default, updating the current branch in a non-bare repository        
remote: is denied, because it will make the index and work tree inconsistent        
remote: with what you pushed, and will require 'git reset --hard' to match        
remote: the work tree to HEAD.        
remote: 
remote: You can set the 'receive.denyCurrentBranch' configuration variable        
remote: to 'ignore' or 'warn' in the remote repository to allow pushing into        
remote: its current branch; however, this is not recommended unless you        
remote: arranged to update its work tree to match what you pushed in some        
remote: other way.        
remote: 
remote: To squelch this message and still keep the default behaviour, set        
remote: 'receive.denyCurrentBranch' configuration variable to 'refuse'.        
To /home/ada/website
 ! [remote rejected] main -> main (branch is currently checked out)
error: failed to push some refs to '/home/ada/website'
exit 1
```

Lines starting `remote:` are what the other side printed. Moving the branch that
is checked out there would leave its files and index describing the old commit,
the same mismatch Chapter 41 showed for `git fetch -u`. So the receiving side
refuses, and that is why servers hold bare repositories.

```console
$ git -C ../website config set receive.denyCurrentBranch updateInstead && git push && cat ../website/index.html
To /home/ada/website
   fc53a18..29bfaec  main -> main
<h1>Atlas</h1>
<p>Maps of the world</p>
```

`updateInstead`, set in the receiving repository, updates its working tree along
with the branch, which is a simple way to publish a site by pushing to it.

Ada committed a footer, and someone edited `index.html` on the server:

```console
$ git push; echo "exit $?"
To /home/ada/website
 ! [remote rejected] main -> main (Working directory has unstaged changes)
error: failed to push some refs to '/home/ada/website'
exit 1
```

Git's documentation says `updateInstead` refuses when the receiving working tree
or index differs from its `HEAD`, so edits made there are never overwritten.

| Value of `receive.denyCurrentBranch` | A push to the checked-out branch |
|---|---|
| `receive.denyCurrentBranch=refuse`, the default | is refused, with the long message |
| `receive.denyCurrentBranch=updateInstead` | updates the branch and the files, unless the files have changes |
| `receive.denyCurrentBranch=warn` | is accepted, with a warning; the files are left behind |
| `receive.denyCurrentBranch=ignore` | is accepted silently; the files are left behind |

### Rules the server sets

In the server's repository:

```console
$ git -C ../server/atlas.git config set receive.denyNonFastForwards true && git push --force origin main~1:main; echo "exit $?"
remote: error: denying non-fast-forward refs/heads/main (you should pull first)        
To ../server/atlas.git
 ! [remote rejected] main~1 -> main (non-fast-forward)
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git -C ../server/atlas.git config set receive.denyDeletes true && git push origin --delete seas; echo "exit $?"
remote: error: denying ref deletion for refs/heads/seas        
To ../server/atlas.git
 ! [remote rejected] seas (deletion prohibited)
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git push origin --delete v1.1-rc
To ../server/atlas.git
 - [deleted]         v1.1-rc
```

`--force` only switches off your own Git's check. The server has its own rules,
and `receive.denyNonFastForwards=true` refuses every non-fast-forward, forced or
not: `[remote rejected]`, not `[rejected]`. `git init --shared` sets it
(Chapter 9).

`receive.denyDeletes=true` refused deleting the branch `seas`, and let the tag
`v1.1-rc` be deleted. Git's documentation says it denies deleting a ref; Git's
source applies it, and `denyNonFastForwards`, only to refs under `refs/heads/`.
Hosting services have their own protected-branch rules, and a refusal by one
arrives the same way, as `remote rejected` with the host's explanation on
`remote:` lines.

### Hooks on the server

The server's repository has a `pre-receive` hook, a shell script in its `hooks`
directory, that refuses any branch named `wip-*` (Chapter 67). Ada committed on
`main` and made a branch `wip-volcanoes`:

```console
$ git push origin main wip-volcanoes; echo "exit $?"
remote: Checking refs/heads/main        
remote: Checking refs/heads/wip-volcanoes        
remote: Branches named wip-* stay on your own machine.        
To ../server/atlas.git
 ! [remote rejected] main -> main (pre-receive hook declined)
 ! [remote rejected] wip-volcanoes -> wip-volcanoes (pre-receive hook declined)
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git ls-remote origin main && git rev-parse main
3f7a6a88d1dc0a3e438bb0db60c64a5e29674014	refs/heads/main
19e228685d066262d7bb9e3f118023aa745a196e
```

What the hook printed reached Ada as `remote:` lines. The hook runs once for the
whole push, and Git's documentation says that if it fails, none of the refs are
updated, so `main`, which it had nothing against, was refused too. The `update`
hook, which runs once per ref, can refuse refs one by one.

### Push options

```console
$ git push -o ci.skip origin main; echo "exit $?"
fatal: the receiving end does not support push options
fatal: the remote end hung up unexpectedly
exit 128
$ git -C ../server/atlas.git config set receive.advertisePushOptions true && git push -o ci.skip -o reviewer=bob origin main
remote: Checking refs/heads/main        
remote: Push option: ci.skip        
remote: Push option: reviewer=bob        
To ../server/atlas.git
   3f7a6a8..19e2286  main -> main
```

`-o`, or `--push-option`, sends a string to the server's hooks, which receive
them in the environment variables `GIT_PUSH_OPTION_COUNT` and
`GIT_PUSH_OPTION_0`, `GIT_PUSH_OPTION_1` and so on, as Git's documentation for
hooks describes; this hook prints them. A server that does not advertise support
refuses the whole push, and Git's own server advertises it only with
`receive.advertisePushOptions=true`. What an option means is up to the server:
hosting services define options of their own, and Chapter 51 lists GitLab's.

Ada committed "Map the caves":

```console
$ git config set push.pushOption ci.skip && git push
remote: Checking refs/heads/main        
remote: Push option: ci.skip        
To ../server/atlas.git
   19e2286..8b9e2b2  main -> main
```

`push.pushOption` supplies options when the command line gives none.

## The pre-push hook

Ada's own repository has a `pre-push` hook that prints what it receives and
then refuses. She committed "Map the forests":

```console
$ git push; echo "exit $?"
pre-push: remote origin, url ../server/atlas.git
pre-push: refs/heads/main -> refs/heads/main
pre-push: refusing, as a test
error: failed to push some refs to '../server/atlas.git'
exit 1
$ git push --no-verify
To ../server/atlas.git
   8b9e2b2..3c9aa9b  main -> main
```

A `pre-push` hook runs on your side, before anything is sent, with the remote's
name and URL as arguments and a line per ref on standard input (Chapter 67).
When it fails, Git prints only "failed to push some refs", with no line for the
ref, so a push refused with no reason is usually a hook: look in `.git/hooks`.
`--no-verify` skips it. A hook is usually there to run a check, such as the
tests, so skip it only once you know why it refused.

## Dry runs and output for scripts

Ada committed "Map the deserts":

```console
$ git push --dry-run && git ls-remote origin main && git rev-parse origin/main
To ../server/atlas.git
   3c9aa9b..0286fe1  main -> main
3c9aa9bd60e06d85ff7c78926d1584f4c54704e6	refs/heads/main
3c9aa9bd60e06d85ff7c78926d1584f4c54704e6
$ git push --porcelain
To ../server/atlas.git
 	refs/heads/main:refs/heads/main	3c9aa9b..0286fe1
Done
$ git push --porcelain -v
Pushing to ../server/atlas.git
updating local tracking ref 'refs/remotes/origin/main'
To ../server/atlas.git
=	refs/heads/main:refs/heads/main	[up to date]
Done
```

`--dry-run`, or `-n`, contacts the server and decides everything, and sends
nothing: the server's `main` and Ada's `origin/main` were still at `3c9aa9b`.

`--porcelain` prints a line per ref on standard output: the flag, a tab, the
full names as `<local>:<remote>`, a tab, and the summary. `Done` ends it. Up to
date refs are listed without needing `-v`, as Git's documentation says; the `-v`
only added the lines at the top.

Bob pushed a commit, and Ada committed "Map the lakes":

```console
$ git push --porcelain; echo "exit $?"
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
To ../server/atlas.git
!	refs/heads/main:refs/heads/main	[rejected] (fetch first)
Done
exit 1
$ git pull -q --rebase && git push -q; echo "exit $?"
exit 0
```

A rejection is a `!` line with the reason, and the exit status is non-zero. The
error and hints went to standard error, and reached the pipe before the lines
on standard output; a script that reads standard output sees only the table.

Ada committed "Map the seas":

```console
$ git push --progress 2>&1 | tr '\r' '\n' | grep -E '^(Enumerating|Counting|Compressing).*done|^Total|->'
Enumerating objects: 6, done.
Counting objects: 100% (6/6), done.
Compressing objects: 100% (3/3), done.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
   5e7dbda..3e2e76f  main -> main
```

On a terminal, a push shows progress as it prepares and sends the objects.
Git's documentation says progress appears only when standard error is a
terminal, and `--progress` forces it. Each line is redrawn in place with
carriage returns; `tr` turns them into new lines and `grep` keeps the final
state, as in Chapter 41. The `grep` also leaves out the `Writing objects` line,
which includes a transfer speed that changes on every run, and on a terminal
comes between `Compressing` and `Total`.

## Publishing a new repository

Ada started a gazetteer on her own computer, as a repository with no remote.
The server needs an empty bare repository to receive it; on a hosting service,
creating a repository without a README makes the same thing. In the gazetteer:

```console
$ git init -q --bare ../server/gazetteer.git
$ git remote add origin ../server/gazetteer.git && git push -u origin main; echo "exit $?"
error: src refspec main does not match any
error: failed to push some refs to '../server/gazetteer.git'
exit 1
```

The gazetteer had no commit yet, so there was no branch `main` to push, only the
name waiting for a first commit (Chapter 9).

Ada committed "Start the gazetteer":

```console
$ git push -u origin main
To ../server/gazetteer.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
$ git clone -q ../server/gazetteer.git ../gazetteer-copy && git -C ../gazetteer-copy log --oneline
c723e8d Start the gazetteer
```

Into an empty repository every branch is new. `-u` set the upstream, so from
now on a plain `git push` and `git pull` work, and the clone shows the
repository is complete. A hosting service that created a README has a commit
of its own, and the first push is then rejected; Chapter 42 shows the
`refusing to merge unrelated histories` that follows a pull.

## The conversation

Chapter 41 traced a fetch. Ada committed "Map the rivers", and traced a push:

```console
$ GIT_TRACE_PACKET=1 git push 2>&1 | grep -o 'push[<>].*'
push< dfb90d7ed5b43dd629cd4834fc7d19eda5979f42 refs/heads/deserts\0report-status report-status-v2 delete-refs side-band-64k quiet atomic ofs-delta push-options object-format=sha1 agent=git/2.55.0.windows.5-Windows
push< c54a8e388e532647814326a4230f3bb1eddcd5ef refs/heads/drafts
push< 9e88b84a1e537ce8a0fc95b0357bfc1bb4f28a36 refs/heads/ideas
push< 3e2e76fb784604b2cde5ccaa133090f432b905fb refs/heads/main
push< 70029e9608800b8a679fc60f97bc23e9530459fd refs/heads/mountains
push< 198624d68dded025fe4d129413854aa4839b58c6 refs/heads/rivers
push< 3e06073b90b6b59caa488af22eb12eae014965ec refs/heads/seas
push< 72e681f7d95bdb69f4b637a805731bf85d522c68 refs/tags/v1.0
push< 4bc134cbc687f58b59a9289fde521ed8d1f9a046 refs/tags/v1.1
push< d3f509c5bc5e6cca3130c4f10d94ea29eeb81278 refs/tags/v1.2
push< 0000
push> 3e2e76fb784604b2cde5ccaa133090f432b905fb 416cb976db42665a1373e3f2edb858891ea5b307 refs/heads/main\0 report-status-v2 side-band-64k quiet object-format=sha1 agent=git/2.55.0.windows.5-Windows
push> 0000
push< unpack ok
push< ok refs/heads/main
push< 0000
```

`<` is what the server's `git-receive-pack` sent, `>` what Ada's Git sent:

| Lines | Mean |
|---|---|
| `push<` hash and ref, to `0000` | every ref the server has; the first line also lists what the server supports after `\0`, such as `atomic` and `push-options` |
| `push>` old hash, new hash, ref | the update Ada asks for: move `main` from `3e2e76f` to `416cb97`; `0000` ends the list |
| (not in the trace) | the pack of objects the server lacks |
| `unpack ok` | the server stored the objects |
| `ok refs/heads/main` | and updated the ref; a refused ref gets `ng` and the reason |

This is where every check of this chapter happens. Your Git compares the old
hashes in the list with what you push, to reject non-fast-forwards and expired
leases before anything is sent, and the server decides the rest when it reads
the update lines. There is no `command=` line: Git's documentation for protocol
version 2 (Chapter 40) defines commands for listing refs and fetching and none
for pushing, so a push uses the older exchange.

Ada committed "Map the mountains":

```console
$ GIT_TRACE_PACKET=1 git -c push.negotiate=true push 2>&1 | grep -o 'fetch> have.*\|fetch< ACK.*\|push> [0-9a-f]* [0-9a-f]* refs/heads/main'
fetch> have f254e58929b3d764f0ff845f3a1fef2179e04c3b
fetch> have 416cb976db42665a1373e3f2edb858891ea5b307
fetch> have 3e2e76fb784604b2cde5ccaa133090f432b905fb
...
fetch< ACK 416cb976db42665a1373e3f2edb858891ea5b307
push> 416cb976db42665a1373e3f2edb858891ea5b307 f254e58929b3d764f0ff845f3a1fef2179e04c3b refs/heads/main
```

Normally a push works out which commits the server already has from its list of
refs alone. With `push.negotiate=true`, Git first runs the same `have` and `ACK`
exchange a fetch uses (Chapter 41), which Git's documentation says is to reduce
the size of the pack sent, when the list alone would miss commits in common. The `have` list is cut; the server
acknowledged the commit its `main` points at.

> **Since Git 2.32.** `push.negotiate`.

### Thin packs

Two identical copies of the atlas were made, `copy1.git` and `copy2.git`, with
an index of 40 maps in `maps/index.txt`. Ada added one line to the index, and
pushed the commit to each:

```console
$ git push --progress ../server/copy1.git main 2>&1 | tr '\r' '\n' | grep -E 'Total|->'
Total 4 (delta 2), reused 0 (delta 0), pack-reused 0 (from 0)
   5946cb5..49889c8  main -> main
$ git push --progress --no-thin ../server/copy2.git main 2>&1 | tr '\r' '\n' | grep -E 'Total|->'
Total 4 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
   5946cb5..49889c8  main -> main
```

The same four objects were sent both times. By default two of them went as
*deltas*, differences from objects that are not in the pack because the server
already has them, which Git's protocol documentation calls a thin pack.
`--no-thin` sent all four whole. Chapter 72 explains deltas. Thin is the
default, and a server that cannot take a thin pack says so itself, so the
option is rarely needed.

### The program on the other end

Ada committed "Map the plains":

```console
$ git push --receive-pack=git-receive-pack
To ../server/atlas.git
   5946cb5..d147d3c  main -> main
$ git push --exec=no-such-program; echo "exit $?"
no-such-program '../server/atlas.git': line 1: no-such-program: command not found
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
exit 128
```

A push runs `git-receive-pack` on the other side, as Chapter 40 describes.
`--receive-pack`, or its other name `--exec`, names a different program, for a
server where Git is installed outside the path its login shell searches; the
first command named the default. `remote.<name>.receivepack` sets it for a
remote.

## push and its neighbours

| To | Use | Difference |
|---|---|---|
| send commits and move the server's branches | `git push` | changes another repository |
| receive commits and update your remote-tracking branches | `git fetch` (Chapter 41) | the other direction; never refused for being behind |
| receive and integrate | `git pull` (Chapter 42) | what to run when a push is rejected |
| see the server's refs without sending anything | `git ls-remote` (Chapter 39), `git push --dry-run` | the second also shows what a push would do |
| copy every ref to a backup | `git push --mirror`, or a push mirror (Chapter 39) | forced, with deletions |
| send commits without a server | `git bundle`, `git format-patch` (Chapter 61) | files you carry or mail |
| ask someone to pull from you | `git request-pull` (Chapter 61), or a pull request (Chapter 50) | you push to your own repository, they merge |

## The settings

On your side:

| Setting | Does |
|---|---|
| `push.default` | What a plain push sends: `simple`, `current`, `upstream`, `matching` or `nothing` |
| `push.autoSetupRemote` | A plain push of a branch with no upstream acts as `-u` |
| `remote.pushDefault` | The remote plain pushes go to, for every branch |
| `branch.<name>.pushRemote` | The remote plain pushes of one branch go to |
| `remote.<name>.push` | Push refspecs used when none is given; they come before `push.default` (Chapter 44) |
| `remote.<name>.pushurl` | Where pushes to this remote go, instead of its `url` (Chapter 39) |
| `remote.<name>.mirror` | Every push to this remote acts as `--mirror` (Chapter 39) |
| `remote.<name>.receivepack` | The program to run on the server |
| `remotes.<group>` | A group of remotes, usable as the repository |
| `push.followTags` | Every push acts as `--follow-tags` |
| `push.useForceIfIncludes` | `--force-with-lease` also checks `--force-if-includes` |
| `push.pushOption` | Push options used when the command line gives none |
| `push.negotiate` | Find common commits by negotiation before pushing |
| `push.gpgSign` | Sign pushes (Chapter 68) |
| `push.recurseSubmodules` | `check`, `on-demand`, `only` or `no` for submodule commits (Chapter 57) |
| `push.useBitmaps` | `false` stops push using reachability bitmaps (Chapter 69) |
| `advice.pushUpdateRejected` | `false` removes the hints printed with rejections |

On the receiving repository:

| Setting | Does |
|---|---|
| `receive.denyCurrentBranch` | What happens to a push to the checked-out branch |
| `receive.denyNonFastForwards` | Refuse every non-fast-forward to a branch, forced or not |
| `receive.denyDeletes` | Refuse deleting a branch |
| `receive.denyDeleteCurrent` | Refuse deleting the checked-out branch of a non-bare repository |
| `receive.advertisePushOptions` | Accept push options |
| `receive.advertiseAtomic` | Offer atomic pushes; on by default |
| `receive.fsckObjects`, `transfer.fsckObjects` | Check every received object (Chapter 81) |
| `receive.hideRefs`, `transfer.hideRefs` | Refs left out of the list the server sends |
