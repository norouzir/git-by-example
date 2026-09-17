# Chapter 45. Divergence and Rejected Pushes

## What it is

A branch and its copy on the server have *diverged* when each has commits the
other lacks. Git cannot push the branch, because moving the server's branch to
your commit would throw away the commits only the server has, and it cannot
pull by moving yours forward, for the same reason in the other direction.
Someone has to combine the two, and Git will not choose how.

That is the situation behind nearly every rejected push, and behind the pull
that asks how to reconcile divergent branches (Chapter 42). Chapter 43 showed
the rejections and the quickest way past them. This chapter is about the
situation itself: how a branch ends up diverged, how to see what is on each
side before doing anything, every way of reconciling the two with what each one
costs, the cases where the usual answer is wrong, the rejections that look like
divergence and are not, and the habits that keep it rare.

| Term | Means |
|---|---|
| *ahead* | the number of commits your branch has that its upstream lacks |
| *behind* | the number of commits the upstream has that your branch lacks |
| *diverged* | ahead and behind at once |
| *upstream* | the remote-tracking branch a local branch is compared with, such as `origin/main` (Chapter 23) |
| *merge base* | the newest commit both sides share, where they split (Chapter 25) |
| *reconcile* | combine the two sides into one history that contains both, or deliberately drop one |
| *equivalent commits* | two commits that make the same change with different hashes, such as a commit and its amended or rebased copy (Chapter 18) |
| *force push* | a push that replaces the server's branch although that drops commits (Chapter 43) |
| *lease* | the condition `git push --force-with-lease` adds: force only if the server's branch is still where your last fetch saw it (Chapter 43) |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does it mean that my branch and the server's have "diverged"?](#what-it-is)
- [Why can't Git just push, or just pull, when they have?](#what-it-is)

**[The situations at a glance](#the-situations-at-a-glance)**

- [My branch is ahead, behind, or both. What happens if I push or pull in each case?](#the-situations-at-a-glance)

**[The example repositories](#the-example-repositories)**

- [What repositories do the examples use?](#the-example-repositories)

**[How a branch diverges](#how-a-branch-diverges)**

- [`git status` says my branch is only ahead, but the push is rejected. How?](#how-a-branch-diverges)
- [Can I find out that the server moved without fetching?](#how-a-branch-diverges)
- [What else, besides someone else pushing, makes a branch diverge?](#how-a-branch-diverges)

**[Seeing both sides](#seeing-both-sides)**

- [How many commits are on each side?](#seeing-both-sides)
- [Which commits are mine and which came from the server?](#seeing-both-sides)
- [Where did the two sides split?](#seeing-both-sides)
- [Which files did each side change?](#seeing-both-sides)
- [Will combining them conflict? Can I tell before I try?](#seeing-both-sides)

**[Reconciling](#reconciling)**

- [What are all the ways to get out of a diverged branch?](#reconciling)
- [What does merging do to the history, and is the push then accepted?](#merge-then-push)
- [What does rebasing do instead?](#rebase-then-push)
- [I'm not ready to combine my work with theirs. What can I do with my commits meanwhile?](#move-your-commits-to-a-branch-of-their-own)
- [Can I send only one of my commits?](#take-only-some-of-your-commits)
- [How do I throw away my commits and take the server's, and get them back if I change my mind?](#keep-the-server-s-version)
- [When is it right to force my version over the server's?](#keep-your-version)
- [I pulled and pushed, and the push was rejected again. Why?](#someone-pushed-again-in-between)
- [Which way should I choose?](#which-way)

**[When both sides changed the same lines](#when-both-sides-changed-the-same-lines)**

- [Why did rebase stop with a conflict twice when merge stopped once?](#when-both-sides-changed-the-same-lines)
- [Should I merge or rebase when I expect conflicts?](#when-both-sides-changed-the-same-lines)

**[Diverged by a rewrite](#diverged-by-a-rewrite)**

- [I amended a commit I had pushed, and now my branch has diverged from itself. What do I do?](#diverged-by-a-rewrite)
- [How do I tell whether the server's extra commits are just my old versions?](#diverged-by-a-rewrite)
- [Why shouldn't I pull after amending a pushed commit?](#diverged-by-a-rewrite)
- [What if someone had already built on the commit I rewrote?](#someone-had-built-on-them)
- [Someone else rewrote the server's branch. What now?](#when-someone-else-rewrote-it)

**[Rejections that are not divergence](#rejections-that-are-not-divergence)**

- [My branch is only behind, with nothing new of mine. Why is the push rejected?](#a-branch-that-is-only-behind)
- [Why does the hint talk about "a pushed branch tip" instead of my current branch?](#a-branch-you-are-not-on)
- [Is there a list of every rejection reason and what to do about it?](#every-rejection)

**[Keeping divergence rare](#keeping-divergence-rare)**

- [What habits keep this from happening?](#keeping-divergence-rare)

**[Commands that show divergence](#commands-that-show-divergence)**

- [Which command shows what, and which of them contact the server?](#commands-that-show-divergence)

**[The settings](#the-settings)**

- [Which settings matter for divergence and rejected pushes?](#the-settings)

</details>

## The situations at a glance

| `git status -sb` shows | Means | `git push` | `git pull` | What to do |
|---|---|---|---|---|
| `## main...origin/main` | the same commit, as of the last fetch | nothing to push | brings anything new | nothing; fetch to check |
| `## main...origin/main [ahead 2]` | only yours has new commits | accepted | "Already up to date." | push |
| `## main...origin/main [behind 2]` | only the server's has new commits | rejected | fast-forwards | pull ([A branch that is only behind](#a-branch-that-is-only-behind)) |
| `## main...origin/main [ahead 2, behind 2]` | diverged | rejected | refuses unless told how (Chapter 42) | [Reconciling](#reconciling) |
| `## main...origin/main [ahead 1, behind 1]` after you amended a pushed commit | diverged from your own old version | rejected | refuses unless told how; merging brings your old version back | [Diverged by a rewrite](#diverged-by-a-rewrite) |
| `## main...origin/main [gone]` | the server's branch was deleted | recreates it | fails (Chapter 42) | Chapter 41 |

Every count in `git status` is as of your last fetch (Chapter 41), so a branch
that says only "ahead" may already have diverged on the server.

## The example repositories

```console
$ git remote -v
origin	../server/atlas.git (fetch)
origin	../server/atlas.git (push)
$ git log --oneline --graph --all --decorate
* 0ad0675 (HEAD -> main, origin/rivers, origin/main, origin/HEAD) Add Europe
* 0dd6887 Start the atlas
```

The atlas again, on a bare repository on the "server", with clones for Ada and
Bob. Every command runs in Ada's clone, and each section says what Bob pushed.
The clones reach the server by the relative path `../server/atlas.git`, which
keeps the hashes of merge commits the same on every machine (Chapter 42).

## How a branch diverges

Bob pushed "Add Asia". Ada, who had not fetched, committed a note:

```console
$ git status -sb
## main...origin/main [ahead 1]
$ git remote show origin | tail -2
  Local ref configured for 'git push':
    main pushes to main (local out of date)
$ git fetch && git status -sb
From ../server/atlas
   0ad0675..ae7e0d4  main       -> origin/main
## main...origin/main [ahead 1, behind 1]
```

`git status` reported only "ahead", because it compares with `origin/main`, which
had not moved since the last fetch. `git remote show` asks the server, and its
`local out of date` means the server's `main` has commits Ada lacks
(Chapter 39); it changes nothing locally. After a fetch, `git status` shows the
divergence. A push before that fetch would have been rejected with
`fetch first`, as Chapter 43 shows.

Two people pushing to one branch is the common cause, and the same happens to
one person working from two computers. The other causes produce the same
`[ahead, behind]`, and need different handling:

| Cause | What is on the server's side | Section |
|---|---|---|
| someone else pushed to the branch | their new commits | [Reconciling](#reconciling) |
| you pushed from another computer | your own commits, made elsewhere | [Reconciling](#reconciling) |
| you amended or rebased commits you had pushed | the old versions of your own commits | [Diverged by a rewrite](#diverged-by-a-rewrite) |
| someone rewrote the server's branch | their rewritten commits, and your branch still has the originals | [When someone else rewrote it](#when-someone-else-rewrote-it) |

## Seeing both sides

Bob pushed "Add Africa", and Ada committed another note:

```console
$ git fetch -q && git status -sb
## main...origin/main [ahead 2, behind 2]
$ git rev-list --left-right --count main...origin/main
2	2
$ git log --oneline --left-right main...origin/main
< a842ca8 Write another note
> d2376fe Add Africa
< fc652ef Write a note
> ae7e0d4 Add Asia
$ git log --oneline -1 $(git merge-base main origin/main)
0ad0675 Add Europe
```

`main...origin/main`, with three dots, means the commits on either side but not
both (Chapter 18). `git rev-list --left-right --count` counts each side, left
first, the same numbers `git status` shows (Chapter 22).
`git log --left-right` lists them with `<` for Ada's and `>` for the server's.
`git merge-base` names the commit they split from (Chapter 25).

```console
$ git diff --stat origin/main...main && git diff --stat main...origin/main
 notes.txt | 2 ++
 1 file changed, 2 insertions(+)
 maps/africa.txt | 1 +
 maps/asia.txt   | 1 +
 2 files changed, 2 insertions(+)
$ git merge-tree --write-tree --name-only main origin/main; echo "exit $?"
87d50b184c5e8fdf76d47acb9e0c99018936f958
exit 0
$ git branch -vv
* main a842ca8 [origin/main: ahead 2, behind 2] Write another note
```

With three dots, `git diff` compares the merge base with the side on the right:
first what Ada changed, then what the server changed (Chapter 13). No file was
changed on both sides, so conflicts are unlikely, and `git merge-tree` confirms
it without touching anything: it performs the merge in memory, prints the
resulting tree, and exits with 0 for a clean merge and 1 for a conflict, listing
the conflicted files (Chapter 25). `git branch -vv` shows the same counts for
every branch at once (Chapter 23).

## Reconciling

Each way below starts from the same state, the one just shown: Ada's two notes
and the server's two maps. Pushes are dry runs, until [Someone pushed again in
between](#someone-pushed-again-in-between), where Ada chooses.

### Merge, then push

```console
$ git merge --no-edit origin/main && git log --oneline --graph -6 && git push --dry-run
Merge made by the 'ort' strategy.
 maps/africa.txt | 1 +
 maps/asia.txt   | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 maps/africa.txt
 create mode 100644 maps/asia.txt
*   f307d1f Merge remote-tracking branch 'origin/main'
|\  
| * d2376fe Add Africa
| * ae7e0d4 Add Asia
* | a842ca8 Write another note
* | fc652ef Write a note
|/  
* 0ad0675 Add Europe
To ../server/atlas.git
   d2376fe..f307d1f  main -> main
```

The merge commit contains both sides, so it contains the server's `main`, and
the push is now a fast-forward: accepted. Ada's commits keep their hashes.
`git pull --no-rebase` does the fetch and the merge in one step, with the message
"Merge branch 'main' of ..." instead (Chapter 42). `--no-edit` accepts the
message that on a terminal would open in an editor.

### Rebase, then push

```console
$ git rebase origin/main && git log --oneline --graph -5 && git push --dry-run
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/main.
* 1c02d62 Write another note
* 8270117 Write a note
* d2376fe Add Africa
* ae7e0d4 Add Asia
* 0ad0675 Add Europe
To ../server/atlas.git
   d2376fe..1c02d62  main -> main
```

Ada's two commits were replayed on top of the server's, as new commits with new
hashes, and the history is a line (Chapter 33). The push is a fast-forward.
`git pull --rebase` is the one-step form (Chapter 42). On a terminal each
`Rebasing` line is redrawn over the one before.

### Move your commits to a branch of their own

```console
$ git switch -q -c border-notes && git push -u origin border-notes
To ../server/atlas.git
 * [new branch]      border-notes -> border-notes
branch 'border-notes' set up to track 'origin/border-notes'.
$ git switch -q main && git reset --hard origin/main && git status -sb
HEAD is now at d2376fe Add Africa
## main...origin/main
```

When your work is not ready to join the shared branch, or should be reviewed
first, give it a branch: `border-notes` holds both notes, on the server too, and
`main` was reset to the server's (Chapter 30). Nothing is combined yet; that
happens later, by a merge or a pull request (Chapter 50).

### Take only some of your commits

```console
$ git branch -q mine && git reset -q --hard origin/main && git cherry-pick mine~1 && git log --oneline -3
[main 8270117] Write a note
 Date: Mon Jan 5 12:00:00 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 notes.txt
8270117 Write a note
d2376fe Add Africa
ae7e0d4 Add Asia
```

`mine` kept both commits, `main` took the server's, and `git cherry-pick` copied
only the first note on top (Chapter 32). The `Date:` line appears because the
copy keeps the original author date, which differs from the moment of copying.
The copy is the very commit the rebase above made, `8270117`: same change, same
parent, and in the sandbox the same time.

### Keep the server's version

```console
$ git reset --hard origin/main && git branch rescued ORIG_HEAD && git log --oneline -2 rescued
HEAD is now at d2376fe Add Africa
a842ca8 Write another note
fc652ef Write a note
```

`git reset --hard origin/main` drops Ada's commits from `main`, when they were
an experiment or a mistake. They are not deleted: `git reset` sets `ORIG_HEAD` to
where the branch was, and a branch made from it brings them back; later, the
reflog still has them (Chapter 36).

> **Careful.** `--hard` also discards uncommitted changes, which no ref records.

### Keep your version

```console
$ git log --oneline main..origin/main && git push --force-with-lease --dry-run
d2376fe Add Africa
ae7e0d4 Add Asia
To ../server/atlas.git
 + d2376fe...a842ca8 main -> main (forced update)
```

A force push makes the server's `main` Ada's, and the two commits listed first
would leave the branch: Bob's maps. Here that is plainly wrong, and a lease does
not prevent it, because Ada has fetched and so knows about them (Chapter 43).
Force only when the commits the server would lose are ones nobody needs, which
in practice means your own old versions: [Diverged by a
rewrite](#diverged-by-a-rewrite).

### Someone pushed again in between

Ada chose to rebase:

```console
$ git pull -q --rebase && git log --oneline -3
1c02d62 Write another note
8270117 Write a note
d2376fe Add Africa
```

Before she pushed, Bob pushed "Add Oceania":

```console
$ git push; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git pull -q --rebase && git push
To ../server/atlas.git
   effcb33..d187078  main -> main
```

Reconciling takes time, and the server does not wait. The branch diverged again
by one commit, and the same two steps, repeated, got the push through. On a busy
branch that loop is normal; the shorter the gap between pull and push, the fewer
rounds it takes.

### Which way

| Way | Your commits | The shared history | The push | Fits when |
|---|---|---|---|---|
| merge | kept, same hashes | a merge commit joins the two sides | plain | your commits are already shared, or the team records merges |
| rebase | replayed, new hashes | one line | plain | your commits exist only in your clone, the usual case |
| a branch of their own | kept, on that branch | unchanged | of the new branch | the work needs review, or is not ready |
| cherry-pick some | the chosen ones copied, new hashes | one line | plain | only part of your work should go |
| keep the server's | dropped from the branch, recoverable for a while | unchanged | nothing to push | your commits were not wanted |
| keep yours | kept | the server's commits are dropped | forced | the server's extra commits are your own old versions |

Merge and rebase both keep everything, and the choice between them is the one
Chapter 42 discusses: rebase for commits that are only yours, merge for commits
others already have, because rebasing replaces commits (Chapter 28).

## When both sides changed the same lines

Bob pushed "Add Berlin", which changes the second line of `maps/europe.txt`.
Ada had changed the same line twice, in "Use the German name" and "Add the
country code":

```console
$ git merge origin/main; echo "exit $?"
Auto-merging maps/europe.txt
CONFLICT (content): Merge conflict in maps/europe.txt
Automatic merge failed; fix conflicts and then commit the result.
exit 1
$ git merge --abort && git rebase origin/main 2>&1 | grep -E 'CONFLICT|Could not apply'
CONFLICT (content): Merge conflict in maps/europe.txt
Could not apply 30696dd... # Use the German name
$ printf 'France\nDeutschland, capital Berlin\nItaly\n' > maps/europe.txt && git add maps/europe.txt && GIT_EDITOR=true git rebase --continue 2>&1 | grep -E 'CONFLICT|Could not apply|Successfully'
CONFLICT (content): Merge conflict in maps/europe.txt
Could not apply 1cc4d3a... # Add the country code
$ git diff
diff --cc maps/europe.txt
index f961220,64f1213..0000000
--- a/maps/europe.txt
+++ b/maps/europe.txt
@@@ -1,3 -1,3 +1,7 @@@
  France
++<<<<<<< HEAD
 +Deutschland, capital Berlin
++=======
+ Deutschland (DE)
++>>>>>>> 1cc4d3a (Add the country code)
  Italy
$ git rebase --abort && git log --oneline -1
1cc4d3a Add the country code
```

A merge compares the final states of the two sides, so it met the conflict once.
A rebase replays Ada's commits one at a time, and each commit that touches the
line conflicts again: after the first was resolved, the second stopped on the
same line. `grep` kept the lines that matter from the rebase's output;
`GIT_EDITOR=true` accepted the commit message without an editor (Chapter 34).
Both commands were abandoned with `--abort` (Chapter 26).

So when many of your commits touch lines the other side changed, a merge is
less work, or squash your commits into one first and then rebase (Chapter 34).
`rerere`, which records a resolution and reapplies it, helps when the same
conflict keeps coming back (Chapter 26). Ada merged, resolved the line as
`Deutschland (DE), capital Berlin`, and pushed.

## Diverged by a rewrite

Ada pushed "Write the notes", and then reworded its message:

```console
$ git commit -q --amend -m 'Write the travel notes' && git status -sb
## main...origin/main [ahead 1, behind 1]
$ git log --oneline --left-right --cherry-mark main...origin/main
= 91f0ed4 Write the travel notes
= d8e1382 Write the notes
$ git range-diff origin/main...main
1:  d8e1382 ! 1:  91f0ed4 Write the notes
    @@ Metadata
     Author: Ada Lovelace <ada@example.com>
     
      ## Commit message ##
    -    Write the notes
    +    Write the travel notes
     
      ## notes.txt ##
     @@
$ git push --force-with-lease
To ../server/atlas.git
 + d8e1382...91f0ed4 main -> main (forced update)
```

An amended commit is a new commit (Chapter 29), so Ada's branch diverged from
the server's with nothing new on either side. The counts look exactly like two
people's work; the tools tell them apart. `--cherry-mark` marks with `=` a
commit whose change also exists on the other side (Chapter 18): both were `=`,
so the server had nothing but Ada's old version. `git range-diff` pairs the old
and new versions of each commit and shows what differs between them, here only
the message (Chapter 35).

With nothing of anyone else's on the server's side, forcing is the right
answer, with a lease in case someone pushes meanwhile. Pulling would be wrong:
a merge would bring the old version back beside the new one, and every commit
would appear twice (Chapter 28).

### Someone had built on them

Bob fetched the travel notes and pushed a comment on top. Ada, without
fetching, changed a line of the notes and amended again:

```console
$ git commit -q -a --amend --no-edit && git fetch -q && git status -sb
## main...origin/main [ahead 1, behind 2]
$ git range-diff origin/main...main
1:  91f0ed4 ! 1:  3254b35 Write the travel notes
    @@ notes.txt
     @@
      Check the borders
      Check the rivers
    -+Check the seas
    ++Check the oceans
     +Check the mountains
     +Check the deserts
2:  468543c < -:  ------- Comment on the notes
$ git push --force-with-lease --force-if-includes; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        main -> main (remote ref updated since checkout)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of the remote-tracking branch has
hint: been updated since the last checkout. If you want to integrate the
hint: remote changes, use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
```

This time `git range-diff` paired the notes, with the changed line, and listed a
second commit with nothing on Ada's side: Bob's comment, which a force push would
remove. `--force-if-includes` refused, because Bob's commit had arrived by fetch
and was never in Ada's branch (Chapter 43).

```console
$ git reset -q --hard origin/main && sed -i 's/seas/oceans/' notes.txt && git commit -q -am 'Say oceans, not seas' && git push
To ../server/atlas.git
   468543c..a020088  main -> main
```

Once someone has built on a commit, stop rewriting it. Ada went back to the
server's branch and made the change as a new commit on top, which is an ordinary
push. The rule and its reasons are Chapter 28's.

### When someone else rewrote it

When the rewrite happened on the server, the other way round, Ada's branch
contains the original commits and the server has the rewritten ones. A merge
would keep both. Chapter 28 shows that mess and the rebase that avoids it, and
Chapter 42 shows `git pull --rebase` finding the fork point, the commit the
rewrite started from, so that only your own commits are replayed.

## Rejections that are not divergence

### A branch that is only behind

```console
$ git reset -q --hard HEAD~1 && git status -sb && git push; echo "exit $?"
## main...origin/main [behind 1]
To ../server/atlas.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git pull && git status -sb
Updating 468543c..a020088
Fast-forward
 notes.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
## main...origin/main
```

A branch with nothing new of its own is still pushed as a request to move the
server's branch to its commit, which would move it backwards. That is not a
fast-forward, so it is rejected like a diverged one. A pull fast-forwards it. If
moving the server's branch back is what you want, that is a force push, and the
commits it removes are gone from the branch for everyone.

### A branch you are not on

Bob pushed a commit to `rivers`, and Ada committed on her `rivers`:

```console
$ git push origin rivers; echo "exit $?"
To ../server/atlas.git
 ! [rejected]        rivers -> rivers (non-fast-forward)
error: failed to push some refs to '../server/atlas.git'
hint: Updates were rejected because a pushed branch tip is behind its remote
hint: counterpart. If you want to integrate the remote changes, use 'git pull'
hint: before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
exit 1
$ git branch -vv
  border-notes a842ca8 [origin/border-notes] Write another note
* main         a020088 [origin/main] Say oceans, not seas
  rivers       14f3b89 [origin/rivers: ahead 1, behind 1] List the Danube
```

The hint changes wording when the rejected branch is not the one checked out;
Git's documentation for `advice.pushNonFFMatching` describes this case, a
refspec that is not the current branch. A pull on the current branch would not
help `rivers`: switch to it and reconcile there. `git branch -vv` finds every
diverged branch at once.

| Hint begins | Shown when | Silenced by |
|---|---|---|
| Updates were rejected because the remote contains work that you do not have locally | the server's commit is not in your repository: `fetch first` | `advice.pushFetchFirst=false` |
| Updates were rejected because the tip of your current branch is behind | the current branch is not a fast-forward | `advice.pushNonFFCurrent=false` |
| Updates were rejected because a pushed branch tip is behind | another branch is not a fast-forward | `advice.pushNonFFMatching=false` |
| Updates were rejected because the tag already exists in the remote | a tag would move | `advice.pushAlreadyExists=false` |
| Updates were rejected because the tip of the remote-tracking branch has been updated since the last checkout | `--force-if-includes` refused | `advice.pushRefNeedsUpdate=false` |

The settings are named in Git's documentation for `advice.*`, and matched to the
hints in `builtin/push.c`; `advice.pushUpdateRejected=false` silences all of
them.

### Every rejection

| Reason in brackets | Means | What to do | Shown in |
|---|---|---|---|
| `fetch first` | the server has commits you have not even fetched | fetch, look, reconcile | Chapter 43 |
| `non-fast-forward` | your branch does not contain the server's commit: diverged, or only behind | reconcile, or pull | this chapter |
| `already exists` | a tag of that name is on the server, pointing elsewhere | force only if moving the tag is intended | Chapter 43 |
| `stale info` | a lease expired: the server's branch moved since your last fetch | fetch and look at what arrived | Chapter 43 |
| `remote ref updated since checkout` | `--force-if-includes`: the server's commit was never in your branch | reconcile with it, or look | this chapter, Chapter 43 |
| `atomic push failed` | another ref in the same `--atomic` push was rejected | deal with that ref | Chapter 43 |
| `remote rejected` ... `(non-fast-forward)` | the server refuses non-fast-forwards even when forced | reconcile; forcing cannot help | Chapter 43 |
| `remote rejected` ... anything else | a setting or hook on the server refused | read the `remote:` lines | Chapter 43 |

## Keeping divergence rare

| Habit | Why | How |
|---|---|---|
| Fetch before you compare | counts and logs are only as new as the last fetch | `git fetch`, or `git remote show` to ask without fetching |
| Integrate before you push, and push soon after | the shorter the gap, the fewer commits on each side and the fewer rounds | `git pull --rebase && git push` |
| Keep your work on its own branch | a branch only you push to cannot diverge because of others | Chapter 23, Chapter 49 |
| Choose one way to pull | no merge commit by surprise, no refusal to decode | `pull.rebase=true`, or `pull.ff=only` (Chapter 42) |
| Do not rewrite what others have | a rewrite diverges everyone's copy | Chapter 28 |
| When you must force, lease and check | refuses when commits you have not seen would be lost | `--force-with-lease`, `push.useForceIfIncludes=true` (Chapter 43) |
| Let the server refuse forced pushes to shared branches | a mistake cannot remove others' work | `receive.denyNonFastForwards` (Chapter 43); protected branches (Chapter 50, Chapter 51) |
| Record conflict resolutions | the same conflict in repeated rebases is resolved once | `rerere.enabled=true` (Chapter 26) |

## Commands that show divergence

| Command | Shows | Contacts the server |
|---|---|---|
| `git status -sb` | ahead and behind of the current branch, as of the last fetch | no |
| `git branch -vv` | the same for every branch | no |
| `git rev-list --left-right --count A...B` | the two counts, for any two commits | no |
| `git log --oneline --left-right A...B` | the commits on each side | no |
| `git log --left-right --cherry-mark A...B` | which commits on each side are equivalent | no |
| `git range-diff B...A` | old and new versions of rewritten commits, paired | no |
| `git merge-base A B` | where the two sides split | no |
| `git diff B...A` | what one side changed since the split | no |
| `git merge-tree --write-tree A B` | whether combining conflicts, without changing anything | no |
| `git fetch` | updates the remote-tracking branches, so the others see the server | yes |
| `git remote show <remote>` | `local out of date` for each branch whose server copy has commits yours lacks | yes |
| `git push --dry-run` | whether a push would be rejected, and why | yes |

## The settings

| Setting | Does |
|---|---|
| `pull.rebase`, `pull.ff` | What a pull does with a diverged branch (Chapter 42) |
| `branch.<name>.rebase` | The same for one branch (Chapter 42) |
| `push.useForceIfIncludes` | Every `--force-with-lease` also checks that you had the server's commit (Chapter 43) |
| `status.aheadBehind` | `false` makes `git status` skip counting, which is slow on large histories (Chapter 10) |
| `rebase.autoStash`, `pull.autoStash` | Reconcile with uncommitted changes (Chapter 42) |
| `rerere.enabled` | Reuse recorded conflict resolutions (Chapter 26) |
| `fetch.prune` | Keep `[gone]` upstreams visible instead of stale ones (Chapter 41) |
| `receive.denyNonFastForwards` | On the server: refuse non-fast-forwards, forced or not (Chapter 43) |
| `advice.pushUpdateRejected` | `false` removes every hint printed with a rejected push |
