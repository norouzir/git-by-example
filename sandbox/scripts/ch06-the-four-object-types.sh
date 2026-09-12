#!/bin/bash
# Generates every transcript in Chapter 6, "The Four Object Types".
#
#   bash sandbox/scripts/ch06-the-four-object-types.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/objects" >/dev/null

sb_say "--- 1. a blob, created with no commit and no file ---"
sb_run "echo 'hello' | git hash-object -w --stdin"
sb_run git cat-file -t ce013625030ba8dba906f756967f9e9ca394464a
sb_run git cat-file -s ce013625030ba8dba906f756967f9e9ca394464a
sb_run git cat-file -p ce013625030ba8dba906f756967f9e9ca394464a

sb_say "--- 2. a blob knows nothing about its name ---"
sb_run git status --short
sb_run git count-objects -v

sb_say "--- 3. a tree, built by hand from that blob ---"
sb_run "printf '100644 blob ce013625030ba8dba906f756967f9e9ca394464a\tgreeting.txt\n' | git mktree"
sb_run git cat-file -t 57e9529754dc514a3ec10db2ff882018fbe1fcbf
sb_run git cat-file -p 57e9529754dc514a3ec10db2ff882018fbe1fcbf

sb_say "--- 4. the same tree via the index ---"
sb_write greeting.txt "hello"
git add greeting.txt
sb_run git write-tree
sb_run git cat-file -p "$(git write-tree)"

sb_say "--- 5. a commit, built by hand from that tree ---"
TREE="$(git write-tree)"
sb_run "git commit-tree $TREE -m 'Say hello'"
ROOT="$(git commit-tree "$TREE" -m 'Say hello')"
sb_run git cat-file -p "$ROOT"
sb_run git cat-file -t "$ROOT"

sb_say "--- 6. a root commit has no parent line ---"
sb_run "git cat-file -p $ROOT | head -1"

sb_say "--- 7. a child commit names its parent ---"
git update-ref refs/heads/main "$ROOT"
sb_tick
sb_write greeting.txt "hello" "goodbye"
sb_commit "Say goodbye too"
sb_run git cat-file -p HEAD

sb_say "--- 8. a merge commit names two parents ---"
git switch -q -c side HEAD~1
sb_write other.txt "from the side branch"
sb_commit "Add a side file"
git switch -q main
git merge -q --no-ff -m "Merge side into main" side
sb_tick
sb_run git cat-file -p HEAD
sb_run git log --graph --oneline

sb_say "--- 9. an annotated tag is a real object ---"
sb_run git tag -a v1.0 -m "'First release'"
sb_run git cat-file -t v1.0
sb_run git cat-file -p v1.0
sb_run git rev-parse v1.0
sb_run "git rev-parse v1.0^{commit}"

sb_say "--- 10. a lightweight tag is not an object at all ---"
sb_run git tag v1.0-light
sb_run git cat-file -t v1.0-light
sb_run git rev-parse v1.0-light
sb_run "cat .git/refs/tags/v1.0-light"
sb_run "cat .git/refs/tags/v1.0"

sb_say "--- 11. every object in the repository, by type ---"
sb_run "git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
sb_run "git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectsize) %(objectname)' | sort"

sb_say "--- 12. object headers are part of the hash, type included ---"
sb_run "printf 'hello\n' | git hash-object --stdin -t blob"
sb_run "printf 'hello\n' | git hash-object --stdin -t commit" || true

sb_say "--- 13. tree entries are sorted, so add order cannot change the hash ---"
sb_fresh "$SANDBOX_ROOT/sorting" >/dev/null
sb_write zebra.txt "x"
sb_write apple.txt "y"
sb_run "git add zebra.txt apple.txt && git write-tree"
sb_run "git rm -q --cached zebra.txt apple.txt"
sb_run "git add apple.txt zebra.txt && git write-tree"
Z="$(git rev-parse :zebra.txt)"
A="$(git rev-parse :apple.txt)"
sb_run "printf '100644 blob $Z\tzebra.txt\n100644 blob $A\tapple.txt\n' | git mktree"
