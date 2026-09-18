#!/bin/bash
# Generates every transcript in Chapter 51, "Merge Requests on GitLab".
#
#   bash sandbox/scripts/ch51-merge-requests-on-gitlab.sh [dir]
#
# No `set -e`: pushes are shown failing, one of them on purpose because a
# push option was not quoted.
#
# Nothing here reaches GitLab. Bare repositories stand in for it:
#
#   gitlab/maps/atlas.git    the project, in a group called `maps`; Ada is its
#                            maintainer and Bob a developer who pushes to it
#   gitlab/carol/atlas.git   Carol's fork, made the way GitLab's "Only the
#                            default branch" choice makes one, with
#                            `--single-branch --no-tags`
#
# Both accept push options, and a post-receive hook prints each option it
# receives, as the hook in Chapter 43 does. What GitLab does on its own side
# is done out of sight with `record_mr`, which keeps refs/merge-requests/<n>/head
# pointing at a merge request's branch, the ref GitLab's documentation names.
#
# Ada's, Bob's and Carol's clones reach the stand-ins by relative URLs, which
# keeps merge commits' hashes stable. `as_ada`, `as_bob` and `as_carol` move
# between the clones and set the identity; the clock is shared.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"
PROJ="$R/gitlab/maps/atlas.git"
FORK="$R/gitlab/carol/atlas.git"

be() {
	export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"
	export GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"
}
as_ada()   { be "Ada Lovelace" ada@example.com;  cd "$R/ada/atlas"; }
as_bob()   { be "Bob Brown" bob@example.com;     cd "$R/bob/atlas"; }
as_carol() { be "Carol Chen" carol@example.com;  cd "$R/carol/atlas"; }

# record_mr <n> <repository> <branch> : GitLab's side of merge request <n>:
# refs/merge-requests/<n>/head in the project follows the branch. Run again
# after every push to the branch.
record_mr() {
	git -C "$PROJ" fetch -q "$2" "+refs/heads/$3:refs/merge-requests/$1/head"
}

# The stand-ins accept push options and print the ones they receive.
stand_in() {
	git init -q --bare "$1"
	git -C "$1" config receive.advertisePushOptions true
	cat > "$1/hooks/post-receive" <<'HOOK'
#!/bin/sh
i=0
while test "$i" -lt "${GIT_PUSH_OPTION_COUNT:-0}"
do
	eval "echo \"Push option: \$GIT_PUSH_OPTION_$i\""
	i=$((i + 1))
done
HOOK
	chmod +x "$1/hooks/post-receive"
}

# ---------------------------------------------------------------------------
sb_fresh "$R/ada/atlas" >/dev/null
sb_write README.md "# Atlas" "" "Maps of Europe and Aisa."
sb_commit "Start the atlas"
sb_write maps/europe.txt "Europe"
sb_commit "Add Europe"
sb_write maps/asia.txt "Aisa"
sb_commit "Add Asia"
git tag -a v1.0 -m "Atlas 1.0"
git switch -q -c drafts
sb_write drafts/oceania.txt "Oceania, draft"
sb_commit "Draft Oceania"
git switch -q main
stand_in "$PROJ"
git push -q "$PROJ" main drafts v1.0
git remote add origin ../../gitlab/maps/atlas.git
git fetch -q origin
git branch -q -u origin/main main
git branch -q -D drafts
git clone -q "$PROJ" "$R/bob/atlas"
as_bob
git remote set-url origin ../../gitlab/maps/atlas.git

sb_say "The example repositories"
sb_run "git remote -v && git log --oneline --graph --all --decorate"

# ---------------------------------------------------------------------------
sb_say "Creating a merge request with push options"
sb_run "git switch -q -c fix-asia && echo Asia > maps/asia.txt && git commit -q -am 'Fix the spelling of Asia'"
sb_tick
sb_run "git push -o merge_request.create -o merge_request.target=main -o merge_request.title=\"Fix the spelling of Asia\" -u origin fix-asia"
record_mr 1 "$PROJ" fix-asia
sb_run "git push -o merge_request.title=Fix the spelling origin fix-asia; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "Updating a merge request"
sb_run "sed -i 's/Aisa/Asia/' README.md && git commit -q -am 'Fix the spelling in the README' && git push"
sb_tick
record_mr 1 "$PROJ" fix-asia
as_ada
sb_write maps/oceania.txt "Oceania"
sb_commit "Add Oceania"
git push -q

# ---------------------------------------------------------------------------
sb_say "Merge methods"
sb_run "git fetch -q && git log --oneline --graph main origin/fix-asia -5"
sb_run "git switch -q -c rebased origin/fix-asia && git rebase -q main"
sb_tick
sb_run "git switch -q -c merge-commit main && git merge -q --no-ff -m \"Merge branch 'fix-asia' into 'main'\" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' origin/fix-asia"
sb_tick
sb_run "git switch -q -c semi-linear main && git merge -q --no-ff -m \"Merge branch 'fix-asia' into 'main'\" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' rebased"
sb_tick
sb_run "git switch -q -c fast-forward main && git merge -q --ff-only rebased"
sb_run "git log --oneline --graph main~1..merge-commit"
sb_run "git log --oneline --graph main~1..semi-linear"
sb_run "git log --oneline --graph main~1..fast-forward"

sb_say "Squashing"
sb_run "git switch -q --detach \$(git merge-base origin/fix-asia main) && git merge -q --squash origin/fix-asia && git commit -q -m 'Fix the spelling of Asia'"
sb_tick
sb_run "SOURCE_SHA=\$(git rev-parse HEAD) && git switch -q -c squash-merge main && git merge -q --no-ff -m \"Merge branch 'fix-asia' into 'main'\" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' \$SOURCE_SHA"
sb_tick
sb_run "git switch -q -c squash-ff main && git merge -q --squash rebased && git commit -q -m 'Fix the spelling of Asia'"
sb_tick
sb_run "git log --oneline --graph main~1..squash-merge"
sb_run "git log --oneline --graph main~1..squash-ff"
git switch -q main
git branch -q -D merge-commit semi-linear fast-forward squash-merge squash-ff

# ---------------------------------------------------------------------------
sb_say "The Rebase button"
# In Git terms, what the button does: the branch rebased onto main, replacing
# the one on the server.
sb_run "git push --force-with-lease origin rebased:fix-asia"
record_mr 1 "$PROJ" fix-asia
git branch -q -D rebased
as_bob
sb_run "git fetch && git status -sb"
sb_run "git pull --rebase && git status -sb"

# ---------------------------------------------------------------------------
sb_say "Merging"
as_ada
sb_run "git fetch -q && git merge -q --no-ff -m \"Merge branch 'fix-asia' into 'main'\" -m 'Fix the spelling of Asia' -m 'See merge request maps/atlas!1' origin/fix-asia && git push -q origin main :fix-asia"
sb_tick

# ---------------------------------------------------------------------------
sb_say "Merge requests from forks"
cd "$R"
git clone -q --bare --single-branch --no-tags "$PROJ" "$FORK"
git -C "$FORK" config receive.advertisePushOptions true
cp "$PROJ/hooks/post-receive" "$FORK/hooks/post-receive"
sb_run "git ls-remote gitlab/maps/atlas.git && git ls-remote gitlab/carol/atlas.git"
git clone -q "$FORK" "$R/carol/atlas"
as_carol
git remote set-url origin ../../gitlab/carol/atlas.git
git remote add upstream ../../gitlab/maps/atlas.git
git fetch -q upstream
sb_run "git switch -q -c fix-europe upstream/main && echo 'Europe, with Iceland' > maps/europe.txt && git commit -q -am 'Add Iceland'"
sb_tick
sb_run "git push -o merge_request.create -o merge_request.target_project=maps/atlas -o merge_request.remove_source_branch origin fix-europe"
record_mr 2 "$FORK" fix-europe
as_ada
sb_run "git fetch origin merge-requests/2/head:mr-origin-2 && git log --oneline main..mr-origin-2"

sb_say "Pushing to a contributor's fork"
sb_run "git fetch ../../gitlab/carol/atlas.git fix-europe && git switch -q -c carol/fix-europe FETCH_HEAD"
sb_run "echo 'Europe, with Iceland and Malta' > maps/europe.txt && git commit -q -am 'Add Malta' && git push ../../gitlab/carol/atlas.git carol/fix-europe:fix-europe"
sb_tick
record_mr 2 "$FORK" fix-europe
sb_run "git commit -q --amend -m 'Add Malta to the Europe map' && git push --force-with-lease ../../gitlab/carol/atlas.git carol/fix-europe:fix-europe"
sb_tick
sb_run "git push --force-with-lease=fix-europe:carol/fix-europe@{1} ../../gitlab/carol/atlas.git carol/fix-europe:fix-europe"
record_mr 2 "$FORK" fix-europe
git switch -q main

# ---------------------------------------------------------------------------
sb_say "Push rules"
# A stand-in for GitLab's "Reject commits that aren't DCO certified": a
# pre-receive hook that refuses any new commit without a Signed-off-by line.
cat > "$PROJ/hooks/pre-receive" <<'HOOK'
#!/bin/sh
status=0
while read old new ref
do
	test "$new" = 0000000000000000000000000000000000000000 && continue
	for c in $(git rev-list "$new" --not --all)
	do
		if ! git log -1 --format=%B "$c" | grep -q '^Signed-off-by: '
		then
			echo "stand-in rule: $(git rev-parse --short "$c") has no Signed-off-by line"
			status=1
		fi
	done
done
exit $status
HOOK
chmod +x "$PROJ/hooks/pre-receive"
as_bob
git switch -q main
git pull -q --ff-only
sb_run "git switch -q -c add-rivers && echo Nile > maps/rivers.txt && git add maps && git commit -q -m 'Add the Nile' && echo Amazon >> maps/rivers.txt && git commit -q -am 'Add the Amazon'"
sb_tick
sb_run "git push -u origin add-rivers"
sb_run "git rebase --signoff main && git push -u origin add-rivers"
sb_tick
sb_run "git log --format='%h %s%n%(trailers)' main..add-rivers"
