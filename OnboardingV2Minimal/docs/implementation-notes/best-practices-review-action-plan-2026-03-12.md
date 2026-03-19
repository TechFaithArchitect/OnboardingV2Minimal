# Best-Practices Review Action Plan (2026-03-12)

This document is now the index for the split best-practices review workspace.

## Working Files
- `docs/implementation-notes/best-practices-review-2026-03-12/checklist.md`
- `docs/implementation-notes/best-practices-review-2026-03-12/execution-log.md`
- `docs/implementation-notes/best-practices-review-2026-03-12/in-progress.md`
- `docs/implementation-notes/best-practices-review-2026-03-12/full-original.md` (source plan)
- `docs/implementation-notes/best-practices-review-2026-03-12/README.md`

## Current State
- Targeted `P0` focal-chain flow remediation is complete and evaluated.
- Agreement subject-status/CMDT alignment has been deployed (`Signed` subject mapping + `Agreement/Paperwork Sent` normalization).
- Next priority remains `P1` CMDT normalization and drift prevention.

## Update Workflow
1. Update source content in `docs/implementation-notes/best-practices-review-2026-03-12/full-original.md`.
2. Regenerate split views with `make refresh-best-practices-docs`.
3. Review generated outputs (`checklist.md`, `execution-log.md`, `in-progress.md`) for accuracy.
4. Only update this index when file locations or process changes.
