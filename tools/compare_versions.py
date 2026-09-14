#!/usr/bin/env python3
"""List what a chapter has lost compared with an earlier version of itself.

The author reviews the book on a phone and cannot reread every chapter after
every edit, so "nothing correct was removed" has to be checked, not promised.
This compares the current text of a chapter with its text at a git revision,
the last commit by default, and lists every sentence, table row, heading and
example line that is no longer present anywhere in the chapter.

Something missing is not automatically a mistake. For each item it shows the
closest line that is still there and how similar the two are, so a rewording
can be told apart from a real loss:

  changed 0.86    a sentence with nothing identical left but a close one; or a
                  table row whose first cell survived with other cells edited.
                  Read both and check the meaning survived
  REMOVED         nothing similar is left, or no row has the same first cell.
                  This needs a reason (it was wrong, or could not be verified),
                  or it has to go back

Example lines usually change for a good reason, because the generator script
changed and every hash after that point changed with it. They are listed
separately and counted, not judged.

It never changes a file. Run it before every commit that edits a chapter, and
account for every REMOVED item in the commit message.

    python tools/compare_versions.py 13              chapter 13 against the last commit
    python tools/compare_versions.py 13 16           several chapters
    python tools/compare_versions.py 13 --rev fb015a5    against any revision
    python tools/compare_versions.py --changed       every chapter with uncommitted edits
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
from difflib import SequenceMatcher

ROOT = pathlib.Path(__file__).resolve().parent.parent
BOOK = ROOT / "book"
SIMILAR = 0.6

LINK_RE = re.compile(r"^- \[[^\]]+\]\((?P<path>[^)]+)\)\s*$", re.M)


def git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True,
                          text=True, encoding="utf-8")


def chapter_files() -> dict[str, pathlib.Path]:
    found = {}
    for m in LINK_RE.finditer((BOOK / "SUMMARY.md").read_text(encoding="utf-8")):
        path = BOOK / m.group("path")
        number = re.match(r"0*(\d+)-", path.name)
        found[number.group(1) if number else path.stem] = path
    return found


def units(text: str) -> tuple[list[str], list[str], list[str]]:
    """Example lines, table rows, and prose sentences (headings included)."""
    code, rows, prose = [], [], []
    in_code, para = False, []

    def flush() -> None:
        if not para:
            return
        joined = " ".join(para)
        joined = re.sub(r"^>\s*", "", joined)
        joined = re.sub(r"\s>\s+", " ", joined)
        for sentence in re.split(r"(?<=[.!?:])\s+(?=[A-Z`*(\"\[])", joined):
            sentence = " ".join(sentence.split())
            if sentence:
                prose.append(sentence)
        para.clear()

    for line in text.splitlines():
        if line.startswith("```"):
            flush()
            in_code = not in_code
            continue
        if in_code:
            if line.strip():
                code.append(line.rstrip())
            continue
        if line.startswith("|"):
            flush()
            if not re.match(r"^\|[-| :]+\|$", line):
                rows.append(" ".join(line.split()))
            continue
        stripped = line.strip()
        if not stripped or stripped.startswith(("<details", "</details", "<summary", "<!--")):
            flush()
            continue
        if line.startswith("#"):
            flush()
            prose.append("HEADING " + line.lstrip("# ").strip())
            continue
        para.append(stripped)
    flush()
    return code, rows, prose


def first_cell(row: str) -> str:
    cells = re.split(r"(?<!\\)\|", row)
    return cells[1].strip() if len(cells) > 2 else row


def closest(item: str, candidates: list[str]) -> tuple[float, str]:
    best, score = "", 0.0
    matcher = SequenceMatcher(None, item)
    for c in candidates:
        matcher.set_seq2(c)
        if matcher.real_quick_ratio() < score or matcher.quick_ratio() < score:
            continue
        r = matcher.ratio()
        if r > score:
            best, score = c, r
    return score, best


def compare(key: str, path: pathlib.Path, rev: str) -> int:
    rel = path.relative_to(ROOT).as_posix()
    old = git("show", f"{rev}:{rel}")
    if old.returncode != 0:
        print(f"Chapter {key}: not present at {rev}, nothing to compare")
        return 0
    o_code, o_rows, o_prose = units(old.stdout)
    n_code, n_rows, n_prose = units(path.read_text(encoding="utf-8"))
    new_flat = " ".join(re.sub(r"(?m)^>\s?", "", path.read_text(encoding="utf-8")).split())

    lost_prose = [s for s in dict.fromkeys(o_prose)
                  if (s.startswith("HEADING ") and s not in n_prose)
                  or (not s.startswith("HEADING ") and s not in new_flat)]
    lost_rows = [r for r in dict.fromkeys(o_rows) if r not in set(n_rows)]
    lost_code = [c for c in dict.fromkeys(o_code) if c not in set(n_code)]

    removed = 0
    report = []
    for item in lost_prose:
        score, match = closest(item, n_prose)
        if score >= SIMILAR:
            report.append(f"  changed {score:.2f}  text: {item[:150]}\n{'':16}now: {match[:150]}")
        else:
            removed += 1
            report.append(f"  REMOVED       text: {item[:150]}")

    # A table row is identified by its first cell, never by overall similarity:
    # rows in one table share columns, so a deleted row always looks like its
    # neighbour, and a similarity match would hide exactly the loss being sought.
    new_by_key = {}
    for r in n_rows:
        new_by_key.setdefault(first_cell(r), []).append(r)
    for item in lost_rows:
        same_key = new_by_key.get(first_cell(item), [])
        if same_key:
            score, match = closest(item, same_key)
            report.append(f"  changed {score:.2f}  row:  {item[:150]}\n{'':16}now: {match[:150]}")
        else:
            removed += 1
            report.append(f"  REMOVED       row:  {item[:150]}")

    print(f"Chapter {key} against {rev}: {len(lost_prose)} sentences and headings, "
          f"{len(lost_rows)} table rows, {len(lost_code)} example lines no longer present; "
          f"{removed} with nothing similar left")
    for line in report:
        print(line)
    if lost_code:
        print(f"  example lines no longer present: {len(lost_code)} "
              f"(expected when the generator changed; listed with --examples)")
        if "--examples" in sys.argv:
            for c in lost_code:
                print(f"    {c[:150]}")
    return removed


def main() -> int:
    args = sys.argv[1:]
    rev = "HEAD"
    if "--rev" in args:
        rev = args[args.index("--rev") + 1]
    files = chapter_files()
    if "--changed" in args:
        changed = git("diff", "--name-only", rev, "--", "book").stdout.split()
        keys = [k for k, p in files.items() if p.relative_to(ROOT).as_posix() in changed]
        if not keys:
            print(f"no chapter differs from {rev}")
            return 0
    else:
        keys = [a for a in args if not a.startswith("--") and a != rev]
    if not keys:
        print(__doc__)
        return 2
    for key in keys:
        if key not in files:
            print(f"Chapter {key} is not in SUMMARY.md", file=sys.stderr)
            return 2
        compare(key, files[key], rev)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
