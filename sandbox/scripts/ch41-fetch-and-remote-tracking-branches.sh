#!/bin/bash
# Generates every transcript in Chapter 41, "fetch and Remote-Tracking Branches".
#
#   bash sandbox/scripts/ch41-fetch-and-remote-tracking-branches.sh [dir]
#
# No `set -e`: several commands are shown being refused.
#
# Three repositories: the team's bare "server", Bob's clone, which pushes the
# changes Ada then fetches, and Ada's clone, where every transcript runs. Bob's
# work is done out of sight with the `bob` function; the chapter says what he
# did before each fetch that shows it. Both clones commit on the one sandbox
# clock, so the order below is what keeps the hashes stable.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
SERVER="$SANDBOX_ROOT/server/atlas.git"

bob() { ( cd "$SANDBOX_ROOT/bob" && eval "$@" ) >/dev/null 2>&1; }
bob_commit() { # <file> <line> <message>
	( cd "$SANDBOX_ROOT/bob" && sb_write "$1" "$2" && git add -A && git commit -q -m "$3" )
	sb_tick
}

# ---------------------------------------------------------------------------
sb_fresh "$SANDBOX_ROOT/bob" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git tag -a v1.0 -m "First edition"
git switch -q -c rivers
sb_write rivers.txt "Danube"
sb_commit "List rivers"
git switch -q -c drafts main
sb_write drafts.txt "An idea"
sb_commit "Draft an idea"
git switch -q main
git init -q --bare "$SERVER"
git remote add origin "$SERVER"
git push -q origin main rivers drafts v1.0
git branch -q -u origin/main

cd "$SANDBOX_ROOT"
git clone -q "$SERVER" ada
cd ada

sb_say "The example repository"
sb_run "git log --oneline --graph --all --decorate"

# Bob: a commit on main, a new branch, a rewritten drafts, rivers deleted,
# a new tag on main, and v1.0 moved to the new commit.
bob_commit maps/africa.txt "Africa" "Add Africa"
bob "git push -q origin main"
bob "git switch -q -c deserts"
bob_commit deserts.txt "Sahara" "List deserts"
bob "git push -q origin deserts"
bob "git switch -q drafts && git commit -q --amend -m 'Draft a better idea'"; sb_tick
bob "git push -q -f origin drafts && git push -q origin --delete rivers"
bob "git switch -q main && git tag v1.1 && git push -q origin v1.1"
bob "git tag -f -a v1.0 -m 'First edition, corrected' && git push -q -f origin v1.0"

sb_run "git ls-remote origin"

# ---------------------------------------------------------------------------
sb_say "Reading the output"
sb_run "git fetch"
sb_run "git fetch"
sb_run "git fetch -v"
sb_run "git fetch --prune"
sb_run "git fetch --tags"
sb_run "git fetch --tags --force"

# ---------------------------------------------------------------------------
sb_say "Remote-tracking branches"
sb_run "git branch -r"
sb_run "git for-each-ref --format='%(refname)' refs/remotes"
sb_run "git log --oneline main..origin/main"
sb_run "git status -sb"
sb_run "git reflog show origin/drafts"
sb_run "git switch origin/drafts"
sb_run "git switch -q --detach origin/drafts && git status | head -1 && git switch -q main"

sb_say "Deleting one"
sb_run "git branch -d -r origin/deserts && git fetch"

# ---------------------------------------------------------------------------
sb_say "What fetch does not change"
bob_commit maps/asia.txt "Asia" "Add Asia"
bob "git push -q origin main"
sb_run "git log --oneline -1 main && git status --short && git fetch && git log --oneline -1 main && git status -sb"

sb_say "A dry run"
bob_commit maps/americas.txt "Americas" "Add the Americas"
bob "git push -q origin main"
sb_run "git count-objects && git fetch --dry-run && git count-objects && git log --oneline -1 origin/main"
sb_run "git fetch"

# ---------------------------------------------------------------------------
sb_say "Which remote"
git init -q --bare "$SANDBOX_ROOT/server/bob-atlas.git"
bob "git push -q $SANDBOX_ROOT/server/bob-atlas.git drafts:mountains"
sb_run "git remote add bob $SANDBOX_ROOT/server/bob-atlas.git"
sb_run "git fetch bob && git switch -q -c mountains bob/mountains"
sb_run "git fetch -v"
sb_run "git switch -q main && git fetch -v"
sb_run "git fetch origin bob"
sb_run "git fetch --multiple origin bob"
sb_run "git fetch --all"
sb_run "git -c remotes.everyone='origin bob' fetch everyone"
sb_run "git -c fetch.all=true fetch"
sb_run "git -c fetch.all=true fetch --no-all"
( cd "$SANDBOX_ROOT" && git init -q lonely )
sb_run "git -C $SANDBOX_ROOT/lonely fetch; echo \"exit \$?\""

sb_say "Fetching from a URL"
sb_run "git fetch $SERVER deserts"
sb_run "git log --oneline -1 FETCH_HEAD"

# ---------------------------------------------------------------------------
sb_say "Fetching particular branches"
bob_commit maps/oceania.txt "Oceania" "Add Oceania"
bob "git push -q origin main"
sb_run "git fetch origin main"
sb_run "git fetch origin nosuch"
sb_run "git fetch origin deserts:deserts && git branch -v --list deserts"

sb_say "Into a local branch"
bob "git switch -q deserts"
bob_commit deserts.txt "Sahara, Gobi" "Add the Gobi"
bob "git push -q origin deserts"
sb_run "git fetch origin deserts:deserts"
sb_run "git fetch origin drafts:deserts"
sb_run "git fetch origin +drafts:deserts"
sb_run "git fetch origin deserts:deserts"
sb_run "git switch -q deserts && git fetch origin +deserts:deserts"
sb_run "git fetch -u origin +deserts:deserts && git status --short"
sb_run "git reset -q --hard && git status --short && git log --oneline -1"
git switch -q main
git branch -q -D deserts

sb_say "A commit"
sb_run "git fetch origin \$(git rev-parse --short origin/main~1)"
sb_run "git fetch origin $(git rev-parse origin/main~1)"

sb_say "Choosing where copies go"
sb_run "git fetch --refmap= origin drafts"
sb_run "git fetch --refmap='+refs/heads/*:refs/remotes/snapshot/*' origin drafts && git branch -r --list 'snapshot/*'"
sb_run "printf 'main\ndrafts\n' | git fetch --stdin origin"
git branch -q -d -r snapshot/drafts

sb_say "Setting the upstream while fetching"
sb_run "git switch -q -c solo && git fetch --set-upstream origin deserts && git branch -vv --list solo"
git switch -q main
git branch -q -D solo

# ---------------------------------------------------------------------------
sb_say "FETCH_HEAD"
sb_run "git fetch && cat .git/FETCH_HEAD"
sb_run "git fetch origin deserts && git fetch --append origin drafts && cat .git/FETCH_HEAD"
sb_run "git fetch --no-write-fetch-head origin main && cat .git/FETCH_HEAD"
sb_run "git log --oneline -2 FETCH_HEAD"

# ---------------------------------------------------------------------------
sb_say "Tags"
bob "git switch -q --orphan notes && rm -f *.txt && rm -rf maps README.md drafts.txt deserts.txt"
bob_commit notes.txt "Notes" "Start separate notes"
bob "git tag notes-1 && git push -q origin notes-1 && git switch -q -f main && git branch -q -D notes"
bob "git tag -a v1.2 -m 'Second edition' main && git push -q origin v1.2"
sb_run "git ls-remote --tags origin"
sb_run "git fetch && git tag"
sb_run "git fetch --tags && git tag"
sb_run "git tag -d v1.2 notes-1 && git fetch --no-tags && git tag"
sb_run "git fetch origin tag v1.2 && git tag"
sb_run "git config set remote.origin.tagOpt --no-tags && git tag -d v1.2 && git fetch && git tag"
sb_run "git fetch --tags"
git config unset remote.origin.tagOpt

sb_say "A tag that moved"
bob "git tag -f -a v1.2 -m 'Second edition, reprinted' main~1 && git push -q -f origin v1.2"
sb_run "git fetch"
sb_run "git fetch --tags"
sb_run "git fetch --tags --force && git log --oneline -1 v1.2"

# ---------------------------------------------------------------------------
sb_say "Pruning"
git switch -q -c lakes main
git push -q origin lakes 2>/dev/null
git branch -q -u origin/lakes lakes
git switch -q main
bob "git push -q origin --delete lakes"
sb_run "git branch -vv"
sb_run "git fetch"
sb_run "git fetch --prune"
sb_run "git branch -vv"
sb_run "git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '\$2 == \"[gone]\" { print \$1 }'"
sb_run "git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '\$2 == \"[gone]\" { print \$1 }' | xargs git branch -d"

sb_say "Pruning on every fetch"
bob "git push -q origin main:old-idea"
sb_run "git fetch"
bob "git push -q origin --delete old-idea"
sb_run "git config set fetch.prune true && git fetch"
git config unset fetch.prune

sb_say "Pruning tags"
sb_run "git tag mine && git fetch --prune --prune-tags --dry-run"
sb_run "git fetch -p -P && git tag"

# ---------------------------------------------------------------------------
sb_say "Forced updates"
bob "git switch -q drafts && git commit -q --amend -m 'Draft the best idea'"; sb_tick
bob "git push -q -f origin drafts && git switch -q main"
sb_run "git fetch"
bob "git switch -q drafts && git commit -q --amend -m 'Draft it once more'"; sb_tick
bob "git push -q -f origin drafts && git switch -q main"
sb_run "git fetch --no-show-forced-updates"

# ---------------------------------------------------------------------------
sb_say "The remote's HEAD"
git -C "$SERVER" symbolic-ref HEAD refs/heads/drafts
sb_run "git ls-remote --symref origin HEAD && git fetch && git symbolic-ref refs/remotes/origin/HEAD"
sb_run "git -c remote.origin.followRemoteHEAD=warn fetch"
sb_run "git -c remote.origin.followRemoteHEAD=warn-if-not-branch-drafts fetch 2>&1 | tail -1"
sb_run "git -c remote.origin.followRemoteHEAD=warn-if-not-drafts fetch"
sb_run "git -c remote.origin.followRemoteHEAD=always fetch && git symbolic-ref refs/remotes/origin/HEAD"
git -C "$SERVER" symbolic-ref HEAD refs/heads/main
sb_run "git remote set-head origin -d && git -c remote.origin.followRemoteHEAD=never fetch && git branch -r --list 'origin/HEAD'"
sb_run "git fetch && git symbolic-ref refs/remotes/origin/HEAD"
sb_run "git -c remote.origin.followRemoteHEAD=sometimes fetch"

# ---------------------------------------------------------------------------
sb_say "Quiet, verbose and progress"
bob_commit maps/antarctica.txt "Antarctica" "Add Antarctica"
bob "git push -q origin main"
sb_run "git fetch -q && git log --oneline -1 origin/main"
bob_commit maps/arctic.txt "Arctic" "Add the Arctic"
bob "git push -q origin main"
sb_run "git fetch --progress 2>&1 | tr '\r' '\n' | grep -E 'done|->|From'"

sb_say "Output for scripts"
bob_commit maps/islands.txt "Islands" "Add islands"
bob "git push -q origin main && git switch -q drafts && git commit -q --amend -m 'Draft a final idea' && git push -q -f origin drafts && git switch -q main"; sb_tick
sb_run "git fetch --porcelain"
sb_run "git fetch --porcelain -v"
sb_run "git -c fetch.output=compact fetch -v"

# ---------------------------------------------------------------------------
sb_say "All or nothing"
git branch -q mydrafts origin/main~2
bob_commit maps/deserts.txt "Deserts map" "Map the deserts"
bob "git push -q origin main"
sb_run "git fetch origin main:refs/remotes/origin/main drafts:mydrafts; echo \"exit \$?\"; git log --oneline -1 origin/main"
bob_commit maps/rivers.txt "Rivers map" "Map the rivers"
bob "git push -q origin main"
sb_run "git fetch --atomic origin main:refs/remotes/origin/main drafts:mydrafts; echo \"exit \$?\"; git log --oneline -1 origin/main"
sb_run "git fetch && git log --oneline -1 origin/main"
git branch -q -D mydrafts

# ---------------------------------------------------------------------------
sb_say "The conversation"
bob_commit maps/mountains.txt "Mountains map" "Map the mountains"
bob "git push -q origin main"
sb_run "GIT_TRACE_PACKET=1 git fetch origin 2>&1 >/dev/null | grep -o 'fetch[<>].*' | sed -n '/command=fetch/,\$p'"

sb_say "What the client says it has"
git switch -q -c notes
sb_write notes.txt "A note"
sb_commit "Write a note" >/dev/null
sb_write notes.txt "A note" "Another note"
sb_commit "Write another note" >/dev/null
git switch -q main
sb_run "git log --oneline -2 notes"
bob_commit maps/forests.txt "Forests map" "Map the forests"
bob "git push -q origin main"
sb_run "GIT_TRACE_PACKET=1 git fetch origin 2>&1 >/dev/null | grep -o 'fetch> have.*' | head -4"
bob_commit maps/lakes.txt "Lakes map" "Map the lakes"
bob "git push -q origin main"
sb_run "GIT_TRACE_PACKET=1 git fetch --negotiation-restrict=refs/remotes/origin/main origin 2>&1 >/dev/null | grep -o 'fetch> have.*' | head -4"
bob_commit maps/seas.txt "Seas map" "Map the seas"
bob "git push -q origin main"
sb_run "GIT_TRACE_PACKET=1 git fetch --negotiation-restrict=refs/remotes/origin/main --negotiation-include=refs/heads/notes origin 2>&1 >/dev/null | grep -o 'fetch> have.*' | head -4"
bob_commit maps/glaciers.txt "Glaciers map" "Map the glaciers"
bob "git push -q origin main"
sb_run "git fetch --negotiate-only --negotiation-restrict=refs/heads/notes origin"
sb_run "git fetch --negotiate-only origin"
sb_run "GIT_TRACE_PACKET=1 git -c fetch.negotiationAlgorithm=noop fetch origin 2>&1 >/dev/null | grep -o 'fetch> want.*\|fetch> have.*\|fetch> done'"

sb_say "Keeping the pack"
bob_commit maps/caves.txt "Caves map" "Map the caves"
bob "git push -q origin main"
sb_run "git count-objects -v | grep -E '^(count|in-pack|packs):' && git fetch -q && git count-objects -v | grep -E '^(count|in-pack|packs):'"
bob_commit maps/volcanoes.txt "Volcanoes map" "Map the volcanoes"
bob "git push -q origin main"
sb_run "git fetch -q -k && git count-objects -v | grep -E '^(count|in-pack|packs):'"

# ---------------------------------------------------------------------------
sb_say "fetch and its neighbours"
sb_run "git fetch && git merge -q --ff-only FETCH_HEAD && git log --oneline -1"
