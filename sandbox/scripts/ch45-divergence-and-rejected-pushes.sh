#!/bin/bash
# Generates every transcript in Chapter 45, "Divergence and Rejected Pushes".
#
#   bash sandbox/scripts/ch45-divergence-and-rejected-pushes.sh [dir]
#
# No `set -e`: pushes are shown being rejected, and merges and rebases stopping
# with conflicts.
#
# The team's bare "server", Ada's clone, where every transcript runs, and Bob's
# clone, which commits and pushes out of sight with `bob_push`. Both clones use
# the relative URL ../server/atlas.git, because merge messages name the URL
# and an absolute sandbox path would change their hashes on every run.
#
# The ways of reconciling one diverged branch are shown from the same state:
# Ada's `main` is put back with a quiet `git reset --hard` between them, and
# only dry runs are pushed until the chapter picks one. Every demo that stops
# with a conflict ends with its --abort.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# bob_push <branch> <file> <message> <line>... : Bob brings <branch> up to
# date with the server, commits a file on it, and pushes it.
bob_push() {
	local branch="$1" file="$2" message="$3"; shift 3
	( cd "$SANDBOX_ROOT/bob" && git fetch -q origin &&
	  git switch -q -C "$branch" "origin/$branch" &&
	  sb_write "$file" "$@" && git add -A &&
	  git commit -q -m "$message" && git push -q origin "$branch" ) >/dev/null 2>&1
	sb_tick
}
# ada_commit <file> <message> <line>... : a commit in Ada's clone, not shown
ada_commit() {
	local file="$1" message="$2"; shift 2
	sb_write "$file" "$@" && git add -A && git commit -q -m "$message"
	sb_tick
}

# ---------------------------------------------------------------------------
sb_fresh "$SANDBOX_ROOT/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "France" "Germany" "Italy"
sb_commit "Add Europe"
git branch rivers
git init -q --bare "$SANDBOX_ROOT/server/atlas.git"
git push -q "$SANDBOX_ROOT/server/atlas.git" main rivers
cd "$SANDBOX_ROOT"
rm -rf work
git clone -q server/atlas.git bob
git clone -q server/atlas.git ada
git -C bob remote set-url origin ../server/atlas.git
cd ada
git remote set-url origin ../server/atlas.git

sb_say "The example repositories"
sb_run "git remote -v"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Two people, one branch"
bob_push main maps/asia.txt "Add Asia" "Asia"
ada_commit notes.txt "Write a note" "Check the borders"
sb_run "git status -sb"
sb_run "git remote show origin | tail -2"
sb_run "git fetch && git status -sb"

# ---------------------------------------------------------------------------
sb_say "Seeing both sides"
bob_push main maps/africa.txt "Add Africa" "Africa"
ada_commit notes.txt "Write another note" "Check the borders" "Check the rivers"
sb_run "git fetch -q && git status -sb"
sb_run "git rev-list --left-right --count main...origin/main"
sb_run "git log --oneline --left-right main...origin/main"
sb_run "git log --oneline -1 \$(git merge-base main origin/main)"
sb_run "git diff --stat origin/main...main && git diff --stat main...origin/main"
sb_run "git merge-tree --write-tree --name-only main origin/main; echo \"exit \$?\""
sb_run "git branch -vv"
DIVERGED=$(git rev-parse main)

# ---------------------------------------------------------------------------
sb_say "Merge, then push"
sb_run "git merge --no-edit origin/main && git log --oneline --graph -6 && git push --dry-run"
git reset -q --hard "$DIVERGED"

sb_say "Rebase, then push"
sb_run "git rebase origin/main && git log --oneline --graph -5 && git push --dry-run"
git reset -q --hard "$DIVERGED"

sb_say "Move your commits to a branch of their own"
sb_run "git switch -q -c border-notes && git push -u origin border-notes"
sb_run "git switch -q main && git reset --hard origin/main && git status -sb"
git reset -q --hard "$DIVERGED"

sb_say "Take only some of your commits"
sb_run "git branch -q mine && git reset -q --hard origin/main && git cherry-pick mine~1 && git log --oneline -3"
git reset -q --hard "$DIVERGED"
git branch -q -D mine

sb_say "Keep the server's version"
sb_run "git reset --hard origin/main && git branch rescued ORIG_HEAD && git log --oneline -2 rescued"
git reset -q --hard "$DIVERGED"
git branch -q -D rescued

sb_say "Keep your version"
sb_run "git log --oneline main..origin/main && git push --force-with-lease --dry-run"

sb_say "Someone pushed again in between"
sb_run "git pull -q --rebase && git log --oneline -3"
bob_push main maps/oceania.txt "Add Oceania" "Oceania"
sb_run "git push; echo \"exit \$?\""
sb_run "git pull -q --rebase && git push"

# ---------------------------------------------------------------------------
sb_say "When both sides changed the same lines"
bob_push main maps/europe.txt "Add Berlin" "France" "Germany, capital Berlin" "Italy"
ada_commit maps/europe.txt "Use the German name" "France" "Deutschland" "Italy"
ada_commit maps/europe.txt "Add the country code" "France" "Deutschland (DE)" "Italy"
git fetch -q
sb_run "git merge origin/main; echo \"exit \$?\""
sb_run "git merge --abort && git rebase origin/main 2>&1 | grep -E 'CONFLICT|Could not apply'"
sb_run "printf 'France\nDeutschland, capital Berlin\nItaly\n' > maps/europe.txt && git add maps/europe.txt && GIT_EDITOR=true git rebase --continue 2>&1 | grep -E 'CONFLICT|Could not apply|Successfully'"
sb_run "git diff"
sb_run "git rebase --abort && git log --oneline -1"
# Ada settles it with the merge, and publishes it.
git merge -q origin/main >/dev/null 2>&1
sb_write maps/europe.txt "France" "Deutschland (DE), capital Berlin" "Italy"
git add maps/europe.txt
git commit -q --no-edit
sb_tick
git push -q

# ---------------------------------------------------------------------------
sb_say "Rewriting commits you had pushed"
ada_commit notes.txt "Write the notes" "Check the borders" "Check the rivers" "Check the seas" "Check the mountains" "Check the deserts"
git push -q
sb_run "git commit -q --amend -m 'Write the travel notes' && git status -sb"
sb_tick
sb_run "git log --oneline --left-right --cherry-mark main...origin/main"
sb_run "git range-diff origin/main...main"
sb_run "git push --force-with-lease"

sb_say "Someone had built on them"
bob_push main comments.txt "Comment on the notes" "The seas need a map"
sb_write notes.txt "Check the borders" "Check the rivers" "Check the oceans" "Check the mountains" "Check the deserts"
sb_run "git commit -q -a --amend --no-edit && git fetch -q && git status -sb"
sb_tick
sb_run "git range-diff origin/main...main"
sb_run "git push --force-with-lease --force-if-includes; echo \"exit \$?\""
sb_run "git reset -q --hard origin/main && sed -i 's/seas/oceans/' notes.txt && git commit -q -am 'Say oceans, not seas' && git push"
sb_tick

# ---------------------------------------------------------------------------
sb_say "A branch that is only behind"
sb_run "git reset -q --hard HEAD~1 && git status -sb && git push; echo \"exit \$?\""
sb_run "git pull && git status -sb"

sb_say "A branch you are not on"
bob_push rivers rivers.txt "List the Nile" "Nile"
git switch -q rivers
ada_commit rivers.txt "List the Danube" "Danube"
git switch -q main
git fetch -q
sb_run "git push origin rivers; echo \"exit \$?\""
sb_run "git branch -vv"
