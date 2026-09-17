# Chapter 39. remote

## What it is

`git remote` manages the list of other repositories that this one knows by
name. On its own it answers one question: *which other repositories does this
repository know about?*

A *remote* is a short name, such as `origin`, standing for another repository's
address, together with a rule saying which of its branches to copy and where to
keep the copies. That is all it is: a few lines of configuration in
`.git/config`. Adding, renaming or removing a remote changes your repository
only. Nothing on the other repository changes, and most subcommands do not
contact it at all.

| Term | Means |
|---|---|
| *remote* | a name for another repository's URL, with the rules for fetching from it |
| *URL* | where that repository is: a path such as `/srv/atlas.git`, or an address such as `https://example.com/atlas.git` or `git@example.com:atlas.git` (Chapter 9 lists the forms, Chapter 40 explains them) |
| *fetch* | copy commits and branch positions from a remote into your repository, without touching your own branches (Chapter 41) |
| *remote-tracking branch* | your repository's copy of a branch on a remote, as it was at the last fetch, such as `origin/main`; its full name is `refs/remotes/origin/main` (Chapter 41) |
| *stale* | said of a remote-tracking branch whose branch has since been deleted on the server |
| *`<name>/HEAD`* | a ref such as `origin/HEAD` that names another remote-tracking branch, recording the remote's default branch |
| *fetch refspec* | the rule, such as `+refs/heads/*:refs/remotes/origin/*`, that says which branches a fetch copies and under which names it stores them |
| *upstream* | the branch a local branch is compared with and pulls from (Chapter 23); also, by convention, the name given to the original project's remote when `origin` is your own copy of it |
| *fork* | a copy of someone else's repository on a server, under your own account, that you can push to (Chapter 50) |

The fetch refspec is the one line worth reading closely now. In
`+refs/heads/*:refs/remotes/origin/*`, the left side names branches on the
remote, the right side names where their copies go in your repository, the two
`*` stand for the same branch name, and the leading `+` lets a copy be updated
even when the branch on the remote was rewritten. Chapter 44 covers refspecs in
full.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a remote? Is it a copy of the other repository?](#what-it-is)
- [If I add or remove a remote, does anything change on the server?](#what-it-is)
- [What does `+refs/heads/*:refs/remotes/origin/*` mean?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git remote`?](#synopsis)

**[Subcommands and options at a glance](#subcommands-and-options-at-a-glance)**

- [Is there a list of every subcommand and option, and where each is shown?](#subcommands-and-options-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repositories do the examples use?](#the-example-repository)

**[Listing remotes](#listing-remotes)**

- [How do I see which remotes I have, and their addresses?](#listing-remotes)
- [Why are there two lines for each remote, `(fetch)` and `(push)`?](#listing-remotes)
- [I typed `git remote show -v` and got "unknown switch". Where does `-v` go?](#listing-remotes)
- [`git remote` printed nothing. Is something wrong?](#listing-remotes)
- [What is the `[blob:none]` after a URL?](#listing-remotes)

**[Adding a remote](#adding-a-remote)**

- [How do I add a second remote, and what does Git write?](#adding-a-remote)
- [I added a remote, but none of its branches show up. Why?](#adding-a-remote)
- [How do I add a remote and fetch from it in one step?](#fetching-straight-away)
- [Why does Git say my remote name is "not valid", or "a subset of" another?](#names-git-refuses)
- [I typed the address wrong and `git remote add` did not complain. Why?](#an-address-that-does-not-work)
- [`git remote add -f` failed. Was the remote added anyway?](#an-address-that-does-not-work)
- [I added a remote with a relative path and it doesn't work. Relative to what?](#relative-paths)
- [How do I set up a remote that fetches only one or two branches?](#tracking-only-some-branches)
- [What do `--tags` and `--no-tags` do when adding a remote?](#tags)
- [What is a mirror remote, and what is the difference between `--mirror=fetch` and `--mirror=push`?](#mirrors)
- [I added a mirror to my normal repository and fetching fails. Why?](#mirrors)
- [What does `git push` to a push mirror send?](#mirrors)
- [Why does Git say a master branch "makes no sense with --mirror"?](#mirrors)

**[Renaming a remote](#renaming-a-remote)**

- [How do I rename a remote, for example `origin` to `upstream`?](#renaming-a-remote)
- [Do my branches still track the right place after a rename?](#renaming-a-remote)

**[Removing a remote](#removing-a-remote)**

- [How do I remove a remote, and what goes with it?](#removing-a-remote)
- [Does removing a remote delete my local branches or commits?](#removing-a-remote)
- [Can I remove two remotes at once?](#removing-a-remote)
- [I removed a remote and `git branch -r` shows nothing of it. Is it all gone?](#a-remote-that-tracks-only-some-branches)
- [Rename failed with "dangling symref already exists". What happened, and how do I fix it?](#a-rename-that-stops-halfway)

**[The remote's default branch](#the-remote-s-default-branch)**

- [What is `origin/HEAD`, and what is it for?](#the-remote-s-default-branch)
- [The server changed its default branch. How do I update `origin/HEAD`?](#the-remote-s-default-branch)
- [Why does `git remote set-head origin <branch>` say "Not a valid ref"?](#the-remote-s-default-branch)

**[Choosing which branches to fetch](#choosing-which-branches-to-fetch)**

- [How do I stop fetching every branch of a remote, or add one more later?](#choosing-which-branches-to-fetch)
- [I ran `set-branches` with a branch name and nothing changed. Why?](#when-set-branches-does-nothing)

**[URLs](#urls)**

- [How do I print a remote's URL?](#reading-a-url)
- [The server moved. How do I change the URL?](#changing-a-url)
- [Can I change only a URL that matches a pattern?](#changing-a-url)
- [Can I fetch from one address and push to another?](#a-different-url-for-pushing)
- [Can one remote push to two servers at once?](#several-urls)
- [I added a push URL and now my pushes stopped going to the second server. Why?](#several-urls)
- [How do I delete a URL, and why does Git refuse to delete the last one?](#deleting-urls)
- [The URL in `git remote -v` is not what my config file says. Why?](#rewriting-urls)

**[Inspecting a remote](#inspecting-a-remote)**

- [How do I see everything about a remote: its branches, and what pull and push will do?](#inspecting-a-remote)
- [What do "new", "tracked" and "stale" mean?](#inspecting-a-remote)
- [What do "fast-forwardable" and "local out of date" mean?](#inspecting-a-remote)
- [A branch is listed as "skipped". Why?](#inspecting-a-remote)
- [Why does `git remote show` say my branch pushes to a remote I never push to?](#inspecting-a-remote)
- [Can I see the remote's details without connecting to it?](#without-asking-the-server)
- [What does "(matching) pushes to (matching)" mean?](#without-asking-the-server)
- [What do "rebases onto remote" and "create" mean?](#the-pull-and-push-lines)
- [`git remote show` fails for a server that is down. How do I still see its settings?](#a-remote-that-cannot-be-reached)

**[git ls-remote](#git-ls-remote)**

- [How do I see which branches and tags a server has, without fetching anything?](#git-ls-remote)
- [What is the line ending in `^{}`?](#git-ls-remote)
- [How do I list only branches, or only tags?](#only-branches-or-only-tags)
- [Is `--heads` the same as `--branches`? And why does `-h` print help?](#only-branches-or-only-tags)
- [I asked for `ain` and got nothing, although `main` exists. How do patterns match?](#patterns)
- [How do I find out which branch is the server's default?](#symbolic-refs)
- [How can a script check whether a branch exists on the server?](#exit-status)
- [How do I list tags newest version first?](#sorting)
- [Sorting by date says "missing object". Why?](#sorting)
- [Which remote does `git ls-remote` use when I name none? What is the `From` line?](#without-a-remote-name)
- [Can I use `git ls-remote` outside a repository?](#without-a-remote-name)
- [How do I tell `ls-remote` where Git is installed on the server, or pass options to the server?](#the-program-on-the-other-end)

**[Removing stale remote-tracking branches](#removing-stale-remote-tracking-branches)**

- [A branch was deleted on the server but I still see it. How do I get rid of it?](#removing-stale-remote-tracking-branches)
- [What happens to my local branch that tracked it?](#removing-stale-remote-tracking-branches)
- [I stopped fetching some branches and their old copies are still there. Why doesn't prune remove them?](#branches-you-stopped-fetching)

**[Fetching from several remotes](#fetching-from-several-remotes)**

- [How do I fetch from all my remotes at once?](#fetching-from-several-remotes)
- [How do I fetch from a chosen group of remotes?](#fetching-from-several-remotes)
- [How do I leave one remote out when fetching all of them?](#fetching-from-several-remotes)

**[Remotes defined in files](#remotes-defined-in-files)**

- [An old repository has `.git/remotes` or `.git/branches` directories. What are they?](#remotes-defined-in-files)
- [Git warns that reading a remote from a file is "nominated for removal". What do I do?](#remotes-defined-in-files)

**[Common setups](#common-setups)**

- [Should my remote be called `origin` or `upstream`?](#common-setups)
- [How do I set up remotes for working on a fork?](#common-setups)

**[Exit status of git remote](#exit-status-of-git-remote)**

- [How does a script tell "no such remote" from "already exists"?](#exit-status-of-git-remote)
- [Does every subcommand exit 2 for a remote that does not exist?](#exit-status-of-git-remote)

**[remote and its neighbours](#remote-and-its-neighbours)**

- [Can I just edit `.git/config` instead of using `git remote`?](#remote-and-its-neighbours)
- [What is the difference between `git remote show`, `git ls-remote` and `git branch -r`?](#remote-and-its-neighbours)
- [Are `git remote update` and `git remote prune` the same as options of `git fetch`?](#remote-and-its-neighbours)

**[The settings](#the-settings)**

- [Which settings belong to a remote, and what does each one do?](#the-settings)

</details>

## Synopsis

```
git remote [-v | --verbose]
git remote add [-t <branch>] [-m <master>] [-f] [--[no-]tags] [--mirror=(fetch|push)] <name> <URL>
git remote rename [--[no-]progress] <old> <new>
git remote remove <name>
git remote set-head <name> (-a | --auto | -d | --delete | <branch>)
git remote set-branches [--add] <name> <branch>...
git remote get-url [--push] [--all] <name>
git remote set-url [--push] <name> <newurl> [<oldurl>]
git remote set-url --add [--push] <name> <newurl>
git remote set-url --delete [--push] <name> <URL>
git remote [-v | --verbose] show [-n] <name>...
git remote prune [-n | --dry-run] <name>...
git remote [-v | --verbose] update [-p | --prune] [(<group> | <remote>)...]
```

| Part | Means |
|---|---|
| `<name>`, `<old>`, `<new>` | A remote's name, such as `origin` |
| `<URL>`, `<newurl>` | An address: a path, `file://`, `https://`, `ssh://` or `user@host:path` |
| `<oldurl>` | A regular expression; the first URL of the remote that matches it is replaced |
| `<branch>` | A branch name on the remote, without `refs/heads/`; `*` is allowed in `set-branches` |
| `<master>` | The branch `<name>/HEAD` should point at |
| `<group>` | A list of remotes defined in the setting `remotes.<group>` |

| Command | Does |
|---|---|
| `git remote -v` | List remotes with their URLs |
| `git remote add <name> <URL>` | Add a remote; fetch nothing |
| `git remote rename <old> <new>` | Rename it, with its remote-tracking branches and settings |
| `git remote remove <name>` | Remove it, with its remote-tracking branches and settings |
| `git remote set-head <name> -a` | Point `<name>/HEAD` at the server's default branch |
| `git remote set-branches <name> <branch>...` | Fetch only these branches from now on |
| `git remote get-url <name>` | Print the URL |
| `git remote set-url <name> <newurl>` | Change the URL |
| `git remote show <name>` | Describe the remote, asking the server for its current state |
| `git remote prune <name>` | Delete remote-tracking branches whose branch is gone from the server |
| `git remote update` | Fetch from every remote |

`rm` is accepted for `remove`. With no subcommand, `git remote` lists names;
`git remote show` with no name does the same.

## Subcommands and options at a glance

| Subcommand | Does | Covered in |
|---|---|---|
| (none), `show` with no name | List remote names | [Listing remotes](#listing-remotes) |
| `add` | Add a remote | [Adding a remote](#adding-a-remote) |
| `rename` | Rename a remote and everything that uses its name | [Renaming a remote](#renaming-a-remote) |
| `remove`, `rm` | Remove a remote and everything that uses its name | [Removing a remote](#removing-a-remote) |
| `set-head` | Set or delete `<name>/HEAD` | [The remote's default branch](#the-remote-s-default-branch) |
| `set-branches` | Replace or extend the list of branches fetched | [Choosing which branches to fetch](#choosing-which-branches-to-fetch) |
| `get-url` | Print URLs | [Reading a URL](#reading-a-url) |
| `set-url` | Change, add or delete URLs | [Changing a URL](#changing-a-url) |
| `show` | Describe a remote | [Inspecting a remote](#inspecting-a-remote) |
| `prune` | Delete stale remote-tracking branches | [Removing stale remote-tracking branches](#removing-stale-remote-tracking-branches) |
| `update` | Fetch from several remotes | [Fetching from several remotes](#fetching-from-several-remotes) |

| Option | With | Does | Covered in |
|---|---|---|---|
| `-v`, `--verbose` | no subcommand, `show`, `update` | Add URLs to the list; more detail from `update`. Goes before the subcommand | [Listing remotes](#listing-remotes) |
| `-f` | `add` | Fetch from the new remote straight away | [Fetching straight away](#fetching-straight-away) |
| `-t <branch>` | `add` | Fetch only this branch; repeatable | [Tracking only some branches](#tracking-only-some-branches) |
| `-m <master>` | `add` | Set `<name>/HEAD` to this branch | [Tracking only some branches](#tracking-only-some-branches) |
| `--tags` | `add` | Always fetch every tag from this remote | [Tags](#tags) |
| `--no-tags` | `add` | Never fetch tags from this remote | [Tags](#tags) |
| `--mirror=fetch` | `add` | Fetch every ref straight into the same name, for a bare copy | [Mirrors](#mirrors) |
| `--mirror=push` | `add` | Make every `git push` to it behave like `git push --mirror` | [Mirrors](#mirrors) |
| `--progress`, `--no-progress` | `rename` | Show or hide progress while references are renamed | [Renaming a remote](#renaming-a-remote) |
| `-a`, `--auto` | `set-head` | Ask the server which branch its `HEAD` names | [The remote's default branch](#the-remote-s-default-branch) |
| `-d`, `--delete` | `set-head` | Delete `<name>/HEAD` | [The remote's default branch](#the-remote-s-default-branch) |
| `--add` | `set-branches` | Add to the list instead of replacing it | [Choosing which branches to fetch](#choosing-which-branches-to-fetch) |
| `--push` | `get-url`, `set-url` | Work on push URLs instead of fetch URLs | [A different URL for pushing](#a-different-url-for-pushing) |
| `--all` | `get-url` | Print every URL, not only the first | [Several URLs](#several-urls) |
| `--add` | `set-url` | Add a URL instead of changing one | [Several URLs](#several-urls) |
| `--delete` | `set-url` | Delete every URL matching a regular expression | [Deleting URLs](#deleting-urls) |
| `-n` | `show` | Do not contact the server | [Without asking the server](#without-asking-the-server) |
| `-n`, `--dry-run` | `prune` | Report what would be pruned | [Removing stale remote-tracking branches](#removing-stale-remote-tracking-branches) |
| `-p`, `--prune` | `update` | Prune while fetching | [Fetching from several remotes](#fetching-from-several-remotes) |

<!-- no-example: --progress
     Git starts rename's progress display only when standard error is a
     terminal, and then as a delayed progress meter that appears only if
     the rename takes more than a moment. Tested with --progress and
     --no-progress on the example repository: both printed nothing, because
     renaming a handful of references finishes at once. -->

`git ls-remote` is a separate command, covered in this chapter because it is
the other way to look at a remote:

| Option of `git ls-remote` | Does | Covered in |
|---|---|---|
| `-b`, `--branches` | Only branches | [Only branches or only tags](#only-branches-or-only-tags) |
| `-t`, `--tags` | Only tags | [Only branches or only tags](#only-branches-or-only-tags) |
| `--heads`, `-h` | Old names for `--branches` and `-b`; `-h` alone prints help | [Only branches or only tags](#only-branches-or-only-tags) |
| `--refs` | Leave out `HEAD` and the extra `^{}` line of each annotated tag | [Only branches or only tags](#only-branches-or-only-tags) |
| `--symref` | Show which branch the server's `HEAD` names | [Symbolic refs](#symbolic-refs) |
| `--exit-code` | Exit with status 2 when nothing matches | [Exit status](#exit-status) |
| `--sort=<key>` | Sort by a key, such as `version:refname` | [Sorting](#sorting) |
| `-q`, `--quiet` | Do not print the `From` line | [Without a remote name](#without-a-remote-name) |
| `--get-url` | Print the URL that would be used, and contact nothing | [Without a remote name](#without-a-remote-name) |
| `--upload-pack=<exec>` | Name the program to run on the server | [The program on the other end](#the-program-on-the-other-end) |
| `-o <option>`, `--server-option=<option>` | Send a string to the server | [The program on the other end](#the-program-on-the-other-end) |

## The example repository

```console
$ git log --oneline --decorate --all
255682e (origin/rivers) List rivers
0fe19df (HEAD -> main, tag: v1.0, origin/main, origin/HEAD) Add Europe
0dd6887 Start the atlas
$ git -C /home/ada/server/atlas.git log --oneline --decorate --all
a6c5b74 (deserts) List deserts
23547ae (HEAD -> main, tag: v1.1-rc) Add Africa
255682e (rivers) List rivers
0fe19df (tag: v1.0) Add Europe
0dd6887 Start the atlas
```

A team keeps an atlas on a server. Four bare repositories stand in for the
server, all under `/home/ada/server`, so the examples need no network:

| Repository | Is |
|---|---|
| `atlas.git` | the team's repository, second in the transcript; Bob has added Africa and a `deserts` branch |
| `ada-atlas.git` | Ada's fork, copied before Bob's work; Ada cloned it into `/home/ada/atlas`, first in the transcript |
| `bob-atlas.git` | Bob's fork, with a `mountains` branch of his own |
| `backup.git`, `copy1.git`, `copy2.git` | empty, for pushing to |

Every command runs in Ada's clone unless the transcript says otherwise, and the
examples run in order, so each one sees what the earlier ones did.

## Listing remotes

```console
$ git remote
origin
$ git remote -v
origin	/home/ada/server/ada-atlas.git (fetch)
origin	/home/ada/server/ada-atlas.git (push)
$ git remote show -v
error: unknown switch `v'
usage: git remote show [<options>] <name>

    -n                    do not query remotes

```

A clone has one remote, `origin`, which `git clone` added (Chapter 9). `-v`
adds the URLs, one line for fetching and one for pushing, because a remote can
push somewhere other than where it fetches from; see
[A different URL for pushing](#a-different-url-for-pushing). The two lines
separate name and URL with a tab.

`-v` belongs to `git remote` itself, so it goes before a subcommand, as Git's
documentation says. After `show` it is read as an option of `show`, which has
none by that name.

```console
$ git -C /home/ada/empty remote
$ git remote
fatal: not a git repository (or any of the parent directories): .git
$ git -C /home/ada/partial remote -v
origin	file:///home/ada/server/atlas.git (fetch) [blob:none]
origin	file:///home/ada/server/atlas.git (push)
```

A repository made with `git init` has no remotes, and the list is simply empty.
Outside any repository there is nothing to list. In a partial clone
(Chapter 46), `-v` shows the filter the remote is fetched with after the fetch
URL.

> **Since Git 2.37.** `git remote -v` shows a partial clone's filter.

## Adding a remote

```console
$ git remote add bob /home/ada/server/bob-atlas.git
$ git remote -v
bob	/home/ada/server/bob-atlas.git (fetch)
bob	/home/ada/server/bob-atlas.git (push)
origin	/home/ada/server/ada-atlas.git (fetch)
origin	/home/ada/server/ada-atlas.git (push)
$ git config get --all --show-names --regexp '^remote\.bob'
remote.bob.url /home/ada/server/bob-atlas.git
remote.bob.fetch +refs/heads/*:refs/remotes/bob/*
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/rivers
```

`git remote add` writes two settings, printed here with `git config get`
(Chapter 3): the URL, and a fetch refspec that will store every branch of
`bob` under `bob/`. It prints nothing and contacts nothing, which is why
`git branch -r` lists no `bob/` branches yet. They appear at the first fetch
(Chapter 41).

The list is sorted by name, not by the order remotes were added.

> **Windows.** In Git Bash, an absolute path such as `/c/Users/ada/atlas.git` is
> converted by the shell before Git sees it, so the URL Git stores, and
> `git remote -v` prints, is `C:/Users/ada/atlas.git`. In PowerShell the path
> reaches Git unchanged and is stored as typed. Tested outside the sandbox, a
> remote added from PowerShell with either form, `/c/Users/...` or
> `C:/Users/...`, worked with `git ls-remote`.

### Fetching straight away

```console
$ git remote add -f upstream /home/ada/server/atlas.git
Updating upstream
From /home/ada/server/atlas
 * [new branch]      deserts    -> upstream/deserts
 * [new branch]      main       -> upstream/main
 * [new branch]      rivers     -> upstream/rivers
 * [new tag]         v1.1-rc    -> v1.1-rc
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/rivers
  upstream/HEAD -> upstream/main
  upstream/deserts
  upstream/main
  upstream/rivers
```

`-f` runs `git fetch upstream` once the remote is added. `Updating upstream`
is `git remote`'s line; the rest is the fetch, one line per branch or tag it
stored, which Chapter 41 reads column by column. `v1.0` is not listed because
Ada already had it.

`upstream/HEAD` appeared with the branches; the section
[The remote's default branch](#the-remote-s-default-branch) says what it is.

### Names Git refuses

```console
$ git remote add upstream /home/ada/server/elsewhere.git; echo "exit $?"
error: remote upstream already exists.
exit 3
$ git remote add 'the team' /home/ada/server/atlas.git; echo "exit $?"
fatal: 'the team' is not a valid remote name
exit 128
$ git remote add upstream/old /home/ada/server/atlas.git; echo "exit $?"
fatal: remote name 'upstream/old' is a subset of existing remote 'upstream'
exit 128
$ git remote add team/eu /home/ada/server/atlas.git && git remote add team /home/ada/server/atlas.git; echo "exit $?"
fatal: remote name 'team' is a superset of existing remote 'team/eu'
exit 128
```

An existing name is refused with exit status 3, and nothing is changed; to
point an existing remote somewhere else, change its URL instead
([Changing a URL](#changing-a-url)).

A remote's name becomes part of ref names, `refs/remotes/<name>/...`, so it must
be something a ref name may contain. Git's source checks exactly that: the name
is valid if `refs/heads/test:refs/remotes/<name>/test` is a valid refspec. A
space is not allowed, and neither is anything else Chapter 23 lists as illegal
in a branch name.

A slash is allowed, so `team/eu` is a valid name. What is refused is one name
inside another: `upstream/old` would keep its branches in
`refs/remotes/upstream/old/...`, which is where a branch called `old/...` of
`upstream` would go. Git refuses the overlap in either order.

> **Since Git 2.51.** Overlapping remote names are refused. An older Git accepts
> them, and the two remotes' branches then share one directory.

### An address that does not work

```console
$ git remote add typo /home/ada/server/atlass.git; echo "exit $?"
exit 0
$ git remote add -f typo2 /home/ada/server/atlass.git; echo "exit $?"
Updating typo2
fatal: '/home/ada/server/atlass.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
error: Could not fetch typo2
exit 1
$ git remote
bob
origin
typo
typo2
upstream
```

Git does not check the URL when it adds a remote, because it does not contact
it. The mistake shows up at the first command that does. With `-f` that is
straight away, and the remote stays added even though the fetch failed: fix it
with `git remote set-url`, or remove it and add it again.

The same three `fatal` lines appear for any server Git cannot read from: a
wrong path, a wrong host, missing permissions. Chapter 40 separates the causes.

### Relative paths

`git ls-remote <remote> main` asks a remote for one branch, which is enough to
show whether its URL works; [git ls-remote](#git-ls-remote) covers it in full.

```console
$ cd maps
$ git remote add here ../../server/atlas.git
$ git ls-remote here main
fatal: '../../server/atlas.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
$ git remote set-url here ../server/atlas.git
$ git ls-remote here main
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
$ cd ..
$ git ls-remote here main
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
```

Git stores a relative path exactly as typed, and uses it relative to the top of
the working tree, whichever directory you are in when you use the remote.
`../../server/atlas.git` was right from `maps`, where Ada typed it, and wrong
for Git. `../server/atlas.git` works from `maps` and from the top alike.

An absolute path avoids the question, and so does moving the repository: a
relative URL breaks when either end moves.

### Tracking only some branches

`git remote update <name>` fetches from that remote; see
[Fetching from several remotes](#fetching-from-several-remotes).

```console
$ git remote add -t main -t deserts -m main selected /home/ada/server/atlas.git
$ git config get --all --show-names --regexp '^remote\.selected'
remote.selected.url /home/ada/server/atlas.git
remote.selected.fetch +refs/heads/main:refs/remotes/selected/main
remote.selected.fetch +refs/heads/deserts:refs/remotes/selected/deserts
$ git remote update selected && git branch -r --list 'selected/*'
Fetching selected
From /home/ada/server/atlas
 * [new branch]      main       -> selected/main
 * [new branch]      deserts    -> selected/deserts
  selected/HEAD -> selected/main
  selected/deserts
  selected/main
```

Each `-t` writes one fetch refspec naming one branch instead of the `*` pattern,
so a fetch copies only those branches: `rivers` was left on the server.
`-m main` makes `selected/HEAD` point at `selected/main`.

This is the tool for a remote with hundreds of branches of which you need two.
To change the list later, use `set-branches`
([Choosing which branches to fetch](#choosing-which-branches-to-fetch)).

### Tags

```console
$ git remote add --no-tags notags /home/ada/server/atlas.git && git remote add --tags alltags /home/ada/server/atlas.git
$ git config get --all --show-names --regexp '^remote\.(notags|alltags)\.tagopt'
remote.notags.tagopt --no-tags
remote.alltags.tagopt --tags
```

Both options write `remote.<name>.tagOpt`, which every later fetch from that
remote obeys. By default a fetch brings the tags that point into the history it
fetched; `--no-tags` stops that, and `--tags` fetches every tag on the server
even when no fetched branch reaches it. Chapter 41 shows the three behaviours
fetching.

### Mirrors

```console
$ git init -q --bare mirror.git && git -C mirror.git remote add --mirror=fetch origin /home/ada/server/atlas.git
$ git -C mirror.git config get --all --show-names --regexp '^remote\.'
remote.origin.url /home/ada/server/atlas.git
remote.origin.fetch +refs/*:refs/*
$ git -C mirror.git remote update
From /home/ada/server/atlas
 * [new branch]      deserts    -> deserts
 * [new branch]      main       -> main
 * [new branch]      rivers     -> rivers
 * [new tag]         v1.0       -> v1.0
 * [new tag]         v1.1-rc    -> v1.1-rc
$ git -C mirror.git branch
  deserts
* main
  rivers
```

A *fetch mirror* copies every ref on the server to the same name locally:
`+refs/*:refs/*`. The server's branches became `mirror.git`'s own branches, not
remote-tracking branches, and each fetch overwrites them. This is how to keep a
bare backup copy of a repository up to date; `git clone --mirror` writes the
same fetch refspec in one step (Chapter 9).

Git's documentation says it only makes sense in a bare repository, because the
fetch would overwrite local commits. In a repository with a working tree:

```console
$ git remote add --mirror=fetch copy /home/ada/server/atlas.git && git remote update copy
Fetching copy
fatal: refusing to fetch into branch 'refs/heads/main' checked out at '/home/ada/atlas'
error: could not fetch copy
$ git remote remove copy
Note: A branch outside the refs/remotes/ hierarchy was not removed;
to delete it, use:
  git branch -d main
```

Git refused to overwrite the branch that is checked out, and nothing was
fetched. Removing the remote then offers to delete `main`, because the mirror's
refspec claims `refs/heads/main` as its own. Do not follow that advice here:
`main` is Ada's branch, and the note only means `git remote remove` left it
alone.

```console
$ git remote add --mirror=push backup /home/ada/server/backup.git
$ git config get --all --show-names --regexp '^remote\.backup'
remote.backup.url /home/ada/server/backup.git
remote.backup.mirror true
$ git push backup
To /home/ada/server/backup.git
 * [new branch]      main -> main
 * [new reference]   origin/HEAD -> origin/HEAD
 * [new reference]   origin/main -> origin/main
 * [new reference]   origin/rivers -> origin/rivers
 * [new reference]   upstream/HEAD -> upstream/HEAD
 * [new reference]   upstream/deserts -> upstream/deserts
 * [new reference]   upstream/main -> upstream/main
 * [new reference]   upstream/rivers -> upstream/rivers
 * [new tag]         v1.0 -> v1.0
 * [new tag]         v1.1-rc -> v1.1-rc
```

A *push mirror* sets `remote.<name>.mirror`, and every push to it behaves like
`git push --mirror` (Chapter 43): the server is made to match this repository.
That means every ref, including Ada's remote-tracking branches from `origin`
and `upstream`, and Git's documentation for `git push --mirror` adds that refs
are force-updated and that a ref deleted here is deleted there.

| Form | Writes | A later command |
|---|---|---|
| `git remote add --mirror=fetch` | `fetch = +refs/*:refs/*` | `git fetch` overwrites every local ref with the server's |
| `git remote add --mirror=push` | `mirror = true` | `git push` makes the server's refs match every local ref |

```console
$ git remote add --mirror old-style /home/ada/server/backup.git
warning: --mirror is dangerous and deprecated; please
	 use --mirror=fetch or --mirror=push instead
$ git config get --all --show-names --regexp '^remote\.old-style'
remote.old-style.url /home/ada/server/backup.git
remote.old-style.fetch +refs/*:refs/*
remote.old-style.mirror true
$ git remote add --mirror=both both /home/ada/server/backup.git
error: unknown --mirror argument: both
$ git remote add --mirror=push -m main m1 /home/ada/server/backup.git
fatal: specifying a master branch makes no sense with --mirror
$ git remote add --mirror=push -t main m2 /home/ada/server/backup.git
fatal: specifying branches to track makes sense only with fetch mirrors
```

`--mirror` with no value still works, with a warning, and sets up both kinds at
once. Any value other than `fetch` or `push` is an error. A mirror has no
remote-tracking branches, so it has no `<name>/HEAD` for `-m` to set, and a
push mirror fetches nothing, so `-t` means nothing for it.

## Renaming a remote

```console
$ git switch -q -c deserts upstream/deserts && git config set remote.pushDefault upstream
$ git branch -vv
* deserts a6c5b74 [upstream/deserts] List deserts
  main    0fe19df [origin/main] Add Europe
$ git remote rename upstream team
$ git branch -vv
* deserts a6c5b74 [team/deserts] List deserts
  main    0fe19df [origin/main] Add Europe
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/rivers
  team/HEAD -> team/main
  team/deserts
  team/main
  team/rivers
$ git config get --all --show-names --regexp '^(remote|branch)\.'
remote.origin.url /home/ada/server/ada-atlas.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
branch.main.remote origin
branch.main.merge refs/heads/main
remote.bob.url /home/ada/server/bob-atlas.git
remote.bob.fetch +refs/heads/*:refs/remotes/bob/*
remote.team.url /home/ada/server/atlas.git
remote.team.fetch +refs/heads/*:refs/remotes/team/*
branch.deserts.remote team
branch.deserts.merge refs/heads/deserts
remote.pushdefault team
$ git reflog show team/main
23547ae refs/remotes/team/main@{0}: remote: renamed refs/remotes/upstream/main to refs/remotes/team/main
23547ae refs/remotes/team/main@{1}: fetch upstream: storing head
```

Before the rename, Ada made a local `deserts` branch tracking
`upstream/deserts` (Chapter 24), and set `remote.pushDefault` to `upstream`
(Chapter 43). `git remote rename` then changed every place the name was used:

| What | Before | After |
|---|---|---|
| The configuration section | `remote.upstream.*` | `remote.team.*` |
| The fetch refspec | `refs/remotes/upstream/*` | `refs/remotes/team/*` |
| Remote-tracking branches, including `HEAD` | `upstream/...` | `team/...` |
| A branch's upstream | `branch.deserts.remote upstream` | `branch.deserts.remote team` |
| The default push remote | `remote.pushDefault upstream` | `remote.pushDefault team` |

The remote-tracking branches were renamed, not fetched again, and their reflogs
came with them, with an entry saying so (Chapter 36). The server was not
contacted, and `bob`, which has nothing to do with the name, was left as it was.

Two limits come from Git's source rather than its documentation. The refspecs
and remote-tracking branches are renamed only when a fetch refspec stores into
`refs/remotes/<old>/`; a hand-written refspec that stores somewhere else is left
as it was. And `remote.pushDefault` is renamed only when it is set in this
repository's own configuration; one in your global configuration still names the
old remote, as it does after `remove`.

```console
$ git remote rename nosuch other; echo "exit $?"
error: No such remote: 'nosuch'
exit 2
$ git remote rename team bob; echo "exit $?"
error: remote bob already exists.
exit 3
```

A missing remote is exit status 2 and a name that is taken is 3, as for `add`.

## Removing a remote

```console
$ git remote remove team
$ git branch -vv
* deserts a6c5b74 List deserts
  main    0fe19df [origin/main] Add Europe
$ git branch -r
  origin/HEAD -> origin/main
  origin/main
  origin/rivers
$ git config get --all --show-names --regexp '^(remote|branch)\.'
remote.origin.url /home/ada/server/ada-atlas.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
branch.main.remote origin
branch.main.merge refs/heads/main
remote.bob.url /home/ada/server/bob-atlas.git
remote.bob.fetch +refs/heads/*:refs/remotes/bob/*
$ git status -sb
## deserts
$ git log --oneline -1 deserts
a6c5b74 List deserts
```

`git remote remove` deleted the remote's settings and its remote-tracking
branches, and also everything that referred to it: `deserts` no longer has an
upstream, so `git status -sb` shows no `...team/deserts`, and
`remote.pushDefault` is gone.

What it did not delete is anything of yours. The local branch `deserts` and its
commit are still there. Nothing on the server changed either: removing a remote
only makes this repository forget the name.

```console
$ git remote rm bob && git remote
origin
$ git remote remove bob; echo "exit $?"
error: No such remote: 'bob'
exit 2
$ git remote remove origin upstream
usage: git remote remove <name>

$ git switch -q main && git branch -q -D deserts
$ git remote add -f upstream /home/ada/server/atlas.git
Updating upstream
From /home/ada/server/atlas
 * [new branch]      deserts    -> upstream/deserts
 * [new branch]      main       -> upstream/main
 * [new branch]      rivers     -> upstream/rivers
```

`rm` is the same subcommand. It takes exactly one name; two are a usage error.
Ada then deleted her `deserts` branch and added `upstream` back, which the rest
of the chapter uses.

Two kinds of ref survive a removal, according to Git's source. A ref another
remote's refspec also stores into is kept, because that remote still uses it.
And a ref outside `refs/remotes/` is never deleted, which is the note
[Mirrors](#mirrors) showed for `main`.

### A remote that tracks only some branches

```console
$ git remote add -t main selected /home/ada/server/atlas.git && git remote update selected
Fetching selected
From /home/ada/server/atlas
 * [new branch]      main       -> selected/main
$ git remote remove selected && git branch -r --list 'selected/*'
$ git symbolic-ref refs/remotes/selected/HEAD
refs/remotes/selected/main
```

`git remote remove` deletes the refs the remote's fetch refspecs store into.
A remote made with `-t main` stores only into `refs/remotes/selected/main`, but
the fetch also created `selected/HEAD`, and nothing in the refspec covers that
name. So it was left behind. `git branch -r` does not list it, since it points
at a branch that no longer exists, but `git symbolic-ref` still finds it.

A dangling symbolic ref like this does no harm until something wants the name.
Delete `<name>/HEAD` first, with `git remote set-head <name> -d`, and the
removal is clean.

### A rename that stops halfway

```console
$ git remote rename upstream selected
error: renaming remote references failed: cannot lock ref 'refs/remotes/selected/HEAD': dangling symref already exists
$ git config get --all --show-names --regexp '^remote\.'
remote.origin.url /home/ada/server/ada-atlas.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
remote.selected.url /home/ada/server/atlas.git
remote.selected.fetch +refs/heads/*:refs/remotes/upstream/*
$ git symbolic-ref --delete refs/remotes/selected/HEAD
$ git config rename-section remote.selected remote.upstream
$ git remote rename upstream selected && git remote rename selected upstream
$ git remote -v && git branch -r --list 'upstream/*'
origin	/home/ada/server/ada-atlas.git (fetch)
origin	/home/ada/server/ada-atlas.git (push)
upstream	/home/ada/server/atlas.git (fetch)
upstream	/home/ada/server/atlas.git (push)
  upstream/HEAD -> upstream/main
  upstream/deserts
  upstream/main
  upstream/rivers
```

The leftover ref from the section above makes a later rename to that name fail,
and fail after it has started. The configuration section was already renamed to
`selected`, but the refspec still stores into `upstream/`, the branches are
still `upstream/...`, and the remote now called `selected` fetches into another
remote's names.

The repair is two commands. `git symbolic-ref --delete` removes the leftover
ref, and `git config rename-section` puts the configuration section back under
its old name (Chapter 62). The rename then works; here it is done and undone,
so the remote keeps the name the rest of the chapter uses.

> **Careful.** `git config rename-section` renames the configuration only. It
> does not move remote-tracking branches or change the settings of branches that
> track the remote, which is why it is the right tool for putting a half-done
> rename back, and the wrong tool for renaming a remote.

> **Since Git 2.46.** `git config rename-section`. On an older Git, write
> `git config --rename-section remote.selected remote.upstream`.

## The remote's default branch

```console
$ git branch -r --list 'origin/*'
  origin/HEAD -> origin/main
  origin/main
  origin/rivers
$ git log --oneline -1 origin
0fe19df Add Europe
$ git remote set-head origin rivers && git log --oneline -1 origin
255682e List rivers
```

`origin/HEAD` is a symbolic ref, a ref that names another ref instead of a
commit (Chapter 7). It records which branch the remote's own `HEAD` names, its
*default branch*: the one a clone checks out. Its use is as a shorthand: a bare
remote name used as a revision means `<name>/HEAD`, so `origin` means
`origin/main` here, as Git's documentation for `set-head` says.
`git remote set-head origin rivers` pointed it at another branch, and `origin`
followed.

Nothing on the server changed; `set-head` never asks the server to change its
default branch.

```console
$ git remote set-head origin -a
'origin/HEAD' has changed from 'rivers' and now points to 'main'
$ git remote set-head origin -a
'origin/HEAD' is unchanged and points to 'main'
$ git remote set-head origin --delete && git branch -r --list 'origin/*'
  origin/main
  origin/rivers
$ git log --oneline -1 origin
fatal: ambiguous argument 'origin': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git remote set-head origin --auto
'origin/HEAD' is now created and points to 'main'
```

`-a`, or `--auto`, asks the server which branch its `HEAD` names and sets
`origin/HEAD` to match, saying whether it changed, stayed, or was created. This
is the command to run when a server changes its default branch, for example from
`master` to `main`. `-d`, or `--delete`, removes `origin/HEAD`, and then
`origin` alone no longer means anything.

A clone sets `origin/HEAD` from the start. A fetch also creates `<name>/HEAD`
when it is missing, which is how `upstream/HEAD` appeared in
[Fetching straight away](#fetching-straight-away); whether a later fetch updates
it is the setting `remote.<name>.followRemoteHEAD`, covered in Chapter 41.

> **Since Git 2.48.** `git fetch` creates `<name>/HEAD` when it is missing. On an
> older Git a fetch does not, and `git remote set-head <name> -a` is the way to
> create it.

```console
$ git remote set-head origin lakes
error: Not a valid ref: refs/remotes/origin/lakes
$ git remote set-head origin
usage: git remote set-head <name> (-a | --auto | -d | --delete | <branch>)

    -a, --[no-]auto       set refs/remotes/<name>/HEAD according to remote
    -d, --[no-]delete     delete refs/remotes/<name>/HEAD

```

`set-head` can only point at a remote-tracking branch that exists in your
repository; a branch that is not on the server, or not fetched yet, is "not a
valid ref". It needs exactly one of `-a`, `-d` or a branch name.

## Choosing which branches to fetch

```console
$ git remote set-branches upstream main
$ git config get --all --show-names --regexp '^remote\.upstream\.fetch'
remote.upstream.fetch +refs/heads/main:refs/remotes/upstream/main
$ git remote set-branches --add upstream 'des*'
$ git config get --all --show-names --regexp '^remote\.upstream\.fetch'
remote.upstream.fetch +refs/heads/main:refs/remotes/upstream/main
remote.upstream.fetch +refs/heads/des*:refs/remotes/upstream/des*
$ git branch -r --list 'upstream/*'
  upstream/HEAD -> upstream/main
  upstream/deserts
  upstream/main
  upstream/rivers
$ git remote show upstream
* remote upstream
  Fetch URL: /home/ada/server/atlas.git
  Push  URL: /home/ada/server/atlas.git
  HEAD branch: main
  Remote branches:
    deserts tracked
    main    tracked
  Local ref configured for 'git push':
    main pushes to main (local out of date)
```

`set-branches` rewrites the fetch refspecs the way `-t` writes them when adding:
without `--add` it replaces the whole list, with `--add` it appends. A name may
contain `*`, quoted so the shell leaves it alone; `des*` matches `deserts` and
any branch added later whose name starts the same way.

It changes what future fetches copy and nothing else. `upstream/rivers` is still
in `git branch -r`, although `rivers` is no longer fetched: it simply stops
being updated. `git remote show` (explained in
[Inspecting a remote](#inspecting-a-remote)) lists only the branches the
refspecs cover. [Branches you stopped fetching](#branches-you-stopped-fetching)
shows how to delete the copies left behind.

### When set-branches does nothing

```console
$ git remote set-branches upstream
$ git config get --all --show-names --regexp '^remote\.upstream'
remote.upstream.url /home/ada/server/atlas.git
$ git remote set-branches upstream '*'; echo "exit $?"
exit 1
$ git config get --all --show-names --regexp '^remote\.upstream'
remote.upstream.url /home/ada/server/atlas.git
$ git remote set-branches --add upstream '*'
$ git config get --all --show-names --regexp '^remote\.upstream'
remote.upstream.url /home/ada/server/atlas.git
remote.upstream.fetch +refs/heads/*:refs/remotes/upstream/*
```

`set-branches` with no branch names removes every fetch refspec, and says
nothing. The remote then fetches no branches at all.

The trap is the next command. Git's source shows that `set-branches` without
`--add` first removes the existing fetch lines and stops if that fails, and with
no lines to remove it does fail: silently, with exit status 1, and the
configuration unchanged. `--add` skips that step, so it works. `'*'` restores
the usual refspec.

## URLs

### Reading a URL

```console
$ git remote get-url origin
/home/ada/server/ada-atlas.git
$ git remote get-url --push origin
/home/ada/server/ada-atlas.git
$ git remote get-url nosuch; echo "exit $?"
error: No such remote 'nosuch'
exit 2
```

`get-url` prints the URL a fetch would use, and with `--push` the one a push
would use. Unlike `git remote -v`, it prints just the URL, which is what a
script wants. [Rewriting URLs](#rewriting-urls) shows the one way the printed
URL can differ from the one in the configuration.

### Changing a URL

```console
$ git remote add publish /home/ada/server/copy.git
$ git remote set-url publish /home/ada/server/copy1.git
$ git remote -v | grep publish
publish	/home/ada/server/copy1.git (fetch)
publish	/home/ada/server/copy1.git (push)
$ git remote set-url publish /home/ada/server/copy2.git copy9
fatal: No such URL found: copy9
$ git remote set-url publish /home/ada/server/copy2.git 'copy[0-9]'
$ git remote get-url publish
/home/ada/server/copy2.git
$ git remote set-url publish /home/ada/server/copy1.git
```

`set-url <name> <newurl>` replaces the URL. Nothing else about the remote
changes: its remote-tracking branches, and the branches that track them, stay as
they are, which is exactly what you want when a server moves or when switching
between HTTPS and SSH addresses for the same repository (Chapter 40).

A third argument is a regular expression, and only a URL matching it is
replaced. With no match, Git refuses and changes nothing. That matters for a
remote with several URLs, below.

### A different URL for pushing

```console
$ git remote set-url --push publish /home/ada/server/copy2.git
$ git remote -v | grep publish
publish	/home/ada/server/copy1.git (fetch)
publish	/home/ada/server/copy2.git (push)
$ git config get --all --show-names --regexp '^remote\.publish\.'
remote.publish.url /home/ada/server/copy1.git
remote.publish.fetch +refs/heads/*:refs/remotes/publish/*
remote.publish.pushurl /home/ada/server/copy2.git
$ git remote set-url --delete --push publish copy2
$ git remote -v | grep publish
publish	/home/ada/server/copy1.git (fetch)
publish	/home/ada/server/copy1.git (push)
```

`--push` writes `remote.<name>.pushurl`. From then on pushes go there and
fetches still come from `url`. Deleting the push URL makes pushes use `url`
again.

Git's documentation adds a condition: the two URLs must lead to the same
repository, so that what you push is what you would see if you fetched straight
afterwards. They are for reaching one repository two ways, such as reading over
HTTPS and writing over SSH. To fetch from one repository and push to a
different one, such as a fork, use two remotes ([Common setups](#common-setups)).

### Several URLs

```console
$ git remote set-url --add publish /home/ada/server/copy2.git
$ git remote -v | grep publish
publish	/home/ada/server/copy1.git (fetch)
publish	/home/ada/server/copy1.git (push)
publish	/home/ada/server/copy2.git (push)
$ git remote get-url publish && git remote get-url --all publish
/home/ada/server/copy1.git
/home/ada/server/copy1.git
/home/ada/server/copy2.git
$ git push publish main
To /home/ada/server/copy1.git
 * [new branch]      main -> main
To /home/ada/server/copy2.git
 * [new branch]      main -> main
$ git -C /home/ada/server/copy1.git log --oneline -1 && git -C /home/ada/server/copy2.git log --oneline -1
0fe19df Add Europe
0fe19df Add Europe
```

`--add` gives the remote a second `url`. A fetch uses only the first; a push goes
to all of them, one after the other, which is the one way to keep two servers
updated with a single `git push`. `get-url` prints the first unless given
`--all`.

```console
$ git remote set-url --add --push publish /home/ada/server/backup.git
$ git remote -v | grep publish
publish	/home/ada/server/copy1.git (fetch)
publish	/home/ada/server/backup.git (push)
```

Adding one push URL changed where every push goes. Git's documentation says a
push goes to every `pushurl` if there is any, and to every `url` only if there
is none, so the moment `backup.git` was added, `copy1.git` and `copy2.git`
stopped receiving pushes. To push to several places while a push URL exists,
add each of them with `--add --push`.

| Settings present | A fetch uses | A push goes to |
|---|---|---|
| one `url` | it | it |
| several `url` | the first | all of them |
| `url` and one or more `pushurl` | the first `url` | every `pushurl`, and no `url` |

### Deleting URLs

```console
$ git remote set-url --delete publish copy1
$ git remote -v | grep publish
publish	/home/ada/server/copy2.git (fetch)
publish	/home/ada/server/backup.git (push)
$ git remote set-url --delete publish copy2
fatal: Will not delete all non-push URLs
$ git remote set-url --delete publish nothing-like-it
fatal: could not unset 'remote.publish.url'
$ git remote remove publish
```

`--delete` removes every URL matching a regular expression; `copy1` matched one,
and the second URL became the one fetches use. It refuses when the pattern would
delete every fetch URL, since a remote without one could not be used; remove the
remote instead. A pattern matching nothing does not say so: the message is
about the configuration setting Git failed to unset.

### Rewriting URLs

```console
$ git config set url./home/ada/server/.insteadOf team:
$ git remote add team team:atlas.git
$ git remote -v | grep team
team	/home/ada/server/atlas.git (fetch)
team	/home/ada/server/atlas.git (push)
$ git config get remote.team.url && git remote get-url team
team:atlas.git
/home/ada/server/atlas.git
$ git config set url./home/ada/server/backup/.pushInsteadOf team:
$ git remote -v | grep team
team	/home/ada/server/atlas.git (fetch)
team	/home/ada/server/backup/atlas.git (push)
```

`url.<base>.insteadOf` rewrites any URL that starts with the given text so it
starts with `<base>` instead. The remote's configuration still says
`team:atlas.git`; `git remote -v` and `get-url` print the URL Git will actually
use, after rewriting. `pushInsteadOf` does the same for pushes only.

Git's documentation says a rewrite applies in any context that takes a URL,
including a remote added later, and in the global configuration it applies to
every repository. That is the point of it: one line can switch every `https://`
address of a host to SSH. Chapter 40 shows that use, and when a rewrite is
ignored.

## Inspecting a remote

Since the clone, Ada's fork on the server gained a branch `lakes`, pushed from
another computer, and lost `rivers`, deleted there. Ada has a local `rivers`
branch, and one commit on `main` she has not pushed.

```console
$ git branch -vv
* main   1971ac4 [origin/main: ahead 1] Add Asia
  rivers 255682e [origin/rivers] List rivers
$ git remote show origin
* remote origin
  Fetch URL: /home/ada/server/ada-atlas.git
  Push  URL: /home/ada/server/ada-atlas.git
  HEAD branch: main
  Remote branches:
    lakes                      new (next fetch will store in remotes/origin)
    main                       tracked
    refs/remotes/origin/rivers stale (use 'git remote prune' to remove)
  Local branches configured for 'git pull':
    main   merges with remote main
    rivers merges with remote rivers
  Local ref configured for 'git push':
    main pushes to main (fast-forwardable)
```

`git remote show` contacts the server, compares what it has with your
repository and configuration, and describes the result:

| Line | Tells you |
|---|---|
| `Fetch URL`, `Push  URL` | the URLs, after rewriting; one `Push URL` line per push URL |
| `HEAD branch` | the server's default branch, asked for now |
| `Remote branches` | each branch on the server that the fetch refspecs cover, and stale copies of deleted ones |
| `Local branches configured for 'git pull'` | each local branch whose upstream is on this remote |
| `Local ref configured for 'git push'` | each local branch that has a branch of the same name on this remote, and how the two compare |

| Word after a remote branch | Means |
|---|---|
| `tracked` | on the server, and you have a remote-tracking branch for it |
| `new (next fetch will store in remotes/origin)` | on the server, and the refspec covers it, but it has not been fetched |
| `stale (use 'git remote prune' to remove)` | your remote-tracking branch for it exists, and the server no longer has the branch |
| `skipped` | on the server, and excluded by a negative refspec, below |

| Word after a push line | Means |
|---|---|
| `up to date` | both point at the same commit |
| `fast-forwardable` | yours is ahead; a push would add your commits |
| `local out of date` | the server's has commits yours lacks; a push would be rejected unless forced (Chapter 45) |
| `create` | the branch does not exist on the server yet |
| `delete` | a push refspec would delete the branch on the server |

The "Remote branches" list comes from the server, so it is current, and a stale
branch is listed under the full name of your copy, since the server no longer
has a name for it. A push line can say `fast-forwardable` only when your
repository has the server's commit; Git's source reports `local out of date`
whenever it does not.

```console
$ git remote show upstream
* remote upstream
  Fetch URL: /home/ada/server/atlas.git
  Push  URL: /home/ada/server/atlas.git
  HEAD branch: main
  Remote branches:
    deserts tracked
    main    tracked
    rivers  tracked
  Local refs configured for 'git push':
    main   pushes to main   (local out of date)
    rivers pushes to rivers (up to date)
```

Read the push lines with care. Ada never pushes to `upstream`, and a plain
`git push` would not go there, yet `show` lists two branches it would "push".
Git's source explains why: with no `remote.<name>.push` set, `show` pairs each
local branch with the remote branch of the same name, and ignores `push.default`
and `remote.pushDefault`. The lines answer "how does my branch compare with the
branch of the same name there?", not "what will `git push` do?".

```console
$ git config set --append remote.upstream.fetch '^refs/heads/rivers' && git remote show upstream | sed -n '/Remote branches/,/rivers/p'
  Remote branches:
    deserts tracked
    main    tracked
    rivers  skipped
```

A refspec starting with `^` is a *negative refspec*: it excludes the branches it
matches from the pattern before it (Chapter 44). A branch it excludes is listed
as `skipped`. `sed` prints only the branch lines, and the setting was removed
again afterwards.

### Without asking the server

```console
$ git remote show -n origin
* remote origin
  Fetch URL: /home/ada/server/ada-atlas.git
  Push  URL: /home/ada/server/ada-atlas.git
  HEAD branch: (not queried)
  Remote branches: (status not queried)
    main
    rivers
  Local branches configured for 'git pull':
    main   merges with remote main
    rivers merges with remote rivers
  Local ref configured for 'git push' (status not queried):
    (matching) pushes to (matching)
```

`-n` uses only what the repository already knows. The remote branches are your
remote-tracking branches, as of the last fetch, so `rivers` is listed and
`lakes` is not. There is no default branch and no comparison.

`(matching) pushes to (matching)` is a placeholder, not information. With no
`remote.<name>.push` configured and no server to compare with, Git's source
prints this phrase and nothing else; it says nothing about what `git push` will
do.

### The pull and push lines

```console
$ git config set branch.rivers.rebase true && git config set remote.origin.push refs/heads/main:refs/heads/published
$ git remote show origin | sed -n '/git pull/,$p'
  Local branches configured for 'git pull':
    main    merges with remote main
    rivers rebases onto remote rivers
  Local ref configured for 'git push':
    main pushes to published (create)
```

A branch set to pull with rebase (`branch.<name>.rebase`, Chapter 42) is shown
as `rebases onto`. A push refspec in `remote.<name>.push` (Chapter 44) replaces
the same-name pairing: `main` now pushes to `published`, which does not exist on
the server, so the push would create it. The misaligned `main` is Git's own
output: the column is sized for the longer word. `sed` only cuts the top of the
output.

### A remote that cannot be reached

```console
$ git remote add gone /home/ada/server/gone.git && git remote show gone
fatal: '/home/ada/server/gone.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
$ git remote show -n gone
* remote gone
  Fetch URL: /home/ada/server/gone.git
  Push  URL: /home/ada/server/gone.git
  HEAD branch: (not queried)
  Local ref configured for 'git push' (status not queried):
    (matching) pushes to (matching)
$ git remote show /home/ada/server/atlas.git
* remote /home/ada/server/atlas.git
  Fetch URL: /home/ada/server/atlas.git
  Push  URL: /home/ada/server/atlas.git
  HEAD branch: main
  Local refs configured for 'git push':
    main   pushes to main   (local out of date)
    rivers pushes to rivers (up to date)
```

Without `-n`, a server that cannot be reached is a fatal error and prints
nothing about the remote, so `-n` is how to read a remote's settings when the
network or the server is down.

`show` also accepts a URL in place of a name. With no configuration behind it
there are no branch lists, and the push lines use the same-name pairing.

## git ls-remote

```console
$ git ls-remote upstream
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	HEAD
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
48c23937c4a8f5fa2410f72898c66f48d9641167	refs/tags/v1.0
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/tags/v1.0^{}
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/tags/v1.1-rc
```

`git ls-remote` asks a server for its refs and prints them: the full hash, a
tab, the full ref name. It fetches nothing and changes nothing in your
repository, and it accepts a remote's name or a URL.

`HEAD` is the server's default branch, given by the commit it points at. A line
ending in `^{}` is a *peeled* tag: `v1.0` is an annotated tag, a tag object with
its own hash, `48c2393...`, and the `^{}` line gives the commit that tag object
points at, `0fe19df...` (Chapter 18). A lightweight tag such as `v1.1-rc` names
the commit directly and has no second line.

### Only branches or only tags

```console
$ git ls-remote --branches upstream
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
$ git ls-remote --tags upstream
48c23937c4a8f5fa2410f72898c66f48d9641167	refs/tags/v1.0
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/tags/v1.0^{}
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/tags/v1.1-rc
$ git ls-remote --tags --refs upstream
48c23937c4a8f5fa2410f72898c66f48d9641167	refs/tags/v1.0
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/tags/v1.1-rc
$ git ls-remote -b -t --refs upstream
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
48c23937c4a8f5fa2410f72898c66f48d9641167	refs/tags/v1.0
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/tags/v1.1-rc
```

`--branches` and `--tags` narrow the list, and together they give both. `--refs`
drops the peeled `^{}` lines and `HEAD`, leaving one line per real ref, which
is the form a script usually wants.

```console
$ git ls-remote --heads upstream
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
$ git ls-remote -h
usage: git ls-remote [--branches] [--tags] [--refs] [--upload-pack=<exec>]
                     [-q | --quiet] [--exit-code] [--get-url] [--sort=<key>]
                     [--symref] [<repository> [<patterns>...]]
...
```

`--heads` is the older name for `--branches` and still gives the same result.
Git's documentation calls it and `-h` deprecated synonyms that may be removed.
`-h` with nothing else on the command line prints help, as it does for every Git
command, so a script should spell out `--branches`.

> **Since Git 2.46.** `--branches` and `-b`. On an older Git, use `--heads`.

### Patterns

```console
$ git ls-remote upstream main
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
$ git ls-remote upstream 'v*'
48c23937c4a8f5fa2410f72898c66f48d9641167	refs/tags/v1.0
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/tags/v1.0^{}
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/tags/v1.1-rc
$ git ls-remote upstream ain
$ git ls-remote upstream heads/main rivers
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
```

Patterns after the remote match the end of a ref name, starting at a slash or
at the start of the name, as Git's documentation puts it. So `main` matches
`refs/heads/main`, `heads/main` matches it too, and `ain` matches nothing,
because no slash comes right before it. `*` and `?` work as glob characters;
quote them. Several patterns list everything any of them matches.

A pattern that matches nothing prints nothing and still exits 0, which is the
next section's subject.

### Symbolic refs

```console
$ git ls-remote --symref upstream HEAD
ref: refs/heads/main	HEAD
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	HEAD
```

Without `--symref`, `HEAD` is only a hash, and more than one branch may point at
the same commit. `--symref` adds a line naming the branch `HEAD` refers to,
which is the server's default branch by name. Git's documentation notes that the
server shows this only for `HEAD`.

### Exit status

```console
$ git ls-remote upstream nosuch; echo "exit $?"
exit 0
$ git ls-remote --exit-code upstream nosuch; echo "exit $?"
exit 2
$ git ls-remote --exit-code upstream main >/dev/null; echo "exit $?"
exit 0
```

```console
$ git ls-remote --exit-code /home/ada/server/gone.git; echo "exit $?"
fatal: '/home/ada/server/gone.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
exit 128
```

Plain `git ls-remote` exits 0 whenever it could talk to the server, whether or
not anything matched. `--exit-code` makes "nothing matched" exit 2, which lets
a script ask whether a branch exists on the server, and a server that cannot be
reached stays a separate case, 128.

### Sorting

```console
$ git ls-remote --tags --sort=-version:refname upstream
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/tags/v1.1-rc
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/tags/v1.0^{}
48c23937c4a8f5fa2410f72898c66f48d9641167	refs/tags/v1.0
$ git ls-remote --branches --sort=committerdate origin
fatal: missing object a9994e62e5e9eb80fb3dbdf7434a48e732602cc9 for refs/heads/lakes
$ git fetch -q origin && git ls-remote --branches --sort=committerdate origin
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/main
a9994e62e5e9eb80fb3dbdf7434a48e732602cc9	refs/heads/lakes
```

`--sort` takes the keys of `git for-each-ref`, with `-` in front to reverse.
`version:refname`, also written `v:refname`, compares the numbers inside names
as numbers; Chapter 22 shows the difference it makes.

A key that needs the commit itself, such as `committerdate`, can only work for
commits your repository has, and the server sends names and hashes, not
commits. `lakes` had not been fetched, so the sort failed with "missing object";
after `git fetch` (Chapter 41) it worked.

### Without a remote name

```console
$ git ls-remote --branches
From /home/ada/server/ada-atlas.git
a9994e62e5e9eb80fb3dbdf7434a48e732602cc9	refs/heads/lakes
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/main
$ git ls-remote --branches 2>/dev/null
a9994e62e5e9eb80fb3dbdf7434a48e732602cc9	refs/heads/lakes
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/main
$ git ls-remote -q --branches
a9994e62e5e9eb80fb3dbdf7434a48e732602cc9	refs/heads/lakes
0fe19df3c0584186fbd106d526ed04be3c0a1664	refs/heads/main
```

With no remote named, `git ls-remote` uses the current branch's remote, here
`origin` through `main`'s upstream. It then prints a `From` line naming the URL,
on standard error, so a pipe or a redirect does not see it. `-q` leaves it out.

When the current branch has no upstream, Git's source falls back on the only
remote if there is exactly one, and on `origin` otherwise. In the empty
repository from [Listing remotes](#listing-remotes), whose branch has no
upstream:

```console
$ git remote add team /home/ada/server/atlas.git && git ls-remote --branches
From /home/ada/server/atlas.git
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
$ git remote add second /home/ada/server/bob-atlas.git && git ls-remote --branches
fatal: No remote configured to list refs from.
```

One remote, `team`, was used although it is not called `origin`. With a second
one, Git looked for `origin`, found none, and gave up. `git fetch` with no
remote is resolved by the same code; `git push` first looks at
`branch.<name>.pushRemote` and `remote.pushDefault` (Chapter 43).

```console
$ git ls-remote --branches server/atlas.git
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
$ git ls-remote
fatal: No remote configured to list refs from.
```

Outside any repository, in `/home/ada`, a URL works: nothing about
`git ls-remote` needs a repository of your own. A remote name cannot, and with
no argument at all there is no remote to fall back on.

```console
$ git ls-remote --get-url
/home/ada/server/ada-atlas.git
$ git ls-remote --get-url upstream
/home/ada/server/atlas.git
$ git ls-remote --get-url nosuch
nosuch
```

`--get-url` prints the URL that would be used, after `insteadOf` rewriting, and
contacts nothing. Unlike `git remote get-url`, it does not complain about an
unknown name: it treats the name as a URL and prints it back.

### The program on the other end

```console
$ git ls-remote --upload-pack=git-upload-pack --branches upstream
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
$ git ls-remote -o region=eu --branches upstream
a6c5b74349923de1a8fb839a1406765f7f96b817	refs/heads/deserts
23547aebb11c3fdec5f84ce0ca4c7aadde592f4d	refs/heads/main
255682e22f27e9fc40bcd3a211d47da90d5f862a	refs/heads/rivers
```

Reading a remote means running a program on the server's side,
`git-upload-pack`, which Chapter 9 introduced for `git clone -u`.
`--upload-pack` names it, for a server where Git is installed somewhere the
login shell does not look; here it names the default, so the result is the same.
The setting `remote.<name>.uploadpack` does it permanently.

`-o`, or `--server-option`, sends a string to the server; Git's documentation
says it is sent only with protocol version 2 (Chapter 40) and that what it means
is up to the server. Git's own `git-upload-pack` accepted `region=eu` without
complaint, and the output is unchanged.

## Removing stale remote-tracking branches

```console
$ git remote prune --dry-run origin
Pruning origin
URL: /home/ada/server/ada-atlas.git
 * [would prune] origin/rivers
$ git remote prune origin
Pruning origin
URL: /home/ada/server/ada-atlas.git
 * [pruned] origin/rivers
$ git remote prune origin
$ git branch -vv
* main   1971ac4 [origin/main: ahead 1] Add Asia
  rivers 255682e [origin/rivers: gone] List rivers
```

A remote-tracking branch is not deleted when its branch is deleted on the
server. Nothing tells your repository, so `origin/rivers` stayed, marked stale by
`git remote show`. `git remote prune` asks the server which branches still exist
and deletes the remote-tracking branches whose branch does not.

`--dry-run`, or `-n`, reports without deleting. Once there is nothing left to
prune, the command prints nothing at all.

Ada's local `rivers` branch was not touched, and neither was its commit. Its
upstream is now `gone` (Chapter 23), which is the usual state of a branch after
the pull request it belonged to was merged and deleted on the server. Delete the
local branch when you no longer need it.

Git's documentation calls `git remote prune <name>` the same as
`git fetch --prune <name>`, except that nothing new is fetched. Setting
`fetch.prune` makes every fetch prune (Chapter 41), and then this command is
rarely needed.

### Branches you stopped fetching

```console
$ git remote set-branches upstream main
$ git remote prune -n upstream
$ git branch -r --list 'upstream/*'
  upstream/HEAD -> upstream/main
  upstream/deserts
  upstream/main
  upstream/rivers
$ git branch -d -r upstream/deserts
Deleted remote-tracking branch upstream/deserts (was a6c5b74).
$ git remote set-branches upstream '*'
```

`prune` deletes a copy only when the branch is gone from the server. `deserts`
and `rivers` still exist there; they are only outside the refspec now, so prune
leaves them, and they stay frozen at their last fetched position. Delete such
copies by hand with `git branch -d -r` (Chapter 23). The refspec is then
restored for the rest of the chapter.

## Fetching from several remotes

Meanwhile Bob pushed a commit to the team's `main` and deleted `rivers` from the
team's server.

```console
$ git remote update
Fetching origin
Fetching upstream
From /home/ada/server/atlas
 * [new branch]      deserts    -> upstream/deserts
   23547ae..0d00631  main       -> upstream/main
$ git remote -v update
Fetching origin
From /home/ada/server/ada-atlas
 = [up to date]      main       -> origin/main
 = [up to date]      lakes      -> origin/lakes
Fetching upstream
From /home/ada/server/atlas
 = [up to date]      deserts    -> upstream/deserts
 = [up to date]      main       -> upstream/main
$ git remote update --prune
Fetching origin
Fetching upstream
From /home/ada/server/atlas
 - [deleted]         (none)     -> upstream/rivers
```

`git remote update` fetches from every remote in turn. `origin` had nothing new;
`upstream` had Bob's commit and `deserts`, whose copy Ada deleted above. With
`-v` before `update`, each fetch also lists the branches that did not change.
With `--prune`, each fetch also deletes stale copies, here `upstream/rivers`,
which survived the first two commands because an ordinary fetch never deletes
anything (Chapter 41).

```console
$ git config set remotes.team 'upstream' && git remote update team
Fetching upstream
$ git config set remote.upstream.skipFetchAll true && git remote -v update
From /home/ada/server/ada-atlas
 = [up to date]      main       -> origin/main
 = [up to date]      lakes      -> origin/lakes
$ git config set remotes.default 'origin upstream' && git remote update
Fetching origin
Fetching upstream
$ git remote update nosuch
fatal: no such remote or remote group: nosuch
```

A *group* is a setting, `remotes.<group>`, listing remote names separated by
spaces, and `git remote update <group>` fetches those. Remote names can be given
directly too.

With no argument, Git's documentation gives the order: the group
`remotes.default` if it is set, and otherwise every remote whose
`remote.<name>.skipFetchAll` is not true. So after `skipFetchAll`, only `origin`
was fetched; with only one remote there is no `Fetching` heading, and `-v` shows
it was `origin`. Then `remotes.default` named `upstream` explicitly, and that
wins over `skipFetchAll`.

Git's documentation calls `skipDefaultUpdate` a deprecated synonym of
`skipFetchAll`, with the later of the two winning if both are set.

## Remotes defined in files

```console
$ cat .git/remotes/old
URL: /home/ada/server/atlas.git
Pull: refs/heads/main:refs/remotes/old/main
$ cat .git/branches/older
/home/ada/server/atlas.git#deserts
$ git remote
origin
upstream
$ git fetch old
warning: reading remote from "remotes/old", which is nominated for removal.

If you still use the "remotes/" directory it is recommended to
migrate to config-based remotes:

	git remote rename old old

If you cannot, please let us know why you still need to use it by
sending an e-mail to <git@vger.kernel.org>.
From /home/ada/server/atlas
 * [new branch]      main       -> old/main
```

Before remotes lived in `.git/config`, Git read them from files, and it still
does. A file in `.git/remotes` has a `URL:` line and `Pull:` and `Push:`
refspecs. A file in `.git/branches` holds a URL and, after `#`, one branch,
`master` if none is given. Git's documentation describes both. Very old
repositories, and tools that were written long ago, may still have them.

Such a remote works for `git fetch` with a warning, but `git remote` does not
list it. The warning's own advice is the fix:

```console
$ git remote rename old old
warning: reading remote from "remotes/old", which is nominated for removal.

If you still use the "remotes/" directory it is recommended to
migrate to config-based remotes:

	git remote rename old old

If you cannot, please let us know why you still need to use it by
sending an e-mail to <git@vger.kernel.org>.
$ ls .git/remotes && git config get --all --show-names --regexp '^remote\.old\.'
remote.old.url /home/ada/server/atlas.git
remote.old.fetch refs/heads/main:refs/remotes/old/main
$ git remote rename older older 2>/dev/null && git config get --all --show-names --regexp '^remote\.older\.'
remote.older.url /home/ada/server/atlas.git
remote.older.push HEAD:refs/heads/deserts
remote.older.fetch refs/heads/deserts:refs/heads/older
```

Renaming a file-based remote to its own name converts it into configuration,
as Git's documentation says, and deletes the file: `.git/remotes` is empty
afterwards. For the second one, `2>/dev/null` hid the same warning.

Read the converted `older` carefully. A `.git/branches` file fetches into a
local *branch* named after the file, `refs/heads/older`, not into a
remote-tracking branch, and pushes `HEAD` to the named branch. That was the
design twenty years ago; keep it only if something depends on it.

> **Careful.** Git's `BreakingChanges` document lists support for both
> directories among the removals planned for Git 3.0. Convert them now.

## Common setups

| Situation | Remotes | Notes |
|---|---|---|
| You cloned a shared repository | `origin` | `git clone` added it (Chapter 9); `git fetch`, `git pull` and `git push` use it without being told |
| You contribute through your own fork | `origin` for your fork, `upstream` for the original | fetch from `upstream`, push to `origin`; `git config set remote.pushDefault origin` makes that the default (Chapter 43, Chapter 50) |
| You review a colleague's work | `origin`, plus one remote per person, such as `bob` | `git remote update bob`, then look at `bob/<branch>` or switch to it (Chapter 24) |
| You keep a backup on another server | a push mirror, such as `backup` | `git push backup` after each session ([Mirrors](#mirrors)) |
| The server moved | the same remote | `git remote set-url origin <new-url>` ([Changing a URL](#changing-a-url)) |
| You read over HTTPS and write over SSH | one remote with a push URL | [A different URL for pushing](#a-different-url-for-pushing), or `pushInsteadOf` (Chapter 40) |

`origin` is a convention, not a keyword. It is the name `git clone` gives the
remote it clones from (Chapter 9 shows how to choose another), and Git falls
back on it when a command needs a remote and none is configured for the branch
([Without a remote name](#without-a-remote-name)). `upstream` is a convention
too, widely used for the original project of a fork, and it has nothing to do
with Git's *upstream branch* except the word. Any name works; what matters is
that everyone on a team, and every script, agrees on what each name means.

## Exit status of git remote

```console
$ for sub in 'get-url nosuch' 'set-url nosuch /srv/x.git' 'set-branches nosuch main' 'rename nosuch x' 'remove nosuch' 'set-head nosuch -d' 'prune nosuch' 'show nosuch'; do git remote $sub >/dev/null 2>&1; echo "$? git remote $sub"; done
2 git remote get-url nosuch
2 git remote set-url nosuch /srv/x.git
2 git remote set-branches nosuch main
2 git remote rename nosuch x
2 git remote remove nosuch
0 git remote set-head nosuch -d
128 git remote prune nosuch
128 git remote show nosuch
```

| Status | From `git remote` means |
|---|---|
| `0` | it worked, or, for `set-head -d`, there was nothing to delete |
| `2` | no such remote, for the subcommands that read a remote's configuration |
| `3` | the name is already taken, for `add` and `rename` |
| `1`, `128`, other | any other error, such as an invalid name or a failed fetch |

Git's documentation promises 2 and 3 for subcommands "such as `add`, `rename`
and `remove`", and the loop shows which others follow it. Two do not. `prune`
and `show` accept a URL in place of a name, so an unknown name is tried as a URL
and fails like an unreachable server, with 128. `set-head -d` on a remote that
does not exist succeeds silently.

A script that wants to add a remote only if it is missing can test
`git remote get-url <name> >/dev/null 2>&1`, which exits 0 when it exists.

## remote and its neighbours

```console
$ git config set remote.bob.url /home/ada/server/bob-atlas.git && git config set remote.bob.fetch '+refs/heads/*:refs/remotes/bob/*'
$ git remote -v | grep bob
bob	/home/ada/server/bob-atlas.git (fetch)
bob	/home/ada/server/bob-atlas.git (push)
$ git remote update bob && git branch -r --list 'bob/*'
Fetching bob
From /home/ada/server/bob-atlas
 * [new branch]      deserts    -> bob/deserts
 * [new branch]      main       -> bob/main
 * [new branch]      mountains  -> bob/mountains
 * [new branch]      rivers     -> bob/rivers
  bob/HEAD -> bob/main
  bob/deserts
  bob/main
  bob/mountains
  bob/rivers
```

Two `git config set` commands wrote the same two settings that
`git remote add bob` wrote at the start of the chapter, and Git treats the
result as the same remote. For a plain `add`, and for `set-url`, which only
writes the `url` and `pushurl` settings shown in
[A different URL for pushing](#a-different-url-for-pushing), editing the
configuration by hand, or with `git config edit` (Chapter 62), comes to the same
thing. For `rename` and `remove` it does not: they also move or delete
remote-tracking branches and fix every branch that tracks the remote, which a
configuration edit leaves undone, as
[A rename that stops halfway](#a-rename-that-stops-halfway) showed.

| To | Use | Difference |
|---|---|---|
| see which remotes exist | `git remote -v` | reads configuration only |
| see a remote's settings and branches | `git remote show <name>` | asks the server, compares with your repository |
| see a server's refs and hashes | `git ls-remote <name>` | asks the server, prints raw refs, compares nothing |
| see your copies of a remote's branches | `git branch -r` (Chapter 23) | local only, as of the last fetch |
| copy commits from one remote | `git fetch <name>` (Chapter 41) | the everyday command |
| copy commits from several | `git remote update`, or `git fetch --all` (Chapter 41) | both honour `skipFetchAll`, as Git's documentation says |
| delete stale copies | `git remote prune <name>` | the same as `git fetch --prune <name>` without fetching, as Git's documentation says |
| start from a remote repository | `git clone` (Chapter 9) | makes the repository, adds `origin` and fetches, in one step |

## The settings

| Setting | Does |
|---|---|
| `remote.<name>.url` | The URL; several are allowed, and a push goes to all of them unless `pushurl` is set |
| `remote.<name>.pushurl` | Where pushes go instead of `url`; several are allowed |
| `remote.<name>.fetch` | A fetch refspec; one per line, as `add -t` and `set-branches` write them (Chapter 44) |
| `remote.<name>.push` | A push refspec used when `git push` is given none (Chapter 43, Chapter 44) |
| `remote.<name>.tagOpt` | `--no-tags` or `--tags`, as `add` writes them (Chapter 41) |
| `remote.<name>.mirror` | `true` makes every push a mirror push, as `add --mirror=push` writes it |
| `remote.<name>.skipFetchAll` | Leave this remote out of `git remote update` and `git fetch --all`; `skipDefaultUpdate` is the older name |
| `remote.<name>.prune`, `remote.<name>.pruneTags` | Prune on every fetch from this remote (Chapter 41) |
| `remote.<name>.followRemoteHEAD` | Whether a fetch creates or updates `<name>/HEAD` (Chapter 41) |
| `remote.<name>.uploadpack`, `remote.<name>.receivepack` | The program to run on the server when fetching, or pushing (Chapter 43) |
| `remote.<name>.serverOption` | Server options sent when none are given on the command line (Chapter 9) |
| `remote.<name>.proxy`, `remote.<name>.proxyAuthMethod` | An HTTP proxy for this remote only (Chapter 40) |
| `remote.<name>.vcs` | Talk to this remote through a helper program `git-remote-<vcs>` (Chapter 40) |
| `remote.<name>.promisor`, `remote.<name>.partialclonefilter` | Settings of a partial clone's remote (Chapter 46) |
| `remote.<name>.negotiationRestrict`, `remote.<name>.negotiationInclude` | Which commits a fetch tells this server it has (Chapter 41) |
| `remote.pushDefault` | The remote `git push` uses by default, for every branch (Chapter 43) |
| `remotes.<group>` | A group of remotes for `git remote update <group>` and `git fetch <group>` |
| `remotes.default` | The group `git remote update` fetches when given none |
| `url.<base>.insteadOf`, `url.<base>.pushInsteadOf` | Rewrite URLs that start with a given text (Chapter 40) |
| `branch.<name>.remote`, `branch.<name>.merge` | A branch's upstream; `rename` and `remove` keep them in step (Chapter 23) |
| `branch.<name>.pushRemote` | Where one branch pushes; `remove` deletes it with the remote (Chapter 43) |
| `clone.defaultRemoteName` | The name `git clone` gives its remote instead of `origin` (Chapter 9) |
| `checkout.defaultRemote` | Which remote wins when `git switch <name>` finds the branch on several (Chapter 24) |
