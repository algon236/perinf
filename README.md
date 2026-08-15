# Personal Work and Information System

PerInf 1.0 is an Org-backed personal information and work-management system
for Emacs. It keeps ordinary Org files as the source of truth while providing
a unified interface for tasks, meetings, people, decisions, documents,
transcripts, and human-approved minutes.

## Highlights

- controlled task and meeting workflows, including work-time tracking
- separate archive sections for completed and cancelled records
- links from meeting evidence through minutes and decisions to resulting tasks
- managed audio and document imports with checksums and stable identifiers
- explicit human review and approval of generated minutes
- interfaces in English, Danish, French, German, and Spanish

Transcription and text generation are intentionally kept outside the core.
Plugins may create artifacts, but PerInf records their provenance and requires
human approval before minutes become final.

## Getting started

Add the repository to Emacs' `load-path`, then evaluate:

```elisp
(require 'perinf)
```

Start PerInf with `M-x perinf`. From the start page, create a new project or
open an existing one. Projects remain normal, portable Org directories.

## Development and packaging

```text
make test
make compile
make package
```

`make package` creates `dist/perinf-1.0.0.tar`, which can be installed with
`M-x package-install-file`.

## License

PerInf is free software licensed under GNU GPL version 3 or any later version.
See [LICENSE](LICENSE).
