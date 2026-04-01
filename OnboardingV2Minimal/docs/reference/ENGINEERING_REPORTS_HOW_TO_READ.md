# How to Read the `reports/` Markdown Files

The [reports](../../reports/) folder holds **generated or semi-generated** markdown that compares **documentation** to **metadata** (or lists dependencies). It is aimed at **engineers and release owners**, not day-to-day business users.

## Why these reports exist

They answer maintenance questions such as:

- Does the **Flow catalog** mention every flow that exists in `force-app`?
- Are there **classes** or **triggers** in the repo with **no** doc reference?
- Which **objects** appear in dependency graphs or “missing from org” snapshots?

## How to read a typical file

1. **Open with your editor’s markdown preview**—tables are easier to scan.
2. **Check the file name:**
   - `docs-*-coverage.md` — items **in** metadata **and** referenced in docs (or the inverse for `*-removal`).
   - `dependency-missing-*.md` — dependency graph found a reference to something **not** in the package.
   - `object-dependency-inventory.md` — broad map of relationships.
3. **Treat counts as a snapshot** — they go stale after refactors. Re-run the generating script if your team has one (see headers inside individual reports when present).

## When should a new team member care?

- **Onboarding a developer:** skim **`docs-class-coverage.md`** and **`docs-metadata-coverage.md`** once to learn how “complete” written catalogs are.
- **Before a big delete:** use **`docs-*-removal.md`** and dependency reports to avoid removing still-referenced symbols.
- **If docs seem wrong:** these files help find **drift**, not replace human judgment.

## Entry points (also linked from [docs README](../README.md))

- [Object dependency inventory](../../reports/object-dependency-inventory.md)
- [Docs vs metadata coverage](../../reports/docs-metadata-coverage.md)
- [Docs vs class coverage](../../reports/docs-class-coverage.md)
- [Dependency missing objects summary](../../reports/dependency-missing-objects-summary.md)
