#!/bin/bash
# Generates every transcript in Chapter 50, "Forks and Pull Requests on GitHub".
#
#   bash sandbox/scripts/ch50-forks-and-pull-requests-on-github.sh [dir]
#
# No `set -e`: a push to a pull request's ref is shown being refused, and
# `git branch -d` refuses a squash-merged branch.
#
# Nothing here reaches GitHub. Two bare repositories stand in for it:
#
#   github/ada/atlas.git   the original project, maintained by Ada
#   github/bob/atlas.git   Bob's fork of it, made with `git clone --bare`,
#                          which copies every branch, as GitHub's Fork button
#                          does unless told to copy the default branch only
#
# What GitHub does on its side is done here by hand, out of sight, with
# `open_pr`: it copies the pull request's branch into the original as
# refs/pull/<n>/head, and a test merge of it as refs/pull/<n>/merge, the refs
# GitHub's documentation names. `receive.hideRefs` makes the stand-in refuse
# pushes to refs/pull/ with the same message GitHub's documentation quotes.
#
# Ada's clone (ada/atlas) and Bob's (bob/atlas) reach the stand-ins by relative
# URLs, because merge messages can name a URL and an absolute sandbox path would
# change their hashes on every run. `as_ada` and `as_bob` move between the
# clones and set the identity; the clock is shared, so hashes stay stable.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"
UP="$R/github/ada/atlas.git"
FORK="$R/github/bob/atlas.git"

as_ada() {
	export GIT_AUTHOR_NAME="Ada Lovelace" GIT_AUTHOR_EMAIL="ada@example.com"
	export GIT_COMMITTER_NAME="Ada Lovelace" GIT_COMMITTER_EMAIL="ada@example.com"
	cd "$R/ada/atlas"
}
as_bob() {
	export GIT_AUTHOR_NAME="Bob Brown" GIT_AUTHOR_EMAIL="bob@example.com"
	export GIT_COMMITTER_NAME="Bob Brown" GIT_COMMITTER_EMAIL="bob@example.com"
	cd "$R/bob/atlas"
}
# open_pr <n> <branch> : GitHub's side of a pull request from Bob's fork:
# refs/pull/<n>/head is the branch, refs/pull/<n>/merge a test merge of it
# into main. Run again after every push to the branch, as GitHub updates both.
open_pr() {
	local n="$1" branch="$2" tree merge
	git -C "$UP" fetch -q "$FORK" "+refs/heads/$branch:refs/pull/$n/head"
	tree="$(git -C "$UP" merge-tree --write-tree main "refs/pull/$n/head")"
	merge="$(git -C "$UP" commit-tree -p main -p "refs/pull/$n/head" -m "Test merge" "$tree")"
	git -C "$UP" update-ref "refs/pull/$n/merge" "$merge"
}

# ---------------------------------------------------------------------------
# The original project, in Ada's clone, and its copy on the stand-in GitHub.
sb_fresh "$R/ada/atlas" >/dev/null
sb_write README.md "# Atlas" "" "Maps of Europe and Aisa."
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
sb_write maps/asia.txt "Aisa"
sb_commit "Add Asia"
git switch -q -c drafts
sb_write drafts/oceania.txt "Oceania, draft"
sb_commit "Draft Oceania"
git switch -q main
git init -q --bare "$UP"
git -C "$UP" config receive.hideRefs refs/pull/
git push -q "$UP" main drafts
git remote add origin ../../github/ada/atlas.git
git fetch -q origin
git branch -q -u origin/main main
git branch -q -D drafts

sb_say "Forking"
cd "$R"
git clone -q --bare "$UP" "$FORK"
sb_run "git ls-remote github/ada/atlas.git && git ls-remote github/bob/atlas.git"

# ---------------------------------------------------------------------------
sb_say "Cloning your fork"
git clone -q "$FORK" "$R/bob/atlas"
as_bob
git remote set-url origin ../../github/bob/atlas.git
sb_run "git remote -v"
sb_run "git remote add upstream ../../github/ada/atlas.git && git fetch upstream"
sb_run "git remote -v && git branch -a"

sb_say "Pulling from one, pushing to the other"
sb_run "git config set remote.pushDefault origin && git config set push.default current && git branch -u upstream/main"
sb_run "git rev-parse --abbrev-ref @{upstream} @{push}"

# ---------------------------------------------------------------------------
sb_say "Keeping your fork up to date"
as_ada
sb_write maps/africa.txt "Africa"
sb_commit "Add Africa"
git push -q
as_bob
sb_run "git fetch upstream && git status -sb"
sb_run "git merge --ff-only upstream/main && git push origin main"

# ---------------------------------------------------------------------------
sb_say "A branch for the change"
sb_run "git switch -c fix-asia upstream/main"
sb_run "echo Asia > maps/asia.txt && git commit -q -am 'Fix the spelling of Asia' && git push"
sb_tick
sb_run "git status -sb"

# ---------------------------------------------------------------------------
sb_say "Opening the pull request"
open_pr 1 fix-asia
sb_run "git ls-remote upstream 'refs/pull/*'"

# ---------------------------------------------------------------------------
sb_say "Reviewing a pull request"
as_ada
sb_write maps/oceania.txt "Oceania"
sb_commit "Add Oceania"
git push -q
open_pr 1 fix-asia
sb_run "git fetch origin pull/1/head:pr-1"
sb_run "git log --oneline main..pr-1"
sb_run "git diff --stat main pr-1 && git diff --stat main...pr-1"
sb_run "git fetch -q origin pull/1/merge && git show -s --format=%p FETCH_HEAD && git show -s --format='%h %s' main pr-1"
sb_run "git push origin pr-1:refs/pull/1/head"

# ---------------------------------------------------------------------------
sb_say "Updating the pull request"
as_bob
sb_run "sed -i 's/Aisa/Asia/' README.md && git commit -q -am 'Fix the spelling in the README' && git push"
sb_tick
open_pr 1 fix-asia
sb_run "git fetch -q upstream && git rebase upstream/main"
sb_tick
sb_run "git push --force-with-lease"
open_pr 1 fix-asia
as_ada
sb_run "git fetch origin +pull/1/head:pr-1 && git range-diff main pr-1@{1} pr-1"

sb_say "Changing a contributor's branch"
sb_run "git remote add bob ../../github/bob/atlas.git && git fetch -q bob && git switch -q -c bob-fix-asia bob/fix-asia"
sb_run "sed -i 's/Maps of/Maps of the continents:/' README.md && git commit -q -am 'Reword the README' && git push bob HEAD:fix-asia"
sb_tick
open_pr 1 fix-asia
git switch -q main
as_bob
sb_run "git pull --ff-only origin fix-asia"

# ---------------------------------------------------------------------------
sb_say "Merging the pull request"
as_ada
sb_run "git fetch -q origin +pull/1/head:pr-1 && git log --format='%h %an  %s' main..pr-1"
sb_run "git switch -q -c by-merge main && git merge -q --no-ff -m 'Merge pull request #1 from bob/fix-asia' -m 'Fix the spelling of Asia' pr-1"
sb_tick
sb_run "git switch -q -c by-squash main && git merge -q --squash pr-1 && git commit -q -m 'Fix the spelling of Asia'"
sb_tick
sb_run "git switch -q -c by-rebase pr-1 && git rebase -q main && git rev-parse --short HEAD && git rebase -q --force-rebase main"
sb_tick
sb_run "git log --graph --format='%h %an / %cn  %s' main~1..by-merge"
sb_run "git log --graph --oneline main~1..by-squash"
sb_run "git log --graph --format='%h %an / %cn  %s' main~1..by-rebase"
git switch -q main
sb_run "git merge -q --no-ff -m 'Merge pull request #1 from bob/fix-asia' -m 'Fix the spelling of Asia' pr-1 && git push -q"
sb_tick

sb_say "After a squash"
sb_run "git log --oneline by-squash..pr-1"
git branch -q -D by-merge by-squash by-rebase pr-1

# ---------------------------------------------------------------------------
sb_say "After the merge"
# The "Delete branch" button on the merged pull request.
git -C "$FORK" update-ref -d refs/heads/fix-asia
git branch -q -D bob-fix-asia
as_bob
sb_run "git fetch --prune origin"
sb_run "git switch -q main && git pull --ff-only && git push"
sb_run "git branch -d fix-asia"

# ---------------------------------------------------------------------------
sb_say "A pull request without a hosting service"
sb_run "git switch -q -c add-rivers upstream/main && echo Nile > maps/rivers.txt && git add maps && git commit -q -m 'Add rivers' && git push -q"
sb_tick
sb_run "git request-pull upstream/main ../../github/bob/atlas.git add-rivers"
