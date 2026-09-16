#!/bin/bash
# Generates every transcript in Chapter 30, "reset".
#
#   bash sandbox/scripts/ch30-reset.sh [dir]
#
# No `set -e`: many commands are shown refusing on purpose.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# Every demonstration starts from the same place: the branch `try` recreated at
# main, a clean working tree and an empty index. The reader sees the switch; the
# checkout and clean before it only undo what the previous example left behind.
fresh() {
	git checkout -qf --detach main
	git clean -qfdx
	sb_run "${1:-git switch -q -C try main}"
}

# ---------------------------------------------------------------------------
# A trip plan.
sb_fresh "$SANDBOX_ROOT/trip" >/dev/null
sb_write README.md "# Trip plan"
sb_commit "Start the trip plan"
sb_write route.md "Day 1 Lisbon" "Day 2 Sintra"
sb_commit "Add the route"
sb_write packing.md "boots" "map"
sb_commit "Add the packing list"
sb_write budget.md "trains 60" "food 120"
sb_commit "Add the budget"

git switch -q -c detour HEAD
sb_write route.md "Day 1 Lisbon" "Day 2 Sintra" "Day 3 Faro"
sb_commit "Go on to Faro"
git switch -q main
sb_write route.md "Day 1 Lisbon" "Day 2 Sintra" "Day 3 Evora"
sb_commit "Go on to Evora"

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git status --short --branch"

# ---------------------------------------------------------------------------
sb_say "The three things reset can touch"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git add packing.md && git status --short"
sb_run "git reset --soft HEAD~1 && git status --short"
sb_run "git log --oneline -2"

sb_say "The same start, with --mixed"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git add packing.md && git reset HEAD~1"
sb_run "git status --short"

sb_say "The same start, with --hard"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git add packing.md && git reset --hard HEAD~1"
sb_run "git status --short && cat route.md"

# ---------------------------------------------------------------------------
sb_say "Undoing the last commit and keeping it staged"
fresh
sb_run "git reset --soft HEAD~1 && git status --short && git log --oneline -1"

sb_say "Squashing the last three commits"
fresh
sb_run "git reset --soft HEAD~3 && git status --short"
sb_run "git commit -q -m 'Plan the trip' && git log --oneline"; sb_tick

sb_say "What --soft leaves alone"
fresh
sb_write budget.md "trains 60" "food 120" "museums 30"
sb_run "git reset --soft HEAD~2 && git status --short"

# ---------------------------------------------------------------------------
sb_say "The default, and what it prints"
fresh
sb_run "git reset --mixed HEAD~2 && git log --oneline -1"
sb_run "git reset --mixed main && git log --oneline -1"
sb_write budget.md "trains 60" "food 120" "museums 30"
sb_run "git add budget.md && git reset"
sb_run "git status --short"

sb_say "Moving the branch as well"
fresh
sb_run "git reset HEAD~2 && git status --short"

sb_say "A file the target commit does not have"
fresh
sb_run "git reset -N HEAD~2 && git status --short"
sb_run "git diff --stat"

sb_say "Without refreshing the index"
fresh
sb_write budget.md "trains 60" "food 120" "museums 30"
sb_run "git add budget.md && git reset --no-refresh"
sb_run "git status --short"

# ---------------------------------------------------------------------------
sb_say "--hard and what it destroys"
fresh
sb_write route.md "Day 1 Porto"
sb_write packing.md "boots" "map" "torch"
sb_run "git add packing.md && git status --short"
sb_run "git reset --hard"
sb_run "git status --short && cat route.md"

sb_say "Untracked and ignored files"
fresh
sb_write scratch.txt "untracked"
sb_write .gitignore "*.log"
sb_write debug.log "ignored"
sb_run "git add .gitignore && git commit -q -m 'Ignore log files' && git status --short"; sb_tick
sb_run "git reset --hard HEAD~1"
sb_run "git status --short && ls"

# ---------------------------------------------------------------------------
sb_say "--merge"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git merge detour"
sb_run "git status --short"
sb_run "git reset --merge"
sb_run "git status --short && git log --oneline -1"

sb_say "--keep"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git reset --keep HEAD~1"
sb_run "git status --short && git log --oneline -1"

sb_say "--keep refusing"
fresh
sb_write route.md "Day 1 Lisbon" "Day 2 Sintra" "Day 3 Evora" "Day 4 Faro"
sb_run "git reset --keep HEAD~1"
sb_run "git status --short && git log --oneline -1"

sb_say "--hard in the same situation"
sb_run "git reset --hard HEAD~1"
sb_run "git status --short && git log --oneline -1"

sb_say "--merge refusing"
fresh
sb_write budget.md "trains 60" "food 120" "museums 30"
sb_run "git add budget.md"
sb_write budget.md "trains 60" "food 120" "museums 30" "ferry 12"
sb_run "git status --short"
sb_run "git reset --merge HEAD~1"
sb_run "git reset --soft HEAD~1 && git status --short"

# ---------------------------------------------------------------------------
sb_say "Resetting files instead of commits"
fresh
sb_write packing.md "boots" "map" "torch"
sb_write budget.md "trains 60" "food 120" "museums 30"
sb_run "git add -A && git status --short"
sb_run "git reset -- packing.md"
sb_run "git status --short"
sb_run "git reset"
sb_run "git status --short"

sb_say "reset and restore --staged"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git add packing.md && git restore --staged packing.md && git status --short"

sb_say "The staged version from another commit"
fresh
sb_run "git reset HEAD~1 -- route.md"
sb_run "git status --short && git diff --cached"
sb_run "git log --oneline -1"

sb_say "reset with a path and a mode"
sb_run "git reset --hard -- route.md"
sb_run "git reset --soft -- route.md"

sb_say "Unstaging part of a file"
fresh
sb_write itinerary.md "Day 1 Lisbon" "Day 2 Sintra" "Day 3 Evora" "Day 4 rest" \
	"Day 5 rest" "Day 6 rest" "Day 7 rest" "Day 8 rest" "Day 9 rest" \
	"Day 10 rest" "Day 11 rest" "Day 12 Porto"
sb_run "git add itinerary.md && git commit -q -m 'Add the itinerary'"; sb_tick
sb_write itinerary.md "Day 1 Faro" "Day 2 Sintra" "Day 3 Evora" "Day 4 rest" \
	"Day 5 rest" "Day 6 rest" "Day 7 rest" "Day 8 rest" "Day 9 rest" \
	"Day 10 rest" "Day 11 rest" "Day 12 Braga"
sb_run "git add itinerary.md && git diff --cached --stat"
sb_run "printf 'n\\ny\\n' | git reset -p; echo"
sb_run "git status --short && git diff --cached"

# ---------------------------------------------------------------------------
sb_say "ORIG_HEAD"
fresh
sb_run "git reset --hard HEAD~2 && git log --oneline -1"
sb_run "git log --oneline -1 ORIG_HEAD"
sb_run "git reset --hard ORIG_HEAD && git log --oneline -1"

# ---------------------------------------------------------------------------
sb_say "Resetting somewhere other than backwards"
fresh
sb_run "git reset --hard HEAD~3 && git log --oneline"
sb_run "git reset --hard main && git log --oneline -1"
sb_run "git reset --hard detour && git log --oneline -2"
sb_run "git status --short"

sb_say "Moving a branch you are not on"
sb_run "git switch -q main && git log --oneline -1 try"
sb_run "git branch -f try main~1 && git log --oneline -1 try"
sb_run "git log --oneline -1"

# ---------------------------------------------------------------------------
sb_say "What reset never touches"
fresh
sb_write packing.md "boots" "map" "torch"
sb_run "git stash push -q -m 'packing ideas' && git stash list"
sb_run "git reset --hard HEAD~2 && git stash list"
sb_run "git log --oneline --decorate -1 main && git log --oneline --decorate -1 detour"
sb_run "git stash drop -q"

# ---------------------------------------------------------------------------
sb_say "When reset refuses"
fresh
sb_run "git reset --soft HEAD~1 -- route.md"
sb_run "git reset --hard nosuchcommit"
sb_run "git reset -- nosuchfile.md"
sb_run "git switch -q --orphan nothing-yet && git reset --hard HEAD~1"
sb_run "git reset && git status --short"
git switch -q main

sb_say "In the middle of a merge"
fresh
sb_run "git merge detour"
sb_run "git status --short"
sb_run "git reset --soft HEAD~1"
sb_run "git reset --merge && git status --short && git log --oneline -1"

sb_say "In a bare repository"
git clone -q --bare "$SANDBOX_ROOT/trip" "$SANDBOX_ROOT/trip.git"
sb_run "git -C $SANDBOX_ROOT/trip.git reset --hard HEAD"
sb_run "git -C $SANDBOX_ROOT/trip.git reset --soft HEAD~1 && git -C $SANDBOX_ROOT/trip.git log --oneline -1"

# ---------------------------------------------------------------------------
sb_say "Undoing a reset"
fresh
sb_run "git reset --hard HEAD~2 && git log --oneline -1"
sb_run "git reflog show try -3"
sb_run "git reset --hard try@{1} && git log --oneline -1"

# ---------------------------------------------------------------------------
# A separate, small repository, so that the only dangling object in it is the
# one the example is looking for.
sb_say "Work that was staged and never committed"
keep_now=$SANDBOX_NOW
sb_fresh "$SANDBOX_ROOT/rescue" >/dev/null
sb_write list.md "one" "two"
sb_commit "Start a list"
sb_write list.md "one" "two" "three"
sb_run "git add list.md && git rev-parse :list.md"
lost=$(git rev-parse :list.md)
sb_run "git reset --hard HEAD"
sb_run "git status --short && cat list.md"
sb_run "git fsck --lost-found"
sb_run "git cat-file -p $lost"
sb_run "git cat-file -p $lost > list.md && cat list.md"
SANDBOX_NOW=$keep_now
sb_settime
cd "$SANDBOX_ROOT/trip"
