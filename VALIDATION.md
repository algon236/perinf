# Validation — 20 September 2026

## Saved statistics addition

- 65 ERT tests passed, including 12 statistics tests for independent month
  counts, immutable reports, previous/year-boundary comparisons, year switching,
  historical stock exclusion, memo subheadings, read-only archive browsing,
  missing sources, unsaved buffers and corrupt history.
- Fresh-process load checks and strict compilation passed.
- Activated in the running Emacs without restarting it; the Statistics menu,
  read-only report and first saved snapshot were verified. Current stock counts
  were checked against the source records. No file-backed buffers were modified.
- Reports are stored under the private project's statistics directory; no
  report snapshots or personal data are included in the source distribution.

## Earlier 1.0.2 validation

- 53 ERT tests passed, including default-agenda selection, explicit-project
  precedence, memo target, data storage, task clocks and existing regressions.
- All runtime Lisp files passed syntax checking and compilation with compiler
  warnings treated as errors.
- The Emacs TAR package installed into an isolated temporary package directory.
  Public command autoloads and UI activation passed in a fresh Emacs process.
- Full NXS startup and dashboard checks passed with the updated runtime package.
- Local Emacs daemon restarted successfully. Version 1.0.2, default project,
  current project, dashboard and memo target all resolved to the agenda tree.
- Local data migration copied and byte-verified 31 files and preserved 8 existing
  agenda files. The old data tree was retained outside this distribution.
- ZIP extracted successfully; the Python installer copied its runtime sources
  and refused existing destinations, including dangling symbolic links.
- ZIP and TAR checksums verified. Distribution excludes user data and state.

Test platform: macOS with GNU Emacs 32.0.50. Declared minimum dependencies are
Emacs 29.1 and Org 9.6; those minimum versions and Windows/Linux were not tested.
This is automated functional validation, not an exhaustive visual UI review.
