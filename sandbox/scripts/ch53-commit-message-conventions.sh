#!/bin/bash
# Generates every transcript in Chapter 53, "Commit Message Conventions".
#
#   bash sandbox/scripts/ch53-commit-message-conventions.sh [dir]
#
# No `set -e`: a commit-msg hook is shown refusing commits.
#
# One repository, `greet`, the small shell project of Chapter 52. Its history
# grows section by section with messages written for each demonstration; the
# messages for `git interpret-trailers` are files beside it, in `msgs/`, and the
# commands read them from there. Bob's commits carry his own name.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"
TAB="$(printf '\t')"

as_ada() {
	export GIT_AUTHOR_NAME="Ada Lovelace" GIT_AUTHOR_EMAIL="ada@example.com"
	export GIT_COMMITTER_NAME="Ada Lovelace" GIT_COMMITTER_EMAIL="ada@example.com"
}
as_bob() {
	export GIT_AUTHOR_NAME="Bob Brown" GIT_AUTHOR_EMAIL="bob@example.com"
	export GIT_COMMITTER_NAME="Bob Brown" GIT_COMMITTER_EMAIL="bob@example.com"
}

# ---------------------------------------------------------------------------
sb_fresh "$R/greet" >/dev/null
sb_write README.md "# greet" "" "Shell functions that greet people."
sb_write lib.sh "hello() {" "${TAB}echo \"Hello, \$1!\"" "}"
sb_commit "Start the greeter"
sb_write test.sh ". ./lib.sh" \
	"test \"\$(hello Ada)\" = \"Hello, Ada!\" || { echo \"FAIL: hello\"; exit 1; }" \
	"echo \"all tests passed\""
sb_commit "Add the tests"

# Bob's farewell, with a body and two trailers.
as_bob
sb_write lib.sh "hello() {" "${TAB}echo \"Hello, \$1!\"" "}" "" "bye() {" \
	"${TAB}echo \"Goodbye, \$1.\"" "}"
git add lib.sh
git commit -q -m "Add a farewell" \
	-m "Greet people when they leave, as well as when they arrive." \
	-m "Reviewed-by: Ada Lovelace <ada@example.com>" -s
sb_tick
as_ada

sb_say "The parts of a message"
sb_run "git log -1 --format=%B"
sb_run "git log -1 --format='%s'"
sb_run "git log -1 --format='%b'"
sb_run "git log -1 --format='%(trailers)'"

sb_say "Where the subject goes"
sb_run "git log --oneline -1 && git format-patch -q -1 -o out && ls out && grep '^Subject' out/*"
rm -rf out

sb_say "A subject of more than one line"
printf 'Test the farewell\nand the greeting together\n\nOne test run covers both functions.\n' > ../msg.txt
sb_write test.sh ". ./lib.sh" \
	"test \"\$(hello Ada)\" = \"Hello, Ada!\" || { echo \"FAIL: hello\"; exit 1; }" \
	"test \"\$(bye Ada)\" = \"Goodbye, Ada.\" || { echo \"FAIL: bye\"; exit 1; }" \
	"echo \"all tests passed\""
git add test.sh
sb_run "cat ../msg.txt && git commit -q -F ../msg.txt"
sb_tick
sb_run "git log --oneline -1 && git format-patch -q -1 -o out && ls out && grep '^Subject' out/*"
rm -rf out

sb_say "How long"
sb_write README.md "# greet" "" "Shell functions that greet people." "" "Run the tests with sh test.sh."
git add README.md
sb_run "git commit -q -m 'Explain in the README how to run the tests and what they print' && git log --oneline -1"
sb_tick
sb_run "git format-patch -q -1 -o out && ls out"
rm -rf out
sb_run "git log -1 --format='%<(50,trunc)%s'"

sb_say "The body is not wrapped"
sb_write README.md "# greet" "" "Shell functions that greet people." "" "Run the tests with sh test.sh; it prints all tests passed."
git add README.md
sb_run "git commit -q -m 'Say what the tests print' -m 'The README said how to run the tests but not what a successful run looks like, which left a new contributor unsure whether the silence meant success.' && git log -1"
sb_tick
sb_run "git log -1 --format='%w(72,4,4)%b'"

sb_say "Referring to another commit"
sb_run "git show -s --pretty=reference HEAD~2"
sb_run "git -c core.abbrev=12 -c pretty.fixes='Fixes: %h (\"%s\")' show -s --pretty=fixes HEAD~2"

# ---------------------------------------------------------------------------
# Messages for the trailer demonstrations, one file each.
mkdir -p ../msgs
printf 'Fix the farewell\n\nKeep the full stop.\n\nReviewed-by: Ada Lovelace <ada@example.com>\nRefs: #12\n' > ../msgs/plain.txt
printf 'Fix the farewell\n\nKeep the full stop.\n\nRefs: #12\nThe report has the details,\nand a screenshot of the\nfailing test.\n' > ../msgs/mixed.txt
printf 'Fix the farewell\n\nKeep the full stop.\n\nSigned-off-by: Bob Brown <bob@example.com>\nThe report has the details,\nand a screenshot of the\nfailing test.\n' > ../msgs/signed.txt
printf 'Fix the farewell\n\nKeep the full stop.\n\nSigned-off-by: Bob Brown <bob@example.com>\nThe report has the details,\nand a screenshot of the\nfailing test, which\nshows the problem.\n' > ../msgs/signed5.txt
printf 'Fix the farewell\nRefs: #12\n' > ../msgs/noblank.txt
printf 'Fix the farewell\n\nKeep the full stop.\n\nRefs : #12\nNote: the value of a trailer\n  can go on to the next line\n Acked-by: Grace Hopper <grace@example.com>\n' > ../msgs/spaces.txt
printf 'feat: say goodbye\n\nBREAKING CHANGE: bye now needs a name\nRefs: #12\n' > ../msgs/breaking.txt
printf 'feat: say goodbye\n\nBREAKING-CHANGE: bye now needs a name\nRefs: #12\n' > ../msgs/breaking2.txt
printf 'fix: keep the full stop\n\nRefs #12\n' > ../msgs/hash.txt
printf 'Fix the farewell\n\nKeep the full stop.\n\nReviewed-by: Ada Lovelace <ada@example.com>\nAcked-by: Grace Hopper <grace@example.com>\nRefs: #9\n' > ../msgs/three.txt
printf 'Fix the farewell\n\nKeep the full stop.\n\nFixes: \nCc: \nReviewed-by: Ada Lovelace <ada@example.com>\n' > ../msgs/empty.txt
printf 'Fix the farewell\n\nKeep the full stop.\n' > ../msgs/bare.txt
printf 'Update the README\n\nAdd a section on the tests, which reads:\n---\nRun the tests with sh test.sh.\n' > ../msgs/dashes.txt
cp ../msgs/bare.txt ../msgs/edit.txt

sb_say "What counts as a trailer"
sb_run "cat ../msgs/plain.txt && git interpret-trailers --parse ../msgs/plain.txt"
sb_run "cat ../msgs/mixed.txt && git interpret-trailers --parse ../msgs/mixed.txt"
sb_run "tail -n 4 ../msgs/signed.txt && git interpret-trailers --parse ../msgs/signed.txt"
sb_run "tail -n 5 ../msgs/signed5.txt && git interpret-trailers --parse ../msgs/signed5.txt"
sb_run "git -c trailer.refs.key=Refs interpret-trailers --parse ../msgs/mixed.txt"
sb_run "cat ../msgs/noblank.txt && git interpret-trailers --parse ../msgs/noblank.txt"
sb_run "cat ../msgs/spaces.txt && git interpret-trailers --parse ../msgs/spaces.txt"

sb_say "A line that only looks like a trailer"
sb_run "git commit -q --allow-empty -s -m 'Fix the link in the README' -m 'The bug report is at' -m 'https://example.com/greet/issues/7' && git log -1 --format=%B"
sb_run "git log -1 --format='%(trailers)'"
sb_run "git commit -q --amend --allow-empty -s -m 'Fix the link in the README' -m 'The bug report is at https://example.com/greet/issues/7.' && git log -1 --format=%B"
git reset -q --hard HEAD~1

sb_say "Signing off"
as_bob
sb_run "git commit -q --allow-empty -s -m 'Signed off by Bob' && git log -1 --format=%B"
as_ada
sb_run "git commit -q --amend --allow-empty --no-edit -s && git log -1 --format=%B"
sb_run "git commit -q --amend --allow-empty --no-edit -s && git log -1 --format=%B"
sb_run "git commit -q --amend --allow-empty --no-edit --trailer 'Reviewed-by: Grace Hopper <grace@example.com>' && git commit -q --amend --allow-empty --no-edit -s && git log -1 --format=%B"
git reset -q --hard HEAD~1

sb_say "Adding trailers from other commands"
sb_run "git tag -a v1.0 -m 'greet 1.0' --trailer 'Reviewed-by: Bob Brown <bob@example.com>' && git cat-file -p v1.0"

# ---------------------------------------------------------------------------
sb_say "git interpret-trailers: adding"
sb_run "git interpret-trailers --trailer 'Reviewed-by: Ada Lovelace <ada@example.com>' --trailer 'Refs=#12' ../msgs/bare.txt"
sb_run "git interpret-trailers --trailer 'Refs: #12' < ../msgs/bare.txt"
sb_run "git interpret-trailers --in-place --trailer 'Refs: #12' ../msgs/edit.txt && cat ../msgs/edit.txt"

sb_say "Where"
sb_run "git interpret-trailers --only-trailers --where=end --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --where=start --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --where=after --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --where=before --trailer 'Acked-by: Bob Brown <bob@example.com>' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --trailer 'Tested-by: Bob' --where=start --trailer 'Tested-by: Carol' --trailer 'Tested-by: Dan' --no-where --trailer 'Tested-by: Eve' ../msgs/three.txt"

sb_say "If exists"
sb_run "git interpret-trailers --only-trailers --trailer 'Refs: #9' ../msgs/three.txt && git interpret-trailers --only-trailers --trailer 'Acked-by: Grace Hopper <grace@example.com>' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --if-exists=addIfDifferentNeighbor --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --if-exists=addIfDifferent --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --if-exists=add --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --if-exists=replace --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --if-exists=doNothing --trailer 'Refs: #9' --trailer 'Refs: #10' ../msgs/three.txt"
sb_run "git -c trailer.ifexists=doNothing interpret-trailers --only-trailers --if-exists=add --trailer 'Refs: #10' --no-if-exists --trailer 'Refs: #11' ../msgs/three.txt"

sb_say "If missing"
sb_run "git interpret-trailers --if-missing=add --trailer 'Refs: #12' ../msgs/bare.txt"
sb_run "git interpret-trailers --if-missing=doNothing --trailer 'Refs: #12' ../msgs/bare.txt"
sb_run "git interpret-trailers --only-trailers --if-missing=doNothing --trailer 'Tested-by: Bob' --no-if-missing --trailer 'Tested-by: Carol' ../msgs/three.txt"
sb_run "git interpret-trailers --only-trailers --trailer 'Refs: #12' --no-trailer --trailer 'Tested-by: Bob' ../msgs/three.txt"

sb_say "Reading"
sb_run "git interpret-trailers --only-trailers ../msgs/spaces.txt"
sb_run "git interpret-trailers --only-trailers --unfold ../msgs/spaces.txt"
sb_run "cat ../msgs/empty.txt && git interpret-trailers --trim-empty ../msgs/empty.txt"

sb_say "Keys"
sb_run "git -c trailer.ack.key=Acked-by interpret-trailers --only-trailers --trailer 'ack: Bob Brown <bob@example.com>' ../msgs/three.txt"
sb_run "git -c trailer.ack.key=Acked-by -c trailer.ack.where=after -c trailer.ack.ifexists=addIfDifferent interpret-trailers --only-trailers --trailer 'ack: Bob Brown <bob@example.com>' --trailer 'ack: Grace Hopper <grace@example.com>' ../msgs/three.txt"
sb_run "git -c trailer.separators=':#' interpret-trailers --parse ../msgs/hash.txt"
sb_run "git -c trailer.separators=':#' -c 'trailer.fix.key=Fix #' interpret-trailers --trailer fix=42 ../msgs/bare.txt"

sb_say "Values from a command"
git config user.name "Ada Lovelace"
git config user.email ada@example.com
sb_run "git -c trailer.see.key=See-also -c 'trailer.see.cmd=git show -s --pretty=reference' interpret-trailers --only-trailers --trailer see=HEAD~1 ../msgs/three.txt"
sb_run "git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.cmd=echo \"\$(git config user.name) <\$(git config user.email)>\"' interpret-trailers --only-trailers ../msgs/three.txt"
sb_run "git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.cmd=echo \"\$(git config user.name) <\$(git config user.email)>\"' interpret-trailers --only-trailers --trailer sign ../msgs/three.txt"
sb_run "git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.cmd=git var GIT_COMMITTER_IDENT | sed \"s/>.*/>/\"' interpret-trailers --only-trailers --trailer sign ../msgs/three.txt"
sb_run "git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.command=echo \"\$(git config user.name) <\$(git config user.email)>\"' interpret-trailers --only-trailers ../msgs/three.txt"
sb_run "git -c trailer.sign.key=Signed-off-by -c 'trailer.sign.command=echo \"\$(git config user.name) <\$(git config user.email)>\"' interpret-trailers --only-trailers --only-input ../msgs/three.txt"

sb_say "Patches"
sb_run "git format-patch -q -1 -o out && git interpret-trailers --trailer 'Tested-by: Bob Brown <bob@example.com>' out/0001-*.patch"
rm -rf out
sb_run "cat ../msgs/dashes.txt && git interpret-trailers --trailer 'Refs: #12' ../msgs/dashes.txt"
sb_run "git interpret-trailers --no-divider --trailer 'Refs: #12' ../msgs/dashes.txt"

# ---------------------------------------------------------------------------
sb_say "Conventional Commits"
conv() { # conv <file> <message>... : change a file and commit with -m for each paragraph
	local f="$1"; shift
	echo "$1" >> "$f"
	local args=()
	for p in "$@"; do args+=(-m "$p"); done
	git add "$f" && git commit -q "${args[@]}"
	sb_tick
}
conv notes.txt "feat: add a farewell"
conv notes.txt "fix(test): report which test failed"
conv notes.txt "docs: explain how to run the tests"
conv notes.txt "feat(greet)!: take the name from GREET_NAME" "When no name is given, fall back to the variable."
conv notes.txt "feat: greet in capitals on request" "BREAKING CHANGE: hello no longer prints a full stop"
conv notes.txt "fix: keep the full stop in the farewell" "Refs #12"
sb_run "git log --oneline v1.0.."
sb_run "git log --format='- %s' -E --grep='^feat(\\(.*\\))?!?: ' v1.0.."
sb_run "git log --format='- %s' -E --grep='^fix(\\(.*\\))?!?: ' v1.0.."
sb_run "git log --oneline -E --grep='^[a-z]+(\\(.*\\))?!: ' --grep='^BREAKING[ -]CHANGE: ' v1.0.."

sb_say "Conventional Commits and Git's trailers"
sb_run "cat ../msgs/breaking.txt && git interpret-trailers --parse ../msgs/breaking.txt"
sb_run "cat ../msgs/breaking2.txt && git interpret-trailers --parse ../msgs/breaking2.txt"
sb_run "cat ../msgs/hash.txt && git interpret-trailers --parse ../msgs/hash.txt"


sb_say "Enforcing a convention"
cat > .git/hooks/commit-msg <<'HOOK'
#!/bin/sh
subject=$(head -n 1 "$1")
if ! echo "$subject" | grep -qE '^(feat|fix|docs|test|refactor|chore)(\([a-z]+\))?!?: '
then
	echo "commit-msg: start the subject with a type, such as 'fix: '" >&2
	exit 1
fi
if test ${#subject} -gt 50
then
	echo "commit-msg: the subject has ${#subject} characters; keep it to 50" >&2
	exit 1
fi
HOOK
chmod +x .git/hooks/commit-msg
sb_run "cat .git/hooks/commit-msg"
sb_run "git commit -q --allow-empty -m 'Tidy the tests'; echo \"exit \$?\""
sb_run "git commit -q --allow-empty -m 'test: run the greeting and the farewell tests together'; echo \"exit \$?\""
sb_run "git commit -q --allow-empty -m 'test: run both tests together' && git log --oneline -1"
