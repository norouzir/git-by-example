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

### The order inside a chapter

The author had to point out that Chapter 13 opened with fine details before
saying what `git diff` is. That must never happen again. A chapter about a
command follows this order:

1. **What it is.** A short explanation of the command itself, and the one
   question its plain form answers. Define any term the next sections rely on.
   Then the collapsed list of questions the chapter answers (see below).
2. **Synopsis.** The forms from Git's own documentation, what each part means,
   and what each form does.
3. **Options at a glance.** Every option, one line each, with the section where
   it is demonstrated.
4. **Details, in teaching order.** Reading the output comes first, then the core
   model, then the options grouped by purpose, then edge cases.
5. **Comparisons with neighbours**, after the reader knows the command well
   enough for the comparison to mean something: `diff` for `git diff`, `patch`
   for `git apply`, and so on.
6. **Reference tables**, such as settings.

This order is about the chapter as a whole. Inside a section the three-layer
rule from the top of this contract applies unchanged: a section may open with
its example, and a sentence goes before the example only when the heading and
the example together cannot be understood without it. That is the case when the
example uses syntax not yet introduced (`git -c` before Chapter 62), or depends
on a setup the transcript does not show and the reader would misread without
knowing. A sentence that restates the heading, or describes what the transcript
already shows, does not belong before or after it.

An earlier version of this contract said every section must open with prose.
The author pointed out that contradicts the three-layer rule, and 33 lead
sentences added to Chapter 13 under it were removed again. Do not reintroduce
it.

Never refer forward to explain something. A pointer to where a topic is covered
in full is fine; relying on a later section for the reader to understand this
one is not.

### Tables that list values

A table listing the values an option accepts must show the complete syntax in
every row, never a bare value. Write `--color-moved=zebra`, not `zebra` under a
header called "Mode": a reader cannot know what "Mode" is or where it goes.
For a configuration setting, the header names the setting: "Value of
`credential.helper`". The same applies to any table whose first column would
otherwise be meaningless on its own.

`tools/audit_examples.py` checks every `--option=value` row separately, so each
value needs its own example, pointer, or written exception.

### Before delivering a chapter

The tools do not see ambiguity. Before a chapter is delivered, check by hand:

- Every table header says what its first column is.
- Every term is defined before the first place it is used, including in the
  options table near the top.
- Every example is understandable from its heading and itself, or has the one
  sentence that makes it so, and no sentence merely restates either.
- Nothing correct was removed. Compare against the previous version of the
  chapter sentence by sentence before delivering a rework; a reworded sentence
  must keep its meaning, and a removed one needs a reason (it was wrong, or
  untested and could not be verified).
- Every claim of equivalence ("the same as", "identical to") is demonstrated,
  or attributed in the text to Git's documentation where it says so.
- The question list covers every section, in the chapter's order, in the
  reader's words, and gives no answer away.

### What complete means

Part 2 was first written to a lower standard and sent back. Chapter 13 is the
calibrated example of the depth expected; read it before writing a chapter.

**The inclusion test is reader uncertainty.** An example belongs if a reader who
has read the chapter up to that point would still be unsure what happens. It is
redundant only if they could confidently predict the output. The same command
in a different state (empty repository, detached HEAD, mid-merge, outside a
repository) usually passes.

**Comparisons are content.** Whenever two commands, options or forms look alike,
say so and show the difference. When they are genuinely identical, say that and
show it. "What is the difference between X and Y" and "can I use X instead of Y"
are among the most important questions the book answers. So is the neighbour
outside Git: `diff` for `git diff`, `patch` for `git apply`, and so on.

**Every chapter lists the questions it answers, in the chapter itself.** It
sits directly after "What it is", as a collapsed block grouped by the chapter's
sections, each question linking to the section or subsection that answers it.
This list is the single source; generator scripts do not keep a copy.

- Write each question as a reader who does not know the answer would ask it,
  in the words they would use while stuck. "I set the rename threshold to 5 and
  nothing changed. Why?", not "Why is -M5 not 5%?". Never put the answer, or a
  term the reader cannot know yet, into the question.
- The list finds gaps. It only grows: an example that teaches something not on
  it means the list was incomplete, and the question is added. It never rejects
  an example.
- `tools/check_refs.py` fails on a question link that leads nowhere and on a
  section no question points to.

**Every option named in a table needs one of:**

1. an example in the chapter;
2. a pointer in that row to the chapter where its concept is taught, with the
   full example there instead of repeated here;
3. a written reason, as a comment in the chapter file directly below the table:

   ```
   <!-- no-example: --option
        why an example would show nothing the sentence does not -->
   ```

   Reasons must be specific. "Niche" is not a reason; "tested on these three
   cases and the output was identical to the default" is.

**List every exception in the delivery message**, with its reason, so the author
can reject one without opening a file. `tools/audit_examples.py N --exceptions`
prints them.

**Test before claiming.** Several facts in Chapter 13 turned out false only when
run: GNU `patch` does understand Git's rename headers; the number in `--stat` is
literal and only the bar scales; `-B` and `--no-indent-heuristic` showed no
difference on any small case tried. Run it, then write it.

The tone is direct and unceremonious. Contractions are fine. Marketing language
is not.

## Conventions the text already uses

Defined in Chapter 1, so changing one means editing that chapter too.

| Convention | Form |
|---|---|
| Transcripts | fenced ` ```console `, commands prefixed `$ `, output unprefixed |
| Coloured transcripts | fenced ` ```ansi `, escapes written as the visible characters `\e[...m`; generate with `sb_run_ansi`. Only where the option shown is about colour; everything else stays plain |
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

Then mark the chapter `[x]` in `OUTLINE.md`, run all three checks, and rebuild:

```sh
python tools/verify_transcripts.py N     # every transcript matches a real run
python tools/audit_examples.py N         # every table option is shown, pointed, or excused
python tools/check_refs.py --map         # every "see Chapter N" resolves
python tools/build_html.py
powershell -File tools/build_pdf.ps1
```

All three must pass before a part is called done. A reader with no internet
cannot recover from a transcript that lies, an option they can only guess at, or
a cross-reference that leads nowhere.

The printed command in a transcript must be exactly what a reader types. Never
simplify it in the chapter; change the generator instead. The verifier catches
the difference.

No release until the whole book is complete and every check passes on every
chapter. See DECISIONS.md for why. Work that must be done before then, including
chapters already marked written that fall short of the current standard, is
listed under "Outstanding" in OUTLINE.md. Keep that list current.

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

**Running bash from Windows Python.** `subprocess.run(["bash", ...])` starts
the WSL launcher from System32, not Git Bash, and fails with a message about
attaching a disk. `tools/verify_transcripts.py` resolves Git's own `bash.exe`
explicitly. Do the same in any new tool.

**Colour and time in the harness.** `sb_run_ansi` forces colour through the
environment so the printed command stays what a reader types. `TZ` is pinned to
UTC because `diff -u` and `--date=local` print local time. `sb_touch` sets file
modification times to the sandbox clock for tools that print them.

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
tools/verify_transcripts.py  checks transcripts against a fresh run
tools/audit_examples.py  checks every table option is shown, pointed, or excused
tools/check_refs.py      checks every chapter reference resolves
build/                   generated, not tracked
OUTLINE.md               approved structure, stable chapter numbers
DECISIONS.md             why the book is the way it is
```
