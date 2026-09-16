#!/bin/bash
# Generates every transcript in Chapter 37, "Removing Files and Secrets from
# History".
#
#   bash sandbox/scripts/ch37-removing-files-and-secrets.sh [dir]
#
# No `set -e`: several commands are shown refusing on purpose.
#
# PREREQUISITE: git-filter-repo must be on PATH. It is not part of Git; see
# CLAUDE.md. Without it the filter-repo section of the chapter cannot be
# verified.
#
# "now" is deliberately NOT pinned: `git gc --prune=now` compares against real
# file times, and pinning the clock would stop it pruning anything.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
exec </dev/null

# Each demonstration starts from a copy of the same repository, because most of
# them rewrite every commit in it and cannot be undone.
build() {
	rm -rf "$SANDBOX_ROOT/$1"
	git clone -q --no-local "$SANDBOX_ROOT/service" "$SANDBOX_ROOT/$1" 2>/dev/null
	cd "$SANDBOX_ROOT/$1"
	git fetch -q origin 'refs/tags/*:refs/tags/*' 2>/dev/null
}

# ---------------------------------------------------------------------------
# A small service, with a private key committed by mistake.
sb_fresh "$SANDBOX_ROOT/service" >/dev/null
sb_write README.md "# service"
sb_commit "Start the service"
sb_write config.yml "port: 8080"
sb_commit "Add the config"
sb_write deploy.pem "-----BEGIN PRIVATE KEY-----" "s3cret-do-not-share" "-----END PRIVATE KEY-----"
sb_commit "Add the deploy key"
sb_write deploy.sh "ssh -i deploy.pem server"
sb_commit "Add the deploy script"
sb_write docs/guide.md "# Guide" "Run deploy.sh."
sb_write docs/faq.md "## Why?" "Because."
sb_commit "Add the documentation"
git tag -a v1.0 -m "Version 1.0"
git rm -q deploy.pem
sb_commit "Remove the deploy key"
sb_write notes.md "Everything is fine."
sb_commit "Add some notes"

git init -q --bare "$SANDBOX_ROOT/origin.git"
git remote add origin "$SANDBOX_ROOT/origin.git"
git push -q --tags origin main

sb_say "The example repository"
sb_run "git log --oneline --decorate"
sb_run "ls"
sb_run "git log --oneline --all -- deploy.pem"
sb_run "git show v1.0:deploy.pem"

sb_say "The file is still in every clone"
sb_run "git rev-list --objects --all | grep deploy.pem"
sb_run "git cat-file -p \$(git rev-parse v1.0^{tree}) | head -5"

# ---------------------------------------------------------------------------
sb_say "It is not committed yet"
build not-yet
sb_write secret.env "TOKEN=abc123"
sb_run "git add secret.env && git status --short"
sb_run "git rm --cached -q secret.env && git status --short"
sb_write .gitignore "*.env"
sb_run "git add .gitignore && git status --short"

sb_say "It is in the last commit"
build last-commit
sb_write secret.env "TOKEN=abc123"
sb_write settings.md "The settings live in secret.env."
sb_run "git add -A && git commit -q -m 'Add the settings' && git show --stat --oneline HEAD"; sb_tick
sb_run "git rm --cached -q secret.env && git commit -q --amend --no-edit && git show --stat --oneline HEAD"; sb_tick
sb_run "git log --all --oneline -- secret.env"

# ---------------------------------------------------------------------------
sb_say "It is everywhere: filter-branch"
build filter-branch
sb_run "git filter-branch --index-filter 'git rm --cached --ignore-unmatch deploy.pem' --prune-empty --tag-name-filter cat -- --all"
sb_run "git log --oneline --decorate"
sb_run "git log --oneline --all -- deploy.pem"
sb_run "git show v1.0:deploy.pem"

sb_say "The original refs"
sb_run "git for-each-ref refs/original"
sb_run "git log --oneline -1 refs/original/refs/heads/main"
sb_run "git show refs/original/refs/heads/main~2:deploy.pem"

sb_say "Making the old objects go away"
sb_run "git for-each-ref --format='%(refname)' refs/original | xargs -n 1 git update-ref -d"
sb_run "git reflog expire --expire=now --all"
sb_run "git gc --prune=now --quiet"
sb_run "git cat-file -t \$(git rev-parse v1.0) 2>&1 | head -2"
sb_run "git rev-list --objects --all | grep deploy.pem || echo 'not in any object'"

sb_say "Checking it is really gone"
sb_run "git log --all --oneline -- deploy.pem"
sb_run "git grep -q 's3cret' \$(git rev-list --all) -- deploy.pem || echo 'no match in any commit'"

# ---------------------------------------------------------------------------
sb_say "The same thing with filter-repo"
build filter-repo
sb_run "git filter-repo --path deploy.pem --invert-paths --force"
sb_run "git log --oneline --decorate"
sb_run "git log --oneline --all -- deploy.pem"
sb_run "git rev-list --objects --all | grep deploy.pem || echo 'not in any object'"
sb_run "git remote -v"
sb_run "ls .git/filter-repo"

sb_say "Removing by content rather than by name"
build filter-repo-text
sb_write replacements.txt "s3cret-do-not-share==>REMOVED"
sb_run "git filter-repo --replace-text ../filter-repo-text/replacements.txt --force"
sb_run "git show v1.0:deploy.pem"
sb_run "git log --oneline"

sb_say "Analysing first"
build filter-repo-analyze
sb_run "git filter-repo --analyze"
sb_run "ls .git/filter-repo/analysis"
sb_run "head -12 .git/filter-repo/analysis/path-all-sizes.txt"

# ---------------------------------------------------------------------------
sb_say "Other filters"
build other-filters
sb_run "git filter-branch --msg-filter 'sed s/deploy/DEPLOY/' -- --all 2>&1 | tail -3"
sb_run "git log --oneline"
build env-filter
sb_run "git filter-branch --env-filter 'GIT_AUTHOR_EMAIL=ada@new.example; export GIT_AUTHOR_EMAIL' -- --all 2>&1 | tail -3"
sb_run "git log -1 --format='%an <%ae>'"
build subdir
sb_run "git filter-branch --subdirectory-filter docs -- --all 2>&1 | tail -3"
sb_run "ls && git log --oneline"

sb_say "The slow way"
build tree-filter
sb_run "git filter-branch --tree-filter 'rm -f deploy.pem' --prune-empty -- --all 2>&1 | tail -3"
sb_run "git log --oneline --all -- deploy.pem"
sb_run "git log --oneline"

sb_say "What filter-branch says before it starts"
build warning
sb_run "git filter-branch --index-filter 'git rm --cached --ignore-unmatch nothing.txt' HEAD 2>&1 | head -12"

# ---------------------------------------------------------------------------
sb_say "What the rewrite does not reach"
cd "$SANDBOX_ROOT/filter-branch"
sb_run "git -C $SANDBOX_ROOT/origin.git log --oneline --all -- deploy.pem"
sb_run "git -C $SANDBOX_ROOT/origin.git show v1.0:deploy.pem"
sb_run "git -C $SANDBOX_ROOT/service log --oneline --all -- deploy.pem"

# ---------------------------------------------------------------------------
sb_say "Keeping it from happening again"
cd "$SANDBOX_ROOT/service"
sb_write .gitignore "*.pem" "*.env" ".env"
sb_run "git add .gitignore && git commit -q -m 'Ignore keys and environment files'"; sb_tick
sb_write new.pem "another key"
sb_run "git status --short"
sb_run "git add new.pem"
sb_run "git add -f new.pem && git status --short"
sb_run "git rm -q --cached new.pem"
cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
if git diff --cached --name-only | grep -q '\.pem$'
then
	echo "pre-commit: refusing to commit a .pem file"
	exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit
sb_run "git add -f new.pem && git commit -m 'Add another key'"
rm .git/hooks/pre-commit
sb_run "git rm -q --cached new.pem && rm new.pem"
