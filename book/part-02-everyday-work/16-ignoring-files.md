# Chapter 16. Ignoring Files

## What it is

An *ignore rule* tells Git to leave an untracked file alone: not to list it as
untracked in `git status`, not to add it with `git add .`, and to delete it with
`git clean` only when asked to. Rules are patterns, one per line, in files named
`.gitignore` and in two personal locations.

Ignoring affects only files Git does not track. A file that is already tracked
stays tracked whatever the rules say (Chapter 8).

`git check-ignore` is the command that goes with it. Given a path, it says
whether the path is ignored and which rule decided.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does ignoring a file actually do? Does it delete anything?](#what-it-is)

**[Synopsis](#synopsis)**

- [What does a line in `.gitignore` look like, and what can I type after `git check-ignore`?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every `git check-ignore` option?](#options-at-a-glance)

**[The simplest rule](#the-simplest-rule)**

- [How do I make Git stop showing my log files?](#the-simplest-rule)
- [Should I commit the `.gitignore` file?](#the-simplest-rule)

**[Always ask, never guess](#always-ask-never-guess)**

- [How do I find out why a file is ignored?](#always-ask-never-guess)
- [My script stops when I run `git check-ignore`. Why?](#always-ask-never-guess)
- [Why does `check-ignore` say nothing about a file that matches a rule?](#checking-in-scripts-and-for-tracked-files)
- [How do I check many files at once from a script?](#checking-in-scripts-and-for-tracked-files)

**[Anchoring](#anchoring)**

- [How do I ignore `build` only at the top, not every folder called `build`?](#anchoring)
- [What does a leading `/` mean in a `.gitignore` inside a subfolder?](#anchoring)

**[The trailing slash](#the-trailing-slash)**

- [What is the difference between `cache` and `cache/`?](#the-trailing-slash)

**[Wildcards](#wildcards)**

- [Why doesn't `logs/*.log` match files in deeper folders?](#wildcards)
- [How do I match everything except some characters, or a range?](#wildcards)
- [On Windows, `*.TXT` ignores my `.txt` files. Why?](#wildcards)

**[Negation](#negation)**

- [How do I ignore a whole folder except one file?](#negation)

**[The negation trap](#the-negation-trap)**

- [I added `!docs/keep.txt` but the file is still ignored. Why?](#the-negation-trap)
- [How do I keep one file deep inside an ignored tree?](#the-negation-trap)

**[Order matters](#order-matters)**

- [Does the order of lines in `.gitignore` matter?](#order-matters)

**[Where rules can live](#where-rules-can-live)**

- [Where else can I put ignore rules, and which one wins?](#where-rules-can-live)
- [How do I ignore my editor's files in every repository?](#where-rules-can-live)

**[Comments, blank lines and escaping](#comments-blank-lines-and-escaping)**

- [How do I ignore a file whose name starts with `#` or `!`?](#comments-blank-lines-and-escaping)

**[Listing what is ignored](#listing-what-is-ignored)**

- [How do I see every file Git is ignoring?](#listing-what-is-ignored)
- [How do I list new files I've forgotten to add?](#listing-what-is-ignored)

**[Two things gitignore cannot do](#two-things-gitignore-cannot-do)**

- [I added a file to `.gitignore` but Git still tracks it. Why?](#two-things-gitignore-cannot-do)
- [How do I keep an empty folder in the repository?](#two-things-gitignore-cannot-do)

**[Forcing past a rule](#forcing-past-a-rule)**

- [How do I add one file that a rule ignores?](#forcing-past-a-rule)

**[Changes to a tracked file](#changes-to-a-tracked-file)**

- [How do I ignore my local changes to a file that is tracked, like a config file?](#changes-to-a-tracked-file)

**[A starting .gitignore](#a-starting-gitignore)**

- [What should go in a project's `.gitignore`?](#a-starting-gitignore)

**[The settings](#the-settings)**

- [Which settings affect ignoring?](#the-settings)

</details>

## Synopsis

A `.gitignore` file holds one pattern per line:

```
# a comment
*.log
/build/
!keep.log
```

```
git check-ignore [<options>] <pathname>...
git check-ignore [<options>] --stdin
```

| Part | Means |
|---|---|
| `<pathname>` | A path to check; it does not have to exist |
| `--stdin` | Read the paths from standard input, one per line |

| Line in a `.gitignore` | Means |
|---|---|
| `name` | Ignore anything called `name`, at any depth |
| `dir/` | Ignore directories called `dir` |
| `/name` | Only at the top of this `.gitignore`'s directory |
| `!pattern` | Stop ignoring what an earlier rule ignored |
| `# text` | A comment |

## Options at a glance

| Option | Does | Covered in |
|---|---|---|
| `-v`, `--verbose` | Print the rule that decided, with its file and line | [Always ask, never guess](#always-ask-never-guess) |
| `-n`, `--non-matching` | Also print paths no rule matched. Needs `-v` | [Always ask, never guess](#always-ask-never-guess) |
| `-q`, `--quiet` | Print nothing, only set the exit code. One path only | [Checking in scripts, and for tracked files](#checking-in-scripts-and-for-tracked-files) |
| `--stdin` | Read paths from standard input | [Checking in scripts, and for tracked files](#checking-in-scripts-and-for-tracked-files) |
| `-z` | Separate input and output with NUL bytes. Needs `--stdin` | [Checking in scripts, and for tracked files](#checking-in-scripts-and-for-tracked-files) |
| `--no-index` | Check tracked files too, ignoring the index | [Checking in scripts, and for tracked files](#checking-in-scripts-and-for-tracked-files) |
| `--index` | Undo an earlier `--no-index` | [Checking in scripts, and for tracked files](#checking-in-scripts-and-for-tracked-files) |

## The simplest rule

```console
$ git status --short
?? app.py
?? debug.log
$ git status --short
?? .gitignore
?? app.py
$ git status --short --ignored
?? .gitignore
?? app.py
!! debug.log
```

A `.gitignore` file containing `*.log` and the noise is gone. Note that
`.gitignore` itself shows up as untracked, because it is an ordinary file and
you are meant to commit it.

`--ignored` lists ignored files under `!!` (Chapter 10).

## Always ask, never guess

```console
$ git check-ignore -v debug.log
.gitignore:1:*.log	debug.log
$ git check-ignore -v app.py
$ git check-ignore -v --non-matching app.py
::	app.py
```

The output is `file:line:pattern<TAB>path`. That is the whole diagnostic tool
and it is the first thing to reach for whenever a file is ignored and should
not be, or the reverse.

| Behaviour | Meaning |
|---|---|
| Prints a rule | That rule decided it |
| Prints nothing, exits 1 | No rule matched, so the file is not ignored |
| Prints `::` with `--non-matching` | Confirms explicitly that nothing matched |
| Prints nothing for a tracked file | Ignore rules do not apply to tracked files (Chapter 8) |

> **Careful.** `check-ignore` exits 1 when nothing matches, which is an answer
> rather than an error. In a script with `set -e` that will terminate you.

### Checking in scripts, and for tracked files

```console
$ git check-ignore debug.log app.py build/out.o; echo "exit $?"
debug.log
build/out.o
exit 0
$ git check-ignore app.py; echo "exit $?"
exit 1
$ git check-ignore -q debug.log; echo "exit $?"
exit 0
$ git check-ignore -q debug.log app.py
fatal: --quiet is only valid with a single pathname
$ git check-ignore -v build build/ build/out.o
.gitignore:2:build/	build
.gitignore:2:build/	build/
.gitignore:2:build/	build/out.o
```

Without `-v` it prints only the paths that are ignored, and exits 0 if at least
one is. `-q` is for asking about exactly one path in a script. A file inside an
ignored directory is reported with the directory's rule.

`tracked.log` matches `*.log`, but it was added with `-f` before the rule
existed:

```console
$ git check-ignore tracked.log; echo "exit $?"
exit 1
$ git check-ignore -v --no-index tracked.log
.gitignore:1:*.log	tracked.log
$ git check-ignore -v --no-index --index tracked.log; echo "exit $?"
exit 1
```

A tracked file is never ignored, so `check-ignore` says nothing. `--no-index`
checks the rules as if the file were not tracked, which is how to find out why a
rule you wrote does not seem to apply. `--index` cancels it again.

For many paths, `--stdin` reads them one per line, and `-n` marks the ones that
matched nothing, so every input gets an output line:

```console
$ printf 'debug.log\napp.py\n' | git check-ignore -v -n --stdin
.gitignore:1:*.log	debug.log
::	app.py
$ printf 'debug.log\0app.py\0' | git check-ignore -z --stdin -n -v | tr '\0' '@'; echo
.gitignore@1@*.log@debug.log@@@@app.py@
$ git check-ignore -z debug.log
fatal: -z only makes sense with --stdin
$ git check-ignore -n app.py
fatal: --non-matching is only valid with --verbose
$ git check-ignore
fatal: no path specified
$ git check-ignore ../outside.txt; echo "exit $?"
fatal: ../outside.txt: '../outside.txt' is outside repository at '/home/ada/checking'
exit 128
```

With `-z`, names in and out are separated by NUL bytes, shown here as `@`, and
the colons and tab of `-v` become NULs too, so any file name is safe. Git's
documentation says `-n` exists for exactly this: a script feeding paths in one at
a time can tell "not ignored" from "no answer yet".

| Exit code | Means |
|---|---|
| `0` | At least one path is ignored |
| `1` | None of the paths is ignored |
| `128` | An error, such as a path outside the repository |

## Anchoring

A pattern containing a slash anywhere except at the end is matched against the
path from the repository root. A pattern with no slash matches at any depth.

```console
$ printf 'build/\n' > .gitignore
$ git status --short --ignored
?? .gitignore
?? app.py
?? debug.log
!! build/
!! src/
$ printf '/build/\n' > .gitignore
$ git status --short --ignored
?? .gitignore
?? app.py
?? debug.log
?? src/
!! build/
```

With `build/`, both the top-level `build` and `src/build` were ignored. With
`/build/`, only the top-level one.

`src/` was listed as ignored as a whole because its only content was
`src/build/`. (`debug.log` came back because each command replaces the whole
`.gitignore` with one line.)

| Pattern | Matches |
|---|---|
| `build` | Anything called `build`, at any depth |
| `/build` | Only `build` at the repository root |
| `build/` | Only directories called `build`, at any depth |
| `/build/` | Only the top-level `build` directory |
| `src/build` | Only that exact path from the root |

The leading slash is how you say "this one, not every one with the same name".

"From the root" means from the directory the `.gitignore` is in. In a
`.gitignore` inside `work/`:

```console
$ printf '/scratch.tmp\n' > work/.gitignore
$ git check-ignore -v scratch.tmp work/scratch.tmp work/sub/scratch.tmp
work/.gitignore:1:/scratch.tmp	work/scratch.tmp
$ printf 'sub/scratch.tmp\n' > work/.gitignore
$ git check-ignore -v scratch.tmp work/scratch.tmp work/sub/scratch.tmp
work/.gitignore:1:sub/scratch.tmp	work/sub/scratch.tmp
```

`/scratch.tmp` matched only `work/scratch.tmp`, and `sub/scratch.tmp` only
`work/sub/scratch.tmp`. Neither affected the `scratch.tmp` at the top.

## The trailing slash

```console
$ printf 'cache\n' > .gitignore
$ git check-ignore -v cache
.gitignore:1:cache	cache
$ printf 'cache/\n' > .gitignore
$ git check-ignore -v cache
$ git check-ignore -v cache_dir/x.txt
```

`cache` matched the file. `cache/` did not, because the trailing slash
restricts the pattern to directories. It did not match the directory
`cache_dir` either: a pattern matches a whole name, not the beginning of one.

Use the trailing slash whenever you mean a directory. It documents intent and
it prevents a file that happens to share the name from vanishing.

## Wildcards

```console
$ printf '?.txt\n' > .gitignore
$ git check-ignore -v a.txt ab.txt
.gitignore:1:?.txt	a.txt
$ printf '[ab]*.txt\n' > .gitignore
$ git check-ignore -v a.txt ab.txt
.gitignore:1:[ab]*.txt	a.txt
.gitignore:1:[ab]*.txt	ab.txt
```

| Wildcard | Matches |
|---|---|
| `*` | Any run of characters, but never a `/` |
| `?` | Exactly one character, never a `/` |
| `[abc]` | One character from the set |
| `[a-z]` | One character from the range |
| `[!abc]` | One character not in the set |
| `**/` | Any number of directories, at the start |
| `/**` | Everything inside, at the end |
| `/**/` | Any number of directories, in the middle |

The `*` not crossing `/` is the rule that matters most:

```console
$ printf '*.log\n' > .gitignore
$ git check-ignore -v logs/deep/nested.log
.gitignore:1:*.log	logs/deep/nested.log
$ printf 'logs/*.log\n' > .gitignore
$ git check-ignore -v logs/deep/nested.log
$ printf 'logs/**/*.log\n' > .gitignore
$ git check-ignore -v logs/deep/nested.log
.gitignore:1:logs/**/*.log	logs/deep/nested.log
```

`*.log` matched at any depth, because it contains no slash and so floats.
`logs/*.log` did not match, because it is anchored and `*` cannot cross the
`/` into `deep`. `logs/**/*.log` matched, because `**` is the wildcard that
crosses directories.

The rest of the table, each run once:

```console
$ printf '[!ab].txt\n' > .gitignore && git check-ignore -v -n a.txt b.txt c.txt
::	a.txt
::	b.txt
.gitignore:1:[!ab].txt	c.txt
$ printf '[a-b].txt\n' > .gitignore && git check-ignore -v -n a.txt b.txt c.txt
.gitignore:1:[a-b].txt	a.txt
.gitignore:1:[a-b].txt	b.txt
::	c.txt
$ printf 'foo/*\n' > .gitignore && git check-ignore -v -n foo/test.json foo/bar foo/bar/hello.c
.gitignore:1:foo/*	foo/test.json
.gitignore:1:foo/*	foo/bar
.gitignore:1:foo/*	foo/bar/hello.c
$ printf '**/foo\n' > .gitignore && git check-ignore -v -n foo deep/x/foo
.gitignore:1:**/foo	foo
.gitignore:1:**/foo	deep/x/foo
$ printf 'a/**/b\n' > .gitignore && git check-ignore -v -n a/b a/x/y/b
.gitignore:1:a/**/b	a/b
.gitignore:1:a/**/b	a/x/y/b
```

`foo/*` looks like it contradicts the rule about `*`: `foo/bar/hello.c` was
ignored. Git's documentation explains that the pattern itself does not match
`foo/bar/hello.c`, but it does match the directory `foo/bar`, and everything
inside an ignored directory is ignored, so `check-ignore` names that rule.
`**/foo` is, as the documentation says, the same as plain `foo`, and `a/**/b`
matches with no directories in between too.

> **Windows.** With `core.ignorecase` set to `true`, the default on Windows and
> macOS, patterns match without regard to case:
>
> ```console
> $ printf '*.TXT\n' > .gitignore && git check-ignore -v a.txt
> .gitignore:1:*.TXT	a.txt
> $ git -c core.ignorecase=false check-ignore -v a.txt; echo "exit $?"
> exit 1
> ```
>
> A `.gitignore` that works on Windows can therefore fail on Linux, where
> `core.ignorecase` is `false`. Write patterns in the case the files really use.

## Negation

A `!` prefix un-ignores something a previous rule caught:

```console
$ printf 'docs/*\n!docs/keep.txt\n' > .gitignore
$ git status --short --ignored
?? .gitignore
?? a.txt
?? ab.txt
?? app.py
?? build/
?? cache_dir/
?? debug.log
?? docs/
?? logs/
?? src/
!! docs/notes.txt
$ git check-ignore -v docs/keep.txt
.gitignore:2:!docs/keep.txt	docs/keep.txt
$ git check-ignore -v docs/notes.txt
.gitignore:1:docs/*	docs/notes.txt
```

Notice `check-ignore` reports the negation rule as the one that decided. It
names whichever rule won, not only rules that ignore.

## The negation trap

This is the most reported "gitignore is broken" behaviour, and it is not a bug.

```console
$ printf 'docs/\n!docs/keep.txt\n' > .gitignore
$ git status --short --ignored
?? .gitignore
?? a.txt
?? ab.txt
?? app.py
?? build/
?? cache_dir/
?? debug.log
?? logs/
?? src/
!! docs/
$ git check-ignore -v docs/keep.txt
.gitignore:1:docs/	docs/keep.txt
```

The negation did nothing. Line 1 still decided.

The rule: **if a directory is excluded, Git does not descend into it**, so
nothing inside can be re-included. Git never looks at `docs/keep.txt` because
it already dismissed `docs/` entirely, which is a deliberate performance
decision.

The fix is to exclude the *contents* rather than the directory:

```console
$ printf 'docs/**\n!docs/keep.txt\n' > .gitignore
$ git status --short --ignored
?? .gitignore
?? a.txt
?? ab.txt
?? app.py
?? build/
?? cache_dir/
?? debug.log
?? docs/
?? logs/
?? src/
!! docs/notes.txt
```

| Want | Write |
|---|---|
| Ignore a directory entirely | `docs/` |
| Ignore its contents but keep one file | `docs/**` then `!docs/keep.txt` |
| Ignore everything in a nested tree but keep one deep file | Un-ignore every directory on the path first |

That last row is the painful one. To keep `a/b/c/keep.txt` under a blanket
ignore, you must re-include each directory level:

```console
$ cat .gitignore
/*
!/a/
/a/*
!/a/b/
/a/b/*
!/a/b/c/
/a/b/c/*
!/a/b/c/keep.txt
!.gitignore
$ git status --short --ignored -uall
?? .gitignore
?? a/b/c/keep.txt
!! a/b/c/other.txt
!! a/b/mid.txt
!! top.txt
$ git check-ignore -v a/b/c/keep.txt a/b/c/other.txt
.gitignore:8:!/a/b/c/keep.txt	a/b/c/keep.txt
.gitignore:7:/a/b/c/*	a/b/c/other.txt
```

Ugly, and the only thing that works. When you find yourself writing it, ask
whether a narrower ignore pattern would be simpler. The last line keeps the
`.gitignore` itself, which `/*` would otherwise ignore too.

## Order matters

```console
$ printf '*.txt\n!important.txt\n' > .gitignore
$ git check-ignore -v important.txt
.gitignore:2:!important.txt	important.txt
$ printf '!important.txt\n*.txt\n' > .gitignore
$ git check-ignore -v important.txt
.gitignore:2:*.txt	important.txt
```

Same two lines, opposite results. **The last matching rule wins.** So negations
must come after the rule they are cancelling, which means a `.gitignore` is
read top to bottom like a series of overrides, not like a set.

## Where rules can live

Git reads ignore rules from these places, listed as Git's documentation lists
them, from the one that wins to the one that loses:

| Location | Scope | Committed | Set by |
|---|---|---|---|
| The command line, such as `git clean -e` (Chapter 14) | That one command | No | You, each time |
| `.gitignore` in any directory | That directory and below | Yes | The project |
| `.git/info/exclude` | This repository only | No | You |
| `core.excludesFile` | Every repository you have | No | You |

Within that, the deepest `.gitignore` beats a shallower one:

```console
$ printf '*.tmp\n' > .gitignore
$ git check-ignore -v work/scratch.tmp
.gitignore:1:*.tmp	work/scratch.tmp
$ printf '!scratch.tmp\n' > work/.gitignore
$ git check-ignore -v work/scratch.tmp
work/.gitignore:1:!scratch.tmp	work/scratch.tmp
$ git status --short
?? .gitignore
?? a.txt
?? ab.txt
?? app.py
?? build/
?? cache_dir/
?? debug.log
?? docs/
?? important.txt
?? logs/
?? src/
?? work/
```

The file in `work/` overrode the one at the top, because it is closer to the
file being tested.

The two personal locations:

```console
$ printf 'private-notes.txt\n' >> .git/info/exclude
$ git check-ignore -v private-notes.txt
.git/info/exclude:7:private-notes.txt	private-notes.txt
$ printf '*.bak\n' > /home/ada/global-ignore
$ git config set core.excludesFile /home/ada/global-ignore
$ git check-ignore -v draft.bak
/home/ada/global-ignore:1:*.bak	draft.bak
```

`.git/info/exclude` already has six lines of comments when Git creates it, which
is why the new rule is line 7. And a `.gitignore` wins over `.git/info/exclude`
in both directions:

```console
$ printf '*.bak\n' >> .git/info/exclude && printf '!keep.bak\n' > .gitignore
$ git check-ignore -v -n keep.bak other.bak
.gitignore:1:!keep.bak	keep.bak
.git/info/exclude:7:*.bak	other.bak
$ printf '*.bak\n' > .gitignore && printf '!keep.bak\n' >> .git/info/exclude
$ git check-ignore -v -n keep.bak other.bak
.gitignore:1:*.bak	keep.bak
.gitignore:1:*.bak	other.bak
```

Without `core.excludesFile`, Git still reads a personal file: Git's
documentation gives the default as `$XDG_CONFIG_HOME/git/ignore`, or
`~/.config/git/ignore` when `XDG_CONFIG_HOME` is not set. Here the variable
points into the sandbox:

```console
$ cat /home/ada/xdg/git/ignore
*.swp
$ XDG_CONFIG_HOME=/home/ada/xdg git check-ignore -v notes.swp
/home/ada/xdg/git/ignore:1:*.swp	notes.swp
$ printf '/notes.swp\n' > /home/ada/anchored-ignore
$ git -c core.excludesFile=/home/ada/anchored-ignore check-ignore -v -n notes.swp sub/notes.swp
/home/ada/anchored-ignore:1:/notes.swp	notes.swp
::	sub/notes.swp
```

Rules in the two personal files are anchored at the top of whatever repository
they are applied to, so `/notes.swp` matched only the top-level file.

| Use | For |
|---|---|
| `.gitignore` | Anything every developer on the project would want ignored: build output, dependencies, generated files |
| `.git/info/exclude` | Things specific to your copy of this project |
| `core.excludesFile` | Your editor's files, your operating system's files |

> **Worth knowing.** Committing `.DS_Store` or `Thumbs.db` patterns to a
> project's `.gitignore` is a small act of rudeness. Those are artefacts of
> *your* operating system and belong in your global excludes file, not in
> everyone's repository. The same goes for `.idea/` and `.vscode/` unless the
> team has agreed to share editor settings.

## Comments, blank lines and escaping

```console
$ printf '# a comment\n\n\#not-a-comment.txt\ntrailing-space  \n' > .gitignore
$ git check-ignore -v '#not-a-comment.txt'
.gitignore:3:\#not-a-comment.txt	#not-a-comment.txt
$ git check-ignore -v trailing-space
.gitignore:4:trailing-space	trailing-space
```

| Line | Meaning |
|---|---|
| Starting with `#` | A comment |
| Starting with `\#` | A literal `#`, for a file genuinely named that way |
| Blank | Ignored, use them for grouping |
| Ending with spaces | Trailing spaces are stripped unless escaped with `\` |
| Starting with `\!` | A literal `!` |
| Ending with `\` | An invalid pattern that never matches |

Trailing whitespace being stripped is the quiet one. A pattern typed as
`build ` works, and a pattern for a file whose name really does end in a space
needs `build\ `.

```console
$ printf '\\!important!.txt\n' > .gitignore && cat .gitignore
\!important!.txt
$ git check-ignore -v '!important!.txt'
.gitignore:1:\!important!.txt	!important!.txt
$ printf 'a.txt\\\n' > .gitignore && cat .gitignore
a.txt\
$ git check-ignore -v a.txt; echo "exit $?"
exit 1
```

The first pattern is Git's own documentation example: the backslash makes the
leading `!` part of the name. The second ends in a backslash, and matches
nothing at all. Git's documentation adds that a backslash escapes any
character, so `\*` matches a file with a real `*` in its name.

## Listing what is ignored

```console
$ git status --short --ignored
?? .gitignore
?? a.txt
?? ab.txt
?? app.py
?? build/
?? cache_dir/
?? debug.log
?? docs/
?? important.txt
?? logs/
?? src/
?? work/
!! draft.bak
!! private-notes.txt
$ git ls-files --others --ignored --exclude-standard
draft.bak
private-notes.txt
$ git ls-files --others --exclude-standard
.gitignore
a.txt
ab.txt
app.py
build/out.txt
cache_dir/x.txt
debug.log
docs/keep.txt
docs/notes.txt
important.txt
logs/deep/nested.log
src/build/out.txt
work/.gitignore
work/scratch.tmp
```

| Command | Lists |
|---|---|
| `git status --ignored` | Ignored entries, collapsed by directory |
| `git ls-files --others --ignored --exclude-standard` | Every ignored file individually |
| `git ls-files --others --exclude-standard` | Every untracked file that is *not* ignored |

That last one is the answer to "what have I forgotten to add". `--others`
means untracked, and `--exclude-standard` applies the normal ignore rules,
which `ls-files` does not do on its own.

## Two things gitignore cannot do

**It cannot untrack a file.** Once a path is in the index, no pattern affects
it. Chapter 8 demonstrates this and gives the fix, `git rm --cached`.

**It cannot ignore a directory into existence.** Git stores no empty
directories (Chapter 4), so a directory containing only ignored files does not
survive a clone. The convention is a `.gitkeep` file, or a `.gitignore` inside
that directory containing:

```console
$ cat uploads/.gitignore
*
!.gitignore
$ git status --short -uall --ignored
?? readme.txt
?? uploads/.gitignore
!! uploads/photo.jpg
$ git add -A && git commit -q -m 'Keep the uploads directory' && git ls-files
readme.txt
uploads/.gitignore
$ git clone -q /home/ada/emptydir.git /home/ada/copy && ls -A /home/ada/copy/uploads
.gitignore
```

which ignores everything in the directory except the ignore file itself, giving
Git one tracked file to hang the directory on. The clone has an `uploads`
directory, holding only the `.gitignore`. A `.gitkeep` is just an empty file
with a name people recognise; Git gives the name no special meaning.

## Forcing past a rule

```console
$ git add private-notes.txt
The following paths are ignored by one of your .gitignore files:
private-notes.txt
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
$ git add -f private-notes.txt && git status --short
A  private-notes.txt
?? .gitignore
?? a.txt
?? ab.txt
?? app.py
?? build/
?? cache_dir/
?? debug.log
?? docs/
?? important.txt
?? logs/
?? src/
?? work/
$ git check-ignore -v private-notes.txt; echo "exit $?"
exit 1
$ git rm -q --cached private-notes.txt
```

`-f` overrides the ignore rules for one `git add`. After that the file is
tracked and the rule stops applying to it entirely, which is rarely what
people expect: `check-ignore` now says it is not ignored. Chapter 11 covers the
message and `-f` in full. The message says ".gitignore files" even though this
rule is in `.git/info/exclude`.

## Changes to a tracked file

The common wish is to ignore local edits to a tracked file, such as a
configuration file with your own password in it. Ignore rules cannot do that,
and Git's FAQ says plainly that Git has no way to: when Git needs to overwrite
the file, it could not know whether your changes were precious. The FAQ also
warns against the two `git update-index` flags people reach for,
`--assume-unchanged` and `--skip-worktree`, which do not work properly for
this.

What it recommends instead is to commit a template and ignore the real file:

```console
$ cp config.example.ini config.ini && git status --short --ignored
!! config.ini
```

This repository commits `config.example.ini` and a `.gitignore` containing
`config.ini`. Each person copies the template and edits the copy, which Git
never shows or commits.

## A starting .gitignore

Do not write one from scratch. Every language ecosystem has a maintained
template, and Git hosts publish collections of them. What matters is knowing
what belongs in one:

| Category | Examples |
|---|---|
| Build output | `dist/`, `build/`, `target/`, `*.o`, `*.class` |
| Dependencies | `node_modules/`, `vendor/`, `.venv/` |
| Generated files | `*.min.js`, compiled translations, generated API clients |
| Local configuration | `.env`, `config.local.*` |
| Caches | `__pycache__/`, `.pytest_cache/`, `.gradle/` |
| Editor and OS files | belong in your global excludes, not here |

> **Careful.** A `.env` file usually holds passwords and access keys, which makes
> it one of the most damaging files to commit by mistake. Add it to `.gitignore`
> in the same commit that creates it, not later. If it has already been
> committed, change the credentials first: removing the file from history
> (Chapter 37) does not reach the clones other people already have.

## The settings

| Setting | Effect |
|---|---|
| `core.excludesFile` | Your personal ignore file for every repository. Defaults to `$XDG_CONFIG_HOME/git/ignore` or `~/.config/git/ignore` |
| `core.ignoreCase` | `true` makes patterns match without regard to case; `true` by default on Windows and macOS |
| `status.showUntrackedFiles` | How status lists untracked files, ignored or not (Chapter 10) |
| `advice.addIgnoredFile` | `false` removes the hint when `git add` refuses an ignored file |
