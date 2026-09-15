#!/bin/bash
# Generates every transcript in Chapter 19, "blame".
#
#   bash sandbox/scripts/ch19-blame.sh [dir]
#
# No `set -e`: several commands shown here fail on purpose, such as blame on a
# file that is not tracked, and the transcript must carry on past them.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
# --date=relative, --since and --color-by-age compare against "now".
sb_pin_now

as() {
	export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"
	export GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"
}
ada()   { as "Ada Lovelace" "ada@example.com"; }
grace() { as "Grace Hopper" "grace@example.com"; }
alan()  { as "Alan Turing" "alan@example.com"; }

# The functions of the shop, so that later versions of the file can be built
# from the same pieces.
prices()   { printf '%s\n' "PRICES = {'tea': 3, 'cake': 5${1:-}}"; }
# The same line after "Format the code", which changed the quotes.
newprices() { printf '%s\n' 'PRICES = {"tea": 3, "cake": 5, "pie": 4}'; }
f_price()  { printf '%s\n' "def price(item):" "    \"\"\"Look up the price of one item.\"\"\"" "    return PRICES[item]"; }
f_tax()    { printf '%s\n' "def tax(amount):" "    \"\"\"Work out the sales tax on an amount.\"\"\"" "    return amount${1:- * 0.10}"; }
f_total()  { printf '%s\n' "def total(items):" "    subtotal = sum(price(i) for i in items)" "    return subtotal${1:- + tax(subtotal)}"; }
f_disc()   { printf '%s\n' "def discount(amount):" "    \"\"\"Take a pound off for loyal customers.\"\"\"" "    return amount - ${1:-1}"; }

# ---------------------------------------------------------------------------
sb_fresh "$SANDBOX_ROOT/shop" >/dev/null
ada
{ prices; echo; f_price; echo; f_tax; echo; f_total; } > shop.py
sb_commit "Start the shop"

grace
{ prices; echo; f_price; echo; f_tax " * 0.20"; echo; f_total; } > shop.py
sb_commit "Raise tax to 20%"
git tag v1

alan
{ prices ", 'pie': 4"; echo; f_price; echo; f_tax " * 0.20"; echo; f_total; echo; f_disc; } > shop.py
sb_commit "Sell pie and add a discount"

sb_say "--- B1. the plain form ---"
sb_run "git blame shop.py"
sb_run "git blame nosuch.py"
sb_write notes.txt "not tracked"
sb_run "git blame notes.txt"
rm notes.txt
sb_run "git blame ."

sb_say "--- B2. format options ---"
sb_run "git blame -s shop.py"
sb_run "git blame -e -L 7,9 shop.py"
sb_run "git blame -l -L 7,9 shop.py"
sb_run "git blame -t -L 7,9 shop.py"
sb_run "git blame -n -L 7,9 shop.py"
sb_run "git blame -f -L 7,9 shop.py"
sb_run "git blame --abbrev=12 -L 7,9 shop.py"
sb_run "git blame --abbrev=4 -L 7,9 shop.py"
sb_run "git blame --no-abbrev -L 7,9 shop.py"
sb_run "git blame --date=short -L 7,9 shop.py"
sb_run "git blame --date=relative -L 7,9 shop.py"
sb_run "git -c blame.date=short blame -L 7,9 shop.py"
sb_run "git -c blame.showEmail=true blame -L 7,9 shop.py"
sb_run "git blame -c -L 7,9 shop.py"
sb_run "git annotate -L 7,9 shop.py"
sb_run "git blame -b -L 7,9 shop.py"
sb_run "git blame --root -L 7,9 shop.py"
sb_run "git -c blame.blankBoundary=true blame -L 7,9 shop.py"
sb_run "git -c blame.showRoot=true blame -L 7,9 shop.py"
sb_run "git blame -p -L 8,9 shop.py"
sb_run "git blame -p -L 15,17 shop.py"
sb_run "git blame --line-porcelain -L 15,17 shop.py | grep '^author '"
sb_run "git blame --incremental -L 8,9 shop.py"
sb_run "git blame --show-stats -L 8,9 shop.py"
sb_run "git blame --progress -s -L 8,9 shop.py"
sb_run "GIT_PROGRESS_DELAY=0 git blame --progress -s -L 8,9 shop.py"
sb_run "git blame --progress -p shop.py"

sb_say "--- B3. lines ---"
sb_run "git blame -s -L 7,9 shop.py"
sb_run "git blame -s -L 7,+3 shop.py"
sb_run "git blame -s -L 9,-3 shop.py"
sb_run "git blame -s -L 15 shop.py"
sb_run "git blame -s -L ,2 shop.py"
sb_run "git blame -s -L 9,7 shop.py"
sb_run "git blame -s -L :tax shop.py"
# Git Bash turns an argument that starts with / into a Windows path; the
# transcript shows bash as it behaves everywhere else, and the chapter explains.
MSYS_NO_PATHCONV=1 sb_run "git blame -s -L '/^def total/,/return/' shop.py"
MSYS_NO_PATHCONV=1 sb_run "git blame -s -L '/def/,+1' -L '/def/,+1' shop.py"
MSYS_NO_PATHCONV=1 sb_run "git blame -s -L '/def/,+1' -L '^/def/,+1' shop.py"
sb_run "git blame -s -L 1,1 -L 15,17 shop.py"
sb_run "git blame -s -L 1,4 -L 3,5 shop.py"
sb_run "git blame -s -L 40,50 shop.py"
sb_run "git blame -s -L :nosuch shop.py"

sb_say "--- B4. older versions, uncommitted lines, other contents ---"
sb_run "git blame -s v1 -- shop.py"
sb_run "git blame -s v1.. -- shop.py"
sb_run "git blame -s --since='2026-01-05 10:30' -- shop.py"
{ prices ", 'pie': 4, 'jam': 2"; echo; f_price; echo; f_tax " * 0.20"; echo; f_total; echo; f_disc; } > shop.py
# Uncommitted lines are dated with the real clock, so these transcripts use -s,
# and cut the time lines from porcelain output.
sb_run "git blame -s -L 1,2 shop.py"
sb_run "git blame -p -L 1,1 shop.py"
sb_run "git blame -s -L 1,2 HEAD -- shop.py"
git checkout -q -- shop.py
{ printf '%s\n' "PRICES = {'tea': 3, 'cake': 6}" ""; f_price; } > "$SANDBOX_ROOT/draft.py"
sb_run "git blame -s --contents ../draft.py shop.py"
sb_run "git blame -s --contents ../draft.py v1 -- shop.py"
sb_run "git blame -p --contents ../draft.py -L 1,1 shop.py"
sb_run "git show v1:shop.py | git blame -s --contents - shop.py"

# ---------------------------------------------------------------------------
sb_say "--- B5. whitespace and ignored commits ---"
grace
{ echo "# Prices in pounds."; newprices; echo; f_price; echo; f_tax "*0.20"; echo; f_total "+tax(subtotal)"; echo; f_disc; } > shop.py
sb_commit "Format the code"
fmt=$(git rev-parse --short HEAD)
sb_run "git show --stat --oneline"
sb_run "git blame -s shop.py"
sb_run "git blame -s -w shop.py"
sb_run "git blame -s --ignore-rev $fmt shop.py"
sb_run "git -c blame.markIgnoredLines=true -c blame.markUnblamableLines=true blame -s --ignore-rev $fmt shop.py"
sb_run "git -c blame.markIgnoredLines=true -c blame.markUnblamableLines=true blame --line-porcelain --ignore-rev $fmt -L 1,1 shop.py"
sb_run "git rev-parse $fmt > .git-blame-ignore-revs"
sb_run "cat .git-blame-ignore-revs"
sb_run "git blame -s --ignore-revs-file .git-blame-ignore-revs -L 8,10 shop.py"
sb_run "git config blame.ignoreRevsFile .git-blame-ignore-revs"
sb_run "git blame -s -L 8,10 shop.py"
sb_run "git blame -s --ignore-revs-file '' -L 8,10 shop.py"
sb_run "git blame -s --ignore-rev nosuch -L 8,10 shop.py"
git config --unset blame.ignoreRevsFile
rm .git-blame-ignore-revs

sb_say "--- B6. moved and copied lines ---"
ada
{ echo "# Prices in pounds."; newprices; echo; f_price; echo; f_disc; echo; f_tax "*0.20"; echo; f_total "+tax(subtotal)"; } > shop.py
sb_commit "Put discount before tax"
git tag v2
sb_run "git blame -s shop.py"
sb_run "git blame -s -M shop.py"
sb_run "git blame -s -M --score-debug -L 7,9 shop.py"
sb_run "git blame -s -M80 -L 7,9 shop.py"

alan
{ echo "# Prices in pounds."; newprices; echo; f_price; echo; f_disc; echo; echo "from tax import tax"; echo; f_total "+tax(subtotal)"; } > shop.py
f_tax "*0.20" > tax.py
sb_commit "Move tax into its own file"
sb_run "git show --stat --oneline"
sb_run "git blame -s tax.py"
sb_run "git blame -s -M tax.py"
sb_run "git blame -s -C tax.py"

grace
{ f_total "+tax(subtotal)"; echo; printf '%s\n' "def receipt(items):" "    return total(items)"; } > receipt.py
sb_write stock.py "STOCK = {'tea': 10}"
sb_commit "Add a receipt and a stock list"
sb_run "git show --stat --oneline"
sb_run "git blame -s -C receipt.py"
sb_run "git blame -s -C -C receipt.py"

ada
{ echo "STOCK = {'tea': 10}"; echo; f_price; } > stock.py
sb_commit "Look up prices from the stock list"
sb_run "git show --stat --oneline"
sb_run "git blame -s -C -C stock.py"
sb_run "git blame -s -C -C -C stock.py"
sb_run "git blame -s -CCC stock.py"
sb_run "git blame -s -C -C -C60 stock.py"

sb_say "--- B7. renames, merges, walking forwards, rewritten history ---"
grace
git mv shop.py store.py
sb_commit "Rename shop.py to store.py"
sb_run "git blame -s -L 1,5 store.py"
sb_run "git blame -s --no-show-name -L 1,2 store.py"
sb_run "git blame -s -L 1,5 shop.py"
sb_run "git blame -s -L 1,5 HEAD~1 -- shop.py"

git switch -q -c promo
alan
{ echo "# Prices in pounds."; newprices; echo; f_price; echo; f_disc 2; echo; echo "from tax import tax"; echo; f_total "+tax(subtotal)"; } > store.py
sb_commit "Double the discount"
git switch -q main
ada
git merge -q --no-ff -m "Merge the promotion" promo >/dev/null
sb_tick
sb_run "git log --oneline --graph -4"
sb_run "git blame -s -L 8,10 store.py"
sb_run "git blame -s --first-parent -L 8,10 store.py"

sb_run "git log --oneline v1..v2"
sb_run "git blame -s --reverse v1..v2 -- shop.py"
sb_run "git blame -s --reverse v1 -- shop.py"
sb_run "git blame -s --reverse v2 -- nosuch.py"

# A made-up history for -S: v2 whose parent is the commit before "Format the
# code", as if that commit had never been made.
{
	echo "$(git rev-parse v2) $(git rev-parse v2~2)"
	echo "$(git rev-parse v2~2) $(git rev-parse v2~3)"
	echo "$(git rev-parse v2~3) $(git rev-parse v2~4)"
	echo "$(git rev-parse v2~4)"
} > "$SANDBOX_ROOT/history.txt"
sb_run "cat ../history.txt"
sb_run "git blame -s -S ../history.txt v2 -- shop.py"

sb_say "--- B8. names, encodings, algorithms and colour ---"
sb_write .mailmap "Grace Hopper <grace@navy.example> <grace@example.com>"
sb_run "cat .mailmap"
sb_run "git blame -e -L 1,2 store.py"
sb_run "git blame -L 1,2 store.py"
rm .mailmap

# A commit whose author's name is stored in ISO-8859-1, built by hand.
sed -i '1s/.*/# Prices in pounds sterling./' store.py
git add store.py
tree=$(git write-tree)
printf 'tree %s\nparent %s\nauthor Zo\353 Quill <zoe@example.com> %s +0000\ncommitter Zo\353 Quill <zoe@example.com> %s +0000\nencoding ISO-8859-1\n\nSay which pounds\n' \
	"$tree" "$(git rev-parse HEAD)" "$SANDBOX_NOW" "$SANDBOX_NOW" > "$SANDBOX_ROOT/commit.txt"
c=$(git hash-object -t commit -w "$SANDBOX_ROOT/commit.txt")
git update-ref refs/heads/main "$c"
git reset -q --hard
sb_tick
sb_run "git blame -L 1,1 store.py | cat -A"
sb_run "git blame --encoding=none -L 1,1 store.py | cat -A"
sb_run "git blame --encoding=ISO-8859-1 -L 1,1 store.py | cat -A"

SHOP_NOW=$SANDBOX_NOW
# The example Chapter 13 uses for diff algorithms, blamed.
sb_fresh "$SANDBOX_ROOT/frob" >/dev/null
ada
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
grace
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
sb_commit "Replace fact with fib"
sb_run "git blame -s --diff-algorithm=myers -L 12,20 frob.c"
sb_run "git blame -s --diff-algorithm=histogram -L 12,20 frob.c"
sb_run "git -c diff.algorithm=histogram blame -s -L 12,20 frob.c"
cd "$SANDBOX_ROOT/shop"
SANDBOX_NOW=$SHOP_NOW
sb_settime

sb_run "git blame --color-lines -L 3,5 store.py | cat -A"
sb_run_ansi "git blame --color-lines -L 1,9 store.py"
sb_run_ansi "git -c color.blame.repeatedLines=magenta blame --color-lines -L 3,5 store.py"
sb_run_ansi "git -c blame.coloring=repeatedLines blame -L 3,5 store.py"
sb_run_ansi "git blame --color-by-age -L 1,9 store.py"
sb_run_ansi "git -c color.blame.highlightRecent='blue,6 hours ago,red' blame --color-by-age -L 1,9 store.py"
sb_run_ansi "git -c blame.coloring=highlightRecent blame -L 1,3 store.py"
