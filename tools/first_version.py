#!/usr/bin/env python3
r"""Find the first Git release in which a file of Git's own source contains a pattern.

Version badges must be confirmed, never recalled. The local release notes are
the first place to look, but they do not mention every option: `git clone
--revision`, `git clone --tags` and `git init --initial-branch` appear in no
release note at all. This fills the gap by reading the file as it was in each
release, straight from the Git source repository, and binary-searching the
minor versions for the first one that matches.

Two kinds of file answer two questions:

  Documentation/<page>     when the option was documented
  builtin/<command>.c      when the option actually existed

They can disagree. `git clone --tags` works from 2.49 but was documented only in
2.52, so for a badge search the source, and match the option's definition
exactly, such as `OPT_BOOL\(0, "tags"`. The pattern is a Python regular
expression, so parentheses are escaped and alternatives are written with a bare
`|`. A loose pattern like '"revision"' matches unrelated strings too, and gives
an answer that is far too early.

Documentation pages were .txt files before they were .adoc; both are tried.
This needs network access, and is only for writing the book, never for reading it.

    python tools/first_version.py builtin/clone.c 'OPT_STRING\(0, "revision"'
    python tools/first_version.py Documentation/git-clone '^`--revision'
"""

from __future__ import annotations

import re
import subprocess
import sys
import urllib.error
import urllib.request

RAW = "https://raw.githubusercontent.com/git/git/v2.{minor}.0/{path}"


def installed_minor() -> int:
    out = subprocess.run(["git", "--version"], capture_output=True, text=True).stdout
    match = re.search(r"git version 2\.(\d+)", out)
    return int(match.group(1)) if match else 55


def fetch(minor: int, path: str) -> str | None:
    candidates = [path]
    if path.startswith("Documentation/") and not re.search(r"\.\w+$", path):
        candidates = [path + ".adoc", path + ".txt"]
    for candidate in candidates:
        try:
            with urllib.request.urlopen(RAW.format(minor=minor, path=candidate), timeout=30) as r:
                return r.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError:
            continue
    return None


def contains(minor: int, path: str, pattern: re.Pattern) -> bool:
    body = fetch(minor, path)
    return body is not None and pattern.search(body) is not None


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    path, pattern = sys.argv[1], re.compile(sys.argv[2], re.M)
    hi = installed_minor()
    if not contains(hi, path, pattern):
        print(f"{path}: pattern not found even in 2.{hi}.0")
        return 1
    lo = 0
    if contains(lo, path, pattern):
        print(f"{path}: already present in 2.0.0, so no badge is needed")
        return 0
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if contains(mid, path, pattern):
            hi = mid
        else:
            lo = mid
    print(f"{path}: first present in 2.{hi}.0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
