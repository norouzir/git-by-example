# Chapter 2. The Sandbox

## Why this chapter exists

Most books print fake hashes. They write `a1b2c3d` because the real hash would
be different on your machine anyway, so why bother.

This book prints real ones. Every hash you see was produced by running the
command, and if you ever get to a computer and run the same commands, you will
get the same hashes. That is a deliberate choice, and it costs something to
keep, so it is worth explaining how it works.

It matters because a reader with no computer has no way to check the book. The
only thing you can do is trust it. Reproducible hashes are the closest thing to
a receipt that the examples were not invented.

## Why hashes normally differ

A commit is a small text object, and Git names it by hashing its contents. You
can read the object directly:

```console
$ git cat-file -p HEAD
tree e22b5fff04de41c427ec4a451ddd9ebe19b7b5a0
author Ada Lovelace <ada@example.com> 1767603600 +0000
committer Ada Lovelace <ada@example.com> 1767603600 +0000

Add README
```

Look at what is inside: a tree, two names, two email addresses, two timestamps,
and the message. The hash covers all of it. So the same file contents committed
by a different person, or one second later, is a different commit:

```console
# committed at 09:00:00
54a8962392bac7c6f6733529e95abde1907d69a5

# identical content, committed at 09:00:01
30667b43bfd24ce31321e99278a7333900020541
```

Not similar. Completely different, because that is what a hash function does.

This is also the mechanism behind several things later in the book, including
why `git rebase` cannot preserve commit hashes and why `git commit --amend`
produces a new commit rather than editing the old one.

## The five things that are pinned

To make the hashes stable, five sources of variation are removed:

| Source | Normally | In the sandbox |
|---|---|---|
| Author and committer | Your name and email | `Ada Lovelace <ada@example.com>` |
| Time | Now | Starts 2026-01-05 09:00:00 +0000, advances one hour per commit |
| Your global config | Read from your home directory | Replaced by a fixed file |
| System config | Read from the install directory | Ignored completely |
| Line endings | `core.autocrlf` is on by default on Windows | Turned off, so blobs match everywhere |

Time is set explicitly rather than left to the clock. It starts on a Monday
morning and moves forward one hour per commit, which is why timestamps in the
examples look like a plausible working day.

## Ignoring your configuration

The third and fourth rows deserve a note, because the mechanism is useful on
its own. Git reads two environment variables:

| Variable | Effect |
|---|---|
| `GIT_CONFIG_GLOBAL` | Use this file instead of your personal config |
| `GIT_CONFIG_SYSTEM` | Use this file instead of the system-wide config |

Point either at `/dev/null` and that whole level of configuration disappears:

```console
$ GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git config list
```

> **Worth knowing.** This is the cleanest way to test whether your own
> configuration is causing a problem. Run the command with both variables
> pointed at `/dev/null`. If the problem goes away, it was your config, and
> Chapter 62 shows how to find which setting did it.

## The pinned configuration, in full

Only settings that affect reproducibility or how transcripts render are pinned.
Everything else is left at Git's own defaults, so the messages and warnings in
this book are the ones a stock installation actually prints:

```ini
[core]
	autocrlf = false
	pager = cat
[init]
	defaultBranch = main
[color]
	ui = false
[advice]
	detachedHead = true
```

The `init.defaultBranch` line is worth calling out. Git still creates `master`
by default and prints a long hint about it, which you will see in Chapter 3.
The sandbox sets `main` so that examples are not buried under that hint every
time, and because `main` is what you will meet in nearly every project today.

## Building an example repository

Examples are built by a small shell harness. The parts that matter:

```sh
export GIT_AUTHOR_NAME="Ada Lovelace"
export GIT_AUTHOR_EMAIL="ada@example.com"
export GIT_COMMITTER_NAME="Ada Lovelace"
export GIT_COMMITTER_EMAIL="ada@example.com"

SANDBOX_NOW=1767603600             # 2026-01-05 09:00:00 +0000

sb_settime() {
	export GIT_AUTHOR_DATE="@$SANDBOX_NOW +0000"
	export GIT_COMMITTER_DATE="@$SANDBOX_NOW +0000"
}

sb_tick() {                        # move the clock forward one hour
	SANDBOX_NOW=$((SANDBOX_NOW + 3600))
	sb_settime
}

sb_commit() {                      # stage everything, commit, advance time
	git add -A && git commit -q -m "$1" && sb_tick
}
```

The `@<seconds> +0000` form is Git's raw date format. It is exact and has no
time zone ambiguity, unlike anything human-readable. Chapter 17 covers the
other date formats Git accepts.

> **Careful.** `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` are separate
> variables, and setting only one is a classic mistake. A commit with a
> backdated author and a current committer looks fine in `git log` and wrong
> in `git log --pretty=fuller`. Chapter 12 covers the two dates in detail.

## Proof that it works

The self-test builds the same repository twice, in two different scratch
directories, and compares:

```console
===== RUN 1 =====
2a84279 Add the app
ea1027e Add README
2a8427922f3b70d0e0e13bdfaeea55fa21903d66
ea1027eb3df3a6d460c00309894b06bc73ace0c4

===== RUN 2 =====
2a84279 Add the app
ea1027e Add README
2a8427922f3b70d0e0e13bdfaeea55fa21903d66
ea1027eb3df3a6d460c00309894b06bc73ace0c4
```

Different directory, different moment in real time, identical result.

## Remotes without a network

Parts 6 and 7 are about remotes, which sounds like it needs a server. It does
not. A Git remote can be a plain directory, and a **bare repository** is
exactly the thing a server would host: a repository with no working files,
just the administrative contents at the top level.

```console
$ git init --bare origin.git
$ git remote add origin /home/ada/origin.git
$ git push -u origin main
To /home/ada/origin.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

From there it behaves like any remote you would clone from a server:

```console
$ git clone origin.git clone2
$ cd clone2
$ git log --oneline
54a8962 Add README
$ git remote -v
origin	/home/ada/origin.git (fetch)
origin	/home/ada/origin.git (push)
```

This covers almost everything in the remote chapters: pushing, fetching,
diverged branches, rejected pushes, force pushes, deleted branches, and every
error message they produce. The only things it cannot demonstrate are
authentication and the network protocols themselves, which Chapter 40 covers
separately.

> **Worth knowing.** This is genuinely useful outside the book. A bare
> repository on a USB stick or a shared folder is a complete Git server with
> no software to install, which is one way to collaborate with no internet at
> all. Chapter 61 covers the other way, `git bundle`.

## The one edit made to transcripts

Scratch directories have machine-specific names like `/tmp/tmp.K5yObdQyXZ`.
Showing those would be noise, so the sandbox root is rewritten to `/home/ada`
in captured output. The few messages that embed the machine's own user name or
hostname get the same treatment, and appear as `<user>` and `<hostname>`.

That is the only edit. No output in this book was retyped, shortened by hand,
or corrected after the fact. Where output was trimmed for length, the cut is
marked with `...` on its own line.

## Reproducing this yourself

If you do get to a computer, the harness and the script for every chapter are
in the book's repository, under `sandbox/`. Running a chapter's script rebuilds
that chapter's example repository from nothing:

```console
$ bash sandbox/scripts/ch12-commit.sh /tmp/playground
```

You do not need the repository to follow the book. Nothing in the text depends
on having run anything.
