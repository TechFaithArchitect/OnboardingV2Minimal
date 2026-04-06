# How to Read Legacy `reports/` Markdown (optional, local)

The **`reports/`** directory is **gitignored**. It was used for **generated or semi-generated** markdown that compared **documentation** to **metadata** (dependency snapshots, “docs vs class” coverage style lists). Nothing in `reports/` is required to **deploy** the Salesforce app.

If you still generate those files locally, treat them as **point-in-time engineering deltas**, not user-facing documentation.

## Principles

1. **Dependency inventories** list references from docs or metadata to objects and integrations. Use them to find stale doc links or missing objects after a retrieve—not as a behavior spec.
2. **“Coverage” style reports** compare doc mentions to what exists in source. A gap usually means “doc not updated yet” or “internal-only metadata,” not necessarily a prod bug.
3. Prefer **in-repo sources of truth** for ongoing work: [FLOW_CATALOG.md](../developer/FLOW_CATALOG.md), [APEX_CLASS_INVENTORY.md](../developer/APEX_CLASS_INVENTORY.md), [OBJECT_CATALOG.md](../technical/OBJECT_CATALOG.md), and `npm run doc:metrics` (see [scripts/doc-metrics.js](../../scripts/doc-metrics.js)).

## Operational hardening (tracked)

For security/tooling status and npm automation, use **[best-practices-findings.md](../technical/best-practices-findings.md)** under `docs/technical/`.
