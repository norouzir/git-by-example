# Chapter 48. Releases and Versioning

## What it is

A release is a commit you give a version number to and hand to other people.
Git has no release command and no release object. A release in Git is an
annotated tag on a commit (Chapter 47), usually with a commit before it that
writes the number into the project, and often an archive made from the tag for
people who will not clone. Everything around that, choosing the number, saying
what changed, building from the tag, fixing an old release, is done with
commands the book has already shown, put together.

This chapter is organised by the steps of releasing rather than by a command,
like Chapter 45. The one question it answers is: *how do I publish a version of
my project that everyone can name, find and rebuild exactly?*

| Term | Means |
|---|---|
| *release* | a version of the project given a number and published; in Git, a tagged commit |
| *version number* | the name of a release, such as `1.2.0`; the tag usually adds a `v`: `v1.2.0` |
| *semantic versioning* | a rule for choosing version numbers from what changed, described below |
| *pre-release* | a version published for testing before the release, such as `1.1.0-rc.1` |
| *release candidate* | a pre-release meant to become the release unless a problem is found; `rc` |
| *changelog*, *release notes* | the list of what changed since the previous release |
| *maintenance branch* | a branch started at an old release's tag, for fixes to that release |
| *backport* | copying a fix from a newer line of development to an older one |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What is a release, in terms of Git?](#what-it-is)

**[The release steps at a glance](#the-release-steps-at-a-glance)**

- [What are the steps of a release, and which commands does each use?](#the-release-steps-at-a-glance)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[Version numbers](#version-numbers)**

- [How do I decide whether the next version is 1.1.1, 1.2.0 or 2.0.0?](#semantic-versioning)
- [What do `-rc.1` and `+build.5` at the end of a version mean?](#semantic-versioning)
- [Is `v1.2.0` a version number, or is `1.2.0`?](#semantic-versioning)
- [Why does Git list `v1.10.0` before `v1.2.0`, or `v1.0.0` before `v1.0.0-alpha`?](#how-git-orders-versions)
- [How do I make Git sort versions the way Semantic Versioning does?](#how-git-orders-versions)
- [Do I have to use Semantic Versioning?](#other-ways-to-number)

**[Preparing a release](#preparing-a-release)**

- [How do I find the last release, and what has changed since?](#what-changed-since-the-last-release)
- [Why does the list of changes include commits from the maintenance branch?](#what-changed-since-the-last-release)
- [How do I see only the merges, or only which files changed?](#what-changed-since-the-last-release)
- [How do I turn the history into release notes?](#release-notes-from-the-history)

**[Making a release](#making-a-release)**

- [What exactly do I commit, tag and push to make a release?](#the-release-commit-and-its-tag)
- [How does a build know which version it is?](#the-version-inside-a-build)
- [Why did `git describe --tags` print the name of my bookmark tag?](#the-version-inside-a-build)
- [What does `-dirty` at the end of a version mean?](#the-version-inside-a-build)
- [How do I make a `.tar.gz` or `.zip` of a release?](#release-archives)
- [How do I keep some files out of the archive, or write the version into it?](#release-archives)
- [Given an archive, how do I find the commit it was made from?](#release-archives)

**[Release candidates](#release-candidates)**

- [Why does `git describe` name the release candidate instead of the last release?](#release-candidates)
- [How do I list releases with candidates in the right place?](#release-candidates)

**[Maintaining an older release](#maintaining-an-older-release)**

- [How do I fix a bug in 1.0 after 1.1 is out?](#maintaining-an-older-release)
- [Where should a fix be made first, so that every release gets it?](#fixing-the-oldest-branch-and-merging-up)
- [I backported a fix with cherry-pick. Why does `git tag --contains` not list the release that has it?](#backporting-with-cherry-pick)

**[Which release is the latest](#which-release-is-the-latest)**

- [What is the latest release, and why do three ways of asking give three answers?](#which-release-is-the-latest)

**[When a release is wrong](#when-a-release-is-wrong)**

- [A release has a bug, or was tagged on the wrong commit. What now?](#when-a-release-is-wrong)

**[Releases on hosting services](#releases-on-hosting-services)**

- [What is a "release" on GitHub or GitLab, and how does it relate to a tag?](#releases-on-hosting-services)
- [Someone made a release in the web page. How do I get its tag?](#releases-on-hosting-services)

**[Handing a release to someone](#handing-a-release-to-someone)**

- [Should I give someone an archive, a bundle or a clone?](#handing-a-release-to-someone)

**[The settings](#the-settings)**

- [Which settings help with releases?](#the-settings)

</details>

## The release steps at a glance

| Step | Commands | Covered in |
|---|---|---|
| find the last release and what changed since | `git describe --abbrev=0`, `git log <tag>..` | [What changed since the last release](#what-changed-since-the-last-release) |
| choose the number | Semantic Versioning, from what changed | [Semantic versioning](#semantic-versioning) |
| write the number down and commit it | an ordinary commit, `Release 1.2.0` | [The release commit and its tag](#the-release-commit-and-its-tag) |
| tag it | `git tag -a v1.2.0 -m 'Atlas 1.2.0'` | [The release commit and its tag](#the-release-commit-and-its-tag) |
| publish the commit and the tag | `git push --follow-tags` | [The release commit and its tag](#the-release-commit-and-its-tag) |
| build and package | `git describe`, `git archive` | [The version inside a build](#the-version-inside-a-build), [Release archives](#release-archives) |
| fix an older release | a branch from its tag, a fix, a new tag | [Maintaining an older release](#maintaining-an-older-release) |

## The example repository

```console
$ git log --oneline --graph --all --decorate
* fb06623 (HEAD -> main, origin/main) Add the Americas
* 1d5c15c (tag: v1.1.0) Release 1.1.0
* 077ab2f Add Oceania
* 2639051 (tag: v1.1.0-rc.1) Release 1.1.0-rc.1
*   10347db Merge branch 'maint-1.0'
|\  
| * a2bd505 (tag: v1.0.1, origin/maint-1.0, maint-1.0) Release 1.0.1
| * 2859560 Fix the spelling of Asia
* |   461167e Merge branch 'africa'
|\ \  
| |/  
|/|   
| * c8d534c Add Madagascar
| * 1f265b3 Add Africa
|/  
* 51337c9 (tag: v1.0.0) Release 1.0.0
* 633a6bf Add Asia
* 088e6e1 Add Europe
* 72286d9 Start the atlas
```

Ada's atlas has had releases 1.0.0 and 1.1.0, with a release candidate for 1.1.0
between them. `maint-1.0` started at `v1.0.0` for fixes to that release; its
one fix became 1.0.1 and was merged into `main`. `Africa` was developed on a
branch and merged. Each `Release` commit changes one file, `VERSION`, to the
new number; the tag on it is annotated. `main` has one commit since 1.1.0.
Everything is pushed to `origin`.

## Version numbers

### Semantic versioning

Many projects number their releases by Semantic Versioning, a published rule
(semver.org, version 2.0.0) that makes the number say what changed. A version is
`MAJOR.MINOR.PATCH`, three numbers without leading zeros:

| Since the last release | Increase | And reset | Example after `1.1.0` |
|---|---|---|---|
| only backward compatible bug fixes | `PATCH` | nothing | `1.1.1` |
| new backward compatible features | `MINOR` | `PATCH` to 0 | `1.2.0` |
| any change that breaks what worked before | `MAJOR` | `MINOR` and `PATCH` to 0 | `2.0.0` |

"Backward compatible" is measured against the project's *public API*, which the
specification requires the project to declare, in its code or its
documentation: functions for a library, commands and options for a program, the
file format for the atlas. The specification adds:

- `0.y.z` is for initial development, when anything may change at any time;
  `1.0.0` defines the public API.
- Once a version is released, its contents must not change: any change is a new
  version. In Git terms, a published release tag never moves (Chapter 47).
- A *pre-release* is written with a hyphen and dot-separated parts after the
  patch number: `1.0.0-alpha`, `1.0.0-alpha.1`, `1.0.0-rc.1`. It comes before
  the release itself: `1.0.0-rc.1` is older than `1.0.0`.
- *Build metadata* is written with a plus: `1.0.0+20130313144700`. It is ignored
  when versions are compared.
- `v1.2.3` is not itself a semantic version, the specification says, but
  putting `v` before it in a tag name is the common practice.

The specification orders pre-releases by comparing the dot-separated parts one
by one, numbers as numbers and words as text, a number before a word, and gives
this example: `1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta <
1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0`.

### How Git orders versions

A repository with one commit, tagged with the specification's example and three
more:

```console
$ git tag
v1.0.0
v1.0.0-alpha
v1.0.0-alpha.1
v1.0.0-alpha.beta
v1.0.0-beta
v1.0.0-beta.11
v1.0.0-beta.2
v1.0.0-rc.1
v1.10.0
v1.2.0
v2.0.0-rc.1
$ git tag --sort=version:refname
v1.0.0
v1.0.0-alpha
v1.0.0-alpha.1
v1.0.0-alpha.beta
v1.0.0-beta
v1.0.0-beta.2
v1.0.0-beta.11
v1.0.0-rc.1
v1.2.0
v1.10.0
v2.0.0-rc.1
$ git -c versionsort.suffix=- tag --sort=version:refname
v1.0.0-alpha
v1.0.0-alpha.1
v1.0.0-alpha.beta
v1.0.0-beta
v1.0.0-beta.2
v1.0.0-beta.11
v1.0.0-rc.1
v1.0.0
v1.2.0
v1.10.0
v2.0.0-rc.1
```

By default names sort as text, so `v1.10.0` comes before `v1.2.0` and `beta.11`
before `beta.2`. `version:refname` compares the numbers as numbers, which puts
those right, but it still compares the ending of `v1.0.0` and `v1.0.0-alpha` as
text, and the release comes before its own pre-releases. `versionsort.suffix`
names endings that come before the release (Chapter 47); since every
pre-release starts with a hyphen, a suffix of `-` alone moved them all, and the
order became exactly the specification's. Set it in the configuration, together
with `tag.sort=version:refname`, and every `git tag` lists versions this way
(Chapter 62).

### Other ways to number

Semantic Versioning is a convention, and Git needs none: a tag can be any valid
name. Some projects number by date, some with a single growing number. Git
itself uses three numbers: in the release notes installed with it, 2.54.0 and
2.55.0 are feature releases, and 2.54.1 says it is "primarily to merge fixes"
still relevant to the 2.54 line, which is the maintenance pattern shown below.
Whatever the scheme, choose one before the first release, because tags are
never renamed, and check that `--sort=version:refname` orders it the way you
mean.

## Preparing a release

### What changed since the last release

```console
$ git describe --abbrev=0
v1.1.0
$ git log --oneline v1.1.0..
fb06623 Add the Americas
$ git log --oneline --no-merges v1.0.0..v1.1.0
1d5c15c Release 1.1.0
077ab2f Add Oceania
2639051 Release 1.1.0-rc.1
a2bd505 Release 1.0.1
2859560 Fix the spelling of Asia
c8d534c Add Madagascar
1f265b3 Add Africa
$ git log --oneline --first-parent v1.0.0..v1.1.0
1d5c15c Release 1.1.0
077ab2f Add Oceania
2639051 Release 1.1.0-rc.1
10347db Merge branch 'maint-1.0'
461167e Merge branch 'africa'
$ git diff --stat v1.0.0 v1.1.0
 VERSION          | 2 +-
 maps/africa.txt  | 2 ++
 maps/asia.txt    | 2 +-
 maps/oceania.txt | 1 +
 4 files changed, 5 insertions(+), 2 deletions(-)
$ git shortlog -sn v1.0.0..v1.1.0
     9	Ada Lovelace
```

`git describe --abbrev=0` names the nearest annotated tag behind `HEAD`, the
last release on this line (Chapter 22), and `v1.1.0..` lists what is not in it
yet (Chapter 18). Between two releases, `--no-merges` lists every commit made,
including the fix and the release commit of 1.0.1: the merge brought them into
`main`, so they are part of 1.1.0 too. `--first-parent` follows `main` alone
and shows each merge as one line, which is the shorter summary when work
arrives on branches (Chapter 17). `git diff --stat` compares the two releases'
files, however they got there, and `git shortlog -sn` counts commits per
author, for the thanks at the end of release notes (Chapter 22).

### Release notes from the history

```console
$ git log --no-merges --reverse --format='- %s' v1.0.0..v1.1.0 -- maps
- Add Africa
- Add Madagascar
- Fix the spelling of Asia
- Add Oceania
```

A first draft of release notes, oldest first: one line per commit, and
`-- maps` kept only commits that changed the maps, which drops the release
commits. Good release notes are written for users and group changes by kind,
so this is a starting point, not the result. Release notes are only as good as
the commit messages they are made from; Chapter 53 covers conventions that make
messages sortable into features and fixes.

## Making a release

### The release commit and its tag

```console
$ git status --short && echo 1.2.0 > VERSION && git commit -q -am 'Release 1.2.0' && git tag -a v1.2.0 -m 'Atlas 1.2.0'
$ git push --follow-tags
To /home/ada/server/atlas.git
   fb06623..4bbf284  main -> main
 * [new tag]         v1.2.0 -> v1.2.0
$ git log -1 --format='%h %s' v1.2.0 && git show v1.2.0:VERSION
4bbf284 Release 1.2.0
1.2.0
```

`Add the Americas` is a new, backward compatible feature, so the next version
is 1.2.0. `git status --short` printed nothing, so there was nothing
uncommitted to leave out of the release by accident. The number went into
`VERSION`, a commit recorded it, and an annotated tag named that commit. Keep the
release commit to the version change alone, so that it says exactly one thing.
`git push --follow-tags` sent the branch and, with it, the annotated tag on the
pushed commit (Chapter 43).

The tag names a commit whose `VERSION` says the same number, so the project
itself and Git agree. A project that does not want a version file can take the
number from Git instead, as the next section does.

### The version inside a build

```console
$ git describe
v1.2.0
```

On the release commit itself, `git describe` prints the tag's name. After one
more commit, `Add Antarctica`:

```console
$ git describe && git tag reviewed && git describe --tags
v1.2.0-1-ga363271
reviewed
$ git describe --tags --match 'v[0-9]*' --dirty --always
v1.2.0-1-ga363271
$ echo 'Antarctica, draft' >> maps/antarctica.txt && git describe --tags --match 'v[0-9]*' --dirty --always
v1.2.0-1-ga363271-dirty
```

`v1.2.0-1-ga363271` reads: one commit after `v1.2.0`, at commit `a363271`
(Chapter 22). Built into a program, that tells anyone exactly what they are
running. A build script that adds `--tags`, so that lightweight release tags
count too, counts every other lightweight tag as well, and a private bookmark
such as `reviewed` became the version. `--match 'v[0-9]*'` limits `describe` to
release tags. `--dirty` adds `-dirty` when files have uncommitted changes, so a build
from a changed working tree cannot pass for a release, and `--always` prints an
abbreviated hash instead of failing when there is no tag at all (Chapter 22).
The tag `reviewed` was deleted afterwards.

### Release archives

```console
$ git ls-tree --name-only v1.2.0
.gitattributes
README.md
VERSION
maps
notes
release.txt
$ git archive --prefix=atlas-1.2.0/ -o ../atlas-1.2.0.tar.gz v1.2.0 && tar -tzf ../atlas-1.2.0.tar.gz
atlas-1.2.0/
atlas-1.2.0/README.md
atlas-1.2.0/VERSION
atlas-1.2.0/maps/
atlas-1.2.0/maps/africa.txt
atlas-1.2.0/maps/americas.txt
atlas-1.2.0/maps/asia.txt
atlas-1.2.0/maps/europe.txt
atlas-1.2.0/maps/oceania.txt
atlas-1.2.0/release.txt
$ tar -xzOf ../atlas-1.2.0.tar.gz atlas-1.2.0/release.txt
Atlas v1.2.0, built from commit 4bbf284
$ gzip -dc ../atlas-1.2.0.tar.gz | git get-tar-commit-id && git rev-parse v1.2.0^{commit}
4bbf284bb7ad9b0a011acd76c57e3055dd637dcb
4bbf284bb7ad9b0a011acd76c57e3055dd637dcb
$ cat .gitattributes
release.txt export-subst
notes/ export-ignore
.gitattributes export-ignore
```

`git archive` packs the files of one commit, with no history, for someone who
will not clone (Chapter 61 covers it in full). `--prefix` puts everything in a
directory named after the release, as people expect when they unpack it, and
Git's documentation says the format follows the name given to `-o`, here
`.tar.gz`. `notes/` and `.gitattributes` are in the repository but not in the
archive, and `release.txt` was filled in: the attributes in `.gitattributes` did
both (Chapter 65). `export-ignore` leaves a path out of archives, and
`export-subst` replaces `$Format:...$` in a file with the same placeholders as
`git log --format`. The file in the repository reads
`Atlas $Format:%(describe)$, built from commit $Format:%h$`. Git's documentation
notes that only one `%(describe)` is replaced per archive, and that nothing is
replaced when the archive is made from a tree rather than a commit or a tag.

The same documentation says an archive made from a commit or a tag carries that
commit's hash, which `git get-tar-commit-id` reads back from a tar archive:
given an archive, you can find where it came from.

```console
$ git archive -o ../atlas-1.2.0.zip v1.2.0 && unzip -l ../atlas-1.2.0.zip
Archive:  ../atlas-1.2.0.zip
4bbf284bb7ad9b0a011acd76c57e3055dd637dcb
  Length      Date    Time    Name
---------  ---------- -----   ----
        8  2026-01-05 23:00   README.md
        6  2026-01-05 23:00   VERSION
        0  2026-01-05 23:00   maps/
       18  2026-01-05 23:00   maps/africa.txt
       13  2026-01-05 23:00   maps/americas.txt
        5  2026-01-05 23:00   maps/asia.txt
        7  2026-01-05 23:00   maps/europe.txt
        8  2026-01-05 23:00   maps/oceania.txt
       40  2026-01-05 23:00   release.txt
---------                     -------
      105                     9 files
```

A name ending in `.zip` makes a zip archive. In a zip, the documentation says,
the commit's hash is stored as the archive's comment, which `unzip -l` printed
under the archive's name. Every file carries the time of the release commit,
not the time the archive was made, which is also from Git's documentation.

## Release candidates

```console
$ git describe v1.1.0~1 && git describe --exclude '*-rc.*' v1.1.0~1
v1.1.0-rc.1-1-g077ab2f
v1.0.1-6-g077ab2f
$ git -c versionsort.suffix=- tag --sort=-version:refname -l 'v*'
v1.2.0
v1.1.0
v1.1.0-rc.1
v1.0.1
v1.0.0
```

A release candidate is tagged like a release: `v1.1.0-rc.1` is an annotated tag
on its own `Release 1.1.0-rc.1` commit, and `Add Oceania` came before the
release commit of 1.1.0. Because it is annotated, `git describe` counts from it; a build
made between the candidate and the release reports itself as the candidate plus
one commit. `--exclude '*-rc.*'` skips candidates, and the nearest full release
behind `Add Oceania` is `v1.0.1`, reached through the merge of `maint-1.0`.
Sorted with the setting from [How Git orders versions](#how-git-orders-versions),
newest first, the candidate stands where it belongs: after `v1.0.1`, before
`v1.1.0`.

## Maintaining an older release

A fix for 1.0 after 1.1 is out goes on `maint-1.0`, a branch started at
`v1.0.0`, and is released from there as 1.0.1, 1.0.2 and so on. The branch
was made with `git branch maint-1.0 v1.0.0` (Chapter 23). The question is how
the same fix reaches the newer releases, and there are two ways.

### Fixing the oldest branch and merging up

```console
$ git tag --contains 2859560
v1.0.1
v1.1.0
v1.1.0-rc.1
v1.2.0
```

`2859560` is `Fix the spelling of Asia`, made on `maint-1.0` and released as
1.0.1. `maint-1.0` was then merged into `main`, as the example repository shows,
so the very same commit is in every later release, and `git tag --contains`
answers "which releases have this fix?" completely (Chapter 47). Git's own
documentation of its workflow, `gitworkflows`, makes this its rule: "Always
commit your fixes to the oldest supported branch that requires them", and merge
the branches upwards from time to time.

### Backporting with cherry-pick

When the fix was made on `main` first, it is copied back instead. Ada fixed the
Europe map on `main`, commit `3cceef6`, and released it for 1.0 users:

```console
$ git switch -q maint-1.0 && git cherry-pick -x 3cceef6
[maint-1.0 2040fca] Fix the Europe map
 Date: Tue Jan 6 01:00:00 2026 +0000
 1 file changed, 1 insertion(+)
$ echo 1.0.2 > VERSION && git commit -q -am 'Release 1.0.2' && git tag -a v1.0.2 -m 'Atlas 1.0.2'
$ git log -1 --format=%B HEAD~1
Fix the Europe map

(cherry picked from commit 3cceef6cecd5afc62fefe05857b77d47c1a37ad4)

$ git tag --contains 3cceef6; echo "exit $?"
exit 0
$ git log --all --oneline --grep='cherry picked from commit 3cceef6cecd5afc62fefe05857b77d47c1a37ad4'
2040fca Fix the Europe map
$ git tag --contains 2040fca
v1.0.2
```

A cherry-pick makes a new commit, `2040fca`, with the same change and a
different hash (Chapter 32). So `git tag --contains 3cceef6` lists nothing:
no release contains the original yet, and 1.0.2 contains only the copy. `-x`
wrote the original's hash into the copy's message, and `git log --grep` finds
the copy by it, in every branch with `--all`; `git tag --contains` then names
1.0.2. Without `-x`, `git log --cherry-mark` can still pair the two by their
changes (Chapter 45). Always backport with `-x`. `gitworkflows` treats this as
the exception: a fix that turns out to be needed on an older branch after it
was made on a newer one is cherry-picked downwards.

| Compared on | Fix the oldest branch, merge up | Fix `main`, cherry-pick back |
|---|---|---|
| The fix exists as | one commit, in every release | one commit per branch it was copied to |
| `git tag --contains <fix>` | lists every release with the fix | lists only releases on the fix's own branch |
| Finding every release with the fix | one command | a search for each copy |
| In `gitworkflows` | the rule | the exception, for a fix made on the newer branch first |

## Which release is the latest

```console
$ git describe --abbrev=0 main && git describe --abbrev=0 maint-1.0
v1.2.0
v1.0.2
$ git -c versionsort.suffix=- tag --sort=-version:refname -l 'v*' | head -1
v1.2.0
$ git for-each-ref --sort=-taggerdate --count=1 --format='%(refname:short)' 'refs/tags/v*'
v1.0.2
```

"The latest release" means three different things, and with a maintenance
branch they give different answers. `git describe --abbrev=0` gives the nearest
release behind a commit, which depends on the branch: 1.2.0 on `main`, 1.0.2 on
`maint-1.0`. The highest version number is 1.2.0. The release made most recently
is 1.0.2, because it was tagged after 1.2.0. Ask the question that matches what
you need: the version a build is based on, the version to recommend, or what
happened last.

## When a release is wrong

A published release is never changed: Semantic Versioning forbids changing the
contents of a released version, and Git's documentation on re-tagging says a
tag others have fetched must not be moved behind their backs (Chapter 47).

| What happened | What to do |
|---|---|
| a release has a bug | fix it and release the next patch version, `1.2.1` |
| a release broke compatibility by accident | what the Semantic Versioning FAQ says: release a new minor version that restores compatibility, never change the released one, and tell users which version was at fault |
| the tag is on the wrong commit and nobody has fetched it | move it with `git tag -f` and push again (Chapter 47) |
| the tag is on the wrong commit and others have it | release the right commit under a new number; moving it means telling everyone ([Moving a published tag](#ch47-moving-a-published-tag)) |
| a secret was released | a new release is not enough: the secret is in the old one's history; see Chapter 37 |

## Releases on hosting services

GitHub and GitLab both offer "Releases": a page per release, with notes and
files to download. Both are built on Git tags, and their documentation says:

| Compared on | GitHub | GitLab |
|---|---|---|
| A release is | based on a Git tag | based on a Git tag; creating a release tags the code |
| A release for a new tag | the page creates the tag, on a branch you choose | the page creates the tag, from a branch or commit you choose |
| Files to download | a zip and a tarball of the repository at the tag, made automatically; up to 1000 more files of under 2 GiB each | files and links you attach |
| Also | drafts; a "pre-release" mark; a "latest" mark, set by Semantic Versioning unless chosen | deleting a release keeps its tag; deleting the tag deletes the release |

Checked on the services' documentation in September 2026; details change, and
Chapters 50 and 51 cover the services themselves. The part that is Git is the
tag, and a tag made in a web page reaches your clone like any other:

```console
$ git fetch
From /home/ada/server/atlas
 * [new tag]         v1.3.0-rc.1 -> v1.3.0-rc.1
$ git tag -l 'v1.3*'
v1.3.0-rc.1
```

Here someone else's clone had pushed the tag, standing in for a release made
in a web page. It points at a commit Ada already had, and a plain fetch still
brought it: Git's documentation says fetch follows any tag that points into the
histories being fetched, and that includes commits already there (Chapter 41).

## Handing a release to someone

| Give them | Made with | They get | Covered in |
|---|---|---|---|
| an archive | `git archive` | the files of the release, no history, no Git needed | [Release archives](#release-archives), Chapter 61 |
| a bundle | `git bundle create` | history and tags in one file, which Git's documentation describes for transfer without a server; it can be cloned or fetched from | Chapter 61 |
| a clone | `git clone` from the server | everything, and later releases with `git fetch` | Chapter 9 |

For a reader like the one this book was written for, the bundle matters: a
single file that carries a release and its history from one computer to
another, on anything that holds a file.

## The settings

| Setting | Does |
|---|---|
| `versionsort.suffix` | Endings that sort before the release; `-` puts every pre-release first ([How Git orders versions](#how-git-orders-versions)) |
| `tag.sort` | The order of `git tag`; `version:refname` for versions (Chapter 47) |
| `push.followTags` | Push annotated tags along with the commits they tag (Chapter 43) |
| `tag.gpgSign` | Sign every tag, so users can check a release came from you (Chapter 68) |
| `tar.<format>.command` | Another compression for `git archive` (Chapter 61) |
