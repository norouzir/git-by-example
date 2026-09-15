#!/bin/bash
# Generates every transcript in Chapter 21, "grep and Searching History".
#
#   bash sandbox/scripts/ch21-grep.sh [dir]
#
# No `set -e`: git grep exits with 1 when nothing matches, which several
# examples show on purpose.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null

# ---------------------------------------------------------------------------
# A small library catalogue.
sb_fresh "$SANDBOX_ROOT/library" >/dev/null
sb_write src/books.py \
	"LOAN_DAYS = 14" \
	"" \
	"def lend(book, member):" \
	"    # TODO: check the member's limit" \
	"    book.borrower = member" \
	"    book.due = today() + LOAN_DAYS" \
	"" \
	"def renew_loan(book):" \
	"    book.due = book.due + LOAN_DAYS" \
	"" \
	"def give_back(book):" \
	"    book.borrower = None"
sb_write src/members.py \
	"class Member:" \
	"    def __init__(self, name):" \
	"        self.name = name" \
	"        self.loans = []" \
	"" \
	"def find_member(name):" \
	"    # todo: search by card number too" \
	"    return MEMBERS[name]"
sb_write docs/README.md \
	"# Library" \
	"" \
	"Members may borrow books for 14 days." \
	"A loan can be renewed once."
sb_write docs/guide/lending.md \
	"Lending" \
	"=======" \
	"" \
	"Use lend() to lend a book." \
	"-- is not a valid loan period."
printf 'PNG\0\0 lend lend\n' > logo.png
sb_write .gitignore "build/"
sb_commit "Start the catalogue"
git tag v1.0

sb_write src/books.py \
	"LOAN_DAYS = 21" \
	"" \
	"def lend(book, member):" \
	"    # TODO: check the member's limit" \
	"    book.borrower = member" \
	"    book.due = today() + LOAN_DAYS" \
	"" \
	"def give_back(book):" \
	"    book.borrower = None" \
	"    book.due = None"
sb_commit "Lend for three weeks and drop renewals"
sb_write docs/README.md \
	"# Library" \
	"" \
	"Members may borrow books for 21 days." \
	"Loans cannot be renewed."
sb_commit "Update the README"

git switch -q -c fines
sb_write src/fines.py \
	"FINE_PER_DAY = 0.10" \
	"" \
	"def fine(days_late):" \
	"    return days_late * FINE_PER_DAY"
sb_commit "Charge fines for late books"
git switch -q main

# Files Git does not track: one untracked, one ignored.
sb_write notes.txt "Ask about lend limits."
sb_write build/cache.txt "lend cache"

sb_say "--- G1. the plain form ---"
sb_run "git grep lend"
sb_run "git grep nosuch; echo \"exit \$?\""
sb_run "grep -rI lend . | sort"
sb_run "cd src"
cd src
sb_run "git grep lend"
sb_run "git grep --full-name lend"
sb_run "git grep lend -- ../docs"
sb_run "cd .."
cd ..

sb_say "--- G2. matching ---"
sb_run "git grep -i todo"
sb_run "git grep todo"
sb_run "git grep -c book"
sb_run "git grep -c -w book"
sb_run "git grep -v -e '^$' -e '^ ' -- src/members.py"
sb_run "git grep 'book\\.due = .*DAYS'"
sb_run "git grep 'book.' -- docs"
sb_run "git grep -F 'book.' -- docs"
sb_run "git grep -E 'borrower|loans'"
sb_run "git grep 'borrower\\|loans'"
sb_run "git grep -G 'borrower|loans'"
sb_run "git grep -P 'due(?= =)'"
sb_run "git grep '-- is'"
sb_run "git grep -e '-- is'"
sb_run "printf 'borrower\\nloans\\n' > ../patterns.txt"
sb_run "git grep -f ../patterns.txt"
sb_run "git grep ''  -- docs/README.md"

sb_say "--- G3. combining patterns ---"
sb_run "git grep -e book -e name -- src"
sb_run "git grep -e book --and -e due"
sb_run "git grep -e book --and --not -e due -- src"
sb_run "git grep -e def --and \\( -e lend -e give \\)"
sb_run "git grep --and -e book"
sb_run "git grep --all-match -e borrower -e LOAN_DAYS"
sb_run "git grep --all-match -e borrower -e name"

sb_say "--- G4. what is printed ---"
sb_run "git grep -n LOAN_DAYS"
sb_run "git grep --column LOAN_DAYS"
sb_run "git grep -o 'book\\.[a-z]*'"
sb_run "git grep -c book"
sb_run "git grep -l book"
sb_run "git grep --name-only book"
sb_run "git grep -L book"
sb_run "git grep -h book -- src/books.py"
sb_run "git grep -h -H book -- src/books.py"
sb_run "git grep -m 1 book"
sb_run "git grep -m 0 book; echo \"exit \$?\""
sb_run "git grep -q LOAN_DAYS; echo \"exit \$?\""
sb_run "git grep -q nosuch; echo \"exit \$?\""
sb_run "git grep -l -z book | cat -A; echo"
sb_run "git grep -Ocat -e 'renewed'"

sb_say "--- G5. context ---"
sb_run "git grep -A 1 borrower"
sb_run "git grep -B 1 borrower"
sb_run "git grep -C 1 LOAN_DAYS -- src"
sb_run "git grep -1 LOAN_DAYS -- src"
sb_run "git grep --break -n member"
sb_run "git grep --heading -n member"
sb_run "git grep -p TODO"
sb_run "git grep -W TODO"
sb_run "git grep -n -p -i todo"

sb_say "--- G6. which files ---"
sb_run "git grep lend -- '*.md'"
sb_run "git grep lend -- ':!docs'"
sb_run "git grep -e Lend -e lend -- docs"
sb_run "git grep book -- docs"
sb_run "git grep --max-depth 0 book -- docs"
sb_run "git grep --max-depth 1 book -- docs"
sb_run "git grep --no-recursive book -- docs"
sb_run "git grep --no-recursive -r book -- docs"
sb_run "git grep -I lend"
sb_run "git grep -a lend -- logo.png | cat -A"
sb_write .gitattributes "*.png diff=png"
sb_run "cat .gitattributes"
sb_run "git -c diff.png.textconv='sed s/lend/LOAN/g' grep LOAN -- logo.png; echo \"exit \$?\""
sb_run "git -c diff.png.textconv='sed s/lend/LOAN/g' grep --textconv LOAN -- logo.png | cat -A"
rm .gitattributes

sb_say "--- G7. where to search ---"
sb_write src/books.py \
	"LOAN_DAYS = 28" \
	"" \
	"def lend(book, member):" \
	"    # TODO: check the member's limit" \
	"    book.borrower = member" \
	"    book.due = today() + LOAN_DAYS" \
	"" \
	"def give_back(book):" \
	"    book.borrower = None" \
	"    book.due = None"
git add src/books.py
sb_write src/books.py \
	"LOAN_DAYS = 7" \
	"" \
	"def lend(book, member):" \
	"    # TODO: check the member's limit" \
	"    book.borrower = member" \
	"    book.due = today() + LOAN_DAYS" \
	"" \
	"def give_back(book):" \
	"    book.borrower = None" \
	"    book.due = None"
sb_run "git grep 'LOAN_DAYS ='"
sb_run "git grep --cached 'LOAN_DAYS ='"
sb_run "git grep 'LOAN_DAYS =' HEAD"
sb_run "git grep 'LOAN_DAYS =' v1.0"
sb_run "git grep 'LOAN_DAYS =' HEAD v1.0 fines"
sb_run "git grep 'LOAN_DAYS =' v1.0 -- src"
sb_run "git grep 'LOAN_DAYS =' v1.0:src"
sb_run "git grep 'LOAN_DAYS =' HEAD~2..HEAD"
sb_run "git grep --cached --untracked lend"
git restore --staged --worktree src/books.py
sb_run "git grep --untracked lend"
sb_run "git grep --untracked --no-exclude-standard lend"
sb_run "git grep --no-index lend"
sb_run "git grep --no-index --exclude-standard lend"
sb_run "cd .."
cd ..
mkdir -p plain
sb_write plain/todo.txt "lend the atlas"
sb_run "cd plain"
cd plain
sb_run "git grep lend"
sb_run "git grep --no-index lend"
sb_run "git -c grep.fallbackToNoIndex=true grep lend"
sb_run "cd ../library"
cd ../library

sb_say "--- G8. colour ---"
sb_run_ansi "git grep -n -p LOAN_DAYS -- src"
sb_run_ansi "git grep --no-color -n LOAN_DAYS -- src"
sb_run "git grep --color=always -n LOAN_DAYS -- src | cat -A"
sb_run "git grep --color=auto -n LOAN_DAYS -- src | cat -A"

sb_say "--- G9. searching history ---"
sb_run "git log --oneline --all"
sb_run "git grep renew_loan"
sb_run "git grep renew_loan \$(git rev-list --all)"
sb_run "git grep renew_loan HEAD~1 HEAD~2"
sb_run "git log --oneline -S renew_loan"
sb_run "git log --oneline -S renew_loan -p -- src/books.py"
sb_run "git show HEAD~2:src/books.py"
sb_run "git log --oneline -G 'LOAN_DAYS = [0-9]+' -p -- src/books.py"
sb_run "git grep FINE_PER_DAY"
sb_run "git log --oneline -S FINE_PER_DAY"
sb_run "git log --oneline --all -S FINE_PER_DAY"
fines=$(git rev-parse --short fines)
sb_run "git branch --contains $fines"
sb_run "git log --oneline --all -i --grep=fine"
sb_run "git log --oneline --all -- src/fines.py"
sb_run "git grep -c FINE_PER_DAY \$(git rev-list --all) -- src/fines.py"
sb_run "git rev-list --all | xargs git grep renew_loan"
