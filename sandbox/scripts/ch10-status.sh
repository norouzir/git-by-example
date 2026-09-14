#!/bin/bash
# Generates every transcript in Chapter 10, "status".
#
#   bash sandbox/scripts/ch10-status.sh [dir]
#
# No `set -e`: several commands shown here exit non-zero on purpose, such as a
# merge that stops on a conflict or `git commit --dry-run` with nothing staged,
# and the transcript must carry on past them.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_fresh "$SANDBOX_ROOT/work" >/dev/null

sb_write README.md "# Project"
sb_write app.py "print('hello')"
sb_write notes.md "notes"
sb_write build/out.log "noise"
sb_write .gitignore "build/"
sb_commit "Initial commit"
git remote add origin "$SANDBOX_ROOT/server.git"
git push -q -u origin main

sb_say "--- 1. a clean tree ---"
sb_run git status
sb_run git status --short
sb_run git status -sb

sb_say "--- 2. every kind of change at once ---"
sb_write README.md "# Project" "Now with more words."
git add README.md
sb_write README.md "# Project" "Now with more words." "And more still."
sb_write app.py "print('hello')" "print('world')"
git mv notes.md docs.md
rm -f .gitignore
sb_write newfile.txt "brand new"
sb_write build/another.log "more noise"
sb_run git status
sb_run git status --short
sb_run "git diff --cached --name-status"
sb_run "git diff --name-status"
sb_run "git ls-files --others --exclude-standard"

sb_say "--- 3. the branch header ---"
sb_run git status -sb
sb_run git status --short --branch --ahead-behind

sb_say "--- 4. machine-readable output ---"
sb_run git status --porcelain
sb_run git status --porcelain=v1
sb_run "git status --porcelain=v2 --branch"

sb_say "--- 5. how much to say about untracked files ---"
sb_write extra/one.txt "a"
sb_write extra/two.txt "b"
sb_run "git status --short --untracked-files=normal"
sb_run "git status --short --untracked-files=all"
sb_run "git status --short --untracked-files=no"
sb_run git status -uno

sb_say "--- 6. ignored files ---"
git checkout -q -- .gitignore 2>/dev/null || git restore .gitignore
sb_run git status --short
sb_run git status --short --ignored
sb_run "git status --short --ignored=matching"

sb_say "--- 7. ahead and behind a remote ---"
git add -A >/dev/null && git commit -q -m "Work in progress" && sb_tick
sb_run git status -sb
sb_run git status
sb_run "git log --oneline origin/main..HEAD"

sb_say "--- 8. detached HEAD ---"
sb_run git switch -q --detach HEAD~1
sb_run git status
sb_run git status -sb
sb_run git switch -q -

sb_say "--- 9. during a conflict ---"
git switch -q -c other HEAD~1
sb_write app.py "print('hello')" "print('from other')"
sb_commit "Change app on other"
git switch -q main
sb_run "git merge other"
sb_run git status
sb_run git status --short
sb_run git status -sb
sb_run "git ls-files --stage app.py"
sb_run git merge --abort
sb_run git status --short

sb_say "--- 10. during a rebase ---"
sb_run "git rebase other"
sb_run git status
sb_run git rebase --abort
sb_run git status -sb

# =============================================================================
# Everything below runs in repositories of its own, so nothing above changes.

cd "$SANDBOX_ROOT"

sb_say "--- N1. outside a repository, and before the first commit ---"
sb_run "git status"
sb_fresh "$SANDBOX_ROOT/empty" >/dev/null
sb_run "git status"
sb_run "git status -sb"
sb_write a.txt "a"
sb_run "git status"
sb_run "git status -sb"
sb_run "git status --porcelain=v2 --branch"

sb_say "--- N2. every combination of the two columns ---"
sb_fresh "$SANDBOX_ROOT/xy" >/dev/null
for f in a b c d e f g h i j; do
	sb_write $f.txt "line of $f" "second line of $f" "third line of $f"
done
sb_commit "Base"
sb_write new1.txt "new"; git add new1.txt
sb_write new2.txt "new"; git add new2.txt; sb_write new2.txt "new" "more"
sb_write new3.txt "new"; git add new3.txt; rm new3.txt
sb_write a.txt "changed"; git add a.txt
sb_write b.txt "changed"; git add b.txt; sb_write b.txt "changed again"
sb_write c.txt "changed"; git add c.txt; rm c.txt
git rm -q d.txt
rm e.txt
sb_write f.txt "line of f" "second line of f" "third line of f" "fourth"
git mv g.txt g2.txt
git mv h.txt h2.txt; sb_write h2.txt "line of h" "second line of h" "third line of h" "more"
git mv i.txt i2.txt; rm i2.txt
sb_run "git status --short"
sb_run "git status"
sb_run "mv j.txt j2.txt && git add -N j2.txt"
sb_run "git status --short -- j.txt j2.txt"

sb_say "--- N3. a type change ---"
sb_fresh "$SANDBOX_ROOT/typ" >/dev/null
sb_write link.txt "target.txt"
sb_commit "Base"
h=$(git hash-object -w link.txt)
sb_run "git update-index --cacheinfo 120000,$h,link.txt"
sb_run "git status --short"
sb_run "git status"

sb_say "--- N4. unusual file names ---"
sb_fresh "$SANDBOX_ROOT/names" >/dev/null
sb_write "old name.txt" "o"
sb_commit "Base"
git mv "old name.txt" "new name.txt"
sb_write "café.txt" "x"
sb_run "git status --short"
sb_run "git -c core.quotePath=false status --short"
sb_run "git status -z | tr '\0' '@'; echo"
sb_run "git status --porcelain=v2 -z | tr '\0' '@'; echo"

sb_say "--- N5. the branch header in every state ---"
git init -q --bare "$SANDBOX_ROOT/srv.git"
sb_fresh "$SANDBOX_ROOT/br" >/dev/null
sb_write f.txt "1"
sb_commit "One"
git remote add origin "$SANDBOX_ROOT/srv.git"
git push -q -u origin main
git clone -q "$SANDBOX_ROOT/srv.git" "$SANDBOX_ROOT/colleague"
(cd "$SANDBOX_ROOT/colleague" && sb_write g.txt "2" && sb_commit "From a colleague" && git push -q)
sb_tick
git fetch -q
sb_run "git status -sb"
sb_run "git status"
sb_write h.txt "3"
sb_commit "Local"
sb_run "git status -sb"
sb_run "git status"
sb_run "git status --porcelain=v2 --branch"

sb_say "--- N6. skipping the ahead and behind count ---"
sb_run "git status --no-ahead-behind"
sb_run "git status -sb --no-ahead-behind"
sb_run "git status --porcelain=v2 --branch --no-ahead-behind"
sb_run "git -c status.aheadBehind=false status -sb"
sb_run "git -c status.aheadBehind=false status --porcelain=v2 --branch"

sb_say "--- N7. no upstream, and an upstream that is gone ---"
sb_run "git switch -q -c solo"
sb_run "git status -sb"
sb_run "git status"
sb_run "git push -q -u origin solo"
sb_run "git push -q origin --delete solo"
sb_run "git status -sb"
sb_run "git status"
sb_run "git status --porcelain=v2 --branch"
sb_run "git switch -q --detach main"
sb_run "git status --porcelain=v2 --branch"
sb_run "git switch -q main"

sb_say "--- N8. comparing with more than one branch ---"
git init -q --bare "$SANDBOX_ROOT/fork.git"
sb_run "git remote add fork $SANDBOX_ROOT/fork.git"
sb_run "git config set remote.pushDefault fork"
sb_run "git config set push.default current"
sb_run "git push -q"
sb_write i.txt "4"
sb_commit "Not pushed anywhere"
sb_run "git status"
sb_run "git -c 'status.compareBranches=@{upstream} @{push}' status"
sb_run "git -c 'status.compareBranches=@{push}' status"
sb_run "git -c 'status.compareBranches=@{upstream} @{push}' status -sb"

sb_say "--- N9. the stash ---"
sb_write f.txt "changed"
git stash -q
sb_run "git status --show-stash"
sb_run "git status --porcelain=v2 --show-stash"
sb_run "git status -sb --show-stash"
sb_run "git -c status.showStash=true status"

sb_say "--- N10. paths and subdirectories ---"
sb_fresh "$SANDBOX_ROOT/sub" >/dev/null
sb_write README.md "r"
sb_write src/app.py "a"
sb_write src/lib/util.py "u"
sb_commit "Base"
sb_write README.md "r2"
sb_write src/app.py "a2"
sb_write src/lib/util.py "u2"
sb_write src/new.py "n"
cd src
sb_run "git status"
sb_run "git status --short"
sb_run "git -c status.relativePaths=false status --short"
sb_run "git status --short ."
sb_run "git status --short -- lib"
sb_run "git status --short :/README.md"
sb_run "cd .."
cd ..
sb_run "git status --short -- '*.py'"
cd src
sb_run "git status nothing-here"
sb_run "git status --porcelain"
cd ..

sb_say "--- N11. untracked files: every spelling ---"
sb_fresh "$SANDBOX_ROOT/unt" >/dev/null
sb_write keep.txt "k"
sb_commit "Base"
sb_write dir/one.txt "1"
sb_write dir/two.txt "2"
sb_write top.txt "t"
sb_run "git status --short -u"
sb_run "git status --short --untracked-files=true"
sb_run "git status --short --untracked-files=false"
sb_run "git status --short --untracked-files=maybe"
sb_run "git -c status.showUntrackedFiles=all status --short"
sb_run "git -c status.showUntrackedFiles=all status --short -unormal"
sb_run "git status --short -u no"

sb_say "--- N12. ignored files: every mode ---"
sb_fresh "$SANDBOX_ROOT/ign" >/dev/null
sb_write .gitignore "*.log" "build/"
sb_commit "Base"
sb_write build/out.bin "x"
sb_write logs/a.log "x"
sb_write logs/b.log "x"
sb_write mixed/c.log "x"
sb_write mixed/keep.txt "x"
sb_write top.log "x"
sb_run "cat .gitignore"
sb_run "git status --short --ignored=traditional"
sb_run "git status --short --ignored=matching"
sb_run "git status --short --ignored=no"
sb_run "git status --short --ignored=traditional -uall"
sb_run "git status --short --ignored=matching -uall"
sb_run "git status --ignored"

sb_say "--- N13. renames ---"
sb_fresh "$SANDBOX_ROOT/ren" >/dev/null
sb_write long.txt 1 2 3 4 5 6 7 8 9 10
sb_commit "Base"
git mv long.txt moved.txt
sb_write moved.txt 1 2 3 4 5 6 7 X Y Z
git add moved.txt
sb_run "git status --short"
sb_run "git status --short --no-renames"
sb_run "git status --short --find-renames=50"
sb_run "git status --short -M80"
sb_run "git -c status.renames=false status --short"
sb_run "git -c status.renames=false status --short --renames"
sb_run "cp moved.txt copy.txt && git add copy.txt"
sb_run "git status --short"
sb_run "git -c status.renames=copies status --short"

sb_say "--- N14. the changes themselves ---"
sb_fresh "$SANDBOX_ROOT/verb" >/dev/null
sb_write app.py "print('hello')"
sb_commit "Base"
sb_write app.py "print('hello')" "print('staged')"
git add app.py
sb_write app.py "print('hello')" "print('staged')" "print('not staged')"
sb_run "git status -v"
sb_run "git status -vv"
sb_run "git status -s -v"

sb_say "--- N15. columns ---"
sb_fresh "$SANDBOX_ROOT/col" >/dev/null
sb_write keep.txt "k"
sb_commit "Base"
for n in alpha beta gamma delta epsilon zeta eta theta iota kappa lambda; do sb_write $n.txt "x"; done
sb_run "git status --column"
sb_run "git status --column=row"
sb_run "COLUMNS=40 git status --column"
sb_run "git -c column.status=always status --no-column"
sb_run "git status --short --column"

sb_say "--- N16. settings that change the default output ---"
cd "$SANDBOX_ROOT/sub"
sb_run "git -c status.short=true status"
sb_run "git -c status.short=true status --no-short"
sb_run "git -c status.short=true status --long"
sb_run "git -c status.short=true -c status.branch=true status"
sb_run "git -c status.branch=true status --short --no-branch"
sb_run "git -c advice.statusHints=false status"
sb_run "git -c status.displayCommentPrefix=true status"

sb_say "--- N17. is the tree dirty ---"
sb_run "git status --short; echo \"exit \$?\""
sb_run "test -z \"\$(git status --porcelain)\" && echo clean || echo dirty"
sb_run "git commit --dry-run --short; echo \"exit \$?\""
sb_run "git add README.md"
sb_run "git commit --dry-run --short; echo \"exit \$?\""
sb_run "git commit --dry-run -a --short; echo \"exit \$?\""
sb_run "git diff --quiet; echo \"exit \$?\""
sb_run "git diff --cached --quiet; echo \"exit \$?\""

sb_say "--- N18. colour ---"
git init -q --bare "$SANDBOX_ROOT/csrv.git"
sb_fresh "$SANDBOX_ROOT/colour" >/dev/null
sb_write app.py "print('hello')"
sb_write README.md "# Project"
sb_commit "Base"
git remote add origin "$SANDBOX_ROOT/csrv.git"
git push -q -u origin main
sb_write README.md "# Project" "More"
sb_commit "Local"
sb_write app.py "print('hello')" "print('staged')"
git add app.py
sb_write README.md "# Project" "More" "Unstaged"
sb_write todo.txt "untracked"
sb_run_ansi "git status -sb"
sb_run_ansi "git status"

sb_say "--- N19. conflict codes ---"
sb_fresh "$SANDBOX_ROOT/codes" >/dev/null
sb_write both-mod.txt "base"
sb_write del-us.txt "base"
sb_write del-them.txt "base"
sb_write ren.txt "base" "content" "more"
sb_commit "Base"
git switch -q -c theirs
sb_write both-mod.txt "theirs"
git rm -q del-them.txt
sb_write del-us.txt "changed by them"
sb_write both-add.txt "theirs"
git mv ren.txt ren-theirs.txt
sb_commit "Theirs"
git switch -q main
sb_write both-mod.txt "ours"
git rm -q del-us.txt
sb_write del-them.txt "changed by us"
sb_write both-add.txt "ours"
git mv ren.txt ren-ours.txt
sb_commit "Ours"
sb_run "git merge theirs"
sb_run "git status --short"
sb_run "git status"
sb_run "git status --porcelain=v2"

sb_say "--- N20. other operations in progress ---"
sb_fresh "$SANDBOX_ROOT/ops" >/dev/null
sb_write app.py "one"
sb_commit "Base"
git switch -q -c side
sb_write app.py "side"
sb_commit "Side change"
git switch -q main
sb_write app.py "two"
sb_commit "Change to two"
sb_write app.py "three"
sb_commit "Change to three"
sb_run "git cherry-pick side"
sb_run "git status"
sb_run "git cherry-pick --abort"
sb_run "git revert --no-edit HEAD~1"
sb_run "git status"
sb_run "git revert --abort"
sb_run "git merge side"
sb_write app.py "resolved"
sb_run "git add app.py"
sb_run "git status"
sb_run "git merge --abort"
sb_run "git bisect start"
sb_run "git status"
sb_run "git bisect reset"
sb_run "git rebase side"
sb_run "git status --porcelain=v2 --branch"
sb_run "git rebase --abort"

sb_say "--- N21. a sparse checkout ---"
sb_fresh "$SANDBOX_ROOT/sparse" >/dev/null
sb_write a/1.txt "1"
sb_write b/2.txt "2"
sb_write top.txt "t"
sb_commit "Base"
sb_run "git sparse-checkout set a"
sb_run "git status"
