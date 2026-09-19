#!/bin/bash
# Generates every transcript in Chapter 7, "Refs, HEAD, and Branches as Pointers".
#
#   bash sandbox/scripts/ch07-refs-head-and-branches.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/refs" >/dev/null

sb_write a.txt "first"
sb_commit "First commit"
sb_write b.txt "second"
sb_commit "Second commit"

sb_say "--- 1. a branch is a file containing a hash ---"
sb_run "cat .git/refs/heads/main"
sb_run "wc -c < .git/refs/heads/main"
sb_run git rev-parse main

sb_say "--- 2. HEAD is a file containing the name of a branch ---"
sb_run "cat .git/HEAD"
sb_run git symbolic-ref HEAD
sb_run git rev-parse HEAD main refs/heads/main

sb_say "--- 3. creating a branch writes one small file ---"
sb_run "ls .git/refs/heads"
sb_run git branch feature
sb_run "ls .git/refs/heads"
sb_run "cat .git/refs/heads/feature"
sb_run git branch -v

sb_say "--- 4. switching a branch rewrites HEAD ---"
sb_run git switch feature
sb_run "cat .git/HEAD"
sb_run git switch main
sb_run "cat .git/HEAD"

sb_say "--- 5. committing moves the branch the file points at ---"
sb_run "cat .git/refs/heads/main"
sb_run "echo third > c.txt && git add c.txt && git commit -m 'Third commit'"
sb_tick
sb_run "cat .git/refs/heads/main"
sb_run "cat .git/refs/heads/feature"

sb_say "--- 6. detached HEAD is HEAD holding a hash instead of a name ---"
sb_run git switch --detach HEAD~1
sb_run "cat .git/HEAD"
sb_run git symbolic-ref HEAD || true
sb_run git status
sb_run git branch --show-current

sb_say "--- 6b. the same state reached with checkout ---"
git switch -q main
sb_run git checkout HEAD~1
git switch -q main

sb_say "--- 7. moving a branch by hand ---"
sb_run git log --oneline
sb_run git update-ref refs/heads/feature HEAD~2
sb_run git branch -v
sb_run git update-ref refs/heads/feature HEAD
sb_run git branch -v

sb_say "--- 8. listing refs ---"
sb_run git show-ref
sb_run "git for-each-ref --format='%(refname) %(objecttype) %(objectname:short)'"

sb_say "--- 9. refs can be packed away into one file ---"
sb_run "ls .git/refs/heads"
sb_run git pack-refs --all
sb_run "ls .git/refs/heads || true"
sb_run "cat .git/packed-refs"
sb_run git rev-parse main
sb_run git branch -v

sb_say "--- 10. a ref is a path, so one branch name can block another ---"
sb_run git branch feature/login || true
sb_run git branch -D feature
sb_run git branch feature/login
sb_run "find .git/refs -type f | sort"
sb_run git branch feature || true
sb_run git branch feature/login/deeper || true

sb_say "--- 11. what names are legal ---"
sb_run "git check-ref-format --branch 'good-name'"
sb_run "git check-ref-format --branch 'bad name'" || true
sb_run "git branch 'bad name'" || true
sb_run "git branch 'ends.lock'" || true
sb_run "git branch 'has..dots'" || true
sb_run "git branch -- '-leading-dash'" || true
sb_run "git check-ref-format refs/heads/-x && echo valid"
sb_run "git check-ref-format --branch -x" || true

sb_say "--- 11b. a branch called @ ---"
sb_run "git branch @ HEAD~1 && git log --oneline -1 @ && git log --oneline -1 heads/@"
sb_run "git switch @" || true
git update-ref -d refs/heads/@

sb_say "--- 12. the same rule in a reftable repository ---"
mkdir -p "$SANDBOX_ROOT/rt" && cd "$SANDBOX_ROOT/rt" && git init -q --ref-format=reftable
git commit -q --allow-empty -m "Start"
sb_run "git branch feature && git branch feature/login" || true
sb_run "cat .git/HEAD && git symbolic-ref HEAD"
