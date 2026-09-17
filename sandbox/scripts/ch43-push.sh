#!/bin/bash
# Generates every transcript in Chapter 43, "push".
#
#   bash sandbox/scripts/ch43-push.sh [dir]
#
# No `set -e`: many pushes are shown being rejected, which exits with status 1
# or 128.
#
# The team's bare "server", Ada's clone, where every transcript runs, and Bob's
# clone, which pushes out of sight with `bob_push` so that Ada's pushes have
# something to be rejected by. A few more bare repositories stand for Ada's
# fork, a backup and a mirror, and one non-bare repository for a web site. All
# of them live under the sandbox root, so nothing touches a network.
#
# Hooks are shell scripts written into the server's hooks directory, as
# Chapter 67 explains; they print what they received so that the chapter can
# show it.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
SERVER="$SANDBOX_ROOT/server"

# bob_push <branch> <file> <message> <line>... : Bob brings <branch> up to
# date with the server, commits a file on it, and pushes it.
bob_push() {
	local branch="$1" file="$2" message="$3"; shift 3
	( cd "$SANDBOX_ROOT/bob" && git fetch -q origin &&
	  git switch -q -C "$branch" "origin/$branch" &&
	  sb_write "$file" "$@" && git add -A &&
	  git commit -q -m "$message" && git push -q origin "$branch" ) >/dev/null 2>&1
	sb_tick
}
# ada_commit <file> <message> <line>... : a commit in Ada's clone, not shown
ada_commit() {
	local file="$1" message="$2"; shift 2
	sb_write "$file" "$@" && git add -A && git commit -q -m "$message"
	sb_tick
}

# ---------------------------------------------------------------------------
sb_fresh "$SANDBOX_ROOT/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git init -q --bare "$SERVER/atlas.git"
git push -q "$SERVER/atlas.git" main
cd "$SANDBOX_ROOT"
rm -rf work
git clone -q server/atlas.git bob
git clone -q server/atlas.git ada
cd ada
git remote set-url origin ../server/atlas.git

sb_say "The example repository"
sb_run "git remote -v"
sb_run "git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Reading the output"
ada_commit maps/africa.txt "Add Africa" "Africa"
sb_run "git push"
sb_run "git push"
sb_run "git push -v"
git switch -q -c deserts
ada_commit deserts.txt "List deserts" "Sahara"
sb_run "git push origin deserts"
git switch -q main

sb_say "What a push changes here"
ada_commit maps/asia.txt "Add Asia" "Asia"
sb_run "git status -sb && git push -q && git status -sb && git reflog -1 origin/main"

# ---------------------------------------------------------------------------
sb_say "Which branch a plain push sends"
git switch -q -c rivers
ada_commit rivers.txt "List rivers" "Danube"
sb_run "git push; echo \"exit \$?\""
sb_run "git push -u origin rivers"
sb_run "git push"
git switch -q -c lakes
ada_commit lakes.txt "List lakes" "Baikal"
sb_run "git config set push.autoSetupRemote true && git push"
git config unset push.autoSetupRemote
git switch -q main

sb_say "push.default"
git switch -q -c maps origin/main
ada_commit maps/oceania.txt "Add Oceania" "Oceania"
sb_run "git branch -vv --list maps && git push; echo \"exit \$?\""
sb_run "git -c push.default=upstream push --dry-run"
sb_run "git -c push.default=current push --dry-run"
sb_run "git -c push.default=matching push --dry-run -v"
sb_run "git -c push.default=nothing push; echo \"exit \$?\""
git switch -q main
git branch -q -D maps

# ---------------------------------------------------------------------------
sb_say "Which remote"
git init -q --bare "$SERVER/ada-atlas.git"
git init -q --bare "$SERVER/backup.git"
git switch -q deserts
git branch -q -u origin/deserts
ada_commit deserts.txt "Add the Gobi" "Sahara" "Gobi"
sb_run "git remote add fork ../server/ada-atlas.git && git config set remote.pushDefault fork"
sb_run "git push && git status -sb"
sb_run "git rev-parse --abbrev-ref @{upstream} && git rev-parse --abbrev-ref @{push}"
sb_run "git -c push.default=current rev-parse --abbrev-ref @{push}"
sb_run "git remote add backup ../server/backup.git && git config set branch.deserts.pushRemote backup && git push"
sb_run "git push origin"
git config unset branch.deserts.pushRemote
git config unset remote.pushDefault

sb_say "Several remotes at once"
sb_run "git config set remotes.everywhere 'fork backup' && git push everywhere deserts main"
sb_run "git push --atomic everywhere deserts; echo \"exit \$?\""
ada_commit deserts.txt "Add the Atacama" "Sahara" "Gobi" "Atacama"
sb_run "git push --repo=fork && git push --repo=fork deserts; echo \"exit \$?\""
git switch -q main

# ---------------------------------------------------------------------------
sb_say "Naming what to push"
ada_commit maps/americas.txt "Add the Americas" "Americas"
sb_run "git push origin HEAD"
sb_run "git push origin main:review"
sb_run "git push origin main~1:refs/heads/before-americas"
sb_run "git push origin main~1:snapshot; echo \"exit \$?\""
sb_run "git push origin nosuch; echo \"exit \$?\""
git branch -q mountains main~2
sb_run "git push --all origin"
sb_run "git ls-remote --branches origin"

sb_say "Detached HEAD"
git switch -q --detach main~1
sb_run "git push; echo \"exit \$?\""
sb_run "git push origin HEAD; echo \"exit \$?\""
sb_run "git push origin HEAD:refs/heads/experiment"
git switch -q main

# ---------------------------------------------------------------------------
sb_say "Tags"
sb_run "git tag -a v1.0 -m 'First edition' && git tag draft && git push --follow-tags"
sb_run "git push origin draft"
sb_run "git tag v1.1-rc && git push origin tag v1.1-rc"
ada_commit maps/arctic.txt "Add the Arctic" "Arctic"
git tag -a v1.1 -m "Second edition"
git tag checked
sb_run "git push --tags"
ada_commit maps/islands.txt "Add islands" "Islands"
git tag -a v1.2 -m "Third edition"
sb_run "git config set push.followTags true && git push"
git config unset push.followTags
sb_run "git push --all --tags origin; echo \"exit \$?\""

sb_say "A tag that moved"
sb_run "git tag -f draft HEAD~1 && git push origin draft; echo \"exit \$?\""
sb_run "git push origin +draft"

# ---------------------------------------------------------------------------
sb_say "Deleting and renaming on the server"
sb_run "git push origin --delete before-americas experiment"
sb_run "git push origin :review"
sb_run "git push origin --delete draft checked"
sb_run "git push origin --delete v1.1-rc nosuch; echo \"exit \$?\"; git ls-remote --tags origin v1.1-rc"
sb_run "git push --delete origin; echo \"exit \$?\""
sb_run "git push --delete origin main:main; echo \"exit \$?\""

sb_say "Renaming a branch on the server"
sb_run "git branch -m lakes seas && git push -u origin seas && git push origin --delete lakes"
sb_run "git branch -vv --list seas"

# ---------------------------------------------------------------------------
sb_say "Rejected pushes"
bob_push main maps/antarctica.txt "Add Antarctica" "Antarctica"
ada_commit notes.txt "Write a note" "Check the borders"
sb_run "git push; echo \"exit \$?\""
sb_run "git fetch && git push; echo \"exit \$?\""
sb_run "git pull -q --rebase && git push"

sb_say "Several branches in one push"
bob_push rivers rivers.txt "Add the Nile" "Danube" "Nile"
ada_commit notes.txt "Write another note" "Check the borders" "Check the rivers"
git switch -q rivers
ada_commit rivers.txt "Add the Rhine" "Danube" "Rhine"
git switch -q main
sb_run "git push origin main rivers; echo \"exit \$?\""
ada_commit notes.txt "Write a third note" "Check the borders" "Check the rivers" "Check the seas"
sb_run "git push --atomic origin main rivers; echo \"exit \$?\""
sb_run "git ls-remote origin main && git rev-parse main origin/main"
git fetch -q
git switch -q rivers
git reset -q --hard origin/rivers
git switch -q main
git push -q origin main

# ---------------------------------------------------------------------------
sb_say "Forcing a push"
git switch -q -c drafts
ada_commit drafts.txt "Draft an idea" "An idea"
git push -q -u origin drafts
sb_run "git commit -q --amend -m 'Draft a better idea' && git push; echo \"exit \$?\""
sb_tick
sb_run "git push --force"
sb_run "git commit -q --amend -m 'Draft the best idea' && git push origin +drafts"
sb_tick

sb_say "A lease"
bob_push drafts drafts-bob.txt "Comment on the idea" "Looks good"
sb_run "git commit -q --amend -m 'Draft the final idea' && git push --force-with-lease; echo \"exit \$?\""
sb_tick
sb_run "git fetch && git push --force-with-lease --dry-run"
sb_run "git push --force-with-lease --force-if-includes; echo \"exit \$?\""
sb_run "git -c push.useForceIfIncludes=true push --force-with-lease; echo \"exit \$?\""
sb_run "git log --oneline drafts..origin/drafts"
sb_run "git push --force-with-lease=drafts:\$(git rev-parse origin/drafts~1) --dry-run; echo \"exit \$?\""
sb_run "git push --force-with-lease=drafts:origin/drafts --dry-run"
sb_run "git push --force-with-lease --no-force-with-lease --dry-run; echo \"exit \$?\""
sb_run "git push --force-with-lease=ideas: origin drafts:ideas && git push --force-with-lease=ideas: origin main:ideas; echo \"exit \$?\""
git reset -q --hard origin/drafts
git switch -q main

# ---------------------------------------------------------------------------
sb_say "Mirrors and pruning"
git init -q --bare "$SERVER/mirror.git"
sb_run "git push --mirror ../server/mirror.git"
sb_run "git branch -D mountains && git push --mirror ../server/mirror.git"
sb_run "git push --mirror ../server/mirror.git main; echo \"exit \$?\""
git push -q backup main:old-backup-branch
sb_run "git ls-remote --branches backup && git push --prune backup 'refs/heads/*:refs/heads/*'"

# ---------------------------------------------------------------------------
sb_say "Pushing to a repository with a working tree"
( cd "$SANDBOX_ROOT" && git init -q website && cd website &&
  sb_write index.html "<h1>Atlas</h1>" && git add -A && git commit -q -m "Start the site" )
sb_tick
( cd "$SANDBOX_ROOT" && git clone -q website site-work )
cd "$SANDBOX_ROOT/site-work"
ada_commit index.html "Add a subtitle" "<h1>Atlas</h1>" "<p>Maps of the world</p>"
sb_run "git push; echo \"exit \$?\""
sb_run "git -C ../website config set receive.denyCurrentBranch updateInstead && git push && cat ../website/index.html"
ada_commit index.html "Add a footer" "<h1>Atlas</h1>" "<p>Maps of the world</p>" "<footer>2026</footer>"
echo "<!-- edited on the server -->" >> ../website/index.html
sb_run "git push; echo \"exit \$?\""
cd "$SANDBOX_ROOT/ada"

sb_say "Rules the server sets"
ada_commit notes.txt "Rewrite the notes" "Check everything"
git push -q origin main
sb_run "git -C ../server/atlas.git config set receive.denyNonFastForwards true && git push --force origin main~1:main; echo \"exit \$?\""
git -C ../server/atlas.git config unset receive.denyNonFastForwards
sb_run "git -C ../server/atlas.git config set receive.denyDeletes true && git push origin --delete seas; echo \"exit \$?\""
sb_run "git push origin --delete v1.1-rc"
git -C ../server/atlas.git config unset receive.denyDeletes

sb_say "Hooks on the server"
cat > ../server/atlas.git/hooks/pre-receive <<'HOOK'
#!/bin/sh
# Reject any branch whose name starts with wip-.
while read old new ref
do
	echo "Checking $ref"
	case "$ref" in
	refs/heads/wip-*) echo "Branches named wip-* stay on your own machine."; exit 1 ;;
	esac
done
i=0
while test "$i" -lt "${GIT_PUSH_OPTION_COUNT:-0}"
do
	eval "echo \"Push option: \$GIT_PUSH_OPTION_$i\""
	i=$((i + 1))
done
HOOK
chmod +x ../server/atlas.git/hooks/pre-receive
ada_commit maps/volcanoes.txt "Map the volcanoes" "Etna"
git branch -q wip-volcanoes
sb_run "git push origin main wip-volcanoes; echo \"exit \$?\""
sb_run "git ls-remote origin main && git rev-parse main"

sb_say "Push options"
sb_run "git push -o ci.skip origin main; echo \"exit \$?\""
sb_run "git -C ../server/atlas.git config set receive.advertisePushOptions true && git push -o ci.skip -o reviewer=bob origin main"
ada_commit maps/caves.txt "Map the caves" "Lascaux"
sb_run "git config set push.pushOption ci.skip && git push"
git config unset push.pushOption
rm ../server/atlas.git/hooks/pre-receive
git branch -q -D wip-volcanoes

# ---------------------------------------------------------------------------
sb_say "The pre-push hook"
cat > .git/hooks/pre-push <<'HOOK'
#!/bin/sh
echo "pre-push: remote $1, url $2"
while read local_ref local_oid remote_ref remote_oid
do
	echo "pre-push: $local_ref -> $remote_ref"
done
echo "pre-push: refusing, as a test"
exit 1
HOOK
chmod +x .git/hooks/pre-push
ada_commit maps/forests.txt "Map the forests" "Taiga"
sb_run "git push; echo \"exit \$?\""
sb_run "git push --no-verify"
rm .git/hooks/pre-push

# ---------------------------------------------------------------------------
sb_say "Dry runs and output for scripts"
ada_commit maps/deserts.txt "Map the deserts" "Sahara"
sb_run "git push --dry-run && git ls-remote origin main && git rev-parse origin/main"
sb_run "git push --porcelain"
sb_run "git push --porcelain -v"
bob_push main maps/glaciers.txt "Map the glaciers" "Aletsch"
ada_commit maps/lakes.txt "Map the lakes" "Baikal"
sb_run "git push --porcelain; echo \"exit \$?\""
sb_run "git pull -q --rebase && git push -q; echo \"exit \$?\""
ada_commit maps/seas.txt "Map the seas" "Caspian"
sb_run "git push --progress 2>&1 | tr '\r' '\n' | grep -E '^(Enumerating|Counting|Compressing).*done|^Total|->'"

# ---------------------------------------------------------------------------
sb_say "Publishing a new repository"
cd "$SANDBOX_ROOT"
git init -q gazetteer
cd gazetteer
sb_run "git init -q --bare ../server/gazetteer.git"
sb_run "git remote add origin ../server/gazetteer.git && git push -u origin main; echo \"exit \$?\""
ada_commit places.txt "Start the gazetteer" "Paris"
sb_run "git push -u origin main"
sb_run "git clone -q ../server/gazetteer.git ../gazetteer-copy && git -C ../gazetteer-copy log --oneline"
cd "$SANDBOX_ROOT/ada"

# ---------------------------------------------------------------------------
sb_say "The conversation"
ada_commit maps/rivers.txt "Map the rivers" "Nile"
sb_run "GIT_TRACE_PACKET=1 git push 2>&1 | grep -o 'push[<>].*'"
ada_commit maps/mountains.txt "Map the mountains" "Alps"
sb_run "GIT_TRACE_PACKET=1 git -c push.negotiate=true push 2>&1 | grep -o 'fetch> have.*\|fetch< ACK.*\|push> [0-9a-f]* [0-9a-f]* refs/heads/main'"

sb_say "Thin packs"
index_lines() { # <n> : the lines of a map index with <n> entries
	for i in $(seq 1 "$1"); do printf 'Map %02d of the atlas, with its title and its scale\n' "$i"; done
}
index_lines 40 > maps/index.txt
git add -A && git commit -q -m "Index the maps" && sb_tick
git push -q
git clone -q --bare ../server/atlas.git ../server/copy1.git
git clone -q --bare ../server/atlas.git ../server/copy2.git
index_lines 41 > maps/index.txt
git add -A && git commit -q -m "Index one more map" && sb_tick
sb_run "git push --progress ../server/copy1.git main 2>&1 | tr '\r' '\n' | grep -E 'Total|->'"
sb_run "git push --progress --no-thin ../server/copy2.git main 2>&1 | tr '\r' '\n' | grep -E 'Total|->'"

sb_say "The program on the other end"
ada_commit maps/plains.txt "Map the plains" "Pampas"
sb_run "git push --receive-pack=git-receive-pack"
sb_run "git push --exec=no-such-program; echo \"exit \$?\""
