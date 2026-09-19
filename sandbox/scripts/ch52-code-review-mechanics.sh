#!/bin/bash
# Generates every transcript in Chapter 52, "Code Review Mechanics".
#
#   bash sandbox/scripts/ch52-code-review-mechanics.sh [dir]
#
# No `set -e`: `git diff --check` exits non-zero on purpose, a test run inside
# `git rebase -x` is shown failing, and `git range-diff --max-memory` is shown
# refusing.
#
# One project, `greet`, on a bare server (server/greet.git), with a clone for
# Ada, who reviews, and one for Bob, who wrote the change. The clones reach the
# server by the relative URL ../../server/greet.git, because merge messages name
# the URL and an absolute sandbox path would change their hashes on every run.
# `as_ada` and `as_bob` move between the clones and set the identity; the clock
# is shared, so hashes stay stable.
#
# The story, in the chapter's order: Bob pushes version 1 of a change (three
# commits, the last a fixup he forgot to fold in); Ada reads it, tries it in a
# second working tree, tests every commit, and pushes a fixup of her own; Ada
# moves `main` on; Bob keeps version 1 as `farewell-v1`, folds the fixups in,
# rebases onto the new `main` and pushes version 2; Ada compares the two.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null
R="$SANDBOX_ROOT"

be() {
	export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"
	export GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"
}
as_ada() { be "Ada Lovelace" ada@example.com; cd "$R/ada/greet"; }
as_bob() { be "Bob Brown" bob@example.com;    cd "$R/bob/greet"; }
TAB="$(printf '\t')"

# ---------------------------------------------------------------------------
# The project: two shell files, a function and its test.
sb_fresh "$R/ada/greet" >/dev/null
sb_write README.md "# greet" "" "Shell functions that greet people."
sb_write lib.sh "hello() {" "${TAB}echo \"Hello, \$1!\"" "}"
sb_commit "Start the greeter"
sb_write test.sh ". ./lib.sh" \
	"test \"\$(hello Ada)\" = \"Hello, Ada!\" || { echo \"FAIL: hello\"; exit 1; }" \
	"echo \"all tests passed\""
sb_commit "Add the tests"
git init -q --bare "$R/server/greet.git"
git remote add origin ../../server/greet.git
git push -q -u origin main
git clone -q "$R/server/greet.git" "$R/bob/greet"
git -C "$R/bob/greet" remote set-url origin ../../server/greet.git

sb_say "The example repository"
sb_run "git log --oneline && cat lib.sh test.sh"

# Bob's change, version 1: a farewell, its test, and a fixup he forgot to fold
# in. The first commit has a debug line, which makes the second commit's test
# fail until the third removes it, and a space before a tab.
as_bob
git switch -q -c farewell
sb_write lib.sh "hello() {" "${TAB}echo \"Hello, \$1!\"" "}" "" "bye() {" \
	"${TAB}echo \"DEBUG: bye \$1\"" " ${TAB}echo \"Goodbye, \$1.\"" "}"
sb_commit "Add a farewell"
sb_write test.sh ". ./lib.sh" \
	"test \"\$(hello Ada)\" = \"Hello, Ada!\" || { echo \"FAIL: hello\"; exit 1; }" \
	"test \"\$(bye Ada)\" = \"Goodbye, Ada.\" || { echo \"FAIL: bye\"; exit 1; }" \
	"echo \"all tests passed\""
sb_commit "Test the farewell"
sb_write lib.sh "hello() {" "${TAB}echo \"Hello, \$1!\"" "}" "" "bye() {" \
	" ${TAB}echo \"Goodbye, \$1.\"" "}"
sb_commit "fixup! Add a farewell"

# ---------------------------------------------------------------------------
sb_say "Asking for a review"
sb_run "git shortlog -s -n origin/main -- lib.sh test.sh"
sb_run "git push -u origin farewell"

# ---------------------------------------------------------------------------
sb_say "What is under review"
as_ada
sb_run "git fetch origin"
sb_run "git log --reverse --format='%h %an  %s' main..origin/farewell"
sb_run "git diff --stat main...origin/farewell"

sb_say "All at once, or one commit at a time"
sb_run "git diff main...origin/farewell"
sb_run "git log -p --reverse --oneline main..origin/farewell"

# ---------------------------------------------------------------------------
sb_say "Trying it without disturbing your work"
echo "Say hello to people by name." >> README.md
sb_run "git status --short"
sb_run "git worktree add --detach ../review origin/farewell"
sb_run "cd ../review"
cd ../review
sb_run "sh test.sh"

# ---------------------------------------------------------------------------
sb_say "Checking the change"
sb_run "git diff --check main...origin/farewell; echo \"exit \$?\""
sb_run "git rebase -x 'sh test.sh' --keep-base main"
sb_run "git rebase --abort && git log --oneline -1"

# ---------------------------------------------------------------------------
sb_say "Suggesting a change as a commit"
sb_run "sed -i 's/^ //' lib.sh && git commit -q -a --fixup=HEAD~2 && git push -q origin HEAD:farewell"
sb_tick
sb_run "cd ../greet"
cd ../greet
sb_run "git worktree remove ../review"

# Ada commits her README change on main and pushes it: main moves on.
git commit -q -am "Say what greet is for" && git push -q
sb_tick

# ---------------------------------------------------------------------------
sb_say "Responding to a review"
as_bob
sb_run "git branch farewell-v1 && git pull -q --ff-only && git log --format='%h %an  %s' origin/main.."
sb_run "git rebase --autosquash origin/main"
sb_tick
sb_run "git log --format='%h %an  %s' origin/main.."
sb_run "git push --force-with-lease"

sb_say "Telling the reviewer what changed"
sb_run "git range-diff origin/main farewell-v1 farewell"
sb_run "git format-patch -q -v2 --cover-letter --range-diff=farewell-v1 -o outgoing origin/main && ls outgoing"
sb_run "cat outgoing/v2-0000-cover-letter.patch"
sb_run "git format-patch -q -v2 --cover-letter --interdiff=farewell-v1 -o outgoing2 origin/main && sed -n '/^Interdiff/,\$p' outgoing2/v2-0000-cover-letter.patch"

# ---------------------------------------------------------------------------
sb_say "Comparing two versions"
as_ada
sb_run "git fetch origin"
sb_run "git diff --stat origin/farewell@{1} origin/farewell"
sb_run "git range-diff main origin/farewell@{1} origin/farewell"

sb_say "The three forms"
sb_run "diff <(git range-diff main origin/farewell@{1} origin/farewell) <(git range-diff main..origin/farewell@{1} main..origin/farewell) && echo same"
sb_run "diff <(git range-diff origin/farewell@{1}...origin/farewell) <(git range-diff origin/farewell..origin/farewell@{1} origin/farewell@{1}..origin/farewell) && echo same"
sb_run "git range-diff origin/farewell@{1}~3^! origin/farewell~1^!"

sb_say "Choosing the base"
sb_run "git range-diff origin/farewell@{1}...origin/farewell"
sb_run "git range-diff --right-only origin/farewell@{1}...origin/farewell"
sb_run "git range-diff --left-only origin/farewell@{1}...origin/farewell"

sb_say "Reading the output"
as_bob
sb_run "git switch -q --detach origin/main && git cherry-pick farewell farewell~1 && git range-diff origin/main farewell HEAD"
git switch -q farewell
as_ada

sb_say "When a commit is shown as removed and added"
sb_run "git range-diff --creation-factor=20 main origin/farewell@{1} origin/farewell"

sb_say "Only some files"
sb_run "git range-diff main origin/farewell@{1} origin/farewell -- test.sh"

sb_say "Colour"
sb_run_ansi "git range-diff main origin/farewell@{1} origin/farewell -- lib.sh"
sb_run_ansi "git range-diff --no-dual-color main origin/farewell@{1} origin/farewell -- lib.sh"

sb_say "Notes"
as_bob
sb_run "git notes add -m 'v2: fold in both fixups' HEAD~1 && git range-diff origin/main farewell-v1 farewell"
sb_run "git range-diff --no-notes origin/main farewell-v1 farewell"
sb_run "git notes --ref=changes add -m 'v2: test unchanged' HEAD && git range-diff --notes=changes origin/main farewell-v1 farewell"

sb_say "Merges"
sb_run "git switch -q -c farewell-merged farewell-v1 && git merge -q --no-edit origin/main && git range-diff origin/main farewell-v1 farewell-merged"
sb_tick
sb_run "git range-diff --remerge-diff origin/main farewell-v1 farewell-merged"
sb_run "git range-diff --diff-merges=first-parent origin/main farewell-v1 farewell-merged"
git switch -q farewell

sb_say "Output options"
as_ada
sb_run "git range-diff --abbrev=12 -s main origin/farewell@{1} origin/farewell"
sb_run "git range-diff -U1 main origin/farewell@{1} origin/farewell"
sb_run "git range-diff --stat main origin/farewell@{1} origin/farewell"
sb_run "git range-diff --max-memory=1 main origin/farewell@{1} origin/farewell"

# ---------------------------------------------------------------------------
sb_say "Approving"
sb_run "git switch -q --detach origin/farewell && git rebase -x 'sh test.sh' --keep-base main"
sb_run "git rev-parse HEAD origin/farewell && git switch -q main"

# ---------------------------------------------------------------------------
sb_say "Neighbours"
as_bob
sb_run "for c in farewell-v1~2 farewell~1 farewell-v1~1 farewell; do git show \$c | git patch-id; done"
