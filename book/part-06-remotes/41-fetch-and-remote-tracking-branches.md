# Chapter 41. fetch and Remote-Tracking Branches

## What it is

`git fetch` downloads from another repository the commits, trees, blobs and tags
you do not have yet, and records where that repository's branches are, in
*remote-tracking branches* such as `origin/main`. On its own it answers one
question: *what has happened on the server since I last looked?*

It never changes your own branches, your staged changes or your files. After a
fetch you have the new commits and a record of where they belong, and deciding
what to do with them, merging, rebasing or nothing, is a separate step
(Chapter 42). That is why fetching is always safe, and why it is worth doing
before any comparison with the server means anything.

| Term | Means |
|---|---|
| *remote-tracking branch* | your repository's record of a branch on a remote, as of the last fetch: `origin/main`, stored as `refs/remotes/origin/main` |
| *upstream* | the remote-tracking branch a local branch is compared with and pulls from, set by `branch.<name>.remote` and `branch.<name>.merge` (Chapter 23) |
| *refspec* | a rule `<source>:<destination>` saying which refs to fetch and where to store them; `+` in front allows a forced update (Chapter 44) |
| *fast-forward* | an update where the new commit contains the old one in its history, so nothing is lost |
| *forced update* | an update where it does not: the branch on the server was rewritten |
| *stale* | a remote-tracking branch whose branch was deleted on the server |
| *prune* | delete stale remote-tracking branches |
| *`FETCH_HEAD`* | a file in `.git` listing what the last fetch fetched, usable as a revision |
| *tag following* | fetching the tags that point into the history just fetched, which `git fetch` does by default |
| *negotiation* | the exchange in which your side tells the server which commits it already has, so that only the missing ones are sent |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does `git fetch` do, and can it change my files or my branches?](#what-it-is)
- [What is the difference between `origin/main` and `main`?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git fetch`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is shown?](#options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repositories do the examples use, and what changed on the server?](#the-example-repository)

**[Reading the output](#reading-the-output)**

- [What do the symbols `*`, `+`, `-`, `t`, `!` and `=` at the start of fetch's lines mean?](#reading-the-output)
- [Why do some lines have two dots between the hashes and some three?](#reading-the-output)
- [`git fetch` printed nothing. Did it work?](#reading-the-output)
- [What does "would clobber existing tag" mean?](#reading-the-output)

**[Remote-tracking branches](#remote-tracking-branches)**

- [Where are remote-tracking branches kept, and how do I list them?](#remote-tracking-branches)
- [How do I see which commits the server has that I don't?](#remote-tracking-branches)
- [Can I commit on `origin/main`?](#remote-tracking-branches)
- [How do I start working on a branch that only exists on the server?](#remote-tracking-branches)
- [Do remote-tracking branches have a reflog?](#remote-tracking-branches)
- [I deleted `origin/deserts` by hand. What happens at the next fetch?](#deleting-one)

**[What fetch does not change](#what-fetch-does-not-change)**

- [After `git fetch`, why are my files still the old version?](#what-fetch-does-not-change)
- [Why does `git status` say "up to date" when the server has new commits?](#what-fetch-does-not-change)
- [Does `git fetch --dry-run` download anything?](#a-dry-run)

**[Which remote](#which-remote)**

- [Which remote does a plain `git fetch` fetch from?](#which-remote)
- [How do I fetch from two remotes? `git fetch origin bob` fails.](#which-remote)
- [How do I fetch from every remote at once, or make that the default?](#which-remote)
- [What does `git fetch` do in a repository with no remotes?](#which-remote)
- [Can I fetch from a URL without adding a remote?](#fetching-from-a-url)

**[Fetching particular branches](#fetching-particular-branches)**

- [How do I fetch just one branch?](#fetching-particular-branches)
- [Does `git fetch origin main` update `origin/main`?](#fetching-particular-branches)
- [What does "couldn't find remote ref" mean?](#fetching-particular-branches)
- [Can I fetch straight into a local branch, without switching to it?](#into-a-local-branch)
- [Why did fetch say `[rejected] (non-fast-forward)`?](#into-a-local-branch)
- [Why won't Git fetch into the branch I'm on, and what happens if I force it?](#into-a-local-branch)
- [Can I fetch one commit by its hash?](#a-commit)
- [How do I fetch a branch without updating the remote-tracking branches, or into a different name?](#choosing-where-copies-go)
- [Can a script give fetch its list of branches on standard input?](#choosing-where-copies-go)
- [How do I set a branch's upstream while fetching?](#setting-the-upstream-while-fetching)

**[FETCH_HEAD](#fetchhead)**

- [What is `FETCH_HEAD`, and what does "not-for-merge" mean in it?](#fetchhead)
- [How do I look at what I fetched from a URL?](#fetchhead)
- [Can two fetches add to `FETCH_HEAD` instead of replacing it?](#fetchhead)

**[Tags](#tags)**

- [Which tags does `git fetch` bring, and why not all of them?](#tags)
- [How do I fetch every tag, or no tags?](#tags)
- [How do I fetch one particular tag?](#tags)
- [I fetched one tag and got another one too. Why?](#tags)
- [A tag was moved on the server and my copy didn't change. How do I update it?](#a-tag-that-moved)

**[Pruning](#pruning)**

- [A branch was deleted on the server. Why do I still have `origin/<branch>`?](#pruning)
- [How do I find and delete my local branches whose server branch is gone?](#pruning)
- [How do I make every fetch prune?](#pruning-on-every-fetch)
- [Can fetch delete my tags? What does `--prune-tags` do?](#pruning-tags)

**[Forced updates](#forced-updates)**

- [What does "(forced update)" mean, and what should I do about it?](#forced-updates)
- [Fetch warned that the forced-update check is disabled. What did I lose?](#forced-updates)

**[The remote's HEAD](#the-remote-s-head)**

- [The server changed its default branch. Does fetch update `origin/HEAD`?](#the-remote-s-head)
- [What do the values of `followRemoteHEAD` do?](#the-remote-s-head)
- [I set the value the hint suggested and the warning did not go away. Why?](#the-remote-s-head)

**[Quiet, verbose and progress](#quiet-verbose-and-progress)**

- [How do I make fetch silent, or show more?](#quiet-verbose-and-progress)
- [Why don't I see the "Receiving objects" progress when I redirect the output?](#quiet-verbose-and-progress)

**[Output for scripts](#output-for-scripts)**

- [What output format should a script read?](#output-for-scripts)
- [How do I make fetch's lines shorter?](#output-for-scripts)

**[All or nothing](#all-or-nothing)**

- [One ref was rejected. Were the others updated anyway?](#all-or-nothing)
- [What does `--atomic` change?](#all-or-nothing)

**[The conversation](#the-conversation)**

- [What exactly do Git and the server say during a fetch?](#the-conversation)
- [What are "want", "have" and "ACK"?](#the-conversation)
- [Can I choose which of my commits fetch tells the server about?](#what-the-client-says-it-has)
- [Where do the fetched objects end up, and what does `--keep` change?](#keeping-the-pack)

**[fetch and its neighbours](#fetch-and-its-neighbours)**

- [What is the difference between `git fetch` and `git pull`?](#fetch-and-its-neighbours)
- [Should I use `git fetch --all` or `git remote update`?](#fetch-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings change what fetch does?](#the-settings)

</details>

## Synopsis

```
git fetch [<options>] [<repository> [<refspec>...]]
git fetch [<options>] <group>
git fetch --multiple [<options>] [(<repository>|<group>)...]
git fetch --all [<options>]
```

| Part | Means |
|---|---|
| `<repository>` | A remote's name or a URL; left out, the current branch's remote, or `origin` |
| `<refspec>` | What to fetch and where to put it: `main`, `main:local`, `+drafts:refs/remotes/origin/drafts`, `tag v1.0`, or a full commit hash |
| `<group>` | A name defined by the setting `remotes.<group>`, standing for several remotes |

| Command | Does |
|---|---|
| `git fetch` | Fetch from the current branch's remote everything its fetch refspecs cover |
| `git fetch origin` | The same from a named remote |
| `git fetch origin main` | Fetch one branch; record it in `FETCH_HEAD` and update `origin/main` |
| `git fetch origin main:topic` | Fetch `main` into the local branch `topic`, if that is a fast-forward |
| `git fetch --prune` | Also delete remote-tracking branches whose branch is gone |
| `git fetch --tags` | Also fetch every tag |
| `git fetch --all` | Fetch from every remote |
| `git fetch <url> <branch>` | Fetch from a repository that is not a remote, into `FETCH_HEAD` only |

## Options at a glance

### Which remotes

| Option | Does | Covered in |
|---|---|---|
| `--all`, `--no-all` | Every remote, or not, whatever `fetch.all` says | [Which remote](#which-remote) |
| `--multiple` | Allow several remotes and groups as arguments | [Which remote](#which-remote) |
| `-j <n>`, `--jobs=<n>` | Fetch several remotes, or submodules, in parallel | [Which remote](#which-remote) |

<!-- no-example: -j
     With --multiple or --all, -j fetches the remotes in parallel. Tried with
     two remotes that had nothing to fetch: the output was identical to --all.
     With real work to do, the order in which parallel fetches print is not
     fixed, so a transcript would not match the next run. -->

### What to fetch and where it goes

| Option | Does | Covered in |
|---|---|---|
| `--refmap=<refspec>` | Store fetched refs by this rule instead of the remote's fetch refspecs | [Choosing where copies go](#choosing-where-copies-go) |
| `--stdin` | Read refspecs from standard input, one per line | [Choosing where copies go](#choosing-where-copies-go) |
| `-f`, `--force` | Allow updates that are not fast-forwards, like `+` in every refspec | [Into a local branch](#into-a-local-branch) |
| `-u`, `--update-head-ok` | Allow fetching into the checked-out branch; meant for Git's own use | [Into a local branch](#into-a-local-branch) |
| `--set-upstream` | Make what was fetched the current branch's upstream | [Setting the upstream while fetching](#setting-the-upstream-while-fetching) |
| `-a`, `--append` | Add to `FETCH_HEAD` instead of replacing it | [FETCH_HEAD](#fetchhead) |
| `--write-fetch-head`, `--no-write-fetch-head` | Write `FETCH_HEAD`, or not | [FETCH_HEAD](#fetchhead) |

### Tags and pruning

| Option | Does | Covered in |
|---|---|---|
| `-t`, `--tags` | Fetch every tag as well | [Tags](#tags) |
| `-n`, `--no-tags` | Fetch no tags, not even the followed ones | [Tags](#tags) |
| `-p`, `--prune` | Delete stale remote-tracking branches first | [Pruning](#pruning) |
| `-P`, `--prune-tags` | With `--prune`, also delete local tags the remote does not have | [Pruning tags](#pruning-tags) |
| `--show-forced-updates`, `--no-show-forced-updates` | Check for forced updates, or skip the check | [Forced updates](#forced-updates) |

### Output

| Option | Does | Covered in |
|---|---|---|
| `-q`, `--quiet` | Print nothing but errors | [Quiet, verbose and progress](#quiet-verbose-and-progress) |
| `-v`, `--verbose` | Also list refs that did not change | [Reading the output](#reading-the-output) |
| `--progress` | Show progress even when not writing to a terminal | [Quiet, verbose and progress](#quiet-verbose-and-progress) |
| `--porcelain` | One machine-readable line per ref, on standard output | [Output for scripts](#output-for-scripts) |
| `--dry-run` | Report what would change, and change no ref | [A dry run](#a-dry-run) |
| `--atomic` | Update every ref or none | [All or nothing](#all-or-nothing) |

### Negotiation

| Option | Does | Covered in |
|---|---|---|
| `--negotiation-restrict=<revision>`, `--negotiation-tip=<revision>` | Tell the server only about commits reachable from these | [What the client says it has](#what-the-client-says-it-has) |
| `--negotiation-include=<revision>` | Always tell the server about these | [What the client says it has](#what-the-client-says-it-has) |
| `--negotiate-only` | Print the commits in common with the server, and fetch nothing | [What the client says it has](#what-the-client-says-it-has) |

> **Since Git 2.55.** `--negotiation-restrict` and `--negotiation-include`.
> `--negotiation-tip` is the older name, and still accepted.

### Covered in other chapters

| Option | Does | Covered in |
|---|---|---|
| `--depth=<n>`, `--deepen=<n>`, `--shallow-since=<date>`, `--shallow-exclude=<ref>` | Fetch a shallow history, or change its depth | Chapter 46 |
| `--unshallow`, `--update-shallow` | Make a shallow repository complete, or accept refs that need it deeper | Chapter 46 |
| `--filter=<spec>`, `--refetch` | Partial clone filters | Chapter 46 |
| `--recurse-submodules[=<when>]`, `--no-recurse-submodules` | Fetch in submodules too | Chapter 57 |
| `--recurse-submodules-default=<when>`, `--submodule-prefix=<path>` | Used internally when fetching submodules | Chapter 57 |
| `--auto-maintenance`, `--auto-gc`, `--write-commit-graph` | Housekeeping after fetching | Chapter 69 |
| `--prefetch` | Fetch into `refs/prefetch/`, for background maintenance | Chapter 69 |
| `--upload-pack <program>` | The program to run on the server | Chapter 39 |
| `-o <option>`, `--server-option=<option>` | Send a string to the server | Chapter 39 |
| `-4`, `-6` | Use only IPv4, or only IPv6, addresses; also spelled `--ipv4` and `--ipv6` | Chapter 40 |
| `-k`, `--keep` | Keep the downloaded pack, the file the objects arrive in | [Keeping the pack](#keeping-the-pack) |


## The example repository

```console
$ git log --oneline --graph --all --decorate
* b2b2f85 (origin/drafts) Draft an idea
| * 255682e (origin/rivers) List rivers
|/  
* 0fe19df (HEAD -> main, tag: v1.0, origin/main, origin/HEAD) Add Europe
* 0dd6887 Start the atlas
```

Ada cloned the team's atlas from a bare repository, `/home/ada/server/atlas.git`
(Chapter 9). The graph is her clone: her `main`, and the remote-tracking branches
the clone made. Bob works in a clone of his own and pushes to the same server.

Since Ada cloned, Bob has added a commit to `main`, pushed a new branch
`deserts`, rewritten `drafts` and force-pushed it, deleted `rivers`, added a tag
`v1.1`, and moved the tag `v1.0` to his new commit. `git ls-remote`
(Chapter 39) shows the server as it is now, without fetching anything:

```console
$ git ls-remote origin
0dbdc880eb0e3ff85d215510620f39a74a8a8ea2	HEAD
8786d838f680a7ba8f6968618551a595e0ca810e	refs/heads/deserts
1656595cae95ad32e2457f0cbb5374884d1c90f8	refs/heads/drafts
0dbdc880eb0e3ff85d215510620f39a74a8a8ea2	refs/heads/main
9c338766d934f191fb1707f2e5833b61cee233d6	refs/tags/v1.0
0dbdc880eb0e3ff85d215510620f39a74a8a8ea2	refs/tags/v1.0^{}
0dbdc880eb0e3ff85d215510620f39a74a8a8ea2	refs/tags/v1.1
```

Bob keeps working through the chapter, and each section says what he pushed
before its fetch. Every command runs in Ada's clone.

## Reading the output

```console
$ git fetch
From /home/ada/server/atlas
   0fe19df..0dbdc88  main       -> origin/main
 * [new branch]      deserts    -> origin/deserts
 + b2b2f85...1656595 drafts     -> origin/drafts  (forced update)
 * [new tag]         v1.1       -> v1.1
$ git fetch
```

`From` names the repository, then there is one line per ref that changed, in
columns: a flag, a summary, the ref on the server, an arrow, and the ref it was
stored as here. Git's documentation defines the flags:

| Flag | Means |
|---|---|
| ` ` (space) | an update that is a fast-forward |
| `+` | a forced update: the old commit is not in the new one's history |
| `-` | a ref pruned, deleted because the server no longer has it |
| `t` | a tag updated |
| `*` | a new ref |
| `!` | a ref rejected, or that failed to update |
| `=` | a ref already up to date; listed only with `-v` |

The summary for an update is a range you can paste into `git log`
(Chapter 18): `0fe19df..0dbdc88` with two dots for a fast-forward, meaning the
commits added, and `b2b2f85...1656595` with three for a forced update, meaning
the commits on either side. For a new ref it is the word in brackets.

The second `git fetch` printed nothing, because nothing had changed: silence is
success. `v1.0`, although Bob moved it, is not mentioned; [Tags](#tags) explains
why.

```console
$ git fetch -v
From /home/ada/server/atlas
 = [up to date]      main       -> origin/main
 = [up to date]      deserts    -> origin/deserts
 = [up to date]      drafts     -> origin/drafts
$ git fetch --prune
From /home/ada/server/atlas
 - [deleted]         (none)     -> origin/rivers
$ git fetch --tags
From /home/ada/server/atlas
 ! [rejected] v1.0       -> v1.0  (would clobber existing tag)
$ git fetch --tags --force
From /home/ada/server/atlas
 t [tag update]      v1.0       -> v1.0
```

The other flags. `-v` lists what did not change. `--prune` deleted
`origin/rivers`, whose server branch is gone, and a deletion has no source, so
the server side reads `(none)`. `--tags` asked for every tag, including `v1.0`,
whose server copy now differs from Ada's, and Git refused to overwrite a tag,
with the reason in brackets; `--force` allowed it. Each of these has a section
below.

## Remote-tracking branches

```console
$ git branch -r
  origin/HEAD -> origin/main
  origin/deserts
  origin/drafts
  origin/main
$ git for-each-ref --format='%(refname)' refs/remotes
refs/remotes/origin/HEAD
refs/remotes/origin/deserts
refs/remotes/origin/drafts
refs/remotes/origin/main
$ git log --oneline main..origin/main
0dbdc88 Add Africa
$ git status -sb
## main...origin/main [behind 1]
```

A remote-tracking branch is an ordinary ref under `refs/remotes/<remote>/`, and
every command that takes a revision takes one. `git branch -r` lists them
(Chapter 23). The fetch refspec `+refs/heads/*:refs/remotes/origin/*` is what put
them there: each branch `X` on `origin` became `origin/X` (Chapter 39).

Their use is comparison. `main..origin/main` is the commits the server's `main`
has and Ada's does not (Chapter 18), and `git status` counts them, but only up
to the last fetch: until then, the server's newer commits are invisible to both.

```console
$ git reflog show origin/drafts
1656595 refs/remotes/origin/drafts@{0}: fetch: forced-update
$ git switch origin/drafts
fatal: a branch is expected, got remote branch 'origin/drafts'
hint: If you want to detach HEAD at the commit, try again with the --detach option.
$ git switch -q --detach origin/drafts && git status | head -1 && git switch -q main
HEAD detached at origin/drafts
```

A remote-tracking branch has a reflog like any branch, written by fetch, so
`origin/drafts@{1}` is where it was before (Chapter 36); here it has a single
entry, the forced update.

You do not commit on a remote-tracking branch. Only fetch moves it, and
`git switch` refuses to make it the current branch; with `--detach` you can look
at its commit, on a detached `HEAD` (Chapter 24). To work on a branch that
exists only on the server, make a local branch from it: `git switch deserts`
does that when exactly one remote has a `deserts`, as Chapter 24 shows, and sets
`origin/deserts` as its upstream.

### Deleting one

```console
$ git branch -d -r origin/deserts && git fetch
Deleted remote-tracking branch origin/deserts (was 8786d83).
From /home/ada/server/atlas
 * [new branch]      deserts    -> origin/deserts
```

Deleting a remote-tracking branch by hand deletes only the record. The branch
is still on the server and the refspec still covers it, so the next fetch
brings it back as new, as Git's documentation for `git branch` warns. To stop
fetching a branch, change the refspec (Chapter 39); to remove the branch, delete
it on the server (Chapter 43).

## What fetch does not change

Bob pushed a commit to `main`:

```console
$ git log --oneline -1 main && git status --short && git fetch && git log --oneline -1 main && git status -sb
0fe19df Add Europe
From /home/ada/server/atlas
   0dbdc88..ed4a0f7  main       -> origin/main
0fe19df Add Europe
## main...origin/main [behind 2]
```

The fetch moved `origin/main`. Ada's `main` is where it was, her working tree is
clean and has the same files, and only `git status` changed its count. The new
commits are in the repository, and `git merge`, `git rebase` or `git pull`
brings them into `main` (Chapter 25, Chapter 33, Chapter 42).

This is also why `git status` never contacts the server on its own. A status
that fetched would be slow, would fail with no network, and would give a
different answer each time it ran, while a status against the last fetch is
instant and reproducible. So a status of "up to date" means "up to date with the
last fetch", and `git fetch` first is what makes it mean the server.

### A dry run

Bob pushed another commit:

```console
$ git count-objects && git fetch --dry-run && git count-objects && git log --oneline -1 origin/main
27 objects, 2 kilobytes
From /home/ada/server/atlas
   ed4a0f7..60de880  main       -> origin/main
31 objects, 2 kilobytes
ed4a0f7 Add Asia
$ git fetch
From /home/ada/server/atlas
   ed4a0f7..60de880  main       -> origin/main
```

`--dry-run` printed what a fetch would do and left `origin/main` where it was, as
the next fetch, printing the same line, confirms. It did download: the
repository gained four objects, counted by `git count-objects` (Chapter 71). A
dry run spares the refs, not the network, and the real fetch after it had
nothing left to download.

## Which remote

Bob also has a fork, at `/home/ada/server/bob-atlas.git`, with a branch
`mountains`:

```console
$ git remote add bob /home/ada/server/bob-atlas.git
$ git fetch bob && git switch -q -c mountains bob/mountains
From /home/ada/server/bob-atlas
 * [new branch]      mountains  -> bob/mountains
$ git fetch -v
From /home/ada/server/bob-atlas
 = [up to date]      mountains  -> bob/mountains
$ git switch -q main && git fetch -v
From /home/ada/server/atlas
 = [up to date]      main       -> origin/main
 = [up to date]      deserts    -> origin/deserts
 = [up to date]      drafts     -> origin/drafts
```

With no remote named, fetch uses the current branch's remote: on `mountains`,
which tracks `bob/mountains`, it fetched from `bob`; on `main`, from `origin`.
Git's documentation gives the rule as "`origin`, unless the current branch has
an upstream"; Chapter 39 showed from Git's source that a repository with exactly
one remote uses that one.

```console
$ git fetch origin bob
fatal: couldn't find remote ref bob
$ git fetch --multiple origin bob
Fetching origin
Fetching bob
$ git fetch --all
Fetching origin
Fetching bob
$ git -c remotes.everyone='origin bob' fetch everyone
Fetching origin
Fetching bob
$ git -c fetch.all=true fetch
Fetching origin
Fetching bob
$ git -c fetch.all=true fetch --no-all
$ git -C /home/ada/lonely fetch; echo "exit $?"
exit 0
```

After a remote's name, the next words are refspecs, so `git fetch origin bob`
looked for a branch called `bob` on `origin`. `--multiple` makes every argument a
remote or a group. `--all` fetches every remote, except those with
`remote.<name>.skipFetchAll` (Chapter 39), and a group from `remotes.<group>`
fetches its members. Each fetch is announced with `Fetching`; nothing new was
found, so nothing else was printed.

`fetch.all=true` makes a bare `git fetch` behave like `--all`, and `--no-all`
overrides it for one command, which then fetched `origin` alone. In a repository
with no remotes at all, `/home/ada/lonely`, a bare `git fetch` does nothing and
reports success.

> **Since Git 2.44.** `fetch.all`.

### Fetching from a URL

```console
$ git fetch /home/ada/server/atlas.git deserts
From /home/ada/server/atlas
 * branch            deserts    -> FETCH_HEAD
$ git log --oneline -1 FETCH_HEAD
8786d83 List deserts
```

A URL works where a remote's name does, for a repository you want to look at
once. With no remote there are no fetch refspecs and no remote-tracking
branches, so the result is only recorded in [`FETCH_HEAD`](#fetchhead); the
objects are in the repository, and Git's documentation notes that housekeeping
eventually removes them if nothing refers to them.

## Fetching particular branches

Bob pushed a commit to `main`:

```console
$ git fetch origin main
From /home/ada/server/atlas
 * branch            main       -> FETCH_HEAD
   60de880..af5b2d0  main       -> origin/main
$ git fetch origin nosuch
fatal: couldn't find remote ref nosuch
$ git fetch origin deserts:deserts && git branch -v --list deserts
From /home/ada/server/atlas
 * [new branch]      deserts    -> deserts
  deserts 8786d83 List deserts
```

A refspec after the remote fetches only what it names. `main` has no
destination, so it went into `FETCH_HEAD`, and, as the second line shows,
`origin/main` was updated anyway. Git's documentation explains that the remote's
configured fetch refspecs still decide where a named branch is stored, even
though they no longer decide what is fetched.

A branch the server does not have is a fatal error, "couldn't find remote ref",
and nothing is fetched.

`deserts:deserts` has a destination: the local branch `deserts`, which it
created. That is a way to get or update a local branch without switching to it.

### Into a local branch

Bob added a commit to `deserts`:

```console
$ git fetch origin deserts:deserts
From /home/ada/server/atlas
   8786d83..71a4a54  deserts    -> deserts
   8786d83..71a4a54  deserts    -> origin/deserts
$ git fetch origin drafts:deserts
From /home/ada/server/atlas
 ! [rejected] drafts     -> deserts  (non-fast-forward)
$ git fetch origin +drafts:deserts
From /home/ada/server/atlas
 + 71a4a54...1656595 drafts     -> deserts  (forced update)
$ git fetch origin deserts:deserts
From /home/ada/server/atlas
 ! [rejected] deserts    -> deserts  (non-fast-forward)
```

Into a local branch, fetch accepts only a fast-forward, as a push does, because
anything else would throw commits off the branch. `drafts` does not contain
`deserts`'s commit, so it was rejected. A `+` before the refspec, or `--force`,
allows it, and the reverse, going back to the server's `deserts`, is then a
rewrite too and is refused in its turn.

Git's documentation lists the exceptions: into `refs/tags/` a changed tag needs
forcing, as [A tag that moved](#a-tag-that-moved) shows, and outside
`refs/heads/` and `refs/tags/` any update is accepted without `+`.

```console
$ git switch -q deserts && git fetch origin +deserts:deserts
fatal: refusing to fetch into branch 'refs/heads/deserts' checked out at '/home/ada/ada'
$ git fetch -u origin +deserts:deserts && git status --short
From /home/ada/server/atlas
 + 1656595...71a4a54 deserts    -> deserts  (forced update)
D  deserts.txt
A  drafts.txt
D  maps/africa.txt
$ git reset -q --hard && git status --short && git log --oneline -1
71a4a54 Add the Gobi
```

Not even `+` lets fetch move the branch you are on. `-u`, or `--update-head-ok`,
does, and shows why it is refused: the branch moved, the index and the files did
not, so `git status` now describes the old commit's files as staged changes
against the new one, as if you had prepared a commit that undoes Bob's work.
Git's documentation says the option exists for `git pull` to use internally.
`git reset --hard` made the index and files match the branch again (Chapter 30),
which here lost nothing, because nothing uncommitted was there.

### A commit

```console
$ git fetch origin $(git rev-parse --short origin/main~1)
fatal: couldn't find remote ref 60de880
$ git fetch origin 60de88033e517ecf70bb26d7fccf238490167359
From /home/ada/server/atlas
 * branch            60de88033e517ecf70bb26d7fccf238490167359 -> FETCH_HEAD
```

A commit can be fetched by its full hash, which Git's documentation allows in a
refspec's source. An abbreviated hash is read as a ref name, and no ref has that
name. Whether a server hands out a commit by hash depends on the server and its
settings; Git's own did here.

### Choosing where copies go

```console
$ git fetch --refmap= origin drafts
From /home/ada/server/atlas
 * branch            drafts     -> FETCH_HEAD
$ git fetch --refmap='+refs/heads/*:refs/remotes/snapshot/*' origin drafts && git branch -r --list 'snapshot/*'
From /home/ada/server/atlas
 * branch            drafts     -> FETCH_HEAD
 * [new branch]      drafts     -> snapshot/drafts
  snapshot/drafts
$ printf 'main\ndrafts\n' | git fetch --stdin origin
From /home/ada/server/atlas
 * branch            main       -> FETCH_HEAD
 * branch            drafts     -> FETCH_HEAD
```

`--refmap` replaces the configured fetch refspecs in their second job, deciding
where a branch named on the command line is stored. Empty, it stores nothing but
`FETCH_HEAD`; with a rule, it stores under the names the rule gives. `--stdin`
reads refspecs from standard input, one per line, for a script with a long list;
Git's documentation says the `tag <name>` form is not accepted there. The full
syntax of refspecs, including the negative ones that start with `^`, is
Chapter 44.

### Setting the upstream while fetching

```console
$ git switch -q -c solo && git fetch --set-upstream origin deserts && git branch -vv --list solo
From /home/ada/server/atlas
 * branch            deserts    -> FETCH_HEAD
* solo 0fe19df [origin/deserts: behind 3] Add Europe
```

`--set-upstream` makes the fetched branch the current branch's upstream, as
`git branch -u` would (Chapter 23). The release notes that introduced it give
the case: a clone of your own fork, where you add the original project as a
remote and want to follow its branch.

> **Since Git 2.24.** `git fetch --set-upstream`.

## FETCH_HEAD

```console
$ git fetch && cat .git/FETCH_HEAD
af5b2d000fd96a658f7a32ca217a95f21a4faa20		branch 'main' of /home/ada/server/atlas
71a4a54b98c618239b2ea571dee1716683855bd7	not-for-merge	branch 'deserts' of /home/ada/server/atlas
1656595cae95ad32e2457f0cbb5374884d1c90f8	not-for-merge	branch 'drafts' of /home/ada/server/atlas
```

`FETCH_HEAD` is a file, rewritten by every fetch, with a line per ref fetched:
the commit, a marker, and a description. Git's documentation says it exists for
scripts and for `git pull`. The marker is for `git pull`, which merges the lines
without it (Chapter 42): the branch the current branch's upstream names, `main`
here, has none, and every other branch is `not-for-merge`.

As a revision, `FETCH_HEAD` means the commit on its first line, so
`git log FETCH_HEAD` and `git merge FETCH_HEAD` work with it like any ref.

```console
$ git fetch origin deserts && git fetch --append origin drafts && cat .git/FETCH_HEAD
From /home/ada/server/atlas
 * branch            deserts    -> FETCH_HEAD
From /home/ada/server/atlas
 * branch            drafts     -> FETCH_HEAD
71a4a54b98c618239b2ea571dee1716683855bd7		branch 'deserts' of /home/ada/server/atlas
1656595cae95ad32e2457f0cbb5374884d1c90f8		branch 'drafts' of /home/ada/server/atlas
$ git fetch --no-write-fetch-head origin main && cat .git/FETCH_HEAD
71a4a54b98c618239b2ea571dee1716683855bd7		branch 'deserts' of /home/ada/server/atlas
1656595cae95ad32e2457f0cbb5374884d1c90f8		branch 'drafts' of /home/ada/server/atlas
$ git log --oneline -2 FETCH_HEAD
71a4a54 Add the Gobi
8786d83 List deserts
```

Named on the command line, a branch is for merging. `--append` added the second
fetch's line instead of replacing the file, `--no-write-fetch-head` left the
file alone, and the log started from its first line, `deserts`. Git's
documentation adds that `--dry-run` never writes the file.

> **Since Git 2.29.** `--no-write-fetch-head`.

## Tags

Bob added a tag `v1.2` on `main`, and a tag `notes-1` on a commit that is on no
branch at all:

```console
$ git ls-remote --tags origin
41a657425dd01d80fd650a97c977482eb93a8ba7	refs/tags/notes-1
9c338766d934f191fb1707f2e5833b61cee233d6	refs/tags/v1.0
0dbdc880eb0e3ff85d215510620f39a74a8a8ea2	refs/tags/v1.0^{}
0dbdc880eb0e3ff85d215510620f39a74a8a8ea2	refs/tags/v1.1
3379f9cbf5a76dd3a585a497e0ed26c6e92fa336	refs/tags/v1.2
af5b2d000fd96a658f7a32ca217a95f21a4faa20	refs/tags/v1.2^{}
$ git fetch && git tag
From /home/ada/server/atlas
 * [new tag]         v1.2       -> v1.2
v1.0
v1.1
v1.2
$ git fetch --tags && git tag
From /home/ada/server/atlas
 * [new tag]         notes-1    -> notes-1
notes-1
v1.0
v1.1
v1.2
```

By default fetch brings the tags that point into the history it fetched, which
Git's documentation calls following them: `v1.2` points at a commit on `main`,
and came. `notes-1` points at a commit no fetched branch reaches, so it did not,
until `--tags` asked for every tag.

```console
$ git tag -d v1.2 notes-1 && git fetch --no-tags && git tag
Deleted tag 'v1.2' (was 3379f9c)
Deleted tag 'notes-1' (was 41a6574)
v1.0
v1.1
$ git fetch origin tag v1.2 && git tag
From /home/ada/server/atlas
 * [new tag]         v1.2       -> v1.2
 * [new tag]         notes-1    -> notes-1
notes-1
v1.0
v1.1
v1.2
$ git config set remote.origin.tagOpt --no-tags && git tag -d v1.2 && git fetch && git tag
Deleted tag 'v1.2' (was 3379f9c)
notes-1
v1.0
v1.1
$ git fetch --tags
From /home/ada/server/atlas
 * [new tag]         v1.2       -> v1.2
```

`--no-tags`, or `-n`, fetches no tags. `tag v1.2` in place of a refspec fetches
that one tag, and Git's documentation spells it out as
`refs/tags/v1.2:refs/tags/v1.2`.

It brought `notes-1` too, and that is following at work: its commit had been
downloaded by the earlier `--tags`, and deleting a tag does not delete the
commit, so after this fetch `notes-1` pointed at a commit the repository has.

`remote.<name>.tagOpt` makes a choice permanent for one remote: `--no-tags`
stopped the plain fetch bringing `v1.2`, and `--tags` on the command line still
overrides it. `git remote add --tags` and `--no-tags` write this setting
(Chapter 39), and so does `git clone --no-tags` (Chapter 9).

| Command | Tags fetched |
|---|---|
| `git fetch` | those pointing at commits in the repository after the fetch |
| `git fetch --tags` | every tag on the server, as well |
| `git fetch --no-tags` | none |
| `git fetch origin tag <name>` | that tag, plus the followed ones |

### A tag that moved

Bob moved `v1.2` to an older commit, and force-pushed it:

```console
$ git fetch
$ git fetch --tags
From /home/ada/server/atlas
 ! [rejected] v1.2       -> v1.2  (would clobber existing tag)
$ git fetch --tags --force && git log --oneline -1 v1.2
From /home/ada/server/atlas
 t [tag update]      v1.2       -> v1.2
60de880 Add the Americas
```

Following only adds tags you do not have, so a plain fetch said nothing about
the moved one. Asked for explicitly, a changed tag is refused, "would clobber
existing tag", because a tag is meant never to move; Git's documentation says
this has been the rule since Git 2.20, and that before it fetch overwrote tags
silently. `--force`, or a `+` refspec, accepts the change. Chapter 47 discusses
why moving a published tag is best avoided.

## Pruning

Ada had pushed a branch `lakes` and set it as her local `lakes`'s upstream.
Bob deleted it on the server:

```console
$ git branch -vv
  lakes     0fe19df [origin/lakes] Add Europe
* main      0fe19df [origin/main: behind 4] Add Europe
  mountains 1656595 [bob/mountains] Draft a better idea
$ git fetch
$ git fetch --prune
From /home/ada/server/atlas
 - [deleted]         (none)     -> origin/lakes
$ git branch -vv
  lakes     0fe19df [origin/lakes: gone] Add Europe
* main      0fe19df [origin/main: behind 4] Add Europe
  mountains 1656595 [bob/mountains] Draft a better idea
```

Git keeps data until told to throw it away, as the section on pruning in its
documentation puts it, and that includes remote-tracking branches whose branch
was deleted. A plain fetch left `origin/lakes`. `--prune`, or `-p`, deleted it
before fetching.

The local branch `lakes` is Ada's and was not touched. Its upstream is now
`gone`, which Chapter 10 and Chapter 23 show from `git status` and `git branch`.

```console
$ git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$2 == "[gone]" { print $1 }'
lakes
$ git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$2 == "[gone]" { print $1 }' | xargs git branch -d
Deleted branch lakes (was 0fe19df).
```

Such branches are usually left over from work that was merged on the server and
deleted there. `%(upstream:track)` prints `[gone]` for them (Chapter 22), `awk`
keeps their names, and `xargs git branch -d` deletes each. `-d` refuses a branch
whose commits are not merged (Chapter 23), which makes the command safe to run:
only work that is already somewhere else goes.

### Pruning on every fetch

Bob pushed a branch `old-idea`, and after Ada fetched it he deleted it:

```console
$ git fetch
From /home/ada/server/atlas
 * [new branch]      old-idea   -> origin/old-idea
$ git config set fetch.prune true && git fetch
From /home/ada/server/atlas
 - [deleted]         (none)     -> origin/old-idea
```

`fetch.prune=true` makes every fetch prune, which is why Chapter 3 suggests it:
it keeps `git branch -r` a true picture of the server.
`remote.<name>.prune` does the same for one remote and wins over `fetch.prune`;
`git fetch --no-prune` overrides both once.

### Pruning tags

```console
$ git tag mine && git fetch --prune --prune-tags --dry-run
From /home/ada/server/atlas
 - [deleted]         (none)     -> mine
$ git fetch -p -P && git tag
From /home/ada/server/atlas
 - [deleted]         (none)     -> mine
notes-1
v1.0
v1.1
v1.2
```

`--prune-tags`, or `-P`, with `--prune`, also deletes every local tag the
remote does not have, and a tag that exists only on your computer is exactly
such a tag: `mine` was deleted. Git's documentation describes it as the same as
adding the refspec `refs/tags/*:refs/tags/*` while pruning, and warns to use it
with care, since the tags may never have come from that remote.

> **Careful.** `fetch.pruneTags=true` does this on every fetch that prunes.
> Leave it off unless every tag you care about lives on that one server.

## Forced updates

Bob rewrote `drafts` and force-pushed it:

```console
$ git fetch
From /home/ada/server/atlas
 + 1656595...9be0a8f drafts     -> origin/drafts  (forced update)
```

A forced update means the server's branch was rewritten (Chapter 28). The fetch
itself is safe: `origin/drafts` is only a record, and its old position is in its
reflog. The question is whether you had based anything on the old commits; if
so, Chapter 28 shows how to move your work across.

Bob rewrote it once more:

```console
$ git fetch --no-show-forced-updates
warning: fetch normally indicates which branches had a forced update,
but that check has been disabled; to re-enable, use '--show-forced-updates'
flag or run 'git config fetch.showForcedUpdates true'
From /home/ada/server/atlas
   9be0a8f..4cdaeee  drafts     -> origin/drafts
```

Deciding whether an update was forced means walking history, which can take a
while on a large repository, and Git's documentation says the check can be
skipped for speed. Skipped, a forced update looks like a fast-forward: two dots,
no `+`, no note. `fetch.showForcedUpdates=false` skips it every time, with the
same warning; `--show-forced-updates` insists on the check.


## The remote's HEAD

`origin/HEAD` records which branch the server's own `HEAD` names, its default
branch (Chapter 39). The server changed it to `drafts`:

```console
$ git ls-remote --symref origin HEAD && git fetch && git symbolic-ref refs/remotes/origin/HEAD
ref: refs/heads/drafts	HEAD
4cdaeee2c556543c787af9c12ea35451cd8e7b30	HEAD
refs/remotes/origin/main
$ git -c remote.origin.followRemoteHEAD=warn fetch
hint: Run 'git remote set-head origin drafts' to follow the change, or set
hint: 'remote.origin.followRemoteHEAD' configuration option to a different value
hint: if you do not want to see this message. Specifically running
hint: 'git config set remote.origin.followRemoteHEAD warn-if-not-branch-drafts'
hint: will disable the warning until the remote changes HEAD to something else.
hint: Disable this message with "git config set advice.fetchRemoteHEADWarn false"
'HEAD' at 'origin' is 'drafts', but we have 'main' locally.
```

By default fetch creates `origin/HEAD` when it is missing, and leaves an existing
one alone, so Ada's still says `main`. `remote.<name>.followRemoteHEAD` chooses
otherwise:

| Value of `remote.<name>.followRemoteHEAD` | A fetch |
|---|---|
| `create`, the default | creates `<name>/HEAD` if missing; never changes it |
| `warn` | creates it if missing; warns when it differs from the server's |
| `warn-if-not-<branch>` | the same, but silent while the server's is `<branch>` |
| `always` | sets it to the server's every time |
| `never` | never creates or changes it |

```console
$ git -c remote.origin.followRemoteHEAD=warn-if-not-branch-drafts fetch 2>&1 | tail -1
'HEAD' at 'origin' is 'drafts', but we have 'main' locally.
$ git -c remote.origin.followRemoteHEAD=warn-if-not-drafts fetch
$ git -c remote.origin.followRemoteHEAD=always fetch && git symbolic-ref refs/remotes/origin/HEAD
refs/remotes/origin/drafts
```

The hint suggests `warn-if-not-branch-drafts`, and in Git 2.55 that value does
not silence the warning, as the first command shows; `tail` only keeps the
warning. Git's source reads everything after `warn-if-not-` as the branch name,
so it waits for a branch called `branch-drafts`. The documentation's form,
`warn-if-not-drafts`, works. `always` followed the server.

The server's default went back to `main`:

```console
$ git remote set-head origin -d && git -c remote.origin.followRemoteHEAD=never fetch && git branch -r --list 'origin/HEAD'
$ git fetch && git symbolic-ref refs/remotes/origin/HEAD
refs/remotes/origin/main
$ git -c remote.origin.followRemoteHEAD=sometimes fetch
warning: unrecognized followRemoteHEAD value 'sometimes' ignored
```

With `never`, a deleted `origin/HEAD` stayed deleted; the default recreated it.
An unknown value is ignored with a warning, and the default applies.

> **Since Git 2.48.** Fetch creating `<name>/HEAD`, and
> `remote.<name>.followRemoteHEAD`.

## Quiet, verbose and progress

Bob pushed a commit, and then another:

```console
$ git fetch -q && git log --oneline -1 origin/main
9e528f8 Add Antarctica
$ git fetch --progress 2>&1 | tr '\r' '\n' | grep -E 'done|->|From'
remote: Enumerating objects: 6, done.        
remote: Counting objects: 100% (6/6), done.        
remote: Compressing objects: 100% (3/3), done.        
From /home/ada/server/atlas
   9e528f8..5e919fd  main       -> origin/main
```

`-q` prints nothing unless something goes wrong; the fetch still happened.

On a terminal, fetch shows progress while it works: `remote:` lines from the
server as it prepares the objects, then lines about receiving them. Git's
documentation says progress is shown only when standard error is a terminal,
so it disappears as soon as the output goes into a file or a pipe, and
`--progress` brings it back. Each progress line is redrawn in place with
carriage returns; `tr` turns them into new lines and `grep` keeps the final
state of each, as in Chapter 9. The "Receiving objects" line that Chapter 9's
clone printed did not appear for this fetch.

## Output for scripts

Bob pushed a commit to `main` and rewrote `drafts`:

```console
$ git fetch --porcelain
  5e919fd1e81d28ec1b620d9c2abec7fe10b96240 53bd61905531a827eecee995229beeefb03930a8 refs/remotes/origin/main
+ 4cdaeee2c556543c787af9c12ea35451cd8e7b30 136c34e7899e430baa3d52441e1dacffc300b9e1 refs/remotes/origin/drafts
$ git fetch --porcelain -v
= 53bd61905531a827eecee995229beeefb03930a8 53bd61905531a827eecee995229beeefb03930a8 refs/remotes/origin/main
= 71a4a54b98c618239b2ea571dee1716683855bd7 71a4a54b98c618239b2ea571dee1716683855bd7 refs/remotes/origin/deserts
= 136c34e7899e430baa3d52441e1dacffc300b9e1 136c34e7899e430baa3d52441e1dacffc300b9e1 refs/remotes/origin/drafts
```

`--porcelain` prints one line per ref on standard output, not standard error:
the flag, the old hash, the new hash, and the full name of the local ref. A
created ref has an old hash of zeros. Git's documentation describes it as the
format intended for machines to read, so a script should use it rather than the
aligned columns.

```console
$ git -c fetch.output=compact fetch -v
From /home/ada/server/atlas
 = [up to date]      main       -> origin/*
 = [up to date]      deserts    -> origin/*
 = [up to date]      drafts     -> origin/*
```

`fetch.output=compact` shortens the human format: where one side's name appears
in the other, Git's documentation says, it is replaced by `*`, so
`main -> origin/main` reads `main -> origin/*`.

> **Since Git 2.41.** `--porcelain`.

## All or nothing

Ada has a local branch `mydrafts` that `drafts` cannot fast-forward, and Bob
pushed a commit to `main`:

```console
$ git fetch origin main:refs/remotes/origin/main drafts:mydrafts; echo "exit $?"; git log --oneline -1 origin/main
From /home/ada/server/atlas
   53bd619..0ebe4c0 main       -> origin/main
 ! [rejected] drafts     -> mydrafts  (non-fast-forward)
exit 1
0ebe4c0 Map the deserts
```

One of two updates was rejected, and the command failed, but the other was made:
`origin/main` moved. That is fetch's normal behaviour, ref by ref.

Bob pushed another commit to `main`:

```console
$ git fetch --atomic origin main:refs/remotes/origin/main drafts:mydrafts; echo "exit $?"; git log --oneline -1 origin/main
From /home/ada/server/atlas
   0ebe4c0..fabed61 main       -> origin/main
 ! [rejected] drafts     -> mydrafts  (non-fast-forward)
exit 1
0ebe4c0 Map the deserts
$ git fetch && git log --oneline -1 origin/main
From /home/ada/server/atlas
   0ebe4c0..fabed61  main       -> origin/main
fabed61 Map the rivers
```

With `--atomic`, Git's documentation says, either every ref is updated or none
is. The same rejection now kept `origin/main` where it was, although the output
still lists the update it would have made; the exit status and the ref itself
are the evidence, not the list. The plain fetch after it made the update.

> **Since Git 2.31.** `git fetch --atomic`.

## The conversation

Chapter 40 traced `git ls-remote`. A fetch continues from there: after listing
the server's refs, it asks for objects. Bob pushed a commit:

```console
$ GIT_TRACE_PACKET=1 git fetch origin 2>&1 >/dev/null | grep -o 'fetch[<>].*' | sed -n '/command=fetch/,$p'
fetch> command=fetch
fetch> agent=git/2.55.0.windows.5-Windows
fetch> object-format=sha1
fetch> 0001
fetch> thin-pack
fetch> no-progress
fetch> include-tag
fetch> ofs-delta
fetch> want 4e5117539926400993f768c023274a46f2bbae61
fetch> have fabed61f1ab8ed92c10b02f4321205c6a944298b
fetch> have 0ebe4c0c26825f9f41bb62e4ff197f632337f63f
fetch> have 136c34e7899e430baa3d52441e1dacffc300b9e1
fetch> have 53bd61905531a827eecee995229beeefb03930a8
fetch> have 5e919fd1e81d28ec1b620d9c2abec7fe10b96240
fetch> have 9e528f8528426aef8d3939e7306f0433c115c1a7
fetch> have 41a657425dd01d80fd650a97c977482eb93a8ba7
fetch> have 71a4a54b98c618239b2ea571dee1716683855bd7
fetch> have af5b2d000fd96a658f7a32ca217a95f21a4faa20
fetch> have 60de88033e517ecf70bb26d7fccf238490167359
fetch> have 1656595cae95ad32e2457f0cbb5374884d1c90f8
fetch> have 0dbdc880eb0e3ff85d215510620f39a74a8a8ea2
fetch> 0000
fetch< acknowledgments
fetch< ACK fabed61f1ab8ed92c10b02f4321205c6a944298b
fetch< ACK 136c34e7899e430baa3d52441e1dacffc300b9e1
fetch< ACK 41a657425dd01d80fd650a97c977482eb93a8ba7
fetch< ACK 71a4a54b98c618239b2ea571dee1716683855bd7
fetch< ACK 1656595cae95ad32e2457f0cbb5374884d1c90f8
fetch< ACK 0dbdc880eb0e3ff85d215510620f39a74a8a8ea2
fetch< ready
fetch< 0001
fetch< packfile
```

The command is Chapter 40's trace, with `sed` starting the print at the request
for objects. `>` is what Ada's Git sent, `<` what it received:

| Lines | Mean |
|---|---|
| `command=fetch` and the lines up to `0001` | a request for objects, in protocol version 2 |
| `thin-pack`, `no-progress`, `include-tag`, `ofs-delta` | requests about the pack: smaller deltas, no progress messages, annotated tags for the objects sent, and a delta format Ada's side can read |
| `want 4e51175...` | the commit Ada does not have: the new tip of `main` |
| `have ...` | commits Ada already has, starting from the most recent |
| `ACK ...` | the server has those too; they are common ground |
| `ready` | the server knows enough to decide what to send |
| `packfile` | the objects follow, as one pack, which the trace does not print |

This is why a fetch after a small change is fast however big the repository:
the server sends only what is reachable from the `want` lines and not from any
commit both sides have. The same exchange is why two repositories can
synchronise over an untrusted network by hashes alone, as Chapter 6 put it: a
hash the server acknowledges stands for the whole history behind it.

### What the client says it has

Ada has two commits of her own, on a branch `notes` that the server has never
seen. Bob pushed a commit before each fetch below:

```console
$ git log --oneline -2 notes
28f57bf Write another note
523d5fb Write a note
$ GIT_TRACE_PACKET=1 git fetch origin 2>&1 >/dev/null | grep -o 'fetch> have.*' | head -4
fetch> have 28f57bf505d6c4c89414de815a93ba169c8d0c35
fetch> have 523d5fb5481cb4efc4864963c56596d7ab1c01ad
fetch> have 4e5117539926400993f768c023274a46f2bbae61
fetch> have fabed61f1ab8ed92c10b02f4321205c6a944298b
$ GIT_TRACE_PACKET=1 git fetch --negotiation-restrict=refs/remotes/origin/main origin 2>&1 >/dev/null | grep -o 'fetch> have.*' | head -4
fetch> have 57b3a21a5423c08740e2f56689d82e7792774ba9
fetch> have 4e5117539926400993f768c023274a46f2bbae61
fetch> have fabed61f1ab8ed92c10b02f4321205c6a944298b
fetch> have 0ebe4c0c26825f9f41bb62e4ff197f632337f63f
$ GIT_TRACE_PACKET=1 git fetch --negotiation-restrict=refs/remotes/origin/main --negotiation-include=refs/heads/notes origin 2>&1 >/dev/null | grep -o 'fetch> have.*' | head -4
fetch> have 28f57bf505d6c4c89414de815a93ba169c8d0c35
fetch> have ce5e2a0928b3f931faa5825002a6ba3f3c30ab4b
fetch> have 57b3a21a5423c08740e2f56689d82e7792774ba9
fetch> have 4e5117539926400993f768c023274a46f2bbae61
```

By default fetch offers commits from every local ref, which is why Ada's two
private commits came first, and they are useless to the server: it cannot have
them. In a repository with thousands of branches that list gets long.

`--negotiation-restrict` offers only commits reachable from the refs it names,
here `origin/main`, and the private ones disappeared. `--negotiation-include`
adds the tips it names back, whatever the restriction, and `28f57bf` returned,
without the commit before it. Both take a ref, a glob of refs or a full hash,
and `remote.<name>.negotiationRestrict` and `negotiationInclude` make them
permanent. The `head -4` only shortens the lists.

Git's source adds one detail: commits the server listed among its refs and that
you already have are offered whatever the restriction, since they are certainly
common. That is why a restriction changes nothing visible until you have commits
the server has never seen.

```console
$ git fetch --negotiate-only --negotiation-restrict=refs/heads/notes origin
0fe19df3c0584186fbd106d526ed04be3c0a1664
$ git fetch --negotiate-only origin
fatal: --negotiate-only needs one or more --negotiation-restrict=*
$ GIT_TRACE_PACKET=1 git -c fetch.negotiationAlgorithm=noop fetch origin 2>&1 >/dev/null | grep -o 'fetch> want.*\|fetch> have.*\|fetch> done'
fetch> want a765050b6f5be07be4a88d8e3fbcefc1b2e09aee
fetch> done
```

`--negotiate-only` fetches nothing and prints the commits the server
acknowledged as common with the refs named: `notes` branched from `0fe19df`,
which is the newest of its commits the server has. Git's documentation says it
exists so that `git push` can use it when `push.negotiate` is set (Chapter 43),
and it requires a restriction.

`fetch.negotiationAlgorithm` chooses how the list is built: `consecutive`, the
default, walks back one commit at a time; `skipping` skips ahead to finish in
fewer rounds, at the cost of a possibly larger download; and `noop`, above,
offers nothing at all, so the server sends everything `main` needs, as if
cloning.

### Keeping the pack

Bob pushed a commit before each fetch:

```console
$ git count-objects -v | grep -E '^(count|in-pack|packs):' && git fetch -q && git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 92
in-pack: 0
packs: 0
count: 96
in-pack: 0
packs: 0
$ git fetch -q -k && git count-objects -v | grep -E '^(count|in-pack|packs):'
count: 96
in-pack: 5
packs: 1
```

The objects arrive as a pack, and what happens next depends on how many there
are. Git's documentation for `fetch.unpackLimit` says that below the limit the
received objects are stored as loose objects, one file each, and the pack is
discarded; `count`, the loose objects, grew by four. `-k`, or `--keep`, keeps
the pack as it arrived: `packs` went from none to one, holding five
objects, and no loose ones were added. Chapter 71 and Chapter 72 explain loose
objects and packs, and `git gc` packs loose objects later in any case
(Chapter 77).

## fetch and its neighbours

```console
$ git fetch && git merge -q --ff-only FETCH_HEAD && git log --oneline -1
3815405 Map the volcanoes
```

That is `git pull` taken apart. A pull runs a fetch, and then merges or rebases
the current branch onto what was fetched; Chapter 42 covers the second half and
the settings that choose it.

| To | Use | Difference |
|---|---|---|
| download and look first | `git fetch` | changes no branch of yours |
| download and update the current branch | `git pull` (Chapter 42) | also merges or rebases |
| see what the server has, downloading nothing | `git ls-remote` (Chapter 39) | only refs and hashes |
| describe a remote and compare | `git remote show` (Chapter 39) | contacts the server, fetches nothing |
| fetch every remote | `git fetch --all` or `git remote update` (Chapter 39) | both skip remotes with `skipFetchAll`; `update` also has `remotes.default` |
| delete stale copies without fetching | `git remote prune` (Chapter 39) | Git's documentation calls it `git fetch --prune` without the fetch |
| make a repository from a remote | `git clone` (Chapter 9) | `init`, `remote add`, `fetch` and `checkout` in one |

## The settings

| Setting | Does |
|---|---|
| `remote.<name>.fetch` | The fetch refspecs: what a plain fetch copies, and where named branches are stored (Chapter 44) |
| `remote.<name>.tagOpt` | `--tags` or `--no-tags` for this remote |
| `fetch.prune`, `remote.<name>.prune` | Prune on every fetch; the remote's setting wins |
| `fetch.pruneTags`, `remote.<name>.pruneTags` | Also prune tags when pruning |
| `fetch.all` | Make a plain `git fetch` fetch every remote |
| `remote.<name>.skipFetchAll` | Leave this remote out of `--all` |
| `remotes.<group>` | A named group of remotes |
| `fetch.parallel` | How many remotes `--multiple` fetches at once; 1 by default (Chapter 69) |
| `fetch.output` | `full` or `compact` |
| `fetch.showForcedUpdates` | `false` skips the forced-update check |
| `remote.<name>.followRemoteHEAD` | Whether fetch creates or updates `<name>/HEAD` |
| `fetch.negotiationAlgorithm` | `consecutive`, `skipping`, `noop` or `default` |
| `remote.<name>.negotiationRestrict`, `remote.<name>.negotiationInclude` | Defaults for the negotiation options |
| `fetch.fsckObjects`, `transfer.fsckObjects` | Check every fetched object for corruption (Chapter 81) |
| `fetch.writeCommitGraph` | Update the commit-graph file after each fetch (Chapter 69) |
| `fetch.recurseSubmodules` | Whether fetch also fetches submodules (Chapter 57) |
| `fetch.unpackLimit`, `transfer.unpackLimit` | Below this many objects, store them as loose files instead of a pack (Chapter 72) |
| `fetch.hideRefs` | Refs to leave out of the connectivity check after fetching; for repositories with very many refs |
| `fetch.bundleURI`, `fetch.bundleCreationToken` | Download from a bundle before fetching (Chapter 61) |
| `branch.<name>.remote`, `branch.<name>.merge` | The remote a plain fetch uses on this branch, and what `FETCH_HEAD` marks for merging (Chapter 23) |
| `checkout.defaultRemote` | Which remote's branch `git switch <name>` uses when several have it (Chapter 24) |
| `advice.fetchRemoteHEADWarn` | `false` removes the hint from the `followRemoteHEAD` warning |
