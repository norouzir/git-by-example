#!/bin/bash
# Generates every transcript in Chapter 27, "Merge Strategies and Options".
#
#   bash sandbox/scripts/ch27-merge-strategies-and-options.sh [dir]
#
# No `set -e`: strategies and options fail on purpose here.
#
# As in ch25 and ch26, every merge that commits says --no-edit, because Git
# opens an editor only on a terminal.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

m() { sb_run "$1"; sb_tick; }

# ---------------------------------------------------------------------------
# A second project, vendored into the first one later.
sb_fresh "$SANDBOX_ROOT/lib" >/dev/null
sb_write lib.txt "parse 1" "print 1"
sb_commit "Write the library"

# ---------------------------------------------------------------------------
# The shop.
LIB_NOW="$SANDBOX_NOW"
sb_fresh "$SANDBOX_ROOT/shop" >/dev/null
sb_write prices.txt "Tea 2" "Coffee 3" "Cake 4" "Bun 1"
sb_write notes.txt "Order flour on Fridays" "Call the baker" "Check the oven" "Count the cups" "Water the plant"
sb_write steps.txt "Step:" "done" "check" "wait 1" "start" "Step:" "done" "Step:"
sb_write recipe.txt "mix  flour" "bake  it" "serve it"
sb_write eol.txt "mix flour" "bake it" "serve it"
sb_write cross.txt "one" "two" "three" "four" "five" "six" "seven"
sb_write size.txt "size 1"
sb_commit "Open the shop"

git switch -q -c sale
sb_write prices.txt "Tea 4" "Coffee 3" "Cake 4" "Bun 2"
sb_write flyer.txt "Half price Tuesday"
sb_commit "Cut prices for the sale"

git switch -q main
sb_write prices.txt "Tea 3" "Coffee 3" "Cake 4" "Bun 1"
sb_commit "Raise the tea price"

# Renames.
git switch -q -c renamed main
git mv notes.txt kitchen-notes.txt
sb_commit "Rename the notes"
git switch -q -c edited main
sb_write notes.txt "Order flour on Fridays" "Call the baker" "Check the oven twice" "Count the cups" "Water the plant"
sb_commit "Change a note"
git switch -q -c rewritten main
git mv notes.txt jobs.txt
sb_write jobs.txt "Sweep the floor" "Wipe the tables" "Check the oven" "Count the cups" "Lock the door"
sb_commit "Rewrite the notes as jobs"

# A directory renamed on one side, a file added to it on the other.
git switch -q -c work main
sb_write src/app.txt "the app"
sb_write src/util.txt "the util"
sb_commit "Add a src directory"
git switch -q -c dir-moved work
git mv src lib
sb_commit "Move src to lib"
git switch -q -c dir-added work
sb_write src/extra.txt "the extra"
sb_commit "Add a file to src"

# Whitespace.
git switch -q -c space-ours main
sb_write recipe.txt "mix   flour" "bake it" "serve it"
sb_commit "Re-space the recipe"
git switch -q -c space-theirs main
sb_write recipe.txt "mix  water" "bake  it now" "serve it"
sb_commit "Change the recipe"
git switch -q -c eol-ours main
printf 'mix flour   \nbake it\nserve it\n' > eol.txt
sb_commit "Pad the first line"
git switch -q -c cr-ours main
printf 'mix flour\r\nbake it\nserve it\n' > eol.txt
sb_commit "Write the first line with CRLF"
git switch -q -c eol-theirs main
sb_write eol.txt "mix batter" "bake it" "serve it"
sb_commit "Change the first line"

# A file of repeated lines, for the diff algorithms.
git switch -q -c steps-ours main
sb_write steps.txt "Step:" "check" "wait 1" "start" "Step:" "Stop:" "Stop:" "Step:"
sb_commit "Reorganize the steps"
git switch -q -c steps-theirs main
sb_write steps.txt "check" "Step:" "check" "Step:" "wait 1" "start" "Step:" "done" "Step:"
sb_commit "Add checks to the steps"

# Criss-cross history: two merge bases.
git switch -q -c cross-a main
sb_write cross.txt "ONE" "two" "three" "four" "five" "six" "seven"
sb_commit "Shout one"
git switch -q -c cross-b main
sb_write cross.txt "one" "two" "three" "four" "FIVE" "six" "seven"
sb_commit "Shout two"
git switch -q -c cross1 cross-a
git merge -q --no-edit cross-b >/dev/null
sb_tick
sb_write cross.txt "ONE" "two" "three" "four" "FIVE" "six" "seventh"
sb_commit "Number seven, take one"
git switch -q -c cross2 cross-b
git merge -q --no-edit cross-a >/dev/null
sb_tick
sb_write cross.txt "ONE" "two" "three" "four" "FIVE" "six" "7"
sb_commit "Number seven, take two"

# A change made and then undone on one side.
git switch -q -c flip main
sb_write size.txt "size 2"
sb_commit "Make it bigger"
sb_write size.txt "size 1"
sb_commit "Put the size back"
git switch -q -c bump main
sb_write size.txt "size 2"
sb_commit "Make it bigger too"

# A log file both sides append to.
git switch -q -c list main
sb_write log.txt "opened Monday"
sb_commit "Start a log"
git switch -q -c list-a list
sb_write log.txt "opened Monday" "cleaned Tuesday"
sb_commit "Log Tuesday"
git switch -q -c list-b list
sb_write log.txt "opened Monday" "painted Wednesday"
sb_commit "Log Wednesday"

git switch -q main

# =============================================================================
sb_say "--- C1. the example repository ---"
sb_run "git log --oneline --graph --decorate main sale renamed"
sb_run "git branch"

sb_say "--- C2. which strategy runs ---"
sb_run "git switch -q -C try main"
sb_run "git merge --no-edit sale"
sb_run "git merge --abort"
sb_run "git merge --no-edit -s ort sale"
sb_run "git merge --abort"
sb_run "git merge --no-edit -s recursive sale"
sb_run "git merge --abort"
sb_run "git merge -s theirs sale"
sb_run "git merge -X nosuch sale"
sb_run "git merge --no-edit sale cross-a"
sb_run "git merge --no-edit -s ort sale cross-a"
sb_run "git switch -q -C try main"
sb_run "git merge --no-edit -s octopus sale"
sb_run "git merge --no-edit -s resolve -s ort sale"
sb_run "git merge --abort"

sb_say "--- C3. resolve ---"
sb_run "git switch -q -C try main"
sb_run "git merge --no-edit -s resolve sale"
sb_run "git status --short"
sb_run "sed -n '2p;4p' prices.txt"
sb_run "git merge --abort"
sb_run "git switch -q -C try renamed"
sb_run "git merge --no-edit edited"
sb_run "cat kitchen-notes.txt"
sb_run "git switch -q -C try work"
m "git merge --no-edit -s resolve edited"
sb_run "cat notes.txt"
sb_run "git switch -q -C try renamed"
sb_run "git merge --no-edit -s resolve edited"
sb_run "git status --short"
sb_run "git merge --abort"

sb_say "--- C4. ours strategy ---"
sb_run "git switch -q -C try main"
m "git merge --no-edit -s ours sale"
sb_run "git show --stat --format=%s"
sb_run "cat prices.txt"
sb_run "ls"
sb_run "git log --oneline --graph -3"
sb_run "git merge --no-edit sale"
sb_run "git branch --merged"

sb_say "--- C5. subtree ---"
sb_run "git switch -q -C vendored main"
sb_run "git remote add lib ../lib"
sb_run "git fetch -q lib"
sb_run "git merge -s ours --no-commit --allow-unrelated-histories lib/main"
sb_run "git read-tree --prefix=vendor/lib -u lib/main"
m "git commit -q -m 'Vendor the library'"
sb_run "git ls-files vendor"
LIB_BACK="$SANDBOX_NOW"
cd "$SANDBOX_ROOT/lib"
sb_write lib.txt "parse 2" "print 1"
sb_commit "Improve the parser"
cd "$SANDBOX_ROOT/shop"
SANDBOX_NOW="$LIB_BACK"; sb_settime
sb_run "git fetch -q lib"
sb_run "git switch -q -C try vendored"
m "git merge --no-edit lib/main"
sb_run "cat vendor/lib/lib.txt"
sb_run "git switch -q -C try vendored"
m "git merge --no-edit -s subtree lib/main"
sb_run "cat vendor/lib/lib.txt"
sb_run "git switch -q -C try vendored"
m "git merge --no-edit -X subtree=vendor/lib lib/main"
sb_run "cat vendor/lib/lib.txt"
sb_run "git switch -q -C try vendored"
sb_run "git merge --no-edit -X no-renames lib/main"
sb_run "git status --short"
sb_run "git merge --abort"

sb_say "--- C6. -X ours and -X theirs ---"
sb_run "git switch -q -C try main"
m "git merge --no-edit -X ours sale"
sb_run "cat prices.txt"
sb_run "ls flyer.txt"
sb_run "git switch -q -C try main"
m "git merge --no-edit -X theirs sale"
sb_run "cat prices.txt"

sb_say "--- C7. whitespace ---"
sb_run "git switch -q -C try space-ours"
sb_run "git merge --no-edit space-theirs"
sb_run "cat recipe.txt"
sb_run "git merge --abort"
m "git merge --no-edit -X ignore-space-change space-theirs"
sb_run "cat recipe.txt"
sb_run "git switch -q -C try space-ours"
m "git merge --no-edit -X ignore-all-space space-theirs"
sb_run "cat recipe.txt"
sb_run "git switch -q -C try eol-ours"
sb_run "git merge --no-edit eol-theirs"
sb_run "git merge --abort"
m "git merge --no-edit -X ignore-space-at-eol eol-theirs"
sb_run "cat eol.txt"
sb_run "git switch -q -C try cr-ours"
sb_run "git merge --no-edit eol-theirs"
sb_run "git merge --abort"
m "git merge --no-edit -X ignore-cr-at-eol eol-theirs"
sb_run "cat -A eol.txt"

sb_say "--- C8. renames ---"
sb_run "git switch -q -C try renamed"
sb_run "git merge --no-edit -X no-renames edited"
sb_run "git status --short"
sb_run "git merge --abort"
sb_run "git -c merge.renames=false merge --no-edit edited"
sb_run "git merge --abort"
m "git -c merge.renames=false merge --no-edit -X find-renames edited"
sb_run "git switch -q -C try rewritten"
sb_run "git merge --no-edit edited"
sb_run "git merge --abort"
sb_run "git merge --no-edit -X find-renames=30% edited"
sb_run "cat jobs.txt"
sb_run "git merge --abort"
sb_run "git merge --no-edit -X rename-threshold=30 edited"
sb_run "git status --short"
sb_run "git merge --abort"

sb_say "--- C9. directory renames ---"
sb_run "git switch -q -C try dir-moved"
sb_run "git merge --no-edit dir-added"
sb_run "git status --short"
sb_run "ls lib"
sb_run "git merge --abort"
m "git -c merge.directoryRenames=true merge --no-edit dir-added"
sb_run "ls lib"
sb_run "git switch -q -C try dir-moved"
m "git -c merge.directoryRenames=false merge --no-edit dir-added"
sb_run "ls lib src"

sb_say "--- C10. diff algorithms ---"
sb_run "git switch -q -C try steps-ours"
sb_run "git merge --no-edit steps-theirs"
sb_run "cat steps.txt"
sb_run "git merge --abort"
m "git merge --no-edit -X diff-algorithm=myers steps-theirs"
sb_run "cat steps.txt"
sb_run "git switch -q -C try steps-ours"
m "git merge --no-edit -X patience steps-theirs"
sb_run "git switch -q -C try steps-ours"
sb_run "git merge --no-edit -X histogram steps-theirs"
sb_run "git merge --abort"
sb_run "git switch -q -C try steps-ours"
m "git merge --no-edit -X diff-algorithm=minimal steps-theirs"

sb_say "--- C11. verbosity ---"
sb_run "git switch -q -C try main"
sb_run "git -c merge.verbosity=0 merge --no-edit sale"
sb_run "git status --short"
sb_run "git merge --abort"
sb_run "GIT_MERGE_VERBOSITY=0 git merge --no-edit sale"
sb_run "git merge --abort"

sb_say "--- C12. merge drivers ---"
sb_run "git switch -q -C try list-a"
sb_run "git merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git merge --abort"
sb_run "echo 'log.txt merge=union' > .gitattributes"
m "git merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git switch -q -C try list-a"
sb_run "rm .gitattributes"
m "git -c merge.default=union merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git switch -q -C try list-a"
sb_run "echo 'log.txt merge=binary' > .gitattributes"
sb_run "git merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git status --short"
sb_run "git merge --abort"
sb_run "echo 'log.txt -merge' > .gitattributes"
sb_run "git merge --no-edit list-b"
sb_run "git merge --abort"
sb_run "git config set merge.keep-ours.name 'always keep our version'"
sb_run "git config set merge.keep-ours.driver true"
sb_run "echo 'log.txt merge=keep-ours' > .gitattributes"
m "git merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git switch -q -C try list"
m "git merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git switch -q -C try list-a"
sb_run "git config set merge.show-args.driver 'echo \"driver ran: marker size %L, path %P, labels %S %X %Y\" >&2; cp %B %A'"
sb_run "echo 'log.txt merge=show-args' > .gitattributes"
m "git merge --no-edit list-b"
sb_run "cat log.txt"
sb_run "git switch -q -C try list-a"
sb_run "git config set merge.give-up.driver 'exit 1'"
sb_run "echo 'log.txt merge=give-up' > .gitattributes"
sb_run "git merge --no-edit list-b"
sb_run "git status --short"
sb_run "cat log.txt"
sb_run "git merge --abort"
sb_run "rm .gitattributes"

sb_say "--- C13. criss-cross ---"
sb_run "git switch -q -C try cross1"
sb_run "git log --oneline --graph cross1 cross2"
sb_run "git merge-base --all cross1 cross2"
sb_run "git -c merge.conflictStyle=diff3 merge --no-edit cross2"
sb_run "cat cross.txt"
sb_run "git merge --abort"
sb_run "git merge --no-edit -s resolve cross2"
sb_run "git status --short"
sb_run "git merge --abort"
sb_run "echo 'cross.txt merge=show-args' > .gitattributes"
m "git merge --no-edit cross2"
sb_run "git switch -q -C try cross1"
sb_run "git config set merge.show-args.recursive binary"
m "git merge --no-edit cross2"
sb_run "cat cross.txt"
sb_run "git switch -q -C try cross1"
sb_run "rm .gitattributes"

sb_say "--- C14. a change undone on one side ---"
sb_run "git switch -q -C try flip"
sb_run "git log --oneline -3"
m "git merge --no-edit bump"
sb_run "cat size.txt"

sb_say "--- C15. the same options elsewhere ---"
sb_run "git switch -q -C try main"
m "git cherry-pick -X theirs sale"
sb_run "cat prices.txt"
sb_run "git switch -q -C try main"
sb_run "git show \$(git merge-tree --write-tree -X theirs main sale):prices.txt"
sb_run "git merge-tree --write-tree --name-only main sale"
