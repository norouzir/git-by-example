# Chapter 16. Ignoring Files

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

## Anchoring

A pattern containing a slash anywhere except at the end is matched against the
path from the repository root. A pattern with no slash matches at any depth.

```console
$ printf 'build/\n' > .gitignore
$ git status --short --ignored
...
!! build/
!! src/
$ printf '/build/\n' > .gitignore
$ git status --short --ignored
...
?? src/
!! build/
```

With `build/`, both the top-level `build` and `src/build` were ignored. With
`/build/`, only the top-level one.

| Pattern | Matches |
|---|---|
| `build` | Anything called `build`, at any depth |
| `/build` | Only `build` at the repository root |
| `build/` | Only directories called `build`, at any depth |
| `/build/` | Only the top-level `build` directory |
| `src/build` | Only that exact path from the root |

The leading slash is how you say "this one, not every one with the same name".

## The trailing slash

```console
$ printf 'cache\n' > .gitignore
$ git check-ignore -v cache
.gitignore:1:cache	cache
$ printf 'cache/\n' > .gitignore
$ git check-ignore -v cache
```

`cache` matched the file. `cache/` did not, because the trailing slash
restricts the pattern to directories.

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

## Negation

A `!` prefix un-ignores something a previous rule caught:

```console
$ printf 'docs/*\n!docs/keep.txt\n' > .gitignore
$ git status --short --ignored
...
?? docs/
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
...
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
...
?? docs/
!! docs/notes.txt
```

| Want | Write |
|---|---|
| Ignore a directory entirely | `docs/` |
| Ignore its contents but keep one file | `docs/**` then `!docs/keep.txt` |
| Ignore everything in a nested tree but keep one deep file | Un-ignore every directory on the path first |

That last row is the painful one. To keep `a/b/c/keep.txt` under a blanket
ignore, you must re-include each directory level:

```
/*
!/a/
/a/*
!/a/b/
/a/b/*
!/a/b/c/
/a/b/c/*
!/a/b/c/keep.txt
```

Ugly, and the only thing that works. When you find yourself writing it, ask
whether a narrower ignore pattern would be simpler.

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

Git reads ignore rules from four places:

| Location | Scope | Committed | Set by |
|---|---|---|---|
| `.gitignore` in any directory | That directory and below | Yes | The project |
| `.git/info/exclude` | This repository only | No | You |
| `core.excludesFile` | Every repository you have | No | You |
| Built-in | Nothing by default | No | Git |

They are consulted from least to most specific, and the most specific match
wins. Within that, the deepest `.gitignore` beats a shallower one:

```console
$ printf '*.tmp\n' > .gitignore
$ git check-ignore -v work/scratch.tmp
.gitignore:1:*.tmp	work/scratch.tmp
$ printf '!scratch.tmp\n' > work/.gitignore
$ git check-ignore -v work/scratch.tmp
work/.gitignore:1:!scratch.tmp	work/scratch.tmp
```

The file in `work/` overrode the one at the top, because it is closer to the
file being tested.

The two personal locations:

```console
$ printf 'private-notes.txt\n' >> .git/info/exclude
$ git check-ignore -v private-notes.txt
.git/info/exclude:7:private-notes.txt	private-notes.txt
$ git config set core.excludesFile /home/ada/global-ignore
$ git check-ignore -v draft.bak
/home/ada/global-ignore:1:*.bak	draft.bak
```

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

Trailing whitespace being stripped is the quiet one. A pattern typed as
`build ` works, and a pattern for a file whose name really does end in a space
needs `build\ `.

## Listing what is ignored

```console
$ git status --short --ignored
...
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
...
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

```
*
!.gitignore
```

which ignores everything in the directory except the ignore file itself, giving
Git one tracked file to hang the directory on.

## Forcing past a rule

```console
$ git add -f debug.log
```

`-f` overrides the ignore rules for one `git add`. After that the file is
tracked and the rule stops applying to it entirely, which is rarely what
people expect. Chapter 11 has the full error message Git prints without `-f`.

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

> **Careful.** `.env` is the single most commonly leaked file in public
> repositories. Add it to `.gitignore` in the same commit that creates it, not
> later. If it has already been committed, Chapter 37 covers removing it from
> history and its first instruction is to rotate the credentials, because
> deleting it from history does not reach clones other people already have.
