#!/bin/bash
# Generates every transcript in Chapter 39, "remote".
#
#   bash sandbox/scripts/ch39-remote.sh [dir]
#
# No `set -e`: many commands are shown failing on purpose, and `git remote`
# answers a missing remote with exit status 2.
#
# Every "server" is a bare repository under $SANDBOX_ROOT/server, so nothing
# here touches a network. Commits made in the server-side work repository and
# in Ada's clone share the sandbox clock, so the order of the setup below is
# what keeps the hashes stable.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
SERVER="$SANDBOX_ROOT/server"

# ---------------------------------------------------------------------------
# The team's atlas, built in a work repository and pushed to two bare
# repositories: the team's own, and Ada's fork of it, copied before Bob added
# Africa and the deserts branch. Bob's fork gets a branch of its own.
sb_fresh "$SANDBOX_ROOT/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git tag -a v1.0 -m "First edition"
git switch -q -c rivers
sb_write rivers.txt "Danube"
sb_commit "List rivers"
git switch -q main
git init -q --bare "$SERVER/atlas.git"
git push -q "$SERVER/atlas.git" main rivers v1.0
git clone -q --bare "$SERVER/atlas.git" "$SERVER/ada-atlas.git"

sb_write maps/africa.txt "Africa"
sb_commit "Add Africa"
git switch -q -c deserts
sb_write deserts.txt "Sahara"
sb_commit "List deserts"
git switch -q main
git tag v1.1-rc main
git push -q "$SERVER/atlas.git" main deserts v1.1-rc

git clone -q --bare "$SERVER/atlas.git" "$SERVER/bob-atlas.git"
git switch -q -c mountains
sb_write mountains.txt "Alps"
sb_commit "List mountains"
git switch -q main
git push -q "$SERVER/bob-atlas.git" mountains
for r in backup copy1 copy2; do git init -q --bare "$SERVER/$r.git"; done

cd "$SANDBOX_ROOT"
git clone -q "$SERVER/ada-atlas.git" atlas
cd atlas

sb_say "The example repository"
sb_run "git log --oneline --decorate --all"
sb_run "git -C $SERVER/atlas.git log --oneline --decorate --all"

# ---------------------------------------------------------------------------
sb_say "Listing remotes"
sb_run "git remote"
sb_run "git remote -v"
sb_run "git remote show -v"
( cd "$SANDBOX_ROOT" && git init -q empty )
sb_run "git -C $SANDBOX_ROOT/empty remote"
cd "$SANDBOX_ROOT"
sb_run "git remote"
cd atlas
git clone -q --filter=blob:none "file://$SERVER/atlas.git" "$SANDBOX_ROOT/partial" 2>/dev/null
sb_run "git -C $SANDBOX_ROOT/partial remote -v"

# ---------------------------------------------------------------------------
sb_say "Adding a remote"
sb_run "git remote add bob $SERVER/bob-atlas.git"
sb_run "git remote -v"
sb_run "git config get --all --show-names --regexp '^remote\.bob'"
sb_run "git branch -r"

sb_say "Fetching straight away"
sb_run "git remote add -f upstream $SERVER/atlas.git"
sb_run "git branch -r"

sb_say "Names Git refuses"
sb_run "git remote add upstream $SERVER/elsewhere.git; echo \"exit \$?\""
sb_run "git remote add 'the team' $SERVER/atlas.git; echo \"exit \$?\""
sb_run "git remote add upstream/old $SERVER/atlas.git; echo \"exit \$?\""
sb_run "git remote add team/eu $SERVER/atlas.git && git remote add team $SERVER/atlas.git; echo \"exit \$?\""
git remote remove team/eu

sb_say "An address that does not work"
sb_run "git remote add typo $SERVER/atlass.git; echo \"exit \$?\""
sb_run "git remote add -f typo2 $SERVER/atlass.git; echo \"exit \$?\""
sb_run "git remote"
git remote remove typo
git remote remove typo2

sb_say "Relative paths"
sb_run "cd maps"
cd maps
sb_run "git remote add here ../../server/atlas.git"
sb_run "git ls-remote here main"
sb_run "git remote set-url here ../server/atlas.git"
sb_run "git ls-remote here main"
sb_run "cd .."
cd ..
sb_run "git ls-remote here main"
git remote remove here

sb_say "Tracking only some branches"
sb_run "git remote add -t main -t deserts -m main selected $SERVER/atlas.git"
sb_run "git config get --all --show-names --regexp '^remote\.selected'"
sb_run "git remote update selected && git branch -r --list 'selected/*'"
git remote set-head selected -d
git remote remove selected

sb_say "Tags"
sb_run "git remote add --no-tags notags $SERVER/atlas.git && git remote add --tags alltags $SERVER/atlas.git"
sb_run "git config get --all --show-names --regexp '^remote\.(notags|alltags)\.tagopt'"
git remote remove notags >/dev/null 2>&1
git remote remove alltags >/dev/null 2>&1

sb_say "Mirrors"
cd "$SANDBOX_ROOT"
sb_run "git init -q --bare mirror.git && git -C mirror.git remote add --mirror=fetch origin $SERVER/atlas.git"
sb_run "git -C mirror.git config get --all --show-names --regexp '^remote\.'"
sb_run "git -C mirror.git remote update"
sb_run "git -C mirror.git branch"
cd atlas
sb_run "git remote add --mirror=fetch copy $SERVER/atlas.git && git remote update copy"
sb_run "git remote remove copy"
sb_run "git remote add --mirror=push backup $SERVER/backup.git"
sb_run "git config get --all --show-names --regexp '^remote\.backup'"
sb_run "git push backup"
sb_run "git remote add --mirror old-style $SERVER/backup.git"
sb_run "git config get --all --show-names --regexp '^remote\.old-style'"
sb_run "git remote add --mirror=both both $SERVER/backup.git"
sb_run "git remote add --mirror=push -m main m1 $SERVER/backup.git"
sb_run "git remote add --mirror=push -t main m2 $SERVER/backup.git"
git remote remove backup >/dev/null 2>&1
git remote remove old-style >/dev/null 2>&1

# ---------------------------------------------------------------------------
sb_say "Renaming a remote"
sb_run "git switch -q -c deserts upstream/deserts && git config set remote.pushDefault upstream"
sb_run "git branch -vv"
sb_run "git remote rename upstream team"
sb_run "git branch -vv"
sb_run "git branch -r"
sb_run "git config get --all --show-names --regexp '^(remote|branch)\.'"
sb_run "git reflog show team/main"
sb_run "git remote rename nosuch other; echo \"exit \$?\""
sb_run "git remote rename team bob; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Removing a remote"
sb_run "git remote remove team"
sb_run "git branch -vv"
sb_run "git branch -r"
sb_run "git config get --all --show-names --regexp '^(remote|branch)\.'"
sb_run "git status -sb"
sb_run "git log --oneline -1 deserts"
sb_run "git remote rm bob && git remote"
sb_run "git remote remove bob; echo \"exit \$?\""
sb_run "git remote remove origin upstream"
sb_run "git switch -q main && git branch -q -D deserts"
sb_run "git remote add -f upstream $SERVER/atlas.git"

sb_say "Removing a remote that tracks only some branches"
sb_run "git remote add -t main selected $SERVER/atlas.git && git remote update selected"
sb_run "git remote remove selected && git branch -r --list 'selected/*'"
sb_run "git symbolic-ref refs/remotes/selected/HEAD"

sb_say "A rename that stops halfway"
sb_run "git remote rename upstream selected"
sb_run "git config get --all --show-names --regexp '^remote\.'"
sb_run "git symbolic-ref --delete refs/remotes/selected/HEAD"
sb_run "git config rename-section remote.selected remote.upstream"
sb_run "git remote rename upstream selected && git remote rename selected upstream"
sb_run "git remote -v && git branch -r --list 'upstream/*'"

# ---------------------------------------------------------------------------
sb_say "The remote's default branch"
sb_run "git branch -r --list 'origin/*'"
sb_run "git log --oneline -1 origin"
sb_run "git remote set-head origin rivers && git log --oneline -1 origin"
sb_run "git remote set-head origin -a"
sb_run "git remote set-head origin -a"
sb_run "git remote set-head origin --delete && git branch -r --list 'origin/*'"
sb_run "git log --oneline -1 origin"
sb_run "git remote set-head origin --auto"
sb_run "git remote set-head origin lakes"
sb_run "git remote set-head origin"

# ---------------------------------------------------------------------------
sb_say "Choosing which branches to fetch"
sb_run "git remote set-branches upstream main"
sb_run "git config get --all --show-names --regexp '^remote\.upstream\.fetch'"
sb_run "git remote set-branches --add upstream 'des*'"
sb_run "git config get --all --show-names --regexp '^remote\.upstream\.fetch'"
sb_run "git branch -r --list 'upstream/*'"
sb_run "git remote show upstream"

sb_say "When set-branches does nothing"
sb_run "git remote set-branches upstream"
sb_run "git config get --all --show-names --regexp '^remote\.upstream'"
sb_run "git remote set-branches upstream '*'; echo \"exit \$?\""
sb_run "git config get --all --show-names --regexp '^remote\.upstream'"
sb_run "git remote set-branches --add upstream '*'"
sb_run "git config get --all --show-names --regexp '^remote\.upstream'"

# ---------------------------------------------------------------------------
sb_say "Reading a URL"
sb_run "git remote get-url origin"
sb_run "git remote get-url --push origin"
sb_run "git remote get-url nosuch; echo \"exit \$?\""

sb_say "Changing a URL"
sb_run "git remote add publish $SERVER/copy.git"
sb_run "git remote set-url publish $SERVER/copy1.git"
sb_run "git remote -v | grep publish"
sb_run "git remote set-url publish $SERVER/copy2.git copy9"
sb_run "git remote set-url publish $SERVER/copy2.git 'copy[0-9]'"
sb_run "git remote get-url publish"
sb_run "git remote set-url publish $SERVER/copy1.git"

sb_say "Pushing somewhere else"
sb_run "git remote set-url --push publish $SERVER/copy2.git"
sb_run "git remote -v | grep publish"
sb_run "git config get --all --show-names --regexp '^remote\.publish\.'"
sb_run "git remote set-url --delete --push publish copy2"
sb_run "git remote -v | grep publish"

sb_say "Several URLs"
sb_run "git remote set-url --add publish $SERVER/copy2.git"
sb_run "git remote -v | grep publish"
sb_run "git remote get-url publish && git remote get-url --all publish"
sb_run "git push publish main"
sb_run "git -C $SERVER/copy1.git log --oneline -1 && git -C $SERVER/copy2.git log --oneline -1"
sb_run "git remote set-url --add --push publish $SERVER/backup.git"
sb_run "git remote -v | grep publish"

sb_say "Deleting URLs"
sb_run "git remote set-url --delete publish copy1"
sb_run "git remote -v | grep publish"
sb_run "git remote set-url --delete publish copy2"
sb_run "git remote set-url --delete publish nothing-like-it"
sb_run "git remote remove publish"

sb_say "Rewriting URLs"
sb_run "git config set url.$SERVER/.insteadOf team:"
sb_run "git remote add team team:atlas.git"
sb_run "git remote -v | grep team"
sb_run "git config get remote.team.url && git remote get-url team"
sb_run "git config set url.$SERVER/backup/.pushInsteadOf team:"
sb_run "git remote -v | grep team"
git remote remove team >/dev/null 2>&1
git config unset "url.$SERVER/.insteadOf"
git config unset "url.$SERVER/backup/.pushInsteadOf"

# ---------------------------------------------------------------------------
# Since the clone: on Ada's fork, a branch "lakes" with a commit of its own was
# pushed from another computer, and "rivers" was deleted. Ada has a local
# rivers branch and an unpushed commit on main.
( cd "$SANDBOX_ROOT/work" &&
  git switch -q -c lakes main~1 &&
  sb_write lakes.txt "Baikal" && sb_commit "List lakes" >/dev/null &&
  git push -q "$SERVER/ada-atlas.git" lakes &&
  git switch -q main ) 
sb_tick
git -C "$SERVER/ada-atlas.git" branch -D rivers >/dev/null
git switch -q -c rivers --track origin/rivers >/dev/null
git switch -q main
sb_write maps/asia.txt "Asia"
sb_commit "Add Asia" >/dev/null

sb_say "Inspecting a remote"
sb_run "git branch -vv"
sb_run "git remote show origin"
sb_run "git remote show upstream"
sb_run "git config set --append remote.upstream.fetch '^refs/heads/rivers' && git remote show upstream | sed -n '/Remote branches/,/rivers/p'"
git config unset --fixed-value --value='^refs/heads/rivers' remote.upstream.fetch

sb_say "Without asking the server"
sb_run "git remote show -n origin"

sb_say "Pull and push lines"
sb_run "git config set branch.rivers.rebase true && git config set remote.origin.push refs/heads/main:refs/heads/published"
sb_run "git remote show origin | sed -n '/git pull/,\$p'"
git config unset branch.rivers.rebase
git config unset remote.origin.push

sb_say "A remote that cannot be reached"
sb_run "git remote add gone $SERVER/gone.git && git remote show gone"
sb_run "git remote show -n gone"
git remote remove gone
sb_run "git remote show $SERVER/atlas.git"

# ---------------------------------------------------------------------------
sb_say "git ls-remote"
sb_run "git ls-remote upstream"

sb_say "Only branches or only tags"
sb_run "git ls-remote --branches upstream"
sb_run "git ls-remote --tags upstream"
sb_run "git ls-remote --tags --refs upstream"
sb_run "git ls-remote -b -t --refs upstream"
sb_run "git ls-remote --heads upstream"
sb_run "git ls-remote -h"

sb_say "Patterns"
sb_run "git ls-remote upstream main"
sb_run "git ls-remote upstream 'v*'"
sb_run "git ls-remote upstream ain"
sb_run "git ls-remote upstream heads/main rivers"

sb_say "Symbolic refs"
sb_run "git ls-remote --symref upstream HEAD"

sb_say "Exit status"
sb_run "git ls-remote upstream nosuch; echo \"exit \$?\""
sb_run "git ls-remote --exit-code upstream nosuch; echo \"exit \$?\""
sb_run "git ls-remote --exit-code upstream main >/dev/null; echo \"exit \$?\""
sb_run "git ls-remote --exit-code $SERVER/gone.git; echo \"exit \$?\""

sb_say "Sorting"
sb_run "git ls-remote --tags --sort=-version:refname upstream"
sb_run "git ls-remote --branches --sort=committerdate origin"
sb_run "git fetch -q origin && git ls-remote --branches --sort=committerdate origin"

sb_say "Without a remote name"
sb_run "git ls-remote --branches"
sb_run "git ls-remote --branches 2>/dev/null"
sb_run "git ls-remote -q --branches"
cd "$SANDBOX_ROOT/empty"
sb_run "git remote add team $SERVER/atlas.git && git ls-remote --branches"
sb_run "git remote add second $SERVER/bob-atlas.git && git ls-remote --branches"
cd "$SANDBOX_ROOT"
sb_run "git ls-remote --branches server/atlas.git"
sb_run "git ls-remote"
cd atlas
sb_run "git ls-remote --get-url"
sb_run "git ls-remote --get-url upstream"
sb_run "git ls-remote --get-url nosuch"

sb_say "The program on the other end"
sb_run "git ls-remote --upload-pack=git-upload-pack --branches upstream"
sb_run "git ls-remote -o region=eu --branches upstream"

# ---------------------------------------------------------------------------
sb_say "Removing stale remote-tracking branches"
sb_run "git remote prune --dry-run origin"
sb_run "git remote prune origin"
sb_run "git remote prune origin"
sb_run "git branch -vv"

sb_say "Branches you stopped fetching"
sb_run "git remote set-branches upstream main"
sb_run "git remote prune -n upstream"
sb_run "git branch -r --list 'upstream/*'"
sb_run "git branch -d -r upstream/deserts"
sb_run "git remote set-branches upstream '*'"

# ---------------------------------------------------------------------------
sb_say "Fetching from several remotes"
# Meanwhile on the team's server: Bob adds the Americas, and rivers is deleted.
( cd "$SANDBOX_ROOT/work" &&
  sb_write maps/americas.txt "Americas" && sb_commit "Add the Americas" >/dev/null &&
  git push -q "$SERVER/atlas.git" main &&
  git push -q "$SERVER/atlas.git" --delete rivers )
sb_tick
sb_run "git remote update"
sb_run "git remote -v update"
sb_run "git remote update --prune"
sb_run "git config set remotes.team 'upstream' && git remote update team"
sb_run "git config set remote.upstream.skipFetchAll true && git remote -v update"
sb_run "git config set remotes.default 'origin upstream' && git remote update"
sb_run "git remote update nosuch"
git config unset remote.upstream.skipFetchAll
git config unset remotes.default
git config unset remotes.team

# ---------------------------------------------------------------------------
sb_say "Remotes defined in files"
mkdir -p .git/remotes .git/branches
printf 'URL: %s\nPull: refs/heads/main:refs/remotes/old/main\n' "$SERVER/atlas.git" > .git/remotes/old
printf '%s#deserts\n' "$SERVER/atlas.git" > .git/branches/older
sb_run "cat .git/remotes/old"
sb_run "cat .git/branches/older"
sb_run "git remote"
sb_run "git fetch old"
sb_run "git remote rename old old"
sb_run "ls .git/remotes && git config get --all --show-names --regexp '^remote\.old\.'"
sb_run "git remote rename older older 2>/dev/null && git config get --all --show-names --regexp '^remote\.older\.'"
git remote remove old
git remote remove older >/dev/null 2>&1
git branch -q -D older 2>/dev/null

# ---------------------------------------------------------------------------
sb_say "Exit status"
sb_run "for sub in 'get-url nosuch' 'set-url nosuch /srv/x.git' 'set-branches nosuch main' 'rename nosuch x' 'remove nosuch' 'set-head nosuch -d' 'prune nosuch' 'show nosuch'; do git remote \$sub >/dev/null 2>&1; echo \"\$? git remote \$sub\"; done"

# ---------------------------------------------------------------------------
sb_say "remote and its neighbours"
sb_run "git config set remote.bob.url $SERVER/bob-atlas.git && git config set remote.bob.fetch '+refs/heads/*:refs/remotes/bob/*'"
sb_run "git remote -v | grep bob"
sb_run "git remote update bob && git branch -r --list 'bob/*'"
