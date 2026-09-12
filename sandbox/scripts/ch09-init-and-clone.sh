#!/bin/bash
# Generates every transcript in Chapter 9, "init and clone".
#
#   bash sandbox/scripts/ch09-init-and-clone.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null

sb_say "--- 1. git init and what it makes ---"
cd "$SANDBOX_ROOT"
sb_run git init project
cd project
sb_run "find .git -maxdepth 1 | sort"
sb_run "find .git -type f | sort"
sb_run "cat .git/HEAD"
sb_run "cat .git/config"

sb_say "--- 2. init is safe to run twice ---"
sb_run git init
sb_run git init

sb_say "--- 3. init does not touch your files ---"
sb_write keep.txt "still here"
sb_run git init
sb_run cat keep.txt
sb_run git status --short

sb_say "--- 4. choosing the first branch name ---"
cd "$SANDBOX_ROOT"
sb_run git init -b trunk other
sb_run "cat other/.git/HEAD"

sb_say "--- 5. a bare repository has no working tree ---"
sb_run git init --bare server.git
sb_run "ls server.git"
sb_run "git -C server.git config core.bare"
sb_run "git -C server.git rev-parse --is-bare-repository"

sb_say "--- 6. building something to clone ---"
cd "$SANDBOX_ROOT/project"
sb_write README.md "# Project"
sb_commit "Add README"
sb_write src/main.py "print('one')"
sb_commit "Add main"
sb_write src/util.py "def helper(): pass"
sb_commit "Add util"
git switch -q -c topic
sb_write src/extra.py "extra"
sb_commit "Add extra on topic"
git switch -q main
git remote add origin "$SANDBOX_ROOT/server.git"
git push -q origin main topic
sb_run git log --oneline

sb_say "--- 7. clone, and what it set up for you ---"
cd "$SANDBOX_ROOT"
sb_run git clone server.git fresh
cd fresh
sb_run git log --oneline
sb_run git remote -v
sb_run git branch
sb_run git branch -a
sb_run git status -sb
sb_run "git config get remote.origin.url"
sb_run "git config get branch.main.remote"
sb_run "git config get branch.main.merge"

sb_say "--- 8. clone refuses to overwrite a non-empty directory ---"
cd "$SANDBOX_ROOT"
mkdir -p occupied && printf 'mine\n' > occupied/file.txt
sb_run git clone server.git occupied || true
sb_run "ls occupied"
mkdir -p empty-target
sb_run git clone server.git empty-target

sb_say "--- 9. cloning an empty repository warns ---"
sb_run git init --bare nothing.git
sb_run git clone nothing.git nothing-clone
sb_run "git -C nothing-clone status"

sb_say "--- 10. shallow clones, and the local-path trap ---"
sb_run git clone --depth 1 server.git shallow-broken
sb_run "git -C shallow-broken log --oneline"
sb_run "git -C shallow-broken rev-parse --is-shallow-repository"
sb_run git clone --depth 1 "file://$SANDBOX_ROOT/server.git" shallow
sb_run "git -C shallow log --oneline"
sb_run "git -C shallow rev-parse --is-shallow-repository"
sb_run "cat shallow/.git/shallow"
sb_run "git -C shallow log --oneline main"

sb_say "--- 10b. single-branch clones ---"
sb_run git clone --single-branch --branch topic server.git just-topic
sb_run "git -C just-topic branch -a"
sb_run "git -C just-topic log --oneline"
sb_run "git -C just-topic config get --all remote.origin.fetch"

sb_say "--- 11. bare and mirror clones ---"
sb_run git clone --bare server.git copy-bare.git
sb_run "ls copy-bare.git | head"
sb_run "git -C copy-bare.git config get --all remote.origin.fetch" || true
sb_run git clone --mirror server.git copy-mirror.git
sb_run "git -C copy-mirror.git config get --all remote.origin.fetch"
sb_run "git -C copy-bare.git branch"
sb_run "git -C copy-mirror.git branch"

sb_say "--- 12. clone is four commands in a coat ---"
mkdir -p byhand && cd byhand
sb_run git init -q
sb_run git remote add origin "$SANDBOX_ROOT/server.git"
sb_run git fetch -q origin
sb_run git switch -q main
sb_run git log --oneline
sb_run git status -sb
