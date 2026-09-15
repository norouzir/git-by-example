#!/bin/bash
# Generates every transcript in Chapter 24,
# "switch, checkout, and detached HEAD".
#
#   bash sandbox/scripts/ch24-switch-checkout-and-detached-head.sh [dir]
#
# No `set -e`: many commands are shown failing on purpose.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# ---------------------------------------------------------------------------
# A recipe collection. The server has branches `drinks` and `pies` that nobody
# has locally; a second remote, `backup`, also has `drinks`.
git init -q --bare "$SANDBOX_ROOT/server.git"
git init -q --bare "$SANDBOX_ROOT/backup.git"
sb_fresh "$SANDBOX_ROOT/recipes" >/dev/null
git remote add origin "$SANDBOX_ROOT/server.git"
sb_write README.md "# Recipes"
sb_write soup.txt "Tomato soup" "Serves 4"
sb_write .gitignore "*.log"
sb_commit "Start the collection"
sb_write bread.txt "Flour" "Water" "Salt"
sb_commit "Add bread"
git tag v1.0
git switch -q -c desserts
sb_write cake.txt "Chocolate cake"
sb_write bread.txt "Flour" "Water" "Salt" "Sugar"
sb_commit "Add cake, sweeten the bread"
git switch -q -c drinks main
sb_write lemonade.txt "Lemons" "Sugar" "Water"
sb_commit "Add lemonade"
git switch -q -c pies main
sb_write apple-pie.txt "Apples" "Pastry"
sb_commit "Add apple pie"
git push -q origin main drinks pies
git push -q "$SANDBOX_ROOT/backup.git" drinks
git switch -q main
git branch -q -D drinks pies
git remote add backup "$SANDBOX_ROOT/backup.git"
git fetch -q origin
git fetch -q backup
git branch -q -u origin/main
sb_write soup.txt "Tomato soup" "Serves 6"
sb_commit "Make more soup"
git branch -q docs v1.0
git worktree add -q "$SANDBOX_ROOT/recipes-docs" docs
# A branch that tracks a log file on purpose, although *.log is ignored.
git switch -q -c logs
sb_write debug.log "tracked log"
git add -f debug.log
git commit -q -m "Track a log on purpose"
git switch -q main
RECIPES_NOW=$SANDBOX_NOW

# =============================================================================
sb_say "--- S1. switching ---"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git branch -vv"
sb_run "ls"
sb_run "git switch desserts"
sb_run "ls"
sb_run "cat .git/HEAD"
sb_run "cat bread.txt"
sb_run "git switch main"
sb_run "ls"
sb_run "git switch -"
sb_run "git switch -"
sb_run "git switch @{-1}"
sb_run "git switch -q main"
sb_run "git switch main"
sb_run "git switch nosuch"
sb_run "git switch soup.txt"
sb_run "git switch desserts soup.txt"
sb_run "git switch HEAD~1"
sb_run "git switch v1.0"
sb_run "git switch origin/main"
sb_run "git switch docs"
sb_run "git switch --ignore-other-worktrees docs"
sb_run "git switch -q main"
git init -q "$SANDBOX_ROOT/fresh"
sb_run "git -C ../fresh switch -"

sb_say "--- S2. guessing ---"
sb_run "git branch -r"
sb_run "git switch pies"
sb_run "git branch -vv --list pies"
sb_run "git switch -q main"
sb_run "git switch drinks"
sb_run "git remote -v"
sb_run "git -c checkout.defaultRemote=origin switch drinks"
sb_run "git switch -q main"
sb_run "git branch -q -D drinks pies"
sb_run "git switch --no-guess pies"
sb_run "git -c checkout.guess=false switch pies"
sb_run "git switch --track origin/drinks"
sb_run "git switch -q main"
sb_run "git branch -q -D drinks"
sb_run "git switch -c my-drinks origin/drinks"
sb_run "git switch -q main"
sb_run "git switch --no-track -c drinks2 origin/drinks"
sb_run "git switch -q main"
sb_run "git branch -vv --list 'my-drinks' 'drinks2'"
sb_run "git branch -q -D my-drinks drinks2"

sb_say "--- S3. local changes ---"
sb_write README.md "# Recipes" "Family favourites."
sb_run "git status --short"
sb_run "git switch desserts"
sb_run "git status --short"
sb_run "git switch -q main"
sb_write bread.txt "Flour" "Water" "Salt" "Yeast"
sb_run "git status --short"
sb_run "git switch desserts"
sb_run "git branch --show-current"
sb_run "git switch -m desserts"
sb_run "git status --short"
sb_run "cat bread.txt"
sb_run "git stash list"
sb_run "git reset -q --hard"
sb_run "git switch -q main"
sb_run "git stash pop"
sb_run "git stash list"
sb_run "git switch --conflict=diff3 desserts"
sb_run "cat bread.txt"
sb_run "git reset -q --hard"
sb_run "git switch -q main"
sb_run "git stash drop"
sb_write bread.txt "Strong flour" "Water" "Salt"
sb_run "git diff"
sb_run "git switch desserts"
sb_run "git switch -m desserts"
sb_run "cat bread.txt"
sb_run "git stash list"
sb_run "git switch -m main"
sb_run "cat bread.txt"
sb_write bread.txt "Flour" "Water" "Salt" "Yeast"
sb_run "git add bread.txt"
sb_run "git status --short"
sb_run "git switch desserts"
sb_run "git switch --discard-changes desserts"
sb_run "git status --short"
sb_run "cat bread.txt"
sb_run "git switch -q main"
sb_write bread.txt "Flour" "Water" "Salt" "Yeast"
sb_run "git switch -f desserts"
sb_run "git switch -q main"
sb_write cake.txt "My own cake"
sb_run "git status --short"
sb_run "git switch desserts"
sb_run "git switch -f desserts"
sb_run "cat cake.txt"
sb_run "git switch -q main"
sb_write cake.txt "My own cake"
sb_run "git checkout -f desserts"
sb_run "cat cake.txt"
sb_run "git switch -q main"
sb_write debug.log "my local log"
sb_run "git status --short --ignored"
sb_run "git switch --no-overwrite-ignore logs"
sb_run "git switch --overwrite-ignore logs"
sb_run "cat debug.log"
sb_run "git switch -q main"
sb_write debug.log "my local log"
sb_run "git switch logs"
sb_run "cat debug.log"
sb_run "git switch -q main"
cd "$SANDBOX_ROOT/recipes"; SANDBOX_NOW=$RECIPES_NOW; sb_settime

sb_say "--- S4. creating ---"
sb_run "git switch -c topic"
sb_run "git switch -c topic"
sb_run "git switch -C topic v1.0"
sb_run "git log --oneline -1"
sb_run "git switch -q main"
sb_run "git switch -c fix v1.0"
sb_run "git switch -q main"
sb_run "git switch -c base desserts...main"
sb_run "git log --oneline -1"
sb_run "git switch -q main"
sb_write README.md "# Recipes" "Draft."
sb_run "git switch -c draft"
sb_run "git status --short"
sb_run "git switch -q main"
sb_run "git restore README.md"
sb_run "git switch -C docs main"
sb_run "git branch -v --list docs"
sb_run "git switch -c docs2 nosuch"
sb_run "git branch --list docs2"
sb_run "git branch -q -D topic fix base draft"

sb_say "--- S5. detached HEAD ---"
sb_run "git switch --detach v1.0"
sb_run "git status"
sb_run "git branch"
sb_run "cat .git/HEAD"
sb_write bread.txt "Flour" "Water" "Salt" "Rosemary"
sb_run "git commit -q -am 'Try rosemary bread'"
sb_run "git status | head -1"
sb_run "git log --oneline --graph --decorate HEAD main"
sb_run "git switch main"
detached=$(git rev-parse --short HEAD@{1})
sb_run "git reflog -3"
sb_run "git branch rosemary $detached"
sb_run "git switch -d"
sb_run "git switch main"
sb_run "git switch --detach HEAD~1"
sb_run "git switch -c fix-soup"
sb_run "git switch -q main"
sb_run "git switch -q --detach"
git switch -q --detach
sb_run "git commit -q --allow-empty -m 'Keep me'"
git commit -q --allow-empty -m 'Keep me'
sb_run "git branch keep-me"
sb_run "git status | head -1"
sb_run "git switch main"
sb_run "git checkout v1.0"
sb_run "git checkout -q main"
git checkout -q main
sb_run "git -c advice.detachedHead=false checkout v1.0"
sb_run "git checkout -q main"
git checkout -q main
sb_run "git checkout origin/main"
sb_run "git checkout -q main"
git checkout -q main
sb_run "git checkout --detach"
sb_run "git checkout -q main"
git checkout -q main
git branch -q -D rosemary fix-soup keep-me

sb_say "--- S6. orphan ---"
sb_write notes.txt "untracked notes"
sb_run "git switch --orphan gh-pages"
sb_run "ls"
sb_run "git status --short"
sb_run "git log; echo \"exit \$?\""
sb_write index.html "<h1>Recipes</h1>"
sb_run "git add index.html"
sb_run "git commit -q -m 'Publish the site'"
sb_run "git log --oneline"
sb_run "git switch -q main"
git switch -q main
sb_run "ls"
sb_run "git checkout --orphan snapshot"
sb_run "git status --short"
sb_run "git commit -q -m 'History starts here'"
sb_run "git log --oneline"
sb_run "git switch -q main"
git switch -q main
sb_run "git switch --orphan gh-pages2 v1.0"
sb_run "git checkout --orphan snapshot2 v1.0"
sb_run "git status --short"
git switch -q -f main
git branch -q -D snapshot gh-pages
rm -f notes.txt

sb_say "--- S7. checkout differences ---"
sb_run "git checkout"
sb_run "git checkout desserts"
sb_run "git checkout -"
sb_run "git checkout -b topic v1.0"
sb_run "git checkout -B topic main"
sb_run "git checkout -q main"
git checkout -q main
sb_run "git checkout -l -b with-log"
sb_run "git reflog show with-log"
sb_run "git checkout -q main"
git checkout -q main
sb_run "git checkout --track origin/drinks"
sb_run "git checkout -q main"
git checkout -q main
git branch -q -D topic with-log drinks
sb_write pies "Notes about pies"
sb_run "git status --short"
sb_run "git checkout pies"
sb_run "git switch pies"
sb_run "git switch -q main"
git switch -q main
git branch -q -D pies
sb_run "git checkout pies --"
sb_run "git checkout -q main"
git checkout -q main
git branch -q -D pies
sb_run "git checkout -- pies"
sb_run "git add pies"
sb_run "git checkout pies"
sb_run "git checkout pies --"
sb_run "git branch --show-current"
sb_run "git checkout -q main"
git checkout -q main
git branch -q -D pies
git rm -q --cached pies
rm -f pies

sb_say "--- S8. quiet, progress ---"
sb_run "git switch -q desserts"
sb_run "git switch --progress main"
sb_run "GIT_PROGRESS_DELAY=0 git switch --progress desserts"
sb_run "GIT_PROGRESS_DELAY=0 git switch --progress -q main"
sb_run "GIT_PROGRESS_DELAY=0 git switch --no-progress desserts"
sb_run "git switch -q main"
sb_run "git switch --recurse-submodules desserts"
sb_run "git switch -q main"
