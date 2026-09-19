# Chapter 3. Installing and Configuring Git

## Installing

| Platform | Command | Notes |
|---|---|---|
| Debian, Ubuntu | `sudo apt install git` | Often already present |
| Fedora, RHEL | `sudo dnf install git` | |
| Arch | `sudo pacman -S git` | |
| Alpine | `sudo apk add git` | |
| macOS | `brew install git` | macOS ships an older Git through the developer tools; Homebrew gets you a current one |
| Windows | Download the installer from the Git for Windows project | Installs Git plus a Bash shell |
| Any Linux, no root | Build from source | Covered at the end of this chapter |

Distribution packages lag. If your Git is more than a year old, some of the
commands in this book will not exist yet. The version badges tell you which
ones.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[Installing](#installing)**

- [How do I install Git on my system?](#installing)

**[Checking what you have](#checking-what-you-have)**

- [Which version of Git do I have?](#checking-what-you-have)
- [How do I update Git on Windows, and is it safe for my repositories?](#checking-what-you-have)

**[The four configuration levels](#the-four-configuration-levels)**

- [Where does Git keep its settings, and which one wins when two disagree?](#the-four-configuration-levels)
- [I set a value and Git ignores it. Why?](#the-four-configuration-levels)
- [What is the difference between unsetting a value and setting it to nothing?](#the-four-configuration-levels)

**[Two ways to write every config command](#two-ways-to-write-every-config-command)**

- [Should I write `git config set user.email` or `git config user.email`?](#two-ways-to-write-every-config-command)

**[The one setting you must have](#the-one-setting-you-must-have)**

- [Git says "Author identity unknown". What do I do?](#the-one-setting-you-must-have)
- [What if Git guesses my email address?](#the-one-setting-you-must-have)

**[The default branch name](#the-default-branch-name)**

- [Why does `git init` print a long hint about `master`, and how do I stop it?](#the-default-branch-name)

**[The editor](#the-editor)**

- [Which editor does Git open, and how do I change it?](#the-editor)
- [My commit aborts as soon as the editor opens. Why?](#the-editor)

**[Windows specifics](#windows-specifics)**

- [What does the Git for Windows installer configure for me?](#windows-specifics)

**[Credentials](#credentials)**

- [How do I stop Git asking for my password every time?](#credentials)
- [Is `credential.helper store` safe?](#credentials)

**[A starting configuration](#a-starting-configuration)**

- [Which settings are worth setting on a new machine?](#a-starting-configuration)

**[Building from source](#building-from-source)**

- [How do I install a newer Git without root access?](#building-from-source)
- [My build of Git fails because Rust is missing. What now?](#building-from-source)

</details>

## Checking what you have

```console
$ git --version
git version 2.55.0.windows.5
$ git version
git version 2.55.0.windows.5
```

`git version` without the dashes does the same thing. Both forms have always
worked and neither is more correct.

On Windows, Git can update itself, with `git update-git-for-windows`. It asks
the network for the latest release, so the book shows no transcript of it.
According to its script, installed with Git for Windows as
`mingw64/bin/git-update-git-for-windows`, it prints the version you have, then
either `Up to date` or the version available, and in a terminal it then asks
before downloading anything:

```
Git for Windows <your version> (64-bit)
Update <latest version> is available
Download and install <release name> [N/y]?
```

Upgrading never touches your repositories. Git's on-disk format has not changed
in a way that requires migration, and nothing is rewritten when you install a
new version. Downgrading afterwards is safe too, with one exception: a
repository that uses a feature newer than the older Git, such as the SHA-256
object format or the reftable way of storing refs, records it as a repository
*extension*, and a Git that does not know the extension refuses to work in that
repository ("unknown repository extension found", in Git's `setup.c`).

## The four configuration levels

Almost every book says Git has three levels of configuration. It has four:

| Level | Where it lives | Flag | Applies to |
|---|---|---|---|
| System | `/etc/gitconfig`, or the install directory on Windows | `--system` | Every user on the machine |
| Global | `~/.gitconfig`, or `~/.config/git/config` | `--global` | You, in every repository |
| Local | `.git/config` inside a repository | `--local` | That one repository |
| Worktree | `.git/config.worktree` | `--worktree` | One worktree, see Chapter 56 |

The worktree level only exists when `extensions.worktreeConfig` is turned on,
so most of the time you really are dealing with three. It is mentioned here
because when it is active and you do not know it exists, the resulting
behaviour is baffling.

> **Worth knowing.** If both `~/.config/git/config` and `~/.gitconfig` exist,
> Git reads both, in that order. This surprises people who edit one file and
> see no change because the other one overrides it.

They are read in the order in the table, and the last value read wins. Here is
the whole rule in one transcript:

```console
$ git config set user.email "ada@widget.example"
$ git config list --show-scope
global	user.name=Ada Lovelace
global	user.email=ada@example.com
global	init.defaultbranch=main
local	core.repositoryformatversion=0
local	core.filemode=false
local	core.bare=false
local	core.logallrefupdates=true
local	core.symlinks=false
local	core.ignorecase=true
local	user.email=ada@widget.example
$ git config get user.email
ada@widget.example
$ git config get --global user.email
ada@example.com
$ git config unset user.email
$ git config get user.email
ada@example.com
```

There is no `system` line because the book's examples run with the system level
switched off (Chapter 2); on a real installation its lines come first, marked
`system`, and on Windows there are several ([Windows specifics](#windows-specifics)).

Two details in that transcript are worth pausing on.

The key came back as `init.defaultbranch`, lowercase, although it was written
as `init.defaultBranch`. Section and variable names are case-insensitive and
Git normalises them on output. The value is case-sensitive; the name is not.

And `git config unset` removed the local value, which let the global one
become visible again. Unsetting is not the same as setting to empty. Setting
`user.email` to an empty string gives you a commit with an empty email, which
is legal and useless.

> **Careful.** `git config set` writes to the local level by default, not the
> global one. Setting your name and email without `--global` configures them
> for the current repository only, which is a common reason for "I already set
> that" confusion in the next repository you clone.

## Two ways to write every config command

Git 2.46 deprecated the old flag-based interface and replaced it with
subcommands. Both still work, and the old one is still what most tutorials and
most of Git's own error messages show you.

> **Since Git 2.46.** The subcommand forms below. On an older Git you must use
> the classic column.

| Task | Modern | Classic |
|---|---|---|
| Read one value | `git config get user.email` | `git config --get user.email` |
| Read all values of a key | `git config get --all remote.origin.url` | `git config --get-all remote.origin.url` |
| Write a value | `git config set user.email a@b.c` | `git config user.email a@b.c` |
| Remove a value | `git config unset user.email` | `git config --unset user.email` |
| List everything | `git config list` | `git config --list` |
| Open the file in your editor | `git config edit` | `git config --edit` |
| Rename a section | `git config rename-section a b` | `git config --rename-section a b` |
| Delete a section | `git config remove-section a` | `git config --remove-section a` |

Chapter 62 covers `git config` in full. The level flags (`--global`,
`--local`, `--system`, `--worktree`) work the same way in both forms and go
after the subcommand:

```console
$ git config set --global user.name "Ada Lovelace"
```

This book uses the modern form, and shows the classic form wherever you are
likely to meet it.

## The one setting you must have

Git refuses to commit without knowing who you are. This is the failure, in
full, because you will see it on every fresh machine:

```console
$ git commit -m "First"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got '<user>@<hostname>.(none)')
```

Two things about that message.

It suggests the classic syntax, even on a Git where that syntax is deprecated.
Git's error messages have not all caught up with the 2.46 change, and this is
a good early lesson: the messages are written by people, at different times,
and they do not always agree with the documentation.

And the `(none)` in the guessed address is Git telling you it tried to invent
an email from your username and machine name and could not find a domain. If
your machine happens to have a domain name, Git will not refuse. It will commit
as `you@some-internal-hostname`, and print a notice, from Git's `sequencer.c`,
that begins "Your name and email address were configured automatically based
on your username and hostname. Please check that they are accurate." It is easy
to miss, and you will discover the address weeks later in a published history.
Set your identity explicitly.

```console
$ git config set --global user.name "Ada Lovelace"
$ git config set --global user.email "ada@example.com"
```

The name is free text and shows up in `git log`. The email is what matters,
because hosting services like GitHub match commits to accounts by email
address.

## The default branch name

A fresh Git still creates `master` and complains about it:

```console
$ git init demo1
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
Initialized empty Git repository in /home/ada/demo1/.git/
```

Set it once and the hint goes away:

```console
$ git config set --global init.defaultBranch main
$ git init demo2
Initialized empty Git repository in /home/ada/demo2/.git/
```

> **Worth knowing.** This setting only affects repositories you create. It has
> no effect on repositories you clone, which arrive with whatever branch name
> the origin uses. And it is not retroactive: an existing `master` stays
> `master` until you rename it, which Chapter 23 covers.

## The editor

Git opens an editor for commit messages, interactive rebases, and merge
conflict resolution. If you do not choose one, you get whatever `$VISUAL` or
`$EDITOR` says, and failing that, usually `vi`.

```console
$ git config set --global core.editor "nano"
```

| Editor | Value to use | Why the flags |
|---|---|---|
| nano | `nano` | |
| vim | `vim` | |
| VS Code | `code --wait` | Without `--wait`, Git thinks you finished instantly |
| Sublime Text | `subl -n -w` | Same reason |
| Notepad++ | `"C:/path/to/notepad++.exe" -multiInst -notabbar -nosession -noPlugin` | Forces a separate instance Git can wait on |

The `--wait` pattern is the thing to understand. Git launches the editor and
waits for the process to exit. A graphical editor that hands the file to an
already-running window exits immediately, so Git sees an empty or unchanged
message and aborts the commit. Every graphical editor needs a flag that makes
it block.

> **Careful.** If your editor is misconfigured, `git commit` fails with
> `error: there was a problem with the editor '<editor>'`, naming the editor,
> as Git's `editor.c` prints it. The fastest way to get unstuck
> is `git commit -m "message"`, which needs no editor at all.

## Windows specifics

The Git for Windows installer writes a system-level configuration that you
should know about, because it is not what Git does by default anywhere else:

| Setting | Installer value | What it does |
|---|---|---|
| `core.autocrlf` | `true` | Converts line endings on checkout and commit |
| `core.symlinks` | `false` | Symlinks become plain files unless Windows allows them |
| `core.fscache` | `true` | Caches filesystem calls, a large speedup |
| `credential.helper` | `manager` | Stores passwords in the Windows Credential Manager |
| `http.sslbackend` | `schannel` | Uses the Windows certificate store instead of a bundled one |
| `pull.rebase` | `false` | Makes `git pull` merge, see Chapter 42 |
| `init.defaultbranch` | `master` | The installer sets it explicitly |

It writes a few more, such as the filters for Git LFS (Chapter 59) and the
editor chosen during installation.

You can see yours at any time; the lines marked `system` are the installer's:

```sh
git config list --show-scope
```

`core.autocrlf=true` is the one that causes trouble. It means the bytes in your
working files are not the bytes in your commits, which is usually what you want
on Windows and occasionally a disaster. Chapter 66 is entirely about this and
explains when to turn it off.

## Credentials

Git needs a password or token every time it talks to an HTTPS remote, unless
something stores it. The `credential.helper` setting names the program that
does, and these are the values it usually takes:

| Value of `credential.helper` | Platform | Storage |
|---|---|---|
| `manager` | Windows | Windows Credential Manager, encrypted |
| `osxkeychain` | macOS | Keychain, encrypted |
| `libsecret` | Linux with a desktop | Secret Service, encrypted |
| `cache` | Any | Memory, forgotten after 15 minutes by default |
| `store` | Any | A plain text file in your home directory |

```console
$ git config set --global credential.helper manager
```

> **Careful.** `credential.helper store` writes your token to
> `~/.git-credentials` in plain text, readable by anything that can read your
> home directory. It is the right answer on a server you control and the wrong
> answer on a laptop. Chapter 40 covers SSH keys, which avoid the problem.

## A starting configuration

Everything here is optional except the first two lines. Each is explained in
the chapter listed.

```ini
[user]
	name = Ada Lovelace              # required
	email = ada@example.com          # required

[init]
	defaultBranch = main             # Chapter 3

[core]
	editor = nano                    # Chapter 3

[pull]
	ff = only                        # Chapter 42, refuses surprise merges

[push]
	autoSetupRemote = true           # Chapter 43, no more "--set-upstream"

[merge]
	conflictStyle = zdiff3           # Chapter 26, much better conflict markers

[rerere]
	enabled = true                   # Chapter 26, remembers conflict resolutions

[log]
	date = iso                       # Chapter 17, unambiguous dates

[diff]
	algorithm = histogram            # Chapter 13, better diffs

[fetch]
	prune = true                     # Chapter 41, cleans up deleted branches
```

Write it with `git config edit --global`, which opens the file in your editor,
or set the lines one at a time. Do not copy settings you do not understand
into your configuration and then wonder why Git behaves unlike the
documentation; each of these is justified in its own chapter.

> **Since Git 2.37.** `push.autoSetupRemote`.
> **Since Git 2.35.** `merge.conflictStyle = zdiff3`.

## Building from source

When your distribution is too old and you cannot install packages, building
Git is unusually painless:

```sh
tar xzf git-2.55.0.tar.gz
cd git-2.55.0
make prefix=$HOME/.local install
```

That installs into your home directory with no root access. Add
`$HOME/.local/bin` to your `PATH` and `git --version` reports the new build.

> **Since Git 2.55.** Both build systems enable Rust support by default, so a
> build host without Rust now fails by default. It can still be turned off:
> Git 2.55's `Makefile` says to define `NO_RUST`, as in
> `make NO_RUST=YesPlease prefix=$HOME/.local install`, and its Meson build has
> the option `rust`, turned off with `-Drust=disabled`. Git's `BreakingChanges`
> document gives `make WITH_RUST=YesPlease` and `meson configure -Drust=enabled`
> for turning it on explicitly, which 2.55 does anyway, and says that in Git
> 3.0 the options are removed and Rust becomes mandatory.
