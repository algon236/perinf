# Personal Work and Information System

PerInf 1.0.2 is an Org-backed personal information and work-management system
for Emacs.

It can be used as an alternative to, or a supplement for, Org Agenda. It keeps
ordinary Org files as the source of truth while providing
a unified interface for tasks, meetings, people, decisions, documents,
transcripts, and human-approved minutes.

## Highlights

- controlled task and meeting workflows, including persistent work timers
- a dedicated people view with editable contacts and reusable groups
- separate archive sections for completed and cancelled records
- links from meeting evidence through minutes and decisions to resulting tasks
- managed audio and document imports with checksums and stable identifiers
- explicit human review and approval of generated minutes
- interfaces in English, Danish, French, German, and Spanish

Groups are selection aids rather than references of their own. Selecting a
group for a task or meeting records its current members as individual, stable
person references. Later membership changes therefore never rewrite historical
tasks or meetings. People and groups are archived instead of permanently
deleted and can be reactivated later.

Transcription and text generation are intentionally kept outside the core.
Plugins may create artifacts, but PerInf records their provenance and requires
human approval before minutes become final.

## Saved statistics reports

Choose **Statistics** or run `M-x perinf-statistics`. The first opening saves
a report for the current year; subsequent openings display the latest saved
report. **Ny rapport** saves a new report, **Skift år** selects a year, and
**Gamle rapporter** opens an unchanged earlier report. Report text and these
controls currently use Danish.

Each project stores immutable `report.org` and `snapshot.json` pairs below
`statistics/YEAR/unique-report/`. Include this directory in private backups,
not in the public package repository. Stock counts compare with the previous
report and the last available measurement before January 1, with actual dates
shown. Missing baselines remain unavailable. On the first run of a new year,
the pre-year measurement also serves as the previous report. Year activity
uses creation, closure and scheduled meeting dates, with monthly breakdowns.

Selecting a historical year without a saved report reconstructs activity from
surviving records and explicitly omits historical stock counts. Corrections,
deletions and backfills may affect new calculations, never saved reports.
Timer totals are not treated as monthly work logs. Unsaved source buffers and
corrupt report archives prevent creation rather than silently producing a
misleading comparison. Nothing runs automatically in the background.

## Work timers and recorded activity

Each running clock appears as a boxed line in the PerInf main buffer, with a
project abbreviation, task title, and total recorded time. The lines update every
five seconds, including while the buffer is hidden. Killing that buffer stops its
clocks and saves their elapsed time; hiding it with `q` does not. PerInf reuses one
main buffer: when switching projects, clocks from previously displayed projects
remain attached to that buffer until stopped or the buffer is killed. The normal
inactivity timeout still applies.

Enable automatic activity tracking and inactivity checks explicitly:

```elisp
(perinf-task-activity-mode 1)
```

With a source checkout, first load `perinf` or the generated autoloads.
You can also use `M-x perinf-task-activity-mode`.
Disabling the mode removes its hooks and periodic check. Saved buffer
associations and running task timers remain unchanged; those timers must
then be stopped manually. Enabling again restores associations in open
buffers and resumes checks using the saved last-activity timestamps.


Each active task can have its own work timer, and several task timers may run
at the same time. PerInf stores both accumulated work time and the start of the
current interval, so elapsed time survives Emacs restarts and remains available
after a task is completed or cancelled. Work time is displayed as `H:MM:SS`.
The **Reset timer** action clears the accumulated time without completing the
task; if the timer is running, it continues from zero.

An open Emacs buffer or file can be associated with one active task. File paths
and names of non-file buffers are stored with the task. Once a file has been
associated, PerInf recognizes it automatically when it is opened again. While
the task timer is running, activity in that buffer updates the task's **last
recorded activity** at most once per minute. PerInf deliberately does not infer
which task unrelated keyboard or mouse activity belongs to.

Use the **Associate open buffer or file** action in a task's detail view, or run
`M-x perinf-associate-buffer-with-task` from the work buffer. Starting a timer
with `M-x perinf-start-task-timer` from a work buffer associates that buffer
automatically. Use `M-x perinf-dissociate-buffer-from-task` to remove the
association.

PerInf checks running timers once per minute. A timer is stopped automatically
after 15 minutes without recorded activity, independently of other running
timers. The work interval ends exactly at the 15-minute boundary, and Emacs
shows a minibuffer message naming the task that was stopped. For a running
timer created before activity tracking was available, the timer start time is
used as the fallback activity time.

## Portable distribution

The default project directory is `~/org/agenda/`. An explicitly selected project
or saved last project takes precedence. Existing project data is never included
in the distribution. See `README.da.md` for the Danish installation guide.

Install the source with `python3 install.py` (refuses an existing destination),
or install `dist/perinf-1.0.2.tar` with `M-x package-install-file`.
The ZIP includes source, documentation, tests and build tools.

For a fresh project, create `~/org` first, run `M-x perinf-create-project`, and
accept `~/org/agenda/`. Project creation refuses an existing directory; an existing
agenda directory must be preserved and handled separately. Installing this
package does not migrate existing personal data automatically.

## Getting started

For a local source installation under `~/.emacs.d/lisp/perinf/`, run:

```sh
make install
```

The installer creates missing directories and generates autoloads. It derives
its destination from Emacs' `user-emacs-directory`; set
`PERINF_EMACS_DIRECTORY=/path/to/emacs-directory` to override it. Add to init:

```elisp
(add-to-list 'load-path (expand-file-name "lisp/perinf/" user-emacs-directory))
(load "perinf-autoloads" nil t)
```

Start with `M-x perinf`. Create or open a project from the home page.
Projects remain normal, portable Org directories, separate from installed code.
The package itself never creates installation directories or modifies load-path.
The local installer is responsible for placement under `lisp/`.

Danish is the default before a project is opened. Project metadata selects its
saved language. To keep a Danish UI regardless of a project's language, add:

```elisp
(setq perinf-interface-language 'da
      perinf-interface-language-override 'da)
```

Set the override to nil to follow project metadata. English, French, German and
Spanish remain available. Newly translated validation errors have Danish and
English versions; the other languages use English fallback for these messages.
Canonical Org properties, IDs and stored content are not translated.

For development, adding this repository root to `load-path` and requiring
`perinf` is sufficient. All runtime Lisp modules are in the root directory.

## Development and packaging

```sh
make test
make compile
make package
```

Compilation uses a temporary copy and treats compiler warnings as errors.
`make package` creates `dist/perinf-1.0.2.tar`, installable with
`M-x package-install-file`. Normal package.el installations use
`package-user-dir` (usually `~/.emacs.d/elpa/`), independently of the local
source installer. Never install both versions on the same load-path.

`recipes/perinf` is a proposed MELPA recipe for the dedicated upstream
repository. The source changes must be published there before a MELPA
submission; inclusion is subject to MELPA review.

## Org integration and boundaries

Emacs 29.1 and Org 9.6 are the declared minimum dependencies. Tests for this
release were run with Emacs 32.0.50; Emacs 31 was not independently exercised.
PerInf does not require doct or org-roam and does not replace capture templates
or configure the org-roam database. Internal Org parsing suppresses user mode
hooks and uses the canonical TODO/DONE keywords. Opening a real Org file still
uses the user's normal Org setup.

Writes refuse to overwrite a file visited in a buffer with unsaved changes.
Existing file permission bits are preserved. Individual file replacements are
atomic, but operations touching several files are not database transactions;
concurrent writers in separate Emacs processes are not coordinated.
The existing `localized-long` project setting accepts ISO date input.

## License

PerInf is free software licensed under GNU GPL version 3 or any later version.
See [LICENSE](LICENSE).

## Memos

Choose Memo on the PerInf home page, select a date (optionally including a
time), write the note, and finish with `C-c C-c`
(or cancel with `C-c C-k`). Show memos opens the current project’s
`data/memos.org`. Each entry stores `CATEGORY: Husk`, an ID, and a
creation timestamp, plus a standard Org SCHEDULED date. The category remains the same in every interface language
so later statistics can group entries reliably. No deadline or task status is
required. `M-x perinf-capture-memo` opens the same capture flow.

Open a memo from the dashboard and use **Close and save** above the note to
mark it done, save it, and close its window. The note and category remain in
the Org file for later statistics.
