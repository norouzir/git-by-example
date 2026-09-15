#!/bin/bash
# Generates every transcript in Chapter 17, "log".
#
#   bash sandbox/scripts/ch17-log.sh [dir]
#
# No `set -e`: several commands shown here fail on purpose, such as log in an
# empty repository or on a path that is not there, and the transcript must
# carry on past them.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
# Relative dates in this chapter are computed against the sandbox clock.
sb_pin_now

# as <name> <email> : make the next commits by this person, author and committer
as() {
	export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"
	export GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"
}
ada()   { as "Ada Lovelace" "ada@example.com"; }
grace() { as "Grace Hopper" "grace@example.com"; }
alan()  { as "Alan Turing" "alan@example.com"; }

# commit_msg <file with the message> : stage everything and commit, then tick
commit_msg() {
	git add -A && git commit -q -F "$1" && sb_tick
}

sb_say "--- L0. log with nothing to show ---"
sb_fresh "$SANDBOX_ROOT/empty" >/dev/null
sb_run "git log"
cd "$SANDBOX_ROOT"

# ---------------------------------------------------------------------------
# The main example: a small calculator project.
git init -q --bare "$SANDBOX_ROOT/origin.git"
sb_fresh "$SANDBOX_ROOT/calc" >/dev/null
git remote add origin "$SANDBOX_ROOT/origin.git"

ada
sb_write README.md "# Calculator" "" "A tiny calculator."
sb_commit "Add README"

sb_write calc.py "def sub(a, b):" "    return b - a" "" "" "def add(a, b):" "    return a + b"
sb_commit "Add the calculator"

grace
sb_write test_calc.py "from calc import add, sub" "" "" "def test_add():" "    assert add(2, 3) == 5"
printf 'Add tests\n\nCover add() for now; sub() is still wrong.\n\nRefs: #12\nReviewed-by: Ada Lovelace <ada@example.com>\n' > "$SANDBOX_ROOT/msg"
commit_msg "$SANDBOX_ROOT/msg"
ada
git tag -a v1.0 -m "First release"
git push -q origin main v1.0

git switch -q -c feature
alan
sb_write calc.py "def sub(a, b):" "    return b - a" "" "" "def add(a, b):" "    return a + b" "" "" "def mul(a, b):" "    return a * b"
sb_commit "Add multiply"
sb_write README.md "# Calculator" "" "A tiny calculator." "" "It can multiply."
sb_commit "Document multiply"

git switch -q main
ada
sb_write calc.py "def sub(a, b):" "    return a - b" "" "" "def add(a, b):" "    return a + b"
printf 'Fix subtraction\n\nsub() returned b - a.\n\nRefs: #12\n' > "$SANDBOX_ROOT/msg"
commit_msg "$SANDBOX_ROOT/msg"
git merge -q --no-edit feature >/dev/null
sb_tick

grace
git mv test_calc.py tests_calc.py
sb_commit "Rename the test file"

ada
sb_write calc.py "def sub(a, b):" "    return a - b" "" "" "def add(a, b):" "    return a + b" "" "" "def mul(a, b):" "    return a * b" "" "" "def div(a, b):" "    return a / b"
sb_write README.md "# Calculator" "" "A tiny calculator." "" "It can multiply and divide."
printf 'Add divide\n\nDividing by zero raises ZeroDivisionError.\n' > "$SANDBOX_ROOT/msg"
commit_msg "$SANDBOX_ROOT/msg"
git tag v1.1

alan
sb_write notes/LOG.txt "Logging was written in December and committed now."
GIT_AUTHOR_DATE="2026-01-01 10:00:00 +0330" git add -A
GIT_AUTHOR_DATE="2026-01-01 10:00:00 +0330" git commit -q -m "Backport logging notes"
sb_tick
ada
git branch -q old-feature feature
CALC_NOW=$SANDBOX_NOW
# back_to_calc : return to the main example, with its clock and its "now"
back_to_calc() { cd "$SANDBOX_ROOT/calc"; SANDBOX_NOW=$CALC_NOW; sb_settime; }

sb_say "--- L1. the default output ---"
sb_run "git log -3"

sb_say "--- L2. what log walks ---"
sb_run "git log --oneline"
sb_run "git log --oneline feature"
sb_run "git log --oneline feature main"
sb_run "git log --oneline main ^feature"
sb_run "git log --oneline feature..main"
sb_run "git log --oneline --not feature --not main"
sb_run "git log --oneline origin/main..main"
sb_run "git log --oneline --all"
sb_run "git log --oneline --branches"
sb_run "git log --oneline --branches='old*'"
sb_run "git log --oneline --tags"
sb_run "git log --oneline --remotes"
sb_run "git log --oneline --glob='refs/tags/v1.1'"
sb_run "git log --oneline --glob='refs/tags/v1.[1]'"
sb_run "git log --oneline --glob='tags/v1.1*'"
sb_run "git log --oneline --exclude=main --branches"
sb_run "git log --oneline nosuch"
sb_run "git log --oneline --ignore-missing nosuch feature"
sb_run "echo feature | git log --oneline --stdin"
sb_run "git log --oneline --no-walk v1.0 v1.1 feature"
sb_run "git log --oneline --no-walk=unsorted v1.1 v1.0"
sb_run "git log --oneline --no-walk --do-walk v1.0"
sb_run "git log --oneline --no-walk feature..main"
sb_run "git log --oneline --maximal-only --all"

sb_say "--- L3. how many ---"
sb_run "git log --oneline -2"
sb_run "git log --oneline -n 2"
sb_run "git log --oneline --max-count=2"
sb_run "git log --oneline --skip=2 -2"
sb_run "git log --oneline --max-count-oldest=2"
sb_run "git log --oneline --reverse -2"
sb_run "git log --oneline -2 --reverse --max-count-oldest=2"

sb_say "--- L4. by date ---"
sb_run "git log --format='%h %ad %s' --date=iso"
sb_run "git log --oneline --since='2026-01-05 13:00'"
sb_run "git log --oneline --after='2026-01-05 13:00'"
sb_run "git log --oneline --until='2026-01-05 11:30'"
sb_run "git log --oneline --before='2026-01-05 11:30'"
sb_run "git log --oneline --since='3 hours ago'"
sb_run "git log --oneline --until=yesterday"
sb_run "git log --oneline --since=today"
sb_run "git log --oneline --since='2026-01-05 12:30' --until='2026-01-05 15:30'"
sb_run "git log --oneline --since=nonsense"
sb_run "git log --oneline --until=nonsense -2"
# One date in every accepted spelling; tail -1 prints the oldest commit it let in.
sb_run "git log --oneline --since='2026-01-05 13:00' | tail -1"
sb_run "git log --oneline --since='2026.01.05 13:00' | tail -1"
sb_run "git log --oneline --since='01/05/2026 13:00' | tail -1"
sb_run "git log --oneline --since='05.01.2026 13:00' | tail -1"
sb_run "git log --oneline --since='5 Jan 2026 13:00' | tail -1"
sb_run "git log --oneline --since='Mon, 5 Jan 2026 13:00:00 +0000' | tail -1"
sb_run "git log --oneline --since='@1767618000 +0000' | tail -1"
sb_run "git log --oneline --since=13:00 | tail -1"
sb_run "git log --oneline --since='2026-01-05 13:00 +0330' | tail -1"
sb_run "git log --oneline --since='2026-01-05T13:00:00+03:30' | tail -1"
sb_run "TZ=EST5 git log --oneline --since='2026-01-05 13:00' | tail -1"
sb_run "git log --oneline --since=noon | tail -1"
sb_run "git log --oneline --since='5 hours ago' | tail -1"
sb_run "git log --oneline --since=2026-01-05"
sb_run "git log --oneline --since='2026-01-05 00:00' | tail -1"
sb_write notes/extra.txt "x"
GIT_COMMITTER_DATE="2026-01-05 08:00:00 +0000" GIT_AUTHOR_DATE="2026-01-05 08:00:00 +0000" git add -A
GIT_COMMITTER_DATE="2026-01-05 08:00:00 +0000" GIT_AUTHOR_DATE="2026-01-05 08:00:00 +0000" git commit -q -m "A commit with a wrong clock"
git branch -q wrong-clock
git reset -q --hard HEAD~1
sb_run "git log --format='%h %cd %s' --date=iso -3 wrong-clock"
sb_run "git log --oneline --since='2026-01-05 12:00' wrong-clock"
sb_run "git log --oneline --since-as-filter='2026-01-05 12:00' wrong-clock"
sb_run "git log --oneline main wrong-clock | tail -2"
sb_run "git log --oneline --date-order main wrong-clock | head -2"

sb_say "--- L5. by author, committer and message ---"
sb_run "git log --oneline --author=Grace"
sb_run "git log --oneline --author=GRACE"
sb_run "git log --oneline --author=GRACE -i"
sb_run "git log --oneline --author=Grace --author=Alan"
sb_run "git log --oneline --committer=alan@"
sb_run "git log --oneline --grep=multiply"
sb_run "git log --oneline --grep='#12'"
sb_run "git log --oneline --grep=multiply --grep=divide"
sb_run "git log --oneline --grep=Refs --grep=wrong --all-match"
sb_run "git log --oneline --grep=Refs --invert-grep"
sb_run "git log --oneline --author=Ada --grep=Add"
sb_run "git log --oneline --grep='^Add'"
sb_run "git log --oneline --grep='^Refs'"
sb_run "git log --oneline -E --grep='(mul|div)'"
sb_run "git log --oneline --basic-regexp --grep='\(mul\|div\)'"
sb_run "git log --oneline --grep='(mul|div)'"
sb_run "git log --oneline --grep='sub.'"
sb_run "git log --oneline -F --grep='sub.'"
sb_run "git log --oneline -P --grep='(?i)DIVIDE'"

sb_say "--- L6. merges ---"
sb_run "git log --oneline --merges"
sb_run "git log --oneline --no-merges -4"
sb_run "git log --oneline --min-parents=2"
sb_run "git log --oneline --max-parents=1 -4"
sb_run "git log --oneline --max-parents=0"
sb_run "git log --oneline --max-parents=0 --no-max-parents -3"
sb_run "git log --oneline --max-parents=0 --max-parents=-1 -3"
sb_run "git log --oneline --min-parents=2 --no-min-parents -3"
sb_run "git log --oneline --min-parents=2 --min-parents=0 -3"
sb_run "git log --oneline --first-parent"
sb_fresh "$SANDBOX_ROOT/firstparent" >/dev/null
sb_write base.txt "base"
sb_commit "Base"
git switch -q -c topic
sb_write topic.txt "1"
sb_commit "Topic one"
sb_write topic.txt "2"
sb_commit "Topic two"
git switch -q main
sb_write main.txt "main"
sb_commit "Main work"
git merge -q --no-ff --no-edit topic >/dev/null
sb_tick
sb_run "git log --oneline --graph --all"
sb_run "git log --oneline main..topic"
sb_run "git log --oneline --exclude-first-parent-only main..topic"
back_to_calc

sb_say "--- L7. files ---"
sb_run "git log --oneline -- calc.py"
sb_run "git log --oneline calc.py README.md"
sb_run "git log --oneline tests_calc.py"
sb_run "git log --oneline --follow tests_calc.py"
sb_run "git log --oneline --follow tests_calc.py README.md"
sb_run "git -c log.follow=true log --oneline tests_calc.py"
sb_run "git log --oneline test_calc.py"
sb_run "git log --oneline -- test_calc.py"
sb_run "git log --oneline --diff-filter=A --name-only"
sb_run "git log --oneline --diff-filter=D --name-only"
sb_run "git log --oneline --diff-filter=R --name-status"
sb_run "git log --oneline --diff-filter=D --name-only --no-renames"
sb_run "git log --oneline -1 --stat -- README.md"
sb_run "git log --oneline -1 --stat --full-diff -- README.md"
sb_run "cd notes && git log --oneline . && cd .."
sb_fresh "$SANDBOX_ROOT/removeempty" >/dev/null
sb_write keep.txt "keep"
sb_write config.ini "first"
sb_commit "Add config"
git rm -q config.ini
sb_commit "Remove config"
sb_write config.ini "second"
sb_commit "Bring config back"
sb_run "git log --oneline -- config.ini"
sb_run "git log --oneline --remove-empty -- config.ini"
# A file renamed and half rewritten in the same commit, which --follow loses.
sb_fresh "$SANDBOX_ROOT/rewrite" >/dev/null
sb_write notes.txt one two three four five six seven eight nine ten
sb_commit "Add notes"
git mv notes.txt diary.txt
sb_write diary.txt one two three four five 6 7 8 9 10
sb_commit "Rename and rewrite half"
sb_run "git log --oneline --follow diary.txt"
sb_run "git log --oneline -1 --stat"
sb_run "git log --oneline --follow -M40% diary.txt"
back_to_calc

sb_say "--- L8. lines and functions ---"
sb_run "git log --oneline -L 5,6:calc.py"
sb_run "git log --oneline -L :sub:calc.py --no-patch"
sb_run "git log --oneline -L '/def mul/,+1:calc.py'"
sb_run "git log --oneline -L '/def mul/,+2:calc.py' --no-patch"
sb_run "git log --oneline -L :div:calc.py -L :add:calc.py --no-patch"
sb_run "git log --oneline -L :div:calc.py -L ^:add:calc.py --no-patch"
sb_run "git log --oneline -L :nosuch:calc.py"
sb_run "git log --oneline -L 5,6:calc.py -- README.md"
sb_run "git log --oneline -L 6,-2:calc.py"
sb_run "git log --oneline -L '/def mul/,/def div/:calc.py' --no-patch"
sb_run "git log --oneline -L :sub:calc.py --name-only"
sb_run "git log --oneline -L :sub:calc.py --no-patch --name-only"
sb_run "git log --oneline -L 5,6:calc.py --stat"
sb_run "git log --oneline -L 5,6:calc.py main feature"
sb_run "git log --oneline -L 20,30:calc.py"

sb_say "--- L8b. each commit's changes ---"
sb_run "git log --oneline -2 --stat"
sb_run "git log --oneline -1 -p"
sb_run "git log --oneline -1 --stat -s"
sb_run "git log --oneline -1 -s --stat"
sb_run "git log --oneline -1 -p --no-patch"
sb_run "git log --oneline -1 --raw"
sb_run "git log --oneline -1 --raw -t"
sb_run "git log --oneline -1 -p -q"

sb_say "--- L9. order ---"
sb_fresh "$SANDBOX_ROOT/order" >/dev/null
sb_write base.txt "base"
sb_commit "Base"
git switch -q -c left
sb_write left.txt "1"
sb_commit "Left one"
git switch -q -c right main
sb_write right.txt "1"
GIT_AUTHOR_DATE="2026-01-05 09:30:00 +0000" git add -A
GIT_AUTHOR_DATE="2026-01-05 09:30:00 +0000" git commit -q -m "Right one, written earlier"
sb_tick
git switch -q left
sb_write left.txt "2"
sb_commit "Left two"
git switch -q right
sb_write right.txt "2"
sb_commit "Right two"
git switch -q -c both left
git merge -q --no-edit right >/dev/null
sb_tick
sb_run "git log --graph --format='%h %ad %cd %s' --date=format:%H:%M"
sb_run "git log --format='%h %ad %cd %s' --date=format:%H:%M"
sb_run "git log --format='%h %ad %cd %s' --date=format:%H:%M --date-order"
sb_run "git log --format='%h %ad %cd %s' --date=format:%H:%M --author-date-order"
sb_run "git log --format='%h %ad %cd %s' --date=format:%H:%M --topo-order"
sb_run "git log --format='%h %s' --reverse"
back_to_calc

sb_say "--- L10. built-in formats ---"
for f in oneline short medium full fuller reference email mboxrd raw; do
	sb_run "git log -1 --pretty=$f main~1"
done
sb_run "git log -1 --pretty main~1"
sb_run "git log -2 --format=raw --abbrev-commit"
sb_run "git log -2 --oneline --no-abbrev-commit"
sb_run "git log -2 --oneline --abbrev=10"
sb_run "git log -2 --pretty=oneline"
sb_run "git log -2 --pretty=oneline --abbrev-commit"
sb_run "git -c log.abbrevCommit=true log -1 --pretty=oneline"
sb_run "git log -1 --format=fullest"
sb_run "git -c format.pretty=reference log -2"
sb_run "git -c pretty.changes='format:* %h %s (%an)' log -2 --pretty=changes"

sb_say "--- L11. format strings ---"
sb_run "git log -3 --format='%h %an <%ae> %s'"
sb_run "git log -2 --pretty=format:'%h %s' | cat -A; echo"
sb_run "git log -2 --pretty=tformat:'%h %s' | cat -A"
sb_run "git log -2 --format='%h %s' | cat -A"
sb_run "git log -1 --format='commit %H%ntree %T%nparents %P%nshort %h %t %p'"
sb_run "git log -1 --format='%an|%ae|%al|%ad|%aD|%ai|%aI|%as|%at|%ar|%ah' v1.0"
sb_run "git log -1 --format='%cn|%ce|%cl|%cd|%cD|%ci|%cI|%cs|%ct|%cr|%ch' v1.0"
sb_run "git log -1 --format='[%s]%n[%f]%n[%b]%n[%B]' v1.0"
sb_run "git log -1 --format='%d%n%D' v1.0"
sb_run "git log -4 --format='%h%d'"
sb_run "git log -1 --format='%(trailers)' v1.0"
sb_run "git log -1 --format='%(trailers:key=Refs)' v1.0"
sb_run "git log -1 --format='%(trailers:key=Refs,valueonly)' v1.0"
sb_run "git log -1 --format='%(trailers:keyonly,separator=%x2C )' v1.0"
sb_run "git log -1 --format='%(trailers:key_value_separator==)' v1.0"
sb_run "git log -1 --format='%(describe)'"
sb_run "git log -1 --format='%(describe:tags)'"
sb_run "git log -1 --format='%(describe:tags,abbrev=4)'"
sb_run "git log -1 --format='%(describe:tags,match=v1.0)'"
sb_run "git log -1 --format='%(describe:tags,exclude=v1.1)'"
sb_run "git log -1 --format='[%(describe)]' v1.0~2"
sb_run "git log -2 --format='%h%(decorate)'"
sb_run "git log -2 --format='%h%(decorate:prefix=[,suffix=],separator=%x2C,tag=)'"
sb_run "git log -1 --format='%h%(decorate:pointer=>)'"
sb_run "git log -2 --source --all --format='%h %S %s'"
sb_run "git log -2 --oneline --source --all"
sb_run "git log -3 --format='%h %<(22)%s|%an'"
sb_run "git log -3 --format='%h %<(12,trunc)%s|'"
sb_run "git log -3 --format='%h %<(12,ltrunc)%s|'"
sb_run "git log -3 --format='%h %<(12,mtrunc)%s|'"
sb_run "git log -3 --format='%h %>(22)%s|'"
sb_run "git log -3 --format='%h %><(22)%s|'"
sb_run "git log -3 --format='%<|(12)%h|%s'"
sb_run "git log -3 --format='%h %>|(30)%s|'"
sb_run "git log -3 --format='%h %><|(30)%s|'"
sb_run "git log -3 --format='%<(12)%h%>(8)%s|'"
sb_run "git log -3 --format='%<(12)%h%>>(8)%s|'"
sb_run "git log -1 --format='%w(30,0,4)%B' v1.0"
sb_run "git log -3 --format='%h%+b'"
sb_run "git log -3 --format='%s%n%-b'"
sb_run "git log -3 --format='%h% d'"
sb_run "git log -1 --format='100%% %x41%x42'"
sb_run "git log --format='%h %e %s' -1"
sb_run "git log -1 --format='%Cred%h%Creset %Cgreen%s%Creset' | cat -A"
sb_run "git log -1 --format='%C(always,yellow)%h%C(reset) %s' | cat -A"
sb_run "git log -1 --color=always --format='%C(auto)%h%d %s' | cat -A"
# A message whose trailer block also holds a line that is not a trailer, and a
# trailer folded over two lines. Committed without a tick and removed again, so
# nothing after it changes.
printf 'Trailer demo\n\nBody.\n\nRefs: #12\nsee also the wiki\nSigned-off-by: Ada Lovelace\n  <ada@example.com>\n' > "$SANDBOX_ROOT/msg"
git commit -q --allow-empty -F "$SANDBOX_ROOT/msg"
sb_run "git log -1 --format=%B"
sb_run "git log -1 --format='%(trailers)'"
sb_run "git log -1 --format='%(trailers:only)'"
sb_run "git log -1 --format='%(trailers:key=signed-off-by)'"
sb_run "git log -1 --format='%(trailers:key=Refs,only=false)'"
sb_run "git log -1 --format='%(trailers:unfold)'"
git reset -q --hard HEAD~1

sb_say "--- L12. dates ---"
for d in default relative local iso iso8601 iso-strict iso8601-strict rfc rfc2822 short raw human unix; do
	sb_run "git log -1 --format=%ad --date=$d"
done
sb_run "git log -2 --format='%ad' --date=iso"
sb_run "git log -2 --format='%ad' --date=iso-local"
sb_run "git log -2 --format='%ad' --date=raw-local"
sb_run "git log -1 --format='%ad' --date=format:'%A %d %B %Y, %H:%M'"
sb_run "git log -2 --format='%ad' --date=format-local:'%H:%M %z'"
sb_run "git log -1 --format=%ad --relative-date"
sb_run "git log -1 --date=bogus"
sb_run "git log -1 | grep Date"
sb_run "git -c log.date=short log -1 | grep Date"
sb_run "git -c log.date=auto:short log -1 | grep Date"

sb_say "--- L13. decorations ---"
sb_run "git log --oneline --decorate -3"
sb_run "git log --oneline --decorate=short -2"
sb_run "git log --oneline --decorate=full -2"
sb_run "git log --oneline --decorate=no -2"
sb_run "git log --oneline --no-decorate -2"
sb_run "git log --oneline --decorate=auto -2"
sb_run "git -c log.decorate=full log --oneline -2"
sb_run "git log --oneline --decorate --decorate-refs=refs/tags -6"
sb_run "git log --oneline --decorate --decorate-refs-exclude=refs/tags -6"
sb_run "git -c log.excludeDecoration=refs/remotes log --oneline --decorate -6 v1.0"
sb_run "git -c log.excludeDecoration=refs/remotes log --oneline --decorate --decorate-refs=refs/remotes -6 v1.0"
git update-ref refs/notes/example HEAD
sb_run "git log --oneline -1 --decorate"
sb_run "git log --oneline -1 --decorate --clear-decorations"
sb_run "git log --oneline -1 --decorate --decorate-refs=refs/tags --clear-decorations"
sb_run "git -c log.initialDecorationSet=all log --oneline -1 --decorate"
sb_run "git log --oneline --simplify-by-decoration --all"

sb_say "--- L14. the graph ---"
sb_run "git log --oneline --graph --all"
sb_run "git log --graph -3 --format='%h %s'"
sb_run "git log --oneline --graph --no-walk"
sb_run "git log --oneline --parents -4"
sb_run "git log --oneline --children -4"
sb_run "git log --oneline --show-linear-break --all"
sb_run "git log --oneline --show-linear-break='  ~~~' --all -8"
sb_run_ansi "git log --oneline --graph --decorate --all -9"

sb_say "--- L15. merges and their changes ---"
sb_fresh "$SANDBOX_ROOT/merges" >/dev/null
ada
sb_write greeting.txt "hello" "world" 3 4 5 6 7 8 9 10 11 "end"
sb_commit "Base"
git switch -q -c side
sb_write greeting.txt "hello" "planet" 3 4 5 6 7 8 9 10 11 "the end"
sb_commit "Say planet"
git switch -q main
sb_write greeting.txt "hi" "world" 3 4 5 6 7 8 9 10 11 "end"
sb_commit "Say hi"
git merge -q side >/dev/null 2>&1
sb_write greeting.txt "hi" "planet and world" 3 4 5 6 7 8 9 10 11 "the end"
git add greeting.txt
git commit -q -m "Merge branch 'side'"
sb_tick
sb_run "git log --oneline --graph"
sb_run "git log -p -1"
sb_run "git log -p -m -1"
sb_run "git log -m -1 --oneline"
sb_run "git log -1 --oneline --diff-merges=off -p"
sb_run "git log -1 --oneline --diff-merges=first-parent -p"
sb_run "git log -1 --oneline --dd"
sb_run "git log -1 --oneline --diff-merges=combined -p"
sb_run "git log -1 --oneline --cc"
sb_run "git log -1 --oneline --remerge-diff"
sb_run "git log -1 --oneline --diff-merges=none -p"
sb_run "git log -1 --oneline --no-diff-merges -p"
sb_run "git log -1 --oneline --diff-merges=on -p"
# Every other spelling, compared with the one shown, rather than printed again.
sb_run "diff <(git log -1 --diff-merges=on -p) <(git log -1 -m -p) && echo same"
sb_run "diff <(git log -1 --diff-merges=on -p) <(git log -1 --diff-merges=m -p) && echo same"
sb_run "diff <(git log -1 --diff-merges=on -p) <(git log -1 --diff-merges=separate -p) && echo same"
sb_run "diff <(git log -1 --dd) <(git log -1 --diff-merges=1 -p) && echo same"
sb_run "diff <(git log -1 --diff-merges=combined -p) <(git log -1 --diff-merges=c -p) && echo same"
sb_run "diff <(git log -1 --diff-merges=combined -p) <(git log -1 -c) && echo same"
sb_run "diff <(git log -1 --cc) <(git log -1 --diff-merges=dense-combined -p) && echo same"
sb_run "diff <(git log -1 --cc) <(git log -1 --diff-merges=cc -p) && echo same"
sb_run "diff <(git log -1 --remerge-diff) <(git log -1 --diff-merges=remerge -p) && echo same"
sb_run "diff <(git log -1 --remerge-diff) <(git log -1 --diff-merges=r -p) && echo same"
sb_run "git -c log.diffMerges=first-parent log -1 --oneline -m -p"
sb_run "git log --oneline --first-parent -p -1"
sb_run "git log -1 --oneline --diff-merges=bogus -p"
sb_run "git log -2 --oneline --diff-merges=first-parent"
sb_run "git log -2 --oneline --dd"
git switch -q -c renamer HEAD~2
git mv greeting.txt hello.txt
sb_commit "Rename greeting"
git switch -q main
git merge -q --no-edit renamer
sb_tick
sb_run "git log -1 --format=%h -c --name-status -M"
sb_run "git log -1 --format=%h -c --name-status -M --combined-all-paths"
sb_run "git log --stat --format='%h %s' --max-parents=0"
sb_run "git -c log.showRoot=false log --stat --format='%h %s' --max-parents=0"

sb_say "--- L16. simplified history ---"
sb_fresh "$SANDBOX_ROOT/simplify" >/dev/null
ada
sb_write file.txt "base"
sb_write other.txt "other"
sb_commit "Base"
git switch -q -c topic
sb_write file.txt "topic version"
sb_commit "Change file on topic"
git switch -q main
sb_write other.txt "other, changed"
sb_commit "Change other on main"
git merge -q --no-edit topic
sb_tick
git switch -q -c lost HEAD
sb_write file.txt "a change that a merge will throw away"
sb_commit "Change file on lost"
git switch -q main
git merge -q --no-edit -s ours lost
sb_tick
sb_run "git log --oneline --graph --all"
sb_run "git log --oneline -- file.txt"
sb_run "git log --oneline --full-history -- file.txt"
sb_run "git log --oneline --graph --full-history -- file.txt"
sb_run "git log --oneline --graph --full-history --simplify-merges -- file.txt"
sb_run "git log --oneline --show-pulls -- file.txt"
sb_run "git log --oneline --sparse -- file.txt"
sb_run "git log --oneline --full-history --sparse -- file.txt"
sb_run "git log --oneline --dense -- file.txt"
sb_run "git log --oneline topic..main"
sb_run "git log --oneline --ancestry-path topic..main"
sb_run "git log --oneline --ancestry-path=lost topic..main"

sb_say "--- L17. other options ---"
back_to_calc
sb_run "git log -1 --log-size --format='%h %s'"
sb_run "git log -1 --log-size v1.0"
printf 'Tabs\n\n\tindented\twith\ttabs\n' > "$SANDBOX_ROOT/msg"
git commit -q --allow-empty -F "$SANDBOX_ROOT/msg"
sb_tick
sb_run "git log -1 | cat -A"
sb_run "git log -1 --expand-tabs=4 | cat -A"
sb_run "git log -1 --no-expand-tabs | cat -A"
sb_run "git log -1 --expand-tabs | cat -A"
git reset -q --hard HEAD~1
printf 'caf\351 au lait\n' > "$SANDBOX_ROOT/latin1"
git -c i18n.commitEncoding=ISO-8859-1 commit -q --allow-empty -F "$SANDBOX_ROOT/latin1"
sb_tick
sb_run "git cat-file commit HEAD | tail -3 | cat -A"
sb_run "git log -1 --format='%e %s' | cat -A"
sb_run "git log -1 --format=%s --encoding=ISO-8859-1 | cat -A"
git reset -q --hard HEAD~1
sb_write .mailmap "Grace Hopper <grace@example.com> Grace H <grace@old.example>"
GIT_AUTHOR_NAME="Grace H" GIT_AUTHOR_EMAIL="grace@old.example" git commit -q --allow-empty -m "Commit with an old address"
sb_tick
sb_run "cat .mailmap"
sb_run "git log -1 --format='%an <%ae> | %aN <%aE>'"
sb_run "git log -1 | grep Author"
sb_run "git log -1 --no-mailmap | grep Author"
sb_run "git log -1 --no-use-mailmap | grep Author"
sb_run "git -c log.mailmap=false log -1 | grep Author"
sb_run "git -c log.mailmap=false log -1 --mailmap | grep Author"
sb_run "git -c log.mailmap=false log -1 --use-mailmap | grep Author"
sb_run "git log -1 --no-mailmap --format='%an | %aN'"
git reset -q --hard HEAD~1
rm -f .mailmap
git clone -q --shared --single-branch --no-tags . "$SANDBOX_ROOT/borrower"
sb_run "cd ../borrower"
cd ../borrower
sb_run "git log --oneline --all --no-walk"
sb_run "git log --oneline --all --no-walk --alternate-refs"
sb_run "cd ../calc"
cd ../calc
sb_run "git log --oneline --all --no-walk"
sb_run "git -c transfer.hideRefs=refs/tags log --oneline --exclude-hidden=fetch --all --no-walk"
sb_run "git -c uploadpack.hideRefs=refs/tags log --oneline --exclude-hidden=uploadpack --all --no-walk"
sb_run "git -c uploadpack.hideRefs=refs/tags log --oneline --exclude-hidden=receive --all --no-walk"
for i in 1 2 3 4; do git branch -q "lane$i" "main~$i" 2>/dev/null; done
for i in 1 2 3 4; do git switch -q "lane$i" && sb_write "lane$i.txt" "$i" && sb_commit "Work on lane $i"; done
git switch -q main
sb_run "git log --oneline --graph --branches='lane*' -8"
sb_run "git log --oneline --graph --branches='lane*' -8 --graph-lane-limit=2"
