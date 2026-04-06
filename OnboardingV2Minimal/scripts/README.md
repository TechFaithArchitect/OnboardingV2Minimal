# Scripts Directory (Who, When, Safety)

This folder holds **developer and operator** utilities. Nothing here replaces normal **Salesforce DX** (`sf deploy`, `sf apex run test`) unless your team’s runbook says otherwise.

**New here?** Use [doc-metrics](./doc-metrics.js) and **`scripts/apex/backfill_*.apex`** only when an admin runbook tells you to. Avoid ad-hoc **seed** and **delete** scripts in production without a ticket.

## Safe for many developers

| Path             | Purpose                                                                                                                           |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `doc-metrics.js` | Prints counts (flows, Apex, CMDT, objects) for documentation. Run: `npm run doc:metrics` from the DX project root. **Read-only.** |

## Deploy helpers (`deploy/`)

Shell wrappers around **`sf`** (or legacy **`sfdx`**) for CI or local habits. **Review** each script before running; they assume an org **alias**.

| Script                                                | Typical use                                 |
| ----------------------------------------------------- | ------------------------------------------- |
| `deploy.sh`, `deploy-phase1.sh`, `validate.sh`        | Validate or deploy metadata to a named org. |
| `run-tests.sh`, `run-main-tests.sh`, `post-deploy.sh` | Post-deploy or test batches.                |
| `run-best-practices-in-scope-tests.sh`                | Targeted Apex suite documented in `docs/technical/best-practices-findings.md`; `npm run test:apex:hardening`. |

## Apex one-offs (`apex/`)

| Script                                                | Purpose                                                                                                    |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `backfill_account_vendor_program_onboarding.apex`     | Data backfill for **AVO** rows; referenced from [Deployment Runbook](../docs/admin/DEPLOYMENT_RUNBOOK.md). |
| `backfill_frontier_welcome_template_assignments.apex` | Template assignment backfill (environment-specific).                                                       |
| `m2m_backfill_all_records.apex`                       | Many-to-many / junction maintenance—**confirm scope** before run.                                          |
| `delete_training_for_onboarding.apex`                 | **Destructive** training cleanup—sandbox or controlled use only unless runbook says otherwise.             |
| `debug-onb-status-eval.apex`                          | **Debugging** status evaluation—do not run in prod without guardrails.                                     |
| `hello.apex`                                          | Smoke test that Apex execution works.                                                                      |

## Simulation (`simulation/`)

| Path                                                     | Purpose                                                                                      |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `configurable-org-happy-path.md`                         | Describes a **happy-path** scenario for org configuration.                                   |
| `run-configurable-org-happy-path.sh`, `*.json`, `*.tmpl` | **Optional** automation to exercise onboarding in a controlled org. Read the markdown first. |
| `account-onboarding-through-opportunity.apex` + shell    | Scripted **scenario** run.                                                                   |

## Automation audits (`automation/`)

Bash scripts that **scan** flows, CMDT, or Apex for naming/convention issues. Safe to run locally; they do **not** change Salesforce data.

Examples: `audit-flow-fault-*.sh`, `check-cmdt-alias-drift.sh`, `build-*-map.sh`, `audit-permission-set-high-risk.js` (`npm run audit:permissions:highrisk`).

## Sample / seed (`sample-data/`, root `seed*.apex`)

**Template or environment bootstrap** Apex. Treat as **data migration**: wrong target org can create duplicate or wrong program data. Your org may forbid running these in prod.

## Other

| Path                                | Purpose                                                                    |
| ----------------------------------- | -------------------------------------------------------------------------- |
| `analyze-object-field-alignment.py` | Offline analysis of object/field alignment (no API calls unless extended). |
| `soql/account.soql`                 | Example SOQL for developers.                                               |

## Where this is documented for readers

- [Developer Guide](../docs/developer/DEVELOPER_GUIDE.md) (tooling entry point)
- [docs/README.md](../docs/README.md) (`doc:metrics`)
