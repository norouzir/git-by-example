#!/usr/bin/env python3
"""Check that every option listed in a chapter's tables is actually shown.

A reader with no computer cannot try an option to see what it does, so an
option that appears in a table with no example is one they can only guess at.
For every table row that names an option, this looks for one of:

  demonstrated  the option is used in a `$ ` command inside a console or ansi
                block in the same chapter
  pointer       the row names another chapter, where the option is taught
                with its concept; once that chapter exists, the option must
                be demonstrated there
  exception     the chapter file contains a written reason for having no
                example, as a comment that does not appear in the book:

                    <!-- no-example: --option  why it needs no example -->

Anything else is reported as missing and the script exits 1.

This measures exactly one thing. Passing it means no option was forgotten. It
does not mean the chapter is complete: comparisons with similar commands and
"what happens if" cases are invisible to it.

    python tools/audit_examples.py             every chapter in SUMMARY.md
    python tools/audit_examples.py 13 14       only these chapters
    python tools/audit_examples.py 13 --exceptions   also list the reasons
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"

LINK_RE = re.compile(r"^- \[[^\]]+\]\((?P<path>[^)]+)\)\s*$", re.M)
BLOCK_RE = re.compile(r"```(?:console|ansi)\n(.*?)```", re.S)
OPTION_RE = re.compile(r"`(-{1,2}[A-Za-z][\w-]*)")
POINTER_RE = re.compile(r"\bChapter (\d+)\b")
EXCEPTION_RE = re.compile(r"<!--\s*no-example:\s*(\S+)\s+(.*?)-->", re.S)
ESCAPE_RE = re.compile(r"\\e\[[0-9;]*[A-Za-z]")
GLOBAL_OPTS_RE = re.compile(r"\bgit(?:\s+(?:-C|-c)\s+\S+|\s+--no-pager|\s+--git-dir=\S+|\s+--work-tree=\S+)+\s+")
CELL_SPLIT_RE = re.compile(r"(?<!\\)\|")


def chapters() -> dict[int, pathlib.Path]:
    """Chapter number to file, for every numbered chapter in the manifest."""
    found: dict[int, pathlib.Path] = {}
    for m in LINK_RE.finditer((BOOK / "SUMMARY.md").read_text(encoding="utf-8")):
        path = BOOK / m.group("path")
        number = re.match(r"(\d+)-", path.name)
        if number:
            found[int(number.group(1))] = path
    return found


def command_lines(text: str) -> str:
    """Only the typed commands in example blocks, never the output."""
    lines = []
    for block in BLOCK_RE.findall(text):
        for line in ESCAPE_RE.sub("", block).splitlines():
            if line.startswith("$ "):
                # Options before the subcommand belong to git itself, such as
                # `git -C dir`, and must not count as the subcommand's -C.
                lines.append(GLOBAL_OPTS_RE.sub("git ", line[2:]))
    return "\n".join(lines)


def is_used(option: str, commands: str) -> bool:
    # an option ends at whitespace, a value, a quote, or a shell operator
    end = r"\s='\";|&)<>"
    if option.startswith("--"):
        tail = rf"(?=$|[{end}])"
        return re.search(r"(?<![\w-])" + re.escape(option) + tail, commands, re.M) is not None
    # short options may carry an attached value (-U0, -M90%, -l100) or be
    # bundled with others (-fd, -sb, -am)
    letter = re.escape(option[1:])
    alone = r"(?<![\w-])-" + letter + rf"(?=$|[{end}0-9%])"
    bundled = r"(?<![\w-])-[A-Za-z]*" + letter + rf"[A-Za-z]*(?=$|[{end}])"
    return re.search(alone, commands, re.M) is not None or re.search(bundled, commands, re.M) is not None


def audit(number: int, path: pathlib.Path, all_chapters: dict[int, pathlib.Path]) -> tuple[list, list]:
    text = path.read_text(encoding="utf-8")
    commands = command_lines(text)
    exceptions = {opt: " ".join(reason.split()) for opt, reason in EXCEPTION_RE.findall(text)}
    rows, seen = [], set()

    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = CELL_SPLIT_RE.split(line)
        options = OPTION_RE.findall(cells[1]) if len(cells) > 2 else []
        if not options or cells[1] in seen:
            continue
        seen.add(cells[1])
        label = cells[1].strip()

        if any(is_used(o, commands) for o in options):
            rows.append(("demonstrated", label, ""))
            continue
        excused = next((o for o in options if o in exceptions), None)
        if excused:
            rows.append(("exception", label, exceptions[excused]))
            continue
        pointer = POINTER_RE.search(line)
        if pointer and int(pointer.group(1)) != number:
            target = int(pointer.group(1))
            if target not in all_chapters:
                rows.append(("pointer, pending", label, f"Chapter {target} is not written yet"))
            elif any(is_used(o, command_lines(all_chapters[target].read_text(encoding="utf-8"))) for o in options):
                rows.append(("pointer, verified", label, f"shown in Chapter {target}"))
            else:
                rows.append(("missing", label, f"points to Chapter {target}, which does not show it"))
            continue
        rows.append(("missing", label, ""))

    return rows, [r for r in rows if r[0] == "missing"]


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    show_exceptions = "--exceptions" in sys.argv
    all_chapters = chapters()
    wanted = [int(a) for a in args] if args else sorted(all_chapters)

    failed = False
    for number in wanted:
        if number not in all_chapters:
            print(f"Chapter {number} is not in SUMMARY.md", file=sys.stderr)
            return 2
        rows, missing = audit(number, all_chapters[number], all_chapters)
        if not rows:
            continue
        counts: dict[str, int] = {}
        for status, _, _ in rows:
            counts[status] = counts.get(status, 0) + 1
        summary = ", ".join(f"{n} {s}" for s, n in sorted(counts.items()))
        print(f"Chapter {number:>2}  {len(rows):>3} option rows: {summary}")
        for _, label, note in missing:
            print(f"    missing   {label}" + (f"   ({note})" if note else ""))
        if show_exceptions:
            for status, label, note in rows:
                if status == "exception":
                    print(f"    exception {label}\n              {note}")
        failed = failed or bool(missing)

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
