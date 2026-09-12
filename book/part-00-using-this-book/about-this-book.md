# About This Book

**Git by Example: A Complete Offline Handbook**

By M. Reza Norouzi.

Written against **Git 2.55**. Features that need a version newer than Git 2.23
are marked in the text with the release that introduced them, because a reader
on an older Git gets an `unknown option` error that says nothing about
versions.

## How the examples were made

Nothing in this book was typed from memory.

Every command transcript was produced by actually running the command. The
scripts that generate them live in the book's repository under `sandbox/`, one
per chapter, and they pin the author, the committer, the clock, the
configuration and the line endings. That is why the commit hashes printed in
these pages are real, and why running the same commands yourself produces the
same hashes rather than different ones. Chapter 2 explains the machinery and
shows the self-test that proves it.

Every factual claim about Git's behaviour was checked against the documentation
that ships with Git itself, and against the release notes for the version that
introduced each feature. Where this book says Git does something, that is what
the installed Git does, not what it did some years ago.

The prose was drafted by Claude, an AI assistant from Anthropic, working to the
author's specification and under the author's review. This is disclosed for the
same reason the verification method is disclosed: you are holding a reference
book with no way to check it against anything else, so you are entitled to know
how it was built and to weigh that when you rely on it.

## If you find a mistake

The book lives at:

```
https://github.com/norouzir/git-by-example
```

Errors, unclear passages, and missing cases are all worth reporting there. A
reference that nobody corrects slowly stops being one.

If you are reading this offline and cannot report anything yet, note the
chapter and what surprised you, and check it when you next have a connection.
The most valuable corrections come from people who hit a case the book did not
cover.

## Licence

The text of this book is licensed under Creative Commons
Attribution-ShareAlike 4.0 International (CC BY-SA 4.0). You may copy it, print
it, put it on a phone and hand it to someone with no internet, translate it,
and build on it, as long as you credit the author and license what you build
under the same terms.

The scripts under `sandbox/` and `tools/` are licensed under the MIT licence.
They exist to be copied and adapted, so they carry no share-alike obligation.

Copyright (c) 2026 M. Reza Norouzi.

## Thanks

To everyone who has answered a Git question patiently, and to the Git project
for shipping its complete documentation with the software, which is the only
reason a book written for people with no internet could be checked against
anything at all.
