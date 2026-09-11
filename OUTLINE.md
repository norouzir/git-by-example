# Outline

The approved structure of the book. Agreed 2026-09-11, before writing started.

**Chapter numbers are stable and load-bearing.** The text cross-references
chapters by number, so a chapter keeps its number even if it is written out of
order. Inserting a chapter means appending it at the end of its part and
accepting a gap in reading order, or renumbering every reference in the book.
Prefer the former.

Status marks: `[x]` written, `[ ]` not yet.

## Part 0. Using This Book

- [x] 1. How to Read This Book
- [x] 2. The Sandbox
- [x] 3. Installing and Configuring Git

## Part 1. The Mental Model

- [ ] 4. What Git Actually Stores
- [ ] 5. The Three Areas: Working Tree, Index, Repository
- [ ] 6. The Four Object Types
- [ ] 7. Refs, HEAD, and Branches as Pointers
- [ ] 8. The Lifecycle of a File

## Part 2. Everyday Work

- [ ] 9. init and clone
- [ ] 10. status
- [ ] 11. add
- [ ] 12. commit
- [ ] 13. diff
- [ ] 14. Undoing Local Changes with restore
- [ ] 15. rm and mv
- [ ] 16. Ignoring Files

## Part 3. Reading History

- [ ] 17. log
- [ ] 18. Revision Syntax and show
- [ ] 19. blame
- [ ] 20. bisect
- [ ] 21. grep and Searching History
- [ ] 22. shortlog, describe, rev-list, rev-parse

## Part 4. Branching and Merging

- [ ] 23. branch
- [ ] 24. switch, checkout, and detached HEAD
- [ ] 25. merge
- [ ] 26. Conflicts
- [ ] 27. Merge Strategies and Options

## Part 5. Rewriting History

- [ ] 28. The Golden Rule of Rewriting
- [ ] 29. commit --amend
- [ ] 30. reset
- [ ] 31. revert
- [ ] 32. cherry-pick
- [ ] 33. rebase
- [ ] 34. Interactive Rebase
- [ ] 35. fixup, autosquash, and git history
- [ ] 36. reflog
- [ ] 37. Removing Files and Secrets from History
- [ ] 38. replace, notes, and grafts

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

## Out of scope

Continuous integration. GitHub Actions, GitLab CI and their relatives are large
enough to need their own book and none of them is Git. The parts of GitHub and
GitLab that are Git wearing a web interface are in Part 7.

## Cross-references already committed to the text

Written chapters refer forward to the numbers below. Changing a number means
editing every chapter in the left column.

| Chapter | Refers to |
|---|---|
| 1 | Appendices A, B, E, G, H |
| 2 | Chapters 3, 12, 17, 40, 61, 62 |
| 3 | Chapters 13, 17, 23, 26, 40, 41, 42, 43, 56, 66 |

Do not maintain that table by hand. Regenerate it, and check that nothing
points at a chapter that does not exist:

```sh
python tools/check_refs.py --map
```
