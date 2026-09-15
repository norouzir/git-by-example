#!/bin/bash
# Generates every transcript in Chapter 18, "Revision Syntax and show".
#
#   bash sandbox/scripts/ch18-revision-syntax-and-show.sh [dir]
#
# No `set -e`: many commands shown here fail on purpose, such as a revision
# that does not exist or an ambiguous name, and the transcript must carry on.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
# Reflog entries named by date count back from "now".
sb_pin_now

# ---------------------------------------------------------------------------
# S1-S5. git show, on a small menu project.
sb_fresh "$SANDBOX_ROOT/menu" >/dev/null
sb_write menu.txt "soup" "-" "-" "-" "bread"
sb_commit "Start the menu"
sb_write menu.txt "soup" "-" "-" "-" "bread" "-" "-" "-" "salad"
sb_write notes/today.txt "busy"
sb_commit "Add salad and notes"
git tag -a v1 -m "First menu" -m "Printed on Monday."
sb_tick
git switch -q -c lunch
sb_write menu.txt "soup of the day" "-" "-" "-" "bread" "-" "-" "-" "salad"
sb_commit "Name the soup"
git switch -q main
sb_write menu.txt "soup" "-" "-" "-" "bread" "-" "-" "-" "green salad"
sb_commit "Choose the salad"

sb_say "--- S1. reading the output ---"
sb_run "git show"
sb_run "git show HEAD~2"

sb_say "--- S2. every kind of object ---"
sb_run "git show v1"
sb_run "git show v1^{tree}"
sb_run "git show HEAD:notes"
sb_run "git show HEAD:menu.txt"
git tag draft HEAD~1
sb_run "git show -s draft"
git merge -q --no-edit lunch >/dev/null 2>&1
sb_tick
sb_run "git show"
sb_run "git show -m --stat --oneline"
sb_run "git show --first-parent --stat --oneline"
sb_run "git show --diff-merges=off --oneline"

sb_say "--- S3. several objects ---"
sb_run "git show -s --oneline HEAD~2 HEAD~3"
sb_run "git show -s --oneline HEAD~3 HEAD~2"
sb_run "git show -s --oneline HEAD~2 HEAD~2 main~2"
sb_run "git show -s --oneline HEAD~2 HEAD:notes"
sb_run "git show -s --oneline HEAD~3..HEAD^"
sb_run "git show --oneline nosuch"

sb_say "--- S4. less or different output ---"
sb_run "git show -s HEAD~1"
sb_run "git show --no-patch --oneline HEAD~1"
sb_run "git show -q --oneline HEAD~1"
sb_run "git show --stat --oneline HEAD~2"
sb_run "git show --format= HEAD~1"
sb_run "git show -s --format='%h %an %s' HEAD~2"
sb_run "git show --oneline HEAD~2 -- notes"
sb_run "git show --oneline HEAD~2 -- nosuch.txt"
sb_run "git show -s --oneline v1"

sb_say "--- S2b. a merge that needed a hand ---"
git switch -q -c dinner HEAD~2
sb_write menu.txt "soup" "-" "-" "-" "bread" "-" "-" "-" "steak"
sb_commit "Steak for dinner"
git switch -q main
git merge -q dinner >/dev/null 2>&1
sb_write menu.txt "soup of the day" "-" "-" "-" "bread" "-" "-" "-" "green salad or steak"
git add menu.txt
git commit -q -m "Merge branch 'dinner'"
sb_tick
sb_run "git show"
sb_run "diff <(git show) <(git show --cc) && echo same"
sb_run "git show --remerge-diff --oneline"

# ---------------------------------------------------------------------------
# S6-S12. Naming objects, on an app with a remote, tags and a side branch.
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_fresh "$SANDBOX_ROOT/app" >/dev/null
git remote add origin "$SANDBOX_ROOT/server.git"
sb_write README.md "# App"
sb_commit "Add README"
sb_write src/app.py "print('hello')"
sb_commit "Add the app"
git tag -a v1.0 -m "Release 1.0"
git tag -a v1.0-approved -m "Approved for release" v1.0 2>/dev/null
git tag first-app
sb_write src/app.py "print('hello, world')"
sb_commit "Fix nasty bug in greeting"
sb_write docs/guide.md "Guide"
sb_commit "Write the guide"
git push -q -u origin main
git switch -q -c idea
sb_write src/app.py "print('hello, world')" "import antigravity"
sb_commit "Try a nasty hack"
git switch -q main
sb_write src/app.py "print('hello, world!')"
sb_commit "Add excitement"
APP_NOW=$SANDBOX_NOW
# back_to_app : return to the app, with its clock and its "now"
back_to_app() { cd "$SANDBOX_ROOT/app"; SANDBOX_NOW=$APP_NOW; sb_settime; }

sb_say "--- S6. hashes, names and describe ---"
sb_run "git log --oneline --decorate --all"
full=$(git rev-parse HEAD)
short=$(git rev-parse --short HEAD)
sb_run "git show -s --format=%s $full"
sb_run "git show -s --format=%s $short"
sb_run "git show -s --format=%s ${short:0:4}"
sb_run "git show -s --format=%s ${short:0:3}"
sb_run "git describe"
desc=$(git describe)
sb_run "git show -s --format=%s $desc"
sb_run "git show -s --format=%s v9.9-99-g$short"
sb_run "git show -s --format=%s main"
sb_run "git show -s --format=%s origin/main"
sb_run "git show -s --format=%s @"

sb_say "--- S6b. ambiguous names ---"
git branch first-app HEAD~4
sb_run "git show -s --format=%s first-app"
sb_run "git show -s --format=%s heads/first-app"
sb_run "git show -s --format=%s tags/first-app"
sb_run "git show -s --format=%s refs/heads/first-app"
sb_run "git -c core.warnAmbiguousRefs=false show -s --format=%s first-app"
git branch -q -D first-app

# A separate repository where a short hash is shared by a commit and two blobs.
sb_fresh "$SANDBOX_ROOT/crowded" >/dev/null
for i in $(seq 1 12); do sb_write count.txt "$i"; sb_commit "Count to $i"; done
mkdir -p blobs
for i in $(seq 1 8000); do printf 'blob %d\n' "$i" > "blobs/$i"; done
ls blobs/* | git hash-object -w --stdin-paths >/dev/null
rm -rf blobs
prefix=$(git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' |
	awk '{p=substr($1,1,4); n[p]++; if ($2=="commit") c[p]=1} END {for (p in n) if (n[p]>1 && c[p]) print p}' |
	sort | head -1)
sb_run "git show $prefix"
sb_run "git show -s --format=%s $prefix^{commit}"
sb_run "git log -1 --format=%s $prefix"
sb_run "git -c core.disambiguate=commit show -s --format=%s $prefix"
back_to_app

sb_say "--- S6c. special refs ---"
git clone -q "$SANDBOX_ROOT/server.git" "$SANDBOX_ROOT/clone"
cd "$SANDBOX_ROOT/clone"
sb_run "cd ../clone"
sb_run "git show -s --format=%s origin"
sb_run "git show -s --format=%s origin/HEAD"
sb_run "git fetch -q && git show -s --format=%s FETCH_HEAD"
back_to_app
sb_run "cd ../app"
sb_say "--- S7. parents and ancestors ---"
# The graph from Git's documentation, built with plumbing so every parent is
# exactly where the illustration puts it. Each commit is tagged with its name.
sb_fresh "$SANDBOX_ROOT/graph" >/dev/null
mk() {
	n=$1; shift
	printf '%s\n' "$n" > name.txt
	git add name.txt
	tree=$(git write-tree)
	parents=""
	for p in "$@"; do parents="$parents -p $(git rev-parse "$p")"; done
	c=$(git commit-tree "$tree" $parents -m "$n")
	git tag "$n" "$c"
	sb_tick
}
for r in G H I J E; do mk "$r"; done
mk D G H
mk F I J
mk C F
mk B D E F
mk A B C
git reset -q --hard A
sb_run "git log --graph --format=%s A"
sb_run "git show -s --format=%s A^"
sb_run "git show -s --format=%s A^2"
sb_run "git show -s --format=%s A~2"
sb_run "git show -s --format=%s B^2"
sb_run "git show -s --format=%s B^3"
sb_run "git show -s --format=%s A~3"
sb_run "git show -s --format=%s A~2^2"
sb_run "git show -s --format=%s F^"
sb_run "git show -s --format=%s F^2"
sb_run "git show -s --format=%s A^0"
sb_run "git show -s --format=%s A^ A^1 A~1"
sb_run "git show -s --format=%s A^^ A^1^1 A~2"
sb_run "git show -s --format=%s A^^^ A^1^1^1 A~3"
sb_run "git show -s --format=%s A^^2 B^2"
sb_run "git show -s --format=%s A~2^2 D^2 B^^2 A^^^2"
sb_run "git show -s --format=%s A^^3^2 B^3^2 F^2"
sb_run "git show -s --format=%s A^3"
sb_run "git show -s --format=%s A~4"
sb_run "git show A~2^2:name.txt"

sb_say "--- S8. tags and object types ---"
back_to_app
sb_run "git cat-file -t v1.0"
sb_run "git cat-file -t v1.0^{}"
sb_run "git cat-file -t v1.0^{commit}"
sb_run "git cat-file -t v1.0^0"
sb_run "git cat-file -t v1.0^{tree}"
sb_run "git cat-file -t v1.0^{tag}"
sb_run "git cat-file -t v1.0^{object}"
sb_run "git cat-file -t first-app^{object}"
sb_run "git cat-file -t first-app^{tag}"
sb_run "git cat-file -t HEAD^{blob}"
sb_run "git show -s --format=%s v1.0-approved"
sb_run "git cat-file -t v1.0-approved^{tag}"
sb_run "git cat-file -t v1.0-approved^{}"

sb_say "--- S9. by message ---"
sb_run "git show -s --format=%s ':/nasty'"
sb_run "git show -s --format=%s 'HEAD^{/nasty}'"
sb_run "git show -s --format=%s ':/^Add'"
sb_run "git show -s --format=%s 'HEAD~2^{/^Add}'"
sb_run "git show -s --format=%s ':/!-Add'"
sb_run "git show -s --format=%s ':/Nasty'"

sb_say "--- S10. paths in a commit ---"
sb_run "git show HEAD:src/app.py"
sb_run "git show HEAD~2:src/app.py"
sb_run "git show HEAD:"
sb_run "git show HEAD:src"
sb_run "git show HEAD:nosuch.txt"
sb_run "git show HEAD~3:docs/guide.md"
sb_run "git show HEAD^{tree}:README.md"
sb_run "cd src"
cd src
sb_run "git show HEAD:app.py"
sb_run "git show HEAD:./app.py"
sb_run "git show HEAD:../README.md"
sb_run "cd .."
cd ..

sb_say "--- S12. reflog, previous branch, upstream and push ---"
sb_run "git reflog -3 main"
sb_run "git reflog -3"
sb_run "git show -s --format=%s main@{1}"
sb_run "git show -s --format=%s @{1}"
sb_run "git show -s --format=%s main@{2}"
sb_run "git show -s --format=%s HEAD@{2}"
sb_run "git show -s --format=%s @{99}"
sb_run "git show -s --format=%s 'main@{3 hours ago}'"
sb_run "git show -s --format=%s 'main@{2026-01-05 10:30}'"
sb_run "git show -s --format=%s 'main@{last year}'"
sb_run "git switch idea"
sb_run "git show -s --format=%s @{-1}"
sb_run "git show -s --format=%s @{upstream}"
sb_run "git switch -"
sb_run "git show -s --format=%s @{upstream}"
sb_run "git show -s --format=%s @{u}"
sb_run "git show -s --format=%s main@{u}"
sb_run "git show -s --format=%s @{UPSTREAM}"
sb_run "git show -s --format=%s idea@{u}"
sb_run "git show -s --format=%s @{push}"
git init -q --bare "$SANDBOX_ROOT/fork.git"
git remote add fork "$SANDBOX_ROOT/fork.git"
git push -q fork idea:main
git fetch -q fork
git config push.default current
git config remote.pushDefault fork
sb_run "git config push.default"
sb_run "git config remote.pushDefault"
sb_run "git show -s --format=%s @{push}"
sb_run "git show -s --format=%s @{upstream}"
git config --unset push.default
git config --unset remote.pushDefault

sb_say "--- S6d. ORIG_HEAD ---"
sb_run "git reset --hard HEAD~1"
sb_run "git show -s --format=%s ORIG_HEAD"
sb_run "git reset --hard ORIG_HEAD"

sb_say "--- S11. the index ---"
sb_write src/app.py "print('staged')"
git add src/app.py
sb_write src/app.py "print('not staged yet')"
sb_run "git show :src/app.py"
sb_run "git show :0:src/app.py"
sb_run "git show :1:src/app.py"
sb_run "git show HEAD:src/app.py"
git reset -q --hard
# A conflict, for the other stages.
git switch -q -c polite HEAD~1
sb_write src/app.py "print('hello, world, please')"
sb_commit "Be polite"
git switch -q main
sb_run "git merge polite"
sb_run "git show :1:src/app.py"
sb_run "git show :2:src/app.py"
sb_run "git show :3:src/app.py"
sb_run "git show :src/app.py"
sb_run "git show -s --format=%s MERGE_HEAD"
sb_run "git cat-file -t AUTO_MERGE"
sb_run "git show AUTO_MERGE:src/app.py"
git merge --abort
git branch -q -D polite

sb_say "--- S13. ranges ---"
cd "$SANDBOX_ROOT/graph"
for args in "D" "D F" "^G D" "^D B" "^D B C" "C" "B..C" "B...C" "B^-" "C^@" "B^@" "C^!" "B^!" "F^! D"; do
	sb_run "git log --format=%s $args"
done
sb_run "git log --format=%s B^-2"
sb_run "git log --format=%s A^2^@"
sb_run "git log --format=%s A^@^2"

sb_say "--- S14. two dots and three dots, on two branches ---"
sb_fresh "$SANDBOX_ROOT/kitchen" >/dev/null
sb_write menu.txt "soup" "bread" "salad"
sb_commit "Start the menu"
git switch -q -c topic
sb_write menu.txt "soup" "bread" "salad" "cake"
sb_commit "Add cake"
sb_write drinks.txt "water"
sb_commit "Add drinks"
sb_write drinks.txt "water" "tea"
sb_commit "Add tea"
git switch -q main
sb_write specials.txt "fish"
sb_commit "Add specials"
git cherry-pick topic~1 >/dev/null
sb_tick
sb_write specials.txt "fish" "pie"
sb_commit "Add pie"
sb_run "git log --oneline --graph --all"
sb_run "git log --oneline main..topic"
sb_run "git log --oneline topic..main"
sb_run "git log --oneline main...topic"
sb_run "git log --oneline topic...main"
sb_run "git log --oneline topic.."
sb_run "git log --oneline ..topic"
sb_run "git log --oneline ..."
sb_run "git log --oneline .."
sb_run "git log --oneline .. --"
sb_run "git log --oneline main~2..main topic~1..topic"
sb_run "git diff --stat main..topic"
sb_run "git diff --stat main...topic"

sb_say "--- S15. the two sides ---"
sb_run "git log --oneline --left-right main...topic"
sb_run "git log --oneline --left-only main...topic"
sb_run "git log --oneline --right-only main...topic"
sb_run "git log --format='%m %h %s' --left-right main...topic"
sb_run "git log --oneline --left-right main..topic"
sb_run "git log --oneline --cherry-mark main...topic"
sb_run "git log --oneline --cherry-pick main...topic"
sb_run "git log --oneline --cherry-mark --left-right main...topic"
sb_run "git log --oneline --cherry main...topic"
sb_run "git log --oneline --cherry-pick --right-only --no-merges main...topic"
sb_run "git cherry -v main topic"
sb_run "git log --oneline --boundary main..topic"
sb_run "git log --oneline --boundary --left-right main...topic"
