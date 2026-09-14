#!/bin/bash
# Generates every transcript in Chapter 9, "init and clone".
#
#   bash sandbox/scripts/ch09-init-and-clone.sh [dir]
#
# The questions this chapter answers are listed in the chapter itself. Sections
# 1 to 12 keep their original order so that the commit hashes they print do not
# change; the sections after them add the rest of the chapter.
#
# No -e here on purpose: many examples show a command failing, and the error is
# the answer being demonstrated.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null

sb_say "--- 1. git init and what it makes ---"
cd "$SANDBOX_ROOT"
sb_run git init project
cd project
sb_run "find .git -maxdepth 1 | sort"
sb_run "find .git -type f | sort"
sb_run "cat .git/HEAD"
sb_run "cat .git/config"

sb_say "--- 2. init is safe to run twice ---"
sb_run git init
sb_run git init

sb_say "--- 3. init does not touch your files ---"
sb_write keep.txt "still here"
sb_run git init
sb_run cat keep.txt
sb_run git status --short

sb_say "--- 4. choosing the first branch name ---"
cd "$SANDBOX_ROOT"
sb_run git init -b trunk other
sb_run "cat other/.git/HEAD"

sb_say "--- 5. a bare repository has no working tree ---"
sb_run git init --bare server.git
sb_run "ls server.git"
sb_run "git -C server.git config core.bare"
sb_run "git -C server.git rev-parse --is-bare-repository"

sb_say "--- 6. building something to clone ---"
cd "$SANDBOX_ROOT/project"
sb_write README.md "# Project"
sb_commit "Add README"
sb_write src/main.py "print('one')"
sb_commit "Add main"
# The tag is made at the time the next commit will use, without moving the
# clock, so every commit hash printed in this chapter stays as it was.
git tag -a v1.0 -m "First release"
sb_write src/util.py "def helper(): pass"
sb_commit "Add util"
git switch -q -c topic
sb_write src/extra.py "extra"
sb_commit "Add extra on topic"
git switch -q main
git remote add origin "$SANDBOX_ROOT/server.git"
git push -q origin main topic v1.0
sb_run git log --oneline

sb_say "--- 7. clone, and what it set up for you ---"
cd "$SANDBOX_ROOT"
sb_run git clone server.git fresh
cd fresh
sb_run git log --oneline
sb_run git remote -v
sb_run git branch
sb_run git branch -a
sb_run git status -sb
sb_run "git config get remote.origin.url"
sb_run "git config get branch.main.remote"
sb_run "git config get branch.main.merge"

sb_say "--- 8. clone refuses to overwrite a non-empty directory ---"
cd "$SANDBOX_ROOT"
mkdir -p occupied && printf 'mine\n' > occupied/file.txt
sb_run git clone server.git occupied
sb_run "ls occupied"
mkdir -p empty-target
sb_run git clone server.git empty-target

sb_say "--- 9. cloning an empty repository warns ---"
sb_run git init --bare nothing.git
sb_run git clone nothing.git nothing-clone
sb_run "git -C nothing-clone status"

sb_say "--- 10. shallow clones, and the local-path trap ---"
sb_run git clone --depth 1 server.git shallow-broken
sb_run "git -C shallow-broken log --oneline"
sb_run "git -C shallow-broken rev-parse --is-shallow-repository"
sb_run git clone --depth 1 "file://$SANDBOX_ROOT/server.git" shallow
sb_run "git -C shallow log --oneline"
sb_run "git -C shallow rev-parse --is-shallow-repository"
sb_run "cat shallow/.git/shallow"
sb_run "git -C shallow log --oneline main"

sb_say "--- 10b. single-branch clones ---"
sb_run git clone --single-branch --branch topic server.git just-topic
sb_run "git -C just-topic branch -a"
sb_run "git -C just-topic log --oneline"
sb_run "git -C just-topic config get --all remote.origin.fetch"

sb_say "--- 11. bare and mirror clones ---"
sb_run git clone --bare server.git copy-bare.git
sb_run "ls copy-bare.git | head"
sb_run "git -C copy-bare.git config get --all remote.origin.fetch"
sb_run git clone --mirror server.git copy-mirror.git
sb_run "git -C copy-mirror.git config get --all remote.origin.fetch"
sb_run "git -C copy-bare.git branch"
sb_run "git -C copy-mirror.git branch"

sb_say "--- 12. clone is four commands in a coat ---"
mkdir -p byhand && cd byhand
sb_run git init -q
sb_run git remote add origin "$SANDBOX_ROOT/server.git"
sb_run git fetch -q origin
sb_run git switch -q main
sb_run git log --oneline
sb_run git status -sb

# =============================================================================
cd "$SANDBOX_ROOT"
U="file://$SANDBOX_ROOT/server.git"

sb_say "--- I1. where the repository goes ---"
sb_run "git init deep/er/still"
sb_run "ls deep/er"
sb_run "cd fresh && git init inner && cd .."
sb_write fresh/inner/a.txt "inside the inner repository"
sb_run "git -C fresh status --short"
sb_run "git -C fresh add inner"
git -C fresh/inner add a.txt
git -C fresh/inner commit -q -m "Inner commit"
sb_run "git -C fresh add inner"
sb_run "git -C fresh ls-files -s"
sb_run "git -C fresh rm --cached inner"
sb_run "git -C fresh restore --staged inner"
sb_run "git -C fresh status --short"
rm -rf fresh/inner

sb_say "--- I2. reinitialising ignores a new branch name ---"
sb_run "git -C project init -b other"
sb_run "git -C project branch --show-current"

sb_say "--- I3. bare repositories have nowhere to work ---"
sb_run "git -C server.git status"
sb_run "git -C server.git add README.md"

sb_say "--- I4. templates ---"
mkdir -p tpl/hooks tpl/info
printf '#!/bin/sh\necho checking\n' > tpl/hooks/pre-commit
printf 'secret.txt\n' > tpl/info/exclude
printf 'Our team project\n' > tpl/description
printf 'not copied\n' > tpl/.hidden
sb_run "find tpl -type f | sort"
sb_run "git init --template=tpl withtpl"
sb_run "find withtpl/.git -maxdepth 2 -type f | sort"
sb_run "cat withtpl/.git/description"
sb_run "git init --template= notpl"
sb_run "find notpl/.git | sort"
sb_run "git -c init.templateDir=tpl init -q fromconfig"
sb_run "ls fromconfig/.git"
sb_run "git -c init.templateDir=../tpl init -q fromconfig2 && ls fromconfig2/.git/hooks"
sb_run "GIT_TEMPLATE_DIR=$SANDBOX_ROOT/tpl git init -q fromenv && ls fromenv/.git/hooks"
sb_run "git clone -q --template=tpl server.git clonetpl && ls clonetpl/.git/hooks"

sb_say "--- I5. keeping the repository somewhere else ---"
sb_run "git init --separate-git-dir=store sep"
sb_run "cat sep/.git"
sb_run "ls store"
sb_run "git -C sep rev-parse --git-dir"
sb_run "cd sep && git init --separate-git-dir=../store2 && cd .."
sb_run "cat sep/.git"
sb_run "ls store"
sb_run "git clone -q --separate-git-dir=clonestore server.git sepclone"
sb_run "cat sepclone/.git"

sb_say "--- I6. sharing between users ---"
sb_run "git init --shared=group shr"
sb_run "git -C shr config list --local"
sb_run "git init --shared=umask shr-umask"
sb_run "git -C shr-umask config get core.sharedRepository"
sb_run "git init --shared=all shr-all"
sb_run "git -C shr-all config get core.sharedRepository"
sb_run "git init --shared=0640 shr-0640"
sb_run "git -C shr-0640 config get core.sharedRepository"
sb_run "git init --shared shr-plain"
sb_run "git -C shr-plain config get core.sharedRepository"
sb_run "git init --shared=wrong shr-wrong"

sb_say "--- I7. hash and ref formats ---"
sb_run "git init --object-format=sha256 h256"
cd h256
sb_write a.txt "hello"
sb_commit "First commit"
sb_run "git rev-parse --show-object-format"
sb_run "git rev-parse HEAD"
cd "$SANDBOX_ROOT"
sb_run "git init --ref-format=reftable rft"
cd rft
sb_write a.txt "hello"
sb_commit "First commit"
sb_run "git rev-parse --show-ref-format"
sb_run "ls .git/refs"
sb_run "cat .git/refs/heads"
sb_run "git rev-parse main"
cd "$SANDBOX_ROOT"
sb_run "git clone -q --ref-format=reftable server.git rclone && git -C rclone rev-parse --show-ref-format"
sb_run "git init --object-format=md5 badhash"
sb_run "git init --ref-format=nope badref"

sb_say "--- I8. quiet ---"
sb_run "git init -q quiet"

sb_say "--- C1. the directory clone makes ---"
sb_run "git clone -q server.git"
sb_run "ls -d server"
mkdir -p elsewhere
sb_run "cd elsewhere && git clone -q ../project/.git && ls && cd .."
mkdir -p inplace
sb_run "cd inplace && git clone -q ../server.git . && ls && cd .."
sb_run "git clone nothing-here.git whatever"

sb_say "--- C2. checking out a branch, a tag, or nothing ---"
sb_run "git clone -b v1.0 server.git attag"
sb_run "git -C attag status"
sb_run "git clone -b nosuch server.git missing"
sb_run "git clone --revision=v1.0 server.git atrev"
sb_run "git -C atrev branch -a"
sb_run "git -C atrev log --oneline"
sb_run "git -C atrev config get --all remote.origin.fetch"
sb_run "git clone --revision=v1.0 -b main server.git both"
sb_run "git clone -n server.git nocheck"
sb_run "ls -A nocheck"
sb_run "git -C nocheck status --short"
sb_run "git -C nocheck restore --staged --worktree :/ && ls nocheck"

sb_say "--- C3. naming the remote ---"
sb_run "git clone -q -o upstream server.git named"
sb_run "git -C named remote"
sb_run "git -C named branch -vv"
sb_run "git -c clone.defaultRemoteName=hub clone -q server.git named2"
sb_run "git -C named2 remote"

sb_say "--- C4. configuration during the clone ---"
sb_run "git clone -q -c core.autocrlf=input -c user.name='Grace Hopper' server.git cfg"
sb_run "git -C cfg config list --local"

sb_say "--- C5. other ways to cut history ---"
sb_run "git -C server.git log --format='%h %ad %s' --date=iso main"
sb_run "git clone -q --shallow-since=2026-01-05T09:30:00Z $U since"
sb_run "git -C since log --oneline"
sb_run "git clone -q --shallow-exclude=v1.0 $U excl"
sb_run "git -C excl log --oneline"
sb_run "git clone -q --depth 1 --no-single-branch $U deepall"
sb_run "git -C deepall branch -a"
sb_run "git clone -q shallow fromshallow2"
sb_run "git -C fromshallow2 rev-parse --is-shallow-repository"
sb_run "git clone --reject-shallow shallow fromshallow"
sb_run "git -c clone.rejectShallow=true clone shallow fromshallow3"
sb_run "git -c clone.rejectShallow=true clone -q --no-reject-shallow shallow fromshallow4"
sb_run "git -C fromshallow4 rev-parse --is-shallow-repository"

sb_say "--- C6. tags ---"
sb_run "git clone -q server.git withtags"
sb_run "git -C withtags tag"
sb_run "git clone -q --no-tags server.git notags"
sb_run "git -C notags tag"
sb_run "git -C notags config get remote.origin.tagOpt"
sb_run "git clone -q --no-tags --tags server.git bothtags"
sb_run "git -C bothtags tag"

sb_say "--- C7. partial clones ---"
sb_run "git clone --filter=blob:none $U part1"
git -C server.git config set uploadpack.allowFilter true
sb_run "git -C server.git config set uploadpack.allowFilter true"
sb_run "git clone --filter=blob:none $U part2"
sb_run "git -C part2 config list --local"
sb_run "git -C part2 rev-list --objects --all --missing=print | grep '^?'"
sb_run "git -C part2 ls-tree -r origin/topic"

sb_say "--- C8. sparse clones ---"
sb_run "git clone -q --sparse server.git sp"
sb_run "ls -A sp"
sb_run "git -C sp ls-files"

sb_say "--- C9. local clones and the object store ---"
# A repository no other clone has linked to yet, so the counts start at 1.
git clone -q --bare --no-hardlinks server.git alone.git
OBJ="objects/$(git -C alone.git rev-parse main:README.md | cut -c1-2)/$(git -C alone.git rev-parse main:README.md | cut -c3-)"
sb_run "git -C alone.git rev-parse main:README.md"
sb_run "stat -c %h alone.git/$OBJ"
sb_run "git clone -q alone.git hard"
sb_run "stat -c %h alone.git/$OBJ hard/.git/$OBJ"
sb_run "git clone -q --no-hardlinks alone.git soft"
sb_run "stat -c %h alone.git/$OBJ soft/.git/$OBJ"
sb_run "git clone -q --local $U withlocal"
sb_run "git -C withlocal count-objects -v"
sb_run "git clone -q --no-local server.git noloc"
sb_run "git -C noloc count-objects -v"
sb_run "git clone -q --shared server.git borrowed"
sb_run "cat borrowed/.git/objects/info/alternates"
sb_run "git -C borrowed count-objects -v"
sb_run "git -C borrowed log --oneline"
sb_run "git clone -q --reference server.git $U referenced"
sb_run "cat referenced/.git/objects/info/alternates"
sb_run "git clone -q --reference nowhere.git $U refnot"
sb_run "git clone -q --reference-if-able nowhere.git $U refable"
sb_run "git -C refable log --oneline -1"
sb_run "git clone -q --reference server.git --dissociate $U dissociated"
sb_run "ls dissociated/.git/objects/info"
sb_run "git -C dissociated count-objects -v"

sb_say "--- C10. how much clone prints ---"
sb_run "git clone server.git talk0"
sb_run "git clone -q server.git talk1"
sb_run "git clone -v server.git talk2"
sb_run "git clone --progress server.git talk3"
sb_run "git clone --progress $U talk4 2>&1 | tr '\\r' '\\n' | grep 'done'"

sb_say "--- C11. the program on the other end ---"
sb_run "git clone -q -u git-upload-pack $U up1 && ls up1"
sb_run "git clone -u no-such-program $U up2"

sb_say "--- C12. copying the directory instead ---"
sb_fresh "$SANDBOX_ROOT/work" >/dev/null
sb_write README.md "# Work"
sb_write .gitignore "build/"
sb_commit "Add README"
git remote add origin "$SANDBOX_ROOT/server.git"
sb_write build/out.o "compiled"
sb_write notes.txt "not added yet"
git config set user.email "me@work.example"
cd "$SANDBOX_ROOT"
sb_run "cp -r work copied"
sb_run "git clone -q work cloned"
sb_run "ls -A copied"
sb_run "ls -A cloned"
sb_run "git -C copied remote -v"
sb_run "git -C cloned remote -v"
sb_run "git -C copied config get user.email"
sb_run "git -C cloned config get user.email"
sb_run "git -C copied status --short"
sb_run "git -C cloned status --short"
