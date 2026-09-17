#!/bin/bash
# Generates every transcript in Chapter 44, "Refspecs".
#
#   bash sandbox/scripts/ch44-refspecs.sh [dir]
#
# No `set -e`: many refspecs are shown being refused.
#
# The team's bare "server" is filled from a work repository, which also stands
# in for the others who push to it. It holds branches with slashes in their
# names, a branch and a tag that share the name `topic`, a lightweight and an
# annotated tag, notes, and the refs a hosting service publishes for pull
# requests and merge requests, pushed there by hand for the example. Every
# transcript runs in Ada's clone unless the chapter says otherwise.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
SERVER="$SANDBOX_ROOT/server/atlas.git"

# work <command> : run a command in the work repository, silently
work() { ( cd "$SANDBOX_ROOT/work" && eval "$@" ) >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
sb_fresh "$SANDBOX_ROOT/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
git tag v1.0
git tag topic
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
git tag -a v1.1 -m "Second edition"
for b in topic deserts wip-1 release-1.0 feature/borders feature/rivers/nile
do
	git branch "$b"
done
git switch -q -c drafts
sb_write drafts.txt "An idea"
sb_commit "Draft an idea"
git switch -q main
git notes add -m "Checked by Bob" HEAD
git init -q --bare "$SERVER"
git remote add origin "$SERVER"
git push -q origin 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*' 'refs/notes/*:refs/notes/*'
git push -q origin drafts:refs/pull/7/head deserts:refs/merge-requests/3/head

cd "$SANDBOX_ROOT"
git clone -q "$SERVER" ada
cd ada

sb_say "The example repositories"
sb_run "git ls-remote origin"
sb_run "git config get --all remote.origin.fetch && git branch -r"

# ---------------------------------------------------------------------------
sb_say "Source names"
sb_run "git fetch origin topic && cat .git/FETCH_HEAD"
sb_run "git fetch origin heads/topic && cat .git/FETCH_HEAD"
sb_run "git fetch origin pull/7/head:pr-7 && git log --oneline -1 pr-7"
sb_run "git fetch origin HEAD && cat .git/FETCH_HEAD"
sb_run "git fetch origin :refs/heads/from-head && git log --oneline -1 from-head"

sb_say "Destination names"
sb_run "git fetch origin feature/borders:borders && git for-each-ref --format='%(refname)' 'refs/*/borders'"
sb_run "git fetch origin v1.0:first && git for-each-ref --format='%(refname) %(objecttype)' 'refs/*/first'"
sb_run "git fetch origin v1.1:second; echo \"exit \$?\""
sb_run "git fetch origin v1.1:refs/tags/second && git for-each-ref --format='%(refname) %(objecttype)' 'refs/*/second'"
sb_run "git fetch origin main:refs/remotes/snapshot/x deserts:refs/remotes/snapshot/x; echo \"exit \$?\""

sb_say "Patterns"
sb_run "git fetch origin 'refs/heads/feature/*:refs/remotes/features/*' && git branch -r --list 'features/*'"
sb_run "git fetch origin 'refs/heads/release-*:refs/remotes/releases/v*' && git branch -r --list 'releases/*'"
sb_run "git fetch origin 'refs/pull/*/head:refs/remotes/origin/pr/*' && git branch -r --list 'origin/pr/*'"
sb_run "git fetch origin 'refs/heads/*/*:refs/remotes/two/*/*'; echo \"exit \$?\""
sb_run "git fetch origin 'refs/heads/*:refs/remotes/one'; echo \"exit \$?\""
sb_run "git fetch origin 'refs/heads/*'; echo \"exit \$?\""
sb_run "git fetch origin 'feature/*:refs/remotes/short/*'; echo \"exit \$?\"; git branch -r --list 'short/*'"

sb_say "Forcing with +"
sb_run "git fetch origin drafts:refs/remotes/snapshot/drafts"
work "git switch -q drafts && git commit -q --amend -m 'Draft a better idea' && git push -q -f origin drafts drafts:refs/pull/7/head && git switch -q main"
sb_tick
sb_run "git fetch origin drafts:refs/remotes/snapshot/drafts; echo \"exit \$?\""
sb_run "git fetch origin +drafts:refs/remotes/snapshot/drafts"
work "git switch -q drafts && git commit -q --amend -m 'Draft the best idea' && git push -q -f origin drafts && git switch -q main"
sb_tick
sb_run "git fetch --no-show-forced-updates origin drafts:refs/remotes/snapshot/drafts; echo \"exit \$?\""
sb_run "git fetch origin +v1.1:refs/heads/second; echo \"exit \$?\""

sb_say "Negative refspecs"
sb_run "git fetch origin 'refs/heads/*:refs/remotes/without/*' '^wip-1' && git branch -r --list 'without/wip-*'"
sb_run "git fetch origin 'refs/heads/*:refs/remotes/without-wip/*' '^refs/heads/wip-*' && git branch -r --list 'without-wip/*'"
sb_run "git fetch origin '^refs/heads/wip-*:refs/remotes/wip'; echo \"exit \$?\""
sb_run "git fetch origin \"^\$(git rev-parse origin/wip-1)\"; echo \"exit \$?\""
work "git push -q origin main:wip-2 && git push -q origin --delete wip-1"
sb_run "git config set --append remote.origin.fetch '^refs/heads/wip-*' && git config get --all remote.origin.fetch"
sb_run "git fetch --prune -v && git branch -r --list 'origin/wip-*'"
sb_run "git fetch origin wip-2 && git branch -r --list 'origin/wip-*'"

sb_say "Several refspecs for one remote"
sb_run "git config set --append remote.origin.fetch '+refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*' && git fetch"
sb_run "git config get --all remote.origin.fetch"
git config unset --all remote.origin.fetch
git config set remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

sb_say "Refspecs that clone writes"
cd "$SANDBOX_ROOT"
sb_run "git clone -q --single-branch --branch deserts $SERVER one-branch && git -C one-branch config get --all remote.origin.fetch"
sb_run "git clone -q --mirror $SERVER mirror.git && git -C mirror.git config get --all --show-names --regexp '^remote\\.origin\\.'"
sb_run "git clone -q --bare $SERVER bare.git && git -C bare.git config get --all remote.origin.fetch; echo \"exit \$?\""
cd "$SANDBOX_ROOT/ada"

# ---------------------------------------------------------------------------
sb_say "Push: source names"
# The branches the fetch examples made are not wanted in the push examples.
git branch -q -D borders first from-head pr-7
git branch -q topic origin/topic
git branch -q wip-3 main
sb_write maps/africa.txt "Africa"
git add -A && git commit -q -m "Add Africa"
sb_tick
sb_run "git push origin topic; echo \"exit \$?\""
sb_run "git push --porcelain origin heads/topic main~1:refs/heads/older \$(git rev-parse main):refs/heads/by-hash"

sb_say "Push: destination names"
sb_run "git push --porcelain origin main:review"
sb_run "git push --porcelain origin v1.1:release"
sb_run "git push --porcelain origin main:release; echo \"exit \$?\""
sb_run "git push --porcelain origin main:refs/for/main"
sb_run "git push --porcelain --force origin v1.1:refs/heads/tag-branch; echo \"exit \$?\""

sb_say "Push: empty sources and matching"
sb_run "git push --porcelain origin :review :older"
sb_run "git push --porcelain --dry-run origin :"

sb_say "Push: patterns"
sb_run "git push --porcelain origin 'refs/heads/*:refs/heads/backup/ada/*'"
sb_run "git push origin 'main:refs/heads/*'; echo \"exit \$?\""

sb_say "Push: negative refspecs"
sb_run "git push --porcelain --dry-run origin 'refs/heads/*:refs/heads/copy/*' '^refs/heads/wip-*'"
sb_run "git push --porcelain --dry-run origin 'refs/heads/*:refs/heads/copy/*' '^refs/heads/copy/wip-*'"

sb_say "Push refspecs in the configuration"
sb_run "git config set remote.origin.push 'refs/heads/main:refs/heads/review/main' && git push --porcelain && git push --porcelain origin wip-3"
sb_write maps/asia.txt "Asia"
git add -A && git commit -q -m "Add Asia"
sb_tick
sb_run "git config set remote.origin.push 'HEAD:refs/for/main' && git push --porcelain"
git config unset remote.origin.push

# ---------------------------------------------------------------------------
sb_say "Names Git refuses"
sb_run "git fetch origin 'ma..in'; echo \"exit \$?\""
sb_run "git check-ref-format --branch 'ma..in'; echo \"exit \$?\""
sb_run "git push origin 'tag v1.1'; echo \"exit \$?\""
sb_run "git push origin 'main:refs/heads/x:y'; echo \"exit \$?\""
