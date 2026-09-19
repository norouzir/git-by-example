#!/bin/bash
# Generates every transcript in Chapter 36, "reflog".
#
#   bash sandbox/scripts/ch36-reflog.sh [dir]
#
# No `set -e`: several commands are shown refusing on purpose.
#
# sb_pin_now fixes "now" to the sandbox clock, because the chapter shows
# @{time} syntax and expiry, both of which are computed against the current
# time and would otherwise change as real days pass.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_pin_now
sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# ---------------------------------------------------------------------------
# A recipe collection, with enough history to have an interesting reflog.
sb_fresh "$SANDBOX_ROOT/recipes" >/dev/null
sb_write README.md "# Recipes"
sb_commit "Start the collection"
sb_write bread.md "Flour, water, salt, yeast."
sb_commit "Add bread"
sb_write soup.md "Onions, stock."
sb_commit "Add soup"

git switch -q -c cake
sb_write cake.md "Flour, eggs, sugar."
sb_commit "Add cake"
sb_write cake.md "Flour, eggs, sugar, butter."
sb_commit "Add butter to the cake"

git switch -q main
sb_write soup.md "Onions, stock, thyme."
sb_commit "Season the soup"
git merge -q --no-edit cake; sb_tick
sb_write bread.md "Flour, water, salt, yeast." "Rest for an hour."
git commit -q -am "Add bread"; sb_tick
git commit -q --amend -m "Add bread, with a rest"; sb_tick

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Reading the reflog"
sb_run "git reflog"
sb_run "git reflog -3"

sb_say "The reflog of a branch"
sb_run "git reflog show main -4"
sb_run "git reflog show cake"

sb_say "Which refs have one"
sb_run "git reflog list"
sb_run "git reflog exists refs/heads/cake && echo yes"
sb_run "git reflog exists refs/heads/nosuch || echo no"

# ---------------------------------------------------------------------------
sb_say "Naming an entry"
sb_run "git log --oneline -1 HEAD@{2}"
sb_run "git log --oneline -1 main@{1}"
sb_run "git rev-parse --short 'main@{1 hour ago}'"
sb_run "git log --oneline -1 'main@{2 hours ago}'"
sb_run "git log --oneline -1 'main@{2 weeks ago}'"
sb_run "git log --oneline -1 main@{9}"

sb_say "HEAD@{2} is not HEAD~2"
sb_run "git log --oneline -1 HEAD@{2} && git log --oneline -1 HEAD~2"

# ---------------------------------------------------------------------------
sb_say "Seeing more with git log"
sb_run "git log -g -3"
sb_run "git log -g --oneline -3"
sb_run "git log -g --format='%gd | %gs | %h %s' -4"
sb_run "git log -g --format='%gD' -2"
sb_run "git log -g --grep-reflog=amend --format='%gd %gs'"
sb_run "git log --oneline --reflog | head -5"

# ---------------------------------------------------------------------------
sb_say "What writes an entry"
sb_run "git switch -q cake && git switch -q main && git reflog -3"
sb_run "git reset -q --hard HEAD~1 && git reflog -2"
sb_run "git reset -q --hard HEAD@{1} && git reflog -2"
sb_run "git status --short && git reflog -1"

# ---------------------------------------------------------------------------
sb_say "Finding a commit you thought you lost"
sb_run "git switch -q -c scratch main && git commit -q --allow-empty -m 'A note to self' && git log --oneline -1"; sb_tick
lost=$(git rev-parse --short HEAD)
sb_run "git switch -q main && git branch -D scratch"
sb_run "git log --oneline --all | grep 'A note to self' || echo 'not in any branch'"
sb_run "git reflog -3"
sb_run "git log --oneline -1 $lost"
sb_run "git branch -q rescued $lost && git log --oneline --decorate -1 rescued"

sb_say "Searching the reflog"
sb_run "git log -g --grep='note to self' --format='%gd %gs'"
sb_run "git reflog show main --since='3 hours ago' | head -3"

# ---------------------------------------------------------------------------
sb_say "Writing an entry by hand"
sb_run "git reflog write refs/heads/rescued $(git rev-parse rescued) $(git rev-parse main) 'moved by hand'"
sb_run "git reflog show rescued"
sb_run "git log --oneline --decorate -1 rescued"

sb_say "Deleting entries"
sb_run "git reflog delete --dry-run --verbose rescued@{0}"
sb_run "git reflog delete rescued@{0} && git reflog show rescued"
sb_run "git reflog drop rescued"
sb_run "git reflog exists refs/heads/rescued || echo 'no reflog now'"
sb_run "git log --oneline --decorate -1 rescued"

sb_say "Moving the ref with the entry"
sb_run "git switch -q -c demo main"
sb_write demo.md "A demonstration."
sb_run "git add demo.md && git commit -q -m 'Add a demo note' && git commit -q --allow-empty -m 'And another'"; sb_tick; sb_tick
sb_run "git reflog show demo && git log --oneline -1 demo"
sb_run "git reflog delete --updateref --rewrite demo@{0}"
sb_run "git reflog show demo && git log --oneline -1 demo"
git switch -q main
git branch -qD demo

# ---------------------------------------------------------------------------
sb_say "When entries expire"
sb_run "git reflog show main | wc -l"
sb_run "git reflog expire --dry-run --verbose --expire=90.days.ago main"
sb_run "git reflog expire --dry-run --verbose --expire=90.days.ago --expire-unreachable=90.days.ago main"
sb_run "git reflog show --date=relative main"
sb_run "git reflog expire --dry-run --verbose --expire=3.hours.ago main"
sb_run "git reflog expire --expire=3.hours.ago main && git reflog show main"
sb_run "git reflog show cake | wc -l"
sb_run "git reflog expire --expire=all cake && git reflog show cake"
sb_run "git log --oneline --decorate -1 cake"

# ---------------------------------------------------------------------------
sb_say "Where reflogs are kept"
sb_run "ls .git/logs .git/logs/refs/heads"
sb_run "cat .git/logs/refs/heads/main"
sb_run "git config core.logAllRefUpdates"

sb_say "A repository with no reflog"
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_run "git -C $SANDBOX_ROOT/server.git config core.logAllRefUpdates"
sb_run "git push -q $SANDBOX_ROOT/server.git main && git -C $SANDBOX_ROOT/server.git reflog show main"
sb_run "ls $SANDBOX_ROOT/server.git"

sb_say "A fresh clone"
git clone -q "$SANDBOX_ROOT/recipes" "$SANDBOX_ROOT/clone"
sb_run "git -C $SANDBOX_ROOT/clone reflog show main"
sb_run "git -C $SANDBOX_ROOT/clone log --oneline -3"

# ---------------------------------------------------------------------------
sb_say "reflog and its neighbours"
sb_run "git log --oneline -1 ORIG_HEAD"
sb_run "git fsck --lost-found | head -4"
