#!/bin/bash
# Generates every transcript in Chapter 20, "bisect".
#
#   bash sandbox/scripts/ch20-bisect.sh [dir]
#
# No `set -e`: tests inside a bisection fail on purpose, and so do several
# commands used wrongly; the transcript must carry on past them.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null

good_calc() { sb_write calc.sh 'case "$1" in' '  add) echo $(($2 + $3)) ;;' '  sub) echo $(($2 - $3)) ;;' 'esac'; }

# ---------------------------------------------------------------------------
# A calculator in shell. "Share code between add and sub" breaks addition, and
# the two commits that move the file leave one commit without it.
sb_fresh "$SANDBOX_ROOT/calc" >/dev/null
good_calc
sb_commit "Add the calculator"
git tag v1.0
for n in 2 3 4 5; do
	sb_write "notes/$n.txt" "Note $n"
	sb_commit "Write note $n"
done
sb_write calc.sh 'case "$1" in' '  add) echo $(($2 + $3 + 0)) ;;' '  sub) echo $(($2 - $3)) ;;' 'esac'
sb_commit "Tidy the adder"
sb_write calc.sh 'case "$1" in' '  add) echo $(($2 - $3)) ;;' '  sub) echo $(($2 - $3)) ;;' 'esac'
sb_commit "Share code between add and sub"
git mv calc.sh calc.tmp
sb_commit "Start moving the calculator"
git mv calc.tmp calc.sh
sb_commit "Finish moving the calculator"
for n in 10 11 12 13 14 15 16; do
	sb_write "notes/$n.txt" "Note $n"
	sb_commit "Write note $n"
done

# The test, outside the repository so that checking out old commits cannot
# change or remove it.
sb_write "$SANDBOX_ROOT/test.sh" \
	'test -f calc.sh || exit 125' \
	'test "$(sh calc.sh add 2 3)" = 5'

# test_and_mark [skip-subject...] : show the reader's test, then mark the commit
# the way its result says, until bisect names a commit. Commits whose subject is
# given are skipped instead of tested.
test_and_mark() {
	while :; do
		subject=$(git log -1 --format=%s)
		mark=""
		for s in "$@"; do test "$subject" = "$s" && mark=skip; done
		if test -z "$mark"; then
			sb_run "sh calc.sh add 2 3"
			if test ! -f calc.sh; then mark=skip
			elif test "$(sh calc.sh add 2 3)" = 5; then mark=good
			else mark=bad
			fi
		fi
		out=$(sb_run "git bisect $mark")
		printf '%s\n' "$out"
		case "$out" in *"first 'bad' commit"*|*"could be any of"*) break ;; esac
	done
}

sb_say "--- S1. the bug ---"
sb_run "git log --oneline"
sb_run "sh calc.sh add 2 3"
sb_run "git switch --detach v1.0"
sb_run "sh calc.sh add 2 3"
sb_run "git switch main"

sb_say "--- S2. by hand ---"
sb_run "git bisect start"
sb_run "git bisect bad"
sb_run "git bisect good v1.0"
sb_run "git status"
test_and_mark
sb_run "git bisect log"
sb_run "git for-each-ref refs/bisect"
sb_run "git log --oneline -1"
sb_run "git bisect reset"
sb_run "git status -sb"

sb_say "--- S3. mistakes, log and replay ---"
sb_run "git bisect good"
sb_run "git bisect start HEAD v1.0"
sb_run "sh calc.sh add 2 3"
sb_run "git bisect good"
sb_run "git bisect log > ../bisect.log"
sb_run "cat ../bisect.log"
sb_run "git bisect reset"
wrong=$(grep '^git bisect good ' "$SANDBOX_ROOT/bisect.log" | tail -1 | cut -c17-23)
sb_run "sed -i '/^git bisect good $wrong/d' ../bisect.log"
sb_run "git bisect replay ../bisect.log"
sb_run "git bisect terms"
sb_run "git bisect reset"

sb_say "--- S4. skipping ---"
sb_run "git bisect start HEAD v1.0"
test_and_mark "Share code between add and sub"
sb_run "git bisect reset"
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect skip v1.0..main~12"
sb_run "git bisect log | grep '^git bisect skip'"
sb_run "git bisect reset"

sb_say "--- S5. running a script ---"
sb_run "cat ../test.sh"
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect run sh ../test.sh"
sb_run "git bisect reset"
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect run sh -c 'test \"\$(sh calc.sh add 2 3)\" = 5'"
sb_run "git bisect reset"
sb_write "$SANDBOX_ROOT/abort.sh" 'exit 200'
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect run sh ../abort.sh"
sb_run "git bisect reset"
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect run ../nosuch.sh"
sb_run "git bisect reset"

sb_say "--- S6. other terms ---"
sb_run "git bisect start"
sb_run "git bisect new"
sb_run "git bisect old v1.0"
sb_run "git bisect terms"
sb_run "git bisect bad"
sb_run "git bisect reset"
sb_run "git bisect start --term-new=broken --term-old=working HEAD v1.0"
sb_run "git bisect terms --term-bad"
sb_run "git bisect terms --term-old"
sb_run "git bisect run sh ../test.sh"
sb_run "git bisect reset"
sb_run "git bisect start --term-old=reset --term-new=wrong"

sb_say "--- S7. narrowing the search ---"
sb_run "git bisect start HEAD v1.0 HEAD~11"
sb_run "git bisect reset"
sb_run "git bisect start HEAD v1.0 -- calc.sh"
sb_run "git bisect run sh ../test.sh"
sb_run "git bisect reset"
sb_run "git bisect start HEAD v1.0"
sb_run "git log --oneline --bisect"
sb_run "git bisect visualize --oneline"
sb_run "git bisect view shortlog"
sb_run "git bisect reset HEAD"
sb_run "git log --oneline -1"
sb_run "git switch main"

sb_say "--- S8. without a checkout ---"
sb_run "git bisect start --no-checkout HEAD v1.0"
sb_run "git log --oneline -1"
sb_run "git log --oneline -1 BISECT_HEAD"
sb_run "git status -sb"
sb_run "git bisect run sh -c 'git cat-file -e BISECT_HEAD:calc.sh || exit 125; git show BISECT_HEAD:calc.sh | grep -q \"2 + \\\$3\"'"
sb_run "git bisect reset"

sb_say "--- S9. moving about, marking by name, errors ---"
sb_run "git bisect start HEAD v1.0"
sb_run "git switch --detach HEAD~2"
sb_run "git bisect next"
sb_run "git bisect good HEAD~3"
sb_run "git bisect bad HEAD~1"
sb_run "git bisect reset bisect/bad"
sb_run "git log --oneline -1"
sb_run "git switch main"
sb_run "git bisect start v1.0 HEAD"
sb_run "git bisect reset"
sb_run "git bisect"

# ---------------------------------------------------------------------------
sb_say "--- S10. a bug that came in with a merge ---"
sb_fresh "$SANDBOX_ROOT/merged" >/dev/null
good_calc
sb_commit "Add the calculator"
git tag v1.0
sb_write notes/1.txt "Note 1"
sb_commit "Write note 1"
git switch -q -c topic
sb_write calc.sh 'case "$1" in' '  add) echo $(($2 * $3)) ;;' '  sub) echo $(($2 - $3)) ;;' 'esac'
sb_commit "Rewrite the adder"
sb_write docs.txt "The adder is faster now."
sb_commit "Document the new adder"
git switch -q main
sb_write notes/2.txt "Note 2"
sb_commit "Write note 2"
git merge -q --no-ff -m "Merge the new adder" topic
sb_tick
for n in 3 4; do
	sb_write "notes/$n.txt" "Note $n"
	sb_commit "Write note $n"
done
sb_run "git log --oneline --graph"
sb_run "git bisect start HEAD v1.0"
sb_run "git bisect run sh ../test.sh"
sb_run "git bisect reset"
sb_run "git bisect start --first-parent HEAD v1.0"
sb_run "git bisect run sh ../test.sh"
sb_run "git bisect reset"
