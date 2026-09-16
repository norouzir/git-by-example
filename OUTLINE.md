# Outline

The approved structure of the book. Agreed 2026-09-11, before writing started.

**Chapter numbers are stable and load-bearing.** The text cross-references
chapters by number, so a chapter keeps its number even if it is written out of
order. Inserting a chapter means appending it at the end of its part and
accepting a gap in reading order, or renumbering every reference in the book.
Prefer the former.

Status marks: `[x]` written, `[ ]` not yet. A chapter marked written may still
fall short of the current standard; see Outstanding below.

## Part 0. Using This Book

- [x] 1. How to Read This Book
- [x] 2. The Sandbox
- [x] 3. Installing and Configuring Git

## Part 1. The Mental Model

- [x] 4. What Git Actually Stores
- [x] 5. The Three Areas: Working Tree, Index, Repository
- [x] 6. The Four Object Types
- [x] 7. Refs, HEAD, and Branches as Pointers
- [x] 8. The Lifecycle of a File

## Part 2. Everyday Work

- [x] 9. init and clone
- [x] 10. status
- [x] 11. add
- [x] 12. commit
- [x] 13. diff
- [x] 14. Undoing Local Changes with restore
- [x] 15. rm and mv
- [x] 16. Ignoring Files

## Part 3. Reading History

- [x] 17. log
- [x] 18. Revision Syntax and show
- [x] 19. blame
- [x] 20. bisect
- [x] 21. grep and Searching History
- [x] 22. shortlog, describe, rev-list, rev-parse

## Part 4. Branching and Merging

- [x] 23. branch
- [x] 24. switch, checkout, and detached HEAD
- [x] 25. merge
- [x] 26. Conflicts
- [x] 27. Merge Strategies and Options

## Part 5. Rewriting History

- [x] 28. The Golden Rule of Rewriting
- [x] 29. commit --amend
- [x] 30. reset
- [x] 31. revert
- [x] 32. cherry-pick
- [x] 33. rebase
- [x] 34. Interactive Rebase
- [x] 35. fixup, autosquash, and git history
- [x] 36. reflog
- [x] 37. Removing Files and Secrets from History
- [x] 38. replace, notes, and grafts

## Part 6. Remotes

- [ ] 39. remote
- [ ] 40. Protocols and Authentication
- [ ] 41. fetch and Remote-Tracking Branches
- [ ] 42. pull
- [ ] 43. push
- [ ] 44. Refspecs
- [ ] 45. Divergence and Rejected Pushes
- [ ] 46. Shallow, Partial, and Single-Branch Clones

## Part 7. Collaboration

- [ ] 47. Tags
- [ ] 48. Releases and Versioning
- [ ] 49. Workflow Patterns
- [ ] 50. Forks and Pull Requests on GitHub
- [ ] 51. Merge Requests on GitLab
- [ ] 52. Code Review Mechanics
- [ ] 53. Commit Message Conventions
- [ ] 54. Collaboration Hazards

## Part 8. Specialised Tools

- [ ] 55. stash
- [ ] 56. worktree
- [ ] 57. submodule
- [ ] 58. subtree
- [ ] 59. Git LFS
- [ ] 60. sparse-checkout and Monorepos
- [ ] 61. bundle, archive, and Patch Workflows

## Part 9. Configuration

- [ ] 62. config in Depth
- [ ] 63. The Settings That Actually Matter
- [ ] 64. Aliases
- [ ] 65. gitattributes
- [ ] 66. Line Endings
- [ ] 67. Hooks
- [ ] 68. Signing Commits and Tags
- [ ] 69. Performance Tuning

## Part 10. Internals

- [ ] 70. A Tour of the .git Directory
- [ ] 71. Object Storage on Disk
- [ ] 72. Packfiles and Deltas
- [ ] 73. The Index File Format
- [ ] 74. Refs, Symbolic Refs, and packed-refs
- [ ] 75. Plumbing and Porcelain
- [ ] 76. Merge Base and Graph Algorithms
- [ ] 77. gc, fsck, and Dangling Objects

## Part 11. Recovery

- [ ] 78. The Lost-Commit Decision Tree
- [ ] 79. Recovering Branches, Resets, Rebases, and Stashes
- [ ] 80. Fixing a Merge or Rebase Mid-Flight
- [ ] 81. Repairing a Corrupted Repository
- [ ] 82. Huge Repositories and Large Files
- [ ] 83. Undoing Anything: The Master Table

## Appendices

- [ ] A. Command Index
- [ ] B. Error Message Catalogue
- [ ] C. Configuration Variable Catalogue
- [ ] D. Revision Syntax Reference Card
- [ ] E. Glossary
- [ ] F. Cheat Sheets by Task
- [ ] G. "Which Command Do I Need?" Decision Tables
- [ ] H. Windows Notes, Collected
- [ ] I. Exercises with Answers

## Outstanding

Work that must be finished before the first release, most urgent first.

- **Part 5 review by the author.** Chapters 28 to 38 were written to the
  Chapter 13 standard and pass all three checks (2026-09-16), with no
  checkpoints at all, which is now the rule (see DECISIONS.md). None has been
  read by the author yet.
- **Chapter 37 needs a program that is not part of Git.** `git-filter-repo`
  must be on `PATH` or that chapter's transcripts cannot be verified; CLAUDE.md
  and README.md say how to install it. No other chapter needs anything beyond
  Git itself.
- **Part 4 review by the author.** Chapters 23 to 27 were written to the
  Chapter 13 standard and pass all three checks (2026-09-16), without the first
  two checkpoints (see DECISIONS.md). None has been read by the author yet.
- **Part 3 review by the author.** Chapters 17 to 22 were written to the
  Chapter 13 standard and pass all three checks (2026-09-15), without the first
  two checkpoints (see DECISIONS.md). None has been read by the author yet.
- **Part 2 review by the author.** Every Part 2 chapter now meets the Chapter 13
  standard and passes all three checks (2026-09-14). Chapter 13 was approved;
  Chapters 9 to 12 and 14 to 16 were reworked without the first two checkpoints
  (see DECISIONS.md) and have not yet been read by the author.
- **Transcripts that do not match a fresh run**, found by
  `tools/verify_transcripts.py`: Chapters 7 and 8 have two each.
- **Chapters 1 to 3 have no generator script**, so their transcripts cannot be
  verified at all. Every chapter must pass every check before release.
- **Parts 0 and 1 against the new standard.** Not yet reviewed for the chapter
  order, question lists, or option coverage. Decide with the author how much of
  the standard applies to chapters about concepts rather than one command.

## Out of scope

Continuous integration. GitHub Actions, GitLab CI and their relatives are large
enough to need their own book and none of them is Git. The parts of GitHub and
GitLab that are Git wearing a web interface are in Part 7.

## Cross-references already committed to the text

Written chapters refer forward to the numbers below. Changing a number means
editing every chapter in the left column.

| Chapter | Refers to |
|---|---|
| 1 | Appendix A, Appendix B, Appendix E, Appendix G, Appendix H, Chapter 2 |
| 2 | Chapter 3, Chapter 12, Chapter 17, Chapter 40, Chapter 61, Chapter 62 |
| 3 | Chapter 13, Chapter 17, Chapter 23, Chapter 26, Chapter 40, Chapter 41, Chapter 42, Chapter 43, Chapter 56, Chapter 66 |
| 4 | Chapter 13, Chapter 15, Chapter 29, Chapter 33, Chapter 37, Chapter 57, Chapter 71, Chapter 72, Chapter 75 |
| 5 | Chapter 11, Chapter 26, Chapter 73, Chapter 78, Chapter 79 |
| 6 | Chapter 4, Chapter 12, Chapter 18, Chapter 27, Chapter 28, Chapter 29, Chapter 33, Chapter 37, Chapter 41, Chapter 47, Chapter 77, Chapter 79 |
| 7 | Chapter 18, Chapter 22, Chapter 30, Chapter 36, Chapter 70 |
| 8 | Chapter 16, Chapter 37, Chapter 60 |
| 9 | Chapter 3, Chapter 4, Chapter 5, Chapter 6, Chapter 7, Chapter 14, Chapter 15, Chapter 16, Chapter 23, Chapter 40, Chapter 41, Chapter 43, Chapter 44, Chapter 46, Chapter 50, Chapter 56, Chapter 57, Chapter 60, Chapter 61, Chapter 62, Chapter 66, Chapter 67, Chapter 71, Chapter 72, Chapter 77, Chapter 81 |
| 10 | Chapter 5, Chapter 7, Chapter 8, Chapter 9, Chapter 11, Chapter 12, Chapter 13, Chapter 14, Chapter 16, Chapter 17, Chapter 18, Chapter 20, Chapter 23, Chapter 26, Chapter 41, Chapter 42, Chapter 43, Chapter 45, Chapter 55, Chapter 57, Chapter 60, Chapter 62, Chapter 69, Chapter 75, Chapter 80 |
| 11 | Chapter 5, Chapter 8, Chapter 9, Chapter 10, Chapter 12, Chapter 13, Chapter 14, Chapter 15, Chapter 16, Chapter 18, Chapter 30, Chapter 55, Chapter 57, Chapter 60, Chapter 62, Chapter 63, Chapter 65, Chapter 66, Chapter 75 |
| 12 | Chapter 2, Chapter 3, Chapter 4, Chapter 5, Chapter 6, Chapter 7, Chapter 10, Chapter 11, Chapter 17, Chapter 18, Chapter 26, Chapter 28, Chapter 30, Chapter 35, Chapter 36, Chapter 43, Chapter 53, Chapter 55, Chapter 61, Chapter 62, Chapter 67, Chapter 68, Chapter 75 |
| 13 | Chapter 4, Chapter 5, Chapter 10, Chapter 11, Chapter 17, Chapter 18, Chapter 21, Chapter 26, Chapter 30, Chapter 35, Chapter 57, Chapter 61, Chapter 62, Chapter 63, Chapter 65, Chapter 66, Chapter 67, Chapter 75, Chapter 76 |
| 14 | Chapter 10, Chapter 11, Chapter 17, Chapter 18, Chapter 26, Chapter 30, Chapter 31, Chapter 33, Chapter 57, Chapter 60, Chapter 73, Chapter 76, Chapter 78 |
| 15 | Chapter 4, Chapter 5, Chapter 8, Chapter 11, Chapter 13, Chapter 14, Chapter 17, Chapter 30, Chapter 37, Chapter 57, Chapter 60, Chapter 75 |
| 16 | Chapter 4, Chapter 8, Chapter 10, Chapter 11, Chapter 14, Chapter 37 |
| 17 | Chapter 2, Chapter 4, Chapter 6, Chapter 7, Chapter 9, Chapter 12, Chapter 13, Chapter 18, Chapter 19, Chapter 20, Chapter 21, Chapter 22, Chapter 26, Chapter 27, Chapter 36, Chapter 38, Chapter 41, Chapter 47, Chapter 53, Chapter 56, Chapter 61, Chapter 62, Chapter 64, Chapter 68, Chapter 75 |
| 18 | Chapter 5, Chapter 6, Chapter 7, Chapter 9, Chapter 13, Chapter 14, Chapter 17, Chapter 22, Chapter 24, Chapter 26, Chapter 32, Chapter 36, Chapter 41, Chapter 43, Chapter 50, Chapter 75 |
| 19 | Chapter 13, Chapter 17, Chapter 18, Chapter 21, Chapter 22, Chapter 62 |
| 20 | Chapter 6, Chapter 17, Chapter 18, Chapter 19, Chapter 21, Chapter 22, Chapter 24 |
| 21 | Chapter 11, Chapter 13, Chapter 17, Chapter 18, Chapter 19, Chapter 20, Chapter 22, Chapter 23, Chapter 36, Chapter 57, Chapter 65, Chapter 77 |
| 22 | Chapter 6, Chapter 7, Chapter 9, Chapter 17, Chapter 18, Chapter 19, Chapter 20, Chapter 23, Chapter 30, Chapter 32, Chapter 41, Chapter 46, Chapter 47, Chapter 56, Chapter 57, Chapter 60, Chapter 62, Chapter 68, Chapter 71, Chapter 72, Chapter 73, Chapter 74, Chapter 75, Chapter 81 |
| 23 | Chapter 3, Chapter 7, Chapter 10, Chapter 17, Chapter 18, Chapter 22, Chapter 24, Chapter 25, Chapter 30, Chapter 32, Chapter 36, Chapter 41, Chapter 42, Chapter 43, Chapter 47, Chapter 56, Chapter 57, Chapter 61, Chapter 62, Chapter 74, Chapter 77, Chapter 79 |
| 24 | Chapter 7, Chapter 9, Chapter 10, Chapter 11, Chapter 14, Chapter 16, Chapter 18, Chapter 19, Chapter 20, Chapter 23, Chapter 26, Chapter 30, Chapter 36, Chapter 47, Chapter 55, Chapter 56, Chapter 57, Chapter 60, Chapter 62, Chapter 77 |
| 25 | Chapter 6, Chapter 12, Chapter 13, Chapter 17, Chapter 18, Chapter 23, Chapter 24, Chapter 26, Chapter 27, Chapter 30, Chapter 31, Chapter 32, Chapter 33, Chapter 42, Chapter 55, Chapter 62, Chapter 67, Chapter 68, Chapter 76 |
| 26 | Chapter 3, Chapter 4, Chapter 5, Chapter 10, Chapter 11, Chapter 12, Chapter 13, Chapter 14, Chapter 17, Chapter 18, Chapter 24, Chapter 25, Chapter 27, Chapter 32, Chapter 33, Chapter 55, Chapter 62, Chapter 65, Chapter 77 |

Do not maintain that table by hand. Regenerate it, and check that nothing
points at a chapter that does not exist:

```sh
python tools/check_refs.py --map          # report, and list who refers to what
python tools/check_refs.py --write-table  # rewrite the table above
```
