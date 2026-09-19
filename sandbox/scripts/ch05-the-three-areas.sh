#!/bin/bash
# Generates every transcript in Chapter 5, "The Three Areas".
#
#   bash sandbox/scripts/ch05-the-three-areas.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/areas" >/dev/null

sb_say "--- 1. a new file is in the working tree only ---"
sb_write recipe.txt "flour" "water"
sb_run git status
sb_run git status --short

sb_say "--- 2. git add copies it into the index ---"
sb_run git add recipe.txt
sb_run git status --short
sb_run git ls-files --stage

sb_say "--- 3. git commit copies the index into the repository ---"
sb_commit "Add the recipe"
sb_run git status --short
sb_run git status
sb_run git cat-file -p 'HEAD^{tree}'

sb_say "--- 4. edit the file: working tree and index now disagree ---"
sb_write recipe.txt "flour" "water" "salt"
sb_run git status --short
sb_run git diff
sb_run git diff --staged

sb_say "--- 5. stage it: index and HEAD now disagree instead ---"
sb_run git add recipe.txt
sb_run git status --short
sb_run git diff
sb_run git diff --staged

sb_say "--- 6. edit again without staging: the file is in two states at once ---"
sb_write recipe.txt "flour" "water" "salt" "yeast"
sb_run git status --short
sb_run git status

sb_say "--- 7. the three diffs, on that same file ---"
sb_run git diff
sb_run git diff --staged
sb_run git diff HEAD

sb_say "--- 8. what gets committed is the index, not the working tree ---"
sb_run git commit -m "'Add salt'"
sb_tick
sb_run git show --stat --oneline HEAD
sb_run "git cat-file -p HEAD:recipe.txt"
sb_run cat recipe.txt
sb_run git status --short
sb_run git diff --staged
sb_run git diff HEAD

sb_say "--- 9. the index is a real file listing hashes, not contents ---"
sb_run git ls-files --stage
sb_run git rev-parse ':recipe.txt' 'HEAD:recipe.txt'

sb_say "--- 10. commit -a stages tracked files, and only tracked files ---"
sb_write recipe.txt "flour" "water" "salt" "yeast" "sugar"
sb_write notes.txt "untracked"
sb_run git status --short
sb_run "git commit -a -m 'Add yeast and sugar'"
sb_run git status --short
sb_run git show --stat --oneline HEAD

sb_say "--- 11. moving things backwards between the areas ---"
sb_write recipe.txt "flour" "water" "salt" "yeast" "sugar" "butter"
sb_run git add recipe.txt
sb_run git status --short
sb_run git restore --staged recipe.txt
sb_run git status --short
sb_run git restore recipe.txt
sb_run git status --short
sb_run cat recipe.txt
