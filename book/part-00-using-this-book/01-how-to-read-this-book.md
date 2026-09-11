# Chapter 1. How to Read This Book

## The premise

This book was written for someone with no internet connection and no computer.

That sounds like a strange constraint, so here is what it changes. A normal Git
book can say "see the documentation for the other options." This one cannot.
A normal book can say "try it and see what happens." This one cannot. If you
are reading on a phone on a bus with no signal, every question you could have
answered by typing a command has to already be answered on the page.

So when a command has fourteen options, you get fourteen options. When a
command fails in six different ways, you get six failures with their exact
error text. When two commands look interchangeable but are not, you get both,
side by side, with the case that separates them.

## The three-layer rule

Everything in this book is explained in the cheapest form that actually works.

**Layer one is an example.** If you can see what a command does by reading a
transcript, that is all you get:

```console
$ git init my-project
Initialized empty Git repository in /home/ada/my-project/.git/
```

**Layer two is a short paragraph**, used when the example is correct but
incomplete. The transcript above does not tell you that `git init` is safe to
run twice, or that running it inside an existing repository does not destroy
anything. Two sentences fix that, so you get two sentences.

**Layer three is a long explanation**, used only when leaving it out would
leave a hole you could fall into. The chapter on `git reset` has three pages of
prose, because a reader who half-understands `reset` will eventually lose work.
That is the test: if not understanding the mechanism causes damage, the
mechanism gets explained properly.

Tables replace all three layers whenever the content is a list of parallel
facts. A table of nine options is faster to read and faster to search than nine
paragraphs saying the same thing.

## How to read a transcript

Every transcript in this book was produced by actually running the commands.
Nothing is typed from memory. Here is the anatomy:

```console
$ git commit -m "Add the parser"
[main 2a84279] Add the parser
 1 file changed, 3 insertions(+)
 create mode 100644 src/parser.py
```

| Element | Meaning |
|---|---|
| `$` at the start of a line | A command you type. The `$` is not part of it. |
| Lines with no `$` | Output from Git. You do not type these. |
| `#` at the end of a line | A comment added for the book, not part of the command. |
| `<angle-brackets>` | A placeholder. Substitute your own value and remove the brackets. |
| `[...]` in a synopsis | An optional part. |
| `...` on its own line | Output was trimmed because the omitted part is not relevant. |

When the prompt shows a directory or branch, it means the working directory or
current branch matters to what follows:

```console
my-project (main) $ git status
```

## Call-out boxes

Four kinds of note interrupt the text. They look like this:

> **Since Git 2.51.** A feature that older versions do not have. If your Git is
> older, the command will fail with `unknown option` or `is not a git command`,
> which is a confusing way to learn about a version requirement.

> **Windows.** Something behaves differently on Windows. These are frequent
> enough to deserve their own marker and are collected again in Appendix H.

> **Careful.** An operation that can lose work, or that is hard to undo. Every
> one of these tells you how to recover.

> **Worth knowing.** A detail that is not required but explains why something
> is the way it is.

## Version badges

Git is old and still moving. Commands that this book teaches as the modern
default did not exist a few years ago, and commands you will see in older
tutorials are on their way out. Anything that needs a Git newer than 2.23 is
marked with the version that introduced it.

The examples were produced on this version:

```console
$ git --version
git version 2.55.0.windows.5
```

If yours is older, the marked features are the ones to watch. Everything
unmarked has worked for a decade and will keep working.

## How the book is organised

| Part | What it covers | Read it when |
|---|---|---|
| 0 | Using this book, the sandbox, installing Git | Now |
| 1 | The mental model: objects, refs, the three areas | Before anything else |
| 2 | Everyday work: add, commit, diff, status, ignore | First week |
| 3 | Reading history: log, blame, bisect, search | First month |
| 4 | Branching and merging, and conflicts in depth | When you work with anyone |
| 5 | Rewriting history: rebase, reset, revert, reflog | When you need to fix a mistake |
| 6 | Remotes: fetch, pull, push, refspecs, protocols | When your work leaves your machine |
| 7 | Collaboration: tags, workflows, pull requests, review | When you join a team |
| 8 | Specialised tools: stash, worktree, submodule, LFS | When a specific need appears |
| 9 | Configuration: config, attributes, hooks, signing | When you want Git to fit you |
| 10 | Internals: objects on disk, packfiles, plumbing | When you want to stop guessing |
| 11 | Recovery: getting lost work back | On your worst day |

Parts 1 and 2 are the only ones meant to be read in order. Everything after is
a reference you enter from wherever your question is.

## Four ways to find an answer

Since you cannot search the web, the book has to be searchable itself. There
are four doors in:

**You know the command.** Appendix A lists every command and every option used
in the book, alphabetically, with the page that explains it.

**You have an error message.** Appendix B lists error messages verbatim,
alphabetically, each with its cause and its fix. Look up the exact text Git
printed at you.

**You know what you want to do but not what it is called.** Appendix G has
decision tables. "I committed to the wrong branch" is a row, and the row tells
you which command you need.

**You know the concept.** Appendix E is a glossary, and every term defined in
it appears in bold the first time the book uses it.

## What this book assumes

It assumes you can use a terminal to the extent of changing directory and
listing files. It does not assume you know what version control is, what a
hash is, or what a branch is.

It does not teach a programming language, a text editor, or a shell. Where a
shell feature is needed for an example, the example explains it.

## What this book does not cover

Continuous integration is out of scope. GitHub Actions, GitLab CI and their
relatives are large enough to need their own book, and none of them is Git.
The parts of GitHub and GitLab that are really Git wearing a web interface,
such as forks, pull requests and protected branches, are covered in Part 7.

## A note on the two styles of Git

In 2019 Git split the overloaded `git checkout` command into two focused ones,
`git switch` and `git restore`. In Git 2.51 both of them stopped being
experimental and their interface is now stable.

This book teaches the new pair first, because they are much easier to learn.
But it always shows the `checkout` equivalent next to them, because the world
is full of older scripts, older tutorials and colleagues with older habits,
and `git checkout` is not going away:

| Task | Modern | Classic |
|---|---|---|
| Move to another branch | `git switch topic` | `git checkout topic` |
| Create and move | `git switch -c topic` | `git checkout -b topic` |
| Throw away changes to a file | `git restore file.txt` | `git checkout -- file.txt` |
| Unstage a file | `git restore --staged file.txt` | `git reset HEAD file.txt` |

You will be able to read both. You should write the modern one.
