# Chapter 40. Protocols and Authentication

## What it is

Every command that talks to another repository, `git clone`, `git fetch`,
`git pull`, `git push`, `git ls-remote`, has to do two things before any commit
moves: reach the other repository, and, when the other side asks, prove who you
are. This chapter is about both.

*Reaching* it is the job of a *transport*, chosen by the form of the URL: a
local path, SSH, HTTPS, or Git's own `git://` protocol. Whatever the transport,
the conversation is the same. Git starts a program on the other side,
`git-upload-pack` to fetch or `git-receive-pack` to push, and the two
programs exchange lines in Git's *wire protocol*.

*Proving who you are* is, for the two transports that do it, mostly not Git's
job. Over SSH, the `ssh` program does all of it with a key pair, and Git never
sees a password. Over HTTPS, the server asks for a username and a password or
token, and Git gets them from a *credential helper*, a separate program that
remembers them, or by asking you. A repository never stores who you are, and
cloning one never gives you permission to push to it.

| Term | Means |
|---|---|
| *transport* | the way Git reaches another repository: local, SSH, HTTP(S), `git://`, or a helper program |
| *wire protocol* | the language the two Git programs speak over the transport; it has versions 0, 1 and 2 |
| *smart HTTP* | HTTP with a Git program on the server, which speaks the wire protocol; what every Git host uses |
| *dumb HTTP* | HTTP with no Git on the server, only files for Git to download one by one |
| *key pair* | an SSH *private key*, which stays on your computer, and its *public key*, which you give to the server |
| *passphrase* | a password that encrypts the private key on disk |
| *host key* | the server's own key, which `ssh` checks so that you know you reached the right server |
| *known_hosts* | the file where `ssh` records the host keys it has accepted, `~/.ssh/known_hosts` |
| *token* | a long random string a host issues for use in place of your password; *personal access token* on GitHub and GitLab |
| *credential helper* | a program Git asks for a username and password, and tells whether they worked |
| *askpass program* | a program Git runs to ask you for a password, instead of asking in the terminal |

<details class="questions" markdown="1">
<summary>Questions this chapter answers</summary>

**[What it is](#what-it-is)**

- [What happens between typing `git push` and the server receiving my commits?](#what-it-is)
- [Does Git store my password or who I am in the repository?](#what-it-is)

**[The transports at a glance](#the-transports-at-a-glance)**

- [What ways can Git reach another repository, and which of them are encrypted?](#the-transports-at-a-glance)
- [Which transports need a password, a key, or nothing?](#the-transports-at-a-glance)

**[The examples](#the-examples)**

- [How can this chapter show SSH and HTTPS without a server?](#the-examples)

**[Taking a URL apart](#taking-a-url-apart)**

- [How do I see which host, user, port and path Git reads from a URL?](#taking-a-url-apart)
- [Is `git@example.com:team/atlas.git` a path on my computer or a server address?](#taking-a-url-apart)
- [Why does `git url-parse` refuse a path that `git clone` accepts?](#taking-a-url-apart)

**[What Git runs on the other end](#what-git-runs-on-the-other-end)**

- [What exactly does Git ask `ssh` to run on the server?](#what-git-runs-on-the-other-end)
- [Does the server need Git installed?](#what-git-runs-on-the-other-end)
- [Is pushing a different program on the server from fetching?](#fetching-pushing-and-archiving)

**[SSH](#ssh)**

- [Is `ssh://host/path` the same as `host:path`?](#paths-in-ssh-urls)
- [Git says `'atlas.git' does not appear to be a git repository`, but it's there. Why?](#paths-in-ssh-urls)
- [How do I use a server that listens on a port other than 22?](#paths-in-ssh-urls)
- [How do I make an SSH key, and which file do I give to the server?](#keys)
- [Should my key have a passphrase? How do I avoid typing it every time?](#passphrases-and-the-agent)
- [`ssh` asks "Are you sure you want to continue connecting". What should I check?](#the-first-connection)
- [What does "REMOTE HOST IDENTIFICATION HAS CHANGED" mean?](#the-first-connection)
- [How do I check that my key works before I clone?](#testing-the-key)
- [I get `Permission denied (publickey)`. What does that tell me?](#testing-the-key)
- [How do I use two accounts on the same host, each with its own key?](#several-keys-and-accounts)
- [How do I make one repository use a particular key?](#several-keys-and-accounts)
- [How do I make Git use PuTTY, or another SSH program?](#which-ssh-program)
- [What is the difference between `GIT_SSH`, `GIT_SSH_COMMAND` and `core.sshCommand`?](#which-ssh-program)
- [Git says "ssh variant 'simple' does not support setting port". What is a variant?](#which-ssh-program)
- [Why does Git add `-o SendEnv=GIT_PROTOCOL` to the ssh command?](#options-git-adds)
- [My network blocks port 22. Can I still use SSH?](#when-port-22-is-blocked)

**[HTTPS](#https)**

- [What is the difference between smart and dumb HTTP?](#smart-and-dumb-http)
- [My password stopped working for `git push`. What do I type instead?](#usernames-passwords-and-tokens)
- [What do "Authentication failed", "repository not found" and "unable to access" mean?](#when-https-fails)
- [How do I make Git use a proxy, or not use one for a single host?](#proxies-and-settings-for-one-site)
- [How do I apply an HTTP setting to one site only?](#proxies-and-settings-for-one-site)
- [Git reports a certificate problem. Should I turn off verification?](#certificates)
- [Should I raise `http.postBuffer` when a push fails?](#other-http-settings)

**[Credentials](#credentials)**

- [In what order does Git look for a username and password?](#how-git-asks)
- [How can a script make Git fail instead of waiting for a password?](#how-git-asks)
- [What does the question look like when Git asks for a password?](#how-git-asks)
- [How do I stop Git asking for my username every time?](#usernames)
- [Where does the `store` helper keep my password, and is it safe?](#the-store-helper)
- [My password changed and Git keeps using the old one. How do I make it forget?](#the-store-helper)
- [I have two repositories on the same host with different accounts. Why does Git use the same password?](#the-store-helper)
- [How do I keep a password in memory for a few minutes only?](#the-cache-helper)
- [Which helper should I use on Windows, macOS or Linux?](#the-helper-for-your-system)
- [What happens when several helpers are configured?](#several-helpers)
- [How do I switch off a helper set in the system configuration?](#several-helpers)
- [How do I write my own credential helper?](#writing-a-helper)
- [Can I put the token in the URL instead?](#credentials-in-a-url)

**[Which protocols Git may use](#which-protocols-git-may-use)**

- [Git says "transport 'file' not allowed". Why?](#which-protocols-git-may-use)
- [How do I restrict which protocols Git may use?](#which-protocols-git-may-use)

**[Remote helpers](#remote-helpers)**

- [What is a URL like `ext::` or `hg::`?](#remote-helpers)
- [Git says `'remote-hg' is not a git command`. What is missing?](#remote-helpers)

**[Rewriting URLs](#rewriting-urls)**

- [How do I use SSH for every GitHub repository without changing each URL?](#rewriting-urls)
- [Can I fetch over HTTPS and push over SSH?](#rewriting-urls)
- [Two `insteadOf` rules match. Which one wins?](#rewriting-urls)

**[Protocol versions](#protocol-versions)**

- [How can I see what Git and the server actually say to each other?](#protocol-versions)
- [What are protocol versions 0, 1 and 2, and which am I using?](#protocol-versions)
- [What are the four hex digits at the start of each line?](#protocol-versions)

**[The git:// protocol and git daemon](#the-git-protocol-and-git-daemon)**

- [What is `git://`, and why do hosts no longer offer it?](#the-git-protocol-and-git-daemon)

**[Serving a repository yourself](#serving-a-repository-yourself)**

- [How do I host a repository on my own server, with no hosting service?](#serving-a-repository-yourself)
- [How do I give someone push access over SSH without giving them a shell?](#serving-a-repository-yourself)

**[When a connection fails](#when-a-connection-fails)**

- [Which program printed my error message: Git, ssh, or the server?](#when-a-connection-fails)
- [How do I see more detail about a failing connection?](#seeing-more)

**[SSH or HTTPS](#ssh-or-https)**

- [Should I use SSH or HTTPS?](#ssh-or-https)

**[The settings](#the-settings)**

- [Which settings and environment variables control transports and credentials?](#the-settings)

</details>

## The transports at a glance

| Transport | URL looks like | Proves who you are with | Encrypted | Git on the other side |
|---|---|---|---|---|
| Local | `/srv/git/atlas.git`, `file:///srv/git/atlas.git` | nothing: file permissions decide | no network involved | the same Git, run locally |
| SSH | `ssh://git@example.com/team/atlas.git`, `git@example.com:team/atlas.git` | an SSH key, or the account's password | yes | must be installed on the server |
| HTTPS | `https://example.com/team/atlas.git` | a username and a password or token | yes | a Git-aware web server, for smart HTTP |
| HTTP | `http://example.com/team/atlas.git` | the same, sent in the clear | no | the same |
| Git protocol | `git://example.com/team/atlas.git` | nothing at all | no | `git daemon`, on port 9418 |
| Remote helper | `<transport>::<address>` | whatever the helper does | depends | depends |

Chapter 9 lists the URL syntaxes, and Git's documentation adds that `ftp://`
and `ftps://` still work for fetching but are inefficient, deprecated, and not
to be used. The local transport is the one the rest of this book's examples use;
it needs no authentication because anyone who can read the directory can read
the repository.

## The examples

This chapter cannot connect to a real server, so its transcripts show everything
Git does on your side and stop where a server would answer:

| In the examples | Stands in for |
|---|---|
| `/home/ada/srv/atlas.git` | a repository on a server; `/home/ada` is also the "server account's" home directory |
| `/home/ada/atlas` | Ada's clone of it |
| `bin/ssh` | the `ssh` program: it prints the command line Git gave it, then runs the command on the same computer |
| `bin/askpass` | a password dialog: it prints the question and types an answer |
| `https://example.com/...` | a real HTTPS server, used only in commands that stop before connecting |

What a real server or `ssh` prints in reply cannot be produced here, so it is
quoted in the text, never as a transcript, and attributed to the program that
prints it.

## Taking a URL apart

```console
$ git url-parse -c host https://example.com/team/atlas.git
example.com
$ for part in scheme user host port path; do printf '%-7s' $part; git url-parse -c $part ssh://git@example.com:2222/team/atlas.git; done
scheme ssh
user   git
host   example.com
port   2222
path   /team/atlas.git
$ for part in scheme user host port path; do printf '%-7s' $part; git url-parse -c $part git@example.com:team/atlas.git; done
scheme ssh
user   git
host   example.com
port   
path   /team/atlas.git
```

`git url-parse` prints one part of a URL as Git reads it: `scheme`, `user`,
`password`, `host`, `port` or `path`, chosen with `-c`, or `--component`. A
part the URL does not have prints as an empty line. The loop only asks for each
part in turn.

The second URL has no `ssh://` in front and is still SSH: `user@host:path`,
with no slash before the first colon, is the *scp-like* form, named after the
`scp` copy command that uses the same syntax. Chapter 9 explains the rule that
tells it apart from a local path.

`url-parse` shows the scp-like path as `/team/atlas.git`, like the other form's.
That is how it normalises the parts, and not what Git sends: the section
[Paths in SSH URLs](#paths-in-ssh-urls) shows the two forms are sent
differently.

```console
$ git url-parse -c path example.com:~ada/atlas.git
~ada/atlas.git
$ git url-parse -c host https://example.com/atlas.git git@example.org:atlas.git
example.com
example.org
$ git url-parse -c password https://ada:s3cret@example.com/atlas.git
s3cret
$ git url-parse -c scheme -c host https://example.com/atlas.git
example.com
$ git url-parse https://example.com/atlas.git; echo "exit $?"
exit 0
$ git url-parse /srv/git/atlas.git; echo "exit $?"
fatal: '/srv/git/atlas.git' is not a URL; if you meant a local repository, use 'file:///srv/git/atlas.git'
exit 128
$ git url-parse ./weird:name; echo "exit $?"
fatal: './weird:name' is not a URL; if you meant a local repository, use a 'file://' URL with an absolute path
exit 128
```

Several URLs give one line each. Of two `-c` options only the last counts.
Without `-c` nothing is printed, and the exit status says whether every URL
parsed, which makes it a validator for scripts.

A plain path is not a URL to `url-parse`, although `git clone` and
`git remote add` accept one; the error suggests the `file://` form.

> **Windows.** Git Bash turns an argument starting with `/` into a path under the
> Git installation before Git sees it, so the same command there says
> `'C:/Program Files/Git/srv/git/atlas.git' is not a URL`. That was seen when
> preparing this chapter; the transcript shows what a Linux or macOS shell
> passes. Quoting the path does not stop the conversion; setting
> `MSYS_NO_PATHCONV=1` in front of the command does, tested in Git Bash.

> **Since Git 2.55.** `git url-parse`. On an older Git there is no command that
> shows how Git reads a URL.

## What Git runs on the other end

```console
$ cat bin/ssh
#!/bin/sh
# A stand-in for ssh, for these examples only. It prints the command line
# Git gave it, then runs the command here, in the home directory, the way
# a real ssh would run it on the server.
echo "ssh $*" >&2
while test $# -gt 2; do shift; done
cd && exec sh -c "$2"
$ GIT_SSH_COMMAND=bin/ssh git ls-remote git@example.com:srv/atlas.git
ssh -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack 'srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	HEAD
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
e5b3965c4e0bf29bec863b00bb38f34101c52f68	refs/tags/v1.0
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/tags/v1.0^{}
```

`GIT_SSH_COMMAND` names the program Git runs in place of `ssh`; the section
[Which ssh program](#which-ssh-program) covers it. Here it is the stand-in, and
its first line of output is the whole of what Git asks `ssh` to do:

| Part | Is |
|---|---|
| `-o SendEnv=GIT_PROTOCOL` | an option for `ssh`, explained in [Options Git adds](#options-git-adds) |
| `git@example.com` | the account and the server, from the URL |
| `git-upload-pack 'srv/atlas.git'` | the command `ssh` should run there, with the path from the URL in quotes |

That is all SSH does for Git: it logs in and runs one command, and the two Git
programs talk through the connection. So the server needs Git installed and
`git-upload-pack` reachable from the account's login shell; Chapter 39 showed
`--upload-pack` for a server where it is not. A hosting service gives you no
shell at all, as GitHub's greeting in [Testing the key](#testing-the-key) says,
and accepts only the Git commands.

### Fetching, pushing and archiving

```console
$ cd atlas
$ GIT_SSH_COMMAND=../bin/ssh git fetch git@example.com:srv/atlas.git
ssh -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack 'srv/atlas.git'
From example.com:srv/atlas
 * branch            HEAD       -> FETCH_HEAD
$ GIT_SSH_COMMAND=../bin/ssh git push git@example.com:srv/atlas.git main
ssh git@example.com git-receive-pack 'srv/atlas.git'
Everything up-to-date
$ GIT_SSH_COMMAND=../bin/ssh git archive --remote=git@example.com:srv/atlas.git main | tar -tf -
ssh git@example.com git-upload-archive 'srv/atlas.git'
README.md
$ cd ..
```

| Command | Runs on the server |
|---|---|
| `git clone`, `git fetch`, `git pull`, `git ls-remote` | `git-upload-pack`, which sends objects |
| `git push` | `git-receive-pack`, which receives them and updates refs |
| `git archive --remote` | `git-upload-archive`, which sends a tar or zip of a commit (Chapter 61) |

A server can allow one and refuse the others, which is how read-only access
works: the fetch commands run, `git-receive-pack` does not. The fetch above
names a URL rather than a remote, so nothing is stored but `FETCH_HEAD`
(Chapter 41).

## SSH

### Paths in SSH URLs

```console
$ GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://git@example.com/home/ada/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH_COMMAND=bin/ssh git ls-remote git@example.com:/home/ada/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH_COMMAND=bin/ssh git ls-remote example.com:~/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL example.com git-upload-pack '~/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://example.com/~/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL example.com git-upload-pack '~/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://git@example.com/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack '/srv/atlas.git'
fatal: '/srv/atlas.git' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
$ GIT_SSH_COMMAND=bin/ssh git ls-remote ssh://git@example.com:2222/home/ada/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL -p 2222 git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
```

The two SSH forms send the path differently, and that is the whole of the
difference between them:

| URL | Path sent | Found |
|---|---|---|
| `git@example.com:srv/atlas.git` | `srv/atlas.git` | relative to the account's home directory |
| `git@example.com:/home/ada/srv/atlas.git` | `/home/ada/srv/atlas.git` | from the root |
| `ssh://git@example.com/home/ada/srv/atlas.git` | `/home/ada/srv/atlas.git` | from the root: everything after the host is the path |
| `example.com:~/srv/atlas.git`, `ssh://example.com/~/srv/atlas.git` | `~/srv/atlas.git` | in the home directory, expanded on the server |
| `example.com:~bob/atlas.git` | `~bob/atlas.git` | in user `bob`'s home directory, Git's documentation says |
| `ssh://git@example.com:2222/...` | the same; the port becomes `-p 2222` | |

So `ssh://git@example.com/srv/atlas.git` is not the same address as
`git@example.com:srv/atlas.git`: one looks in `/srv`, the other in the home
directory, and the error names the path that was tried. The first `fatal` line
came from `git-upload-pack` on the server; the rest are Git's on your side.

The scp-like form cannot carry a port, which is why `ssh://` exists: for a
server on port 2222 either write `ssh://`, or give the port in `~/.ssh/config`
([Several keys and accounts](#several-keys-and-accounts)).

A hosting service maps the path to a repository its own way, so its
documentation, not this table, says which forms it accepts. On a server of your
own, the table is what happens.

When the URL names no user, `ssh` picks one itself, from `~/.ssh/config` or,
failing that, your login name on this computer. GitHub's instructions use the
user `git` for everyone, and tell accounts apart by the key.

### Keys

```console
$ mkdir .ssh && ssh-keygen -t ed25519 -C ada@example.com -f .ssh/id_ed25519 -N ''
Generating public/private ed25519 key pair.
Your identification has been saved in .ssh/id_ed25519
Your public key has been saved in .ssh/id_ed25519.pub
The key fingerprint is:
...
$ ls .ssh
id_ed25519
id_ed25519.pub
$ cut -d ' ' -f 1,3 .ssh/id_ed25519.pub
ssh-ed25519 ada@example.com
```

`ssh-keygen` is part of OpenSSH, not Git; Git for Windows installs OpenSSH
along with Git. It made two files. `id_ed25519` is the *private key*: it never leaves this
computer and is never shown to anyone. `id_ed25519.pub` is the *public key*: one
line of the key type, the key itself, and the comment given with `-C`, usually
an email address so you can recognise the key later. The key in the middle, cut
out here, and the fingerprint and picture after "The key fingerprint is:" are
random, different every time, and cut from the transcript for that reason.

| Option | Means |
|---|---|
| `-t ed25519` | the key type; GitHub's instructions for a new key use Ed25519 |
| `-C ada@example.com` | a comment stored in the public key |
| `-f .ssh/id_ed25519` | where to save; without it `ssh-keygen` asks, offering `~/.ssh/id_ed25519` |
| `-N ''` | the passphrase, here empty, so that the example needs no typing |

Typed on its own, `ssh-keygen -t ed25519 -C ada@example.com` asks where to save
the key and then, twice, for a passphrase; pressing Enter at the first question
accepts `~/.ssh/id_ed25519`.

To use the key, give the host the *public* key: paste the whole line of
`id_ed25519.pub` into the SSH keys page of your account's settings on GitHub or
GitLab (Chapter 50, Chapter 51), or append it to `~/.ssh/authorized_keys` of the
account on a server of your own. `ssh` offers keys it finds under standard
names without being told, and `~/.ssh/id_ed25519` is one of those names:
`ssh -G` lists them as `identityfile` lines when no configuration names a key.

> **Careful.** Anyone with a copy of the private key can act as you on every
> server that has the public key, until you remove the public key from them. Do
> not copy it into a repository, a chat, or a backup others can read; make a new
> key per computer instead, so that losing one computer means removing one key.

### Passphrases and the agent

A passphrase encrypts the private key, so a stolen copy of the file is useless
without it. The cost is typing it, and an *agent* removes most of that: a small
program, `ssh-agent`, that holds decrypted keys in memory for the rest of the
session. These are OpenSSH commands, typed in Git Bash or a Unix shell:

```sh
eval "$(ssh-agent -s)"      # start an agent for this shell
ssh-add ~/.ssh/id_ed25519   # asks for the passphrase once
ssh-add -l                  # lists the keys the agent holds
```

`ssh-add` prints `Identity added:` and the key's file name when it works. Every
`git fetch` and `git push` started from that shell then uses the key without
asking. GitHub's own instructions use the same commands. Some desktop systems
start an agent when you log in, and then `ssh-add` alone is enough.

> **Windows.** Two OpenSSH installations are common on one Windows computer: the
> one inside Git for Windows, which Git Bash finds first, and the one Windows
> itself ships in `C:\Windows\System32\OpenSSH`, with its own `ssh-agent.exe`
> and `ssh-add.exe`. On the computer that built this book, Git Bash found Git's
> own `ssh` first. Use the agent and `ssh-add` of the installation whose `ssh`
> Git actually runs; `core.sshCommand` can name the other one, written
> `C:/Windows/System32/OpenSSH/ssh.exe`.

### The first connection

The first time `ssh` reaches a server it has no record of, it stops and asks.
OpenSSH's source prints the question in this form:

```
The authenticity of host 'example.com (<address>)' can't be established.
ED25519 key fingerprint is: SHA256:<fingerprint>
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Older OpenSSH versions print `(yes/no)` and no colon after "is". The question is
whether this is really the server you meant. Compare the fingerprint with the
one the host publishes; GitHub's documentation has a page, "GitHub's SSH key
fingerprints", for exactly this.
Answering `yes` records the host key in `~/.ssh/known_hosts`, and `ssh` never
asks again for that host. Git cannot answer the question for you, and when
`ssh` cannot ask it, because no terminal is attached, it stops with
`Host key verification failed.`

If a server's key later differs from the recorded one, `ssh` refuses to connect
and prints a block beginning `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`.
That happens when a server is reinstalled or a host replaces its keys, and also
when someone is intercepting the connection. Find out which before removing the
old line from `known_hosts`; `ssh-keygen -R example.com` removes it.

### Testing the key

```sh
ssh -T git@github.com
```

`-T` connects without asking for a terminal. GitHub's documentation gives its
answer when the key is accepted as
`Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.`
GitLab and other hosts print their own greeting. Either way, the name in it is
the account the key belongs to, which is the first thing to check when a push is
refused.

When no key is accepted, OpenSSH prints the account, the host, and the methods
the server would have accepted:

```
git@github.com: Permission denied (publickey).
```

`publickey` alone means the server takes keys only and none of the keys offered
matched: the public key was never added to the account, it was added to another
account, or `ssh` offered a different private key. `ssh -v -T git@github.com`
lists each key `ssh` tries; [Seeing more](#seeing-more) shows how to get the
same detail from inside a Git command.

### Several keys and accounts

```console
$ cat .ssh/config
Host github-work
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_work
	IdentitiesOnly yes
$ ssh -G -F .ssh/config github-work 2>/dev/null | grep -E '^(user|hostname|port|identityfile|identitiesonly) '
user git
hostname github.com
port 22
identitiesonly yes
identityfile ~/.ssh/id_work
$ GIT_SSH_COMMAND=bin/ssh git ls-remote github-work:srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL github-work git-upload-pack 'srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
```

A host can tell accounts apart only by key, so two accounts on one host need two
keys, and `ssh` needs to know which to offer. `~/.ssh/config` does that with a
made-up host name: `github-work` means `github.com`, as user `git`, with the key
`~/.ssh/id_work` and no other (`IdentitiesOnly`). `ssh -G` prints the settings
`ssh` would use for a name without connecting; `-F` names the configuration file,
which is `~/.ssh/config` when it is left out.

Git knows nothing of this. It passes `github-work` to `ssh` exactly as written
in the URL, and `ssh` resolves it. So the work repositories' remotes are written
`github-work:team/atlas.git`, and personal ones `git@github.com:ada/notes.git`,
which uses the default key. [Rewriting URLs](#rewriting-urls) shows how to
avoid editing every URL by hand.

```console
$ cd atlas && git config set core.sshCommand '../bin/ssh -i ~/.ssh/id_work -o IdentitiesOnly=yes' && git fetch git@example.com:srv/atlas.git && cd ..
ssh -i /home/ada/.ssh/id_work -o IdentitiesOnly=yes -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack 'srv/atlas.git'
From example.com:srv/atlas
 * branch            HEAD       -> FETCH_HEAD
```

The other way is per repository: `core.sshCommand` in the repository's own
configuration, with `ssh`'s `-i` naming the key. It needs no host alias and
keeps the ordinary URLs. Git runs the value through the shell, so `~` was
expanded before the stand-in saw it. With the real `ssh`, the value would be
`ssh -i ~/.ssh/id_work -o IdentitiesOnly=yes`.

### Which ssh program

```console
$ GIT_SSH=bin/plink git ls-remote ssh://git@example.com:2222/home/ada/srv/atlas.git main
ssh -P 2222 git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH=bin/tortoiseplink git ls-remote ssh://git@example.com:2222/home/ada/srv/atlas.git main
ssh -batch -P 2222 git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH=bin/my-connect git ls-remote git@example.com:srv/atlas.git main
ssh git@example.com git-upload-pack 'srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH=bin/my-connect git ls-remote ssh://git@example.com:2222/home/ada/srv/atlas.git main
fatal: ssh variant 'simple' does not support setting port
$ GIT_SSH=bin/my-connect GIT_SSH_VARIANT=ssh git ls-remote ssh://git@example.com:2222/home/ada/srv/atlas.git main
ssh -o SendEnv=GIT_PROTOCOL -p 2222 git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ git -c core.sshCommand=bin/my-connect -c ssh.variant=putty ls-remote ssh://git@example.com:2222/home/ada/srv/atlas.git main
ssh -P 2222 git@example.com git-upload-pack '/home/ada/srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
```

`plink`, `tortoiseplink` and `my-connect` are copies of the same stand-in under
other names; each still prints `ssh` first because that is what the script
says. What differs is the options Git gave them, and Git chose those by the
program's name. Different SSH programs take different options, and Git's
documentation calls each set a *variant*:

| Variant | Chosen when the program is named | Arguments Git passes |
|---|---|---|
| `ssh` | `ssh`, or anything that answers OpenSSH's `-G` option | `[-p port] [-4] [-6] [-o option] [user@]host command` |
| `plink`, `putty` | `plink`, PuTTY's command-line program | `[-P port] [-4] [-6] [user@]host command` |
| `tortoiseplink` | `tortoiseplink`, from TortoiseGit | `[-P port] [-4] [-6] -batch [user@]host command` |
| `simple` | anything else | `[user@]host command`, and nothing more |

For a name it does not recognise, Git first runs the program with `-G`, and uses
the `ssh` variant if that works; `my-connect` failed that test, became `simple`,
and could not be given a port. `GIT_SSH_VARIANT`, or the setting `ssh.variant`,
sets the variant directly: `ssh`, `plink`, `putty`, `tortoiseplink`, `simple`,
or `auto` for the name-based guess.

```console
$ GIT_SSH_COMMAND='bin/ssh -o IdentitiesOnly=yes' GIT_SSH=bin/plink git ls-remote git@example.com:srv/atlas.git main
ssh -o IdentitiesOnly=yes -o SendEnv=GIT_PROTOCOL git@example.com git-upload-pack 'srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ GIT_SSH='bin/ssh -v' git ls-remote git@example.com:srv/atlas.git main
error: cannot spawn bin/ssh -v: No such file or directory
error: cannot spawn bin/ssh -v: No such file or directory
fatal: unable to fork
```

| To name the program | Where | Takes arguments |
|---|---|---|
| `GIT_SSH_COMMAND` | environment, one command | yes, run through the shell |
| `GIT_SSH` | environment, one command | no: only a path to a program |
| `core.sshCommand` | configuration, of one repository or every one | yes, like `GIT_SSH_COMMAND` |
| none of them | | `ssh`, found on `PATH` |

Git's documentation gives the order: `GIT_SSH_COMMAND` wins over `GIT_SSH`, as
the first transcript shows, and either environment variable wins over
`core.sshCommand`. `GIT_SSH` is taken as the name of a file, so `bin/ssh -v`,
with its space, named a program that does not exist; write a small script for
it, or use `GIT_SSH_COMMAND`.

### Options Git adds

```console
$ GIT_SSH_COMMAND=bin/ssh git -c protocol.version=0 ls-remote git@example.com:srv/atlas.git main
ssh git@example.com git-upload-pack 'srv/atlas.git'
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ cd atlas && GIT_SSH_COMMAND=../bin/ssh git fetch -4 git@example.com:srv/atlas.git && cd ..
ssh -o SendEnv=GIT_PROTOCOL -4 git@example.com git-upload-pack 'srv/atlas.git'
From example.com:srv/atlas
 * branch            HEAD       -> FETCH_HEAD
```

`-o SendEnv=GIT_PROTOCOL` asks `ssh` to pass the environment variable
`GIT_PROTOCOL` to the server, and that variable is how the client offers wire
protocol version 2 ([Protocol versions](#protocol-versions)). With
`protocol.version=0` there is nothing to offer, and the option is gone; a push
never adds it, because Git's documentation says the variable is not used for
pushes yet. `git fetch -4` and `-6` become `ssh`'s own `-4` and `-6`, to use
only IPv4 or only IPv6 addresses.

Git's documentation adds that an OpenSSH server passes the variable on only if
its configuration says `AcceptEnv GIT_PROTOCOL`. Without that, the conversation
falls back to version 0, and works.

### When port 22 is blocked

Some networks allow only web traffic. GitHub's documentation describes an SSH
service on port 443, the HTTPS port, under a different host name,
`ssh.github.com`, and gives these lines for `~/.ssh/config`:

```
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
```

With them, every `git@github.com:...` URL goes through port 443 without being
changed. `ssh -T -p 443 git@ssh.github.com` tests it first. Other hosts may
offer the same under their own names; their documentation says so.

## HTTPS

### Smart and dumb HTTP

Git's documentation describes two protocols over HTTP. *Smart* HTTP runs Git
programs on the server, `git http-backend` or a host's equivalent, and speaks the
same wire protocol as SSH. *Dumb* HTTP needs only an ordinary web server: the
client downloads the repository's files one by one, and it cannot push. A smart
client tries smart first and falls back, so one URL serves both.

```console
$ git -C srv/atlas.git update-server-info && cat srv/atlas.git/info/refs
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
e5b3965c4e0bf29bec863b00bb38f34101c52f68	refs/tags/v1.0
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/tags/v1.0^{}
```

A dumb client cannot ask the server which refs exist, so it reads a file that
lists them. `git update-server-info` writes that file, and it has to be run
again after every change, usually from a hook (Chapter 67). Dumb HTTP matters
only for a repository copied to a plain web server; Git hosting services speak
smart HTTP.

### Usernames, passwords and tokens

Over HTTPS the server answers the first request with "authentication required",
and Git asks its credential helpers, then you, for a username and a password
([How Git asks](#how-git-asks)). It then retries with them, and on success tells
the helpers they worked, so they can remember them.

The password is often not your account's password. GitHub's announcement says
that from 13 August 2021 it no longer accepts account passwords for Git
operations, and requires a personal access token or SSH instead. You create the
token in your account's settings, choose what it may do and when it expires, and
type it where Git asks for the password. GitLab and other hosts offer tokens
too; Chapter 50 and Chapter 51 show where.

A URL can carry the username, `https://ada@example.com/team/atlas.git`, and then
Git asks only for the password. It can technically carry the password as well;
[Credentials in a URL](#credentials-in-a-url) says why not.

### When HTTPS fails

These are Git's own messages, from its source, with `<url>` standing for the
repository's address without any password in it:

| Message | Git prints it when |
|---|---|
| `fatal: Authentication failed for '<url>'` | the server refused the username and password Git sent |
| `fatal: repository '<url>' not found` | the server answered that nothing exists at that address |
| `fatal: unable to access '<url>': <reason>` | anything else went wrong: a name that does not resolve, a proxy, a certificate; the reason comes from the HTTP library |
| `fatal: rate limited by '<url>', please try again later` | the server said too many requests were made |
| `fatal: could not read Username for '<url>': terminal prompts disabled` | the server wants credentials, and Git had no way to ask ([How Git asks](#how-git-asks)) |

Lines beginning `remote:` before these are the server's own explanation, printed
as it sent them, and often the most useful part: a host says there which kind of
token it expected, or that a password is no longer accepted.

After "Authentication failed", Git's source also tells every credential helper
to erase what it supplied. That is why a changed password needs no cleaning up:
the next attempt asks you again. It is also why a mistyped token disappears
from the helper instead of being tried forever.

### Proxies and settings for one site

```console
$ cd atlas
$ git config set http.proxy http://proxy.example.com:3128 && git config set 'http.https://git.example.com/.proxy' ''
$ git config get --url=https://github.com/team/atlas.git http.proxy
http://proxy.example.com:3128
$ git config get --url=https://git.example.com/team/atlas.git http.proxy; echo "exit $?"

exit 0
```

`http.proxy` sends every HTTP and HTTPS request through a proxy. Git's
documentation says it overrides the `http_proxy`, `https_proxy` and `all_proxy`
environment variables, which Git also obeys, and that `remote.<name>.proxy`
overrides it for one remote.

Any `http.*` setting can be limited to some URLs by writing the URL between
`http.` and the setting's name. Here the proxy is switched off for
`git.example.com` by setting it to the empty string. `git config get --url=`
answers "what value applies to this URL?", which is the way to check such a rule
without connecting anywhere.

```console
$ git config set 'http.https://*.example.org.sslVerify' false
$ git config get --url=https://git.example.org/atlas.git http.sslVerify
false
$ git config get --url=https://a.b.example.org/atlas.git http.sslVerify; echo "exit $?"
exit 1
```

Git's documentation gives the matching rules. The scheme must be the same, so an
`https://` rule never applies to `http://`. The host must match, where `*`
stands for one level of name only, so `*.example.org` matched
`git.example.org` and not `a.b.example.org`. A path in the rule matches only at
a slash, and a longer match wins over a shorter one. A user name in the rule
must match the URL's.

> **Since Git 2.46.** `git config get --url`. On an older Git, write
> `git config --get-urlmatch http.proxy https://github.com/team/atlas.git`.

### Certificates

HTTPS checks that the server's certificate was issued for that host by an
authority your computer trusts. When the check fails, the reason after
"unable to access" names a certificate problem, and nothing is transferred.

| Setting | Does |
|---|---|
| `http.sslCAInfo` | a file of extra authorities to trust, such as a company's own; also the variable `GIT_SSL_CAINFO` |
| `http.sslBackend` | which TLS library, the code that encrypts HTTPS, to use: `openssl` or, on Windows, `schannel` |
| `http.schannelCheckRevoke` | whether `schannel` checks that the certificate was not revoked; `best-effort` by default |
| `http.sslCert`, `http.sslKey` | a client certificate, for a server that asks for one |
| `http.sslVerify` | `false` turns the check off; also the variable `GIT_SSL_NO_VERIFY` |

With `schannel`, Git uses Windows's own TLS library and the Windows certificate
store, which helps on a company computer whose own certificate authority has
been installed into Windows. Git's documentation notes that `http.sslCAInfo` is
then ignored unless `http.schannelUseSSLCAInfo` is set.

> **Careful.** `http.sslVerify=false` makes Git accept any certificate from
> anyone, so a network that can intercept the connection can read your token and
> change what you fetch. If you must use it, limit it to one host with
> `http.https://that.host/.sslVerify`, as above, and prefer `http.sslCAInfo`
> with the certificate you actually expect.

### Other HTTP settings

| Setting | Does |
|---|---|
| `http.postBuffer` | the buffer size for sending data, 1 MiB by default; Git's documentation says raising it is not an effective fix for most push problems, and helps only with servers or proxies that cannot take an upload sent in pieces, as HTTP/1.1's chunked encoding sends it |
| `http.version` | `HTTP/1.1` or `HTTP/2`; the default depends on the HTTP library |
| `http.followRedirects` | `initial` by default: follow a redirect on the first request only; `true` always, `false` never |
| `http.extraHeader` | an HTTP header added to every request; an empty value clears the list |
| `http.emptyAuth` | try authentication without a username, for single sign-on schemes such as Kerberos; `auto` by default |
| `http.proactiveAuth` | send credentials on the first request instead of waiting to be asked |
| `http.userAgent` | the program name sent to the server; also `GIT_HTTP_USER_AGENT` |
| `http.lowSpeedLimit`, `http.lowSpeedTime` | give up when a transfer stays below a speed for that many seconds |
| `http.cookieFile`, `http.saveCookies` | read cookies from a file, and write them back |

> **Since Git 2.46.** `http.proactiveAuth`.

## Credentials

### How Git asks

```console
$ printf 'url=https://example.com/team/atlas.git\n' | GIT_TERMINAL_PROMPT=0 git credential fill; echo "exit $?"
fatal: could not read Username for 'https://example.com': terminal prompts disabled
exit 128
$ cat ../bin/askpass
#!/bin/sh
# Stands in for a password dialog: shows the question, answers it.
echo "askpass was asked: $1" >&2
case "$1" in Username*) echo ada ;; *) echo s3cret ;; esac
$ printf 'url=https://example.com/team/atlas.git\n' | GIT_ASKPASS=../bin/askpass git credential fill
askpass was asked: Username for 'https://example.com': 
askpass was asked: Password for 'https://ada@example.com': 
protocol=https
host=example.com
username=ada
password=s3cret
```

`git credential fill` does exactly what Git does when a server asks for
credentials, without a server: it reads a description of the site on standard
input and prints what it found or was told. That makes it the tool for testing
everything in this section. Its format is covered in
[Writing a helper](#writing-a-helper).

Git's documentation gives the order in which it looks:

1. Each credential helper, in turn, until one gives both a username and a password.
2. The program named by `GIT_ASKPASS`.
3. Otherwise, the program named by `core.askPass`.
4. Otherwise, the program named by `SSH_ASKPASS`.
5. Otherwise, a question in the terminal.

An *askpass program* receives the question as its only argument and prints the
answer. The stand-in showed the questions word for word: `Username for` and
`Password for`, with the site, and the password question includes the username.
A graphical askpass program is how a password window can appear instead of a
question in the terminal.

`GIT_TERMINAL_PROMPT=0` removes the last step. With no helper and no askpass
program, Git then fails at once instead of waiting for someone to type, which is
what a script or an automated job wants.

```console
$ printf 'url=https://ada@example.com/team/atlas.git\n' | GIT_ASKPASS=../bin/askpass git credential fill
askpass was asked: Password for 'https://ada@example.com': 
protocol=https
host=example.com
username=ada
password=s3cret
$ printf 'url=https://example.com/team/atlas.git\n' | git -c credential.interactive=false credential fill
fatal: unable to get password from user
```

A username in the URL is used without asking. `credential.interactive=false`
stops Git from asking interactively, and Git's documentation adds that some
helpers respect it too; here there was nothing else to ask, so it failed.

> **Since Git 2.47.** `credential.interactive`.

### Usernames

```console
$ git config set credential.https://example.com.username ada
$ printf 'protocol=https\nhost=example.com\n' | GIT_ASKPASS=../bin/askpass git credential fill
askpass was asked: Password for 'https://ada@example.com': 
protocol=https
host=example.com
username=ada
password=s3cret
$ printf 'protocol=https\nhost=example.org\n' | GIT_TERMINAL_PROMPT=0 git credential fill
fatal: could not read Username for 'https://example.org': terminal prompts disabled
$ git config set 'credential.https://example.net/team.username' ada
$ git config get --url=https://example.net/team/atlas.git credential.username
ada
$ git config get --url=https://example.net/teamwork/atlas.git credential.username; echo "exit $?"
exit 1
```

`credential.<url>.username` saves typing the username for one site, and is safe
to keep in configuration because it holds no secret. `credential.username`,
with no URL, applies everywhere.

The URL is matched the way `http.<url>.*` settings are, as Git's documentation
describes: protocol and host exactly, so `example.org` was not covered, and a
path only as a whole segment, so `team` covers `team/atlas.git` and not
`teamwork/atlas.git`.

### The store helper

```console
$ git config set credential.helper 'store --file ../git-credentials'
$ printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential approve
$ cat ../git-credentials
https://ada:s3cret@example.com
$ printf 'protocol=https\nhost=example.com\n' | git credential fill
protocol=https
host=example.com
username=ada
password=s3cret
```

`credential.helper` names a helper. `store` is one of the two that come with
Git; the name expands to the command `git credential-store`, and the rest of the
value is its options. `git credential approve` is what Git does after a
successful login: it hands the credentials to every helper to keep. `store`
wrote them into the file, and the next `fill` found them with nothing to ask.

The file is plain text, one URL per line with the password in it. Git's
documentation says so at the top of the helper's manual, and says the file's
permissions are set so other users cannot read it, which protects it from other
accounts on the computer and from nothing else. Without `--file`, it is
`~/.git-credentials`.

> **Careful.** `store` is the helper to use on a server you control, for an
> automated job, with a token that can do as little as possible. On your own
> computer, use the helper for your system, below.

```console
$ printf 'protocol=https\nhost=example.com\nusername=bob\n' | GIT_TERMINAL_PROMPT=0 git credential fill
fatal: could not read Password for 'https://bob@example.com': terminal prompts disabled
$ printf 'protocol=https\nhost=example.com\npath=team/atlas.git\n' | git credential fill
protocol=https
host=example.com
username=ada
password=s3cret
$ printf 'protocol=https\nhost=example.com\npath=team/atlas.git\n' | GIT_TERMINAL_PROMPT=0 git -c credential.useHttpPath=true credential fill
fatal: could not read Username for 'https://example.com/team/atlas.git': terminal prompts disabled
$ printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential reject && wc -c ../git-credentials
0 ../git-credentials
```

A stored credential is for a protocol, a host and a username. Asking for `bob`
found nothing, because the stored one is `ada`'s.

The path is ignored by default: a password stored for `example.com` is used for
every repository there, and the `path` line was even dropped from the output.
That is the cause when two repositories on one host belong to different
accounts and Git uses the wrong password for one of them.
`credential.useHttpPath=true` makes the path part of the match, and then each
repository needs its own entry.

`git credential reject` is what Git does after a failed login: every helper is
told to forget. The file is now empty. Doing the same by hand is how to make Git
forget a password.

### The cache helper

```console
$ git config set credential.helper 'cache --timeout 300 --socket /home/ada/cache/socket'
$ printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential approve
$ printf 'protocol=https\nhost=example.com\n' | git credential fill
protocol=https
host=example.com
username=ada
password=s3cret
$ git credential-cache --socket /home/ada/cache/socket exit
$ printf 'protocol=https\nhost=example.com\n' | GIT_TERMINAL_PROMPT=0 git credential fill
fatal: could not read Username for 'https://example.com': terminal prompts disabled
```

`cache` keeps credentials in the memory of a small background process instead of
a file, and forgets them after `--timeout` seconds, 900 by default. `exit` ends
the process at once, and everything it held is gone. `--socket` names the file
through which Git talks to the process, and matters only when the default place
in your home directory does not work, such as on a network drive.

Git's documentation points out that a cache is a poor place for a personal
access token, which lives for weeks: you would type it again every time the
cache expired.

> **Since Git 2.34.** The `cache` helper works on Windows.

### The helper for your system

Neither `store` nor `cache` uses the secure storage an operating system
provides. The helpers that do are separate programs, and Git's documentation
names the popular ones:

| Value of `credential.helper` | Helper | For |
|---|---|---|
| `manager` | Git Credential Manager | Windows, macOS and Linux; included in Git for Windows |
| `osxkeychain` | `git-credential-osxkeychain` | macOS |
| `libsecret` | `git-credential-libsecret` | Linux |
| `wincred` | `git-credential-wincred` | Windows |

Chapter 3 shows how to set one. Git Credential Manager can also sign in through
a browser window with OAuth, the "sign in with" flow, so that no token is ever
typed or copied; Git's documentation names it and `git-credential-oauth` as
helpers that do this.

### Several helpers

```console
$ git config set credential.helper 'store --file ../git-credentials'
$ git config set --append credential.helper '!f() { echo "second helper: $1" >&2; test "$1" = get && echo password=from-second; }; f'
$ git config get --all credential.helper
store --file ../git-credentials
!f() { echo "second helper: $1" >&2; test "$1" = get && echo password=from-second; }; f
$ printf 'protocol=https\nhost=example.com\nusername=ada\n' | git credential fill
second helper: get
protocol=https
host=example.com
username=ada
password=from-second
$ printf 'protocol=https\nhost=example.com\nusername=ada\npassword=s3cret\n' | git credential approve
second helper: store
$ printf 'protocol=https\nhost=example.com\n' | git credential fill
protocol=https
host=example.com
username=ada
password=s3cret
$ printf 'protocol=https\nhost=example.com\n' | GIT_TERMINAL_PROMPT=0 git -c credential.helper= credential fill
fatal: could not read Username for 'https://example.com': terminal prompts disabled
```

`credential.helper` can be set many times, and each value is a helper. A value
starting with `!` is a shell command instead of a helper name, which is the
quickest way to write one; this one reports what it was asked and answers `get`
with a password.

| Operation | Which helpers Git calls |
|---|---|
| `get`, from `fill` | each in order, stopping once it has a username and a password |
| `store`, from `approve` | all of them |
| `erase`, from `reject` | all of them |

The first `fill` had a username but no password: `store` had nothing, so the
second helper was asked. After `approve` stored the credential in both, `store`
answered on its own and the second was never called.

An empty value resets the list. Git's documentation describes it for exactly
the case where a helper is set in a configuration you cannot edit, such as the
system one: `credential.helper=` followed by the helpers you want. Here `-c`
emptied the list for one command, and there was nothing left to ask.

### Writing a helper

A helper is any program Git can run with one of the operations `get`, `store`
or `erase` as its last argument. Git's documentation gives the rule for turning
a value of `credential.helper` into a command:

| Value starts with | Runs |
|---|---|
| `!` | the rest, as a shell command |
| an absolute path | that program, with the value's arguments |
| anything else | `git credential-` followed by the value |

Git writes the description on the helper's standard input, one `key=value` per
line: the `protocol`, `host` and `path` it knows, and the `username` and
`password` for `store` and `erase`. For `get`, the helper prints the lines it
can supply and nothing else. A helper that prints `quit=true` stops Git asking
anyone further. Everything is plain text with no quoting, so a value cannot
contain a newline.

```console
$ git credential capability
version 0
capability authtype
capability state
```

Newer additions to the format are announced as *capabilities*: `authtype` lets
a helper supply a ready-made authorization header for schemes other than a
username and password, and `state` lets it keep information between two rounds
of a multi-step login. An ordinary helper needs neither.

> **Since Git 2.46.** `git credential capability`, and the `authtype` and
> `state` capabilities.

### Credentials in a URL

```console
$ git remote add leaky https://ada:s3cret@example.com/team/atlas.git
$ git -c transfer.credentialsInUrl=die fetch leaky
fatal: URL 'https://ada:<redacted>@example.com/team/atlas.git' uses plaintext credentials
$ git remote get-url leaky
https://ada:s3cret@example.com/team/atlas.git
```

A URL of the form `https://user:password@host/...` works, and puts the password
in `.git/config`, readable by anything that reads the repository's
configuration, and, Git's documentation adds, in the command lines of the
programs Git starts, which other users of the computer may be able to see.

`transfer.credentialsInUrl` checks for it. `die` refused before connecting, and
hid the password in its message; `warn` prints the same message as a warning
and carries on; `allow`, the default, says nothing. Git's documentation notes
that it checks `remote.<name>.url` only, not `pushurl`. The password is still in
the configuration, as `get-url` shows: take it out with
`git remote set-url` and let a helper keep it.

> **Since Git 2.37.** `transfer.credentialsInUrl`.

## Which protocols Git may use

```console
$ git -c protocol.file.allow=never ls-remote ../srv/atlas.git
fatal: transport 'file' not allowed
$ git -c protocol.allow=never ls-remote https://example.com/team/atlas.git
fatal: transport 'https' not allowed
$ GIT_ALLOW_PROTOCOL=https:ssh git ls-remote ../srv/atlas.git
fatal: transport 'file' not allowed
$ GIT_PROTOCOL_FROM_USER=0 git ls-remote ../srv/atlas.git
fatal: transport 'file' not allowed
$ GIT_PROTOCOL_FROM_USER=0 git -c protocol.file.allow=always ls-remote ../srv/atlas.git main
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
```

Git can refuse to use a transport, before it connects to anything. A local path
counts as `file`, as the first command shows.

| Value of `protocol.<name>.allow` | The protocol may be used |
|---|---|
| `always` | always |
| `never` | never |
| `user` | only when `GIT_PROTOCOL_FROM_USER` is unset or true |

Git's documentation gives the defaults: `always` for `http`, `https`, `git` and
`ssh`; `never` for `ext`; `user` for everything else, including `file`.
`protocol.allow` sets a default for every protocol without a setting of its own,
and `GIT_ALLOW_PROTOCOL` allows exactly the colon-separated list it names and
nothing else, whatever the configuration says.

The `user` policy exists for URLs a person did not type. Git sets
`GIT_PROTOCOL_FROM_USER=0` itself when it clones submodules, whose URLs come from
a file in someone else's repository (Chapter 57), so a malicious repository
cannot make it read local files or run programs. That is also why a submodule
with a local path fails with "transport 'file' not allowed" until
`protocol.file.allow` says `always`.

## Remote helpers

```console
$ git ls-remote 'ext::git %s /home/ada/srv/atlas.git'
fatal: transport 'ext' not allowed
$ git -c protocol.ext.allow=always ls-remote 'ext::git %s /home/ada/srv/atlas.git' main
0dd6887bf37be4e247a51bed27fdebf9169f246b	refs/heads/main
$ git ls-remote hg::https://example.com/atlas
git: 'remote-hg' is not a git command. See 'git --help'.

The most similar commands are
	remote-fd
	remote-http
fatal: remote helper 'hg' aborted session
$ git remote add old https://example.com/atlas && git config set remote.old.vcs svn && git ls-remote old
git: 'remote-svn' is not a git command. See 'git --help'.
fatal: remote helper 'svn' aborted session
```

A URL of the form `<transport>::<address>` hands the connection to a program
named `git-remote-<transport>`, which gives Git a way to reach anything someone
has written a helper for, including other version control systems. Git's own
HTTP support works the same way: Git's documentation calls `git-remote-http`
and `git-remote-https` its "curl" family of remote helpers, and the list of
similar commands above shows one.

`git-remote-ext` comes with Git and runs a command of your choosing, with `%s` replaced
by the service Git wants, `upload-pack` here. That is exactly why it is `never`
by default: a URL that runs any program is a way to run programs from a URL.
`fd::`, also included, talks over already-open file descriptors, for programs
that set up the connection themselves.

A missing helper fails as a missing command, `hg` here, which usually means the
bridge to that system is not installed. `remote.<name>.vcs` names a helper for a
remote whose URL has no `::`; this installation of Git has no `svn` helper.

## Rewriting URLs

```console
$ git remote add hub https://github.com/team/atlas.git
$ git config set url.git@github.com:.insteadOf https://github.com/ && git remote -v | grep hub
hub	git@github.com:team/atlas.git (fetch)
hub	git@github.com:team/atlas.git (push)
$ git ls-remote --get-url https://github.com/ada/notes.git
git@github.com:ada/notes.git
$ git config set url.git@work.example.com:.insteadOf https://github.com/team/ && git remote get-url hub
git@work.example.com:atlas.git
```

Chapter 39 introduced `url.<base>.insteadOf`. Its main use is this: with one
setting, every GitHub URL copied as HTTPS is used as SSH, including in commands
that take a URL directly and in repositories cloned later. In the global
configuration it is written
`git config set --global url.git@github.com:.insteadOf https://github.com/`.

When two rules match, Git's documentation says the longest match is used, so
the rule for `https://github.com/team/` won for the team's repository. The same
trick sends work repositories to an alias from
[Several keys and accounts](#several-keys-and-accounts).

```console
$ git config set url.git@github.com:.pushInsteadOf https://github.com/ && git remote -v | grep hub
hub	https://github.com/team/atlas.git (fetch)
hub	git@github.com:team/atlas.git (push)
$ git remote set-url --push hub https://github.com/team/atlas.git && git remote -v | grep hub
hub	https://github.com/team/atlas.git (fetch)
hub	https://github.com/team/atlas.git (push)
```

`pushInsteadOf` rewrites only for pushing: fetching goes over HTTPS, which needs
no key for a public repository, and pushing over SSH. Git's documentation says a
remote with its own `pushurl` ignores `pushInsteadOf`, and the second command
shows it: the push URL, set explicitly, stayed HTTPS.

## Protocol versions

```console
$ GIT_TRACE_PACKET=1 git ls-remote file:///home/ada/srv/atlas.git 2>&1 >/dev/null | grep -o 'ls-remote[<>].*'
ls-remote< version 2
ls-remote< agent=git/2.55.0.windows.5-Windows
ls-remote< ls-refs=unborn
ls-remote< fetch=shallow wait-for-done
ls-remote< server-option
ls-remote< object-format=sha1
ls-remote< 0000
ls-remote> command=ls-refs
ls-remote> agent=git/2.55.0.windows.5-Windows
ls-remote> object-format=sha1
ls-remote> 0001
ls-remote> peel
ls-remote> symrefs
ls-remote> unborn
ls-remote> 0000
ls-remote< 0dd6887bf37be4e247a51bed27fdebf9169f246b HEAD symref-target:refs/heads/main
ls-remote< 0dd6887bf37be4e247a51bed27fdebf9169f246b refs/heads/main
ls-remote< e5b3965c4e0bf29bec863b00bb38f34101c52f68 refs/tags/v1.0 peeled:0dd6887bf37be4e247a51bed27fdebf9169f246b
ls-remote< 0000
ls-remote> 0000
```

`GIT_TRACE_PACKET=1` makes Git print every line it sends and receives on
standard error. The rest of the command is only tidying: `2>&1 >/dev/null`
sends the trace into the pipe and throws the normal output away, and `grep -o`
keeps this side's lines without the time stamp each one starts with. A local
`file://` URL speaks the same protocol as SSH, so this is what an SSH or smart
HTTP conversation looks like too.

Read it as a dialogue. `<` is received, `>` is sent:

| Lines | Say |
|---|---|
| `version 2` to the first `0000` | the server: I speak version 2, and here is what I can do |
| `command=ls-refs` to the next `0000` | the client: list your refs, with symbolic refs and peeled tags |
| the hashes, and `0000` | the server's answer |
| the last `0000` | the client: nothing more |

`0000` ends a message and `0001` separates its sections, as Git's protocol
documentation defines them. `agent=` is each side's version; on Linux it ends
differently. Chapter 41 traces a fetch the same way, where the client says which
commits it wants and has.

```console
$ GIT_TRACE_PACKET=1 git -c protocol.version=0 ls-remote file:///home/ada/srv/atlas.git 2>&1 >/dev/null | grep -o 'ls-remote[<>].*'
ls-remote< 0dd6887bf37be4e247a51bed27fdebf9169f246b HEAD\0multi_ack thin-pack side-band side-band-64k ofs-delta shallow deepen-since deepen-not deepen-relative no-progress include-tag multi_ack_detailed symref=HEAD:refs/heads/main object-format=sha1 agent=git/2.55.0.windows.5-Windows
ls-remote< 0dd6887bf37be4e247a51bed27fdebf9169f246b refs/heads/main
ls-remote< e5b3965c4e0bf29bec863b00bb38f34101c52f68 refs/tags/v1.0
ls-remote< 0dd6887bf37be4e247a51bed27fdebf9169f246b refs/tags/v1.0^{}
ls-remote< 0000
ls-remote> 0000
```

In version 0 the server speaks first and sends every ref it has, whether or not
the client wants them, with its capabilities tucked after a zero byte, shown as
`\0`, on the first line. Version 2 lets the client ask for what it needs, which
on a server with many thousands of branches and tags is a large saving.

| Value of `protocol.version` | Means |
|---|---|
| `protocol.version=0` | the original protocol |
| `protocol.version=1` | the original, with a version line added at the start |
| `protocol.version=2` | the command-based protocol above; the default |

If the server does not support the version asked for, Git's documentation says
the conversation falls back to version 0. Over SSH that also happens when the
server does not accept the `GIT_PROTOCOL` variable
([Options Git adds](#options-git-adds)).

> **Since Git 2.29.** Version 2 is the default. Git 2.26 first made it the
> default and Git 2.27 went back to version 0; on a Git older than 2.29, set
> `protocol.version=2` to use it.

```console
$ GIT_PROTOCOL=version=2 git upload-pack --advertise-refs ../srv/atlas.git; echo
000eversion 2
0027agent=git/2.55.0.windows.5-Windows
0013ls-refs=unborn
0020fetch=shallow wait-for-done
0012server-option
0017object-format=sha1
0000
```

This is the server's first message as it really travels: the server program
started by hand, with `GIT_PROTOCOL` set the way `ssh` would pass it. Each line
starts with four hexadecimal digits giving its length, the four digits
included: `000e` is 14, `version 2`, a newline, and the four. That framing is
the *pkt-line* format; `0000` is a zero length, which is why it can mean "end of
message". `echo` only adds the newline the output does not end with.

## The git:// protocol and git daemon

`git://` is Git's own protocol over a plain TCP connection, to port 9418, served
by `git daemon`. Git's documentation is direct about it: it does no
authentication and should be used with caution on unsecured networks. There is
no encryption either, so nothing proves that what you fetched is what the server
sent. GitHub, for one, stopped accepting it on 15 March 2022, its announcement
says.

By default `git daemon` serves only fetching, and only repositories that contain
a file named `git-daemon-export-ok`, unless started with `--export-all`. It can
still be the simplest way to share read-only repositories inside a trusted local
network:

```sh
touch /srv/git/atlas.git/git-daemon-export-ok
git daemon --base-path=/srv/git /srv/git
# others then clone git://<this-computer>/atlas.git
```

`--base-path` maps the path in the URL onto a directory, and the directory
arguments limit what may be served.

## Serving a repository yourself

| Way | What the server needs | Who may push |
|---|---|---|
| A shared folder or USB drive | nothing; a bare repository in a directory (Chapter 2) | anyone who can write to the directory |
| SSH | an SSH server and Git | every account whose key is in `authorized_keys`, with that account's file permissions |
| `git daemon` | Git, and port 9418 open | nobody, by default |
| Smart HTTP | a web server running `git http-backend` | authenticated users, by default |
| Hosting software, such as GitLab or Gitea | the software | whoever it allows |

The SSH way needs nothing but Git on a machine you can already log in to:

```sh
ssh ada@server.example.com git init --bare /srv/git/atlas.git
git remote add origin ada@server.example.com:/srv/git/atlas.git
git push -u origin main
```

Every account with SSH access also has a shell on the server. `git shell` is a
login shell that allows only the Git commands and nothing else; Git's
documentation shows it being set for an account with
`chsh -s $(command -v git-shell) <user>`. Several people can then share that one
account, with a line in its `authorized_keys` for each person's public key.

`git http-backend` is the program behind smart HTTP. Git's documentation
describes it as a CGI program, one that a web server starts for each request,
which serves fetches by default,
and pushes only when the web server has authenticated the user; the web server
does the authentication, not Git.

## When a connection fails

The first job with any error is to find which program wrote it, because Git
passes through what `ssh`, the HTTP library and the server say:

| Message | Printed by | Means |
|---|---|---|
| `fatal: Could not read from remote repository.` with `Please make sure you have the correct access rights and the repository exists.` | Git, after an SSH or local connection failed | nothing by itself; the line above it has the cause |
| `fatal: '<path>' does not appear to be a git repository` | `git-upload-pack` on the server, or locally | no repository at that path; for SSH check the path form ([Paths in SSH URLs](#paths-in-ssh-urls)) |
| `<user>@<host>: Permission denied (publickey).` | `ssh` | the server accepted none of the keys offered ([Testing the key](#testing-the-key)) |
| `Host key verification failed.` | `ssh` | the host key is unknown or changed, and could not be confirmed ([The first connection](#the-first-connection)) |
| `ssh: Could not resolve hostname <host>: ...` | `ssh` | the name does not exist, is misspelled, or is a `~/.ssh/config` alias that is not defined |
| `ssh: connect to host <host> port 22: ...` | `ssh` | the server could not be reached on that port ([When port 22 is blocked](#when-port-22-is-blocked)) |
| `remote: ...` | the server | its own explanation; read it first |
| `fatal: Authentication failed for '<url>'` | Git, over HTTPS | the credentials were refused, and helpers were told to forget them ([When HTTPS fails](#when-https-fails)) |
| `fatal: repository '<url>' not found` | Git, over HTTPS | nothing at that address |
| `fatal: unable to access '<url>': <reason>` | Git, with the HTTP library's reason | name lookup, proxy or certificate trouble ([Certificates](#certificates)) |
| `fatal: could not read Username for '<url>': terminal prompts disabled` | Git | credentials were needed and nothing could supply them ([How Git asks](#how-git-asks)) |
| `fatal: transport '<name>' not allowed` | Git | a protocol policy refused it ([Which protocols Git may use](#which-protocols-git-may-use)) |
| `fatal: URL '<url>' uses plaintext credentials` | Git | `transfer.credentialsInUrl=die` ([Credentials in a URL](#credentials-in-a-url)) |
| `fatal: ssh variant 'simple' does not support setting port` | Git | a URL with a port, and an SSH program Git does not recognise ([Which ssh program](#which-ssh-program)) |
| `git: 'remote-<name>' is not a git command` | Git | a `<name>::` URL or `remote.<name>.vcs` with no such helper ([Remote helpers](#remote-helpers)) |

The `ssh` messages are quoted from OpenSSH's source, where their exact wording
can change between versions.

### Seeing more

```sh
GIT_SSH_COMMAND='ssh -v' git fetch        # ssh reports each step and key tried
GIT_TRACE_PACKET=1 git fetch              # every protocol line, as above
GIT_TRACE_CURL=1 git fetch                # every HTTP request and response
GIT_TRACE_CURL=1 GIT_TRACE_CURL_NO_DATA=1 git fetch   # the same, headers only
GIT_TRACE=1 git fetch                     # which programs Git starts
```

`ssh -v` is the answer to most SSH problems, because it names the configuration
files read, the host key and each private key offered. `GIT_TRACE_CURL` does the
same for HTTPS. Git's documentation says the traces hide cookies and
authorization headers by default; `GIT_TRACE_REDACT=0` shows them, which is
exactly what not to paste into a bug report.

## SSH or HTTPS

| | SSH | HTTPS |
|---|---|---|
| You set up | a key pair, once per computer | a token, or a credential helper that signs in for you |
| Proves who you are with | the key; no secret is sent | the token, sent to the server on each connection |
| Stored on your computer | the private key, encrypted by its passphrase | the token, in the helper's storage |
| Works through a proxy or strict firewall | only where port 22, or 443 for hosts that offer it, is open | usually |
| Reading a public repository | SSH always logs in, so a key is still needed | works with no credentials at all |
| Several accounts on one host | host aliases in `~/.ssh/config` | `credential.useHttpPath`, or a username in each URL |
| Limiting what the credential can do | per key, as the host allows | per token, with scopes and expiry |

Both are encrypted and both are fine. HTTPS with the credential helper for your
system is the least to set up, especially on Windows, where Git Credential
Manager comes with Git. SSH suits someone who pushes to several hosts and servers
of their own, and needs nothing typed once the agent holds the key. Nothing
stops you using both, even for one repository, as
[Rewriting URLs](#rewriting-urls) showed.

## The settings

| Setting | Does |
|---|---|
| `core.sshCommand` | the SSH program and its arguments ([Which ssh program](#which-ssh-program)) |
| `ssh.variant` | which options Git passes to it: `auto`, `ssh`, `plink`, `putty`, `tortoiseplink`, `simple` |
| `protocol.version` | the wire protocol version to ask for; 2 by default |
| `protocol.allow`, `protocol.<name>.allow` | which transports may be used: `always`, `never`, `user` |
| `url.<base>.insteadOf`, `url.<base>.pushInsteadOf` | rewrite URLs ([Rewriting URLs](#rewriting-urls)) |
| `remote.<name>.proxy`, `remote.<name>.proxyAuthMethod` | a proxy for one remote |
| `remote.<name>.vcs` | a remote helper for one remote ([Remote helpers](#remote-helpers)) |
| `http.proxy`, `http.proxyAuthMethod` | the proxy for HTTP and HTTPS |
| `http.sslVerify`, `http.sslCAInfo`, `http.sslCAPath`, `http.sslBackend` | certificate checking ([Certificates](#certificates)) |
| `http.<url>.*` | any `http.*` setting for matching URLs only |
| `credential.helper` | the credential helpers, in order; an empty value resets the list |
| `credential.username` | the username to use when none is given |
| `credential.useHttpPath` | make the repository path part of a stored credential |
| `credential.interactive` | `false` forbids asking for credentials interactively |
| `credential.<url>.*` | any `credential.*` setting for matching URLs only |
| `credential.sanitizePrompt`, `credential.protectProtocol` | safety checks on what reaches prompts and helpers; added in the security releases 2.40.4 to 2.48.1 and in 2.49 |
| `credentialCache.ignoreSIGHUP` | keep the cache process running when its terminal closes |
| `credentialStore.lockTimeoutMS` | how long `store` waits to lock its file, 1000 by default |
| `core.askPass` | the askpass program, when `GIT_ASKPASS` is unset |
| `transfer.credentialsInUrl` | `allow`, `warn` or `die` for a password in `remote.<name>.url` |

| Environment variable | Does |
|---|---|
| `GIT_SSH_COMMAND` | the SSH program with arguments; wins over `GIT_SSH` and `core.sshCommand` |
| `GIT_SSH` | the SSH program, a path only |
| `GIT_SSH_VARIANT` | overrides `ssh.variant` |
| `GIT_ASKPASS`, `SSH_ASKPASS` | the askpass program, before and after `core.askPass` |
| `GIT_TERMINAL_PROMPT` | `0` stops Git asking in the terminal |
| `GIT_ALLOW_PROTOCOL` | a colon-separated list of the only transports allowed |
| `GIT_PROTOCOL_FROM_USER` | `0` refuses transports whose policy is `user` |
| `GIT_SSL_NO_VERIFY`, `GIT_SSL_CAINFO` | like `http.sslVerify=false` and `http.sslCAInfo` |
| `GIT_HTTP_USER_AGENT` | like `http.userAgent` |
| `http_proxy`, `https_proxy`, `all_proxy` | proxies, when `http.proxy` is not set |
| `GIT_TRACE_PACKET`, `GIT_TRACE_CURL`, `GIT_TRACE_CURL_NO_DATA`, `GIT_TRACE_REDACT` | traces ([Seeing more](#seeing-more)) |
| `GIT_PROTOCOL` | set by Git itself to offer a protocol version; not for setting by hand, Git's documentation says |
