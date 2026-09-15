#!/bin/bash
# Generates every transcript in Chapter 22,
# "shortlog, describe, rev-list, rev-parse".
#
#   bash sandbox/scripts/ch22-shortlog-describe-rev-list-rev-parse.sh [dir]
#
# No `set -e`: several commands are shown failing on purpose, and
# rev-parse --verify -q answers with its exit code.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
# git shortlog without a revision reads standard input whenever it is not a
# terminal. Give every command an empty input, so the run never waits on one.
exec </dev/null
# --until=yesterday and %(committerdate:relative) count from "now".
sb_pin_now

as() {
	export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"
	export GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2"
}
msg() { printf '%s\n' "$@" > "$SANDBOX_ROOT/msg"; }
commit_file() { git add -A && git commit -q -F "$SANDBOX_ROOT/msg" && sb_tick; }

# ---------------------------------------------------------------------------
# A parser project, with a server to push to.
git init -q --bare "$SANDBOX_ROOT/server.git"
sb_fresh "$SANDBOX_ROOT/parser" >/dev/null
git remote add origin "$SANDBOX_ROOT/server.git"

as "Ada Lovelace" "ada@example.com"
sb_write src/parse.py "def parse(text):" "    return text.split()"
msg "Add the parser"
commit_file

as "Grace Hopper" "grace@example.com"
sb_write tests/test_parse.py "from parse import parse" "assert parse('a b') == ['a', 'b']"
msg "Add tests" "" "Reviewed-by: Ada Lovelace <ada@example.com>"
commit_file

as "A. Lovelace" "ada@old.example"
sb_write src/parse.py "def parse(text):" "    return (text or '').split()"
msg "Fix a crash on empty input" "" "Reviewed-by: Grace Hopper <grace@example.com>"
commit_file
as "Ada Lovelace" "ada@example.com"
git tag -a v1.0 -m "Release 1.0"
git push -q -u origin main v1.0

as "Alan Turing" "alan@example.com"
sb_write src/lex.py "def lex(text):" "    return list(text)"
msg "Add a lexer" "" "Co-authored-by: Grace Hopper <grace@example.com>" "Reviewed-by: Ada Lovelace <ada@example.com>"
commit_file

# Grace sent this one as a patch, and Ada applied it: Ada is the committer.
as "Ada Lovelace" "ada@example.com"
export GIT_AUTHOR_NAME="Grace Hopper" GIT_AUTHOR_EMAIL="grace@example.com"
sb_write docs/lexer.md "The lexer splits text into characters."
msg "[PATCH] Document the lexer"
commit_file
git tag v1.1-rc1

as "Ada Lovelace" "ada@example.com"
sb_write src/parse.py "def parse(text):" "    return (text or '').split(' ')"
msg "Speed up parsing" "" "This commit message has a body that is long enough to be wrapped by shortlog when it is asked to show whole messages."
commit_file
git tag -a v1.1 -m "Release 1.1"

# A file written and committed within the same second can look modified to a
# checkout straight afterwards; refresh the index first.
git update-index -q --really-refresh
git switch -q -c grammar v1.0
as "Alan Turing" "alan@example.com"
sb_write src/grammar.py "RULES = []"
msg "Start a grammar"
commit_file
git tag -a grammar-0.1 -m "Grammar preview"
as "Grace Hopper" "grace@example.com"
sb_write src/grammar.py "RULES = ['expr']"
msg "Add the first rule"
commit_file
git switch -q main
as "Ada Lovelace" "ada@example.com"
git merge -q --no-ff -m "Merge the grammar" grammar >/dev/null
sb_tick
git branch -q -D grammar

sb_write .mailmap \
	"# Map old names and addresses to current ones." \
	"Ada Lovelace <ada@example.com> <ada@old.example>"
msg "Add a mailmap"
commit_file
git switch -q -c experiment
as "Alan Turing" "alan@example.com"
sb_write src/fast.py "FAST = True"
msg "Try a faster tokenizer"
commit_file
git switch -q main
as "Ada Lovelace" "ada@example.com"

# =============================================================================
sb_say "--- R1. shortlog ---"
sb_run "git log --oneline --graph --all --decorate"
sb_run "git shortlog HEAD"
sb_run "git shortlog -s HEAD"
sb_run "git shortlog -s -n HEAD"
sb_run "git shortlog -s -n -e HEAD"
sb_run "git shortlog --format='[%h] %s' v1.0"
sb_run "git shortlog --format='%s: %b' -1 v1.1"
sb_run "git shortlog -w --format='%s: %b' -1 v1.1"
sb_run "git shortlog -w40,2,4 --format='%s: %b' -1 v1.1"
sb_run "git shortlog -w0,2,4 --format='%s: %b' -1 v1.1"
sb_run "git shortlog -s -c HEAD"
sb_run "git shortlog -s --committer HEAD"
sb_run "git shortlog -s --group=committer HEAD"
sb_run "git shortlog -s --group=author --group=committer HEAD"
sb_run "git shortlog -s -n --group=trailer:reviewed-by HEAD"
sb_run "git shortlog -s -e --group=trailer:co-authored-by HEAD"
sb_run "git shortlog -s -n --group=author --group=trailer:co-authored-by HEAD"
sb_run "git shortlog -s --group=format:%as HEAD"
sb_run "git shortlog --group=format:%ad --date=format:%H:00 --format=%s v1.0"
sb_run "git shortlog -s --group=nosuch HEAD"
sb_run "git shortlog -s v1.0..v1.1"
sb_run "git shortlog -s HEAD -- docs"
sb_run "git shortlog -s --all"
sb_run "git shortlog -s -n --no-merges HEAD"
sb_run "git shortlog"
sb_run "git shortlog -s"
sb_run "git log --pretty=short v1.0 | git shortlog -s"
sb_run "git log --pretty=short v1.0 | git shortlog --group=trailer:reviewed-by"

sb_say "--- R2. mailmap ---"
sb_run "cat .mailmap"
sb_run "git log -1 --format='%an <%ae> -> %aN <%aE>' v1.0"
sb_run "mv .mailmap ../saved.mailmap"
sb_run "git shortlog -s -e HEAD"
sb_run "mv ../saved.mailmap .mailmap"
sb_run "git shortlog -s -e HEAD"
sb_write "$SANDBOX_ROOT/forms.mailmap" \
	"# 1. a proper name for an address" \
	"Grace Hopper <grace@example.com>" \
	"# 2. a proper address for an address" \
	"<alan@turing.example> <alan@example.com>" \
	"# 3. a proper name and address for an address" \
	"Ada Lovelace <ada@example.com> <ada@old.example>" \
	"# 4. a proper name and address for a name and an address" \
	"Charles Babbage <charles@example.com> Chas <charles@old.example>  # only Chas"
sb_run "cat ../forms.mailmap"
sb_run "git check-mailmap --mailmap-file=../forms.mailmap 'G. Hopper <grace@example.com>' 'Alan Turing <alan@example.com>' 'A. Lovelace <ada@old.example>' 'Chas <charles@old.example>' 'Charlie <charles@old.example>'"
sb_run "git check-mailmap 'a. lovelace <ADA@OLD.Example>'"
sb_run "git check-mailmap 'Grace Hopper <grace@example.com>' '<ada@old.example>' ada@old.example someone@example.com"
sb_run "printf 'Someone <someone@example.com>\\nA. Lovelace <ada@old.example>\\n' | git check-mailmap --stdin 'Grace Hopper <grace@example.com>'"
sb_run "git check-mailmap"
sb_write "$SANDBOX_ROOT/extra.mailmap" \
	"Grace M. Hopper <grace@navy.example> <grace@example.com>" \
	"Augusta Ada King <ada@example.com> <ada@old.example>"
sb_run "cat ../extra.mailmap"
sb_run "git check-mailmap --mailmap-file=../extra.mailmap 'A. Lovelace <ada@old.example>' 'Grace Hopper <grace@example.com>'"
sb_run "git -c mailmap.file=../extra.mailmap shortlog -s -e HEAD"
sb_run "mv .mailmap ../saved.mailmap"
sb_run "git check-mailmap '<ada@old.example>'"
sb_run "git -c mailmap.blob=HEAD:.mailmap check-mailmap '<ada@old.example>'"
sb_run "git check-mailmap --mailmap-blob=HEAD:.mailmap '<ada@old.example>'"
sb_run "mv ../saved.mailmap .mailmap"
sb_run "git -c mailmap.file=../extra.mailmap check-mailmap --mailmap-blob=HEAD:.mailmap '<ada@old.example>'"
sb_run "git -c mailmap.file=../extra.mailmap -c mailmap.blob=HEAD:.mailmap check-mailmap '<ada@old.example>'"
sb_run "git clone -q --bare . ../bare.git"
sb_run "git -C ../bare.git shortlog -s -e HEAD"
sb_run "git -C ../bare.git -c mailmap.blob= shortlog -s -e HEAD"

# =============================================================================
sb_say "--- R3. describe ---"
sb_run "git describe"
sb_run "git describe v1.1"
sb_run "git describe HEAD~1"
sb_run "git describe HEAD~3"
sb_run "git describe --tags HEAD~3"
sb_run "git describe --all"
sb_run "git describe --all HEAD~4"
sb_run "git describe --match 'v1.0'"
sb_run "git describe --match 'v1.0' --match 'grammar-*'"
sb_run "git describe --match 'v1.0' --no-match"
sb_run "git describe --exclude 'v1.1'"
sb_run "git describe --exclude 'v1.1' --no-exclude"
sb_run "git describe --match 'v*' --exclude 'v1.1'"
sb_run "git describe --tags --match 'v1.1-*' HEAD~3"
sb_run "git describe --all --match 'origin/*'"
sb_run "git describe --first-parent"
sb_run "git describe --candidates=1"
sb_run "git describe --debug HEAD~1"
sb_run "git describe --long v1.1"
sb_run "git describe --abbrev=12"
sb_run "git describe --abbrev=0"
sb_run "git describe --candidates=0"
sb_run "git describe --exact-match v1.1"
sb_run "git describe --exact-match HEAD"
sb_run "git describe --contains HEAD~6"
sb_run "git describe --contains HEAD~4"
sb_run "git describe --contains HEAD~1^2"
sb_write src/parse.py "def parse(text):" "    return (text or '').split(' ')" "# unsaved"
sb_run "git describe --dirty"
sb_run "git describe --dirty=-modified"
sb_run "git describe --dirty HEAD"
sb_run "git describe --broken"
sb_run "git restore src/parse.py"
sb_run "git describe --dirty"
# sb_fresh restarts the clock; later relative dates count from the parser's.
PARSER_NOW=$SANDBOX_NOW
back_to_parser() { cd "$SANDBOX_ROOT/parser"; SANDBOX_NOW=$PARSER_NOW; sb_settime; }
# A damaged repository: the newest commit's tree deleted by hand.
sb_fresh "$SANDBOX_ROOT/damaged" >/dev/null
sb_write a.txt a
sb_commit "Add a"
git tag -a v0.1 -m "Version 0.1"
sb_write b.txt b
sb_commit "Add b"
tree=$(git rev-parse HEAD^{tree})
rm -f ".git/objects/${tree:0:2}/${tree:2}"
sb_run "cd ../damaged"
sb_run "git describe"
sb_run "git describe --dirty; echo \"exit \$?\""
sb_run "git describe --broken"
sb_run "git describe --broken=-corrupt"
back_to_parser
sb_run "cd ../parser"
sb_run "git describe \$(git rev-parse HEAD:src/lex.py)"
sb_run "git describe HEAD:src"
sb_fresh "$SANDBOX_ROOT/untagged" >/dev/null
sb_write a.txt a
sb_commit "Only commit"
sb_run "cd ../untagged"
sb_run "git describe"
sb_run "git describe --tags"
sb_run "git describe --always"
back_to_parser
sb_run "cd ../parser"

# =============================================================================
sb_say "--- R4. rev-list ---"
sb_run "git rev-list HEAD~2"
sb_run "git log --format=%H HEAD~2"
sb_run "git rev-list"
sb_run "git rev-list HEAD nosuch"
sb_run "git rev-list --count HEAD"
sb_run "git rev-list --count v1.0..HEAD"
sb_run "git rev-list --count --left-right main...experiment"
sb_run "git switch -q --detach main"
git update-index -q --really-refresh
git switch -q --detach main
sb_run "git cherry-pick experiment"
sb_run "git rev-list --count --left-right HEAD...experiment"
sb_run "git rev-list --count --left-right --cherry-mark HEAD...experiment"
sb_run "git switch -q main"
git switch -q main
sb_run "git rev-list --abbrev-commit --parents -3 HEAD"
sb_run "git rev-list --timestamp -2 HEAD"
sb_run "git rev-list --format='%h %s' -2 HEAD"
sb_run "git rev-list --no-commit-header --format='%h %s' -2 HEAD"
sb_run "git rev-list --no-commit-header --commit-header --format='%h %s' -1 HEAD"
sb_run "git rev-list --oneline -2 HEAD"
sb_run "git rev-list --header -1 HEAD | cat -A; echo"
sb_run "git rev-list --max-age=1767614400 --abbrev-commit HEAD"
sb_run "git rev-list --min-age=1767614400 --abbrev-commit HEAD"
sb_run "git rev-list --objects -1 HEAD~7"
sb_run "git rev-list --objects v1.0..v1.1-rc1"
sb_run "git rev-list --objects --no-object-names v1.0..v1.1-rc1"
sb_run "git rev-list --objects --no-object-names --object-names -1 HEAD~7"
sb_run "git rev-list --objects --in-commit-order v1.0..v1.1-rc1"
sb_run "git rev-list -z --objects -1 HEAD~7 | cat -A; echo"
sb_run "git rev-list --objects-edge HEAD~1 ^HEAD~2"
sb_run "git cat-file -s v1.1-rc1:src/lex.py; git cat-file -s v1.1-rc1:docs/lexer.md"
sb_run "git rev-list --objects --filter=blob:none v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=blob:limit=38 v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=blob:limit=38 --filter-print-omitted v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=object:type=blob v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=object:type=blob --filter-provided-objects v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=tree:0 v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=tree:1 v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=tree:2 v1.0..v1.1-rc1"
spec=$(printf '/docs/\n' | git hash-object --stdin)
sb_run "printf '/docs/\\n' | git hash-object -w --stdin"
sb_run "git rev-list --objects --filter=sparse:oid=$spec v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=tree:3 --filter=blob:limit=38 v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=combine:tree:3+blob:limit=38 v1.0..v1.1-rc1"
sb_run "git rev-list --objects --filter=blob:none --no-filter v1.0..v1.1-rc1 | wc -l"
sb_run "git rev-list --objects --filter=blob:none HEAD:src/lex.py"
sb_run "git rev-list --objects --filter=blob:none --filter-provided-objects HEAD:src/lex.py"
sb_run "git rev-list --objects --filter=nosuch HEAD"
sb_run "git rev-list --filter=blob:none HEAD"
sb_run "cd ../damaged"
cd "$SANDBOX_ROOT/damaged"
sb_run "git rev-list --objects --all >/dev/null; echo \"exit \$?\""
sb_run "git rev-list --objects --missing=error --all >/dev/null; echo \"exit \$?\""
sb_run "git rev-list --objects --missing=allow-promisor --all >/dev/null; echo \"exit \$?\""
sb_run "git rev-list --objects --missing=allow-any --all; echo \"exit \$?\""
sb_run "git rev-list --objects --missing=print --all"
# A partial clone (Chapter 46) leaves out the blobs it has not needed yet.
git -C "$SANDBOX_ROOT/server.git" config uploadpack.allowFilter true
git clone -q --filter=blob:none "file://$SANDBOX_ROOT/server.git" "$SANDBOX_ROOT/partial" 2>/dev/null
sb_run "cd ../partial"
cd "$SANDBOX_ROOT/partial"
sb_run "git rev-list --objects --missing=print --all | grep '^?'"
sb_run "git rev-list --objects --missing=print-info --all | grep '^?'"
sb_run "git rev-list --objects --missing=allow-promisor --all | wc -l"
sb_run "git rev-list --objects --exclude-promisor-objects --all | wc -l"
sb_run "git rev-list --objects --all | wc -l"
sb_run "git rev-list --objects --missing=print --all | grep '^?'"
sb_run "cd ../parser"
cd "$SANDBOX_ROOT/parser"
sb_run "git rev-list --disk-usage HEAD"
sb_run "git rev-list --disk-usage --objects --all"
sb_run "git rev-list --disk-usage=human --objects --all"
sb_run "git rev-list --quiet HEAD; echo \"exit \$?\""
sb_run "git rev-list --objects --unpacked -1 HEAD | wc -l"
sb_run "git rev-list --indexed-objects --objects --no-object-names | head -3"
sb_run "git -C ../bare.git repack -adbq"
sb_run "git -C ../bare.git rev-list --objects --unpacked --all | wc -l"
sb_run "git -C ../bare.git rev-list --objects --use-bitmap-index v1.0..v1.1-rc1"
sb_run "git rev-list --objects --all --progress=Counting | wc -l"
sb_run "GIT_PROGRESS_DELAY=0 git rev-list --objects --all --progress=Counting | wc -l"
sb_run "git rev-list --bisect HEAD ^v1.0"
sb_run "git rev-list --bisect-vars HEAD ^v1.0"
sb_run "git rev-list --bisect-all --abbrev-commit HEAD ^v1.0"

# =============================================================================
sb_say "--- R5. rev-parse: names ---"
sb_run "git rev-parse HEAD"
sb_run "git rev-parse HEAD~1 v1.0 v1.0^{commit}"
sb_run "git rev-parse --short HEAD"
sb_run "git rev-parse --short=12 HEAD"
sb_run "git rev-parse --short=2 HEAD"
sb_run "git rev-parse nosuch >/dev/null"
sb_run "git rev-parse nosuch 2>/dev/null; echo \"exit \$?\""
sb_run "git rev-parse --verify nosuch"
sb_run "git rev-parse --verify -q nosuch; echo \"exit \$?\""
sb_run "git rev-parse --verify HEAD v1.0"
sb_run "git rev-parse --verify 'v1.0^{commit}'"
sb_run "name=--all; git rev-parse --verify -q \"\$name\"; echo \"exit \$?\""
sb_run "name=--all; git rev-parse --verify -q --end-of-options \"\$name\"; echo \"exit \$?\""
sb_run "git rev-parse --symbolic HEAD~1 main"
sb_run "git rev-parse --symbolic-full-name main v1.0 HEAD HEAD~1"
sb_run "git rev-parse --abbrev-ref HEAD"
sb_run "git rev-parse --abbrev-ref main HEAD~1 HEAD"
sb_run "git rev-parse --abbrev-ref @{upstream}"
sb_run "git rev-parse --symbolic-full-name @{upstream}"
sb_run "git tag main HEAD~2"
sb_run "git rev-parse --abbrev-ref=strict refs/heads/main refs/tags/main"
sb_run "git rev-parse --abbrev-ref=loose refs/heads/main refs/tags/main"
sb_run "git tag -d main"
sb_run "git rev-parse --not HEAD ^v1.0"
sb_run "git rev-parse v1.0..HEAD"
sb_run "git rev-parse HEAD^!"
sb_run "git rev-parse --default HEAD"
sb_run "git rev-parse --default HEAD v1.0"
sb_run "git rev-parse --disambiguate=\$(git rev-parse --short=4 HEAD)"
sb_run "git rev-parse --output-object-format=sha1 HEAD"
sb_run "git rev-parse --output-object-format=storage HEAD"
sb_run "git rev-parse --output-object-format=sha256 HEAD"
sb_run "git rev-parse --all"
sb_run "git rev-parse --branches --tags"
sb_run "git rev-parse --symbolic --branches --remotes --tags='v1.1*'"
sb_run "git rev-parse --symbolic --branches='e*' --remotes=origin"
sb_run "git rev-parse --symbolic --glob='refs/tags/v1.[01]'"
sb_run "git rev-parse --symbolic --glob=heads"
sb_run "git rev-parse --symbolic --exclude='*rc*' --tags"
sb_run "git rev-parse --symbolic --exclude='*rc*' --tags --tags"
sb_run "git -c transfer.hideRefs=refs/tags rev-parse --symbolic --exclude-hidden=fetch --all"
sb_run "git rev-parse --exclude-hidden=fetch --branches"

sb_say "--- R6. rev-parse: the repository ---"
sb_run "git rev-parse --show-toplevel"
sb_run "git rev-parse --git-dir"
sb_run "git rev-parse --show-prefix --show-cdup | cat -A"
sb_run "cd src"
cd src
sb_run "git rev-parse --git-dir"
sb_run "git rev-parse --absolute-git-dir"
sb_run "git rev-parse --show-prefix"
sb_run "git rev-parse --show-cdup"
sb_run "git rev-parse --path-format=relative --git-dir --show-toplevel"
sb_run "git rev-parse --path-format=absolute --git-dir"
sb_run "git rev-parse --path-format=relative --show-toplevel --path-format=absolute --git-dir"
sb_run "git rev-parse --prefix src/ parse.py"
sb_run "git rev-parse --sq --prefix src/ -- parse.py 'a b'; echo"
sb_run "git rev-parse --git-path objects/info"
sb_run "git rev-parse --is-inside-work-tree"
sb_run "git rev-parse --is-inside-git-dir"
sb_run "cd ../.git"
cd ../.git
sb_run "git rev-parse --is-inside-work-tree"
sb_run "git rev-parse --is-inside-git-dir"
sb_run "cd .."
cd ..
sb_run "git rev-parse --is-bare-repository"
sb_run "git -C ../bare.git rev-parse --is-bare-repository"
sb_run "git -C ../bare.git rev-parse --show-toplevel"
sb_run "git rev-parse --is-shallow-repository"
git clone -q --depth 1 "file://$SANDBOX_ROOT/server.git" "$SANDBOX_ROOT/shallow" 2>/dev/null
sb_run "git -C ../shallow rev-parse --is-shallow-repository"
sb_run "git rev-parse --resolve-git-dir .git"
sb_run "git rev-parse --resolve-git-dir src"
sb_run "git worktree add -q ../parser-wt experiment"
sb_run "cd ../parser-wt"
cd "$SANDBOX_ROOT/parser-wt"
sb_run "cat .git"
sb_run "git rev-parse --git-dir"
sb_run "git rev-parse --git-common-dir"
sb_run "git rev-parse --resolve-git-dir .git"
sb_run "git rev-parse --git-path HEAD --git-path objects"
sb_run "cd ../parser"
cd "$SANDBOX_ROOT/parser"
sb_run "git rev-parse --show-object-format"
sb_run "git rev-parse --show-object-format=storage"
sb_run "git rev-parse --show-object-format=input"
sb_run "git rev-parse --show-object-format=output"
sb_run "git rev-parse --show-object-format=compat | cat -A"
sb_run "git rev-parse --show-ref-format"
sb_run "git rev-parse --local-env-vars"
sb_run "git rev-parse --shared-index-path; echo \"(empty)\""
git update-index --split-index
sb_run "git update-index --split-index"
sb_run "git rev-parse --shared-index-path | sed 's/sharedindex.*/sharedindex.<hash>/'"
git update-index --no-split-index
sb_run "git update-index --no-split-index"
sb_run "git rev-parse --show-superproject-working-tree; echo \"(empty)\""
sb_run "cd .."
cd ..
sb_run "git rev-parse --show-toplevel"
sb_run "git rev-parse --git-dir"
sb_run "git rev-parse --sq-quote 'a b' \"it's\""
sb_run "cd parser"
cd "$SANDBOX_ROOT/parser"

sb_say "--- R7. rev-parse: sorting arguments ---"
sb_run "git rev-parse --symbolic -n 3 --oneline HEAD~1 src/parse.py"
sb_run "git rev-parse --revs-only --symbolic -n 3 --oneline HEAD~1 src/parse.py"
sb_run "git rev-parse --no-revs --symbolic -n 3 --oneline HEAD~1 src/parse.py"
sb_run "git rev-parse --flags --symbolic -n 3 --oneline HEAD~1 src/parse.py"
sb_run "git rev-parse --no-flags --symbolic -n 3 --oneline HEAD~1 src/parse.py"
sb_run "git rev-parse --flags --no-revs --symbolic -n 3 --oneline HEAD~1 src/parse.py"
sb_run "git rev-parse --symbolic HEAD 'a file.txt' >/dev/null"
sb_run "git rev-parse --symbolic HEAD -- 'a file.txt'"
sb_run "git rev-parse --sq --symbolic HEAD -- 'a file.txt' \"it's\"; echo"
sb_run "git rev-parse --since='2026-01-05 12:00' --until=yesterday"
sb_run "git rev-parse --since='2026-01-05 12:00' --until='2026-01-05 13:00'"
sb_run "git rev-parse --after='2026-01-05 12:00' --before='2026-01-05 13:00'"
sb_write "$SANDBOX_ROOT/greet.sh" \
	'OPTS_SPEC="\' \
	'greet [<options>] <name>...' \
	'--' \
	'h,help!        show the help' \
	'l,loud         shout the greeting' \
	't,times=count  repeat the greeting' \
	'lang?code      greet in another language' \
	'debug*         print what was parsed' \
	' Output' \
	'q,quiet        say nothing' \
	'"' \
	'eval "$(echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@" || echo exit $?)"' \
	'echo "after: $*"'
sb_run "cat ../greet.sh"
sb_run "sh ../greet.sh -lt 2 Ada"
sb_run "sh ../greet.sh --loud --times=3 Ada Grace"
sb_run "sh ../greet.sh --no-loud Ada -q"
sb_run "sh ../greet.sh --ti 2 Ada"
sb_run "sh ../greet.sh --lang Ada"
sb_run "sh ../greet.sh --lang=fr Ada"
sb_run "sh ../greet.sh -- -l"
sb_run "sh ../greet.sh -h"
sb_run "sh ../greet.sh --help-all"
sb_run "sh ../greet.sh --debug Ada"
sb_run "sh ../greet.sh -t; echo \"exit \$?\""
sb_run "sh ../greet.sh --no-help; echo \"exit \$?\""
sb_run "printf 'greet\\n--\\nl,loud  shout\\nt,times=n  repeat\\n' | git rev-parse --parseopt -- -lt2 x"
sb_run "printf 'greet\\n--\\nl,loud  shout\\nt,times=n  repeat\\n' | git rev-parse --parseopt --stuck-long -- -lt2 x"
sb_run "printf 'greet\\n--\\nl,loud  shout\\n' | git rev-parse --parseopt -- -l -- x"
sb_run "printf 'greet\\n--\\nl,loud  shout\\n' | git rev-parse --parseopt --keep-dashdash -- -l -- x"
sb_run "printf 'greet\\n--\\nl,loud  shout\\n' | git rev-parse --parseopt -- x -l"
sb_run "printf 'greet\\n--\\nl,loud  shout\\n' | git rev-parse --parseopt --stop-at-non-option -- x -l"

# =============================================================================
sb_say "--- R8. for-each-ref ---"
sb_run "git for-each-ref"
sb_run "git for-each-ref refs/tags"
sb_run "git for-each-ref 'refs/tags/v1.1*' refs/heads/main"
sb_run "git for-each-ref refs/tag"
sb_run "git for-each-ref --exclude='refs/tags/*rc*' refs/tags"
sb_run "printf 'refs/heads\\nrefs/remotes\\n' | git for-each-ref --stdin"
sb_run "git for-each-ref --stdin refs/heads"
sb_run "git for-each-ref --count=2 refs/tags"
sb_run "git for-each-ref --start-after=refs/heads/main --format='%(refname)'"
sb_run "git for-each-ref --start-after=refs/heads/main refs/tags"
sb_run "git for-each-ref --start-after=refs/heads/main --sort=-refname"
sb_run "git for-each-ref --include-root-refs --format='%(refname)'"
sb_run "git for-each-ref --format='%(refname:short) %(objectname:short) %(objecttype)'"
sb_run "git for-each-ref --format='%(refname) | %(refname:short) | %(refname:lstrip=2) | %(refname:rstrip=-1)' refs/tags/v1.0 refs/remotes"
sb_run "git for-each-ref --format='%(refname:lstrip=-2) | %(refname:strip=2) | %(refname:rstrip=2) | %(refname:lstrip=5) | %(refname:lstrip=-5)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(objectname:short=10) %(objectsize) %(objectsize:disk) %(tree:short) %(parent:short)' refs/heads/main"
sb_run "git for-each-ref --format='%(deltabase)' refs/heads/main"
sb_run "git for-each-ref --format='%(refname:short) %(objecttype) %(*objecttype) %(subject) | %(*subject)' refs/tags"
sb_run "git for-each-ref --format='%(object) %(type) %(tag)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(author)|%(committer)|%(tagger)' refs/heads/main refs/tags/v1.0"
sb_run "git for-each-ref --format='%(refname:short) %(creatordate:short) %(creator)' refs/tags"
sb_run "git for-each-ref --format='%(refname:short) %(authorname) %(authoremail:trim) %(authoremail:localpart) %(committerdate:relative)' refs/heads"
sb_run "git for-each-ref --format='%(refname:short) %(taggername) %(taggerdate:iso) %(*authorname)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(authorname) / %(*authorname) / %(*authorname:mailmap)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(*authoremail) %(*authoremail:mailmap) %(*authoremail:mailmap,trim) %(*authoremail:localpart,mailmap)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(contents)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(contents:subject)%0a%(contents:body)%0a--' 'refs/tags/v1.1^{}' refs/tags/v1.1"
sb_run "git for-each-ref --format='%(*contents:subject)%0a%(*contents:body)%0a--' refs/tags/v1.1"
sb_run "git for-each-ref --format='%(*subject): %(*trailers:key=Reviewed-by,valueonly)' refs/tags/v1.0 refs/tags/v1.1"
sb_run "git for-each-ref --format='%(subject:sanitize) %(contents:size) %(contents:lines=1)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(raw:size)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(raw)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(refname:short) %(signature:grade)' refs/heads/main"
sb_run "git for-each-ref --format='100%% %(refname:short)%09tab' refs/heads/main | cat -A"
sb_run "git for-each-ref --format='%(nosuch)'"
# Branches with every kind of relationship to their upstream.
git update-index -q --really-refresh
git branch -q behind v1.0~1
git branch -q even origin/main
git switch -q --detach v1.0~1
git commit -q --allow-empty -m "A side commit"
git branch -q side
git switch -q main
for b in behind even side; do git branch -q --set-upstream-to=origin/main "$b"; done
git branch -q gone main
git config branch.gone.remote origin
git config branch.gone.merge refs/heads/gone
sb_run "git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track) %(upstream:trackshort)' refs/heads"
sb_run "git for-each-ref --format='%(refname:short) %(upstream) | %(upstream:lstrip=-1) | %(upstream:track,nobracket)' refs/heads/side"
sb_run "git for-each-ref --format='%(refname:short) %(upstream:remotename) %(upstream:remoteref) %(push:short) %(push:track)' refs/heads/main"
git branch -q -D behind even side gone
sb_run "git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads"
sb_run "git for-each-ref --format='%(refname:short)%(is-base:experiment)' refs/heads refs/tags"
sb_run "git for-each-ref --format='%(refname:short)%(is-base:experiment)' refs/heads/main refs/tags"
sb_run "git for-each-ref --format='%(refname:short) %(describe) %(describe:tags)' refs/heads"
sb_run "git for-each-ref --format='%(describe) %(describe:tags=yes) %(describe:abbrev=4) %(describe:match=v1.0) %(describe:exclude=v1.1-rc1,tags)' refs/tags/v1.1-rc1"
sb_run "git for-each-ref --format='%(refname:short) %(worktreepath)' refs/heads"
sb_run "git for-each-ref --format='%(symref) <- %(refname)' refs/remotes"
sb_run "git -C ../shallow for-each-ref --format='%(symref) <- %(refname)' refs/remotes"
sb_run "git -C ../shallow for-each-ref --format='%(symref:short) <- %(refname:short)' refs/remotes"
sb_run "git for-each-ref --format='%(if)%(HEAD)%(then)* %(else)  %(end)%(refname:short)' refs/heads"
sb_run "git for-each-ref --format='%(refname:short)%(if:equals=Alan Turing)%(authorname)%(then) by Alan%(end)' refs/heads"
sb_run "git for-each-ref --format='%(refname:short)%(if:notequals=main)%(refname:short)%(then) (not main)%(end)' refs/heads"
sb_run "git for-each-ref --format='|%(align:12,right)%(refname:short)%(end)|' refs/heads"
sb_run "git for-each-ref --format='|%(align:width=14,position=middle)%(refname:short)%(end)|' refs/heads"
sb_run "git for-each-ref --format='%(if)%(upstream)%(then)%(refname:short)%(end)' refs/heads"
sb_run "git for-each-ref --format='%(if)%(upstream)%(then)%(refname:short)%(end)' --omit-empty refs/heads"
sb_run_ansi "git for-each-ref --color --format='%(color:green)%(refname:short)%(color:reset) %(subject)' refs/heads"
sb_run "git for-each-ref --color=always --format='%(color:green)%(refname:short)%(color:reset)' refs/heads | cat -A"
sb_run "git for-each-ref --format='%(color:green)%(refname:short)%(color:reset)' refs/heads | cat -A"
sb_run "git for-each-ref --color=never --format='%(color:green)%(refname:short)%(color:reset)' refs/heads | cat -A"
sb_run "git for-each-ref --shell --format='ref=%(refname) subject=%(subject)' refs/heads"
sb_run "git tag -a note -m \"It's done\" -m 'Second paragraph'"
sb_run "git for-each-ref --shell --format='%(contents)' refs/tags/note"
sb_run "git for-each-ref --perl --format='%(contents)' refs/tags/note"
sb_run "git for-each-ref --python --format='%(contents)' refs/tags/note"
sb_run "git for-each-ref --tcl --format='%(contents)' refs/tags/note"
sb_run "git tag -d note"
sb_run "git for-each-ref --shell --format='%(raw)' refs/tags/v1.0"
sb_run "git for-each-ref --format='%(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=-refname --format='%(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=creatordate --format='%(creatordate:iso) %(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=-creatordate --count=1 --format='%(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=objectsize --format='%(objectsize) %(refname:short)' refs/tags"
sb_run "git for-each-ref --sort='*authordate' --format='%(*authordate:iso) %(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=refname --sort=objecttype --format='%(objecttype) %(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=objecttype --sort=refname --format='%(objecttype) %(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=creatordate --format='%(creatordate:format:%I%p) %(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=creatordate:format:%I%p --format='%(creatordate:format:%I%p) %(refname:short)' refs/tags"
sb_run "git tag v1.10"
sb_run "git for-each-ref --format='%(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=version:refname --format='%(refname:short)' refs/tags"
sb_run "git for-each-ref --sort=-v:refname --count=1 --format='%(refname:short)' 'refs/tags/v*'"
sb_run "git -c versionsort.suffix=-rc for-each-ref --sort=version:refname --format='%(refname:short)' refs/tags"
sb_run "git branch Zebra main"
sb_run "git for-each-ref --format='%(refname:short)' refs/heads"
sb_run "git for-each-ref --ignore-case --format='%(refname:short)' refs/heads"
sb_run "git for-each-ref --ignore-case --format='%(refname:short)' refs/heads/ZEBRA"
git branch -q -D Zebra
git tag -d v1.10 >/dev/null
sb_run "git for-each-ref --merged=main --format='%(refname:short)' refs/heads refs/tags"
sb_run "git for-each-ref --no-merged=main --format='%(refname:short)' refs/heads refs/tags"
sb_run "git for-each-ref --format='%(refname:short)' refs/heads --merged"
sb_run "git for-each-ref --merged --format='%(refname:short)' refs/heads"
sb_run "git for-each-ref --contains=v1.1 --format='%(refname:short)'"
sb_run "git for-each-ref --no-contains=v1.1 --format='%(refname:short)' refs/tags"
sb_run "git for-each-ref --format='%(refname:short)' --contains"
sb_run "git for-each-ref --points-at=HEAD --format='%(refname:short)'"
sb_run "git for-each-ref --points-at=HEAD~2 --format='%(refname:short)'"
sb_run "git for-each-ref --points-at=v1.1 --format='%(refname:short)'"
sb_run "git show-ref"
sb_run "git branch --format='%(refname:short) %(upstream:track)'"
sb_run "git tag --format='%(refname:short) %(objecttype)'"
sb_run "git name-rev HEAD~4"
sb_run "git name-rev --tags --name-only HEAD~4"
