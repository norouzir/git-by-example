# Chapter 9. init and clone

There are exactly two ways to end up with a repository. You make one, or you
copy one.

## git init

```console
$ git init project
Initialized empty Git repository in /home/ada/project/.git/
```

That created one directory, `.git`, and nothing else. Your project files are
untouched and there are no commits yet.

```console
$ find .git -maxdepth 1 | sort
.git
.git/HEAD
.git/config
.git/description
.git/hooks
.git/info
.git/objects
.git/refs
```

| Entry | Holds |
|---|---|
| `HEAD` | Which branch you are on (Chapter 7) |
| `config` | This repository's configuration (Chapter 62) |
| `description` | A one-line name, used only by the old `gitweb` viewer |
| `hooks/` | Scripts Git runs at certain moments (Chapter 67) |
| `info/` | Repository-local settings, including `info/exclude` (Chapter 16) |
| `objects/` | Every blob, tree, commit and tag (Chapter 71) |
| `refs/` | Branches and tags (Chapter 7) |

The only actual files at the start are three of those plus a pile of sample
hooks, all of them inert because their names end in `.sample`:

```console
$ find .git -type f | sort
.git/HEAD
.git/config
.git/description
.git/hooks/applypatch-msg.sample
.git/hooks/commit-msg.sample
.git/hooks/fsmonitor-watchman.sample
.git/hooks/post-update.sample
.git/hooks/pre-applypatch.sample
.git/hooks/pre-commit.sample
.git/hooks/pre-merge-commit.sample
.git/hooks/pre-push.sample
.git/hooks/pre-rebase.sample
.git/hooks/pre-receive.sample
.git/hooks/prepare-commit-msg.sample
.git/hooks/push-to-checkout.sample
.git/hooks/sendemail-validate.sample
.git/hooks/update.sample
.git/info/exclude
```

There is no `refs/heads/main` yet, because a branch is a file containing a
commit hash and there is no commit to name. `HEAD` points at a branch that does
not exist, which is what "unborn branch" means:

```console
$ cat .git/HEAD
ref: refs/heads/main
```

```console
$ cat .git/config
[core]
	repositoryformatversion = 0
	filemode = false
	bare = false
	logallrefupdates = true
	symlinks = false
	ignorecase = true
```

> **Windows.** Three of those lines are the platform talking. On Linux and
> macOS you will see `filemode = true`, no `symlinks` line, and `ignorecase`
> either absent or `true` on macOS. `filemode = false` means Git will not
> notice a change to the executable bit, because Windows does not have one.
> `ignorecase = true` is the one that causes real trouble, and Chapter 15
> covers renaming a file to a different case.

## init is safe to run twice

```console
$ git init
Reinitialized existing Git repository in /home/ada/project/.git/
$ git init
Reinitialized existing Git repository in /home/ada/project/.git/
```

"Reinitialized" sounds alarming and is not. It re-creates anything missing and
leaves everything else alone. Your commits, branches, config and files all
survive:

```console
$ git init
Reinitialized existing Git repository in /home/ada/project/.git/
$ cat keep.txt
still here
$ git status --short
?? keep.txt
```

> **Worth knowing.** The main real use for re-running `init` is to apply a
> changed template or to restore the sample hooks after deleting them. It is
> not a repair tool. For a damaged repository, Chapter 81 is the chapter you
> want.

## The options worth knowing

| Option | Does |
|---|---|
| `-b <name>`, `--initial-branch=<name>` | Name the first branch |
| `--bare` | No working tree; the repository contents sit at the top level |
| `-q`, `--quiet` | Print nothing on success |
| `--template=<dir>` | Copy `<dir>` instead of the default hooks and `info` |
| `--separate-git-dir=<dir>` | Put the repository elsewhere, leaving a `.git` file that points to it |
| `--object-format=<sha1\|sha256>` | Choose the hash algorithm (Chapter 71) |
| `--ref-format=<files\|reftable>` | Choose the ref storage format (Chapter 7) |
| `--shared[=<perms>]` | Set group permissions, for a repository several users push to |

```console
$ git init -b trunk other
Initialized empty Git repository in /home/ada/other/.git/
$ cat other/.git/HEAD
ref: refs/heads/trunk
```

`-b` beats the `init.defaultBranch` setting, and both beat the built-in default
of `master`. Chapter 3 covers setting it globally so you stop seeing the hint.

## Bare repositories

A bare repository is one with no working tree. It is what a server hosts,
because nobody edits files on the server.

```console
$ git init --bare server.git
Initialized empty Git repository in /home/ada/server.git/
$ ls server.git
HEAD
config
description
hooks
info
objects
refs
```

Those are the same entries as before, except they are at the top level instead
of inside a `.git` directory. That is the whole difference in layout.

```console
$ git -C server.git config core.bare
true
$ git -C server.git rev-parse --is-bare-repository
true
```

| | Ordinary | Bare |
|---|---|---|
| Working tree | Yes | No |
| Repository lives in | `.git/` | The directory itself |
| `core.bare` | `false` | `true` |
| Can you edit files in it | Yes | There are none |
| Can you push to it | Not safely by default | Yes, this is what it is for |
| Named by convention | `project` | `project.git` |

> **Worth knowing.** The `.git` suffix on a bare repository is a convention,
> not a rule. Git does not check it. It exists so that a human looking at a
> directory listing on a server can tell what they are looking at.

## git clone

```console
$ git clone server.git fresh
Cloning into 'fresh'...
done.
$ git log --oneline
facdfab Add util
3cc2dd4 Add main
6386c68 Add README
```

Clone did considerably more than copy files. It set up a remote:

```console
$ git remote -v
origin	/home/ada/server.git (fetch)
origin	/home/ada/server.git (push)
```

It created remote-tracking branches for everything the server had, while
creating only one local branch:

```console
$ git branch
* main
$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
  remotes/origin/topic
```

And it configured that one local branch to track its counterpart:

```console
$ git status -sb
## main...origin/main
$ git config get remote.origin.url
/home/ada/server.git
$ git config get branch.main.remote
origin
$ git config get branch.main.merge
refs/heads/main
```

Those last two settings are what make a bare `git pull` and a bare `git push`
know where to go. Chapters 41 and 43 use them constantly.

Note that `topic` exists as `origin/topic` but not as a local branch. Clone
creates exactly one local branch, the one the server's `HEAD` points at.
Chapter 41 covers turning the others into local branches when you need them.

## clone is four commands wearing a coat

Nothing above is magic. You can do it by hand:

```console
$ git init -q
$ git remote add origin /home/ada/server.git
$ git fetch -q origin
$ git switch -q main
$ git log --oneline
facdfab Add util
3cc2dd4 Add main
6386c68 Add README
$ git status -sb
## main...origin/main
```

Same result, including the tracking setup, because `git switch` to a name that
exists only as a remote-tracking branch creates a local branch that tracks it.

This is worth doing once. After it, "what did clone do to my repository" stops
being a mystery, and adding a second remote to an existing repository stops
feeling different from cloning.

## When clone refuses

```console
$ git clone server.git occupied
fatal: destination path 'occupied' already exists and is not an empty directory.
$ ls occupied
file.txt
```

Your files are untouched. Clone checks before it does anything.

An existing but *empty* directory is fine:

```console
$ git clone server.git empty-target
Cloning into 'empty-target'...
done.
```

And cloning something with no commits in it warns rather than fails:

```console
$ git clone nothing.git nothing-clone
Cloning into 'nothing-clone'...
warning: You appear to have cloned an empty repository.
done.
$ git -C nothing-clone status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

That is a normal state, not a broken clone. The remote is configured and the
first commit you push will populate it.

## Shallow clones, and a trap

`--depth` downloads only recent history, which matters when a repository has
twenty years of commits and you want to build it once.

There is a catch that wastes people's time, so here it is in full:

```console
$ git clone --depth 1 server.git shallow-broken
Cloning into 'shallow-broken'...
warning: --depth is ignored in local clones; use file:// instead.
done.
$ git -C shallow-broken log --oneline
facdfab Add util
3cc2dd4 Add main
6386c68 Add README
$ git -C shallow-broken rev-parse --is-shallow-repository
false
```

Three commits, not one, and `--is-shallow-repository` says `false`. The clone
worked and the option did nothing.

The reason is in Git's documentation of URL forms: a plain local path implies
`--local`, which copies or hardlinks the object database directly instead of
running the normal transfer protocol, and `--depth` is a feature of that
protocol. Writing the same path as a `file://` URL forces the real transport:

```console
$ git clone --depth 1 file:///home/ada/server.git shallow
Cloning into 'shallow'...
$ git -C shallow log --oneline
facdfab Add util
$ git -C shallow rev-parse --is-shallow-repository
true
$ cat shallow/.git/shallow
facdfabc98e3c7a9718ff4308b249b157bbd6545
```

One commit, and a file named `shallow` recording where history was cut off.
That file is how Git knows to stop walking and not to report a broken chain.

> **Careful.** The warning is easy to miss in a wall of clone output, and
> nothing later fails. You simply have a full clone when you asked for a small
> one. If you script a shallow clone, assert on
> `git rev-parse --is-shallow-repository` rather than trusting the flag.

Chapter 46 covers what is and is not possible inside a shallow clone, and how
to deepen one later.

## Single-branch clones

```console
$ git clone --single-branch --branch topic server.git just-topic
Cloning into 'just-topic'...
done.
$ git -C just-topic branch -a
* topic
  remotes/origin/topic
$ git -C just-topic config get --all remote.origin.fetch
+refs/heads/topic:refs/remotes/origin/topic
```

`origin/main` is not there, and the reason is that last line. Clone narrowed
the fetch refspec to one branch, so future fetches will also only ever see
`topic`. This surprises people later, when `git fetch` refuses to show them a
branch that definitely exists on the server. Chapter 44 explains refspecs and
how to widen one again.

`--depth` implies `--single-branch` unless you also pass `--no-single-branch`.

## Bare and mirror clones

Both produce a repository with no working tree. They differ in one config line:

```console
$ git clone --bare server.git copy-bare.git
Cloning into bare repository 'copy-bare.git'...
done.
$ git -C copy-bare.git config get --all remote.origin.fetch
$ git clone --mirror server.git copy-mirror.git
Cloning into bare repository 'copy-mirror.git'...
done.
$ git -C copy-mirror.git config get --all remote.origin.fetch
+refs/*:refs/*
```

`--bare` set no refspec at all. `--mirror` set one that maps *every* ref to the
same name locally, including remote-tracking refs and notes.

| | `--bare` | `--mirror` |
|---|---|---|
| Working tree | No | No |
| Fetch refspec | None | `+refs/*:refs/*` |
| `git fetch` updates refs | No | Yes, all of them, force-updating |
| Use it for | A one-off copy, or a server you will push to | A backup or migration that must stay identical |

Use `--mirror` when you are moving a repository between hosts and want
everything, and `--bare` when you want a server-shaped copy you will push to
normally.

## The clone options table

| Option | Does |
|---|---|
| `-b <name>`, `--branch <name>` | Check out this branch instead of the remote's default. Accepts a tag, which leaves you detached |
| `--single-branch` | Fetch only one branch and narrow the refspec |
| `--no-single-branch` | Undo the narrowing implied by `--depth` |
| `--depth <n>` | Keep only the last `<n>` commits. Needs `file://` for a local path |
| `--shallow-since=<date>` | Cut history by date rather than count |
| `--shallow-exclude=<ref>` | Cut history at a branch or tag |
| `--bare` | No working tree, no fetch refspec |
| `--mirror` | No working tree, mirror every ref |
| `-o <name>`, `--origin <name>` | Call the remote something other than `origin` |
| `-n`, `--no-checkout` | Set everything up but leave the working tree empty |
| `--recurse-submodules` | Clone submodules too (Chapter 57) |
| `--filter=<spec>` | Partial clone: skip downloading some objects until needed (Chapter 46) |
| `--separate-git-dir=<dir>` | Put the repository somewhere other than `.git` |
| `--sparse` | Start with a sparse checkout of the top level only (Chapter 60) |
| `-q`, `--quiet` | Print nothing on success |
| `--progress` | Force progress output even when not on a terminal |

## URL forms

These are the syntaxes Git documents, and you will meet most of them:

| Form | Example |
|---|---|
| SSH | `ssh://git@example.com:22/team/project.git` |
| SSH, scp-like | `git@example.com:team/project.git` |
| HTTPS | `https://example.com/team/project.git` |
| Git protocol | `git://example.com/team/project.git` |
| Local path | `/srv/git/project.git` |
| Local, as a URL | `file:///srv/git/project.git` |

Two details in that table cause real confusion.

The scp-like form is recognised only when there is no slash before the first
colon. So `git@host:path` is SSH, while `./weird:name` is a local directory
called `weird:name`. If you have a local path containing a colon, write it as
`./that/path` or as an absolute path.

And the last two rows are not interchangeable, as the shallow clone section
above showed. A plain path implies `--local`, which copies the object database
directly and is much faster. The `file://` form runs the full protocol.

> **Worth knowing.** `git clone`, `git fetch` and `git pull` also accept a
> bundle file where a URL goes. A bundle is an entire repository in one file
> you can carry on a USB stick, which is the most practical way to move a
> repository between machines with no network at all. Chapter 61 covers it.

> **Careful.** The `git://` protocol does no authentication and no encryption.
> Git's own documentation says to use it with caution on unsecured networks.
> Most hosts have switched it off. Prefer SSH or HTTPS, and Chapter 40 covers
> setting either up.
