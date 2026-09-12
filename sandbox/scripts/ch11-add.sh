#!/bin/bash
# Generates every transcript in Chapter 11, "add".
#
#   bash sandbox/scripts/ch11-add.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/adding" >/dev/null

sb_say "--- 1. the plain form ---"
sb_write a.txt "alpha"
sb_write b.txt "bravo"
sb_run git add a.txt
sb_run git status --short
sb_run git add a.txt b.txt
sb_run git status --short
sb_commit "Add a and b"

sb_say "--- 2. what it actually did ---"
sb_write a.txt "alpha" "second line"
sb_run "git hash-object a.txt"
sb_run git add a.txt
sb_run git ls-files --stage a.txt
sb_run "git cat-file -p :a.txt"

sb_say "--- 3. a dry run ---"
sb_write c.txt "charlie"
sb_run git add -n .
sb_run git status --short
sb_run git add --dry-run c.txt

sb_say "--- 4. the four ways to say everything ---"
sb_write src/one.txt "one"
sb_write src/two.txt "two"
rm b.txt
sb_run git status --short
sb_run "git add -u && git status --short"
sb_run git reset -q
sb_run "git add -A && git status --short"
sb_run git reset -q
sb_run "git add . && git status --short"
sb_run git reset -q

sb_say "--- 5. the difference only shows from a subdirectory ---"
cd src
sb_run "git add . && git status --short"
sb_run git reset -q
sb_run "git add -A && git status --short"
sb_run git reset -q
cd ..
sb_run "git add -A && git status --short"
sb_commit "Add src and remove b"

sb_say "--- 6. pathspecs: globs and directories ---"
sb_write docs/guide.md "guide"
sb_write docs/api.md "api"
sb_write docs/logo.png "not really a png"
sb_run "git add 'docs/*.md' && git status --short"
sb_run git reset -q
sb_run "git add docs && git status --short"
sb_run git reset -q
sb_run "git add ':(glob)**/*.md' && git status --short"
sb_run git reset -q
sb_run "git add ':!docs/logo.png' && git status --short"
sb_run git reset -q

sb_say "--- 7. adding part of a file ---"
sb_write poem.txt "one" "two" "three" "four" "five" "six" "seven" "eight" "nine" "ten"
sb_commit "Add poem"
sb_write poem.txt "ONE" "two" "three" "four" "five" "six" "seven" "eight" "nine" "TEN"
sb_run git diff
sb_run "printf 'y\nn\n' | git add -p poem.txt"
sb_run git status --short
sb_run git diff --staged
sb_run git diff

sb_say "--- 8. ignored files need forcing ---"
sb_write .gitignore "*.log"
sb_commit "Ignore logs"
sb_write debug.log "noise"
sb_run git add debug.log || true
sb_run "git add -f debug.log && git status --short"
sb_run git reset -q

sb_say "--- 9. recording that a file is coming ---"
sb_write draft.txt "unfinished"
sb_run git status --short
sb_run git add -N draft.txt
sb_run git status --short
sb_run git diff
sb_run git ls-files --stage draft.txt

sb_say "--- 10. setting the executable bit without touching the file ---"
sb_write script.sh "#!/bin/sh" "echo hi"
sb_run "git add --chmod=+x script.sh && git ls-files --stage script.sh"
sb_run git reset -q

sb_say "--- 11. errors it produces ---"
sb_run git add nothing-here || true
sb_run "git add ''" || true
cd "$SANDBOX_ROOT"
sb_run "git -C adding add ../outside" || true
