#!/bin/bash
# Generates every transcript in Chapter 4, "What Git Actually Stores".
#
#   bash sandbox/scripts/ch04-what-git-stores.sh [dir]

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
sb_fresh "$SANDBOX_ROOT/store" >/dev/null

sb_say "--- 1. one file, one commit ---"
sb_write poem.txt "roses are red" "violets are blue"
sb_commit "Add the poem"
sb_run git cat-file -p HEAD

sb_say "--- 2. the tree the commit points at ---"
sb_run git cat-file -p 'HEAD^{tree}'

sb_say "--- 3. the blob the tree points at ---"
sb_run git cat-file -p 'HEAD:poem.txt'

sb_say "--- 4. object types and sizes ---"
sb_run git cat-file -t HEAD
sb_run git cat-file -t 'HEAD^{tree}'
sb_run git cat-file -t 'HEAD:poem.txt'
sb_run git cat-file -s 'HEAD:poem.txt'
sb_run "git cat-file -e HEAD:poem.txt && echo exists"
sb_run "git cat-file -e d531a8e56cfd2440190959775e87a1162a38907c || echo \"missing, exit \$?\""
sb_run "git cat-file -e HEAD:missing.txt || echo \"missing, exit \$?\""

sb_say "--- 5. change one line, commit again ---"
sb_write poem.txt "roses are red" "violets are violet"
sb_commit "Fix the second line"
sb_run git cat-file -p 'HEAD^{tree}'
sb_run git cat-file -p 'HEAD~1^{tree}'

sb_say "--- 6. both whole versions are stored, not a diff ---"
sb_run git cat-file -p 'HEAD:poem.txt'
sb_run git cat-file -p 'HEAD~1:poem.txt'
sb_run git cat-file -s 'HEAD:poem.txt'
sb_run git cat-file -s 'HEAD~1:poem.txt'

sb_say "--- 7. hashing content by hand, with no repository involved ---"
sb_run "printf 'roses are red\nviolets are blue\n' | git hash-object --stdin"
sb_run "printf 'roses are red\nviolets are blue\n' | wc -c"
sb_run "printf 'blob 31\0roses are red\nviolets are blue\n' | sha1sum | cut -d' ' -f1"

sb_say "--- 8. identical content is stored once ---"
sb_write a.txt "same bytes"
sb_write b.txt "same bytes"
sb_write c.txt "different bytes"
sb_commit "Add three files, two of them identical"
sb_run git cat-file -p 'HEAD^{tree}'

sb_say "--- 9. an unchanged file keeps its blob across commits ---"
sb_run git rev-parse 'HEAD:a.txt' 'HEAD~1:poem.txt' 'HEAD:poem.txt'

sb_say "--- 10. directories are not objects on their own ---"
mkdir -p empty-dir
sb_run git status --short
sb_run git add empty-dir
sb_run git status --short
sb_run git add no-such-path || true

sb_say "--- 11. a directory with a file in it becomes a tree ---"
sb_write nested/deep/file.txt "hello"
sb_commit "Add a nested file"
sb_run git cat-file -p 'HEAD^{tree}'
sb_run git cat-file -p 'HEAD:nested'
sb_run git cat-file -p 'HEAD:nested/deep'

sb_say "--- 12. renames are not stored, they are deduced ---"
sb_run git rev-parse 'HEAD:c.txt'
git mv c.txt renamed.txt
sb_commit "Rename c.txt"
sb_run git rev-parse 'HEAD:renamed.txt'
sb_run git cat-file -p 'HEAD^{tree}'
sb_run git show --stat --oneline HEAD
sb_run git log --follow --oneline -- renamed.txt

sb_say "--- 13. what the repository holds in total ---"
sb_run git count-objects -v
sb_run "git cat-file --batch-all-objects --batch-check='%(objecttype) %(objectsize) %(objectname)' | sort"

sb_say "--- 14. the executable bit lives in the tree, not the blob ---"
sb_write plain.txt "x"
sb_run "cp plain.txt script.sh && git add plain.txt && git add --chmod=+x script.sh"
sb_run "git write-tree | xargs git cat-file -p | grep -E 'plain.txt|script.sh'"
git rm -q --cached plain.txt script.sh
rm -f plain.txt script.sh

sb_say "--- 15. the empty tree ---"
sb_run "git hash-object -t tree /dev/null"
