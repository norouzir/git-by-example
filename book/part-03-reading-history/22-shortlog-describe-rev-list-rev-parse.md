# Chapter 22. shortlog, describe, rev-list, rev-parse

## What it is

These commands turn history into something shorter than `git log`: a summary, a
name, a list of hashes, a list of refs.

| Command | The question its plain form answers |
|---|---|
| `git shortlog` | Who made which commits? It groups commit titles by author, the way release notes list them |
| `git check-mailmap` | Which name and address will Git show for this person? It tests the `.mailmap` file, which merges one person's old names and addresses into one |
| `git describe` | What is a readable name for this commit? It names it after the nearest tag, such as `v1.1-4-gf8b359d` |
| `git rev-list` | Which commits does this range contain? It prints bare hashes, one per line |
| `git rev-parse` | What hash does this name stand for, and where is the repository? |
| `git for-each-ref` | Which refs are there? It prints them in any format, sorted and filtered |

`git log` (Chapter 17) can answer some of the same questions, but its output is
meant for reading. Git's documentation files `rev-list`, `rev-parse` and
`for-each-ref` under *plumbing*: commands meant to be called by scripts, whose
output is simple to parse. `shortlog` and `describe` are ordinary commands, and
`check-mailmap` is a helper for testing one file.

A *ref* (Chapter 7) is a name that points at an object: a branch, a tag, or a
remote-tracking branch such as `origin/main`. An *annotated* tag is a tag object
with its own message, date and tagger; a *lightweight* tag is only a name for a
commit (Chapter 6). Several commands here treat the two differently.

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What are `shortlog`, `describe`, `rev-list`, `rev-parse` and `for-each-ref` for?](#what-it-is)
- [Why use these instead of `git log`?](#what-it-is)

**[Synopsis](#synopsis)**

- [What can I type after each of these commands?](#synopsis)

**[Options at a glance](#options-at-a-glance)**

- [Is there a list of every option, and where each is explained?](#options-at-a-glance)
- [Which fields can I put in a `for-each-ref` format?](#fields-of-git-for-each-ref)

**[The example history](#the-example-history)**

- [What history do the examples use?](#the-example-history)

**[Summarising commits with shortlog](#summarising-commits-with-shortlog)**

- [How do I list who made which commits, for release notes?](#reading-shortlog-s-output)
- [How do I get only the number of commits per person, biggest first?](#counts-order-and-addresses)
- [How do I show the hash or the whole message instead of the title?](#what-each-commit-line-shows)
- [How do I stop long lines in shortlog output running off the screen?](#what-each-commit-line-shows)
- [How do I count commits by committer, or by reviewer?](#grouping-by-something-other-than-the-author)
- [How do I count co-authors as well as authors?](#grouping-by-something-other-than-the-author)
- [How do I count commits per day or per hour?](#grouping-by-something-other-than-the-author)
- [How do I summarise only one release, one directory, or every branch?](#which-commits-are-summarised)
- [I ran `git shortlog` in a script and it printed nothing. Why?](#when-shortlog-reads-standard-input)
- [Can I feed `git log` output into `git shortlog`?](#when-shortlog-reads-standard-input)

**[The .mailmap file](#the-mailmap-file)**

- [The same person appears twice under different names. How do I merge them?](#what-a-mailmap-changes)
- [What can I write in a `.mailmap` file?](#the-four-kinds-of-line)
- [Does case matter in a `.mailmap` file?](#testing-a-mailmap-with-check-mailmap)
- [How do I check what a mailmap does to one name without running a whole log?](#testing-a-mailmap-with-check-mailmap)
- [Can I keep the mailmap outside the working tree, or read it from a commit?](#mailmaps-kept-elsewhere)
- [When two mailmaps disagree, which one wins?](#mailmaps-kept-elsewhere)
- [Why does a bare repository use a mailmap I never configured?](#mailmaps-kept-elsewhere)

**[Naming a commit with describe](#naming-a-commit-with-describe)**

- [What does a name such as `v1.1-4-gf8b359d` mean?](#reading-describe-s-name)
- [Why does `git describe` ignore my tag?](#which-tags-describe-may-use)
- [How do I make it use only release tags, or leave some tags out?](#which-tags-describe-may-use)
- [Why did `describe` pick a tag that is not the nearest one?](#how-describe-chooses-a-tag)
- [How do I see how `describe` searched?](#how-describe-chooses-a-tag)
- [How do I get only the tag name, or always the long form?](#changing-the-shape-of-the-name)
- [How do I test whether a commit is exactly a tagged release?](#changing-the-shape-of-the-name)
- [Which release first contained this commit?](#the-first-tag-that-contains-a-commit)
- [How do I mark a build made from uncommitted changes?](#uncommitted-changes-and-a-damaged-repository)
- [What does `--broken` do that `--dirty` does not?](#uncommitted-changes-and-a-damaged-repository)
- [Can `describe` name a file, or a directory?](#blobs-trees-and-history-without-tags)
- [What does "No names found, cannot describe anything" mean?](#blobs-trees-and-history-without-tags)

**[Listing commits with rev-list](#listing-commits-with-rev-list)**

- [What is the difference between `git rev-list` and `git log --format=%H`?](#rev-list-and-log)
- [How do I count the commits in a range, or on each side of two branches?](#counting-commits)
- [How do I leave commits that were cherry-picked out of a count?](#counting-commits)
- [How do I print commit details, or the raw commit, from `rev-list`?](#commit-details)
- [How do I list the commits after or before a moment, given as a timestamp?](#commit-details)
- [How do I list every file and directory object a range needs?](#listing-objects)
- [How do I leave out large files, or everything below some depth, from an object list?](#filtering-objects)
- [How do I find objects that are missing from my repository?](#missing-objects)
- [Why did a plain `rev-list` download objects in a partial clone?](#missing-objects)
- [How much disk space does a branch take?](#size-speed-and-progress)
- [How do I see progress on a long `rev-list`?](#size-speed-and-progress)
- [Which commit would bisect test next?](#bisection-helpers)

**[Resolving names with rev-parse](#resolving-names-with-rev-parse)**

- [How do I get the full hash of a branch, tag or `HEAD~2`?](#names-to-hashes)
- [How do I get a short hash, and how short can it be?](#names-to-hashes)
- [How do I check in a script that a name exists?](#checking-a-name-in-a-script)
- [A variable in my script held `--all` and `rev-parse` printed seven hashes. How do I prevent that?](#checking-a-name-in-a-script)
- [How do I get the branch name instead of the hash?](#short-and-symbolic-names)
- [What is the difference between `--symbolic`, `--symbolic-full-name` and `--abbrev-ref`?](#short-and-symbolic-names)
- [What does `rev-parse` print for a range such as `v1.0..HEAD`?](#ranges-and-defaults)
- [How do I list every object whose hash starts with some digits?](#ranges-and-defaults)
- [How do I list all branches, tags or refs matching a pattern?](#sets-of-refs)

**[Asking rev-parse about the repository](#asking-rev-parse-about-the-repository)**

- [How do I find the top directory of the repository, or the `.git` directory?](#paths-inside-the-repository)
- [How do I tell where I am relative to the top?](#paths-inside-the-repository)
- [How do I find a file inside `.git` without guessing its location?](#paths-inside-the-repository)
- [How do I test whether I am in a working tree, a `.git` directory, or a bare repository?](#which-kind-of-repository)
- [How do I tell whether a repository is shallow?](#which-kind-of-repository)
- [In a linked worktree, where is its `.git`?](#which-kind-of-repository)
- [Which hash algorithm and ref storage does the repository use?](#formats-environment-and-outside-a-repository)
- [What happens when I run `rev-parse` outside a repository?](#formats-environment-and-outside-a-repository)

**[Sorting and quoting arguments with rev-parse](#sorting-and-quoting-arguments-with-rev-parse)**

- [How does a script separate revisions, options and paths in its arguments?](#revisions-options-and-paths)
- [How do I quote arguments safely for the shell?](#revisions-options-and-paths)
- [How do I turn a date such as "yesterday" into a timestamp?](#dates-as-timestamps)
- [How do I give my own shell script options like a Git command's?](#parsing-options-in-a-shell-script)

**[Listing refs with for-each-ref](#listing-refs-with-for-each-ref)**

- [How do I list only tags, or refs matching a pattern?](#choosing-refs)
- [How do I page through a very long list of refs?](#choosing-refs)
- [How do I print a ref's short name, its hash, or the object type?](#names-and-objects)
- [How do I print the object behind an annotated tag rather than the tag?](#names-and-objects)
- [How do I print who made a commit or tag, and when?](#people-and-dates)
- [How do I print a commit's title, body or trailers for each branch?](#messages)
- [How do I show which branches are ahead of or behind their upstream?](#upstream-and-related-refs)
- [How do I find which branch another branch was started from?](#upstream-and-related-refs)
- [How do I print something only for some refs, or line output up in columns?](#conditions-alignment-and-colour)
- [Why is `for-each-ref` output coloured even with `color.ui=never`?](#conditions-alignment-and-colour)
- [How do I read `for-each-ref` output safely in a shell, Perl, Python or Tcl script?](#quoting-for-other-languages)
- [How do I list the newest tag first, or sort `v1.10` after `v1.9`?](#sorting-refs)
- [Why does a sort on a formatted date come out in a strange order?](#sorting-refs)
- [How do I list branches already merged, or tags containing a commit?](#filtering-refs-by-history)
- [I wrote `--merged` before `--format` and got "malformed object name". Why?](#filtering-refs-by-history)

**[These commands and their neighbours](#these-commands-and-their-neighbours)**

- [Should I use `for-each-ref`, `show-ref`, `git branch` or `git tag`?](#these-commands-and-their-neighbours)
- [Should I use `rev-list`, `log`, `rev-parse` or `describe`?](#these-commands-and-their-neighbours)
- [What is the difference between `git describe --contains` and `git name-rev`?](#these-commands-and-their-neighbours)

**[The settings](#the-settings)**

- [Which settings change what these commands do?](#the-settings)

</details>

## Synopsis

```
git shortlog [<options>] [<revision-range>] [[--] <path>...]
git log --pretty=short | git shortlog [<options>]

git check-mailmap [<options>] <contact>...

git describe [--all] [--tags] [--contains] [--abbrev=<n>] [<commit-ish>...]
git describe [--all] [--tags] [--contains] [--abbrev=<n>] --dirty[=<mark>]
git describe <blob>

git rev-list [<options>] <commit>... [--] [<path>...]

git rev-parse [<options>] <arg>...
git rev-parse --parseopt [<options>] -- [<args>...]
git rev-parse --sq-quote [<arg>...]

git for-each-ref [--count=<count>] [--shell|--perl|--python|--tcl]
                 [(--sort=<key>)...] [--format=<format>]
                 [--include-root-refs] [--points-at=<object>]
                 [--merged[=<object>]] [--no-merged[=<object>]]
                 [--contains[=<object>]] [--no-contains[=<object>]]
                 [(--exclude=<pattern>)...] [--start-after=<marker>]
                 [ --stdin | (<pattern>...)]
```

| Part | Means |
|---|---|
| `<revision-range>` | Which commits, such as `v1.0..HEAD` (Chapter 18); `HEAD` if left out |
| `<path>` | Only commits that change these paths |
| `<contact>` | A person as Git stores one: `Name <address>`, `<address>`, or a bare `address` |
| `<commit-ish>` | Anything that leads to a commit: a hash, a branch, a tag, `HEAD~2` |
| `<blob>` | A file's contents, named by its hash |
| `<commit>...` | Commits to start from; `^<commit>` excludes a commit and its ancestors |
| `<arg>` | Names, options and paths for `rev-parse` to resolve or sort |
| `<pattern>` | A ref name, the start of one up to a `/` (`refs/tags`), or a glob, a pattern with `*` (`refs/tags/v1.*`) |
| `<key>` | A field to sort by, such as `refname` or `-creatordate` |
| `<format>` | Text with fields such as `%(refname:short)` |
| `<object>` | A commit or other object to filter refs by |

| Command | Does |
|---|---|
| `git shortlog` | Commit titles grouped by author |
| `git log --pretty=short \| git shortlog` | The same, from log output on standard input |
| `git check-mailmap <contact>` | The name and address the mailmap turns `<contact>` into |
| `git describe [<commit-ish>]` | A name based on the nearest tag behind the commit, `HEAD` by default |
| `git describe --dirty` | The same for `HEAD`, marked if the working tree has changes |
| `git describe <blob>` | A commit and a path where that file content appears |
| `git rev-list <commit>...` | The hashes of the commits reachable from these, newest first |
| `git rev-parse <arg>...` | Each name turned into a hash; many options ask about the repository instead |
| `git rev-parse --parseopt` | Parse a shell script's options (a mode of its own) |
| `git rev-parse --sq-quote` | Quote arguments for the shell (a mode of its own) |
| `git for-each-ref [<pattern>...]` | Every ref, or those matching, one line each |

## Options at a glance

### Options of git shortlog

| Option | Does | Covered in |
|---|---|---|
| `-n`, `--numbered` | Sort people by number of commits instead of by name | [Counts, order and addresses](#counts-order-and-addresses) |
| `-s`, `--summary` | Only the count for each person | [Counts, order and addresses](#counts-order-and-addresses) |
| `-e`, `--email` | Show addresses too | [Counts, order and addresses](#counts-order-and-addresses) |
| `--format[=<format>]` | Show something other than the title for each commit | [What each commit line shows](#what-each-commit-line-shows) |
| `-w[<width>[,<indent1>[,<indent2>]]]` | Wrap each commit's line | [What each commit line shows](#what-each-commit-line-shows) |
| `--group=author` | Group by author, the default | [Grouping by something other than the author](#grouping-by-something-other-than-the-author) |
| `--group=committer`, `-c`, `--committer` | Group by committer | [Grouping by something other than the author](#grouping-by-something-other-than-the-author) |
| `--group=trailer:<field>` | Group by the people in a trailer such as `Reviewed-by` | [Grouping by something other than the author](#grouping-by-something-other-than-the-author) |
| `--group=format:<format>` | Group by any text a `git log` format produces | [Grouping by something other than the author](#grouping-by-something-other-than-the-author) |
| `--date=<format>` | How `%ad` and similar print, for `--group=format:` | [Grouping by something other than the author](#grouping-by-something-other-than-the-author) |
| `--all`, `--no-merges` and the other options that choose commits | As in `git log`; Chapter 17 | [Which commits are summarised](#which-commits-are-summarised) |

### Options of git check-mailmap

| Option | Does | Covered in |
|---|---|---|
| `--stdin` | Read more contacts from standard input, one per line | [Testing a mailmap with check-mailmap](#testing-a-mailmap-with-check-mailmap) |
| `--mailmap-file=<file>` | Also read this mailmap file; its entries win | [Testing a mailmap with check-mailmap](#testing-a-mailmap-with-check-mailmap) |
| `--mailmap-blob=<blob>` | Also read a mailmap stored in the repository | [Mailmaps kept elsewhere](#mailmaps-kept-elsewhere) |

### Options of git describe

| Option | Does | Covered in |
|---|---|---|
| `--tags` | Lightweight tags count too | [Which tags describe may use](#which-tags-describe-may-use) |
| `--all` | Any ref counts: branches and remote-tracking branches too | [Which tags describe may use](#which-tags-describe-may-use) |
| `--match <pattern>`, `--no-match` | Only tags matching a glob; clear the list | [Which tags describe may use](#which-tags-describe-may-use) |
| `--exclude <pattern>`, `--no-exclude` | Leave out tags matching a glob; clear the list | [Which tags describe may use](#which-tags-describe-may-use) |
| `--first-parent` | Follow only the first parent of merges | [How describe chooses a tag](#how-describe-chooses-a-tag) |
| `--candidates=<n>` | Stop searching after finding `<n>` tags; 10 by default | [How describe chooses a tag](#how-describe-chooses-a-tag) |
| `--debug` | Explain the search on standard error | [How describe chooses a tag](#how-describe-chooses-a-tag) |
| `--long` | Always `<tag>-<count>-g<hash>`, even on a tagged commit | [Changing the shape of the name](#changing-the-shape-of-the-name) |
| `--abbrev=<n>` | Hash digits; `0` prints only the tag | [Changing the shape of the name](#changing-the-shape-of-the-name) |
| `--exact-match` | Succeed only if a tag points at the commit | [Changing the shape of the name](#changing-the-shape-of-the-name) |
| `--contains` | The first tag that contains the commit, instead of the last before it | [The first tag that contains a commit](#the-first-tag-that-contains-a-commit) |
| `--dirty[=<mark>]` | Add `-dirty`, or `<mark>`, if the working tree has changes | [Uncommitted changes and a damaged repository](#uncommitted-changes-and-a-damaged-repository) |
| `--broken[=<mark>]` | Like `--dirty`, but add `-broken` instead of failing on a damaged repository | [Uncommitted changes and a damaged repository](#uncommitted-changes-and-a-damaged-repository) |
| `--always` | Print a short hash when there is no tag to use | [Blobs, trees and history without tags](#blobs-trees-and-history-without-tags) |

### Options of git rev-list

`git rev-list` accepts every option `git log` uses to choose and order commits,
such as `--all`, `--no-merges`, `--author`, `--since`, `-n` and `--reverse`, and
its formatting options, such as `--format` and `--parents`. Chapter 17 teaches
them; the table lists what is particular to `rev-list`.

| Option | Does | Covered in |
|---|---|---|
| `--count` | Print how many commits, not the commits | [Counting commits](#counting-commits) |
| `--left-right` with `--count` | Two counts, one for each side of `A...B` | [Counting commits](#counting-commits) |
| `--cherry-mark` with `--count` | A third count, for commits with an equivalent on the other side | [Counting commits](#counting-commits) |
| `--timestamp` | The commit time as a number before each hash | [Commit details](#commit-details) |
| `--no-commit-header`, `--commit-header` | Leave out, or keep, the `commit <hash>` line before a custom format | [Commit details](#commit-details) |
| `--header` | Each whole raw commit, ending in a NUL byte | [Commit details](#commit-details) |
| `--max-age=<timestamp>`, `--min-age=<timestamp>` | Commits made after, or before, a time given in seconds since 1970 | [Commit details](#commit-details) |
| `--objects` | The trees and files the commits need, as well as the commits | [Listing objects](#listing-objects) |
| `--no-object-names`, `--object-names` | Leave out, or keep, the path after each object | [Listing objects](#listing-objects) |
| `--in-commit-order` | Each commit's objects straight after it | [Listing objects](#listing-objects) |
| `-z` | Separate everything with NUL bytes, paths as `path=<path>` | [Listing objects](#listing-objects) |
| `--objects-edge` | Also the excluded commits at the edge, marked `-` | [Listing objects](#listing-objects) |
| `--objects-edge-aggressive` | The same, searching harder for edge commits | [Listing objects](#listing-objects) |
| `--filter=<filter-spec>` | Leave some objects out; the forms are in the section | [Filtering objects](#filtering-objects) |
| `--no-filter` | Cancel an earlier `--filter` | [Filtering objects](#filtering-objects) |
| `--filter-print-omitted` | Also list what the filter left out, marked `~` | [Filtering objects](#filtering-objects) |
| `--filter-provided-objects` | Apply the filter to objects named on the command line too | [Filtering objects](#filtering-objects) |
| `--missing=error` | Stop at a missing object, the default | [Missing objects](#missing-objects) |
| `--missing=allow-any` | Carry on past missing objects silently | [Missing objects](#missing-objects) |
| `--missing=allow-promisor` | Carry on only past objects a partial clone expects to be missing | [Missing objects](#missing-objects) |
| `--missing=print` | Carry on, and list missing objects marked `?` | [Missing objects](#missing-objects) |
| `--missing=print-info` | The same, with the path and type of each | [Missing objects](#missing-objects) |
| `--exclude-promisor-objects` | Do not walk into objects a partial clone fetched from its remote | [Missing objects](#missing-objects) |
| `--disk-usage`, `--disk-usage=human` | Bytes the selected objects take on disk | [Size, speed and progress](#size-speed-and-progress) |
| `--quiet` | Print nothing; for the exit code | [Size, speed and progress](#size-speed-and-progress) |
| `--unpacked` | Only objects not yet in a pack | [Size, speed and progress](#size-speed-and-progress) |
| `--indexed-objects` | Start from every tree and file in the index | [Size, speed and progress](#size-speed-and-progress) |
| `--use-bitmap-index` | Go faster using a pack's record of which objects each commit reaches, if it has one | [Size, speed and progress](#size-speed-and-progress) |
| `--progress=<header>` | Report progress on standard error | [Size, speed and progress](#size-speed-and-progress) |
| `--bisect` | The commit halfway through the range | [Bisection helpers](#bisection-helpers) |
| `--bisect-vars` | The same, as shell variables | [Bisection helpers](#bisection-helpers) |
| `--bisect-all` | Every commit, by distance from the ends | [Bisection helpers](#bisection-helpers) |

<!-- no-example: --objects-edge-aggressive
     tested on this history against --objects-edge with the same range, and
     the output was identical; it only differs in shallow repositories, where
     git pack-objects uses it -->

### Options of git rev-parse

| Option | Does | Covered in |
|---|---|---|
| `--short[=<length>]` | A short hash, at least 4 digits | [Names to hashes](#names-to-hashes) |
| `--verify` | Exactly one name, which must exist, or fail | [Checking a name in a script](#checking-a-name-in-a-script) |
| `-q`, `--quiet` | With `--verify`, fail without a message | [Checking a name in a script](#checking-a-name-in-a-script) |
| `--end-of-options` | Nothing after this is an option | [Checking a name in a script](#checking-a-name-in-a-script) |
| `--symbolic` | Print names as given, not as hashes | [Short and symbolic names](#short-and-symbolic-names) |
| `--symbolic-full-name` | Print refs as full names such as `refs/heads/main`; drop other names | [Short and symbolic names](#short-and-symbolic-names) |
| `--abbrev-ref[=(strict\|loose)]` | The shortest unambiguous name of a ref | [Short and symbolic names](#short-and-symbolic-names) |
| `--not` | Put `^` in front of each name, or take it away | [Ranges and defaults](#ranges-and-defaults) |
| `--default <arg>` | Use `<arg>` when no name is given | [Ranges and defaults](#ranges-and-defaults) |
| `--disambiguate=<prefix>` | Every object whose hash starts with `<prefix>` | [Ranges and defaults](#ranges-and-defaults) |
| `--output-object-format=(sha1\|sha256\|storage)` | Print hashes in this algorithm | [Ranges and defaults](#ranges-and-defaults) |
| `--all` | Every ref | [Sets of refs](#sets-of-refs) |
| `--branches[=<pattern>]`, `--tags[=<pattern>]`, `--remotes[=<pattern>]` | Every branch, tag or remote-tracking branch, or those matching | [Sets of refs](#sets-of-refs) |
| `--glob=<pattern>` | Refs matching a glob | [Sets of refs](#sets-of-refs) |
| `--exclude=<glob-pattern>` | Leave refs out of the next set | [Sets of refs](#sets-of-refs) |
| `--exclude-hidden=(fetch\|receive\|uploadpack)` | Leave out refs a server hides; Chapter 17 explains the values | [Sets of refs](#sets-of-refs) |
| `--show-toplevel` | The top directory of the working tree | [Paths inside the repository](#paths-inside-the-repository) |
| `--git-dir` | The `.git` directory | [Paths inside the repository](#paths-inside-the-repository) |
| `--absolute-git-dir` | The same, always absolute | [Paths inside the repository](#paths-inside-the-repository) |
| `--show-prefix` | The current directory, relative to the top | [Paths inside the repository](#paths-inside-the-repository) |
| `--show-cdup` | The way back up to the top, such as `../` | [Paths inside the repository](#paths-inside-the-repository) |
| `--path-format=(absolute\|relative)` | How the path options after it print | [Paths inside the repository](#paths-inside-the-repository) |
| `--prefix <arg>` | Resolve paths as if run from the subdirectory `<arg>` | [Paths inside the repository](#paths-inside-the-repository) |
| `--git-path <path>` | Where `<path>` inside `.git` really is | [Paths inside the repository](#paths-inside-the-repository) |
| `--is-inside-work-tree`, `--is-inside-git-dir` | `true` or `false` | [Paths inside the repository](#paths-inside-the-repository) |
| `--is-bare-repository`, `--is-shallow-repository` | `true` or `false` | [Which kind of repository](#which-kind-of-repository) |
| `--resolve-git-dir <path>` | The repository `<path>` is, or points to | [Which kind of repository](#which-kind-of-repository) |
| `--git-common-dir` | In a linked worktree, the main repository's `.git` | [Which kind of repository](#which-kind-of-repository) |
| `--show-object-format[=(storage\|input\|output\|compat)]` | The hash algorithm | [Formats, environment and outside a repository](#formats-environment-and-outside-a-repository) |
| `--show-ref-format` | How refs are stored | [Formats, environment and outside a repository](#formats-environment-and-outside-a-repository) |
| `--local-env-vars` | The environment variables that belong to one repository | [Formats, environment and outside a repository](#formats-environment-and-outside-a-repository) |
| `--shared-index-path` | The shared file, when the index is split into two files | [Formats, environment and outside a repository](#formats-environment-and-outside-a-repository) |
| `--show-superproject-working-tree` | The repository this one is a submodule of (Chapter 57) | [Formats, environment and outside a repository](#formats-environment-and-outside-a-repository) |
| `--sq-quote` | Only quote the arguments for the shell | [Formats, environment and outside a repository](#formats-environment-and-outside-a-repository) |
| `--revs-only`, `--no-revs` | Keep only what is meant for `rev-list`, or only the rest | [Revisions, options and paths](#revisions-options-and-paths) |
| `--flags`, `--no-flags` | Keep only options, or leave them out | [Revisions, options and paths](#revisions-options-and-paths) |
| `--sq` | Everything on one line, quoted for the shell | [Revisions, options and paths](#revisions-options-and-paths) |
| `--since=<datestring>`, `--after=<datestring>` | Turn a date into `--max-age=<timestamp>` | [Dates as timestamps](#dates-as-timestamps) |
| `--until=<datestring>`, `--before=<datestring>` | Turn a date into `--min-age=<timestamp>` | [Dates as timestamps](#dates-as-timestamps) |
| `--parseopt` | Parse options for a shell script | [Parsing options in a shell script](#parsing-options-in-a-shell-script) |
| `--stuck-long` | With `--parseopt`, print long option names, values attached | [Parsing options in a shell script](#parsing-options-in-a-shell-script) |
| `--keep-dashdash` | With `--parseopt`, keep the first `--` | [Parsing options in a shell script](#parsing-options-in-a-shell-script) |
| `--stop-at-non-option` | With `--parseopt`, stop at the first argument that is not an option | [Parsing options in a shell script](#parsing-options-in-a-shell-script) |

### Options of git for-each-ref

| Option | Does | Covered in |
|---|---|---|
| `<pattern>...` | Only refs matching | [Choosing refs](#choosing-refs) |
| `--exclude=<pattern>` | Leave out refs matching | [Choosing refs](#choosing-refs) |
| `--stdin` | Read the patterns from standard input | [Choosing refs](#choosing-refs) |
| `--count=<count>` | Stop after `<count>` refs | [Choosing refs](#choosing-refs) |
| `--start-after=<marker>` | Start after this ref name, for paging | [Choosing refs](#choosing-refs) |
| `--include-root-refs` | Also `HEAD` and other refs outside `refs/` | [Choosing refs](#choosing-refs) |
| `--format=<format>` | What to print for each ref | [Names and objects](#names-and-objects) |
| `--omit-empty` | No blank line for a ref whose format came out empty | [Conditions, alignment and colour](#conditions-alignment-and-colour) |
| `--color[=<when>]` | Whether `%(color:...)` in the format takes effect | [Conditions, alignment and colour](#conditions-alignment-and-colour) |
| `--shell` (or `-s`), `--perl` (or `-p`), `--python`, `--tcl` | Quote each field for that language | [Quoting for other languages](#quoting-for-other-languages) |
| `--sort=<key>` | Sort by a field; `-` in front for descending | [Sorting refs](#sorting-refs) |
| `--ignore-case` | Sort and match patterns without regard to case | [Sorting refs](#sorting-refs) |
| `--merged[=<object>]`, `--no-merged[=<object>]` | Refs whose tip is, or is not, in `<object>`'s history | [Filtering refs by history](#filtering-refs-by-history) |
| `--contains[=<object>]`, `--no-contains[=<object>]` | Refs whose history has, or lacks, `<object>` | [Filtering refs by history](#filtering-refs-by-history) |
| `--points-at=<object>` | Refs that point at `<object>` | [Filtering refs by history](#filtering-refs-by-history) |

### Fields of git for-each-ref

Each field is written `%(<name>)` in a format, and most can also be a sort key.
A field that does not apply to a ref's object prints nothing rather than failing.
Git's documentation says `git branch --format` and `git tag --format` take the same
fields.

| Field | Prints | Covered in |
|---|---|---|
| `%(refname)`, with `:short`, `:lstrip=<n>`, `:rstrip=<n>`, `:strip=<n>` | The ref's name, whole or cut | [Names and objects](#names-and-objects) |
| `%(objectname)`, with `:short` or `:short=<length>` | The hash the ref points at | [Names and objects](#names-and-objects) |
| `%(objecttype)` | `commit`, `tag`, `tree` or `blob` | [Names and objects](#names-and-objects) |
| `%(objectsize)`, `%(objectsize:disk)` | Size in bytes, or on disk | [Names and objects](#names-and-objects) |
| `%(deltabase)` | The object this one is stored as a difference from, or zeros | [Names and objects](#names-and-objects) |
| `%(tree)`, `%(parent)`, with `:short` | A commit's tree and parents | [Names and objects](#names-and-objects) |
| `%(object)`, `%(type)`, `%(tag)` | An annotated tag's target, its type, and the tag's own name | [Names and objects](#names-and-objects) |
| `%(*<field>)` | The field for the object an annotated tag points at | [Names and objects](#names-and-objects) |
| `%(author)`, `%(committer)`, `%(tagger)` | Name, address and time | [People and dates](#people-and-dates) |
| `%(authorname)`, `%(authoremail)`, `%(authordate)`, and the same for `committer` and `tagger` | One part; `email` takes `:trim`, `:localpart` and `:mailmap` | [People and dates](#people-and-dates) |
| `%(creator)`, `%(creatordate)` | The tagger of an annotated tag, else the committer | [People and dates](#people-and-dates) |
| `%(<date field>:<format>)` | A date in any `--date` format (Chapter 17) | [People and dates](#people-and-dates) |
| `%(contents)`, `%(contents:subject)`, `%(contents:body)`, `%(contents:signature)` | The message, or a part | [Messages](#messages) |
| `%(subject)`, `%(subject:sanitize)`, `%(body)` | The title, as a file name, or the rest | [Messages](#messages) |
| `%(contents:size)`, `%(contents:lines=<n>)` | Message size, or its first lines | [Messages](#messages) |
| `%(trailers)`, with the options of Chapter 17 | The trailers | [Messages](#messages) |
| `%(raw)`, `%(raw:size)` | The object exactly as stored | [Messages](#messages) |
| `%(signature)`, `%(signature:grade)` and the other `signature` parts | A commit's signature; Chapter 68 | [Messages](#messages) |
| `%(upstream)`, `%(push)`, with `:short`, `:track`, `:trackshort`, `:nobracket`, `:remotename`, `:remoteref` | The branch's upstream or push destination, and how far apart | [Upstream and related refs](#upstream-and-related-refs) |
| `%(ahead-behind:<commit-ish>)` | Commits ahead of and behind another commit | [Upstream and related refs](#upstream-and-related-refs) |
| `%(is-base:<commit-ish>)` | Marks the ref another branch most likely started from | [Upstream and related refs](#upstream-and-related-refs) |
| `%(describe)`, with `tags`, `abbrev`, `match`, `exclude` | A `git describe` name | [Upstream and related refs](#upstream-and-related-refs) |
| `%(worktreepath)` | Where the branch is checked out | [Upstream and related refs](#upstream-and-related-refs) |
| `%(symref)` | What a symbolic ref, such as `HEAD`, points to (Chapter 7) | [Upstream and related refs](#upstream-and-related-refs) |
| `%(HEAD)` | `*` for the current branch, a space otherwise | [Conditions, alignment and colour](#conditions-alignment-and-colour) |
| `%(if)`, `%(then)`, `%(else)`, `%(end)`, with `:equals=` or `:notequals=` | Print part of the format only sometimes | [Conditions, alignment and colour](#conditions-alignment-and-colour) |
| `%(align:<width>,<position>)` ... `%(end)` | Pad to a width, left, right or middle | [Conditions, alignment and colour](#conditions-alignment-and-colour) |
| `%(color:<colour>)` | Change colour | [Conditions, alignment and colour](#conditions-alignment-and-colour) |
| `%%`, `%<hex>` | A `%`, or the character with that code, such as `%09` for a tab | [Messages](#messages) |

## The example history

```console
$ git log --oneline --graph --all --decorate
* 0565da9 (experiment) Try a faster tokenizer
* f8b359d (HEAD -> main) Add a mailmap
*   aae0bb0 Merge the grammar
|\  
| * f6c84b1 Add the first rule
| * e579771 (tag: grammar-0.1) Start a grammar
* | 5495411 (tag: v1.1) Speed up parsing
* | 2971fe1 (tag: v1.1-rc1) [PATCH] Document the lexer
* | 741cc7b Add a lexer
|/  
* 7c17193 (tag: v1.0, origin/main) Fix a crash on empty input
* 7373872 Add tests
* c38cfeb Add the parser
```

A parser written by Ada Lovelace, Grace Hopper and Alan Turing. The details that
matter later:

| Commit | Detail |
|---|---|
| `Fix a crash on empty input` | Ada made it under an old name and address, `A. Lovelace <ada@old.example>`; it has a `Reviewed-by: Grace Hopper` trailer |
| `Add tests` | Has a `Reviewed-by: Ada Lovelace` trailer |
| `Add a lexer` | By Alan, with `Co-authored-by: Grace Hopper` and `Reviewed-by: Ada Lovelace` |
| `[PATCH] Document the lexer` | Grace wrote it and Ada committed it, so the author and committer differ |
| `Speed up parsing` | Has a long message body |
| `Add a mailmap` | Adds `.mailmap`, which merges Ada's old identity into the new one |

`v1.0`, `v1.1` and `grammar-0.1` are annotated tags; `v1.1-rc1` is a lightweight
tag. `origin/main` is where `main` was when it was last pushed. `experiment` has
one commit that `main` does not.

## Summarising commits with shortlog

### Reading shortlog's output

```console
$ git shortlog HEAD
Ada Lovelace (5):
      Add the parser
      Fix a crash on empty input
      Speed up parsing
      Merge the grammar
      Add a mailmap

Alan Turing (2):
      Add a lexer
      Start a grammar

Grace Hopper (3):
      Add tests
      Document the lexer
      Add the first rule

```

Each author, sorted by name, with the number of commits and each title, oldest
first. `Fix a crash on empty input` is under Ada Lovelace although it was made as
`A. Lovelace`, because the `.mailmap` file maps that name
([The .mailmap file](#the-mailmap-file)). `[PATCH]` was taken off the front of
`Document the lexer`, which Git's documentation says shortlog always does, and
the merge commit counts like any other.

Why `HEAD` is typed out is explained in
[When shortlog reads standard input](#when-shortlog-reads-standard-input).

### Counts, order and addresses

```console
$ git shortlog -s HEAD
     5	Ada Lovelace
     2	Alan Turing
     3	Grace Hopper
$ git shortlog -s -n HEAD
     5	Ada Lovelace
     3	Grace Hopper
     2	Alan Turing
$ git shortlog -s -n -e HEAD
     5	Ada Lovelace <ada@example.com>
     3	Grace Hopper <grace@example.com>
     2	Alan Turing <alan@example.com>
```

`-s` keeps only the counts, `-n` sorts by count, most commits first, and `-e`
adds each address. The count and the name are separated by a tab. Together they
answer "who contributed most?"

### What each commit line shows

```console
$ git shortlog --format='[%h] %s' v1.0
Ada Lovelace (2):
      [c38cfeb] Add the parser
      [7c17193] Fix a crash on empty input

Grace Hopper (1):
      [7373872] Add tests

$ git shortlog --format='%s: %b' -1 v1.1
Ada Lovelace (1):
      Speed up parsing: This commit message has a body that is long enough to be wrapped by shortlog when it is asked to show whole messages.

```

`--format` takes any `git log` format (Chapter 17). The body is joined onto one
line, which can get long. `-w` wraps it:

```console
$ git shortlog -w --format='%s: %b' -1 v1.1
Ada Lovelace (1):
      Speed up parsing: This commit message has a body that is long enough
         to be wrapped by shortlog when it is asked to show whole messages.

$ git shortlog -w40,2,4 --format='%s: %b' -1 v1.1
Ada Lovelace (1):
  Speed up parsing: This commit message
    has a body that is long enough to be
    wrapped by shortlog when it is asked
    to show whole messages.

$ git shortlog -w0,2,4 --format='%s: %b' -1 v1.1
Ada Lovelace (1):
  Speed up parsing: This commit message has a body that is long enough to be wrapped by shortlog when it is asked to show whole messages.

```

| Command | Wraps at | First line indented | Later lines indented |
|---|---|---|---|
| `git shortlog` | never | 6 spaces | not wrapped |
| `git shortlog -w` | 76 columns | 6 | 9 |
| `git shortlog -w40,2,4` | 40 columns | 2 | 4 |
| `git shortlog -w0,2,4` | never; `0` only changes the indent | 2 | not wrapped |

The numbers go straight after `-w`, with no space. Tried with a space,
`git shortlog -w 40 HEAD` failed, because `40` was read as a revision.

### Grouping by something other than the author

```console
$ git shortlog -s -c HEAD
     6	Ada Lovelace
     2	Alan Turing
     2	Grace Hopper
$ git shortlog -s --committer HEAD
     6	Ada Lovelace
     2	Alan Turing
     2	Grace Hopper
$ git shortlog -s --group=committer HEAD
     6	Ada Lovelace
     2	Alan Turing
     2	Grace Hopper
$ git shortlog -s --group=author --group=committer HEAD
     6	Ada Lovelace
     2	Alan Turing
     3	Grace Hopper
```

`-c`, `--committer` and `--group=committer` are the same. Ada has one commit more
as committer than as author, because she committed Grace's patch. Two `--group`
options count a commit under each value, but only once for each person: Ada is
both author and committer of five commits, and they were not counted twice.

A trailer is a `Key: value` line at the end of a message (Chapter 17 shows how
to print them). `--group=trailer:<key>` counts the people named in it, and the
key is matched regardless of case:

```console
$ git shortlog -s -n --group=trailer:reviewed-by HEAD
     2	Ada Lovelace
     1	Grace Hopper
$ git shortlog -s -e --group=trailer:co-authored-by HEAD
     1	Grace Hopper <grace@example.com>
$ git shortlog -s -n --group=author --group=trailer:co-authored-by HEAD
     5	Ada Lovelace
     4	Grace Hopper
     2	Alan Turing
```

Commits without the trailer are not counted at all. Git's documentation says the
value is read as `Name <address>` when it can be, so the mailmap applies and the
address is hidden without `-e`; a value that is not a name and address is used
as it is. Grace wrote three commits and co-wrote a fourth.

`--group=format:` groups by the text any `git log` format produces:

```console
$ git shortlog -s --group=format:%as HEAD
    10	2026-01-05
$ git shortlog --group=format:%ad --date=format:%H:00 --format=%s v1.0
09:00 (1):
      Add the parser

10:00 (1):
      Add tests

11:00 (1):
      Fix a crash on empty input

$ git shortlog -s --group=nosuch HEAD
error: unknown group type: nosuch
```

`%as` is the author date as `YYYY-MM-DD`, so the first command counts commits per
day; every commit here was made on one day. `--date` sets how `%ad` prints, and
`format:%H:00` turns it into the hour.

> **Since Git 2.29.** `--group`, with `author`, `committer` and `trailer:`.
> **Since Git 2.39.** `--group=format:`.

### Which commits are summarised

```console
$ git shortlog -s v1.0..v1.1
     1	Ada Lovelace
     1	Alan Turing
     1	Grace Hopper
$ git shortlog -s HEAD -- docs
     1	Grace Hopper
$ git shortlog -s --all
     5	Ada Lovelace
     3	Alan Turing
     3	Grace Hopper
$ git shortlog -s -n --no-merges HEAD
     4	Ada Lovelace
     3	Grace Hopper
     2	Alan Turing
```

A range, paths after `--`, and the options that choose commits work as they do
for `git log` (Chapters 17 and 18). `v1.0..v1.1` is the usual way to credit the
people in one release. `--all` added Alan's commit on `experiment`, and
`--no-merges` left out Ada's merge.

### When shortlog reads standard input

```console
$ git shortlog
$ git shortlog -s
$ git log --pretty=short v1.0 | git shortlog -s
     2	Ada Lovelace
     1	Grace Hopper
$ git log --pretty=short v1.0 | git shortlog --group=trailer:reviewed-by
fatal: using --group=trailer with stdin is not supported
```

Git's documentation says that when no revision is given, and either standard
input is not a terminal or no branch is checked out, `git shortlog` summarises
the log it reads from standard input instead of the repository. The examples
here run with an empty, non-terminal input, so the first two commands printed
nothing. Typed at a terminal on a branch, `git shortlog` summarises `HEAD`.

> **Careful.** In a script, a cron job or a CI pipeline, standard input is
> usually not a terminal, and `git shortlog` either prints nothing or waits for
> input that never comes. The same happens at a terminal with a detached `HEAD`.
> Always name the commits: `git shortlog HEAD`.

The second form of the synopsis uses this on purpose: `git log --pretty=short`
prints the author line and title that shortlog needs, so the options of
`git log` can shape what is summarised. Grouping by trailer does not work this
way. Git's documentation adds that outside a repository shortlog looks for a
`.mailmap` file in the current directory.

## The .mailmap file

### What a mailmap changes

```console
$ cat .mailmap
# Map old names and addresses to current ones.
Ada Lovelace <ada@example.com> <ada@old.example>
$ git log -1 --format='%an <%ae> -> %aN <%aE>' v1.0
A. Lovelace <ada@old.example> -> Ada Lovelace <ada@example.com>
$ mv .mailmap ../saved.mailmap
$ git shortlog -s -e HEAD
     1	A. Lovelace <ada@old.example>
     4	Ada Lovelace <ada@example.com>
     2	Alan Turing <alan@example.com>
     3	Grace Hopper <grace@example.com>
$ mv ../saved.mailmap .mailmap
$ git shortlog -s -e HEAD
     5	Ada Lovelace <ada@example.com>
     2	Alan Turing <alan@example.com>
     3	Grace Hopper <grace@example.com>
```

A commit stores a name and address that can never change without rewriting
history. `.mailmap`, at the top of the working tree, changes only how they are
shown: `%an` is the stored name and `%aN` the mapped one (Chapter 17). Without the
file, Ada counts as two people.

`git shortlog`, `git log` and `git show` (Chapter 17), `git blame` (Chapter 19),
`git check-mailmap` and the `:mailmap` fields of `for-each-ref` all use it. It is
an ordinary tracked file, so it is shared with everyone who clones the
repository. Lines starting with `#` are comments, and blank lines are ignored.

### The four kinds of line

```console
$ cat ../forms.mailmap
# 1. a proper name for an address
Grace Hopper <grace@example.com>
# 2. a proper address for an address
<alan@turing.example> <alan@example.com>
# 3. a proper name and address for an address
Ada Lovelace <ada@example.com> <ada@old.example>
# 4. a proper name and address for a name and an address
Charles Babbage <charles@example.com> Chas <charles@old.example>  # only Chas
$ git check-mailmap --mailmap-file=../forms.mailmap 'G. Hopper <grace@example.com>' 'Alan Turing <alan@example.com>' 'A. Lovelace <ada@old.example>' 'Chas <charles@old.example>' 'Charlie <charles@old.example>'
Grace Hopper <grace@example.com>
Alan Turing <alan@turing.example>
Ada Lovelace <ada@example.com>
Charles Babbage <charles@example.com>
Charlie <charles@old.example>
```

What is on the right is matched against commits; what is on the left replaces it.

| Line | Matches | Replaces |
|---|---|---|
| `Proper Name <commit@address>` | any name with that address | the name |
| `<proper@address> <commit@address>` | any name with that address | the address |
| `Proper Name <proper@address> <commit@address>` | any name with that address | both |
| `Proper Name <proper@address> Commit Name <commit@address>` | only that name with that address | both |

`Charlie` shares Charles's old address, but the fourth line names `Chas`, so
Charlie was left alone. A `#` later on a line starts a comment too. The fourth
form is for an address that several people used, such as a shared bug-tracker
address.

### Testing a mailmap with check-mailmap

`git check-mailmap` prints what the mailmap makes of each contact, and the
contact unchanged when nothing matches. `--mailmap-file` in the previous section
added a file for one command.

```console
$ git check-mailmap 'a. lovelace <ADA@OLD.Example>'
Ada Lovelace <ada@example.com>
$ git check-mailmap 'Grace Hopper <grace@example.com>' '<ada@old.example>' ada@old.example someone@example.com
Grace Hopper <grace@example.com>
Ada Lovelace <ada@example.com>
Ada Lovelace <ada@example.com>
<someone@example.com>
$ printf 'Someone <someone@example.com>\nA. Lovelace <ada@old.example>\n' | git check-mailmap --stdin 'Grace Hopper <grace@example.com>'
Grace Hopper <grace@example.com>
Someone <someone@example.com>
Ada Lovelace <ada@example.com>
$ git check-mailmap
fatal: no contacts specified
```

Names and addresses match regardless of case. A contact can leave out the name,
and the brackets too; the output always has brackets. `--stdin` reads more
contacts after the ones on the command line.

> **Since Git 2.47.** `--mailmap-file` and `--mailmap-blob`, and a bare address
> without `<>`. **Since Git 2.49.** Contacts without a name work reliably; Git's
> release notes say `check-mailmap` used to crash on them.

### Mailmaps kept elsewhere

```console
$ cat ../extra.mailmap
Grace M. Hopper <grace@navy.example> <grace@example.com>
Augusta Ada King <ada@example.com> <ada@old.example>
$ git check-mailmap --mailmap-file=../extra.mailmap 'A. Lovelace <ada@old.example>' 'Grace Hopper <grace@example.com>'
Augusta Ada King <ada@example.com>
Grace M. Hopper <grace@navy.example>
$ git -c mailmap.file=../extra.mailmap shortlog -s -e HEAD
     4	Ada Lovelace <ada@example.com>
     2	Alan Turing <alan@example.com>
     1	Augusta Ada King <ada@example.com>
     3	Grace M. Hopper <grace@navy.example>
```

`git -c <name>=<value>` sets a configuration value for one command (Chapter 62).
`mailmap.file` adds a file anywhere on disk to `.mailmap`, and its entries win
where both match. Only the one commit made as `ada@old.example` became Augusta
Ada King: each line matches the identity stored in a commit, not the result of
another line.

`mailmap.blob` and `--mailmap-blob` read a mailmap stored in the repository, such
as the version committed in `HEAD`:

```console
$ mv .mailmap ../saved.mailmap
$ git check-mailmap '<ada@old.example>'
<ada@old.example>
$ git -c mailmap.blob=HEAD:.mailmap check-mailmap '<ada@old.example>'
Ada Lovelace <ada@example.com>
$ git check-mailmap --mailmap-blob=HEAD:.mailmap '<ada@old.example>'
Ada Lovelace <ada@example.com>
$ mv ../saved.mailmap .mailmap
$ git -c mailmap.file=../extra.mailmap check-mailmap --mailmap-blob=HEAD:.mailmap '<ada@old.example>'
Ada Lovelace <ada@example.com>
$ git -c mailmap.file=../extra.mailmap -c mailmap.blob=HEAD:.mailmap check-mailmap '<ada@old.example>'
Augusta Ada King <ada@example.com>
```

With the file moved away, the working tree had no mailmap, but the committed one
still worked. Git reads the sources in this order, and where two have an entry
for the same identity, the later one wins:

| Order | Source |
|---|---|
| 1 | `.mailmap` in the working tree; not read in a bare repository |
| 2 | `mailmap.blob` |
| 3 | `mailmap.file` |
| 4 | `--mailmap-blob` (check-mailmap only) |
| 5 | `--mailmap-file` (check-mailmap only) |

The order is taken from Git's source. The documentation states the steps that
involve a file, and the last two commands show the fourth beating the third and
the third beating the second.

```console
$ git clone -q --bare . ../bare.git
$ git -C ../bare.git shortlog -s -e HEAD
     5	Ada Lovelace <ada@example.com>
     2	Alan Turing <alan@example.com>
     3	Grace Hopper <grace@example.com>
$ git -C ../bare.git -c mailmap.blob= shortlog -s -e HEAD
     1	A. Lovelace <ada@old.example>
     4	Ada Lovelace <ada@example.com>
     2	Alan Turing <alan@example.com>
     3	Grace Hopper <grace@example.com>
```

A bare repository (Chapter 9) has no working tree, so Git's documentation makes
`mailmap.blob` default to `HEAD:.mailmap` there. An empty value turns that off.
Git also does not follow a `.mailmap` that is a symbolic link, the documentation
says, so that the file behaves the same read from disk or from a commit.

## Naming a commit with describe

### Reading describe's name

```console
$ git describe
v1.1-4-gf8b359d
$ git describe v1.1
v1.1
$ git describe HEAD~1
v1.1-3-gaae0bb0
```

| Part of `v1.1-4-gf8b359d` | Means |
|---|---|
| `v1.1` | the nearest annotated tag behind the commit |
| `4` | how many commits `git log v1.1..HEAD` would show |
| `g` | "git", so that version strings from different tools can be told apart |
| `f8b359d` | the commit's short hash |

On a tagged commit the tag alone is printed. The name works anywhere a revision
does, because Git uses only the hash after `-g` (Chapter 18), and it tells a
person where a build came from: `v1.1-4-gf8b359d` is four commits after `v1.1`.

### Which tags describe may use

```console
$ git describe HEAD~3
v1.0-2-g2971fe1
$ git describe --tags HEAD~3
v1.1-rc1
$ git describe --all
heads/main
$ git describe --all HEAD~4
tags/v1.0-1-g741cc7b
```

`HEAD~3` is tagged `v1.1-rc1`, but that tag is lightweight, and plain `describe`
uses only annotated tags. `--tags` accepts both. `--all` accepts any ref, so
`main` named itself, and it prints where each name lives, `heads/` or `tags/`.

```console
$ git describe --match 'v1.0'
v1.0-7-gf8b359d
$ git describe --match 'v1.0' --match 'grammar-*'
grammar-0.1-6-gf8b359d
$ git describe --match 'v1.0' --no-match
v1.1-4-gf8b359d
$ git describe --exclude 'v1.1'
grammar-0.1-6-gf8b359d
$ git describe --exclude 'v1.1' --no-exclude
v1.1-4-gf8b359d
$ git describe --match 'v*' --exclude 'v1.1'
v1.0-7-gf8b359d
$ git describe --tags --match 'v1.1-*' HEAD~3
v1.1-rc1
$ git describe --all --match 'origin/*'
remotes/origin/main-7-gf8b359d
```

Patterns are globs matched against the tag name without `refs/tags/`, and with
`--all` against branch names without `refs/heads/` and `refs/remotes/`. Several
`--match` options accept a tag matching any of them; `--exclude` leaves out a tag
matching any of its patterns, and a tag must pass both. `--no-match` and
`--no-exclude` clear the patterns given before them, which is useful after an
alias has set some. `--match 'v[0-9]*'` is the usual way to ignore tags that are
not releases.

### How describe chooses a tag

```console
$ git describe --first-parent
v1.1-2-gf8b359d
$ git describe --candidates=1
grammar-0.1-6-gf8b359d
$ git describe --debug HEAD~1
describe HEAD~1
No exact match on refs or tags, searching to describe
finished search at 7c1719346af64e57b472676e126492e3115457b6
 annotated          3 v1.1
 annotated          5 grammar-0.1
 annotated          6 v1.0
traversed 7 commits
v1.1-3-gaae0bb0
```

Git's documentation describes the search. If a tag points at the commit, that is
the answer, annotated tags and newer tags first. Otherwise `describe` walks back
through history collecting tags, up to 10 of them, and picks the one with the
fewest commits between it and the commit. `--debug` lists the tags it found with
that count, on standard error.

`--candidates=1` stops at the first tag found. The walk takes the newest commit
first, by commit date, as Git's source shows, and the commit tagged `grammar-0.1`
is newer than the one tagged `v1.1`, so that tag was found first although it is
further away. Git's documentation says a number above 10 takes slightly longer
but may give a more accurate result.

`--first-parent` follows only the first parent of each merge, so tags on branches
merged in are never used, and the count excludes their commits: two commits,
`Add a mailmap` and the merge, instead of four.

### Changing the shape of the name

```console
$ git describe --long v1.1
v1.1-0-g5495411
$ git describe --abbrev=12
v1.1-4-gf8b359da709c
$ git describe --abbrev=0
v1.1
$ git describe --candidates=0
fatal: no tag exactly matches 'f8b359da709cb7ec0c7e2497e7a529dd83a7f579'
$ git describe --exact-match v1.1
v1.1
$ git describe --exact-match HEAD
fatal: no tag exactly matches 'f8b359da709cb7ec0c7e2497e7a529dd83a7f579'
```

`--long` keeps the same shape on a tagged commit, which helps a script split the
name. `--abbrev=<n>` uses at least `<n>` digits, more if needed to stay unique;
`--abbrev=0` prints only the tag, the usual way to ask for the latest release.
`--exact-match` is documented as the same as `--candidates=0`, as the errors
show, and fails unless a tag points at the commit.

### The first tag that contains a commit

```console
$ git describe --contains HEAD~6
v1.0~1
$ git describe --contains HEAD~4
v1.1-rc1~1
$ git describe --contains HEAD~1^2
fatal: cannot describe 'f6c84b15eb58666a67794c9b2a2f586c87c1e90d'
```

`--contains` answers "which release first had this commit?" The name counts back
from the tag: `v1.0~1` is the parent of `v1.0` (Chapter 18). Git's documentation
says it implies `--tags`, which is why the lightweight `v1.1-rc1` was used. `Add
the first rule` came in with the merge after every tag, so no tag contains it.

### Uncommitted changes and a damaged repository

Here `src/parse.py` has a change that is not committed:

```console
$ git describe --dirty
v1.1-4-gf8b359d-dirty
$ git describe --dirty=-modified
v1.1-4-gf8b359d-modified
$ git describe --dirty HEAD
fatal: option '--dirty' and commit-ishes cannot be used together
$ git describe --broken
v1.1-4-gf8b359d-dirty
$ git restore src/parse.py
$ git describe --dirty
v1.1-4-gf8b359d
```

`--dirty` describes `HEAD` and marks a build made from changed files, which then
does not claim to be exactly that commit, so it takes no commit name.
`--broken` behaves the same on a healthy repository.

The difference is in a damaged one. `damaged` is a repository whose newest
commit's tree was deleted from `.git/objects` by hand:

```console
$ cd ../damaged
$ git describe
v0.1-1-gd9c867f
$ git describe --dirty; echo "exit $?"
error: bad tree object HEAD
exit 128
$ git describe --broken
error: bad tree object HEAD
v0.1-1-gd9c867f-broken
$ git describe --broken=-corrupt
error: bad tree object HEAD
v0.1-1-gd9c867f-corrupt
$ cd ../parser
```

`--dirty` gave up, because it could not compare the working tree with a tree that
is gone. `--broken` still printed the name, marked so a build script can go on
and report the problem. Chapter 81 covers repairing such a repository.

### Blobs, trees and history without tags

```console
$ git describe $(git rev-parse HEAD:src/lex.py)
v1.0-1-g741cc7b:src/lex.py
$ git describe HEAD:src
fatal: HEAD:src is neither a commit nor blob
$ cd ../untagged
$ git describe
fatal: No names found, cannot describe anything.
$ git describe --tags
fatal: No names found, cannot describe anything.
$ git describe --always
c7d8c4e
$ cd ../parser
```

Given a file's hash, `describe` names a commit and path where that content
appears: the first commit, going through history from `HEAD`, that contains it,
described in the usual way. `$(...)` puts the output of `git rev-parse` into the
command ([Names to hashes](#names-to-hashes)). A directory's tree cannot be
described.

`untagged` is a repository with one commit and no tags. Plain `describe` has
nothing to count from, even with `--tags`, and `--always` falls back to the short
hash, so a build script always gets a name.

> **Windows.** Tested outside the sandbox with Git 2.55: PowerShell accepts
> `git describe $(git rev-parse HEAD:src/lex.py)` as written, and also with
> plain parentheses, `git describe (git rev-parse HEAD:src/lex.py)`.

## Listing commits with rev-list

### rev-list and log

```console
$ git rev-list HEAD~2
5495411d4ed303d1376f5854a87152042768d4fb
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
7c1719346af64e57b472676e126492e3115457b6
737387221a8a9254d00b352b18b643cb2a9ecf42
c38cfeb22512ec907a36838b38753210dd27b149
$ git log --format=%H HEAD~2
5495411d4ed303d1376f5854a87152042768d4fb
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
7c1719346af64e57b472676e126492e3115457b6
737387221a8a9254d00b352b18b643cb2a9ecf42
c38cfeb22512ec907a36838b38753210dd27b149
$ git rev-list
usage: git rev-list [<options>] <commit>... [--] [<path>...]

  limiting output:
    --max-count=<n>
...
$ git rev-list HEAD nosuch
fatal: ambiguous argument 'nosuch': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

The two lists are the same, and both commands choose commits the same way. The
differences: `rev-list` needs a starting commit, where `log` assumes `HEAD`, and
it has options for objects, filters and counting that `log` lacks. Being
plumbing, it is the one to use in scripts. Without a commit it prints its usage,
a list of options that goes on well past what is shown here.

### Counting commits

```console
$ git rev-list --count HEAD
10
$ git rev-list --count v1.0..HEAD
7
$ git rev-list --count --left-right main...experiment
0	1
$ git switch -q --detach main
$ git cherry-pick experiment
[detached HEAD 1a21319] Try a faster tokenizer
 Author: Alan Turing <alan@example.com>
 Date: Mon Jan 5 19:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 src/fast.py
$ git rev-list --count --left-right HEAD...experiment
1	1
$ git rev-list --count --left-right --cherry-mark HEAD...experiment
0	0	2
$ git switch -q main
```

`A...B` is the commits on either side but not both (Chapter 18). With
`--left-right`, `--count` prints two numbers separated by a tab: commits only in
`A`, then only in `B`. `main` has nothing `experiment` lacks, and `experiment`
has one commit more.

To show the third number, the commit on `experiment` was copied onto a detached
`HEAD` with `git cherry-pick` (Chapter 32). The copy has a different hash, so
each side has one commit of its own. `--cherry-mark` recognises commits that make
the same change (Chapter 18) and counts them separately, both copies, which
leaves nothing unique on either side.

### Commit details

```console
$ git rev-list --abbrev-commit --parents -3 HEAD
f8b359d aae0bb04d54dd018f7deed64baf1a8b8e49a5556
aae0bb0 5495411d4ed303d1376f5854a87152042768d4fb f6c84b15eb58666a67794c9b2a2f586c87c1e90d
f6c84b1 e579771e5d1b369d27e1dc63fbf5f04f690dab97
$ git rev-list --timestamp -2 HEAD
1767636000 f8b359da709cb7ec0c7e2497e7a529dd83a7f579
1767632400 aae0bb04d54dd018f7deed64baf1a8b8e49a5556
$ git rev-list --format='%h %s' -2 HEAD
commit f8b359da709cb7ec0c7e2497e7a529dd83a7f579
f8b359d Add a mailmap
commit aae0bb04d54dd018f7deed64baf1a8b8e49a5556
aae0bb0 Merge the grammar
$ git rev-list --no-commit-header --format='%h %s' -2 HEAD
f8b359d Add a mailmap
aae0bb0 Merge the grammar
$ git rev-list --no-commit-header --commit-header --format='%h %s' -1 HEAD
commit f8b359da709cb7ec0c7e2497e7a529dd83a7f579
f8b359d Add a mailmap
$ git rev-list --oneline -2 HEAD
f8b359d Add a mailmap
aae0bb0 Merge the grammar
```

`--parents` puts each commit's parents after it; `--abbrev-commit` shortened
only the first hash on each line. `--timestamp` is the commit time as seconds
since 1970, the Unix time. A custom `--format` always comes after a `commit
<hash>` line, which `--no-commit-header` removes; the built-in formats such as
`--oneline` have no such line.

> **Since Git 2.33.** `--no-commit-header` and `--commit-header`.

```console
$ git rev-list --header -1 HEAD | cat -A; echo
f8b359da709cb7ec0c7e2497e7a529dd83a7f579$
tree 86078af6fee54f3551e7d5b855c45cd8931e8e88$
parent aae0bb04d54dd018f7deed64baf1a8b8e49a5556$
author Ada Lovelace <ada@example.com> 1767636000 +0000$
committer Ada Lovelace <ada@example.com> 1767636000 +0000$
$
    Add a mailmap$
^@
$ git rev-list --max-age=1767614400 --abbrev-commit HEAD
f8b359d
aae0bb0
f6c84b1
e579771
5495411
2971fe1
741cc7b
$ git rev-list --min-age=1767614400 --abbrev-commit HEAD
741cc7b
7c17193
7373872
c38cfeb
```

`--header` prints each commit as stored, message indented, with a NUL byte after
each; `cat -A` shows line ends as `$` and the NUL as `^@`, and `echo` ends the
line. A script splits the records on the NUL bytes.

`--max-age` keeps commits made at or after a Unix time, and `--min-age` those at
or before it: `1767614400` is 12:00 on 5 January 2026, when `Add a lexer` was
made, so it is in both. `--since` and `--until` (Chapter 17) take readable dates
and are usually easier; [Dates as timestamps](#dates-as-timestamps) shows how one
becomes the other.

### Listing objects

`--objects` lists what a checkout of those commits needs: the commits, then their
trees and files, each with its path.

```console
$ git rev-list --objects -1 HEAD~7
c38cfeb22512ec907a36838b38753210dd27b149
30682e9560f3185786d388aa8c98ff3a4d2476a7 
0ba08b613a05d20b8810fe400815bfce130ef47b src
057b702211c9ba7fc0ef4b9a85744e34a521e796 src/parse.py
$ git rev-list --objects v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf docs/lexer.md
f51905810de642663c045649898c47eaa1ed3bee src
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --no-object-names v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf
f51905810de642663c045649898c47eaa1ed3bee
b4053f16f3bffe14087b6956997c5b632c87a2ae
85d921df761699dab522d6aef688f34b33ced955
$ git rev-list --objects --no-object-names --object-names -1 HEAD~7
c38cfeb22512ec907a36838b38753210dd27b149
30682e9560f3185786d388aa8c98ff3a4d2476a7 
0ba08b613a05d20b8810fe400815bfce130ef47b src
057b702211c9ba7fc0ef4b9a85744e34a521e796 src/parse.py
$ git rev-list --objects --in-commit-order v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf docs/lexer.md
f51905810de642663c045649898c47eaa1ed3bee src
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
741cc7b5372726c23456fdaed4a8f05cbc519eda
85d921df761699dab522d6aef688f34b33ced955 
```

A root tree has an empty path, so its line ends in a space. Only objects the
range adds are listed: `tests` and its file were already in `v1.0`, and the `src`
tree of `Add a lexer` is the same object as in `v1.1-rc1`, listed once. The
second root tree, `85d921d`, is `Add a lexer`'s; by default all commits come
first, and `--in-commit-order` puts each commit's new objects straight after it.
`--no-object-names` leaves the paths out, which suits a command that reads bare
hashes, and a later `--object-names` puts them back.

```console
$ git rev-list -z --objects -1 HEAD~7 | cat -A; echo
c38cfeb22512ec907a36838b38753210dd27b149^@30682e9560f3185786d388aa8c98ff3a4d2476a7^@0ba08b613a05d20b8810fe400815bfce130ef47b^@path=src^@057b702211c9ba7fc0ef4b9a85744e34a521e796^@path=src/parse.py^@
$ git rev-list --objects-edge HEAD~1 ^HEAD~2
-5495411d4ed303d1376f5854a87152042768d4fb
-7c1719346af64e57b472676e126492e3115457b6
aae0bb04d54dd018f7deed64baf1a8b8e49a5556
f6c84b15eb58666a67794c9b2a2f586c87c1e90d
e579771e5d1b369d27e1dc63fbf5f04f690dab97
fba4871ad50442985cd272c19c2ab48ab4d77e27 
975d0df5a2eaae3523d57420014b0a5f5af81864 src
eda42d7ce0fe4ecaaa65c581193c4727f0d02893 src/grammar.py
7f8af99cb460064cb32d519fd02a4c269e32a7da 
4ef95a184098e6ba521283e65946c7e84cb5a3d2 src
530e6f80ca230bde1e639f6fa0debf5952574a87 
4432cfdccd9fec2b6caae1587b72a53bd0b8cb82 src
38b227f7e77d4d76ba535d6bd88413a560ac43d6 src/grammar.py
```

`-z` ends every item with NUL and writes each path as `path=<path>`, so a path
containing a space or newline cannot be misread. `--objects-edge` lists the
commits and objects of the merge and its grammar branch, and first, marked `-`,
the excluded commits at the edge of the range: the parents of listed commits
that are not listed themselves. `git pack-objects` uses them to send a smaller
pack (Chapter 72), and `--objects-edge-aggressive`, documented for shallow
repositories, searches harder for them.

> **Since Git 2.50.** `-z`.

### Filtering objects

A filter leaves objects out of an `--objects` list. Partial clones (Chapter 46)
use the same filters to decide what not to download. The two files added between
`v1.0` and `v1.1-rc1` are 37 and 39 bytes:

```console
$ git cat-file -s v1.1-rc1:src/lex.py; git cat-file -s v1.1-rc1:docs/lexer.md
37
39
$ git rev-list --objects --filter=blob:none v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
f51905810de642663c045649898c47eaa1ed3bee src
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --filter=blob:limit=38 v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
f51905810de642663c045649898c47eaa1ed3bee src
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --filter=blob:limit=38 --filter-print-omitted v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
f51905810de642663c045649898c47eaa1ed3bee src
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
85d921df761699dab522d6aef688f34b33ced955 
~e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf
$ git rev-list --objects --filter=object:type=blob v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf docs/lexer.md
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
$ git rev-list --objects --filter=object:type=blob --filter-provided-objects v1.0..v1.1-rc1
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf docs/lexer.md
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
$ git rev-list --objects --filter=tree:0 v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
$ git rev-list --objects --filter=tree:1 v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --filter=tree:2 v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
f51905810de642663c045649898c47eaa1ed3bee src
85d921df761699dab522d6aef688f34b33ced955 
```

| Filter | Leaves out |
|---|---|
| `--filter=blob:none` | every file |
| `--filter=blob:limit=<n>` | files of `<n>` bytes or more; `k`, `m` and `g` after the number mean KiB, MiB and GiB |
| `--filter=object:type=<type>` | every object that is not of that type: `tag`, `commit`, `tree` or `blob` |
| `--filter=tree:<depth>` | trees and files `<depth>` or more levels below the root tree, which is level 0 |
| `--filter=sparse:oid=<blob-ish>` | files a sparse checkout (Chapter 60) would not need, with the patterns stored in the object `<blob-ish>` |
| `--filter=combine:<filter>+<filter>...` | anything any of the filters leaves out |

`--filter-print-omitted` lists what was left out, marked `~`. `tree:0` keeps no
trees or files at all, `tree:1` only the root trees, and `tree:2` also `docs` and
`src` but not the files in them. The `blob:` and `tree:` filters never leave out
commits.

`object:type=blob` left out the commit `Add a lexer` but printed the commit of
`v1.1-rc1`. That commit was named on the command line, and Git's documentation
says an object named there is printed whatever the filter says, unless
`--filter-provided-objects` is given, as in the next command.

```console
$ printf '/docs/\n' | git hash-object -w --stdin
6e684992f684f856e582bc4d7f6cf36a5c00a62e
$ git rev-list --objects --filter=sparse:oid=6e684992f684f856e582bc4d7f6cf36a5c00a62e v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf docs/lexer.md
f51905810de642663c045649898c47eaa1ed3bee src
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --filter=tree:3 --filter=blob:limit=38 v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
f51905810de642663c045649898c47eaa1ed3bee src
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --filter=combine:tree:3+blob:limit=38 v1.0..v1.1-rc1
2971fe14bfefb06dc27c801b095e0f5b921bd908
741cc7b5372726c23456fdaed4a8f05cbc519eda
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97 
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84 docs
f51905810de642663c045649898c47eaa1ed3bee src
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
85d921df761699dab522d6aef688f34b33ced955 
$ git rev-list --objects --filter=blob:none --no-filter v1.0..v1.1-rc1 | wc -l
8
```

`sparse:oid` needs the patterns stored as an object, which `git hash-object -w`
does (Chapter 75); with `/docs/` only the file under `docs` stayed. Two `--filter`
options and `combine:` gave the same result: an object must pass every filter.
Git's documentation says a filter inside `combine:` has to %-encode the
characters `~!@#$^&*()[]{}\;",<>?'` and backquote, spaces and `+`, which is why
repeating `--filter` is simpler. `--no-filter` cancelled the filter before it,
and all eight objects came back.

```console
$ git rev-list --objects --filter=blob:none HEAD:src/lex.py
b4053f16f3bffe14087b6956997c5b632c87a2ae src/lex.py
$ git rev-list --objects --filter=blob:none --filter-provided-objects HEAD:src/lex.py
$ git rev-list --objects --filter=nosuch HEAD
fatal: invalid filter-spec 'nosuch'
$ git rev-list --filter=blob:none HEAD
fatal: object filtering requires --objects
```

A file named directly behaves the same way: the file itself is printed despite
`blob:none`, until `--filter-provided-objects` is added.

> **Since Git 2.24.** `combine:`. **Since Git 2.32.** `object:type=` and
> `--filter-provided-objects`.

### Missing objects

Every object a commit refers to should be in the repository. Two kinds of
repository break that: a damaged one, and a partial clone, which leaves some out
on purpose. `damaged` is the repository from
[Uncommitted changes and a damaged repository](#uncommitted-changes-and-a-damaged-repository),
with its newest tree deleted.

```console
$ cd ../damaged
$ git rev-list --objects --all >/dev/null; echo "exit $?"
fatal: bad tree object f4b354863caa9cea99b95422c9dab70465757d87
exit 128
$ git rev-list --objects --missing=error --all >/dev/null; echo "exit $?"
fatal: bad tree object f4b354863caa9cea99b95422c9dab70465757d87
exit 128
$ git rev-list --objects --missing=allow-promisor --all >/dev/null; echo "exit $?"
fatal: unexpected missing tree object 'f4b354863caa9cea99b95422c9dab70465757d87'
exit 128
$ git rev-list --objects --missing=allow-any --all; echo "exit $?"
d9c867f97c69f41be1c41c4d21182624f2ae9354
ba193c9d19473d195081550399301e12493a123c
831fbde91822df0be83ac4e28e8234a929c7a348 v0.1
08585692ce06452da6f82ae66b90d98b55536fca 
78981922613b2afb6025042ff6bd878ac1994e85 a.txt
exit 0
$ git rev-list --objects --missing=print --all
d9c867f97c69f41be1c41c4d21182624f2ae9354
ba193c9d19473d195081550399301e12493a123c
831fbde91822df0be83ac4e28e8234a929c7a348 v0.1
08585692ce06452da6f82ae66b90d98b55536fca 
78981922613b2afb6025042ff6bd878ac1994e85 a.txt
?f4b354863caa9cea99b95422c9dab70465757d87
```

`>/dev/null` throws away the list so only the errors show. `--missing=error` is
the default. `allow-promisor` did not help, because this object was not left out
by a partial clone. `allow-any` carried on and skipped it silently, and `print`
listed it at the end, marked `?`. The file `b.txt` is not in either list: it is
known only through the missing tree. The list also has the tag object `v0.1`,
because `--all` starts from every ref.

A partial clone of the server, made with `--filter=blob:none` (Chapter 9), has
the commits and trees but only the files its checkout needed:

```console
$ cd ../partial
$ git rev-list --objects --missing=print --all | grep '^?'
?057b702211c9ba7fc0ef4b9a85744e34a521e796
$ git rev-list --objects --missing=print-info --all | grep '^?'
?057b702211c9ba7fc0ef4b9a85744e34a521e796 path=src/parse.py type=blob
$ git rev-list --objects --missing=allow-promisor --all | wc -l
12
$ git rev-list --objects --exclude-promisor-objects --all | wc -l
0
$ git rev-list --objects --all | wc -l
13
$ git rev-list --objects --missing=print --all | grep '^?'
$ cd ../parser
```

The first version of `src/parse.py` was never downloaded. `print-info` adds its
path and type. `allow-promisor` accepted it as expected, listing the 12 objects
present. `--exclude-promisor-objects` does not walk into anything that came from
the remote the clone promises to fetch from; here that is everything.

> **Careful.** Without a `--missing` option, `rev-list` in a partial clone
> quietly downloaded the missing object: 13 objects were listed, and afterwards
> nothing was missing. On a large repository over a network that can be slow and
> large. Use `--missing=print` or `allow-promisor` to look without fetching.

> **Since Git 2.49.** `--missing=print-info`.

### Size, speed and progress

```console
$ git rev-list --disk-usage HEAD
1844
$ git rev-list --disk-usage --objects --all
4750
$ git rev-list --disk-usage=human --objects --all
4.64 KiB
$ git rev-list --quiet HEAD; echo "exit $?"
exit 0
$ git rev-list --objects --unpacked -1 HEAD | wc -l
11
$ git rev-list --indexed-objects --objects --no-object-names | head -3
615a4ae9a076abbb4b89c226b7bb0918b5cda7cb
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf
eda42d7ce0fe4ecaaa65c581193c4727f0d02893
```

`--disk-usage` prints the bytes the selected objects take in `.git` instead of
listing them: 1844 for the ten commits alone, 4750 with their trees and files.
That answers "how big is this branch?" Git's documentation warns that for packed
objects the size depends on how the pack happens to store differences, so one
object's share is not exact.

`--quiet` prints nothing, for a script that needs only to know the command
worked. `--unpacked` keeps only objects not yet in a pack (Chapter 71); nothing
here has been packed, so all 11 objects of `HEAD` qualified. Git's documentation
says `--indexed-objects` acts as if every tree and file the index uses were named
on the command line, so staged content is included.

```console
$ git -C ../bare.git repack -adbq
$ git -C ../bare.git rev-list --objects --unpacked --all | wc -l
0
$ git -C ../bare.git rev-list --objects --use-bitmap-index v1.0..v1.1-rc1
741cc7b5372726c23456fdaed4a8f05cbc519eda
2971fe14bfefb06dc27c801b095e0f5b921bd908
c581cb03652e8f85c9f3793a7a48fd2eb0b60a84
e5a44e0f11aaf57d9419d6df1a8e0f55f1f04d97
f51905810de642663c045649898c47eaa1ed3bee
85d921df761699dab522d6aef688f34b33ced955
e7582ea3cf0f2dd3aa4eb63225bb869b4f9aa7cf
b4053f16f3bffe14087b6956997c5b632c87a2ae
$ git rev-list --objects --all --progress=Counting | wc -l
45
$ GIT_PROGRESS_DELAY=0 git rev-list --objects --all --progress=Counting | wc -l
Counting: 45, done.
45
```

`git repack -adb` packed the bare copy's objects and wrote a *bitmap*, a record
of which objects each commit reaches (Chapter 72). After it, nothing was
unpacked. With the bitmap, `rev-list` listed the same eight objects in a
different order and, as Git's documentation warns, without paths.

`--progress` reports on standard error, which is how progress still showed
while the list went into `wc`. Like all Git progress, it appears only after a
delay, and a small repository finishes first; `GIT_PROGRESS_DELAY=0` removed the
delay, in bash (Chapter 19).

> **Since Git 2.31.** `--disk-usage`. **Since Git 2.38.** `--disk-usage=human`.

### Bisection helpers

```console
$ git rev-list --bisect HEAD ^v1.0
5495411d4ed303d1376f5854a87152042768d4fb
$ git rev-list --bisect-vars HEAD ^v1.0
bisect_rev='5495411d4ed303d1376f5854a87152042768d4fb'
bisect_nr=3
bisect_good=3
bisect_bad=2
bisect_all=7
bisect_steps=2
$ git rev-list --bisect-all --abbrev-commit HEAD ^v1.0
5495411 (tag: v1.1, dist=3)
2971fe1 (tag: v1.1-rc1, dist=2)
f6c84b1 (dist=2)
741cc7b (dist=1)
aae0bb0 (dist=1)
e579771 (tag: grammar-0.1, dist=1)
f8b359d (HEAD -> main, dist=0)
```

These are what `git bisect` (Chapter 20) uses. With `HEAD` bad and `v1.0` good,
`--bisect` prints the commit it would test next, roughly halving the seven
suspects. During a real bisection it also reads the good and bad marks stored in
`refs/bisect/`.

`--bisect-vars` prints shell variables. Git's documentation describes
`bisect_rev`, the commit; `bisect_all`, the commits in the range; `bisect_good`
and `bisect_bad`, how many are expected to remain to test if that commit turns
out good or bad; and `bisect_nr`, how many are expected to remain after testing
it. It does not describe `bisect_steps`. `--bisect-all` lists every commit ordered
by distance from both ends, furthest first, shown as `dist`; `--bisect` picks the
top one. The list helps choose another commit when that one cannot be tested.

## Resolving names with rev-parse

### Names to hashes

```console
$ git rev-parse HEAD
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
$ git rev-parse HEAD~1 v1.0 v1.0^{commit}
aae0bb04d54dd018f7deed64baf1a8b8e49a5556
fc9790930240cd150046b73c247cf3947cbcbeb1
7c1719346af64e57b472676e126492e3115457b6
$ git rev-parse --short HEAD
f8b359d
$ git rev-parse --short=12 HEAD
f8b359da709c
$ git rev-parse --short=2 HEAD
f8b3
$ git rev-parse nosuch >/dev/null
fatal: ambiguous argument 'nosuch': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git rev-parse nosuch 2>/dev/null; echo "exit $?"
nosuch
exit 128
```

`git rev-parse` turns each name into a full hash, one per line; every way of
naming a commit from Chapter 18 works. `v1.0` gave the tag object, and
`v1.0^{commit}` the commit it points at (Chapter 6). `--short` gives the short
form, at least 4 digits and more if needed to be unique.

A name that is not a revision is printed unchanged, and Git fails if it is not a
file either. `>/dev/null` hid the printed name to show the error alone, and
`2>/dev/null` hid the error to show the name.

### Checking a name in a script

```console
$ git rev-parse --verify nosuch
fatal: Needed a single revision
$ git rev-parse --verify -q nosuch; echo "exit $?"
exit 1
$ git rev-parse --verify HEAD v1.0
fatal: Needed a single revision
$ git rev-parse --verify 'v1.0^{commit}'
7c1719346af64e57b472676e126492e3115457b6
$ name=--all; git rev-parse --verify -q "$name"; echo "exit $?"
0565da9961e28976e1aa55a42c95278a89ba09d3
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
7c1719346af64e57b472676e126492e3115457b6
1597a03d036e257b6ee904c749a27ec8fea7064f
fc9790930240cd150046b73c247cf3947cbcbeb1
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1
2971fe14bfefb06dc27c801b095e0f5b921bd908
exit 1
$ name=--all; git rev-parse --verify -q --end-of-options "$name"; echo "exit $?"
exit 1
```

`--verify` accepts exactly one name that leads to an object, and prints its hash
or fails. `-q` makes the failure silent, so a script can write
`if git rev-parse --verify -q "$name^{commit}" >/dev/null`. `^{commit}` also
checks the type: a tree or a file would fail.

The variable held `--all`, as a name typed by a user can. `rev-parse` read it as
an option and printed every ref before failing; a script taking the first line
would carry on with the wrong commit. `--end-of-options` makes everything after
it a name, and the check failed as it should. Git's documentation recommends it
whenever the name comes from outside the script.

> **Since Git 2.30.** `--end-of-options`.

### Short and symbolic names

```console
$ git rev-parse --symbolic HEAD~1 main
HEAD~1
main
$ git rev-parse --symbolic-full-name main v1.0 HEAD HEAD~1
refs/heads/main
refs/tags/v1.0
refs/heads/main
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse --abbrev-ref main HEAD~1 HEAD
main
main
$ git rev-parse --abbrev-ref @{upstream}
origin/main
$ git rev-parse --symbolic-full-name @{upstream}
refs/remotes/origin/main
```

| Option | Prints for `main` | For `HEAD` | For `HEAD~1` |
|---|---|---|---|
| none | the hash | the hash | the hash |
| `--symbolic` | `main`, as typed | `HEAD` | `HEAD~1` |
| `--symbolic-full-name` | `refs/heads/main` | the branch `HEAD` is on, in full | nothing, it is not a ref |
| `--abbrev-ref` | `main` | the branch `HEAD` is on, short | nothing |

`git rev-parse --abbrev-ref HEAD` is the usual way for a script to get the current
branch. Tried on a detached `HEAD`, both it and `--symbolic-full-name HEAD`
printed `HEAD`. `@{upstream}` is the branch's upstream (Chapter 18).

`--abbrev-ref` shortens as far as the name stays unambiguous. With a tag and a
branch both called `main`:

```console
$ git tag main HEAD~2
$ git rev-parse --abbrev-ref=strict refs/heads/main refs/tags/main
heads/main
tags/main
$ git rev-parse --abbrev-ref=loose refs/heads/main refs/tags/main
heads/main
main
$ git tag -d main
Deleted tag 'main' (was 5495411)
```

`strict` keeps a prefix on any name that matches more than one ref. `loose` drops
it when the short name still finds that ref first: plain `main` means the tag,
because tags are looked up before branches (Chapter 18). Git's documentation says
the default follows `core.warnAmbiguousRefs`, which is `true`, meaning strict.

### Ranges and defaults

```console
$ git rev-parse --not HEAD ^v1.0
^f8b359da709cb7ec0c7e2497e7a529dd83a7f579
fc9790930240cd150046b73c247cf3947cbcbeb1
$ git rev-parse v1.0..HEAD
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
^fc9790930240cd150046b73c247cf3947cbcbeb1
$ git rev-parse HEAD^!
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
^aae0bb04d54dd018f7deed64baf1a8b8e49a5556
$ git rev-parse --default HEAD
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
$ git rev-parse --default HEAD v1.0
fc9790930240cd150046b73c247cf3947cbcbeb1
$ git rev-parse --disambiguate=$(git rev-parse --short=4 HEAD)
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
$ git rev-parse --output-object-format=sha1 HEAD
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
$ git rev-parse --output-object-format=storage HEAD
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
$ git rev-parse --output-object-format=sha256 HEAD
fatal: unsupported object format: sha256
```

A range comes out as the hashes it is made of, with `^` in front of the excluded
one, which is the form `rev-list` takes; `HEAD^!` is the commit without its
parents (Chapter 18). `--not` flips the `^` on every name after it. `--default`
supplies a name when the script's user gave none.

`--disambiguate` lists every object whose hash starts with the prefix, at least
4 digits; here only one did. `--output-object-format` prints hashes in the named
algorithm, and `storage` means the one the repository keeps. This repository
supports only SHA-1, so `sha256` failed.

> **Since Git 2.45.** `--output-object-format`.

### Sets of refs

```console
$ git rev-parse --all
0565da9961e28976e1aa55a42c95278a89ba09d3
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
7c1719346af64e57b472676e126492e3115457b6
1597a03d036e257b6ee904c749a27ec8fea7064f
fc9790930240cd150046b73c247cf3947cbcbeb1
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1
2971fe14bfefb06dc27c801b095e0f5b921bd908
$ git rev-parse --branches --tags
0565da9961e28976e1aa55a42c95278a89ba09d3
f8b359da709cb7ec0c7e2497e7a529dd83a7f579
1597a03d036e257b6ee904c749a27ec8fea7064f
fc9790930240cd150046b73c247cf3947cbcbeb1
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1
2971fe14bfefb06dc27c801b095e0f5b921bd908
$ git rev-parse --symbolic --branches --remotes --tags='v1.1*'
experiment
main
origin/main
v1.1
v1.1-rc1
$ git rev-parse --symbolic --branches='e*' --remotes=origin
experiment
origin/main
$ git rev-parse --symbolic --glob='refs/tags/v1.[01]'
refs/tags/v1.0
refs/tags/v1.1
$ git rev-parse --symbolic --glob=heads
refs/heads/experiment
refs/heads/main
$ git rev-parse --symbolic --exclude='*rc*' --tags
grammar-0.1
v1.0
v1.1
$ git rev-parse --symbolic --exclude='*rc*' --tags --tags
grammar-0.1
v1.0
v1.1
grammar-0.1
v1.0
v1.1
v1.1-rc1
$ git -c transfer.hideRefs=refs/tags rev-parse --symbolic --exclude-hidden=fetch --all
refs/heads/experiment
refs/heads/main
refs/remotes/origin/main
$ git rev-parse --exclude-hidden=fetch --branches
error: options '--exclude-hidden' and '--branches' cannot be used together
```

`--all` is every ref in `refs/`; `--branches`, `--tags` and `--remotes` are one
kind each. A pattern with no `*`, `?` or `[` is a prefix, so `--remotes=origin`
means `origin/*`, and `--glob` adds `refs/` in front when the pattern lacks it.

`--exclude` applies to the next set only, which is why the second `--tags`
brought `v1.1-rc1` back. Its pattern is matched without `refs/tags/` for
`--tags`, and must start with `refs/` before `--all` or `--glob`.
`--exclude-hidden` leaves out the refs a server is configured to hide (Chapter 17
explains the three values); it works only before `--all` or `--glob`.

> **Since Git 2.39.** `--exclude-hidden`.

## Asking rev-parse about the repository

### Paths inside the repository

```console
$ git rev-parse --show-toplevel
/home/ada/parser
$ git rev-parse --git-dir
.git
$ git rev-parse --show-prefix --show-cdup | cat -A
$
$
$ cd src
$ git rev-parse --git-dir
/home/ada/parser/.git
$ git rev-parse --absolute-git-dir
/home/ada/parser/.git
$ git rev-parse --show-prefix
src/
$ git rev-parse --show-cdup
../
$ git rev-parse --path-format=relative --git-dir --show-toplevel
../.git
../
$ git rev-parse --path-format=absolute --git-dir
/home/ada/parser/.git
$ git rev-parse --path-format=relative --show-toplevel --path-format=absolute --git-dir
../
/home/ada/parser/.git
$ git rev-parse --prefix src/ parse.py
src/parse.py
$ git rev-parse --sq --prefix src/ -- parse.py 'a b'; echo
'--' 'src/parse.py' 'src/a b' 
$ git rev-parse --git-path objects/info
../.git/objects/info
$ git rev-parse --is-inside-work-tree
true
$ git rev-parse --is-inside-git-dir
false
$ cd ../.git
$ git rev-parse --is-inside-work-tree
false
$ git rev-parse --is-inside-git-dir
true
$ cd ..
```

| Option | At the top | In `src` |
|---|---|---|
| `--show-toplevel` | `/home/ada/parser` | the same; absolute by default |
| `--git-dir` | `.git`, relative | `/home/ada/parser/.git`, absolute |
| `--absolute-git-dir` | always absolute | always absolute |
| `--show-prefix` | an empty line | `src/` |
| `--show-cdup` | an empty line | `../` |

A script that must work from any directory starts with
`cd "$(git rev-parse --show-toplevel)"`. `--path-format` changes how the path
options after it print, until the next `--path-format`.

`--prefix` treats file names as if typed in that subdirectory, so a script that
moved to the top can still use its user's paths; with `--sq` and `--` it gives
arguments ready for `eval "set ..."`, as in Git's documentation. `--git-path`
answers where a file inside `.git` really is, which is not always
`$(git rev-parse --git-dir)/<path>`: the next section shows a case where the two
differ.

> **Since Git 2.31.** `--path-format`.

### Which kind of repository

```console
$ git rev-parse --is-bare-repository
false
$ git -C ../bare.git rev-parse --is-bare-repository
true
$ git -C ../bare.git rev-parse --show-toplevel
fatal: this operation must be run in a work tree
$ git rev-parse --is-shallow-repository
false
$ git -C ../shallow rev-parse --is-shallow-repository
true
$ git rev-parse --resolve-git-dir .git
.git
$ git rev-parse --resolve-git-dir src
fatal: not a gitdir 'src'
$ git worktree add -q ../parser-wt experiment
$ cd ../parser-wt
$ cat .git
gitdir: /home/ada/parser/.git/worktrees/parser-wt
$ git rev-parse --git-dir
/home/ada/parser/.git/worktrees/parser-wt
$ git rev-parse --git-common-dir
/home/ada/parser/.git
$ git rev-parse --resolve-git-dir .git
/home/ada/parser/.git/worktrees/parser-wt
$ git rev-parse --git-path HEAD --git-path objects
/home/ada/parser/.git/worktrees/parser-wt/HEAD
/home/ada/parser/.git/objects
$ cd ../parser
```

`git -C <dir>` runs the command as if started in `<dir>` (Chapter 9). A bare
repository has no working tree to find a top of. `shallow` is a clone made with
`--depth 1` (Chapter 9).

`git worktree add` (Chapter 56) made a second working tree for `experiment`. Its
`.git` is a file pointing into the main repository, and `--resolve-git-dir`
follows such a file. The worktree has a directory of its own inside the main
`.git`, so `--git-dir` and `--git-common-dir` differ, and `--git-path` put `HEAD`
in the worktree's directory and `objects` in the shared one.

### Formats, environment and outside a repository

```console
$ git rev-parse --show-object-format
sha1
$ git rev-parse --show-object-format=storage
sha1
$ git rev-parse --show-object-format=input
sha1
$ git rev-parse --show-object-format=output
sha1
$ git rev-parse --show-object-format=compat | cat -A
$
$ git rev-parse --show-ref-format
files
$ git rev-parse --local-env-vars
GIT_ALTERNATE_OBJECT_DIRECTORIES
GIT_CONFIG
GIT_CONFIG_PARAMETERS
GIT_CONFIG_COUNT
GIT_OBJECT_DIRECTORY
GIT_DIR
GIT_WORK_TREE
GIT_IMPLICIT_WORK_TREE
GIT_GRAFT_FILE
GIT_INDEX_FILE
GIT_NO_REPLACE_OBJECTS
GIT_REPLACE_REF_BASE
GIT_PREFIX
GIT_SHALLOW_FILE
GIT_COMMON_DIR
$ git rev-parse --shared-index-path; echo "(empty)"
(empty)
$ git update-index --split-index
$ git rev-parse --shared-index-path | sed 's/sharedindex.*/sharedindex.<hash>/'
.git/sharedindex.<hash>
$ git update-index --no-split-index
$ git rev-parse --show-superproject-working-tree; echo "(empty)"
(empty)
$ cd ..
$ git rev-parse --show-toplevel
fatal: not a git repository (or any of the parent directories): .git
$ git rev-parse --git-dir
fatal: not a git repository (or any of the parent directories): .git
$ git rev-parse --sq-quote 'a b' "it's"
 'a b' 'it'\''s'
$ cd parser
```

The object format is the hash algorithm, SHA-1 or SHA-256, and the ref format is
how refs are stored, `files` or `reftable` (Chapter 9). Git's documentation says
`--show-object-format` shows the algorithm used for storage inside `.git`, the
default, for input, where several may be printed, for output, or for
compatibility, which prints an empty line when no compatibility algorithm is
enabled, as here.

`--local-env-vars` names the variables that belong to one repository, such as
`GIT_DIR`, without their values. A script that runs Git in another repository
can unset them first, so a variable meant for the first repository does not
apply to the second.

`--shared-index-path` is empty unless the index is split into two files, an
option for very large repositories (Chapter 73); `sed` replaced the file's
hash. `--show-superproject-working-tree` is empty unless this repository is a
submodule (Chapter 57).

Outside any repository most of these fail. `--sq-quote` only quotes its
arguments, and works anywhere, as does `--parseopt`. Each argument comes out in
single quotes, with a leading space, and a quote inside is written `'\''`.

> **Since Git 2.25.** `--show-object-format`. **Since Git 2.44.**
> `--show-ref-format`. **Since Git 2.52.** `--show-object-format=compat`.

## Sorting and quoting arguments with rev-parse

### Revisions, options and paths

A script that passes its arguments on to `git rev-list` sometimes needs to split
them. `rev-parse` sorts them into revisions and their options, which are for
`rev-list`, and everything else.

```console
$ git rev-parse --symbolic -n 3 --oneline HEAD~1 src/parse.py
-n
3
--oneline
HEAD~1
src/parse.py
$ git rev-parse --revs-only --symbolic -n 3 --oneline HEAD~1 src/parse.py
-n
3
HEAD~1
$ git rev-parse --no-revs --symbolic -n 3 --oneline HEAD~1 src/parse.py
--oneline
src/parse.py
$ git rev-parse --flags --symbolic -n 3 --oneline HEAD~1 src/parse.py
-n
3
--oneline
HEAD~1
$ git rev-parse --no-flags --symbolic -n 3 --oneline HEAD~1 src/parse.py
HEAD~1
src/parse.py
$ git rev-parse --flags --no-revs --symbolic -n 3 --oneline HEAD~1 src/parse.py
--oneline
$ git rev-parse --symbolic HEAD 'a file.txt' >/dev/null
fatal: ambiguous argument 'a file.txt': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
$ git rev-parse --symbolic HEAD -- 'a file.txt'
HEAD
--
a file.txt
$ git rev-parse --sq --symbolic HEAD -- 'a file.txt' "it's"; echo
'HEAD' '--' 'a file.txt' 'it'\''s' 
```

| Option | Kept here |
|---|---|
| `--revs-only` | `-n`, `3`, `HEAD~1`: what `rev-list` takes |
| `--no-revs` | `--oneline`, `src/parse.py`: the rest |
| `--flags` | `-n`, `3`, `--oneline`, and `HEAD~1` |
| `--no-flags` | `HEAD~1`, `src/parse.py` |

`3` stayed with `-n` as its value. Git's documentation says `--flags` leaves out
every parameter that is not an option, but Git 2.55 kept `HEAD~1` and left out
only the path. Combined with `--no-revs`, only `--oneline` was left: the option
that is not for `rev-list`.

A path must exist unless it comes after `--`.
`--sq` puts everything on one line with shell quoting; unlike `--sq-quote`, it
still resolves and sorts the arguments first.

### Dates as timestamps

```console
$ git rev-parse --since='2026-01-05 12:00' --until=yesterday
--max-age=1767614400
--min-age=1767556800
$ git rev-parse --since='2026-01-05 12:00' --until='2026-01-05 13:00'
--max-age=1767614400
--min-age=1767618000
$ git rev-parse --after='2026-01-05 12:00' --before='2026-01-05 13:00'
--max-age=1767614400
--min-age=1767618000
```

`--since` becomes `rev-list`'s `--max-age` and `--until` its `--min-age`, as Unix
times; any date Chapter 17 lists works, and relative ones such as `yesterday`
count from the moment the command runs. `--after` and `--before` are the same, as
the last two commands show.

### Parsing options in a shell script

`--parseopt` gives a shell script options that behave like a Git command's. The
script describes its options on standard input, and `rev-parse` prints a `set --`
command that replaces the script's arguments with a tidy version:

```console
$ cat ../greet.sh
OPTS_SPEC="\
greet [<options>] <name>...
--
h,help!        show the help
l,loud         shout the greeting
t,times=count  repeat the greeting
lang?code      greet in another language
debug*         print what was parsed
 Output
q,quiet        say nothing
"
eval "$(echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@" || echo exit $?)"
echo "after: $*"
$ sh ../greet.sh -lt 2 Ada
after: -l -t 2 -- Ada
$ sh ../greet.sh --loud --times=3 Ada Grace
after: -l -t 3 -- Ada Grace
$ sh ../greet.sh --no-loud Ada -q
after: --no-loud -q -- Ada
$ sh ../greet.sh --ti 2 Ada
after: -t 2 -- Ada
$ sh ../greet.sh --lang Ada
after: --lang -- Ada
$ sh ../greet.sh --lang=fr Ada
after: --lang fr -- Ada
$ sh ../greet.sh -- -l
after: -- -l
```

The specification is the usage line, a line holding only `--`, then one line per
option: the short and long names separated by a comma, flags straight after,
then spaces and the help text.

| In the specification | Means |
|---|---|
| `l,loud` | `-l` and `--loud`; either name can be left out |
| `t,times=count` | `=`: takes a value, shown in help as `<count>` |
| `lang?code` | `?`: the value is optional |
| `debug*` | `*`: hidden from `-h`, shown by `--help-all` |
| `h,help!` | `!`: no `--no-help` |
| ` Output` | a line starting with a space: a group heading in the help |

After the `eval`, the script's arguments are always in the same shape: bundled
short options split (`-lt 2`), long options turned into short ones where they
have one, a value separated from its option, options found even after a name
(`Ada -q`), and a `--` before the names. The abbreviation `--ti` was accepted for
`--times`. An optional value must be attached with `=`: `--lang Ada` took no
value, and `Ada` stayed a name. After `--`, `-l` is a name.

```console
$ sh ../greet.sh -h
usage: greet [<options>] <name>...

    -h, --help            show the help
    -l, --[no-]loud       shout the greeting
    -t, --[no-]times <count>
                          repeat the greeting
    --[no-]lang[=<code>]  greet in another language

Output
    -q, --[no-]quiet      say nothing

$ sh ../greet.sh --help-all
usage: greet [<options>] <name>...

    -h, --help            show the help
    -l, --[no-]loud       shout the greeting
    -t, --[no-]times <count>
                          repeat the greeting
    --[no-]lang[=<code>]  greet in another language
    --[no-]debug          print what was parsed

Output
    -q, --[no-]quiet      say nothing

$ sh ../greet.sh --debug Ada
after: --debug -- Ada
$ sh ../greet.sh -t; echo "exit $?"
error: switch `t' requires a value
exit 129
$ sh ../greet.sh --no-help; echo "exit $?"
error: unknown option `no-help'
usage: greet [<options>] <name>...

    -h, --help            show the help
    -l, --[no-]loud       shout the greeting
    -t, --[no-]times <count>
                          repeat the greeting
    --[no-]lang[=<code>]  greet in another language

Output
    -q, --[no-]quiet      say nothing

exit 129
```

`-h` prints help built from the specification and stops the script. A hidden
option still works. On a mistake, `rev-parse` prints the error, and the help too
for an unknown option, and `|| echo exit $?` makes the script exit with the code
it returned, 129.

```console
$ printf 'greet\n--\nl,loud  shout\nt,times=n  repeat\n' | git rev-parse --parseopt -- -lt2 x
set -- -l -t '2' -- 'x'
$ printf 'greet\n--\nl,loud  shout\nt,times=n  repeat\n' | git rev-parse --parseopt --stuck-long -- -lt2 x
set -- --loud --times='2' -- 'x'
$ printf 'greet\n--\nl,loud  shout\n' | git rev-parse --parseopt -- -l -- x
set -- -l -- 'x'
$ printf 'greet\n--\nl,loud  shout\n' | git rev-parse --parseopt --keep-dashdash -- -l -- x
set -- -l -- '--' 'x'
$ printf 'greet\n--\nl,loud  shout\n' | git rev-parse --parseopt -- x -l
set -- -l -- 'x'
$ printf 'greet\n--\nl,loud  shout\n' | git rev-parse --parseopt --stop-at-non-option -- x -l
set -- -- 'x' '-l'
```

These show the `set --` line itself. The `--` after `--parseopt` separates
`rev-parse`'s own options from the script's arguments.

| Option | Effect in the output |
|---|---|
| `--stuck-long` | long names, and values attached with `=`; Git's documentation suggests it with optional values |
| `--keep-dashdash` | the user's own `--` is kept as an argument |
| `--stop-at-non-option` | parsing stops at the first name, so `-l` after it is left alone; for scripts with subcommands that take their own options |

## Listing refs with for-each-ref

### Choosing refs

```console
$ git for-each-ref
0565da9961e28976e1aa55a42c95278a89ba09d3 commit	refs/heads/experiment
f8b359da709cb7ec0c7e2497e7a529dd83a7f579 commit	refs/heads/main
7c1719346af64e57b472676e126492e3115457b6 commit	refs/remotes/origin/main
1597a03d036e257b6ee904c749a27ec8fea7064f tag	refs/tags/grammar-0.1
fc9790930240cd150046b73c247cf3947cbcbeb1 tag	refs/tags/v1.0
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1 tag	refs/tags/v1.1
2971fe14bfefb06dc27c801b095e0f5b921bd908 commit	refs/tags/v1.1-rc1
$ git for-each-ref refs/tags
1597a03d036e257b6ee904c749a27ec8fea7064f tag	refs/tags/grammar-0.1
fc9790930240cd150046b73c247cf3947cbcbeb1 tag	refs/tags/v1.0
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1 tag	refs/tags/v1.1
2971fe14bfefb06dc27c801b095e0f5b921bd908 commit	refs/tags/v1.1-rc1
$ git for-each-ref 'refs/tags/v1.1*' refs/heads/main
f8b359da709cb7ec0c7e2497e7a529dd83a7f579 commit	refs/heads/main
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1 tag	refs/tags/v1.1
2971fe14bfefb06dc27c801b095e0f5b921bd908 commit	refs/tags/v1.1-rc1
$ git for-each-ref refs/tag
$ git for-each-ref --exclude='refs/tags/*rc*' refs/tags
1597a03d036e257b6ee904c749a27ec8fea7064f tag	refs/tags/grammar-0.1
fc9790930240cd150046b73c247cf3947cbcbeb1 tag	refs/tags/v1.0
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1 tag	refs/tags/v1.1
$ printf 'refs/heads\nrefs/remotes\n' | git for-each-ref --stdin
0565da9961e28976e1aa55a42c95278a89ba09d3 commit	refs/heads/experiment
f8b359da709cb7ec0c7e2497e7a529dd83a7f579 commit	refs/heads/main
7c1719346af64e57b472676e126492e3115457b6 commit	refs/remotes/origin/main
$ git for-each-ref --stdin refs/heads
fatal: unknown arguments supplied with --stdin
$ git for-each-ref --count=2 refs/tags
1597a03d036e257b6ee904c749a27ec8fea7064f tag	refs/tags/grammar-0.1
fc9790930240cd150046b73c247cf3947cbcbeb1 tag	refs/tags/v1.0
```

Each line is the hash, the object type, a tab and the full ref name, sorted by
name. The type is `tag` for an annotated tag and `commit` for a lightweight one.

A pattern matches a whole name, the start of one up to a `/`, or a glob.
`refs/tag` matched nothing, because `refs/tags` does not end at a `/` there.
Several patterns list refs matching any, still in name order. `--exclude` takes
the same kind of pattern; `--stdin` reads patterns one per line, for lists too
long for a command line, and cannot be mixed with patterns as arguments.

```console
$ git for-each-ref --start-after=refs/heads/main --format='%(refname)'
refs/remotes/origin/main
refs/tags/grammar-0.1
refs/tags/v1.0
refs/tags/v1.1
refs/tags/v1.1-rc1
$ git for-each-ref --start-after=refs/heads/main refs/tags
fatal: cannot use --start-after with patterns
$ git for-each-ref --start-after=refs/heads/main --sort=-refname
fatal: cannot use --start-after with custom sort options
$ git for-each-ref --include-root-refs --format='%(refname)'
HEAD
ORIG_HEAD
refs/heads/experiment
refs/heads/main
refs/remotes/origin/main
refs/tags/grammar-0.1
refs/tags/v1.0
refs/tags/v1.1
refs/tags/v1.1-rc1
```

`--start-after` with `--count` pages through a very long list: ask for 100, then
start after the last name printed. It is documented as incompatible with
`--stdin` too. Refs can change between pages, which the documentation warns
about. `--include-root-refs` adds `HEAD` and other refs kept outside `refs/`,
such as `ORIG_HEAD` (Chapter 30).

> **Since Git 2.41.** `--stdin`. **Since Git 2.42.** `--exclude`. **Since Git
> 2.45.** `--include-root-refs`. **Since Git 2.51.** `--start-after`.

### Names and objects

`--format` prints any fields; a field is written `%(<name>)`, with options after
a colon.

```console
$ git for-each-ref --format='%(refname:short) %(objectname:short) %(objecttype)'
experiment 0565da9 commit
main f8b359d commit
origin/main 7c17193 commit
grammar-0.1 1597a03 tag
v1.0 fc97909 tag
v1.1 ed65d32 tag
v1.1-rc1 2971fe1 commit
$ git for-each-ref --format='%(refname) | %(refname:short) | %(refname:lstrip=2) | %(refname:rstrip=-1)' refs/tags/v1.0 refs/remotes
refs/remotes/origin/main | origin/main | origin/main | refs
refs/tags/v1.0 | v1.0 | v1.0 | refs
$ git for-each-ref --format='%(refname:lstrip=-2) | %(refname:strip=2) | %(refname:rstrip=2) | %(refname:lstrip=5) | %(refname:lstrip=-5)' refs/tags/v1.0
tags/v1.0 | v1.0 | refs |  | refs/tags/v1.0
```

| Option of `%(refname)` | Result for `refs/tags/v1.0` |
|---|---|
| `%(refname:short)` | `v1.0`, the shortest unambiguous name |
| `%(refname:lstrip=2)` | `v1.0`: two parts removed from the left |
| `%(refname:strip=2)` | the same; Git's documentation gives `strip` as another name for `lstrip` |
| `%(refname:lstrip=-2)` | `tags/v1.0`: parts removed from the left until two remain |
| `%(refname:rstrip=2)` | `refs`: two parts removed from the right |
| `%(refname:rstrip=-1)` | `refs`: parts removed from the right until one remains |
| `%(refname:lstrip=5)` | empty: there were not five parts to remove |
| `%(refname:lstrip=-5)` | the whole name: it already had fewer than five |

```console
$ git for-each-ref --format='%(objectname:short=10) %(objectsize) %(objectsize:disk) %(tree:short) %(parent:short)' refs/heads/main
f8b359da70 222 159 86078af aae0bb0
$ git for-each-ref --format='%(deltabase)' refs/heads/main
0000000000000000000000000000000000000000
$ git for-each-ref --format='%(refname:short) %(objecttype) %(*objecttype) %(subject) | %(*subject)' refs/tags
grammar-0.1 tag commit Grammar preview | Start a grammar
v1.0 tag commit Release 1.0 | Fix a crash on empty input
v1.1 tag commit Release 1.1 | Speed up parsing
v1.1-rc1 commit  [PATCH] Document the lexer | 
$ git for-each-ref --format='%(object) %(type) %(tag)' refs/tags/v1.0
7c1719346af64e57b472676e126492e3115457b6 commit v1.0
```

`%(objectsize)` is the object's size, as `git cat-file -s` reports it, and
`:disk` the compressed size in `.git`. `%(deltabase)` names the object this one
is stored as a difference from inside a pack (Chapter 72), and all zeros when it
is stored whole, as `main`'s commit is. `%(tree)` and `%(parent)` read a commit's
header.

An annotated tag is an object of its own, so `%(subject)` of `v1.0` is the tag's
message. A `*` in front of a field reads it from the object the tag points at:
the commit. On a lightweight tag the `*` fields are empty, because the ref points
at the commit directly. `%(object)`, `%(type)` and `%(tag)` read the tag object's
own header.

> **Since Git 2.29.** `:short` on `%(tree)` and `%(parent)`.

### People and dates

```console
$ git for-each-ref --format='%(author)|%(committer)|%(tagger)' refs/heads/main refs/tags/v1.0
Ada Lovelace <ada@example.com> 1767636000 +0000|Ada Lovelace <ada@example.com> 1767636000 +0000|
||Ada Lovelace <ada@example.com> 1767614400 +0000
$ git for-each-ref --format='%(refname:short) %(creatordate:short) %(creator)' refs/tags
grammar-0.1 2026-01-05 Alan Turing <alan@example.com> 1767628800 +0000
v1.0 2026-01-05 Ada Lovelace <ada@example.com> 1767614400 +0000
v1.1 2026-01-05 Ada Lovelace <ada@example.com> 1767625200 +0000
v1.1-rc1 2026-01-05 Ada Lovelace <ada@example.com> 1767618000 +0000
$ git for-each-ref --format='%(refname:short) %(authorname) %(authoremail:trim) %(authoremail:localpart) %(committerdate:relative)' refs/heads
experiment Alan Turing alan@example.com alan 60 minutes ago
main Ada Lovelace ada@example.com ada 2 hours ago
$ git for-each-ref --format='%(refname:short) %(taggername) %(taggerdate:iso) %(*authorname)' refs/tags/v1.0
v1.0 Ada Lovelace 2026-01-05 12:00:00 +0000 A. Lovelace
$ git for-each-ref --format='%(authorname) / %(*authorname) / %(*authorname:mailmap)' refs/tags/v1.0
 / A. Lovelace / Ada Lovelace
$ git for-each-ref --format='%(*authoremail) %(*authoremail:mailmap) %(*authoremail:mailmap,trim) %(*authoremail:localpart,mailmap)' refs/tags/v1.0
<ada@old.example> <ada@example.com> ada@example.com ada
```

A commit has an author and a committer, an annotated tag a tagger. The whole
field is the name, address and Unix time as stored; `name`, `email` and `date`
after it give one part. `%(creator)` and `%(creatordate)` use the tagger for an
annotated tag and the committer otherwise, so one format works on both kinds of
tag.

A date field takes any `--date` format from Chapter 17 after a colon;
`relative` counts from the moment you run the command. An email field takes
`:trim`, without the brackets, `:localpart`, the part before `@`, and `:mailmap`,
which applies [the .mailmap file](#the-mailmap-file), in any order.

> **Since Git 2.29.** `:trim` and `:localpart`. **Since Git 2.43.** `:mailmap`.

### Messages

```console
$ git for-each-ref --format='%(contents)' refs/tags/v1.0
Release 1.0

$ git for-each-ref --format='%(contents:subject)%0a%(contents:body)%0a--' 'refs/tags/v1.1^{}' refs/tags/v1.1
Release 1.1

--
$ git for-each-ref --format='%(*contents:subject)%0a%(*contents:body)%0a--' refs/tags/v1.1
Speed up parsing
This commit message has a body that is long enough to be wrapped by shortlog when it is asked to show whole messages.

--
$ git for-each-ref --format='%(*subject): %(*trailers:key=Reviewed-by,valueonly)' refs/tags/v1.0 refs/tags/v1.1
Fix a crash on empty input: Grace Hopper <grace@example.com>

Speed up parsing: 
$ git for-each-ref --format='%(subject:sanitize) %(contents:size) %(contents:lines=1)' refs/tags/v1.0
Release-1.0 12 Release 1.0
$ git for-each-ref --format='%(raw:size)' refs/tags/v1.0
137
$ git for-each-ref --format='%(raw)' refs/tags/v1.0
object 7c1719346af64e57b472676e126492e3115457b6
type commit
tag v1.0
tagger Ada Lovelace <ada@example.com> 1767614400 +0000

Release 1.0

$ git for-each-ref --format='%(refname:short) %(signature:grade)' refs/heads/main
main N
$ git for-each-ref --format='100%% %(refname:short)%09tab' refs/heads/main | cat -A
100% main^Itab$
$ git for-each-ref --format='%(nosuch)'
fatal: unknown field name: nosuch
```

`%(contents)` is the whole message, `:subject` its first paragraph, `:body` the
rest, `:lines=<n>` the first lines, and `:size` its length in bytes; Git's
documentation gives `%(subject)` as the same as `%(contents:subject)`. `%0a` is a
newline.

Patterns match ref names, not revisions, so `refs/tags/v1.1^{}` matched nothing
and printed nothing; the `*` fields are the way to reach the commit.
`%(trailers)` takes the options Chapter 17 describes for `git log`, and each
trailer ends with a newline, hence the blank line after Grace.

`:sanitize` turns the title into something usable as a file name. `%(raw)` is the
object exactly as stored, and `%(raw:size)` its size. `%(signature:grade)` is `N`
for a commit with no signature; Chapter 68 covers signatures and the other
`signature` parts. `%%` prints `%`, and `%` with two hex digits the character
with that code: `%09` is a tab, which `cat -A` shows as `^I`. An unknown field is
an error, not an empty string.

> **Since Git 2.34.** `%(raw)`. **Since Git 2.42.** `%(signature)`.

### Upstream and related refs

To show every kind of relationship with an upstream (Chapter 41), four more
branches were made, each tracking `origin/main`: `behind` is one commit behind
it, `even` is at the same commit, `side` has a commit of its own on an older
commit, and `gone` tracks a remote branch `origin/gone` that does not exist.

```console
$ git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track) %(upstream:trackshort)' refs/heads
behind origin/main [behind 1] <
even origin/main  =
experiment   
gone origin/gone [gone] 
main origin/main [ahead 7] >
side origin/main [ahead 1, behind 1] <>
$ git for-each-ref --format='%(refname:short) %(upstream) | %(upstream:lstrip=-1) | %(upstream:track,nobracket)' refs/heads/side
side refs/remotes/origin/main | main | ahead 1, behind 1
$ git for-each-ref --format='%(refname:short) %(upstream:remotename) %(upstream:remoteref) %(push:short) %(push:track)' refs/heads/main
main origin refs/heads/main origin/main [ahead 7]
```

| `%(upstream:track)` | `%(upstream:trackshort)` | Means |
|---|---|---|
| `[ahead 7]` | `>` | 7 commits here that the upstream lacks |
| `[behind 1]` | `<` | the upstream has 1 commit this branch lacks |
| `[ahead 1, behind 1]` | `<>` | both: the branches have diverged |
| empty | `=` | at the same commit |
| `[gone]` | empty | the upstream ref does not exist |

`experiment` has no upstream, so every upstream field is empty. `:nobracket`
drops the brackets. `%(upstream)` takes `:short`, `:lstrip` and `:rstrip` as
`%(refname)` does. `:remotename` and `:remoteref` are the remote and the branch
name there, and `%(push)` is where `git push` would send the branch, with the same
options. `git branch -vv` (Chapter 23) shows the upstream and the distance to it
for humans.

The four extra branches were deleted again.

```console
$ git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
experiment 1 0
main 0 0
$ git for-each-ref --format='%(refname:short)%(is-base:experiment)' refs/heads refs/tags
experiment(experiment)
main
grammar-0.1
v1.0
v1.1
v1.1-rc1
$ git for-each-ref --format='%(refname:short)%(is-base:experiment)' refs/heads/main refs/tags
main(experiment)
grammar-0.1
v1.0
v1.1
v1.1-rc1
```

`%(ahead-behind:<commit-ish>)` compares each ref with any commit, not only an
upstream: `experiment` is one commit ahead of `main` and none behind.

`%(is-base:<commit-ish>)` marks at most one ref as the one `<commit-ish>` most
likely started from. Git's documentation describes the rule: the ref whose
first-parent history meets the branch's own first-parent history soonest, ties
going to the ref sorted first. `experiment` is trivially its own base, so it has
to be left out of the refs; then `main` is marked.

```console
$ git for-each-ref --format='%(refname:short) %(describe) %(describe:tags)' refs/heads
experiment v1.1-5-g0565da9 v1.1-5-g0565da9
main v1.1-4-gf8b359d v1.1-4-gf8b359d
$ git for-each-ref --format='%(describe) %(describe:tags=yes) %(describe:abbrev=4) %(describe:match=v1.0) %(describe:exclude=v1.1-rc1,tags)' refs/tags/v1.1-rc1
v1.0-2-g2971fe1 v1.1-rc1 v1.0-2-g2971 v1.0-2-g2971fe1 v1.0-2-g2971fe1
$ git for-each-ref --format='%(refname:short) %(worktreepath)' refs/heads
experiment /home/ada/parser-wt
main /home/ada/parser
$ git for-each-ref --format='%(symref) <- %(refname)' refs/remotes
 <- refs/remotes/origin/main
$ git -C ../shallow for-each-ref --format='%(symref) <- %(refname)' refs/remotes
refs/remotes/origin/main <- refs/remotes/origin/HEAD
 <- refs/remotes/origin/main
$ git -C ../shallow for-each-ref --format='%(symref:short) <- %(refname:short)' refs/remotes
origin/main <- origin
 <- origin/main
```

`%(describe)` is `git describe` for each ref, and its options work as in
`git log --format` (Chapter 17): `tags`, `abbrev`, `match` and `exclude`,
separated by commas. `tags=yes` let the lightweight `v1.1-rc1` name its own
commit. `%(worktreepath)` is where a branch is checked out, empty if nowhere;
`experiment` is in the worktree made in
[Which kind of repository](#which-kind-of-repository).

`%(symref)` is what a symbolic ref points to. The pushed repository has no
`origin/HEAD`; a clone, such as `shallow`, does. Its short name is `origin`,
because `origin` alone means `origin/HEAD` (Chapter 18).

> **Since Git 2.41.** `%(ahead-behind:)`. **Since Git 2.42.** `%(describe)`.
> **Since Git 2.47.** `%(is-base:)`.

### Conditions, alignment and colour

```console
$ git for-each-ref --format='%(if)%(HEAD)%(then)* %(else)  %(end)%(refname:short)' refs/heads
  experiment
* main
$ git for-each-ref --format='%(refname:short)%(if:equals=Alan Turing)%(authorname)%(then) by Alan%(end)' refs/heads
experiment by Alan
main
$ git for-each-ref --format='%(refname:short)%(if:notequals=main)%(refname:short)%(then) (not main)%(end)' refs/heads
experiment (not main)
main
$ git for-each-ref --format='|%(align:12,right)%(refname:short)%(end)|' refs/heads
|  experiment|
|        main|
$ git for-each-ref --format='|%(align:width=14,position=middle)%(refname:short)%(end)|' refs/heads
|  experiment  |
|     main     |
$ git for-each-ref --format='%(if)%(upstream)%(then)%(refname:short)%(end)' refs/heads

main
$ git for-each-ref --format='%(if)%(upstream)%(then)%(refname:short)%(end)' --omit-empty refs/heads
main
```

`%(if)<test>%(then)<yes>%(else)<no>%(end)` prints `<yes>` when the text between
`%(if)` and `%(then)` is not empty, ignoring spaces, and `<no>` otherwise;
`%(else)` is optional. `%(HEAD)` is `*` on the current branch and a space
elsewhere, which is why spaces are ignored. `:equals=` and `:notequals=` compare
the text with a string instead.

`%(align:<width>,<position>)` pads what comes before `%(end)` to `<width>`
characters, `left` by default, `right` or `middle`; the parameters can also be
written `width=` and `position=`, in any order. Git's documentation says text
longer than the width is left as it is. `--omit-empty` leaves out the line for a ref whose format came out empty.

> **Since Git 2.41.** `--omit-empty`.

```ansi
$ git for-each-ref --color --format='%(color:green)%(refname:short)%(color:reset) %(subject)' refs/heads
\e[32mexperiment\e[m Try a faster tokenizer
\e[32mmain\e[m Add a mailmap
```

```console
$ git for-each-ref --color=always --format='%(color:green)%(refname:short)%(color:reset)' refs/heads | cat -A
^[[32mexperiment^[[m$
^[[32mmain^[[m$
$ git for-each-ref --format='%(color:green)%(refname:short)%(color:reset)' refs/heads | cat -A
experiment$
main$
$ git for-each-ref --color=never --format='%(color:green)%(refname:short)%(color:reset)' refs/heads | cat -A
experiment$
main$
```

`%(color:<colour>)` takes any colour Chapter 62 describes, such as `bold red`, and
`reset` returns to normal. `--color` alone means `always`. Into a pipe, colour
appeared only with `--color` or `--color=always`.

> **Careful.** `for-each-ref` does not read `color.ui` at all. Without `--color`,
> Git's source decides by whether the output is a terminal, so a format with
> `%(color:...)` is coloured on a terminal even with `color.ui=never`, and not
> coloured into a pipe even with `color.ui=always`. This was tested with Git
> 2.55 by making Git believe its output went to a pager, which it treats like a
> terminal. Write `--color=never` or `--color=always` in scripts.

### Quoting for other languages

```console
$ git for-each-ref --shell --format='ref=%(refname) subject=%(subject)' refs/heads
ref='refs/heads/experiment' subject='Try a faster tokenizer'
ref='refs/heads/main' subject='Add a mailmap'
$ git tag -a note -m "It's done" -m 'Second paragraph'
$ git for-each-ref --shell --format='%(contents)' refs/tags/note
'It'\''s done

Second paragraph
'
$ git for-each-ref --perl --format='%(contents)' refs/tags/note
'It\'s done

Second paragraph
'
$ git for-each-ref --python --format='%(contents)' refs/tags/note
'It\'s done\n\nSecond paragraph\n'
$ git for-each-ref --tcl --format='%(contents)' refs/tags/note
"It's done\n\nSecond paragraph\n"
$ git tag -d note
Deleted tag 'note' (was 731bf84)
$ git for-each-ref --shell --format='%(raw)' refs/tags/v1.0
fatal: --format=raw cannot be used with --python, --shell, --tcl
```

Each field, not the whole line, is quoted as a string in that language, so the
output can be run as code in that language; Git's documentation calls it a
scriptlet to `eval`. A message with a quote and newlines was tagged to show the
difference: shell and Perl keep real newlines, Python and Tcl write `\n`.
`git for-each-ref -h` lists `-s` as short for `--shell` and `-p` for `--perl`.
Git's documentation says `%(raw)` cannot be used with `--shell`, `--python` or
`--tcl` because their strings may
not hold arbitrary bytes.

### Sorting refs

```console
$ git for-each-ref --format='%(refname:short)' refs/tags
grammar-0.1
v1.0
v1.1
v1.1-rc1
$ git for-each-ref --sort=-refname --format='%(refname:short)' refs/tags
v1.1-rc1
v1.1
v1.0
grammar-0.1
$ git for-each-ref --sort=creatordate --format='%(creatordate:iso) %(refname:short)' refs/tags
2026-01-05 12:00:00 +0000 v1.0
2026-01-05 13:00:00 +0000 v1.1-rc1
2026-01-05 15:00:00 +0000 v1.1
2026-01-05 16:00:00 +0000 grammar-0.1
$ git for-each-ref --sort=-creatordate --count=1 --format='%(refname:short)' refs/tags
grammar-0.1
$ git for-each-ref --sort=objectsize --format='%(objectsize) %(refname:short)' refs/tags
137 v1.0
137 v1.1
148 grammar-0.1
237 v1.1-rc1
$ git for-each-ref --sort='*authordate' --format='%(*authordate:iso) %(refname:short)' refs/tags
 v1.1-rc1
2026-01-05 11:00:00 +0000 v1.0
2026-01-05 14:00:00 +0000 v1.1
2026-01-05 15:00:00 +0000 grammar-0.1
$ git for-each-ref --sort=refname --sort=objecttype --format='%(objecttype) %(refname:short)' refs/tags
commit v1.1-rc1
tag grammar-0.1
tag v1.0
tag v1.1
$ git for-each-ref --sort=objecttype --sort=refname --format='%(objecttype) %(refname:short)' refs/tags
tag grammar-0.1
tag v1.0
tag v1.1
commit v1.1-rc1
```

The default order is by `refname`. `--sort` takes any field, `-` in front for
descending, and `--sort=-creatordate --count=1` is the usual way to find the
newest tag. Dates and sizes sort as numbers, everything else as text. Equal
values stay in name order. `*authordate` sorted tags by their commits' dates,
and the lightweight tag, having no `*` fields, came first as empty. With several
`--sort` options the last one decides first, and the earlier ones break ties.

```console
$ git for-each-ref --sort=creatordate --format='%(creatordate:format:%I%p) %(refname:short)' refs/tags
12PM v1.0
01PM v1.1-rc1
03PM v1.1
04PM grammar-0.1
$ git for-each-ref --sort=creatordate:format:%I%p --format='%(creatordate:format:%I%p) %(refname:short)' refs/tags
01PM v1.1-rc1
03PM v1.1
12PM v1.0
04PM grammar-0.1
```

> **Careful.** Git's documentation says a date field with a format in a sort key
> sorts by the formatted text. With Git 2.55 the order was neither by time nor by
> text, because Git's source switches from comparing numbers to comparing text
> part-way through the sort. Sort by the plain field and format it only in
> `--format`.

```console
$ git tag v1.10
$ git for-each-ref --format='%(refname:short)' refs/tags
grammar-0.1
v1.0
v1.1
v1.1-rc1
v1.10
$ git for-each-ref --sort=version:refname --format='%(refname:short)' refs/tags
grammar-0.1
v1.0
v1.1
v1.1-rc1
v1.10
$ git for-each-ref --sort=-v:refname --count=1 --format='%(refname:short)' 'refs/tags/v*'
v1.10
$ git -c versionsort.suffix=-rc for-each-ref --sort=version:refname --format='%(refname:short)' refs/tags
grammar-0.1
v1.0
v1.1-rc1
v1.1
v1.10
$ git branch Zebra main
$ git for-each-ref --format='%(refname:short)' refs/heads
Zebra
experiment
main
$ git for-each-ref --ignore-case --format='%(refname:short)' refs/heads
experiment
main
Zebra
$ git for-each-ref --ignore-case --format='%(refname:short)' refs/heads/ZEBRA
Zebra
```

A lightweight tag `v1.10` was added. Names sort byte by byte, so `v1.10` happens
to come after `v1.1-rc1` here, but it would come before a `v1.9`, because `1`
comes before `9`. `version:refname` compares the numbers inside names as numbers, and
Git's documentation gives `v:refname` as another name for it. The documentation
also explains why it still put `v1.1-rc1` after `v1.1`: names with the same version and different suffixes are compared as text.
`versionsort.suffix=-rc` makes names with that suffix come before the release,
and the setting can be given several times, in the order the suffixes should
sort. Chapter 47 covers release tags.

Upper case sorts before lower case unless `--ignore-case` is given, which also
makes patterns match regardless of case. The tag `v1.10` and the branch `Zebra`
were deleted afterwards.

### Filtering refs by history

```console
$ git for-each-ref --merged=main --format='%(refname:short)' refs/heads refs/tags
main
grammar-0.1
v1.0
v1.1
v1.1-rc1
$ git for-each-ref --no-merged=main --format='%(refname:short)' refs/heads refs/tags
experiment
$ git for-each-ref --format='%(refname:short)' refs/heads --merged
main
$ git for-each-ref --merged --format='%(refname:short)' refs/heads
fatal: malformed object name --format=%(refname:short)
$ git for-each-ref --contains=v1.1 --format='%(refname:short)'
experiment
main
v1.1
$ git for-each-ref --no-contains=v1.1 --format='%(refname:short)' refs/tags
grammar-0.1
v1.0
v1.1-rc1
$ git for-each-ref --format='%(refname:short)' --contains
experiment
main
$ git for-each-ref --points-at=HEAD --format='%(refname:short)'
main
$ git for-each-ref --points-at=HEAD~2 --format='%(refname:short)'
v1.1
$ git for-each-ref --points-at=v1.1 --format='%(refname:short)'
v1.1
```

| Option | Keeps refs whose tip |
|---|---|
| `--merged=<commit>` | is in `<commit>`'s history: already merged into it |
| `--no-merged=<commit>` | is not |
| `--contains=<commit>` | has `<commit>` in its history |
| `--no-contains=<commit>` | does not |
| `--points-at=<object>` | is `<object>`, or is an annotated tag pointing at it |

`--merged=main` answers "which branches can I delete?" (Chapter 23), and
`--contains=<commit>` "which releases have this fix?". The first four default to
`HEAD` without a value. Git's documentation says several `--contains` accept a ref
containing any of them and several `--no-contains` reject one containing any;
`--merged` and `--no-merged` combine the same way.

> **Careful.** Without `=`, the value is optional only as the last argument.
> `--merged --format=...` took `--format=...` as the commit to compare with.
> Write `--merged=HEAD`, or put a bare `--merged` last.

> **Windows.** Tested outside the sandbox with Git 2.55. PowerShell accepts
> formats in single quotes as written. At the cmd prompt, `%(refname:short)`
> works as typed, but in a batch file cmd eats a single `%`, and the format must
> be written `%%(refname:short)`; typed at the prompt, the doubled form prints
> `%(refname:short)` literally, because Git reads `%%` as a `%`.

## These commands and their neighbours

| Command | Lists or prints | Use it when |
|---|---|---|
| `git for-each-ref` | any refs, in any format, sorted and filtered | a script needs refs, or the other commands cannot sort or filter the way you want |
| `git show-ref` | refs and hashes, in one fixed format (Chapter 74) | you want a quick dump, or to check that a ref exists |
| `git branch` | branches, for humans (Chapter 23) | you are at a terminal; `--format` takes the same fields |
| `git tag` | tags, for humans (Chapter 47) | the same, for tags |
| `git rev-parse` | the hash for one name, or facts about the repository | a script needs one hash, or a path |
| `git rev-list` | the commits or objects in a range | a script needs many hashes, counts or objects |
| `git log` | commits, for reading (Chapter 17) | a person reads the output |
| `git describe` | a name for a commit, based on tags | you label a build or ask which release has a commit |
| `git shortlog` | commits grouped by person | you write release notes or credit contributors |
| `git name-rev` | a name for a commit, counted back from a ref that contains it | you want a name relative to any branch or tag |

```console
$ git show-ref
0565da9961e28976e1aa55a42c95278a89ba09d3 refs/heads/experiment
f8b359da709cb7ec0c7e2497e7a529dd83a7f579 refs/heads/main
7c1719346af64e57b472676e126492e3115457b6 refs/remotes/origin/main
1597a03d036e257b6ee904c749a27ec8fea7064f refs/tags/grammar-0.1
fc9790930240cd150046b73c247cf3947cbcbeb1 refs/tags/v1.0
ed65d326f2710fac8b197ea8068c1fc5fb60fbb1 refs/tags/v1.1
2971fe14bfefb06dc27c801b095e0f5b921bd908 refs/tags/v1.1-rc1
$ git branch --format='%(refname:short) %(upstream:track)'
experiment 
main [ahead 7]
$ git tag --format='%(refname:short) %(objecttype)'
grammar-0.1 tag
v1.0 tag
v1.1 tag
v1.1-rc1 commit
$ git name-rev HEAD~4
HEAD~4 tags/v1.1-rc1~1
$ git name-rev --tags --name-only HEAD~4
v1.1-rc1~1
```

`git show-ref` has no `--format`; Chapter 74 covers its own options.
Git's documentation says `git branch` and `git tag` take the same `--format`
fields, as the two commands show.

`git describe` counts forward from the last tag before a commit.
`git describe --contains` and `git name-rev` count back from a ref after it, and
for `HEAD~4` both gave `v1.1-rc1~1`. Git's documentation says `name-rev` uses
branch names too unless given `--tags`, and that `--name-only` with `--tags` drops
`tags/` to match `describe`.

## The settings

| Setting | Effect |
|---|---|
| `mailmap.file` | A mailmap file to read after `.mailmap`; its entries win |
| `mailmap.blob` | A mailmap stored in the repository, such as `HEAD:.mailmap`; the default in a bare repository |
| `log.mailmap` | Whether `git log` and `git show` apply the mailmap; `true` by default (Chapter 17) |
| `versionsort.suffix` | Suffixes, such as `-rc`, that sort before the release in `version:refname`; can be given several times |
| `core.warnAmbiguousRefs` | Warn about ambiguous names, and make `--abbrev-ref` strict; `true` by default (Chapter 18) |
| `core.abbrev` | Length of short hashes, such as those of `rev-parse --short` (Chapter 17) |
| `transfer.hideRefs`, `fetch.hideRefs`, `receive.hideRefs`, `uploadpack.hideRefs` | Refs `--exclude-hidden` leaves out (Chapter 17) |
| `uploadpack.allowFilter` | Whether a server accepts `--filter` from a partial clone (Chapter 9) |

`for-each-ref` does not read `color.ui`; see
[Conditions, alignment and colour](#conditions-alignment-and-colour).
`GIT_PROGRESS_DELAY` is an environment variable, not a setting: the seconds before
progress appears (Chapter 19).
