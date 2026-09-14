# Chapter 9. init and clone

## What it is

There are exactly two ways to end up with a repository. You make one, or you
copy one.

`git init` makes one. It creates an empty repository: a `.git` directory with no
commits in it, in a directory that may already hold your files. It does not add
or change those files.

`git clone` copies one. It creates a new directory, copies every commit from an
existing repository into it, checks out one branch so you have files to work on,
and remembers where the copy came from so that you can fetch from it and push
to it later.

Both only ever write inside the directory they create or are pointed at.
Neither changes the repository it copies from.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is the difference between `git init` and `git clone`? When do I use which?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after `git init` and `git clone`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option of `git init`, and where each is explained?](#git-init-options)
- [Is there a list of every option of `git clone`, and where each is explained?](#git-clone-options)

**[git init](#git-init)**

- [What exactly does `git init` create? Is my project changed?](#git-init)
- [Why is there no branch file after `git init`, even though it says I'm on `main`?](#git-init)
- [My `.git/config` has lines I didn't write, like `ignorecase`. Where do they come from?](#git-init)
- [Can I run `git init` on a path that doesn't exist yet?](#where-the-repository-goes)
- [What happens if I run `git init` inside a folder that is already part of a repository?](#where-the-repository-goes)
- [I added a folder that has its own `.git` by mistake. How do I take it back out?](#where-the-repository-goes)

**[init is safe to run twice](#init-is-safe-to-run-twice)**

- [I ran `git init` again in a repository that already existed. Did I lose anything?](#init-is-safe-to-run-twice)
- [I ran `git init -b` with a new name in an existing repository and the branch didn't change. Why?](#reinitialising-does-not-rename-the-branch)

**[Choosing the first branch name](#choosing-the-first-branch-name)**

- [How do I make the first branch `main` instead of `master`?](#choosing-the-first-branch-name)

**[Bare repositories](#bare-repositories)**

- [What is a bare repository, and why would I want one?](#bare-repositories)
- [Why does `git status` fail in a repository on a server?](#bare-repositories)

**[Templates](#templates)**

- [Can every new repository start with my own hooks and settings already in place?](#templates)
- [I set `init.templateDir` to a folder that exists, but Git says "templates not found". Why?](#templates)

**[Keeping the repository somewhere else](#keeping-the-repository-somewhere-else)**

- [Can I keep the `.git` directory outside my project folder?](#keeping-the-repository-somewhere-else)
- [There's a `.git` *file* instead of a folder in my project. What is it?](#keeping-the-repository-somewhere-else)

**[Sharing a repository between users](#sharing-a-repository-between-users)**

- [Several people push to one repository on the same machine. How do I set up its permissions?](#sharing-a-repository-between-users)

**[Hash and ref formats](#hash-and-ref-formats)**

- [Can I create a repository that uses SHA-256? What else changes?](#hash-and-ref-formats)
- [What is reftable, and why is `refs/heads` a file in my repository?](#hash-and-ref-formats)

**[git clone](#git-clone)**

- [What does `git clone` set up besides copying the files?](#git-clone)
- [The original repository has several branches, but my clone shows only one. Where are the others?](#git-clone)
- [What name does the new folder get, and can I clone into the folder I'm already in?](#the-directory-clone-makes)

**[clone is four commands wearing a coat](#clone-is-four-commands-wearing-a-coat)**

- [Could I get the same result as `git clone` without using it?](#clone-is-four-commands-wearing-a-coat)

**[When clone refuses](#when-clone-refuses)**

- [Clone says the destination "already exists and is not an empty directory". Did it touch my files?](#when-clone-refuses)
- [I cloned a repository and got "You appear to have cloned an empty repository". Is the clone broken?](#when-clone-refuses)
- [What does "repository does not exist" mean when the path looks right?](#when-clone-refuses)

**[Choosing what to check out](#choosing-what-to-check-out)**

- [How do I clone and start on a branch other than the default?](#choosing-what-to-check-out)
- [I cloned with `-b` and a tag name and got a warning that it "is not a commit". Is something wrong?](#a-tag-instead-of-a-branch)
- [How do I clone just the history up to one release, without any branches?](#one-exact-commit)
- [I cloned with `--no-checkout` and `git status` says every file is deleted. What happened?](#nothing-at-all)

**[Naming the remote](#naming-the-remote)**

- [How do I call the remote something other than `origin`?](#naming-the-remote)

**[Setting configuration during the clone](#setting-configuration-during-the-clone)**

- [Can I set a setting for the new repository before its files are checked out?](#setting-configuration-during-the-clone)

**[Shallow clones, and a trap](#shallow-clones-and-a-trap)**

- [How do I download only the latest commit of a huge project?](#shallow-clones-and-a-trap)
- [I cloned with `--depth 1` but got the whole history. Why?](#shallow-clones-and-a-trap)
- [Can I cut history at a date or at a tag instead of a number of commits?](#cutting-history-by-date-or-by-tag)
- [How do I make sure I never accidentally clone from a shallow copy?](#refusing-a-shallow-source)

**[Single-branch clones](#single-branch-clones)**

- [How do I clone only one branch? Why doesn't `git fetch` show the other branches later?](#single-branch-clones)
- [My shallow clone has only one branch. How do I get the others without the full history?](#single-branch-clones)

**[Tags](#tags)**

- [How do I clone without any tags, and will later fetches bring them back?](#tags)

**[Partial clones](#partial-clones)**

- [Can I clone the history but skip downloading file contents until I need them?](#partial-clones)
- [I asked for a partial clone and got "filtering not recognized by server". What does that mean?](#partial-clones)

**[Sparse clones](#sparse-clones)**

- [How do I clone a big repository but only have the top-level files in my folder?](#sparse-clones)

**[Local clones and the object store](#local-clones-and-the-object-store)**

- [Cloning a repository on the same disk was instant. Did it really copy everything?](#hardlinks)
- [I want a true independent copy on the same disk, for a backup. How?](#hardlinks)
- [Why did `--local` say "is ignored"?](#packing-instead-of-copying)
- [Can a clone use the objects of another repository instead of storing its own?](#borrowing-objects-from-another-repository)
- [How do I make a borrowing clone stand on its own?](#stopping-the-borrowing)

**[Bare and mirror clones](#bare-and-mirror-clones)**

- [What is the difference between `--bare` and `--mirror`?](#bare-and-mirror-clones)

**[How much clone prints](#how-much-clone-prints)**

- [How do I make clone silent, or make it show progress?](#how-much-clone-prints)

**[The program on the other end](#the-program-on-the-other-end)**

- [The server keeps Git in an unusual place. How do I tell clone where it is?](#the-program-on-the-other-end)

**[URL forms](#url-forms)**

- [What address formats can I clone from?](#url-forms)
- [Is `/path/to/repo` the same as `file:///path/to/repo`?](#url-forms)

**[Copying the directory instead of cloning](#copying-the-directory-instead-of-cloning)**

- [Can I just copy the project folder instead of cloning it? What's the difference?](#copying-the-directory-instead-of-cloning)

**[init, clone, and their neighbours](#init-clone-and-their-neighbours)**

- [Should I use init and push, clone, a download of the code, or something else?](#init-clone-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings change what `git init` and `git clone` do by default?](#the-settings)

</details>

## Synopsis

These are the forms Git's own documentation lists:

```
git init [-q | --quiet] [--bare] [--template=<template-directory>]
         [--separate-git-dir <git-dir>] [--object-format=<format>]
         [--ref-format=<format>]
         [-b <branch-name> | --initial-branch=<branch-name>]
         [--shared[=<permissions>]] [<directory>]

git clone [--template=<template-directory>]
          [-l] [-s] [--no-hardlinks] [-q] [-n] [--bare] [--mirror]
          [-o <name>] [-b <name>] [-u <upload-pack>] [--reference <repository>]
          [--dissociate] [--separate-git-dir <git-dir>]
          [--depth <depth>] [--[no-]single-branch] [--[no-]tags]
          [--recurse-submodules[=<pathspec>]] [--[no-]shallow-submodules]
          [--[no-]remote-submodules] [--jobs <n>] [--sparse] [--[no-]reject-shallow]
          [--filter=<filter-spec> [--also-filter-submodules]] [--] <repository>
          [<directory>]
```

| Part | Means |
|---|---|
| `<directory>` for `init` | Where to create the repository. Created if it does not exist. Without it, the current directory |
| `<repository>` | What to clone: a path, a URL, or a bundle file. See [URL forms](#url-forms) |
| `<directory>` for `clone` | The new directory to clone into. Without it, a name is taken from `<repository>` |
| `--` | Everything after it is the repository and directory, even if it starts with a dash |

| Command | Does |
|---|---|
| `git init` | Turn the current directory into a repository |
| `git init <directory>` | Create `<directory>` if needed and make it a repository |
| `git init --bare <directory>` | Create a repository with no working tree, as a server would host |
| `git clone <repository>` | Copy `<repository>` into a new directory named after it |
| `git clone <repository> <directory>` | Copy it into `<directory>` |
| `git clone --bare <repository>` | Copy it as a bare repository |

## Options at a glance

Every option below is demonstrated in the section named in the last column.

### git init options

| Option | Does | Covered in |
|---|---|---|
| `-b <name>`, `--initial-branch=<name>` | Name the first branch | [Choosing the first branch name](#choosing-the-first-branch-name) |
| `--bare` | No working tree; the repository contents sit at the top level | [Bare repositories](#bare-repositories) |
| `-q`, `--quiet` | Print nothing on success | [Where the repository goes](#where-the-repository-goes) |
| `--template=<dir>` | Copy `<dir>` instead of the default hooks and `info` | [Templates](#templates) |
| `--separate-git-dir=<dir>` | Put the repository elsewhere, leaving a `.git` file that points to it | [Keeping the repository somewhere else](#keeping-the-repository-somewhere-else) |
| `--object-format=<sha1\|sha256>` | Choose the hash algorithm (Chapter 71) | [Hash and ref formats](#hash-and-ref-formats) |
| `--ref-format=<files\|reftable>` | Choose the ref storage format (Chapter 7) | [Hash and ref formats](#hash-and-ref-formats) |
| `--shared[=<perms>]` | Set group permissions, for a repository several users push to | [Sharing a repository between users](#sharing-a-repository-between-users) |

### git clone options

| Option | Does | Covered in |
|---|---|---|
| `-b <name>`, `--branch <name>` | Check out this branch instead of the remote's default. Accepts a tag, which leaves you detached | [Choosing what to check out](#choosing-what-to-check-out) |
| `--revision=<rev>` | Fetch only the history leading to one commit, make no branches, and detach | [Choosing what to check out](#choosing-what-to-check-out) |
| `-n`, `--no-checkout` | Set everything up but leave the working tree empty | [Choosing what to check out](#choosing-what-to-check-out) |
| `-o <name>`, `--origin <name>` | Call the remote something other than `origin` | [Naming the remote](#naming-the-remote) |
| `-c <key>=<value>`, `--config <key>=<value>` | Set a configuration value in the new repository before anything is fetched | [Setting configuration during the clone](#setting-configuration-during-the-clone) |
| `--depth <n>` | Keep only the last `<n>` commits. Needs `file://` for a local path | [Shallow clones, and a trap](#shallow-clones-and-a-trap) |
| `--shallow-since=<date>` | Cut history by date rather than count | [Shallow clones, and a trap](#shallow-clones-and-a-trap) |
| `--shallow-exclude=<ref>` | Cut history at a branch or tag | [Shallow clones, and a trap](#shallow-clones-and-a-trap) |
| `--reject-shallow`, `--no-reject-shallow` | Refuse, or allow, a source that is itself shallow | [Shallow clones, and a trap](#shallow-clones-and-a-trap) |
| `--single-branch` | Fetch only one branch, and only that branch in later fetches (Chapter 44) | [Single-branch clones](#single-branch-clones) |
| `--no-single-branch` | Undo the narrowing implied by `--depth` | [Single-branch clones](#single-branch-clones) |
| `--no-tags`, `--tags` | Leave tags out, now and in later fetches, or bring them back | [Tags](#tags) |
| `--filter=<spec>` | Partial clone: skip downloading some objects until needed (Chapter 46) | [Partial clones](#partial-clones) |
| `--sparse` | Start with a sparse checkout of the top level only (Chapter 60) | [Sparse clones](#sparse-clones) |
| `-l`, `--local`, `--no-local` | Copy a local repository's files directly, or force the network protocol | [Local clones and the object store](#local-clones-and-the-object-store) |
| `--no-hardlinks` | Copy object files instead of linking them | [Local clones and the object store](#local-clones-and-the-object-store) |
| `-s`, `--shared` | Borrow the source's objects instead of copying them | [Local clones and the object store](#local-clones-and-the-object-store) |
| `--reference=<repo>`, `--reference-if-able=<repo>` | Borrow objects from another local repository | [Local clones and the object store](#local-clones-and-the-object-store) |
| `--dissociate` | Copy what was borrowed, so the clone stands alone | [Local clones and the object store](#local-clones-and-the-object-store) |
| `--bare` | No working tree, no fetch refspec | [Bare and mirror clones](#bare-and-mirror-clones) |
| `--mirror` | No working tree, mirror every ref | [Bare and mirror clones](#bare-and-mirror-clones) |
| `--separate-git-dir=<dir>` | Put the repository somewhere other than `.git` | [Keeping the repository somewhere else](#keeping-the-repository-somewhere-else) |
| `--template=<dir>` | Use this template directory, as for `git init` | [Templates](#templates) |
| `--ref-format=<format>` | Choose the ref storage format, as for `git init` | [Hash and ref formats](#hash-and-ref-formats) |
| `-q`, `--quiet` | Print nothing on success | [How much clone prints](#how-much-clone-prints) |
| `-v`, `--verbose` | Print more, where there is more to say | [How much clone prints](#how-much-clone-prints) |
| `--progress` | Force progress output even when not on a terminal | [How much clone prints](#how-much-clone-prints) |
| `-u <program>`, `--upload-pack=<program>` | Run this program on the other end instead of `git-upload-pack` | [The program on the other end](#the-program-on-the-other-end) |
| `--server-option=<option>` | Pass a string to the server, whose meaning is up to the server | [The program on the other end](#the-program-on-the-other-end) |
| `--recurse-submodules` | Clone submodules too | Chapter 57 |
| `--shallow-submodules`, `--no-shallow-submodules` | Make cloned submodules shallow | Chapter 57 |
| `--remote-submodules`, `--no-remote-submodules` | Update submodules from their remote's branch | Chapter 57 |
| `-j <n>`, `--jobs=<n>` | Clone this many submodules at once | Chapter 57 |
| `--also-filter-submodules` | Apply `--filter` to submodules as well | Chapter 57 |
| `--filter=auto` | Let the server choose the partial clone filter | Chapter 46 |
| `--bundle-uri=<uri>` | Start from a bundle file before fetching | Chapter 61 |

<!-- no-example: --server-option
     Its effect depends entirely on the server; Git's documentation says the
     handling of options, including unknown ones, is server-specific. The
     sandbox server ignores them, so a clone with the option prints exactly what
     a clone without it prints, and an example would show nothing. -->

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

### Where the repository goes

```console
$ git init deep/er/still
Initialized empty Git repository in /home/ada/deep/er/still/.git/
$ ls deep/er
still
```

The directory did not exist, and neither did the two above it. `git init` made
all three.

`-q` makes it silent, which is the form used in scripts:

```console
$ git init -q quiet
```

Running `git init` inside a folder that is already part of a repository does
not join the two. It creates a second, separate repository, and the outer one
sees only an unfamiliar directory:

```console
$ cd fresh && git init inner && cd ..
Initialized empty Git repository in /home/ada/fresh/inner/.git/
$ git -C fresh status --short
?? inner/
$ git -C fresh add inner
error: 'inner/' does not have a commit checked out
error: unable to index file 'inner/'
fatal: adding files failed
```

The outer repository refuses to add it, because a directory with its own `.git`
is another repository and Git will not store it as ordinary files. Once the
inner repository has a commit, `git add` accepts it, with a warning:

```console
$ git -C fresh add inner
warning: adding embedded git repository: inner
hint: You've added another git repository inside your current repository.
hint: Clones of the outer repository will not contain the contents of
hint: the embedded repository and will not know how to obtain it.
hint: If you meant to add a submodule, use:
hint:
hint: 	git submodule add <url> inner
hint:
hint: If you added this path by mistake, you can remove it from the
hint: index with:
hint:
hint: 	git rm --cached inner
hint:
hint: See "git help submodule" for more information.
hint: Disable this message with "git config set advice.addEmbeddedRepo false"
$ git -C fresh ls-files -s
100644 dab306f45e6a154ab0fe50d67298f165cfc75392 0	README.md
160000 90f32ecff15e05d890759cf08baba0fcc83a295a 0	inner
100644 ae3eb5bbaa2743304e90f18f0d3e35ca0fadbe4b 0	keep.txt
100644 65489e7f1757a2e929bbdfef6111a3471dd4c8b3 0	src/main.py
100644 166d6ff5b0ee62a792a3508d8fb68699884d3ac5 0	src/util.py
```

None of the inner files were added. The index holds one entry for `inner`, with
the mode `160000` and the hash of the inner repository's current commit: a
pointer, not the contents. That is the start of a submodule, which Chapter 57
covers doing deliberately.

The hint's own advice for undoing it fails here:

```console
$ git -C fresh rm --cached inner
error: the following file has staged content different from both the
file and the HEAD:
    inner
(use -f to force removal)
$ git -C fresh restore --staged inner
$ git -C fresh status --short
?? inner/
```

`git restore --staged` (Chapter 14) takes the entry back out, and nothing inside
`inner` is touched. `git rm --cached -f inner` also works; Chapter 15 covers why
`rm` asks for `-f`. An accidental nested repository is almost always a mistake:
the lasting cure is to delete the inner `.git`, or to move the directory out.

`git -C <dir>` in these examples runs a command as if you were inside `<dir>`,
without changing directory. Chapter 62 covers it with the other options that go
before the command name.

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

### Reinitialising does not rename the branch

```console
$ git -C project init -b other
warning: re-init: ignored --initial-branch=other
Reinitialized existing Git repository in /home/ada/project/.git/
$ git -C project branch --show-current
main
```

`-b` only names the first branch of a new repository. On an existing one Git
says so and ignores it. Renaming a branch is `git branch -m`, in Chapter 23.

## Choosing the first branch name

```console
$ git init -b trunk other
Initialized empty Git repository in /home/ada/other/.git/
$ cat other/.git/HEAD
ref: refs/heads/trunk
```

`-b` beats the `init.defaultBranch` setting, and both beat the built-in default
of `master`. Chapter 3 covers setting it globally so you stop seeing the hint.

> **Since Git 2.28.** `-b`, `--initial-branch` and `init.defaultBranch`. On an
> older Git, create the repository and rename the branch before the first
> commit with `git symbolic-ref HEAD refs/heads/main`.

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

Every command that works on files fails, because there are no files:

```console
$ git -C server.git status
fatal: this operation must be run in a work tree
$ git -C server.git add README.md
fatal: this operation must be run in a work tree
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

## Templates

A template directory is copied into every new repository's `.git`. This one
holds a hook, an exclude file, a description, and a file whose name starts with
a dot:

```console
$ find tpl -type f | sort
tpl/.hidden
tpl/description
tpl/hooks/pre-commit
tpl/info/exclude
$ git init --template=tpl withtpl
Initialized empty Git repository in /home/ada/withtpl/.git/
$ find withtpl/.git -maxdepth 2 -type f | sort
withtpl/.git/HEAD
withtpl/.git/config
withtpl/.git/description
withtpl/.git/hooks/pre-commit
withtpl/.git/info/exclude
$ cat withtpl/.git/description
Our team project
```

Everything was copied except `.hidden`: Git's documentation says names starting
with a dot are skipped. The sample hooks did not appear either, because this
template replaced the default one rather than adding to it.

An empty template gives the barest possible repository:

```console
$ git init --template= notpl
Initialized empty Git repository in /home/ada/notpl/.git/
$ find notpl/.git | sort
notpl/.git
notpl/.git/HEAD
notpl/.git/config
notpl/.git/objects
notpl/.git/objects/info
notpl/.git/objects/pack
notpl/.git/refs
notpl/.git/refs/heads
notpl/.git/refs/tags
```

No `description`, no `hooks`, no `info`. Git works perfectly well without them.

To use a template every time, set `init.templateDir`, or the environment
variable `GIT_TEMPLATE_DIR`. There is a trap in how a relative path is read:

```console
$ git -c init.templateDir=tpl init -q fromconfig
warning: templates not found in tpl
$ ls fromconfig/.git
HEAD
config
objects
refs
$ git -c init.templateDir=../tpl init -q fromconfig2 && ls fromconfig2/.git/hooks
pre-commit
$ GIT_TEMPLATE_DIR=/home/ada/tpl git init -q fromenv && ls fromenv/.git/hooks
pre-commit
```

`--template=tpl` found the directory, and the setting with the same `tpl` did
not. With a directory name given, a relative path from the setting is looked up
from inside the new repository's directory, so `../tpl` worked, while
`--template` is read from where you typed it. The repository was still created,
with no hooks or `info` at all. Use an absolute path in the setting and the
question never arises.

`git -c <name>=<value>` sets a configuration value for one command only, without
changing any file (Chapter 62).

`git clone` accepts the same option:

```console
$ git clone -q --template=tpl server.git clonetpl && ls clonetpl/.git/hooks
pre-commit
```

## Keeping the repository somewhere else

`--separate-git-dir` puts the repository in one place and the working files in
another:

```console
$ git init --separate-git-dir=store sep
Initialized empty Git repository in /home/ada/store/
$ cat sep/.git
gitdir: /home/ada/store
$ ls store
HEAD
config
description
hooks
info
objects
refs
$ git -C sep rev-parse --git-dir
/home/ada/store
```

`sep/.git` is a one-line text file, not a directory. Git follows it to find the
repository, so every command run in `sep` works as usual. You will meet `.git`
files like this again in worktrees (Chapter 56) and submodules (Chapter 57).

Running it again on an existing repository moves the repository:

```console
$ cd sep && git init --separate-git-dir=../store2 && cd ..
Reinitialized existing Git repository in /home/ada/store2/
$ cat sep/.git
gitdir: /home/ada/store2
$ ls store
ls: cannot access 'store': No such file or directory
```

`store` is gone and its contents are in `store2`. `git clone` has the same option:

```console
$ git clone -q --separate-git-dir=clonestore server.git sepclone
$ cat sepclone/.git
gitdir: /home/ada/clonestore
```

> **Careful.** The `.git` file holds an absolute path. Move or rename the
> repository directory by hand and the working tree loses it, with every command
> failing as if there were no repository at all. Move it with
> `git init --separate-git-dir` instead, which rewrites the file.

## Sharing a repository between users

`--shared` is for a repository on one machine that several user accounts push
to. It records the permissions to use in the configuration:

```console
$ git init --shared=group shr
Initialized empty shared Git repository in /home/ada/shr/.git/
$ git -C shr config list --local
core.repositoryformatversion=0
core.filemode=false
core.bare=false
core.logallrefupdates=true
core.symlinks=false
core.ignorecase=true
core.sharedrepository=1
receive.denynonfastforwards=true
```

Two lines were added. `core.sharedrepository=1` makes Git create every file and
directory group-writable. `receive.denynonfastforwards=true` is set by default
in shared repositories, so nobody can force-push over someone else's work
(Chapter 43).

| Form | `core.sharedRepository` | Effect |
|---|---|---|
| `--shared=umask`, `--shared=false` | not set | Normal permissions, from your umask. The default |
| `--shared`, `--shared=group`, `--shared=true` | `1` | Group-writable |
| `--shared=all`, `--shared=world`, `--shared=everybody` | `2` | Group-writable and readable by everyone |
| `--shared=0640`, or any octal mode | that mode | Exactly those permissions, overriding your umask |

```console
$ git init --shared=umask shr-umask
Initialized empty Git repository in /home/ada/shr-umask/.git/
$ git -C shr-umask config get core.sharedRepository
$ git init --shared=all shr-all
Initialized empty shared Git repository in /home/ada/shr-all/.git/
$ git -C shr-all config get core.sharedRepository
2
$ git init --shared=0640 shr-0640
Initialized empty shared Git repository in /home/ada/shr-0640/.git/
$ git -C shr-0640 config get core.sharedRepository
0640
$ git init --shared shr-plain
Initialized empty shared Git repository in /home/ada/shr-plain/.git/
$ git -C shr-plain config get core.sharedRepository
1
$ git init --shared=wrong shr-wrong
fatal: bad boolean config value 'wrong' for 'arg'
```

Note the message changes to "empty shared Git repository" for every form that
actually shares, and `--shared` with no value means `group`.

> **Windows.** Windows has no Unix group permissions, so the setting is written
> but changes nothing you can see. It matters on Linux and macOS servers. On a
> hosted service such as GitHub or GitLab it does not matter at all, because the
> service controls access.

## Hash and ref formats

A repository can name its objects with SHA-256 instead of SHA-1 (Chapter 4):

```console
$ git init --object-format=sha256 h256
Initialized empty Git repository in /home/ada/h256/.git/
$ git rev-parse --show-object-format
sha256
$ git rev-parse HEAD
a3b8fe47efd1562e02952a38ddcad496f099449b08455e91dbd9b903ed2d509f
```

Sixty-four hex characters instead of forty. A SHA-256 repository cannot exchange
commits with a SHA-1 one; Chapter 71 covers the transition.

And refs can be stored in the reftable format instead of one file per ref
(Chapter 7):

```console
$ git init --ref-format=reftable rft
Initialized empty Git repository in /home/ada/rft/.git/
$ git rev-parse --show-ref-format
reftable
$ ls .git/refs
heads
$ cat .git/refs/heads
this repository uses the reftable format
$ git rev-parse main
9d3645b1c40a680fa8d6b3d29071c5513ea8a090
```

In a reftable repository `refs/heads` is a file holding a single sentence, left
there so that an old tool looking for branch files finds a clear message rather
than an empty directory. The branch is real, as `git rev-parse` shows; it is just
not stored where Chapter 7's `cat` commands would look.

`git clone` accepts `--ref-format` too, and both options reject a value they do
not know:

```console
$ git clone -q --ref-format=reftable server.git rclone && git -C rclone rev-parse --show-ref-format
reftable
$ git init --object-format=md5 badhash
fatal: unknown hash algorithm 'md5'
$ git init --ref-format=nope badref
fatal: unknown ref storage format 'nope'
```

> **Since Git 2.29.** `--object-format=sha256`, marked experimental at first.

> **Since Git 2.45.** `--ref-format=reftable`. The option itself appeared in
> 2.44, when `files` was the only value it accepted.

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

### The directory clone makes

Without a directory name, clone takes one from the source, dropping a trailing
`.git`, or a trailing `/.git`:

```console
$ git clone -q server.git
$ ls -d server
server
$ cd elsewhere && git clone -q ../project/.git && ls && cd ..
project
```

A directory of `.` clones into the current directory, which is allowed as long
as it is empty:

```console
$ cd inplace && git clone -q ../server.git . && ls && cd ..
README.md
keep.txt
src
```

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

A path that is not a repository fails before anything is created:

```console
$ git clone nothing-here.git whatever
fatal: repository 'nothing-here.git' does not exist
```

## Choosing what to check out

Clone normally checks out the branch the source's `HEAD` points at. `-b` picks
another branch, as the section [Single-branch clones](#single-branch-clones)
shows with `topic`. A name that does not exist fails:

```console
$ git clone -b nosuch server.git missing
Cloning into 'missing'...
fatal: Remote branch nosuch not found in upstream origin
```

### A tag instead of a branch

```console
$ git clone -b v1.0 server.git attag
Cloning into 'attag'...
done.
warning: refs/tags/v1.0 1a811f4dd71d2ed446a2a9e2ae2dda752d075f08 is not a commit!
Note: switching to '3cc2dd4921b9f59448898cbeea963e1b95ef872f'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

$ git -C attag status
Not currently on any branch.
nothing to commit, working tree clean
```

The warning looks worse than it is. `v1.0` is an annotated tag, and an annotated
tag is its own object pointing at a commit (Chapter 6). Git reports that the tag
object is not a commit, follows it to the commit, and checks that out. The
result is correct: you are detached at the commit `v1.0` names, which is
`3cc2dd4`, "Add main".

### One exact commit

`--revision` fetches only the history leading to one commit, and nothing else:

```console
$ git clone --revision=v1.0 server.git atrev
Cloning into 'atrev'...
done.
warning: refs/tags/v1.0 1a811f4dd71d2ed446a2a9e2ae2dda752d075f08 is not a commit!
Note: switching to '3cc2dd4921b9f59448898cbeea963e1b95ef872f'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

$ git -C atrev branch -a
* (no branch)
$ git -C atrev log --oneline
3cc2dd4 Add main
6386c68 Add README
$ git -C atrev config get --all remote.origin.fetch
$ git clone --revision=v1.0 -b main server.git both
Cloning into 'both'...
fatal: options '--revision' and '--branch' cannot be used together
```

It looks the same as `-b v1.0` at first. The difference is everything else:

| | `git clone -b v1.0` | `git clone --revision=v1.0` |
|---|---|---|
| Checks out | the commit the tag names, detached | the same |
| Fetches | every branch and tag | only the history of that commit |
| Remote-tracking branches | all of them | none |
| Fetch refspec | the usual one | none, so a later `git fetch` brings nothing |
| Accepts | a branch or a tag name | a ref name or a commit hash |

`--revision` is for building one exact version, typically in automation, where
anything else in the clone is waste. Git's documentation gives full names like
`refs/tags/v1.0` as the argument; the short name worked here too. It cannot be
combined with `-b`, or with `--mirror`.

> **Since Git 2.49.** `--revision`.

### Nothing at all

```console
$ git clone -n server.git nocheck
Cloning into 'nocheck'...
done.
$ ls -A nocheck
.git
$ git -C nocheck status --short
D  README.md
D  keep.txt
D  src/main.py
D  src/util.py
$ git -C nocheck restore --staged --worktree :/ && ls nocheck
README.md
keep.txt
src
```

`-n` fetched everything and checked out nothing. `git status` then reports every
file as a staged deletion, because `HEAD` names a commit full of files while the
index is empty, and an index without a file that `HEAD` has is exactly what a
staged deletion is (Chapter 5).

> **Careful.** Committing in that state records the deletion of every file. To
> get the files, restore from `HEAD` as shown, or run `git checkout HEAD -- .`
> in the classic form. `-n` is useful when you want to change a setting, such as
> a sparse checkout (Chapter 60), before any file is written.

## Naming the remote

```console
$ git clone -q -o upstream server.git named
$ git -C named remote
upstream
$ git -C named branch -vv
* main facdfab [upstream/main] Add util
$ git -c clone.defaultRemoteName=hub clone -q server.git named2
$ git -C named2 remote
hub
```

`-o` names this one clone's remote. `clone.defaultRemoteName` changes the name
for every clone. The command line wins when both are given.

`upstream` is the common choice when you clone your own fork, so that `origin`
can be added for the original project; Chapter 50 covers that arrangement.

## Setting configuration during the clone

```console
$ git clone -q -c core.autocrlf=input -c user.name='Grace Hopper' server.git cfg
$ git -C cfg config list --local
core.repositoryformatversion=0
core.filemode=false
core.bare=false
core.logallrefupdates=true
core.symlinks=false
core.ignorecase=true
core.autocrlf=input
user.name=Grace Hopper
remote.origin.url=/home/ada/server.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main
```

Both values went into the new repository's own configuration, above the lines
clone writes itself. They took effect before any file was checked out, which is
the point: a setting such as `core.autocrlf` changes how files are written, so
setting it afterwards would be too late for the first checkout (Chapter 66).

| | `git -c <key>=<value> clone ...` | `git clone -c <key>=<value> ...` |
|---|---|---|
| Written to | nothing; lasts for that one command | the new repository's `.git/config` |
| Applies to | the clone command only | the clone and everything afterwards |

Git's documentation notes two settings that do not take effect this way,
`remote.<name>.mirror` and `remote.<name>.tagOpt`. Use `--mirror` and
`--no-tags` for those.

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

### Cutting history by date or by tag

The server's history, with dates:

```console
$ git -C server.git log --format='%h %ad %s' --date=iso main
facdfab 2026-01-05 11:00:00 +0000 Add util
3cc2dd4 2026-01-05 10:00:00 +0000 Add main
6386c68 2026-01-05 09:00:00 +0000 Add README
$ git clone -q --shallow-since=2026-01-05T09:30:00Z file:///home/ada/server.git since
$ git -C since log --oneline
facdfab Add util
3cc2dd4 Add main
$ git clone -q --shallow-exclude=v1.0 file:///home/ada/server.git excl
$ git -C excl log --oneline
facdfab Add util
```

`--shallow-since` kept the commits made after half past nine. `--shallow-exclude`
left out everything reachable from the tag `v1.0`, which points at "Add main",
so only the commit after it remained.

| To keep | Use |
|---|---|
| The last `<n>` commits | `--depth=<n>` |
| Commits after a date | `--shallow-since=<date>` |
| Commits not already in a release | `--shallow-exclude=<tag or branch>`, repeatable |

All three need the `file://` form for a local path, for the same reason as
`--depth`.

### Refusing a shallow source

A shallow clone can itself be cloned, and the result is shallow too, which can
surprise whoever depends on it later:

```console
$ git clone -q shallow fromshallow2
$ git -C fromshallow2 rev-parse --is-shallow-repository
true
$ git clone --reject-shallow shallow fromshallow
Cloning into 'fromshallow'...
fatal: source repository is shallow, reject to clone.
$ git -c clone.rejectShallow=true clone shallow fromshallow3
Cloning into 'fromshallow3'...
fatal: source repository is shallow, reject to clone.
$ git -c clone.rejectShallow=true clone -q --no-reject-shallow shallow fromshallow4
$ git -C fromshallow4 rev-parse --is-shallow-repository
true
```

`--reject-shallow`, or `clone.rejectShallow` set to `true`, makes clone fail
instead. `--no-reject-shallow` overrides the setting for one clone.

> **Since Git 2.32.** `--reject-shallow` and `clone.rejectShallow`.

## Single-branch clones

```console
$ git clone --single-branch --branch topic server.git just-topic
Cloning into 'just-topic'...
done.
$ git -C just-topic branch -a
* topic
  remotes/origin/topic
$ git -C just-topic log --oneline
b6a6a48 Add extra on topic
facdfab Add util
3cc2dd4 Add main
6386c68 Add README
$ git -C just-topic config get --all remote.origin.fetch
+refs/heads/topic:refs/remotes/origin/topic
```

`origin/main` is not there, and the reason is that last line. Clone narrowed
the fetch refspec to one branch, so future fetches will also only ever see
`topic`. This surprises people later, when `git fetch` refuses to show them a
branch that definitely exists on the server. Chapter 44 explains refspecs and
how to widen one again.

Note that the history is complete: `topic` was made from `main`, so its history
includes `main`'s commits. A single-branch clone limits branches, not history.

`--depth` implies `--single-branch` unless you also pass `--no-single-branch`:

```console
$ git clone -q --depth 1 --no-single-branch file:///home/ada/server.git deepall
$ git -C deepall branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
  remotes/origin/topic
```

Every branch, each with only its latest commit.

## Tags

```console
$ git clone -q server.git withtags
$ git -C withtags tag
v1.0
$ git clone -q --no-tags server.git notags
$ git -C notags tag
$ git -C notags config get remote.origin.tagOpt
--no-tags
$ git clone -q --no-tags --tags server.git bothtags
$ git -C bothtags tag
v1.0
```

Tags come along by default. `--no-tags` leaves them out and writes
`remote.origin.tagOpt`, so later fetches leave them out too; an explicit fetch of
a tag still works (Chapter 41). `--tags` exists only to cancel an earlier
`--no-tags`, and on the command line the later of the two wins.

> **Since Git 2.49.** `--tags`. `--no-tags` is much older.

## Partial clones

A partial clone fetches the whole history but skips some objects, fetching them
later only when a command needs them. `--filter=blob:none` skips every file's
content:

```console
$ git clone --filter=blob:none file:///home/ada/server.git part1
Cloning into 'part1'...
warning: filtering not recognized by server, ignoring
$ git -C server.git config set uploadpack.allowFilter true
$ git clone --filter=blob:none file:///home/ada/server.git part2
Cloning into 'part2'...
```

The first attempt fell back to an ordinary full clone, because the server has to
allow filtering and this one did not. The warning is the only sign. Hosting
services allow it; for your own server it is the `uploadpack.allowFilter`
setting shown.

```console
$ git -C part2 config list --local
core.repositoryformatversion=1
core.filemode=false
core.bare=false
core.logallrefupdates=true
core.symlinks=false
core.ignorecase=true
remote.origin.url=file:///home/ada/server.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
remote.origin.promisor=true
remote.origin.partialclonefilter=blob:none
branch.main.remote=origin
branch.main.merge=refs/heads/main
$ git -C part2 rev-list --objects --all --missing=print | grep '^?'
?0f2287157f7cb0dd40498c7a92f74b6975fa2d57
$ git -C part2 ls-tree -r origin/topic
100644 blob dab306f45e6a154ab0fe50d67298f165cfc75392	README.md
100644 blob ae3eb5bbaa2743304e90f18f0d3e35ca0fadbe4b	keep.txt
100644 blob 0f2287157f7cb0dd40498c7a92f74b6975fa2d57	src/extra.py
100644 blob 65489e7f1757a2e929bbdfef6111a3471dd4c8b3	src/main.py
100644 blob 166d6ff5b0ee62a792a3508d8fb68699884d3ac5	src/util.py
```

The remote is marked as a *promisor*, one that promises to supply missing
objects on demand. Exactly one object is missing, and `ls-tree` shows it is
`src/extra.py`, which exists only on `topic`. The other files were not skipped
after all: checking out `main` needed their contents, so Git fetched them during
the clone. Chapter 46 covers the other filters and how commands behave when an
object has to be fetched.

## Sparse clones

```console
$ git clone -q --sparse server.git sp
$ ls -A sp
.git
README.md
keep.txt
$ git -C sp ls-files
README.md
keep.txt
src/main.py
src/util.py
```

Only the files at the top level are in the working tree. The index still lists
`src/`, so Git knows the files exist and does not think they were deleted.
Chapter 60 covers growing the checkout to include the directories you want.

| | Partial clone, `--filter` | Sparse clone, `--sparse` |
|---|---|---|
| Limits | what is downloaded | what is written to your working tree |
| All history present | yes | yes |
| All file contents present | no, fetched when needed | yes |
| Saves | network and disk in `.git` | disk and time in the working tree |

The two combine, and for very large repositories they usually are combined.

> **Since Git 2.25.** `--sparse`.

## Local clones and the object store

When the source is a path on the same machine, clone does not transfer anything.
It copies the object files directly, and where it can, it does not even copy
them.

### Hardlinks

A *hardlink* is a second name for the same file on disk. `stat -c %h` prints how
many names a file has:

```console
$ git -C alone.git rev-parse main:README.md
dab306f45e6a154ab0fe50d67298f165cfc75392
$ stat -c %h alone.git/objects/da/b306f45e6a154ab0fe50d67298f165cfc75392
1
$ git clone -q alone.git hard
$ stat -c %h alone.git/objects/da/b306f45e6a154ab0fe50d67298f165cfc75392 hard/.git/objects/da/b306f45e6a154ab0fe50d67298f165cfc75392
2
2
$ git clone -q --no-hardlinks alone.git soft
$ stat -c %h alone.git/objects/da/b306f45e6a154ab0fe50d67298f165cfc75392 soft/.git/objects/da/b306f45e6a154ab0fe50d67298f165cfc75392
2
1
```

After the ordinary clone, the object file has two names, one in each repository,
and takes up disk space once. After `--no-hardlinks`, the clone has its own copy.

That is safe because objects are never modified (Chapter 6), so two repositories
sharing one file cannot interfere. The reason to avoid it is a backup: a copy on
the same disk that shares files with the original is not a separate copy if the
disk damages that file.

`stat -c %h` is the GNU form of the command, which Git Bash on Windows and most
Linux systems have; other systems spell it differently.

### Packing instead of copying

```console
$ git clone -q --local file:///home/ada/server.git withlocal
warning: --local is ignored
$ git -C withlocal count-objects -v
count: 0
size: 0
in-pack: 17
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
$ git clone -q --no-local server.git noloc
$ git -C noloc count-objects -v
count: 0
size: 0
in-pack: 17
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
```

`--local` is ignored for a URL, as the warning says; a URL always uses the
protocol. `--no-local` forces the protocol for a plain path. Either way the
objects arrive as one pack file (Chapter 72) instead of individual copied files.

| Source written as | Default behaviour | To get the other |
|---|---|---|
| a path, `server.git` | direct copy with hardlinks, `--local` | `--no-local`, or write it as `file://` |
| a URL, `file:///.../server.git` | the transfer protocol | not possible; `--local` is ignored |

Git's documentation lists two cases where the direct copy is refused. A source
whose `objects` directory is, or contains, a symbolic link makes the clone fail,
so that files outside the repository are never copied by accident. A source
owned by another user account needs `--no-local` for the clone to succeed. It
also warns that a direct copy taken while someone is writing to the source can
catch it half-written, just as `cp -r` would.

### Borrowing objects from another repository

`--shared` goes further than hardlinks: the clone keeps no objects of its own and
reads the source's:

```console
$ git clone -q --shared server.git borrowed
$ cat borrowed/.git/objects/info/alternates
/home/ada/server.git/objects
$ git -C borrowed count-objects -v
count: 0
size: 0
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
alternate: /home/ada/server.git/objects
$ git -C borrowed log --oneline
facdfab Add util
3cc2dd4 Add main
6386c68 Add README
```

Zero objects, and yet the whole history is there. `objects/info/alternates`
names another object directory to look in, and Git reads from it as if it were
its own.

`--reference` does the same for a repository that is not the source, which is
how a machine that already has a copy of a large project avoids downloading it
again:

```console
$ git clone -q --reference server.git file:///home/ada/server.git referenced
$ cat referenced/.git/objects/info/alternates
/home/ada/server.git/objects
$ git clone -q --reference nowhere.git file:///home/ada/server.git refnot
fatal: reference repository 'nowhere.git' is not a local repository.
$ git clone -q --reference-if-able nowhere.git file:///home/ada/server.git refable
info: Could not add alternate for 'nowhere.git': reference repository 'nowhere.git' is not a local repository.
$ git -C refable log --oneline -1
facdfab Add util
```

`--reference` to something that is not a repository fails. `--reference-if-able`
says so and clones normally, which suits a script run on machines where the
reference copy may or may not exist.

> **Careful.** Git's documentation calls borrowing a possibly dangerous
> operation. The clone depends on the source keeping every object it borrowed.
> If commits are deleted from the source and its objects are cleaned away, the
> borrowing clone loses objects it needs and becomes corrupt, with no warning
> when it happens. The cleaning is not something you have to run: ordinary
> commands such as `git commit` start it automatically now and then (Chapter
> 77). Only borrow from a repository that you control and that never discards
> history.

The same documentation adds two details about the borrowing clone itself.
`git gc` in it is safe and keeps it small. `git repack` without `--local` copies
the borrowed objects in and loses the saving, which is harmless but may not be
what you wanted.

### Stopping the borrowing

```console
$ git clone -q --reference server.git --dissociate file:///home/ada/server.git dissociated
$ ls dissociated/.git/objects/info
packs
$ git -C dissociated count-objects -v
count: 0
size: 0
in-pack: 17
packs: 1
size-pack: 2
prune-packable: 0
garbage: 0
size-garbage: 0
```

`--dissociate` borrows during the clone to save the download, then copies what it
borrowed and removes the `alternates` file. The result stands on its own. For a
clone that is already borrowing, Git's documentation gives `git repack -a` as
the way to copy everything in; Chapter 72 covers `repack`.

| Option | Objects stored in the clone | Depends on another repository |
|---|---|---|
| (path, default) | hardlinked | no |
| `--no-hardlinks` | copied | no |
| `--shared` | none | yes, the source |
| `--reference=<repo>` | only those `<repo>` lacks | yes, `<repo>` |
| `--reference=<repo> --dissociate` | all | no |

## Bare and mirror clones

Both produce a repository with no working tree. They differ in one config line:

```console
$ git clone --bare server.git copy-bare.git
Cloning into bare repository 'copy-bare.git'...
done.
$ ls copy-bare.git | head
HEAD
config
description
hooks
info
objects
packed-refs
refs
$ git -C copy-bare.git config get --all remote.origin.fetch
$ git clone --mirror server.git copy-mirror.git
Cloning into bare repository 'copy-mirror.git'...
done.
$ git -C copy-mirror.git config get --all remote.origin.fetch
+refs/*:refs/*
$ git -C copy-bare.git branch
* main
  topic
$ git -C copy-mirror.git branch
* main
  topic
```

`--bare` set no refspec at all. `--mirror` set one that maps *every* ref to the
same name locally, including remote-tracking refs and notes.

Both copied the source's branches as local branches, `main` and `topic`, rather
than as `origin/main` and `origin/topic`. A bare repository has no working tree
to check a branch out into, so remote-tracking branches would serve no purpose.

| | `--bare` | `--mirror` |
|---|---|---|
| Working tree | No | No |
| Fetch refspec | None | `+refs/*:refs/*` |
| `git fetch` updates refs | No | Yes, all of them, force-updating |
| Use it for | A one-off copy, or a server you will push to | A backup or migration that must stay identical |

Use `--mirror` when you are moving a repository between hosts and want
everything, and `--bare` when you want a server-shaped copy you will push to
normally.

## How much clone prints

```console
$ git clone server.git talk0
Cloning into 'talk0'...
done.
$ git clone -q server.git talk1
$ git clone -v server.git talk2
Cloning into 'talk2'...
done.
$ git clone --progress server.git talk3
Cloning into 'talk3'...
done.
$ git clone --progress file:///home/ada/server.git talk4 2>&1 | tr '\r' '\n' | grep 'done'
remote: Enumerating objects: 17, done.
remote: Counting objects: 100% (17/17), done.
remote: Compressing objects: 100% (11/11), done.
Receiving objects: 100% (17/17), done.
Resolving deltas: 100% (3/3), done.
```

For a local path, `-v` and `--progress` printed nothing extra, because a direct
copy has no progress to report. Through the protocol, `--progress` reports each
stage.

Progress normally appears only on a terminal, and it redraws one line again and
again using carriage returns. `--progress` forces it even when the output goes
to a file or a pipe; here `tr` turns each carriage return into a new line so the
stages can be read, and `grep` keeps only the final line of each.

| Option | Prints |
|---|---|
| (none) | `Cloning into`, warnings, errors; progress on a terminal |
| `-q` | warnings and errors only |
| `-v` | the same as none, plus extra detail where a transport has any |
| `--progress` | progress even when not on a terminal |

## The program on the other end

Cloning through the protocol runs a program on the other end, normally
`git-upload-pack`. On a server where Git is installed somewhere unusual, `-u`
names it:

```console
$ git clone -q -u git-upload-pack file:///home/ada/server.git up1 && ls up1
README.md
keep.txt
src
$ git clone -u no-such-program file:///home/ada/server.git up2
Cloning into 'up2'...
...
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

The omitted line is the other end's shell reporting that it cannot find the
program, and its wording depends on that system's shell. The `fatal` lines are
Git's own, and they are the same message you get for a wrong address or missing
permissions, so a wrong `-u` looks like a connection problem.

Git's documentation describes `-u` for cloning over SSH, which is where it is
needed in practice; the example shows it applies to `file://` too.

`--server-option` passes a string to the server in the same transfer, for a
server that has defined its own options. It is sent only over protocol version 2,
the string cannot contain a newline, and the option can be repeated. What it
does is up to the server. Without it, clone sends the values of
`remote.<name>.serverOption`.

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

## Copying the directory instead of cloning

A repository is a directory, so copying the directory copies the repository. It
is not the same as cloning. Here `work` has a remote, an ignored build file, a
file never added, and an email address set only in this repository:

```console
$ cp -r work copied
$ git clone -q work cloned
$ ls -A copied
.git
.gitignore
README.md
build
notes.txt
$ ls -A cloned
.git
.gitignore
README.md
$ git -C copied remote -v
origin	/home/ada/server.git (fetch)
origin	/home/ada/server.git (push)
$ git -C cloned remote -v
origin	/home/ada/work (fetch)
origin	/home/ada/work (push)
$ git -C copied config get user.email
me@work.example
$ git -C cloned config get user.email
$ git -C copied status --short
?? notes.txt
$ git -C cloned status --short
```

| | `cp -r` | `git clone` |
|---|---|---|
| Committed history | yes | yes |
| Uncommitted, untracked and ignored files | yes | no |
| `.git/config`, including remotes and your settings | copied as is | fresh; one remote, pointing at the source |
| Hooks, reflog, stash | copied | not copied |
| Result | a second copy of the same working state | a new repository that knows where it came from |

Copy when you want everything exactly as it is, such as moving your working copy
to another disk. Clone when you want a clean repository from what was
committed. Copying a repository while a Git command is running in it can capture
it half-written, so do it when nothing is running.

## init, clone, and their neighbours

| You have | You want | Use |
|---|---|---|
| Files, no repository | To start tracking them | `git init`, then `git add` and `git commit` |
| A repository somewhere | A working copy of it | `git clone` |
| A local repository | To publish it to a new, empty server repository | `git init --bare` on the server, then `git remote add` and `git push` (Chapter 43) |
| A repository | A second working tree for the same repository, sharing its objects | `git worktree add` (Chapter 56) |
| A repository | Only the files of one commit, with no history | `git archive` (Chapter 61), or a host's download button |
| A repository | To move it with no network | `git bundle` (Chapter 61) |

A host's "download ZIP" gives files without history and without `.git`. You
cannot commit, pull or push from it; `git clone` of the same address gives you
all of that.

## The settings

| Setting | Effect |
|---|---|
| `init.defaultBranch` | Name of the first branch in a new repository. Since Git 2.28 |
| `init.templateDir` | Template directory for `init` and `clone`. Use an absolute path |
| `init.defaultObjectFormat` | Default hash algorithm for new repositories. Since Git 2.47 |
| `init.defaultRefFormat` | Default ref storage format for new repositories. Since Git 2.47 |
| `clone.defaultRemoteName` | Name of the remote a clone creates, instead of `origin` |
| `clone.rejectShallow` | Refuse to clone a shallow repository. Since Git 2.32 |
| `clone.filterSubmodules` | Apply a partial clone filter to submodules too (Chapter 57). Since Git 2.36 |
| `core.sharedRepository` | Permissions for a shared repository, written by `--shared` |
| `receive.denyNonFastForwards` | Refuse force pushes; set in shared repositories |
| `uploadpack.allowFilter` | On a server, allow partial clones |
| `remote.<name>.promisor` | Marks the remote a partial clone fetches missing objects from |
| `remote.<name>.partialclonefilter` | The filter a partial clone was made with |
| `remote.<name>.tagOpt` | `--no-tags` to stop fetching tags; written by `clone --no-tags` |
| `remote.<name>.serverOption` | Server options sent when none are given with `--server-option` |

| Environment variable | Effect |
|---|---|
| `GIT_TEMPLATE_DIR` | Template directory, taking priority over `init.templateDir` |
| `GIT_DEFAULT_HASH` | Default hash algorithm for new repositories |
| `GIT_DEFAULT_REF_FORMAT` | Default ref storage format for new repositories |

Git's documentation gives the order for templates: `--template`, then
`GIT_TEMPLATE_DIR`, then `init.templateDir`, then the built-in directory.
