# Working on this book

Read this before writing a single line of the book. `DECISIONS.md` explains why
these rules exist; `OUTLINE.md` is the approved structure and the source of
chapter numbers.

## What this is

*Git by Example: A Complete Offline Handbook*. A Git reference for a reader who
has a phone, no computer, and no internet. Everything they would normally learn
by running a command or searching the web has to be on the page.

The repository is <https://github.com/norouzir/git-by-example>.

## The rules that are not negotiable

**Never state a Git fact from memory.** Training data is older than the
installed Git. Check the documentation that ships with the install:

| Source | Path | Use for |
|---|---|---|
| Command docs | `C:\Program Files\Git\mingw64\share\doc\git-doc\*.adoc` | Behaviour, options, synopsis |
| Config variables | same directory, `git-config.html` | Config docs are only assembled into the HTML |
| Release notes | `.../git-doc/RelNotes/*.adoc` | Which release introduced a feature, for version badges |
| Deprecations | `.../git-doc/BreakingChanges.adoc` | What is deprecated now vs planned for Git 3.0 |
| Exact synopsis | `git <cmd> -h` | What the installed binary actually accepts |

Reach for the web only when something is not on disk.

**Never invent output.** Every transcript in the book comes from actually
running the commands through the sandbox harness. If an example cannot be run,
it does not go in the book in transcript form.

**Never break hash reproducibility.** Examples run under `sandbox/lib/sandbox.sh`,
which pins identity, clock, configuration and line endings. After touching the
harness, run the self-test:

```sh
bash sandbox/scripts/selftest-reproducibility.sh
```

**Badge anything newer than Git 2.23.** A reader on an older Git gets an
`unknown option` error that says nothing about versions. Confirm the release
from the local release notes before writing the badge, never from memory.

## Style contract

Explain everything in the cheapest form that actually works, in this order:

1. An example, if a transcript shows what happens.
2. A short paragraph, if the example is correct but incomplete.
3. A long explanation, only if leaving it out would let the reader lose work.

A table replaces all three whenever the content is a list of parallel facts.
Long prose is allowed; it just needs a reason to exist.

Cover the variations, not the happy path. For each command the reader should
find: what it does, every option worth knowing, what changes if a flag is
altered, what error appears when it is used wrongly, how it differs from its
neighbours, what the common practice is, and how to undo it.

The tone is direct and unceremonious. Contractions are fine. Marketing language
is not.

## Conventions the text already uses

Defined in Chapter 1, so changing one means editing that chapter too.

| Convention | Form |
|---|---|
| Transcripts | fenced ` ```console `, commands prefixed `$ `, output unprefixed |
| Placeholders | `<angle-brackets>` |
| Trimmed output | `...` on its own line |
| Call-outs | blockquote opening with **Since Git X.Y.**, **Windows.**, **Careful.**, or **Worth knowing.** |
| Modern vs classic commands | a two-column table, modern first |

Paths in captured output are rewritten to `/home/ada`, and machine-specific
user names and hostnames to `<user>` and `<hostname>`. That is the only editing
of real output that is permitted.

## Workflow

Deliver one part at a time and stop for feedback before starting the next.

Writing a chapter means three artefacts, not one:

1. `book/part-NN-.../NN-slug.md`, the chapter.
2. `sandbox/scripts/chNN-slug.sh`, the script that generates its examples.
3. A line added to `book/SUMMARY.md`, which is the build manifest and controls
   order. The build fails on a file listed there that does not exist.

Then mark the chapter `[x]` in `OUTLINE.md`, check that every forward reference
still points somewhere real, and rebuild:

```sh
python tools/check_refs.py --map
python tools/build_html.py
powershell -File tools/build_pdf.ps1
```

A reader with no internet cannot recover from a cross-reference that leads to
the wrong chapter, so `check_refs.py` must pass before a part is called done.

## Things that have already bitten

**Line endings.** `core.autocrlf=true` at system level on Windows was storing
shell scripts with CRLF, which makes a shebang fail on Linux with
`bad interpreter`. `.gitattributes` now forces LF. Do not remove it.

**PDF rendering.** Headless Edge silently writes no file if another Edge is
already running, because the new process hands off to the existing instance and
exits. `tools/build_pdf.ps1` passes its own `--user-data-dir` to prevent that.
Do not remove that flag.

**Large heredocs.** Writing a long chapter through a shell heredoc is fragile
with this much mixed punctuation. Use the file-writing tool instead.

**Sandbox environment leaking.** The harness exports `GIT_AUTHOR_*`,
`GIT_COMMITTER_*` and `GIT_CONFIG_GLOBAL`. Never source it in a shell that will
later commit to this repository, or the book's commits get authored by Ada
Lovelace in 2026.

**Reading the config docs from Python.** Config variables are only in the
assembled `git-config.html`, and Python cannot open the MSYS-style
`/mingw64/...` path. Use the Windows path:
`C:/Program Files/Git/mingw64/share/doc/git-doc/git-config.html`. Strip tags
and search the text.

**`set -e` in generator scripts.** Several commands answer with a non-zero
exit rather than failing: `git check-ignore` when nothing matches,
`git diff --quiet` on a dirty tree, `git rm` on an unmatched path. Under
`set -e` these terminate the script mid-transcript and the truncation is easy
to miss. Either write them as a condition (`cmd && echo a || echo b`) or drop
`-e` for that script with a comment saying why, as `ch16` does.

**Quoting through `sb_run`.** `sb_run` joins its arguments and evals them, so
inner quotes are lost: `sb_run git branch 'bad name'` runs
`git branch bad name`, which is a different command with a different error.
Pass the whole thing as one string instead: `sb_run "git branch 'bad name'"`.

## Layout

```
book/SUMMARY.md          build manifest; order here is the book's order
book/part-NN-*/          one directory per part, one file per chapter
sandbox/lib/sandbox.sh   the harness; sb_fresh, sb_write, sb_commit, sb_run
sandbox/lib/gitconfig    the pinned configuration examples run under
sandbox/scripts/         one generator script per chapter
tools/build_html.py      Markdown to one self-contained HTML file
tools/build_pdf.ps1      that HTML to PDF via headless Edge
build/                   generated, not tracked
OUTLINE.md               approved structure, stable chapter numbers
DECISIONS.md             why the book is the way it is
```
