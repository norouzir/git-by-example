# Chapter 44. Refspecs

## What it is

A *refspec* is the rule `git fetch`, `git pull` and `git push` follow to decide
which refs to transfer and which refs to create or update with them. Its
general form is `[+]<source>:<destination>`: take the ref named on the left,
and store it under the name on the right, with the `+` allowing an update that
is not a fast-forward. On its own a refspec answers one question: *what goes
where?*

Every fetch and every push uses one, even when you type none. A plain
`git fetch` follows `+refs/heads/*:refs/remotes/origin/*`, which `git clone`
wrote into the configuration (Chapter 39), and `git push origin main` expands
`main` into `refs/heads/main:refs/heads/main`. Chapters 41 to 43 used refspecs
as they came. This chapter is their grammar: every form, how short names are
expanded on each side, what `*` can match, what `+` and `^` do, and the errors
for each.

The direction matters, because the two sides swap. When fetching, the source
is on the server and the destination in your repository; when pushing, it is
the other way round.

| Term | Means |
|---|---|
| *source* | the left side: the ref the commits come from; on the server when fetching, in your repository when pushing |
| *destination* | the right side: the ref created or updated; in your repository when fetching, on the server when pushing |
| *full ref name* | a name starting with `refs/`, such as `refs/heads/main` for a branch or `refs/tags/v1.0` for a tag (Chapter 7) |
| *short name* | a name without `refs/`, such as `main`, which Git expands by rules that differ for each side |
| *pattern* | a refspec with one `*` on each side, the `*` standing for any part of a name |
| *negative refspec* | a refspec starting with `^`, which leaves out the refs it matches |
| *fetch refspec*, *push refspec* | the refspecs in `remote.<name>.fetch` and `remote.<name>.push`, used when the command line names none |
| *fast-forward* | an update where the new commit contains the old one (Chapter 41) |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a refspec, and where have I been using one without knowing?](#what-it-is)
- [Which side of a refspec is on the server?](#what-it-is)

**[The forms at a glance](#the-forms-at-a-glance)**

- [What forms can a refspec take, and what does each do in a fetch and in a push?](#the-forms-at-a-glance)

**[Where refspecs come from](#where-refspecs-come-from)**

- [Where does Git get a refspec when I don't type one?](#where-refspecs-come-from)

**[The example repositories](#the-example-repositories)**

- [What repositories do the examples use?](#the-example-repositories)

**[Fetch refspecs](#fetch-refspecs)**

- [What does the default fetch refspec mean, part by part?](#fetch-refspecs)
- [The server has a branch and a tag with the same name. Which one does `git fetch origin <name>` take?](#source-names)
- [How do I fetch a GitHub pull request by its number?](#source-names)
- [What does a refspec with nothing before the colon fetch?](#source-names)
- [Where does `git fetch origin a:b` put `b` if I don't write `refs/`?](#destination-names)
- [Why does fetching a tag into a short name fail with "trying to write non-commit object"?](#destination-names)
- [Can `*` match a name with slashes in it, or only part of a name?](#patterns)
- [Why is my refspec "invalid"?](#patterns)
- [My pattern matched nothing and gave no error. Why?](#patterns)
- [What happens if I leave out the `+`?](#forcing-with)
- [Is the `+` needed for refs outside `refs/heads/` and `refs/tags/`?](#forcing-with)
- [How do I fetch every branch except some?](#negative-refspecs)
- [Why didn't `^wip-1` leave out `wip-1`?](#negative-refspecs)
- [Does pruning delete a remote-tracking branch that a negative refspec leaves out?](#negative-refspecs)
- [Why did `--prune` delete a ref I had fetched by hand?](#negative-refspecs)
- [How do I make a remote fetch pull requests or merge requests as well as branches?](#several-refspecs-for-one-remote)
- [What refspecs do `--single-branch`, `--mirror` and `--bare` clones get?](#refspecs-that-clone-writes)

**[Push refspecs](#push-refspecs)**

- [Git says "src refspec topic matches more than one". What do I type instead?](#push-source-names)
- [Can I push a commit that is not a branch, such as `main~1` or a hash?](#push-source-names)
- [How does push decide whether a short destination is a branch or a tag?](#push-destination-names)
- [How do I push for review to `refs/for/main`?](#push-destination-names)
- [Can I force a tag into a branch?](#push-destination-names)
- [What do `:branch` and a bare `:` push?](#push-empty-sources-and-matching)
- [How do I push all my branches under a prefix, as a backup?](#push-patterns)
- [My negative refspec did not exclude anything in a push. Why?](#push-negative-refspecs)
- [How do I make a plain `git push` send a branch somewhere else by default?](#push-refspecs-in-the-configuration)

**[Names Git refuses](#names-git-refuses)**

- [Which names are not valid in a refspec, and how do I check one?](#names-git-refuses)
- [Why does `'tag v1.1'` in quotes fail when `tag v1.1` works?](#names-git-refuses)

**[Common refspecs](#common-refspecs)**

- [Is there a list of refspecs for the usual jobs?](#common-refspecs)

**[Refspecs and their neighbours](#refspecs-and-their-neighbours)**

- [How is a refspec different from a revision, or a pattern given to `git ls-remote` or `git branch --list`?](#refspecs-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings hold refspecs or change how they are applied?](#the-settings)

</details>

## The forms at a glance

```
[+]<source>:<destination>
[+]<source>
:<destination>
:
^<source>
tag <name>
```

| Part | Means |
|---|---|
| `+` | Allow the update even if it is not a fast-forward |
| `<source>` | A ref name, full or short, a pattern with one `*`, or when pushing any commit; when fetching, a full commit hash is also accepted |
| `:` | Separates the two sides |
| `<destination>` | A ref name, full or short, or a pattern with one `*` if the source has one |
| `^` | Makes the refspec negative: a source only, never a hash |

| Refspec | In a fetch | In a push |
|---|---|---|
| `main:topic` | fetch the server's `main` into your `topic` | update the server's `topic` with your `main` |
| `main` | fetch `main` into `FETCH_HEAD`, and the remote-tracking branch the fetch refspecs name (Chapter 41) | update the server's `main` with yours |
| `+main:topic` | the same, allowing a non-fast-forward | the same, allowing a non-fast-forward |
| `:topic` | fetch the server's `HEAD` into `topic` | delete the server's `topic` |
| `:` | fetch the server's `HEAD` into `FETCH_HEAD` | push every branch whose name exists on both sides |
| `refs/heads/*:refs/remotes/origin/*` | fetch every branch, each into its own name | push to the server's `refs/remotes/origin/`, which is rarely wanted |
| `^refs/heads/wip-*` | leave out the server's branches starting `wip-` | leave out the server's branches starting `wip-` |
| `tag v1.0` | `refs/tags/v1.0:refs/tags/v1.0` | `refs/tags/v1.0:refs/tags/v1.0` |

Git's documentation describes each of these. The sections below show each in
use, and every row was tried for this chapter; the `:` of a fetch, which is
rarely typed, fetched the server's `HEAD` into `FETCH_HEAD` and nothing else.

## Where refspecs come from

| Where | Used by | Covered in |
|---|---|---|
| the command line of `git fetch` and `git pull` | that command, instead of the fetch refspecs | Chapter 41, Chapter 42 |
| the command line of `git push` | that command, instead of the push refspecs and `push.default` | Chapter 43 |
| `remote.<name>.fetch` | a fetch that names no refspec; and, as a map, where a named branch's copy goes | [Fetch refspecs](#fetch-refspecs) |
| `remote.<name>.push` | a push that names no refspec | [Push refspecs in the configuration](#push-refspecs-in-the-configuration) |
| `git fetch --refmap=<refspec>` | the map, instead of `remote.<name>.fetch` | Chapter 41 |
| `git clone`, `git remote add`, `git remote set-branches` | write `remote.<name>.fetch` | [Refspecs that clone writes](#refspecs-that-clone-writes), Chapter 39 |

## The example repositories

The team's server holds a branch and a tag both called `topic`, branches with
slashes in their names, a lightweight tag `v1.0` and an annotated tag `v1.1`,
notes, and two refs of the kind a hosting service creates: `refs/pull/7/head`,
as GitHub publishes each pull request, and `refs/merge-requests/3/head`, as
GitLab does. Here they were pushed there by hand. Ada has just cloned it:

```console
$ git ls-remote origin
0fe19df3c0584186fbd106d526ed04be3c0a1664	HEAD
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/deserts
24207d64b28eb653e6540e5dda26724ec5fe60f1	refs/heads/drafts
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/feature/borders
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/feature/rivers/nile
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/main
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/release-1.0
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/topic
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/wip-1
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/merge-requests/3/head
1afcada05c72e80ed7a9a1217d7d9cd84bd8b6ef	refs/notes/commits
24207d64b28eb653e6540e5dda26724ec5fe60f1	refs/pull/7/head
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/tags/topic
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/tags/v1.0
abffb58d0e339c924842fc460ea574966571c411	refs/tags/v1.1
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/tags/v1.1^{}
```

`git ls-remote` lists every ref on the server with its full name (Chapter 39).
Every command runs in Ada's clone unless the section says otherwise.

## Fetch refspecs

```console
$ git config get --all remote.origin.fetch && git branch -r
+refs/heads/*:refs/remotes/origin/*
  origin/HEAD -> origin/main
  origin/deserts
  origin/drafts
  origin/feature/borders
  origin/feature/rivers/nile
  origin/main
  origin/release-1.0
  origin/topic
  origin/wip-1
```

The fetch refspec `git clone` wrote reads, part by part: `+`, accept rewritten
branches; `refs/heads/*`, every branch on the server; `:`; and
`refs/remotes/origin/*`, stored under `refs/remotes/origin/` with the same name.
That is where every remote-tracking branch came from, `feature/rivers/nile`
included. Nothing outside `refs/heads/` matched, so the pull request, the merge
request and the notes were not fetched; the tags came by tag following
(Chapter 41).

### Source names

```console
$ git fetch origin topic && cat .git/FETCH_HEAD
From /home/ada/server/atlas
 * tag               topic      -> FETCH_HEAD
0dd6887bf37be4e247a51bed27fdebf9169f246b		tag 'topic' of /home/ada/server/atlas
$ git fetch origin heads/topic && cat .git/FETCH_HEAD
From /home/ada/server/atlas
 * branch            topic      -> FETCH_HEAD
0fe19df3c0584186fbd106d526ed04be3c0a1664		branch 'topic' of /home/ada/server/atlas
```

A short source is looked up among the server's refs by the rules Git uses for
revisions (Chapter 18), in this order, and the first that exists wins:

| A short source `<name>` means | If it exists |
|---|---|
| `refs/<name>` | first |
| `refs/tags/<name>` | second |
| `refs/heads/<name>` | third |
| `refs/remotes/<name>` | fourth |
| `refs/remotes/<name>/HEAD` | fifth |

So `topic` found the tag before the branch, as `FETCH_HEAD` shows. `heads/topic`
matched `refs/heads/topic` under the first rule, and the full name
`refs/heads/topic` is always unambiguous.

```console
$ git fetch origin pull/7/head:pr-7 && git log --oneline -1 pr-7
From /home/ada/server/atlas
 * [new ref]         refs/pull/7/head -> pr-7
24207d6 Draft an idea
```

The first rule is what makes GitHub's documented command for looking at a pull
request work: `git fetch origin pull/ID/head:BRANCH_NAME`. `pull/7/head` is
`refs/pull/7/head`, and it went into a new local branch `pr-7`. `[new ref]` is
fetch's word for a ref that is neither a branch nor a tag.

```console
$ git fetch origin HEAD && cat .git/FETCH_HEAD
From /home/ada/server/atlas
 * branch            HEAD       -> FETCH_HEAD
0fe19df3c0584186fbd106d526ed04be3c0a1664		/home/ada/server/atlas
$ git fetch origin :refs/heads/from-head && git log --oneline -1 from-head
From /home/ada/server/atlas
 * [new ref]         HEAD       -> from-head
0fe19df Add Europe
```

`HEAD` fetches whatever the server's `HEAD` points at, its default branch
(Chapter 39), and `FETCH_HEAD` then names no branch. An empty source means the
same `HEAD`, so `:refs/heads/from-head` stored it in a new branch. A full commit
hash is also a valid source, as Chapter 41 shows.

### Destination names

```console
$ git fetch origin feature/borders:borders && git for-each-ref --format='%(refname)' 'refs/*/borders'
From /home/ada/server/atlas
 * [new branch]      feature/borders -> borders
refs/heads/borders
$ git fetch origin v1.0:first && git for-each-ref --format='%(refname) %(objecttype)' 'refs/*/first'
From /home/ada/server/atlas
 * [new tag]         v1.0       -> first
refs/heads/first commit
$ git fetch origin v1.1:second; echo "exit $?"
error: trying to write non-commit object abffb58d0e339c924842fc460ea574966571c411 to branch 'refs/heads/second'
From /home/ada/server/atlas
 ! [new tag] v1.1       -> second  (unable to update local ref)
exit 1
$ git fetch origin v1.1:refs/tags/second && git for-each-ref --format='%(refname) %(objecttype)' 'refs/*/second'
From /home/ada/server/atlas
 * [new tag]         v1.1       -> second
refs/tags/second tag
```

A short destination in a fetch became a branch, whatever the source was. The
branch `feature/borders` went to `refs/heads/borders`, which is what you would
expect; the tag `v1.0` went to `refs/heads/first`, a branch, which you might
not. That worked because `v1.0` is a lightweight tag, pointing straight at a
commit. `v1.1` is an annotated tag, a tag object (Chapter 6), and a branch can
only point at a commit, so the update failed. With the full name
`refs/tags/second` the tag object was stored as a tag.

The rule in practice: when fetching anything but a branch into your repository,
write the destination in full.

```console
$ git fetch origin main:refs/remotes/snapshot/x deserts:refs/remotes/snapshot/x; echo "exit $?"
fatal: Cannot fetch both refs/heads/main and refs/heads/deserts to refs/remotes/snapshot/x
exit 128
```

Two sources cannot share a destination, whether they come from the command line
or from several fetch refspecs, and the whole fetch stops.

### Patterns

```console
$ git fetch origin 'refs/heads/feature/*:refs/remotes/features/*' && git branch -r --list 'features/*'
From /home/ada/server/atlas
 * [new branch]      feature/borders     -> features/borders
 * [new branch]      feature/rivers/nile -> features/rivers/nile
  features/borders
  features/rivers/nile
$ git fetch origin 'refs/heads/release-*:refs/remotes/releases/v*' && git branch -r --list 'releases/*'
From /home/ada/server/atlas
 * [new branch]      release-1.0 -> releases/v1.0
  releases/v1.0
$ git fetch origin 'refs/pull/*/head:refs/remotes/origin/pr/*' && git branch -r --list 'origin/pr/*'
From /home/ada/server/atlas
 * [new ref]         refs/pull/7/head -> origin/pr/7
  origin/pr/7
```

The `*` matches any part of a name, slashes included: `rivers/nile` is one match.
It can stand beside other text, as in `release-*`, and what it matched is put
where the destination's `*` is, so `release-1.0` became `v1.0`. It can sit in
the middle of a name, as in `refs/pull/*/head`, which is how a pattern picks the
number out of every pull request's ref. The quotes keep the shell from
expanding `*` itself.

```console
$ git fetch origin 'refs/heads/*/*:refs/remotes/two/*/*'; echo "exit $?"
fatal: invalid refspec 'refs/heads/*/*:refs/remotes/two/*/*'
exit 128
$ git fetch origin 'refs/heads/*:refs/remotes/one'; echo "exit $?"
fatal: invalid refspec 'refs/heads/*:refs/remotes/one'
exit 128
$ git fetch origin 'refs/heads/*'; echo "exit $?"
fatal: invalid refspec 'refs/heads/*'
exit 128
$ git fetch origin 'feature/*:refs/remotes/short/*'; echo "exit $?"; git branch -r --list 'short/*'
exit 0
```

Git's documentation requires exactly one `*` on each side, and each refusal
above breaks that: two stars, a star on one side only, and a pattern with no
destination, which on a fetch command line has nowhere to put what it matches.

The last one is the quiet trap. Short names are expanded only when there is no
`*`; a pattern is compared with the server's full names as it is, so `feature/*`
matched no `refs/heads/feature/...`, and the fetch did nothing and reported
success. Write patterns in full.

### Forcing with +

The server's `drafts` was fetched into `refs/remotes/snapshot/drafts`, and then
rewritten and force-pushed:

```console
$ git fetch origin drafts:refs/remotes/snapshot/drafts
From /home/ada/server/atlas
 * [new branch]      drafts     -> snapshot/drafts
$ git fetch origin drafts:refs/remotes/snapshot/drafts; echo "exit $?"
From /home/ada/server/atlas
 ! [rejected] drafts     -> snapshot/drafts  (non-fast-forward)
 + 24207d6...17cc1fa drafts     -> origin/drafts  (forced update)
exit 1
$ git fetch origin +drafts:refs/remotes/snapshot/drafts
From /home/ada/server/atlas
 + 24207d6...17cc1fa drafts     -> snapshot/drafts  (forced update)
```

Without `+`, a destination that already exists is updated only by a
fast-forward. The same fetch updated `origin/drafts` because the configured
refspec, which also applied, has its `+`. With `+`, or `--force` for every
refspec, the rewritten branch was accepted.

That the rule held under `refs/remotes/` contradicts Git's documentation for
Git 2.55, which says that outside `refs/heads/` and `refs/tags/` any update is
accepted without `+`, "a commit for another commit that doesn't have the
previous commit as an ancestor" included. Git's source (`update_local_ref` in
`builtin/fetch.c`) accepts without `+` only an update involving an object that
is not a commit; for commits it rejects every non-fast-forward, wherever it
goes. So the `+` at the start of the default refspec is doing real work.

The server's `drafts` was rewritten once more:

```console
$ git fetch --no-show-forced-updates origin drafts:refs/remotes/snapshot/drafts; echo "exit $?"
warning: fetch normally indicates which branches had a forced update,
but that check has been disabled; to re-enable, use '--show-forced-updates'
flag or run 'git config fetch.showForcedUpdates true'
From /home/ada/server/atlas
   17cc1fa..f5cb459  drafts     -> snapshot/drafts
   17cc1fa..f5cb459  drafts     -> origin/drafts
exit 0
$ git fetch origin +v1.1:refs/heads/second; echo "exit $?"
error: trying to write non-commit object abffb58d0e339c924842fc460ea574966571c411 to branch 'refs/heads/second'
From /home/ada/server/atlas
 ! [new tag] v1.1       -> second  (unable to update local ref)
exit 1
```

The forced-update check Chapter 41 describes is also the check the missing `+`
relies on: in the same source, skipping it treats every update as a
fast-forward. So with `--no-show-forced-updates`, or
`fetch.showForcedUpdates=false`, the rewritten branch went into a refspec
without `+`, printed with two dots as if nothing had been rewritten.

No `+` puts a tag object into a branch; Git's documentation says so, and the
second command shows it.

### Negative refspecs

```console
$ git fetch origin 'refs/heads/*:refs/remotes/without/*' '^wip-1' && git branch -r --list 'without/wip-*'
From /home/ada/server/atlas
 * [new branch]      deserts             -> without/deserts
 * [new branch]      drafts              -> without/drafts
 * [new branch]      feature/borders     -> without/feature/borders
 * [new branch]      feature/rivers/nile -> without/feature/rivers/nile
 * [new branch]      main                -> without/main
 * [new branch]      release-1.0         -> without/release-1.0
 * [new branch]      topic               -> without/topic
 * [new branch]      wip-1               -> without/wip-1
  without/wip-1
$ git fetch origin 'refs/heads/*:refs/remotes/without-wip/*' '^refs/heads/wip-*' && git branch -r --list 'without-wip/*'
From /home/ada/server/atlas
 * [new branch]      deserts             -> without-wip/deserts
 * [new branch]      drafts              -> without-wip/drafts
 * [new branch]      feature/borders     -> without-wip/feature/borders
 * [new branch]      feature/rivers/nile -> without-wip/feature/rivers/nile
 * [new branch]      main                -> without-wip/main
 * [new branch]      release-1.0         -> without-wip/release-1.0
 * [new branch]      topic               -> without-wip/topic
  without-wip/deserts
  without-wip/drafts
  without-wip/feature/borders
  without-wip/feature/rivers/nile
  without-wip/main
  without-wip/release-1.0
  without-wip/topic
$ git fetch origin '^refs/heads/wip-*:refs/remotes/wip'; echo "exit $?"
fatal: invalid refspec '^refs/heads/wip-*:refs/remotes/wip'
exit 128
$ git fetch origin "^$(git rev-parse origin/wip-1)"; echo "exit $?"
fatal: invalid refspec '^0fe19df3c0584186fbd106d526ed04be3c0a1664'
exit 128
```

A refspec starting with `^` takes refs away from what the others match. Git's
documentation puts it as: a ref is included if it matches at least one positive
refspec and no negative one. `^refs/heads/wip-*` left out every branch starting
`wip-`.

`^wip-1` left out nothing, and said nothing. Like a pattern, a negative refspec
is compared with full names, so it has to start with `refs/`. It may be a
pattern, and may not have a destination or be a hash, which the last two
commands show.

> **Since Git 2.29.** Negative refspecs.

In the configuration, a negative refspec applies to every plain fetch. Since the
examples above, the server gained a branch `wip-2` and lost `wip-1`:

```console
$ git config set --append remote.origin.fetch '^refs/heads/wip-*' && git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
^refs/heads/wip-*
$ git fetch --prune -v && git branch -r --list 'origin/wip-*'
From /home/ada/server/atlas
 - [deleted]         (none)              -> origin/pr/7
 = [up to date]      main                -> origin/main
 = [up to date]      deserts             -> origin/deserts
 = [up to date]      drafts              -> origin/drafts
 = [up to date]      feature/borders     -> origin/feature/borders
 = [up to date]      feature/rivers/nile -> origin/feature/rivers/nile
 = [up to date]      release-1.0         -> origin/release-1.0
 = [up to date]      topic               -> origin/topic
  origin/wip-1
$ git fetch origin wip-2 && git branch -r --list 'origin/wip-*'
From /home/ada/server/atlas
 * branch            wip-2      -> FETCH_HEAD
 * [new branch]      wip-2      -> origin/wip-2
  origin/wip-1
  origin/wip-2
```

Three things happened that are worth knowing.

`wip-2` was not fetched, as intended. But `origin/wip-1`, whose branch is gone,
was not pruned either: pruning only considers refs the refspecs cover, and the
negative refspec uncovered it. Delete it by hand with `git branch -d -r`
(Chapter 23).

`origin/pr/7`, fetched earlier by hand into `refs/remotes/origin/pr/`, *was*
pruned. The configured refspec's destination covers everything under
`refs/remotes/origin/`, and the server has no branch `pr/7`, so Git's
documentation for pruning applies as it says: refs are pruned as a function of
the refspec, not of how they were made. Keep refs from other sources out of a
remote's namespace, or add their refspec to the configuration, as the next
section does.

And naming `wip-2` on the command line fetched it, and also created
`origin/wip-2`: the negative refspec decides what a plain fetch takes, not where
a branch you name is stored.

### Several refspecs for one remote

```console
$ git config set --append remote.origin.fetch '+refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*' && git fetch
From /home/ada/server/atlas
 * [new ref]         refs/merge-requests/3/head -> origin/merge-requests/3
$ git config get --all remote.origin.fetch
+refs/heads/*:refs/remotes/origin/*
^refs/heads/wip-*
+refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

`remote.<name>.fetch` can have any number of lines, and a plain fetch applies
all of them. The one added is the line GitLab's documentation gives for
checking out merge requests; for GitHub, the same form with
`+refs/pull/*/head:refs/remotes/origin/pr/*` fetches every pull request. Each
line is added with `--append`. Without it, `git config set` replaces a setting
that has one line, and a remote whose branch refspec was replaced stops fetching
branches; with several lines it refuses, "cannot overwrite multiple values with
a single value", which was tried for this chapter.
`git remote set-branches` writes these lines too (Chapter 39).

### Refspecs that clone writes

In the directory above the clones:

```console
$ git clone -q --single-branch --branch deserts /home/ada/server/atlas.git one-branch && git -C one-branch config get --all remote.origin.fetch
+refs/heads/deserts:refs/remotes/origin/deserts
$ git clone -q --mirror /home/ada/server/atlas.git mirror.git && git -C mirror.git config get --all --show-names --regexp '^remote\.origin\.'
remote.origin.url /home/ada/server/atlas.git
remote.origin.tagopt --no-tags
remote.origin.fetch +refs/*:refs/*
remote.origin.mirror true
$ git clone -q --bare /home/ada/server/atlas.git bare.git && git -C bare.git config get --all remote.origin.fetch; echo "exit $?"
exit 1
```

A single-branch clone fetches one branch, with no pattern, which is why later
fetches bring nothing else until the refspec is widened (Chapter 9, Chapter 39).
A mirror clone's `+refs/*:refs/*` copies every ref under its own name and
overwrites the local ones on every fetch. Tags arrive through that refspec
like any other ref, and `tagOpt` is set to `--no-tags`, so tag following is off. A bare clone writes no fetch refspec at all, and `git config get`
answers a missing setting with exit status 1.

## Push refspecs

### Push: source names

Ada has a local branch `topic` and the tag `topic`, and committed "Add Africa"
on `main`:

```console
$ git push origin topic; echo "exit $?"
error: src refspec topic matches more than one
error: failed to push some refs to '/home/ada/server/atlas.git'
exit 1
$ git push --porcelain origin heads/topic main~1:refs/heads/older $(git rev-parse main):refs/heads/by-hash
To /home/ada/server/atlas.git
=	refs/heads/topic:refs/heads/topic	[up to date]
*	main~1:refs/heads/older	[new branch]
*	dcc54d02ad781aeca6d1f50408a53f5e3b310d9b:refs/heads/by-hash	[new branch]
Done
```

A push's source is looked up in your repository. Where a fetch took the first
match, a push refuses a short name that matches more than one ref. `heads/topic`
or `refs/heads/topic` settles it. `--porcelain` prints both sides of every
refspec in full (Chapter 43), which makes it the way to see what a short name
became.

The source of a push can be any revision (Chapter 18): `main~1` and a full hash
both worked, and the porcelain line shows them as typed, because they are not
refs. Their destinations have to be full names, as Chapter 43 shows.

### Push: destination names

```console
$ git push --porcelain origin main:review
To /home/ada/server/atlas.git
*	refs/heads/main:refs/heads/review	[new branch]
Done
$ git push --porcelain origin v1.1:release
To /home/ada/server/atlas.git
*	refs/tags/v1.1:refs/tags/release	[new tag]
Done
$ git push --porcelain origin main:release; echo "exit $?"
error: failed to push some refs to '/home/ada/server/atlas.git'
hint: Updates were rejected because the tag already exists in the remote.
To /home/ada/server/atlas.git
!	refs/heads/main:refs/tags/release	[rejected] (already exists)
Done
exit 1
```

A short destination in a push is worked out from both sides, by the rules in
Git's documentation for `git push`: a name that already exists on the server
means that ref; otherwise the source's kind is used, `refs/heads/` for a branch
and `refs/tags/` for a tag. So `main:review` made a branch, `v1.1:release` a tag,
and `main:release`, with `release` now a tag on the server, was aimed at the tag
and refused like any change to a tag. When the server has a branch and a tag of
the same name, a short destination is refused with "dst refspec ... matches more
than one", as a test for this chapter showed; write it in full.

| Destination written | Source | Becomes |
|---|---|---|
| nothing, as in `main` | a branch or tag | the same full name as the source |
| a name the server has | anything | that ref |
| a new name | a branch | `refs/heads/<name>` |
| a new name | a tag | `refs/tags/<name>` |
| a new name | a commit expression or hash | an error: write `refs/heads/<name>` |
| a full name, `refs/...` | anything | exactly that |

```console
$ git push --porcelain origin main:refs/for/main
To /home/ada/server/atlas.git
*	refs/heads/main:refs/for/main	[new reference]
Done
$ git push --porcelain --force origin v1.1:refs/heads/tag-branch; echo "exit $?"
remote: error: trying to write non-commit object abffb58d0e339c924842fc460ea574966571c411 to branch 'refs/heads/tag-branch'        
error: failed to push some refs to '/home/ada/server/atlas.git'
To /home/ada/server/atlas.git
!	refs/tags/v1.1:refs/heads/tag-branch	[remote rejected] (invalid new value provided)
Done
exit 1
```

A full destination can be anywhere under `refs/`. Gerrit, a code review server,
turns a push to `refs/for/<branch>` into a review, and its documentation gives
the command as `git push <url> HEAD:refs/for/branch`; Git's own server, as here,
simply stores the ref. And as in a fetch, not even `--force` puts a tag object
into a branch: the server refused it.

### Push: empty sources and matching

```console
$ git push --porcelain origin :review :older
To /home/ada/server/atlas.git
-	:refs/heads/older	[deleted]
-	:refs/heads/review	[deleted]
Done
$ git push --porcelain --dry-run origin :
To /home/ada/server/atlas.git
=	refs/heads/topic:refs/heads/topic	[up to date]
 	refs/heads/main:refs/heads/main	0fe19df..dcc54d0
Done
```

Pushing nothing into a destination deletes it, which is what `--delete` writes
for you (Chapter 43). `:` alone pushes the *matching* branches, every local
branch whose name the server also has; Ada's `wip-3`, which the server lacks,
was left out. It is what `push.default=matching` does, and `+:` would force
them all.

### Push: patterns

```console
$ git push --porcelain origin 'refs/heads/*:refs/heads/backup/ada/*'
To /home/ada/server/atlas.git
*	refs/heads/main:refs/heads/backup/ada/main	[new branch]
*	refs/heads/topic:refs/heads/backup/ada/topic	[new branch]
*	refs/heads/wip-3:refs/heads/backup/ada/wip-3	[new branch]
Done
$ git push origin 'main:refs/heads/*'; echo "exit $?"
fatal: invalid refspec 'main:refs/heads/*'
exit 128
```

A pattern pushes every local ref it matches, here each branch into a prefix of
Ada's own on the server, which is a way to back up unfinished branches without
mixing them with the team's. With `--prune`, branches deleted locally are
deleted under the prefix too (Chapter 43). The rules for `*` are the fetch rules:
one on each side.

### Push: negative refspecs

```console
$ git push --porcelain --dry-run origin 'refs/heads/*:refs/heads/copy/*' '^refs/heads/wip-*'
To /home/ada/server/atlas.git
*	refs/heads/main:refs/heads/copy/main	[new branch]
*	refs/heads/topic:refs/heads/copy/topic	[new branch]
*	refs/heads/wip-3:refs/heads/copy/wip-3	[new branch]
Done
$ git push --porcelain --dry-run origin 'refs/heads/*:refs/heads/copy/*' '^refs/heads/copy/wip-*'
To /home/ada/server/atlas.git
*	refs/heads/main:refs/heads/copy/main	[new branch]
*	refs/heads/topic:refs/heads/copy/topic	[new branch]
Done
```

`^refs/heads/wip-*` did not leave out `wip-3`; `^refs/heads/copy/wip-*` did. In
a push, a negative refspec is compared with the names on the server, the
destinations, which Git's source applies to the list of remote refs
(`apply_negative_refspecs` in `remote.c`). When the names are the same on both
sides, as in Git's documentation's example
`git push origin 'refs/heads/*' '^refs/heads/dev-*'`, the difference does not
show. So in both directions a negative refspec names refs as the server calls
them: the source of a fetch, the destination of a push.

### Push refspecs in the configuration

```console
$ git config set remote.origin.push 'refs/heads/main:refs/heads/review/main' && git push --porcelain && git push --porcelain origin wip-3
To /home/ada/server/atlas.git
*	refs/heads/main:refs/heads/review/main	[new branch]
Done
To /home/ada/server/atlas.git
*	refs/heads/wip-3:refs/heads/wip-3	[new branch]
Done
```

`remote.<name>.push` gives a push that names no refspec its refspecs, before
`push.default` is consulted (Chapter 43). A refspec on the command line replaces
it, so `git push origin wip-3` pushed `wip-3` normally.

Ada committed "Add Asia":

```console
$ git config set remote.origin.push 'HEAD:refs/for/main' && git push --porcelain
To /home/ada/server/atlas.git
 	HEAD:refs/for/main	dcc54d0..7534a26
Done
```

`HEAD` works in the configuration too, so a plain `git push` sent the current
branch to `refs/for/main`, which on Gerrit saves typing the refspec for every
review. Here the ref already existed from the push above, and was updated.

## Names Git refuses

```console
$ git fetch origin 'ma..in'; echo "exit $?"
fatal: invalid refspec 'ma..in'
exit 128
$ git check-ref-format --branch 'ma..in'; echo "exit $?"
fatal: 'ma..in' is not a valid branch name
exit 128
$ git push origin 'tag v1.1'; echo "exit $?"
fatal: invalid refspec 'tag v1.1'
exit 128
$ git push origin 'main:refs/heads/x:y'; echo "exit $?"
error: src refspec main:refs/heads/x does not match any
error: failed to push some refs to '/home/ada/server/atlas.git'
exit 1
```

Each side of a refspec must be a valid ref name, and `..` is not allowed in one.
`git check-ref-format` tests a name without trying to use it, and its
documentation lists every rule, such as no `..`, no spaces, and no name ending
in `.lock`.

`tag <name>` is two arguments, not a refspec: Git's documentation for `git push`
calls it "technically a special syntax", and in quotes, as one argument, it is
invalid. It cannot go into `remote.<name>.fetch` either; write
`refs/tags/v1.1:refs/tags/v1.1` there.

A refspec is split at its last colon, so a second colon makes the source
`main:refs/heads/x`, which names nothing, and the error says so in its own
terms.

## Common refspecs

| To | Refspec | Where |
|---|---|---|
| fetch every branch, as `git clone` sets up | `+refs/heads/*:refs/remotes/origin/*` | `remote.origin.fetch` |
| fetch one branch only | `+refs/heads/main:refs/remotes/origin/main` | `remote.origin.fetch` |
| fetch every tag | `+refs/tags/*:refs/tags/*`, or `git fetch --tags` (Chapter 41) | command line or `remote.<name>.fetch` |
| fetch GitHub pull requests | `+refs/pull/*/head:refs/remotes/origin/pr/*` | `remote.origin.fetch`, added |
| look at one GitHub pull request | `pull/<number>/head:<branch>` | `git fetch origin` |
| fetch GitLab merge requests | `+refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*` | `remote.origin.fetch`, added |
| fetch or push notes, which Chapter 38 explains | `refs/notes/*:refs/notes/*` | command line, or `remote.<name>.fetch`, added |
| fetch or push replacements | `refs/replace/*:refs/replace/*` | command line (Chapter 38) |
| leave out branches | `^refs/heads/<prefix>*` | with a positive refspec |
| copy every ref | `+refs/*:refs/*` | a mirror clone's `remote.origin.fetch` |
| back up your branches under a prefix | `refs/heads/*:refs/heads/backup/<you>/*` | `git push`, with `--prune` to follow deletions |
| send for review on Gerrit | `HEAD:refs/for/<branch>` | `git push`, or `remote.origin.push` |
| delete a branch on the server | `:<branch>` | `git push` |

## Refspecs and their neighbours

| Looks like | Is | Matches | Covered in |
|---|---|---|---|
| `main:review`, `refs/heads/*:refs/remotes/origin/*` | a refspec | full or expanded ref names, on two sides | this chapter |
| `main~1`, `origin/main`, `HEAD@{1}` | a revision | one commit; usable as a push source only | Chapter 18 |
| `git ls-remote origin 'main'` | a pattern for `ls-remote` | the end of the server's ref names | Chapter 39 |
| `git branch --list 'feature/*'` | a glob | local branch names | Chapter 23 |
| `git log -- 'maps/*'` | a pathspec | files, not refs | Chapter 11 |

## The settings

| Setting | Does |
|---|---|
| `remote.<name>.fetch` | Fetch refspecs: what a plain fetch takes, and where named branches go; several lines allowed |
| `remote.<name>.push` | Push refspecs, used when a push names none, before `push.default` (Chapter 43) |
| `remote.<name>.mirror` | Pushes act as `--mirror`, pushing every ref (Chapter 43) |
| `remote.<name>.tagOpt` | Tag following on or off for this remote (Chapter 41) |
| `remote.<name>.prune`, `fetch.prune` | Prune what the fetch refspecs' destinations cover (Chapter 41) |
| `fetch.showForcedUpdates` | `false` skips the forced-update check, and with it the effect of a missing `+` |
| `push.default` | What a push sends when neither the command line nor `remote.<name>.push` says (Chapter 43) |
