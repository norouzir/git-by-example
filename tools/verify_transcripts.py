#!/usr/bin/env python3
"""Check that every transcript in a chapter is what the commands really print.

The book promises that no output was typed from memory. This holds it to that:
it runs the chapter's generator script, then checks that every `console` and
`ansi` block in the chapter appears in the generator's output, line for line
and in order.

Two things are allowed to differ, both documented in Chapter 1:

  ...        a line containing only three dots skips any number of lines
  # note     a comment line the book added, which the output need not contain

Anything else that does not match is reported, which catches output that was
trimmed without saying so, output that was retyped, and output that was
invented. A block must also stop where its last command's output stops: lines
cut off the end without a closing `...` are reported too.

    python tools/verify_transcripts.py 13        one chapter
    python tools/verify_transcripts.py 9 13 16   several
"""

from __future__ import annotations

import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"
SCRIPTS = ROOT / "sandbox" / "scripts"

LINK_RE = re.compile(r"^- \[[^\]]+\]\((?P<path>[^)]+)\)\s*$", re.M)
BLOCK_RE = re.compile(r"```(console|ansi)\n(.*?)```", re.S)


def chapter_file(number: int) -> pathlib.Path | None:
    for m in LINK_RE.finditer((BOOK / "SUMMARY.md").read_text(encoding="utf-8")):
        path = BOOK / m.group("path")
        if re.match(rf"0*{number}-", path.name):
            return path
    return None


def find_bash() -> str:
    """The bash that ships with Git.

    On Windows, asking for plain "bash" can start the WSL launcher from
    System32 instead, which fails or runs a different Git entirely.
    """
    if os.name == "nt":
        for candidate in (
            pathlib.Path(r"C:\Program Files\Git\bin\bash.exe"),
            pathlib.Path(r"C:\Program Files\Git\usr\bin\bash.exe"),
        ):
            if candidate.exists():
                return str(candidate)
    return shutil.which("bash") or "bash"


def generator_output(number: int) -> list[str]:
    scripts = sorted(SCRIPTS.glob(f"ch{number:02d}-*.sh"))
    if not scripts:
        return []
    with tempfile.TemporaryDirectory() as scratch:
        result = subprocess.run(
            [find_bash(), str(scripts[0]), scratch],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
    return [line.rstrip() for line in (result.stdout + result.stderr).splitlines()]


def ends_cleanly(output: list[str], o: int) -> bool:
    """Does the output of the block's last command stop where the block does?

    After the last matched line, and any blank lines a block cannot show at its
    end, must come the next command, a comment line such as the one `sb_say`
    prints between sections, or the end of the run. Anything else is output the
    block left out without a `...`.
    """
    while o < len(output) and output[o] == "":
        o += 1
    return o >= len(output) or output[o].startswith(("$ ", "# "))


def matches(block: list[str], output: list[str]) -> tuple[bool, str]:
    """Is `block` found in `output`, in order, honouring `...` and notes?"""
    first = next((i for i, l in enumerate(block) if l not in ("...",) and not l.startswith("# ")), None)
    if first is None:
        return True, ""
    best_fail, cut_short = "", ""
    for start, line in enumerate(output):
        if line != block[first]:
            continue
        o, ok, skipping = start + 1, True, False
        for want in block[first + 1:]:
            if want == "...":
                skipping = True
                continue
            if skipping:
                found = next((j for j in range(o, len(output)) if output[j] == want), None)
                if found is None:
                    ok, best_fail = False, want
                    break
                o, skipping = found + 1, False
                continue
            if o < len(output) and output[o] == want:
                o += 1
            elif want.startswith("# "):
                continue
            else:
                ok, best_fail = False, want
                break
        if ok and (skipping or ends_cleanly(output, o)):
            return True, ""
        if ok and not cut_short:
            rest = next(l for l in output[o:] if l != "")
            cut_short = f"(the block ends, but the output goes on with) {rest}"
    return False, cut_short or best_fail or block[first]


def main() -> int:
    numbers = [int(a) for a in sys.argv[1:]]
    if not numbers:
        print(__doc__)
        return 2
    failed = False
    for number in numbers:
        path = chapter_file(number)
        if path is None:
            print(f"Chapter {number} is not in SUMMARY.md", file=sys.stderr)
            return 2
        output = generator_output(number)
        if not output:
            print(f"Chapter {number:>2}  has no generator script, so nothing in it can be verified")
            failed = True
            continue
        text = path.read_text(encoding="utf-8")
        blocks = [(m.start(), m.group(2)) for m in BLOCK_RE.finditer(text)]
        bad = []
        for offset, body in blocks:
            lines = [l.rstrip() for l in body.rstrip("\n").splitlines()]
            if not any(l.startswith("$ ") for l in lines):
                continue  # an illustration, not a transcript
            ok, where = matches(lines, output)
            if not ok:
                line_no = text.count("\n", 0, offset) + 1
                bad.append((line_no, lines[0], where))
        checked = sum(1 for _, b in blocks if "\n$ " in "\n" + b)
        print(f"Chapter {number:>2}  {checked} transcripts checked, {len(bad)} do not match real output")
        for line_no, head, where in bad:
            print(f"    line {line_no}: {head}\n        first line that does not match: {where!r}")
        failed = failed or bool(bad)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
