#!/bin/bash
# Generates every transcript in Chapter 40, "Protocols and Authentication".
#
#   bash sandbox/scripts/ch40-protocols-and-authentication.sh [dir]
#
# No `set -e`: many commands are shown failing on purpose.
#
# Nothing here uses a network or a real credential store:
#
#   - HOME is the sandbox root, so ~/.ssh, the credential-store file and the
#     credential-cache socket all live inside it;
#   - GIT_ASKPASS and SSH_ASKPASS are unset, so no graphical prompt can open;
#   - every SSH URL goes through bin/ssh, a stand-in that prints the command
#     line Git gave it and then runs the command on this computer;
#   - https:// URLs appear only in commands that stop before connecting
#     (a refused protocol, a URL with a password, or `--get-url`).
#
# The one program run that is not Git is ssh-keygen, with -f inside the
# sandbox; its fingerprint lines are random and the chapter cuts them.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/sandbox.sh"

sb_root "${1:-$(mktemp -d)}" >/dev/null
export HOME="$SANDBOX_ROOT"
unset GIT_ASKPASS SSH_ASKPASS
exec </dev/null

# The shell Git starts for GIT_SSH_COMMAND may spell the sandbox path its own
# way; rewrite that spelling to /home/ada too.
SANDBOX_ROOT_SH="$(cygpath -u "$SANDBOX_ROOT_WIN" 2>/dev/null || printf '%s' "$SANDBOX_ROOT")"
sb_filter() {
	sed -e "s|$SANDBOX_ROOT_WIN|$SANDBOX_DISPLAY_HOME|g" \
	    -e "s|$SANDBOX_ROOT|$SANDBOX_DISPLAY_HOME|g" \
	    -e "s|$SANDBOX_ROOT_SH|$SANDBOX_DISPLAY_HOME|g"
}

# ---------------------------------------------------------------------------
# A small atlas, in a bare "server" repository under ~/srv, and Ada's clone.
sb_fresh "$SANDBOX_ROOT/work" >/dev/null
sb_write README.md "# Atlas"
sb_commit "Start the atlas"
git tag -a v1.0 -m "First edition"
git init -q --bare "$SANDBOX_ROOT/srv/atlas.git"
git push -q "$SANDBOX_ROOT/srv/atlas.git" main v1.0
cd "$SANDBOX_ROOT"
git clone -q srv/atlas.git atlas
rm -rf work

mkdir -p bin
cat > bin/ssh <<'EOS'
#!/bin/sh
# A stand-in for ssh, for these examples only. It prints the command line
# Git gave it, then runs the command here, in the home directory, the way
# a real ssh would run it on the server.
echo "ssh $*" >&2
while test $# -gt 2; do shift; done
cd && exec sh -c "$2"
EOS
chmod +x bin/ssh
for name in plink tortoiseplink my-connect; do cp bin/ssh "bin/$name"; done

# ---------------------------------------------------------------------------
sb_say "Taking a URL apart"
sb_run "git url-parse -c host https://example.com/team/atlas.git"
sb_run "for part in scheme user host port path; do printf '%-7s' \$part; git url-parse -c \$part ssh://git@example.com:2222/team/atlas.git; done"
sb_run "for part in scheme user host port path; do printf '%-7s' \$part; git url-parse -c \$part git@example.com:team/atlas.git; done"
sb_run "git url-parse -c path example.com:~ada/atlas.git"
sb_run "git url-parse -c host https://example.com/atlas.git git@example.org:atlas.git"
sb_run "git url-parse -c password https://ada:s3cret@example.com/atlas.git"
sb_run "git url-parse -c scheme -c host https://example.com/atlas.git"
sb_run "git url-parse https://example.com/atlas.git; echo \"exit \$?\""
MSYS_NO_PATHCONV=1 sb_run "git url-parse /srv/git/atlas.git; echo \"exit \$?\""
sb_run "git url-parse ./weird:name; echo \"exit \$?\""

# ---------------------------------------------------------------------------
sb_say "What Git runs on the other end"
sb_run "cat bin/ssh"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote git@example.com:srv/atlas.git"

sb_say "Fetching, pushing and archiving"
sb_run "cd atlas"
cd atlas
sb_run "GIT_SSH_COMMAND=../bin/ssh git fetch git@example.com:srv/atlas.git"
sb_run "GIT_SSH_COMMAND=../bin/ssh git push git@example.com:srv/atlas.git main"
sb_run "GIT_SSH_COMMAND=../bin/ssh git archive --remote=git@example.com:srv/atlas.git main | tar -tf -"
sb_run "cd .."
cd ..

# ---------------------------------------------------------------------------
sb_say "Paths in SSH URLs"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://git@example.com$SANDBOX_ROOT/srv/atlas.git main"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote git@example.com:$SANDBOX_ROOT/srv/atlas.git main"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote example.com:~/srv/atlas.git main"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://example.com/~/srv/atlas.git main"
MSYS_NO_PATHCONV=1 sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://git@example.com/srv/atlas.git main"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://git@example.com:2222$SANDBOX_ROOT/srv/atlas.git main"

sb_say "Which ssh program"
sb_run "GIT_SSH=bin/plink git ls-remote ssh://git@example.com:2222$SANDBOX_ROOT/srv/atlas.git main"
sb_run "GIT_SSH=bin/tortoiseplink git ls-remote ssh://git@example.com:2222$SANDBOX_ROOT/srv/atlas.git main"
sb_run "GIT_SSH=bin/my-connect git ls-remote git@example.com:srv/atlas.git main"
sb_run "GIT_SSH=bin/my-connect git ls-remote ssh://git@example.com:2222$SANDBOX_ROOT/srv/atlas.git main"
sb_run "GIT_SSH=bin/my-connect GIT_SSH_VARIANT=ssh git ls-remote ssh://git@example.com:2222$SANDBOX_ROOT/srv/atlas.git main"
sb_run "git -c core.sshCommand=bin/my-connect -c ssh.variant=putty ls-remote ssh://git@example.com:2222$SANDBOX_ROOT/srv/atlas.git main"
sb_run "GIT_SSH_COMMAND='bin/ssh -o IdentitiesOnly=yes' GIT_SSH=bin/plink git ls-remote git@example.com:srv/atlas.git main"
sb_run "GIT_SSH='bin/ssh -v' git ls-remote git@example.com:srv/atlas.git main"

sb_say "Options Git adds"
sb_run "GIT_SSH_COMMAND=bin/ssh git -c protocol.version=0 ls-remote git@example.com:srv/atlas.git main"
sb_run "cd atlas && GIT_SSH_COMMAND=../bin/ssh git fetch -4 git@example.com:srv/atlas.git && cd .."

# ---------------------------------------------------------------------------
sb_say "Keys"
sb_run "mkdir .ssh && ssh-keygen -t ed25519 -C ada@example.com -f .ssh/id_ed25519 -N ''"
sb_run "ls .ssh"
sb_run "cut -d ' ' -f 1,3 .ssh/id_ed25519.pub"

sb_say "Several keys and accounts"
cat > .ssh/config <<'EOS'
Host github-work
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_work
	IdentitiesOnly yes
EOS
sb_run "cat .ssh/config"
sb_run "ssh -G -F .ssh/config github-work 2>/dev/null | grep -E '^(user|hostname|port|identityfile|identitiesonly) '"
sb_run "GIT_SSH_COMMAND=bin/ssh git ls-remote github-work:srv/atlas.git main"
sb_run "cd atlas && git config set core.sshCommand '../bin/ssh -i ~/.ssh/id_work -o IdentitiesOnly=yes' && git fetch git@example.com:srv/atlas.git && cd .."
git -C atlas config unset core.sshCommand

# ---------------------------------------------------------------------------
sb_say "Smart and dumb HTTP"
sb_run "git -C srv/atlas.git update-server-info && cat srv/atlas.git/info/refs"

sb_say "Proxies and settings for one site"
sb_run "cd atlas"
cd atlas
sb_run "git config set http.proxy http://proxy.example.com:3128 && git config set 'http.https://git.example.com/.proxy' ''"
sb_run "git config get --url=https://github.com/team/atlas.git http.proxy"
sb_run "git config get --url=https://git.example.com/team/atlas.git http.proxy; echo \"exit \$?\""
sb_run "git config set 'http.https://*.example.org.sslVerify' false"
sb_run "git config get --url=https://git.example.org/atlas.git http.sslVerify"
sb_run "git config get --url=https://a.b.example.org/atlas.git http.sslVerify; echo \"exit \$?\""
git config unset http.proxy
git config unset 'http.https://git.example.com/.proxy'
git config unset 'http.https://*.example.org.sslVerify'

# ---------------------------------------------------------------------------
cat > ../bin/askpass <<'EOS'
#!/bin/sh
# Stands in for a password dialog: shows the question, answers it.
echo "askpass was asked: $1" >&2
case "$1" in Username*) echo ada ;; *) echo s3cret ;; esac
EOS
chmod +x ../bin/askpass

sb_say "How Git asks"
sb_run "printf 'url=https://example.com/team/atlas.git\n' | GIT_TERMINAL_PROMPT=0 git credential fill; echo \"exit \$?\""
sb_run "cat ../bin/askpass"
sb_run "printf 'url=https://example.com/team/atlas.git\n' | GIT_ASKPASS=../bin/askpass git credential fill"
sb_run "printf 'url=https://ada@example.com/team/atlas.git\n' | GIT_ASKPASS=../bin/askpass git credential fill"
sb_run "printf 'url=https://example.com/team/atlas.git\n' | git -c credential.interactive=false credential fill"

sb_say "Usernames"
sb_run "git config set credential.https://example.com.username ada"
sb_run "printf 'protocol=https\nhost=example.com\n' | GIT_ASKPASS=../bin/askpass git credential fill"
sb_run "printf 'protocol=https\nhost=example.org\n' | GIT_TERMINAL_PROMPT=0 git credential fill"
sb_run "git config set 'credential.https://example.net/team.username' ada"
sb_run "git config get --url=https://example.net/team/atlas.git credential.username"
sb_run "git config get --url=https://example.net/teamwork/atlas.git credential.username; echo \"exit \$?\""
git config unset credential.https://example.com.username
git config unset 'credential.https://example.net/team.username'

sb_say "The store helper"
sb_run "git config set credential.helper 'store --file ../git-credentials'"
sb_run "printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential approve"
sb_run "cat ../git-credentials"
sb_run "printf 'protocol=https\nhost=example.com\n' | git credential fill"
sb_run "printf 'protocol=https\nhost=example.com\nusername=bob\n' | GIT_TERMINAL_PROMPT=0 git credential fill"
sb_run "printf 'protocol=https\nhost=example.com\npath=team/atlas.git\n' | git credential fill"
sb_run "printf 'protocol=https\nhost=example.com\npath=team/atlas.git\n' | GIT_TERMINAL_PROMPT=0 git -c credential.useHttpPath=true credential fill"
sb_run "printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential reject && wc -c ../git-credentials"

sb_say "The cache helper"
sb_run "git config set credential.helper 'cache --timeout 300 --socket $SANDBOX_ROOT/cache/socket'"
sb_run "printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential approve"
sb_run "printf 'protocol=https\nhost=example.com\n' | git credential fill"
sb_run "git credential-cache --socket $SANDBOX_ROOT/cache/socket exit"
sb_run "printf 'protocol=https\nhost=example.com\n' | GIT_TERMINAL_PROMPT=0 git credential fill"
git credential-cache --socket "$SANDBOX_ROOT/cache/socket" exit >/dev/null 2>&1
git config unset credential.helper

sb_say "Several helpers"
sb_run "git config set credential.helper 'store --file ../git-credentials'"
sb_run "git config set --append credential.helper '!f() { echo \"second helper: \$1\" >&2; test \"\$1\" = get && echo password=from-second; }; f'"
sb_run "git config get --all credential.helper"
sb_run "printf 'protocol=https\nhost=example.com\nusername=ada\n' | git credential fill"
sb_run "printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential approve"
sb_run "printf 'protocol=https\nhost=example.com\n' | git credential fill"
sb_run "printf 'protocol=https\nhost=example.com\n' | GIT_TERMINAL_PROMPT=0 git -c credential.helper= credential fill"
git config unset --all credential.helper
rm -f ../git-credentials

sb_say "Capabilities"
sb_run "git credential capability"

sb_say "Credentials in a URL"
sb_run "git remote add leaky https://ada:s3cret@example.com/team/atlas.git"
sb_run "git -c transfer.credentialsInUrl=die fetch leaky"
sb_run "git remote get-url leaky"
git remote remove leaky

# ---------------------------------------------------------------------------
sb_say "Which protocols Git may use"
sb_run "git -c protocol.file.allow=never ls-remote ../srv/atlas.git"
sb_run "git -c protocol.allow=never ls-remote https://example.com/team/atlas.git"
sb_run "GIT_ALLOW_PROTOCOL=https:ssh git ls-remote ../srv/atlas.git"
sb_run "GIT_PROTOCOL_FROM_USER=0 git ls-remote ../srv/atlas.git"
sb_run "GIT_PROTOCOL_FROM_USER=0 git -c protocol.file.allow=always ls-remote ../srv/atlas.git main"

sb_say "Remote helpers"
sb_run "git ls-remote 'ext::git %s $SANDBOX_ROOT_WIN/srv/atlas.git'"
sb_run "git -c protocol.ext.allow=always ls-remote 'ext::git %s $SANDBOX_ROOT_WIN/srv/atlas.git' main"
sb_run "git ls-remote hg::https://example.com/atlas"
sb_run "git remote add old https://example.com/atlas && git config set remote.old.vcs svn && git ls-remote old"
git remote remove old

# ---------------------------------------------------------------------------
sb_say "Rewriting URLs"
sb_run "git remote add hub https://github.com/team/atlas.git"
sb_run "git config set url.git@github.com:.insteadOf https://github.com/ && git remote -v | grep hub"
sb_run "git ls-remote --get-url https://github.com/ada/notes.git"
sb_run "git config set url.git@work.example.com:.insteadOf https://github.com/team/ && git remote get-url hub"
git config unset url.git@work.example.com:.insteadOf
git config unset url.git@github.com:.insteadOf
sb_run "git config set url.git@github.com:.pushInsteadOf https://github.com/ && git remote -v | grep hub"
sb_run "git remote set-url --push hub https://github.com/team/atlas.git && git remote -v | grep hub"
git remote remove hub
git config unset url.git@github.com:.pushInsteadOf

# ---------------------------------------------------------------------------
sb_say "Protocol versions"
sb_run "GIT_TRACE_PACKET=1 git ls-remote file://$SANDBOX_ROOT/srv/atlas.git 2>&1 >/dev/null | grep -o 'ls-remote[<>].*'"
sb_run "GIT_TRACE_PACKET=1 git -c protocol.version=0 ls-remote file://$SANDBOX_ROOT/srv/atlas.git 2>&1 >/dev/null | grep -o 'ls-remote[<>].*'"
sb_run "GIT_PROTOCOL=version=2 git upload-pack --advertise-refs ../srv/atlas.git; echo"
