# Chapter 28. The Golden Rule of Rewriting

## What it is

*Rewriting history* means replacing commits that already exist with different
ones. Git never edits a commit: a commit's name is a hash of everything in it,
including its parent, so any change at all produces a second commit with a
different name, and the branch is moved to point at the new one. The old commit
is still in the repository, unreferenced, until Git eventually deletes it.

That is the whole mechanism, and everything else in this part follows from it.
The rest of this chapter is about the consequence, which is the rule this part
is named after:

> **Rewrite freely while the commits are still yours alone. Once other people
> have them, replacing them makes work for every one of those people, so it is
> something to agree on rather than something to do.**

The rule is usually stated as "never rewrite public history", which is shorter
and, taken literally, wrong: teams rewrite pushed branches every day and are
right to. [The rule, and what it actually says](#the-rule-and-what-it-actually-says)
works out who "other people" are and what the real test is.

| Term | Means |
|---|---|
| *rewriting* | replacing one or more existing commits with different ones, so that the branch's history is not the same as it was |
| *force-push* | a push that replaces a branch on the server with one that is not a descendant of what was there, throwing the old commits off the branch |
| *fast-forward* | an update where the new commit has the old one as an ancestor, so nothing is lost; an ordinary push is always one (Chapter 25) |
| *diverged* | your branch and its upstream each have commits the other does not |
| *upstream* | the branch your branch is compared with and pulls from, usually a remote-tracking branch such as `origin/keys` (Chapter 23, Chapter 41) |
| *reachable* | findable by walking back from some ref; an unreachable commit still exists but nothing names it (Chapter 6) |
| *patch id* | a hash of a commit's *change* with line numbers ignored, which lets Git recognise the same change in two differently named commits (Chapter 32) |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What does "rewriting history" mean, if Git never changes a commit?](#what-it-is)
- [Is there one sentence that says when it is safe?](#what-it-is)

**[Which commands rewrite](#which-commands-rewrite)**

- [Which commands rewrite history, and which only add to it?](#which-commands-rewrite)
- [Does making a branch point somewhere else count, if I made no new commits?](#which-commands-rewrite)

**[The example repository](#the-example-repository)**

- [What repository do the examples use?](#the-example-repository)

**[What counts as rewriting](#what-counts-as-rewriting)**

- [Everyone says `git revert` is the safe one. Safe compared to what?](#what-counts-as-rewriting)
- [Is changing a commit message really the same kind of operation as a rebase?](#what-counts-as-rewriting)

**[Why a rewritten commit is a new commit](#why-a-rewritten-commit-is-a-new-commit)**

- [I only fixed a typo in a commit message. Why did the hash change?](#why-a-rewritten-commit-is-a-new-commit)
- [I changed one old commit and every commit after it changed too. Why?](#why-a-rewritten-commit-is-a-new-commit)
- [Are both versions of the commit in my repository now?](#why-a-rewritten-commit-is-a-new-commit)

**[Where the old commits go](#where-the-old-commits-go)**

- [What happened to the commit I replaced? Is it deleted?](#where-the-old-commits-go)
- [Why does `git log` not show it any more?](#where-the-old-commits-go)
- [How long do I have to change my mind?](#where-the-old-commits-go)

**[Telling whether a commit has left your machine](#telling-whether-a-commit-has-left-your-machine)**

- [How do I check whether the commits I am about to change have been pushed?](#telling-whether-a-commit-has-left-your-machine)
- [How do I tell whether anyone has built on top of my branch?](#telling-whether-a-commit-has-left-your-machine)
- [Can I see what a force-push would throw away before I run it?](#telling-whether-a-commit-has-left-your-machine)

**[What a rewrite does to someone else's clone](#what-a-rewrite-does-to-someone-else-s-clone)**

- [What does the other person see the next time they fetch?](#what-the-other-clone-sees)
- [A colleague pulled after I rebased and now sees every commit twice. What did I do?](#what-a-plain-pull-does)
- [Why did their `git pull` make a merge commit instead of taking my new commits?](#what-a-plain-pull-does)
- [If my rewrite only renames commits, why can't Git match them up by itself?](#what-a-plain-pull-does)

**[The rule, and what it actually says](#the-rule-and-what-it-actually-says)**

- [Is "never rewrite public history" a rule or advice?](#the-rule-and-what-it-actually-says)
- [My branch is pushed to my own fork and nobody else uses it. May I rebase it?](#the-rule-and-what-it-actually-says)
- [My whole team rebases their review branches before merging. Are we all doing it wrong?](#the-rule-and-what-it-actually-says)
- [Who counts as "other people" — does a build server count?](#the-rule-and-what-it-actually-says)

**[When someone else rewrites under you](#when-someone-else-rewrites-under-you)**

- [Someone rebased the branch mine is based on. How do I move my commits over?](#replaying-your-own-commits)
- [Why did Git skip some of my commits, and is that safe?](#replaying-your-own-commits)
- [The same change is now in history twice. How do I clean that up?](#saying-where-your-own-work-starts)
- [My rebase brought back commits that had been deliberately dropped. Why?](#saying-where-your-own-work-starts)

**[Rewriting a branch other people use](#rewriting-a-branch-other-people-use)**

- [Is there a form of force-push that refuses when someone else has pushed?](#a-lease-on-the-branch)
- [My push was rejected with "stale info". What does that mean?](#a-lease-on-the-branch)
- [What would `--force` have done instead?](#what-force-would-have-done)
- [I have changed my mind halfway. How do I get back to what the server has?](#backing-out-of-the-rewrite)
- [What do I tell the others to run afterwards?](#backing-out-of-the-rewrite)
- [Should I delete the branch and push under a new name instead?](#backing-out-of-the-rewrite)

**[A rewrite does not delete anything](#a-rewrite-does-not-delete-anything)**

- [I rewrote history to remove a password. Is it gone?](#a-rewrite-does-not-delete-anything)
- [Why can I still reach the old commit by its hash, here and on the server?](#a-rewrite-does-not-delete-anything)
- [Does rewriting on my machine change what is on the server?](#a-rewrite-does-not-delete-anything)

**[Rewriting or a new commit](#rewriting-or-a-new-commit)**

- [Should I fix this by rewriting or by adding a commit?](#rewriting-or-a-new-commit)
- [Which of these commands are safe on a branch other people have?](#rewriting-or-a-new-commit)

**[The settings](#the-settings)**

- [Can a server refuse a rewrite outright?](#the-settings)
- [Which settings change the warnings and the safety net?](#the-settings)

</details>

## Which commands rewrite

| Command | What it does to history | Chapter |
|---|---|---|
| `git commit --amend` | replaces the commit at the tip of the branch | Chapter 29 |
| `git reset` | moves the branch, abandoning the commits it moved off | Chapter 30 |
| `git rebase` | copies a range of commits onto a new parent and moves the branch to the copies | Chapter 33 |
| `git rebase -i` | the same, plus reordering, dropping, splitting and combining | Chapter 34 |
| `git history fixup`, `reword`, `split` | replaces one commit in the middle of a branch, and everything after it | Chapter 35 |
| `git filter-branch`, `git filter-repo` | rebuilds every commit in the repository | Chapter 37 |
| `git branch -f`, `git switch -C`, `git update-ref` | move a branch without making any commit | Chapter 23, Chapter 74 |
| `git push --force`, `--force-with-lease` | replaces a branch on the server with one that is not a descendant | Chapter 43 |

And these, which are often called rewriting and are not:

| Command | What it does to history | Chapter |
|---|---|---|
| `git revert` | adds a commit that undoes an old one; the old one stays exactly where it was | Chapter 31 |
| `git cherry-pick` | adds a copy of a commit here; the original stays where it was | Chapter 32 |
| `git merge` | adds a commit with two parents; both sides keep every commit they had | Chapter 25 |
| `git notes`, `git replace` | attach or substitute without touching the commit | Chapter 38 |

The test is not whether a command makes new objects — `git revert` and
`git cherry-pick` both do. It is whether a commit that the branch used to
contain is no longer in it afterwards.

`git branch -f` is in the first table for that reason. It makes nothing at all,
but a branch moved backwards no longer contains the commits it did, and anyone
who fetches it sees exactly what they would see after a rebase.

## The example repository

```console
$ git log --oneline --graph --all --decorate
* f3ab852 (origin/keys) Add a note about the alarm
* 25f4eb7 (HEAD -> keys) Mention the cabinet key
* 04d9056 Note where the spare key is
| * 22d22a3 (origin/main, origin/HEAD) Add the phone number
|/  
* beec938 (main) Add the address
* 522a502 Add the opening hours
* 6d48f3d Start the handbook
```

A team handbook, in three places at once:

| Place | Is |
|---|---|
| `/home/ada/server.git` | a bare repository, the `origin` both clones push to, spelled `../server.git` in each |
| `/home/ada/handbook` | Ada's clone, where most examples run |
| `/home/ada/handbook-sam` | Sam's clone, a second person's copy of the same repository |

Ada wrote `main` and the branch `keys`, and pushed both. Sam cloned, added
`Add the phone number` to `main`, and added one commit of his own on top of
Ada's `keys`:

```console
$ git log -2 --format='%h %an %s' origin/keys
f3ab852 Sam Chen Add a note about the alarm
25f4eb7 Ada Lovelace Mention the cabinet key
```

The two clones are on one machine and `origin` is a directory, so the examples
need no network; a real `origin` on a server behaves the same way. Where an
example moves from one clone to the other it shows the `cd`, so the transcript
always says which repository the next command runs in.

## What counts as rewriting

```console
$ git log --oneline -2
beec938 Add the address
522a502 Add the opening hours
$ git revert --no-edit HEAD
[scratch b1707ea] Revert "Add the address"
 Date: Mon Jan 5 16:00:00 2026 +0000
 1 file changed, 1 deletion(-)
 delete mode 100644 address.md
$ git log --oneline -3
b1707ea Revert "Add the address"
beec938 Add the address
522a502 Add the opening hours
```

`beec938` is still there, still says the same thing, still has the same name.
The branch grew by one commit. Anyone who already had `beec938` still has it,
and their next pull is an ordinary fast-forward.

```console
$ git commit --amend -q -m 'Take the address out again, it was wrong' && git log --oneline -3
deff658 Take the address out again, it was wrong
beec938 Add the address
522a502 Add the opening hours
```

`b1707ea` has gone from the branch and `deff658` has taken its place. Nothing
was edited: `deff658` is a new commit, built from the same tree and the same
parent with a different message, and the branch was moved to it. That is the
smallest possible rewrite, and it is the same operation as the largest one.

> **Worth knowing.** The two commands have the same effect on the *files*. They
> differ entirely in what they do to the *history*, and that is the only thing
> the rule in this chapter is about.

## Why a rewritten commit is a new commit

```console
$ git log --format='%h %p %s' -4
25f4eb7 04d9056 Mention the cabinet key
04d9056 beec938 Note where the spare key is
beec938 522a502 Add the address
522a502 6d48f3d Add the opening hours
```

`%p` is the parent's hash (Chapter 17). Every commit names its parent, and the
parent's name is part of what the commit's own name is computed from, so the
chain is fixed in both directions: change anything about a commit and its name
changes, and every commit that named it as a parent must be rebuilt too.

```console
$ git rebase origin/main
Rebasing (1/2)
Rebasing (2/2)
Successfully rebased and updated refs/heads/keys.
$ git log --format='%h %p %s' -4
a2e3543 72b5b34 Mention the cabinet key
72b5b34 22d22a3 Note where the spare key is
22d22a3 beec938 Add the phone number
beec938 522a502 Add the address
```

Nothing was edited here either. `Note where the spare key is` has the same
message, the same author and the same change as before; only its parent is
different, `22d22a3` instead of `beec938`. That was enough to make it
`72b5b34` instead of `04d9056`. `Mention the cabinet key` then had no choice:
its parent had been renamed, so it was rebuilt as `a2e3543`.

This is why rewriting one old commit rewrites everything after it, and why the
cost of a rewrite grows with how far back it reaches. It is also why no
command can offer to rewrite a commit "in place": there is no such thing.

> **Worth knowing.** The commit's name also covers its committer and the
> committer's date, so two rebases of the same commits a second apart produce
> different hashes. Chapter 33 shows which fields survive a rebase and which
> are replaced.

The two progress lines are one line on a terminal: Git ends them with a
carriage return rather than a newline, so each is drawn over the last.

## Where the old commits go

```console
$ git reflog -3
a2e3543 HEAD@{0}: rebase (finish): returning to refs/heads/keys
a2e3543 HEAD@{1}: rebase (pick): Mention the cabinet key
72b5b34 HEAD@{2}: rebase (pick): Note where the spare key is
$ git cat-file -t 25f4eb7
commit
$ git show -s --oneline 25f4eb7
25f4eb7 Mention the cabinet key
```

The old commit is untouched. `git log` stopped showing it because `git log`
walks back from a ref, and no ref leads to `25f4eb7` any more — not because
anything was removed. Given the name, Git still has the object.

The name is the problem: after a rewrite you rarely still have it. That is
what the *reflog* is for. It records every value each ref has held, so the
commit you just replaced has a name again:

```console
$ git log --oneline -1 keys@{1}
25f4eb7 Mention the cabinet key
```

`keys@{1}` is "where `keys` pointed one move ago". Chapter 36 covers the
reflog, Chapter 30 uses it to undo a reset, and Chapter 79 is the full recovery
procedure.

**How long you have.** Reflog entries expire: 90 days for entries still
reachable from the branch, 30 for the rest, and `git gc` deletes objects that
nothing reaches once they are older than two weeks. In practice you have weeks,
not minutes. None of it helps in a clone that never had the commit, and none of
it runs on the server, where reflogs are off by default.

## Telling whether a commit has left your machine

The rule turns on one question — has anyone else got these commits? — and Git
can answer most of it.

```console
$ git branch -r --contains 04d9056
  origin/keys
$ git branch -r --contains HEAD
```

`-r` lists remote-tracking branches, and `--contains` keeps only those that
have the commit in their history (Chapter 23). `04d9056` is on `origin/keys`,
so it is on the server and anyone who has fetched may have it. The commit at
`HEAD` is on no remote-tracking branch, so as far as this clone knows it has
never left the machine.

> **Careful.** A remote-tracking branch says what the server looked like the
> last time you fetched, not what it looks like now. `git fetch` first, or the
> answer is as old as your last fetch.

```console
$ git status -sb
## keys...origin/keys [ahead 3, behind 3]
```

Three commits on each side that the other does not have: the branch and its
upstream have *diverged*, which after a rebase is the normal state and means
"I have rewritten commits that the server still has the originals of"
(Chapter 10).

The two halves of that can be listed:

```console
$ git log --oneline HEAD..@{upstream}
f3ab852 Add a note about the alarm
25f4eb7 Mention the cabinet key
04d9056 Note where the spare key is
```

`HEAD..@{upstream}` is "commits on the upstream that are not in my branch"
(Chapter 18), which is exactly the list a force-push would throw off the
branch. Two of them are the originals of commits that were just rewritten and
are no loss. `f3ab852` is Sam's, and is not in the rewritten history at all —
force-pushing now would take his commit off the branch.

```console
$ git log --oneline @{upstream}..HEAD
a2e3543 Mention the cabinet key
72b5b34 Note where the spare key is
22d22a3 Add the phone number
```

The other direction is what the push would add.

```console
$ git log --oneline --graph HEAD @{upstream}
* a2e3543 Mention the cabinet key
* 72b5b34 Note where the spare key is
* 22d22a3 Add the phone number
| * f3ab852 Add a note about the alarm
| * 25f4eb7 Mention the cabinet key
| * 04d9056 Note where the spare key is
|/  
* beec938 Add the address
* 522a502 Add the opening hours
* 6d48f3d Start the handbook
```

Naming both and drawing the graph shows the shape of the problem: two parallel
copies of the same work that meet only at `beec938`.

| To find out | Run |
|---|---|
| Is this commit on the server? | `git branch -r --contains <commit>` |
| Which of my branches contain it? | `git branch --contains <commit>` |
| Have I pushed my current branch? | `git status -sb`, or `git log --oneline @{upstream}..HEAD` |
| What would a force-push throw away? | `git log --oneline HEAD..@{upstream}` |
| Has anyone built on top of it? | nothing local can tell you; ask, or look at the forge |

The last row is the honest limit. Git knows what your clone has fetched. It
cannot know that a colleague has your branch checked out with three commits on
top that they have not pushed, and no command will ever tell you that.

## What a rewrite does to someone else's clone

```console
$ git push --force-with-lease origin keys
To ../server.git
 + f3ab852...a2e3543 keys -> keys (forced update)
```

The `+` and `(forced update)` mark a push that was not a fast-forward: the
branch on the server now points at `a2e3543`, and `f3ab852` — Sam's commit —
is no longer on it. Nothing was deleted from the server, but nothing on the
server leads to it any more.

### What the other clone sees

```console
$ cd ../handbook-sam
$ git fetch origin
From ../server
 + f3ab852...a2e3543 keys       -> origin/keys  (forced update)
$ git status -sb
## keys...origin/keys [ahead 3, behind 3]
```

Sam's `keys` is unchanged — a fetch never touches your own branches — but his
`origin/keys` has jumped sideways, and his branch is now diverged from it. He
did nothing; the divergence arrived in the post.

His three "ahead" commits are `Note where the spare key is`, `Mention the
cabinet key` and his own `Add a note about the alarm`. The first two are Ada's
originals, which he has no way of knowing have been replaced rather than
abandoned.

### What a plain pull does

```console
$ git pull --no-rebase --no-edit
Merge made by the 'ort' strategy.
 phone.md | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 phone.md
$ git log --oneline --graph -7
*   5b49ab1 Merge branch 'keys' of ../server into keys
|\  
| * a2e3543 Mention the cabinet key
| * 72b5b34 Note where the spare key is
| * 22d22a3 Add the phone number
* | f3ab852 Add a note about the alarm
* | 25f4eb7 Mention the cabinet key
* | 04d9056 Note where the spare key is
|/  
```

This is the classic mess, and it is the single most common consequence of a
rewrite. `git pull` fetched and then merged, because merging is what it does
with a diverged branch, and both copies of Ada's work are now permanently in
the history:

```console
$ git log --oneline --grep='Note where the spare key is'
72b5b34 Note where the spare key is
04d9056 Note where the spare key is
```

The files came out right — the merge had nothing to reconcile, since both sides
contain the same content — so nothing warns Sam that anything is wrong. He
pushes, and from then on everyone's `git log` has every rewritten commit twice.

**Why Git cannot fix this by itself.** `git merge` works on commits, and these
are different commits. It has no reason to believe that `04d9056` and
`72b5b34` are the same work: identical messages are a coincidence as far as
Git is concerned, and a rewrite is free to change the content too. The one
command that does look at changes rather than commits is `git rebase`, which
is what Sam should have run, and [When someone else rewrites under
you](#when-someone-else-rewrites-under-you) does.

> **Careful.** With `pull.rebase` unset, modern Git refuses a diverged pull and
> asks you to choose (Chapter 42). The example passes `--no-rebase` to get the
> merge that older setups produce by default, and that a reader who has
> configured merging will get without asking.

## The rule, and what it actually says

The short form — "never rewrite public history" — is a useful slogan and a bad
rule, because "public" is not the thing that matters. What matters is whether
anyone else's work is built on the commits you are about to replace.

**The test.** Before rewriting, ask in this order:

1. Are the commits only in this clone? Rewrite them. Nothing else can be
   affected, and no conversation is needed.
2. Are they pushed, but on a branch nobody else builds on — your own topic
   branch, a fork, a review branch that belongs to you? Rewrite them and
   force-push. This is normal practice, and the whole of "clean up the branch
   before it is merged" depends on it.
3. Does anyone else have them? Then a rewrite costs each of those people the
   recovery in [When someone else rewrites under
   you](#when-someone-else-rewrites-under-you), and costs anyone who gets it
   wrong the duplicate history above. Agree it first, or add a commit instead.
4. Is it a branch the team treats as the trunk — `main`, `master`, a release
   branch? Do not rewrite it. Not because the commits are public, but because
   everyone builds on it and nobody expects to check.

**Who "other people" are.** Anyone with a clone that has the commits. That
includes:

| Also counts as another person | Because |
|---|---|
| your own second clone or worktree | it has the old commits and will diverge from itself |
| a build server that clones on every run | its next run fetches a branch that is not a descendant of the last |
| a mirror of the repository | it either refuses the update or copies the rewrite onward |
| an open pull or merge request | the forge keeps the old commits and shows them; the review comments hang off them (Chapter 50, Chapter 51) |
| a tag pointing into the range | tags do not move, so the tag keeps the old commits alive and reachable (Chapter 47) |

A build server counts, but cheaply: it has no work of its own to lose, so the
worst case is a wasted run. A colleague with unpushed commits is the expensive
case.

**What the rule is not.** It is not a rule about hashes being sacred, and it is
not an argument for merging over rebasing. Teams that rebase every branch
before merging rewrite history constantly, obey the rule exactly, and have
tidier history than teams that never rewrite anything. The rule only says: know
who is holding the other end.

## When someone else rewrites under you

This is the other half of the story, and every developer needs it, because
sooner or later someone will rewrite a branch you are working on. Sam is where
the [plain pull](#what-a-plain-pull-does) left him, with a merge he does not
want.

### Replaying your own commits

```console
$ git reset --hard f3ab852
HEAD is now at f3ab852 Add a note about the alarm
$ git rebase origin/keys
warning: skipped previously applied commit 04d9056
warning: skipped previously applied commit 25f4eb7
hint: use --reapply-cherry-picks to include skipped commits
hint: Disable this message with "git config set advice.skippedCherryPicks false"
Rebasing (1/1)
Successfully rebased and updated refs/heads/keys.
$ git log --oneline --graph -5
* 1a277bf Add a note about the alarm
* a2e3543 Mention the cabinet key
* 72b5b34 Note where the spare key is
* 22d22a3 Add the phone number
* beec938 Add the address
```

`git reset --hard f3ab852` undoes the merge by putting the branch back where it
was before the pull (Chapter 30). Then `git rebase origin/keys` replays Sam's
commits on top of the rewritten branch — and skips two of them.

The skipping is the useful part. Before replaying anything, rebase compares the
*changes* on both sides by patch id, which ignores the commit's name, its
message and where the lines sit in the file. `04d9056` and `72b5b34` make the
same change, so the copy is dropped as already applied, and the history comes
out with one of each commit and Sam's own work on the end.

It is safe here because the two histories really do contain the same changes.
When they do not — because the rewrite edited content, dropped a commit or
squashed several into one — the comparison stops matching and rebase replays
commits that are already there in another form. Chapter 33 covers that case,
which Git's own documentation calls the hard
case.

> **Careful.** A commit that was *deliberately dropped* during the rewrite will
> come back, because from rebase's point of view it is simply a change the
> upstream does not have. If the rewrite existed to remove something, check the
> result rather than trusting the replay.

### Saying where your own work starts

The general answer, which does not depend on Git recognising anything, is to
tell it where your own commits begin:

```console
$ git reset --hard f3ab852
HEAD is now at f3ab852 Add a note about the alarm
$ git rebase --onto origin/keys f3ab852~1
Rebasing (1/1)
Successfully rebased and updated refs/heads/keys.
$ git log --oneline -5
1a277bf Add a note about the alarm
a2e3543 Mention the cabinet key
72b5b34 Note where the spare key is
22d22a3 Add the phone number
beec938 Add the address
```

`git rebase --onto <new-base> <old-base>` means "take the commits after
`<old-base>`, and put them on `<new-base>`" (Chapter 33). Here `<old-base>` is
`f3ab852~1`, the last commit Sam did not write, so exactly his own commit is
moved and the rewritten copies are never considered at all. The result is the
same commit, `1a277bf`, as the replay produced.

| Situation | Command |
|---|---|
| The rewrite kept the same changes | `git rebase <upstream>` and let it skip |
| The rewrite changed, dropped or combined commits | `git rebase --onto <upstream> <last-commit-that-is-not-mine>` |
| You have nothing of your own on the branch | `git reset --hard <upstream>` |
| You are not sure what you have | `git log --oneline <upstream>..HEAD` first |

Once he is happy, Sam pushes normally, because his branch is now a descendant
of what the server has:

```console
$ git push -q origin keys && git log --oneline -1 origin/keys
1a277bf Add a note about the alarm
```

## Rewriting a branch other people use

Ada, meanwhile, has decided the wording of `Mention the cabinet key` was
incomplete and amends it — a second rewrite of a branch Sam is using, and she
has not fetched since his push.

### A lease on the branch

```console
$ cd ../handbook
$ git add keys.md && git commit --amend -q --no-edit && git log --oneline -1
4437301 Mention the cabinet key
$ git push --force-with-lease origin keys
To ../server.git
 ! [rejected]        keys -> keys (stale info)
error: failed to push some refs to '../server.git'
```

`--force-with-lease` forces the update only if the branch on the server is
still where your remote-tracking branch says it is. Sam pushed since Ada's last
fetch, so it is not, and the push is refused: *stale info* means "your
information about this branch is out of date", not "your commits are wrong".

The rejection is the option's entire purpose. It is what stands between a
rewrite and the loss of work you did not know existed.

```console
$ git fetch origin
From ../server
   a2e3543..1a277bf  keys       -> origin/keys
$ git log --oneline HEAD..@{upstream}
1a277bf Add a note about the alarm
a2e3543 Mention the cabinet key
```

After fetching, the list of what the push would have thrown away is two
commits: `a2e3543`, the commit Ada replaced, which is no loss, and `1a277bf`,
which is Sam's and was written after her last fetch.

> **Careful.** The lease is a lease on *your* last fetch, not a lock. Fetch,
> then force-push without looking at what arrived, and it will happily let you
> clobber it: you now "expect" what the server has. Anything that fetches in the
> background — an editor, a scheduled job — defeats it for the same reason.
> `--force-if-includes` closes that particular hole by also requiring the
> remote's tip to be in your branch's reflog; Chapter 43 covers both.
>
> **Since Git 2.30.** `--force-if-includes`.

### What --force would have done

The same situation, on a throwaway branch called `spike`, so that the answer
can be seen rather than described. Ada has amended her one commit there, and
Sam has pushed a commit on top of the old one:

```console
$ git add spike.md && git commit --amend -q -m 'Start the spike again' && git log --oneline -1
1bef761 Start the spike again
$ git push --force-with-lease origin spike
To ../server.git
 ! [rejected]        spike -> spike (stale info)
error: failed to push some refs to '../server.git'
$ git push --force origin spike
To ../server.git
 + a9f8aa2...1bef761 spike -> spike (forced update)
```

`--force` disables the lease check along with the fast-forward rule, so the
push it had just refused went through. On the server:

```console
$ git -C /home/ada/server.git log --oneline spike
1bef761 Start the spike again
beec938 Add the address
522a502 Add the opening hours
6d48f3d Start the handbook
$ git -C /home/ada/server.git branch --contains a9f8aa2
```

Sam's commit `a9f8aa2` is on no branch on the server. The last command printed
nothing at all, which is the answer: the object is still in the repository, but
nothing reaches it, and the next `git gc` there will delete it. Sam's clone
still has it, so this is recoverable — as long as somebody notices.

| Option | Refuses when | Use |
|---|---|---|
| `git push` | the update is not a fast-forward | always, unless you meant to rewrite |
| `git push --force-with-lease` | the server's branch has moved since your last fetch | rewriting a branch you pushed |
| `git push --force` | never | when you have checked by hand, and know what is there |

### Backing out of the rewrite

Ada's amend was to a commit Sam has already built on, so rewriting it means
making Sam do the recovery again. The cheap alternative is to stop rewriting
and add a commit instead:

```console
$ git reset --hard origin/keys
HEAD is now at 1a277bf Add a note about the alarm
$ git commit -q -am 'Say when the keys go back' && git push -q origin keys
$ git log --oneline --graph -4
* 20f4d6f Say when the keys go back
* 1a277bf Add a note about the alarm
* a2e3543 Mention the cabinet key
* 72b5b34 Note where the spare key is
```

`git reset --hard origin/keys` throws away the amended commit and puts the
branch exactly where the server has it; the edit itself is then made again as a
new commit and pushed with an ordinary push. Nobody has to do anything, and
nothing about the branch's earlier history changed.

**If you do go ahead with the rewrite,** the message to the other people is
short and worth sending before the push, not after:

> I force-pushed `keys`. If you have work on it: `git fetch`, then
> `git rebase origin/keys`, or `git rebase --onto origin/keys <your first
> commit>~1` if that duplicates anything. Do not `git pull`.

**Pushing under a new name instead** is the other way out, and often the
kindest: push the rewritten branch as `keys-v2`, leave `keys` alone, and let
people move over when they are ready. It costs a branch name and saves every
recovery in this chapter. It is also what a forge does for you if you close the
pull request and open another.

## A rewrite does not delete anything

```console
$ git cat-file -t 25f4eb7
commit
$ git -C /home/ada/server.git cat-file -t 25f4eb7
commit
$ git -C /home/ada/server.git log --oneline -1 25f4eb7
25f4eb7 Mention the cabinet key
```

`25f4eb7` was replaced by a rebase and pushed over with a forced update, and it
is still a readable commit in Ada's clone *and* on the server. The force-push
moved a branch; it did not send an instruction to delete anything, because
there is no such instruction in Git's protocol.

```console
$ git -C /home/ada/server.git branch --contains 25f4eb7
```

No branch on the server contains it: that is the whole of what the rewrite
achieved. The commit is unreachable, which means it no longer appears in any
log, and that Git is free to delete it during garbage collection — eventually,
locally, and only where nothing else keeps it alive.

**What this means in practice.**

| Question | Answer |
|---|---|
| Can I get my old commit back? | Yes, from the reflog, for weeks (Chapter 36) |
| Did the rewrite remove the secret I committed? | No. The blob is still an object here, on the server, and in every other clone (Chapter 37) |
| Will the server ever clean up? | It garbage-collects on its own schedule, which you do not control; a forge may keep the commit reachable for its own reasons, such as an open pull request |
| Does anything I do locally change another clone? | Never. Every clone is cleaned up by whoever runs the commands in it |

Chapter 37 is about the case where "unreachable" is not good enough, and it is
the hardest chapter in the book for exactly this reason.

## Rewriting or a new commit

Almost every mistake can be fixed either way. The choice is not about which is
tidier; it is about who else is holding the commits.

| Mistake | Only yours | Already shared |
|---|---|---|
| Wrong message on the last commit | `git commit --amend` (Chapter 29) | a new commit, or leave it; or `git notes` to annotate without touching it (Chapter 38) |
| Forgot a file in the last commit | `git commit --amend` (Chapter 29) | a follow-up commit |
| Wrong message on an older commit | `git rebase -i`, `reword` (Chapter 34), or `git history reword` (Chapter 35) | leave it |
| A bad commit, several back | `git rebase -i`, `drop` (Chapter 34) | `git revert` (Chapter 31) |
| Committed on the wrong branch | `git reset` and re-commit (Chapter 30), or `git cherry-pick` then reset | `git cherry-pick` onto the right branch (Chapter 32), then revert on the wrong one |
| Several messy commits | `git rebase -i`, `squash` (Chapter 34) | leave them; squash when the branch is merged instead (Chapter 25) |
| A committed secret | Chapter 37, and change the secret | Chapter 37, and change the secret first |

The row that matters most is the fourth: `git revert` is the answer to almost
every "this commit was wrong" on a shared branch, it needs no coordination, and
it leaves a record of the decision that a rewrite would have erased.

## The settings

| Setting | Does | Chapter |
|---|---|---|
| `receive.denyNonFastForwards` | On the server: refuse any push that is not a fast-forward, `--force` included. Set by default in a repository created with `--shared` | Chapter 43 |
| `advice.skippedCherryPicks` | Set to `false` to stop the "skipped previously applied commit" hint during a rebase | Chapter 33 |
| `pull.rebase` | What `git pull` does with a diverged branch: merge, rebase, or refuse | Chapter 42 |
| `gc.reflogExpire`, `gc.reflogExpireUnreachable` | How long the reflog keeps a replaced commit findable, 90 and 30 days | Chapter 36 |
| `core.logAllRefUpdates` | Whether reflogs are written at all; off in a bare repository, which is why a server has no safety net | Chapter 36 |

The last two are the ones worth knowing before you need them: the reason a
rewrite is recoverable on your machine is `core.logAllRefUpdates`, and the
reason it is not recoverable on the server is the same setting being off there.
