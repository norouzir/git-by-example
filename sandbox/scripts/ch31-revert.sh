#!/bin/bash
# Generates every transcript in Chapter 31, "revert".
#
#   bash sandbox/scripts/ch31-revert.sh [dir]
#
# No `set -e`: many commands are shown refusing or conflicting on purpose.
#
# Git opens an editor only when it is talking to a terminal, which the sandbox
# never is, so every command that would open one says --no-edit or sets
# GIT_EDITOR in the printed command.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

fresh() {
	git checkout -qf --detach main
	git clean -qfdx
	sb_run "${1:-git switch -q -C try main}"
}

# ---------------------------------------------------------------------------
# A shop's price list.
sb_fresh "$SANDBOX_ROOT/shop" >/dev/null
sb_write README.md "# Price list"
sb_commit "Start the price list"
sb_write drinks.md "tea 2" "coffee 3"
sb_commit "Add the drinks"
sb_write snacks.md "crisps 1" "cake 4"
sb_commit "Add the snacks"

git switch -q -c loyalty
sb_write loyalty.md "10 stamps, one free drink"
sb_commit "Start a loyalty card"
sb_write loyalty.md "10 stamps, one free drink" "Stamps last a year."
sb_commit "Say when stamps expire"
git switch -q main

sb_write drinks.md "tea 3" "coffee 4"
sb_write snacks.md "crisps 2" "cake 5"
sb_commit "Raise every price"
sb_write hours.md "Open 08:00 to 18:00."
sb_commit "Add the opening hours"
git merge -q --no-edit loyalty; sb_tick

sb_say "The example repository"
sb_run "git log --oneline --graph --decorate -7"
sb_run "git show --stat --oneline main~2"

# ---------------------------------------------------------------------------
sb_say "Reverting one commit"
fresh
sb_run "git revert --no-edit main~2"; sb_tick
sb_run "git log --oneline -2"
sb_run "git show --stat HEAD"
sb_run "cat drinks.md"

sb_say "The message revert writes"
fresh
sb_run "GIT_EDITOR=cat git revert -e main~2"; sb_tick
sb_run "git log -1 --format=%B"

sb_say "Writing the reason in"
fresh
sb_run "GIT_EDITOR=\"sed -i '1s/.*/Put the old prices back, the rise was a mistake/'\" git revert -e main~2"; sb_tick
sb_run "git log -1 --format=%B"

sb_say "A shorter reference"
fresh
sb_run "GIT_EDITOR=\"sed -i '1s/.*/Put the old prices back/'\" git revert -e --reference main~2"; sb_tick
sb_run "git log -1 --format=%B"
sb_run "git -c revert.reference=true revert --no-edit main~3 && git log -1 --format=%B"; sb_tick

# ---------------------------------------------------------------------------
sb_say "Reverting several commits"
fresh
sb_run "git revert --no-edit main~2 main~3"; sb_tick; sb_tick
sb_run "git log --oneline -3"
sb_run "ls"

sb_say "A range"
fresh
sb_run "git revert --no-edit main~3..main~1"; sb_tick; sb_tick
sb_run "git log --oneline -3"

sb_say "Reverting without committing"
fresh
sb_run "git revert -n main~2 main~3"
sb_run "git status --short"
sb_run "git commit -q -m 'Undo the price rise and the snacks' && git log --oneline -2"; sb_tick

# ---------------------------------------------------------------------------
sb_say "Reverting a merge"
fresh
sb_run "git revert --no-edit HEAD"
sb_run "git log --oneline --graph -3 HEAD"
sb_run "git revert --no-edit -m 1 HEAD"; sb_tick
sb_run "git log --oneline -2 && ls"
sb_run "git show --stat --oneline HEAD"

sb_say "The other parent"
fresh
sb_run "git revert --no-edit -m 2 HEAD"; sb_tick
sb_run "git show --stat --oneline HEAD"

sb_say "Merging again after a reverted merge"
fresh
sb_run "git revert --no-edit -m 1 HEAD"; sb_tick
sb_run "git merge --no-edit loyalty"
sb_run "ls"
sb_run "git revert --no-edit HEAD"; sb_tick
sb_run "git log --oneline -3 && ls"

# ---------------------------------------------------------------------------
sb_say "When a revert conflicts"
fresh
sb_write drinks.md "tea 3" "coffee 4" "cocoa 5"
sb_run "git commit -q -am 'Add cocoa' && git log --oneline -1"; sb_tick
sb_run "git revert --no-edit main~2"
sb_run "git status --short --branch"
sb_run "git status | head -12"
sb_run "cat drinks.md"
sb_run "git log --oneline -1 REVERT_HEAD"

sb_say "Finishing the revert"
sb_write drinks.md "tea 2" "coffee 3" "cocoa 5"
sb_run "git add drinks.md && git revert --continue --no-edit"; sb_tick
sb_run "git log --oneline -2 && cat drinks.md"

sb_say "Abandoning a revert"
fresh
sb_write drinks.md "tea 3" "coffee 4" "cocoa 5"
sb_run "git commit -q -am 'Add cocoa'"; sb_tick
sb_run "git revert --no-edit main~2"
sb_run "git revert --abort && git status --short && cat drinks.md"

sb_say "Quitting instead"
sb_run "git revert --no-edit main~2"
sb_run "git revert --quit && git status --short"
sb_run "git log --oneline -1"
sb_run "git reset -q --hard HEAD && git status --short"

sb_say "Skipping one commit of several"
fresh
sb_write drinks.md "tea 3" "coffee 4" "cocoa 5"
sb_run "git commit -q -am 'Add cocoa'"; sb_tick
sb_run "git revert --no-edit main~2 main~1"
sb_run "git revert --skip"; sb_tick
sb_run "git log --oneline -3 && ls"

sb_say "Taking a side automatically"
fresh
sb_write drinks.md "tea 3" "coffee 4" "cocoa 5"
sb_run "git commit -q -am 'Add cocoa'"; sb_tick
sb_run "git revert --no-edit -Xours main~2"; sb_tick
sb_run "git log --oneline -2 && cat drinks.md"

sb_say "Another strategy"
fresh
sb_run "git revert --no-edit --strategy=ort main~2 && git log --oneline -1"; sb_tick

# ---------------------------------------------------------------------------
sb_say "Signing off"
fresh
sb_run "git revert --no-edit -s main~2 && git log -1 --format=%B"; sb_tick

# ---------------------------------------------------------------------------
sb_say "When revert refuses"
fresh
sb_write drinks.md "tea 3" "coffee 4" "cocoa 5"
sb_run "git revert --no-edit main~2"
sb_run "git status --short"
sb_run "git stash push -q && git status --short"
sb_run "git revert --no-edit main~2 && git log --oneline -1"; sb_tick

sb_say "During a merge"
fresh
sb_write drinks.md "tea 3" "coffee 4" "cocoa 5"
sb_run "git commit -q -am 'Add cocoa'"; sb_tick
git switch -q -c rival main
sb_write drinks.md "tea 3" "coffee 4" "hot chocolate 5"
sb_run "git commit -q -am 'Add hot chocolate'"; sb_tick
sb_run "git switch -q try && git merge rival"
sb_run "git revert --no-edit main~2"
sb_run "git merge --abort"

sb_say "A commit that is not in this branch"
fresh
sb_run "git switch -q -c other main~3 && git revert --no-edit main~2"
sb_run "git status --short --branch && git log --oneline -1"
sb_run "git revert --quit && git log --oneline -2 && ls"

sb_say "With no commits at all"
sb_run "git switch -q --orphan nothing-yet && git revert --no-edit HEAD"
git switch -q main
