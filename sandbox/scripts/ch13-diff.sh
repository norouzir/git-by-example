#!/bin/bash
# Generates every transcript in Chapter 13, "diff".
#
#   bash sandbox/scripts/ch13-diff.sh [dir]
#
# The questions this chapter answers are listed in the chapter itself, at the
# top of book/part-02-everyday-work/13-diff.md, and that list is the only copy.
# tools/verify_transcripts.py ties every transcript in the chapter to the output
# of this script, so no mapping between questions and sections is kept here.
#
# No -e here on purpose: many examples in this chapter are about exit codes,
# and a non-zero exit is the answer being demonstrated, not a failure.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/diffing" >/dev/null

sb_write story.txt "Once upon a time" "there was a repository." "It had many commits." "The end."
sb_write config.ini "debug = false" "port = 8080"
sb_commit "Add story and config"

sb_say "--- 1. reading a diff ---"
sb_write story.txt "Once upon a time" "there was a git repository." "It had many commits." "The end."
sb_run git diff

sb_say "--- 2. the header lines decoded ---"
sb_run "git diff | head -5"
sb_run "git rev-parse :story.txt"
sb_run "git hash-object story.txt"

sb_say "--- 3. how much context ---"
sb_run "git diff -U1"
sb_run "git diff -U0"
sb_run "git diff --unified=3 | head -4"

sb_say "--- 4. summaries instead of content ---"
sb_write config.ini "debug = true" "port = 8080" "timeout = 30"
sb_run git diff --stat
sb_run git diff --numstat
sb_run git diff --shortstat
sb_run git diff --name-only
sb_run git diff --name-status
sb_run git diff --summary

sb_say "--- 5. word level ---"
sb_run "git diff --word-diff story.txt"
sb_run "git diff --word-diff=porcelain story.txt"

sb_say "--- 6. comparing things other than the working tree ---"
git add -A && git commit -q -m "Tell a git story" && sb_tick
sb_write story.txt "Once upon a time" "there was a git repository." "It had many commits." "It had branches too." "The end."
sb_commit "Mention branches"
sb_run git diff HEAD~2 HEAD --stat
sb_run "git diff HEAD~2..HEAD --stat"
sb_run "git diff HEAD~2 HEAD -- story.txt"

sb_say "--- 7. two dots and three dots are not the same ---"
git switch -q -c feature HEAD~2
sb_write feature.txt "new feature"
sb_commit "Add a feature"
git switch -q main
sb_run git log --oneline --all --graph
sb_run "git diff main..feature --name-status"
sb_run "git diff main...feature --name-status"
sb_run git merge-base main feature
sb_run "git diff --merge-base main feature --name-status"

sb_say "--- 8. searching diffs for content ---"
sb_run "git log -S 'branches' --oneline"
sb_run "git log -G 'debug' --oneline"
sb_run "git log --oneline -- config.ini"

sb_say "--- 10. renames ---"
git mv story.txt tale.txt
sb_run git diff --cached --stat
sb_run "git diff --cached -M --name-status"
sb_run "git diff --cached --no-renames --name-status"
sb_run git restore --staged --worktree .

sb_say "--- 12. diffing files Git does not track ---"
cd "$SANDBOX_ROOT"
printf 'alpha\nbravo\n' > one.txt
printf 'alpha\ncharlie\n' > two.txt
sb_run "git diff --no-index one.txt two.txt"
sb_run "git diff --no-index --stat one.txt two.txt"
cd "$SANDBOX_ROOT/diffing"

sb_say "--- 13. exit codes for scripts ---"
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
sb_write story.txt "changed"
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
sb_run "git diff --exit-code --stat || echo '(exit was non-zero)'"
sb_run git checkout -q -- story.txt
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
sb_write brand-new.txt "never added"
sb_run "git diff --quiet && echo 'clean (exit 0)' || echo 'dirty (exit 1)'"
sb_run git status --short
rm -f brand-new.txt

# =============================================================================
sb_say "--- N1. git diff and the diff command ---"
sb_fresh "$SANDBOX_ROOT/neighbours" >/dev/null
sb_write story.txt "Once upon a time" "there was a repository." "The end."
sb_write extra.txt "a file that will be renamed"
sb_commit "Add story"
sb_write story.txt "Once upon a time" "there was a git repository." "The end."
touch -d "@1767603600" story.txt

sb_say "    plain diff wants two files"
sb_run "diff -u story.txt"
sb_run "git show HEAD:story.txt > ../story-committed.txt"
touch -d "@1767600000" ../story-committed.txt
sb_run "diff -u ../story-committed.txt story.txt"
sb_run "git diff"

sb_say "    exit codes"
sb_run "diff -u ../story-committed.txt story.txt > /dev/null; echo exit=\$?"
sb_run "git diff > /dev/null; echo exit=\$?"
sb_run "git diff --exit-code > /dev/null; echo exit=\$?"

sb_say "    inside a repository, two paths are a pathspec"
git checkout -q -- story.txt
sb_write draft-one.txt "alpha" "bravo"
sb_write draft-two.txt "alpha" "charlie"
sb_commit "Add two drafts"
sb_run "git diff draft-one.txt draft-two.txt; echo exit=\$?"
sb_run "git diff --no-index draft-one.txt draft-two.txt; echo exit=\$?"

sb_say "    outside a repository, --no-index is implied"
mkdir -p "$SANDBOX_ROOT/outside"
cd "$SANDBOX_ROOT/outside"
export GIT_CEILING_DIRECTORIES="$SANDBOX_ROOT"
printf 'alpha\nbravo\n' > one.txt
printf 'alpha\ncharlie\n' > two.txt
sb_run "git rev-parse --is-inside-work-tree"
sb_run "git diff one.txt two.txt; echo exit=\$?"
unset GIT_CEILING_DIRECTORIES
cd "$SANDBOX_ROOT/neighbours"

sb_say "    the patch command can apply git diff output"
sb_write story.txt "Once upon a time" "there was a git repository." "The end."
git mv extra.txt renamed.txt
git add -A
sb_run "git diff --staged > ../change.diff"
sb_run "cat ../change.diff"
sb_run "git reset -q --hard"
sb_run "patch -p1 < ../change.diff"
sb_run git status --short

# =============================================================================
sb_say "--- N2. extended headers and hunk headers ---"
sb_fresh "$SANDBOX_ROOT/headers" >/dev/null
sb_write gone.txt "about to be deleted"
sb_write run.sh "#!/bin/sh" "echo hi"
sb_write tail.txt "ends with a newline"
sb_write mover.txt "line 1" "line 2" "line 3" "line 4" "line 5" "line 6" "line 7" "line 8" "line 9" "line 10"
sb_commit "Starting point"
sb_write new.txt "brand new"
git add new.txt
git rm -q gone.txt
git update-index --chmod=+x run.sh
printf 'no newline at the end' > tail.txt
git add tail.txt
git mv mover.txt moved.txt
sb_write moved.txt "line 1" "line 2" "line 3" "line 4" "line 5" "line 6" "line 7" "line 8" "line 9" "line ten"
git add moved.txt
sb_run "git diff --staged -- new.txt"
sb_run "git diff --staged -- gone.txt"
sb_run "git diff --staged -- run.sh"
sb_run "git diff --staged -- tail.txt"
sb_run "git diff --staged -- mover.txt moved.txt"

sb_say "    the function name after @@, and -W"
sb_fresh "$SANDBOX_ROOT/funcname" >/dev/null
sb_write prices.py "def total(items):" "    subtotal = 0" "    count = 0" "    for item in items:" "        subtotal += item.price" "        count += 1" "    if count == 0:" "        return 0" "    tax = subtotal * 0.2" "    return subtotal + tax" "" "def describe(item):" "    return item.name"
sb_commit "Add prices"
sb_write prices.py "def total(items):" "    subtotal = 0" "    count = 0" "    for item in items:" "        subtotal += item.price" "        count += 1" "    if count == 0:" "        return 0" "    tax = subtotal * 0.25" "    return subtotal + tax" "" "def describe(item):" "    return item.name"
sb_run git diff
sb_run "git diff -W"
sb_run "git diff --function-context -U0"

sb_say "    merging nearby hunks"
sb_fresh "$SANDBOX_ROOT/hunks" >/dev/null
sb_write n.txt 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
sb_commit "Numbers"
sb_write n.txt 1 2 THREE 4 5 6 7 8 9 10 11 TWELVE 13 14 15 16 17 18 19 20
sb_run git diff
sb_run "git diff --inter-hunk-context=2"

# =============================================================================
sb_say "--- N3. choosing what to compare ---"
sb_fresh "$SANDBOX_ROOT/sources" >/dev/null
sb_write a.txt "version one"
sb_commit "One"
sb_write a.txt "version two"
sb_commit "Two"
sb_write a.txt "version three"
sb_run "git diff HEAD~1"
sb_run "git add a.txt && git diff --staged HEAD~1"
sb_run "git diff -R HEAD~1 --staged"

sb_say "    one file between commits, and two different files"
sb_write b.txt "a different file"
sb_commit "Three, plus b"
sb_run "git diff HEAD~2:a.txt HEAD:a.txt"
sb_run "git diff HEAD:a.txt HEAD:b.txt"

sb_say "    --relative"
sb_write sub/inner.txt "inside"
sb_write outer.txt "outside"
sb_commit "Add sub"
sb_write sub/inner.txt "inside, changed"
sb_write outer.txt "outside, changed"
cd sub
sb_run "git diff --stat"
sb_run "git diff --relative --stat"
cd ..
git checkout -q -- .

sb_say "    new files are invisible to git diff"
sb_write brand-new.txt "not added yet"
sb_run "git diff --stat"
sb_run "git status --short"
sb_run "git add -N brand-new.txt && git diff --stat"

sb_say "    before the first commit"
sb_fresh "$SANDBOX_ROOT/unborn" >/dev/null
sb_write first.txt "the very first file"
git add first.txt
sb_run "git diff --staged"
sb_run "git diff HEAD; echo exit=\$?"

# =============================================================================
sb_say "--- N4. git diff, git show and git log -p ---"
sb_fresh "$SANDBOX_ROOT/showlog" >/dev/null
sb_write poem.txt "roses are red"
sb_commit "First"
sb_write poem.txt "roses are red" "violets are blue"
sb_commit "Second"
sb_run "git diff HEAD~1 HEAD"
sb_run "git show HEAD"
sb_run "git log -p -1"
sb_run "git show --format= HEAD"

sb_say "    the first commit has no parent to compare with"
sb_run "git diff HEAD~2 HEAD~1; echo exit=\$?"
sb_run "git show --stat --oneline HEAD~1"
sb_run "git diff 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD~1 --stat"

# =============================================================================
sb_say "--- N5. summaries ---"
sb_fresh "$SANDBOX_ROOT/summaries" >/dev/null
sb_write gone.txt "about to be deleted"
sb_write run.sh "#!/bin/sh"
sb_write mover.txt "line 1" "line 2" "line 3" "line 4" "line 5"
sb_commit "Starting point"
sb_write new.txt "brand new"
git rm -q gone.txt
git update-index --chmod=+x run.sh
git mv mover.txt moved.txt
git add -A
sb_run "git diff --staged --stat"
sb_run "git diff --staged --summary"
sb_run "git diff --staged --compact-summary"

sb_say "    what is scaled in --stat"
sb_fresh "$SANDBOX_ROOT/scaling" >/dev/null
seq 1 300 > big.txt
printf 'a\nb\n' > small.txt
sb_commit "Big and small"
seq 1 300 | sed 's/$/ changed/' > big.txt
printf 'a\nB\n' > small.txt
sb_run "git diff --stat"
sb_run "git diff --numstat"
sb_run "git diff --stat=50"
sb_run "git diff --stat --stat-count=1"

sb_say "    --dirstat"
sb_fresh "$SANDBOX_ROOT/dirstat" >/dev/null
mkdir -p src docs
seq 1 100 > src/core.txt
seq 1 100 > docs/guide.txt
sb_commit "Tree"
seq 1 100 | sed '1,30s/$/ edited/' > src/core.txt
seq 1 100 | sed '1,10s/$/ edited/' > docs/guide.txt
sb_run "git diff --dirstat"
sb_run "git diff --dirstat=lines"

sb_say "    --dirstat parameters"
sb_fresh "$SANDBOX_ROOT/dirstat-params" >/dev/null
mkdir -p src/core src/ui docs
seq 1 100 > src/core/a.txt
seq 1 100 > src/core/b.txt
seq 1 100 > src/ui/c.txt
seq 1 100 > docs/d.txt
seq 1 100 > top.txt
sb_commit "Tree"
seq 1 100 | sed '1,40s/$/ e/' > src/core/a.txt
seq 1 100 | sed '1,40s/$/ e/' > src/core/b.txt
seq 1 100 | sed '1,5s/$/ e/' > src/ui/c.txt
seq 1 100 | sed '1,3s/$/ e/' > docs/d.txt
seq 1 100 | sed '1s/$/ e/' > top.txt
sb_run "git diff --stat"
sb_run "git diff --dirstat"
sb_run "git diff --dirstat=files"
sb_run "git diff --dirstat=cumulative"
sb_run "git diff --dirstat=files,cumulative"
sb_run "git diff --dirstat=10"

# =============================================================================
sb_say "--- N6. word diffs ---"
sb_fresh "$SANDBOX_ROOT/words" >/dev/null
sb_write call.c "result = compute(alpha, beta);"
sb_commit "Add call"
sb_write call.c "result = compute(alpha, gamma);"
sb_run "git diff --word-diff"
sb_run "git diff --word-diff --word-diff-regex='[A-Za-z]+|[^[:space:]]'"
sb_run_ansi "git diff --color-words"
sb_run_ansi "git diff --word-diff=color"
sb_run "git diff --word-diff=plain > ../a.diff; git diff --word-diff > ../b.diff; cmp ../a.diff ../b.diff && echo same"
sb_run "git diff --word-diff=none > ../a.diff; git diff > ../b.diff; cmp ../a.diff ../b.diff && echo same"

# =============================================================================
sb_say "--- N7. -S and -G ---"
sb_fresh "$SANDBOX_ROOT/pickaxe" >/dev/null
sb_write lib.c "int main() {" "    frotz(nitfol, one);" "}"
sb_commit "Add the call"
sb_write lib.c "int main() {" "    frotz(nitfol, two);" "}"
sb_commit "Change the argument"
sb_write lib.c "int main() {" "}"
sb_commit "Remove the call"
sb_run "git log --oneline"
sb_run "git log -S 'frotz(nitfol' --oneline"
sb_run "git log -G 'frotz\\(nitfol' --oneline"
sb_run "git log -S 'frotz\\(nit+' --pickaxe-regex --oneline"

sb_say "    --pickaxe-all"
sb_write lib.c "int main() {" "    frotz(nitfol, three);" "}"
sb_write notes.txt "an unrelated note"
sb_commit "Bring the call back, and add a note"
sb_run "git log -S frotz --oneline --name-only -1"
sb_run "git log -S frotz --pickaxe-all --oneline --name-only -1"

sb_say "    -S also filters git diff"
sb_run "git diff HEAD~1 HEAD --name-only"
sb_run "git diff HEAD~1 HEAD --name-only -S frotz"

sb_say "    a line that only moves, within one file and between files"
sb_fresh "$SANDBOX_ROOT/pickaxe-moved" >/dev/null
sb_write lib.c "int main() {" "    frotz(nitfol, one);" "}" "" "void other() {" "}"
sb_commit "Add the call"
sb_write lib.c "int main() {" "}" "" "void other() {" "    frotz(nitfol, one);" "}"
sb_commit "Move the call into other"
sb_run "git log --oneline"
sb_run "git log -S 'frotz(nitfol' --oneline"
sb_run "git log -G 'frotz\\(nitfol' --oneline"
sb_fresh "$SANDBOX_ROOT/pickaxe-moved-files" >/dev/null
sb_write a.c "int main() {" "    frotz(nitfol, one);" "}"
sb_write b.c "void other() {" "}"
sb_commit "Add the call"
sb_write a.c "int main() {" "}"
sb_write b.c "void other() {" "    frotz(nitfol, one);" "}"
sb_commit "Move the call to another file"
sb_run "git log -S 'frotz(nitfol' --oneline --name-status"

# =============================================================================
sb_say "--- N8. whitespace ---"
sb_fresh "$SANDBOX_ROOT/ws" >/dev/null
sb_write spacing.txt "hello world" "a b" "end"
sb_commit "Add spacing"
printf 'helloworld\na    b\nend   \n' > spacing.txt
sb_run "git diff"
sb_run "git diff -b"
sb_run "git diff -w"
sb_run "git diff --ignore-space-at-eol"

sb_say "    ignoring whitespace does not change what is committed"
sb_run "git diff -w --stat"
sb_run "git diff --stat"
sb_run "git commit -qam 'Respace' && git show --stat --oneline HEAD"
sb_tick

sb_say "    blank lines"
sb_write blank.txt "one" "two"
sb_commit "Add blank.txt"
printf 'one\n\n\ntwo\n' > blank.txt
sb_run "git diff blank.txt"
sb_run "git diff --ignore-blank-lines blank.txt"
git checkout -q -- blank.txt

sb_say "    carriage returns"
sb_write endings.txt "one" "two"
sb_commit "Add endings.txt"
printf 'one\r\ntwo\r\n' > endings.txt
sb_run "git diff endings.txt | cat -A"
sb_run "git diff --ignore-cr-at-eol endings.txt"
git checkout -q -- endings.txt

sb_say "    whitespace errors"
sb_write check.txt "clean line"
sb_commit "Add check.txt"
printf 'clean line\ntrailing spaces   \n  \tspace before tab\n' > check.txt
sb_run "git diff --check; echo exit=\$?"
sb_run_ansi "git diff check.txt"

# =============================================================================
sb_say "--- N9. rename thresholds and copies ---"
sb_fresh "$SANDBOX_ROOT/renames" >/dev/null
seq 1 20 > orig.txt
sb_commit "Add orig.txt"
git mv orig.txt moved.txt
seq 1 20 | awk 'NR<=12{print} NR>12{print $0" edited"}' > moved.txt
git add -A
sb_run "git diff --staged --name-status"
sb_run "git diff --staged -M5 --name-status"
sb_run "git diff --staged -M05 --name-status"
sb_run "git diff --staged -M50% --name-status"

sb_say "    exact renames only"
sb_fresh "$SANDBOX_ROOT/exact" >/dev/null
seq 1 20 > before.txt
sb_commit "Add before.txt"
git mv before.txt after.txt
seq 1 20 | sed '20s/$/ edited/' > after.txt
git add -A
sb_run "git diff --staged --name-status"
sb_run "git diff --staged -M100% --name-status"

sb_say "    copies"
sb_fresh "$SANDBOX_ROOT/copies" >/dev/null
seq 1 30 > template.txt
seq 100 130 > other.txt
sb_commit "Add template and other"
cp template.txt copy-of-template.txt
seq 100 130 > copy-of-other.txt
echo "tweak" >> other.txt
git add -A
sb_run "git diff --staged --name-status"
sb_run "git diff --staged -C --name-status"
sb_run "git diff --staged -C --find-copies-harder --name-status"

# =============================================================================
sb_say "--- N10. moved code ---"
sb_fresh "$SANDBOX_ROOT/moved" >/dev/null
sb_write m.py "def alpha():" "    return \"first function body\"" "" "def beta():" "    return \"second function body\"" "" "def gamma():" "    return \"third function body\""
sb_commit "Add m.py"
sb_write m.py "def beta():" "    return \"second function body\"" "" "def gamma():" "    return \"third function body\"" "" "def alpha():" "    return \"first function body\""
sb_run_ansi "git diff"
sb_run_ansi "git diff --color-moved"

sb_say "    the modes: plain, zebra, dimmed-zebra, default"
sb_fresh "$SANDBOX_ROOT/moved-modes" >/dev/null
sb_write f.txt "alpha one alpha one alpha" "alpha two alpha two alpha" "stays put number one here" "stays put number two here" "stays put number three here" "bravo one bravo one bravo" "bravo two bravo two bravo" "stays put number four here" "stays put number five here" "stays put number six here" "end"
sb_commit "Add f.txt"
sb_write f.txt "stays put number one here" "stays put number two here" "stays put number three here" "stays put number four here" "stays put number five here" "stays put number six here" "bravo one bravo one bravo" "bravo two bravo two bravo" "alpha one alpha one alpha" "alpha two alpha two alpha" "end"
sb_run_ansi "git diff --color-moved=no"
sb_run_ansi "git diff --color-moved=plain"
sb_run_ansi "git diff --color-moved=zebra"
sb_run_ansi "git diff --color-moved=dimmed-zebra"
sb_run_ansi "git diff --color-moved=default > ../a.diff; git diff --color-moved=zebra > ../b.diff; cmp ../a.diff ../b.diff && echo same"

sb_say "    the modes: plain against blocks"
sb_fresh "$SANDBOX_ROOT/moved-blocks" >/dev/null
sb_write s.txt "x = 1" "a long enough line of real content here" "another long line of genuine content" "y = 2"
sb_commit "Add s.txt"
sb_write s.txt "a long enough line of real content here" "another long line of genuine content" "y = 2" "x = 1"
sb_run_ansi "git diff --color-moved=plain"
sb_run_ansi "git diff --color-moved=blocks"

# =============================================================================
sb_say "--- N11. algorithms ---"
sb_fresh "$SANDBOX_ROOT/algorithms" >/dev/null
cat > frob.c <<'EOF'
#include <stdio.h>

// Frobs foo heartily
int frobnitz(int foo)
{
    int i;
    for(i = 0; i < 10; i++)
    {
        printf("Your answer is: ");
        printf("%d\n", foo);
    }
}

int fact(int n)
{
    if(n > 1)
    {
        return fact(n-1) * n;
    }
    return 1;
}

int main(int argc, char **argv)
{
    frobnitz(fact(10));
}
EOF
sb_commit "Add frob.c"
cat > frob.c <<'EOF'
#include <stdio.h>

int fib(int n)
{
    if(n > 2)
    {
        return fib(n-1) + fib(n-2);
    }
    return 1;
}

// Frobs foo heartily
int frobnitz(int foo)
{
    int i;
    for(i = 0; i < 10; i++)
    {
        printf("%d\n", foo);
    }
}

int main(int argc, char **argv)
{
    frobnitz(fib(10));
}
EOF
sb_run "git diff --diff-algorithm=myers"
sb_run "git diff --diff-algorithm=histogram"
sb_run "git diff --minimal > ../a.diff; git diff --diff-algorithm=myers > ../b.diff; cmp ../a.diff ../b.diff && echo same"
sb_run "git diff --patience > ../a.diff; git diff --histogram > ../b.diff; cmp ../a.diff ../b.diff && echo same"

sb_say "    --anchored"
sb_fresh "$SANDBOX_ROOT/anchored" >/dev/null
sb_write fruit.txt "apple" "banana" "cherry"
sb_commit "Add fruit"
sb_write fruit.txt "cherry" "apple" "banana"
sb_run "git diff"
sb_run "git diff --anchored=cherry"

# =============================================================================
sb_say "--- N12. --diff-filter ---"
sb_fresh "$SANDBOX_ROOT/filter" >/dev/null
sb_write keep.txt "untouched"
sb_write edit.txt "before"
sb_write remove.txt "doomed"
sb_commit "Three files"
sb_write edit.txt "after"
rm remove.txt
sb_write add.txt "new"
git add -A
sb_run "git diff --staged --name-status"
sb_run "git diff --staged --name-status --diff-filter=A"
sb_run "git diff --staged --name-status --diff-filter=D"
sb_run "git diff --staged --name-status --diff-filter=AD"
sb_run "git diff --staged --name-status --diff-filter=d"

sb_say "    the other letters"
sb_fresh "$SANDBOX_ROOT/filter-more" >/dev/null
sb_write edit.txt "before"
seq 1 30 > rename-me.txt
seq 40 70 > source.txt
sb_write link-me.txt "becomes a symbolic link"
sb_commit "Starting point"
sb_write edit.txt "after"
git mv rename-me.txt renamed.txt
cp source.txt copied.txt
echo "one more line" >> source.txt
git add -A
LINK_TARGET="$(printf 'edit.txt' | git hash-object -w --stdin)"
git update-index --cacheinfo "120000,$LINK_TARGET,link-me.txt"
sb_run "git diff --staged -C --name-status"
sb_run "git diff --staged -C --name-status --diff-filter=M"
sb_run "git diff --staged -C --name-status --diff-filter=R"
sb_run "git diff --staged -C --name-status --diff-filter=C"
sb_run "git diff --staged -C --name-status --diff-filter=T"

# =============================================================================
sb_say "--- N13. prefixes, output files and odd file names ---"
sb_fresh "$SANDBOX_ROOT/prefix" >/dev/null
sb_write p.txt "one"
sb_commit "Add p.txt"
sb_write p.txt "two"
sb_run "git diff"
sb_run "git diff --no-prefix"
sb_run "git diff --src-prefix=old/ --dst-prefix=new/"
sb_run "git -c diff.mnemonicPrefix=true diff"
sb_run "git add p.txt && git -c diff.mnemonicPrefix=true diff --staged"
sb_run "git -c diff.mnemonicPrefix=true diff --staged --default-prefix"
sb_run "git diff --staged --stat --output=../saved.txt"
sb_run "cat ../saved.txt"

sb_say "    non-ASCII names and -z"
sb_write "café.txt" "coffee"
git add "café.txt"
sb_run "git diff --staged --name-only"
sb_run "git -c core.quotePath=false diff --staged --name-only"
sb_run "git diff --staged --name-only -z | tr '\\000' '|'; echo"

# =============================================================================
sb_say "--- N14. binary files ---"
sb_fresh "$SANDBOX_ROOT/binary" >/dev/null
printf '\000\001\002' > image.bin
sb_commit "Add image.bin"
printf '\000\011\011\011' > image.bin
sb_run "git diff"
sb_run "git diff --numstat"
sb_run "git diff --stat"
sb_run "git diff --text | cat -v"
sb_run "git diff --binary > ../binary.diff && cat ../binary.diff"
sb_run "git checkout -q -- image.bin"
sb_run "patch -p1 < ../binary.diff; echo exit=\$?"
sb_run "git apply ../binary.diff; echo exit=\$?"
sb_run git status --short
