# Personal Information System

Personal Information System is an Org-backed work management core for tasks, meetings, people,
transcripts, and human-approved minutes.

This repository contains the first executable bootstrap:

- English source code and language-independent data keys
- interface locale data for English, Danish, French, German, and Spanish
- initial object, property, status, and project metadata registries
- a storage API boundary in front of persistent Org files
- a minimal `M-x perinf` start page
- a meeting evidence chain from managed audio and immutable raw transcript to
  externally generated draft minutes, human review, submission, and explicit
  human final approval

The core deliberately does not call a transcription or text-generation
service. Such integrations belong in a separate plugin project. The core
imports their artifacts, records source and content checksums, and keeps the
human submission and approval decisions in the Org data. Draft minutes open as
ordinary Org files for review; submission recalculates the content checksum,
and final approval is unavailable until that review step is complete. A final
reviewer can reject the submission with a required reason; submission,
rejection, resubmission, and approval are appended as review events instead of
replacing the earlier audit trail. Final approval verifies that the current
minutes content still matches the checksum recorded at submission; changed
content must be rejected and submitted again. The approved checksum is stored
separately with the human approval. The minutes detail view presents the
chronological review history with localized event names, project date and time
formats, actors, and rejection reasons. Minutes awaiting final approval also
appear in the Work view with direct open, approve, and reject actions. The
Records view lists stored people, raw transcripts, and minutes as clickable
Org-backed records with their current statuses. Title search covers tasks,
meetings, people, transcripts, and minutes; transcript and minutes titles
include the related meeting title so results remain distinguishable. The Home
overview counts raw transcripts, minutes, and pending final approvals; those
counts link to Records or Work.

Meetings use controlled lifecycle transitions from `planned` to `in-progress`
and then `held`; a planned meeting may also be marked as held directly,
postponed, or cancelled. A postponed meeting can return to planned status or
be cancelled. The core records actual start and finish timestamps and rejects
repeated, terminal, or otherwise invalid transitions.

Decisions are first-class Org records with a stable ID, normalized decision
date, optional rationale, localized creation workflow, Records listing, detail
view, and title search. A decision can be registered directly from
final-approved minutes; its Org properties retain both the source meeting ID
and source minutes ID, and the decision detail links back to both records.

Decisions can create sourced tasks. The task retains the decision ID and, when
present on the decision, the originating meeting and minutes IDs. Task details
link back to the source decision, preserving the chain from meeting evidence
through approval and decision to action. Decision details provide the inverse
view by listing every task originating from the decision, with task status and
a link to the task.

Tasks can be assigned or reassigned to a registered person. Assignment stores
the person’s stable ID; Work shows the responsible person, and task details
link back to the person record. Person details provide the inverse view: all
tasks currently assigned to that person, with status and links to each task.
The same person detail also lists meetings in which the person is registered,
including meeting date, participant role, meeting status, and a link back to
the meeting.

Tasks use a controlled workflow from open to active, waiting, completed, or
cancelled. Active and waiting tasks can move between operational states;
completed and cancelled tasks can be reopened. Cancelled tasks are terminal
for overview and overdue counts until reopened.

Open tasks whose normalized deadline is before the current local date are
marked overdue in Work. Home counts overdue tasks and links that count to Work;
completed tasks are excluded from the overdue calculation.
Work orders tasks by operational urgency: overdue first, then open tasks by
nearest deadline, then open tasks without deadlines, and completed tasks last.

Contexts are first-class Org records with stable IDs, optional descriptions,
localized creation, Records listing, detail view, and title search.
Tasks can be placed in or moved between contexts. Work and task details show
the context, while context details provide the inverse list of related tasks.

Meeting participants have controlled attendance states: invited, attended,
absent, or excused. Meeting details show role and localized attendance and
provide direct actions for recording the final attendance state.
Person meeting history includes the same localized attendance state alongside
the person’s role and the meeting status.

Meeting details show decisions and tasks carrying that meeting’s stable ID,
with links to each object and task status. This makes the evidence-to-action
chain navigable forward from the meeting as well as backward from each record.
The minutes detail provides the corresponding source-specific view: it lists
the decisions and tasks carrying that minutes record’s stable ID, including
links and task status.

## Run the bootstrap

Add this directory to Emacs’ load path, evaluate:

```elisp
(require 'perinf)
```

and run:

```text
M-x perinf
```

The start page can create a project, or use:

```text
M-x perinf-create-project
```

To reopen an existing project:

```text
M-x perinf-open-project
```

To open the included example project:

```elisp
(perinf-core-open
 (expand-file-name "examples/minimal-project" perinf-source-directory))
```

The last example assumes `perinf-source-directory` points at this repository.

## Tests

```text
make test
make compile
```

## Build an installable Emacs package

```text
make package
```

This creates `dist/perinf-0.1.0.tar`. Install it from Emacs with:

```text
M-x package-install-file
```

## License

Personal Information System is free software licensed under GNU GPL version 3 or any later version.
See `LICENSE`.
