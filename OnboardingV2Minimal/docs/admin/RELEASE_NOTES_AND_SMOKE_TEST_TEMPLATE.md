# Release Notes and Smoke-Test Template

Use this template for **each** promotion (sandbox → UAT → production) alongside the [Deployment Runbook](./DEPLOYMENT_RUNBOOK.md). It ties **what changed** to **what to verify** so onboarding regressions are caught early.

## How To Fill This Quickly

1. Fill release header first.
2. Write stakeholder summary in plain business terms.
3. Check changed technical areas.
4. Run smoke tests and mark pass/fail with notes.
5. Capture sign-off names/dates before promoting further.

## Release header

| Field                                       | Value |
| ------------------------------------------- | ----- |
| **Release name / ticket**                   |       |
| **Source (branch / tag)**                   |       |
| **Target org**                              |       |
| **Deployed by / date**                      |       |
| **Gearset comparison ID or link** (if used) |       |

## Summary for stakeholders (non-technical)

2–4 sentences: user-visible behavior, programs affected, any planned downtime.

## Technical changes (check all that apply)

- [ ] Flows (list API names or link to ticket)
- [ ] Apex
- [ ] Custom objects / fields
- [ ] Custom metadata (CMDT) — types: \_\_\_
- [ ] Permission sets
- [ ] Integrations / named credentials (see [Environment matrix](../technical/ENVIRONMENT_AND_INTEGRATIONS_MATRIX.md))
- [ ] Documentation updates (link PR or commits)

## Risk and rollback

| Risk | Mitigation | Rollback trigger |
| ---- | ---------- | ---------------- |
|      |            |                  |

Rollback: follow [Deployment Runbook — Rollback strategy](./DEPLOYMENT_RUNBOOK.md#rollback-strategy).

## Smoke tests (baseline)

Complete after deploy. Aligned with [Baseline setup guide](../BASELINE_SETUP_GUIDE.md).

| #   | Test                                                                                                                                 | Expected                                                | Pass / fail | Notes |
| --- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------- | ----------- | ----- |
| 1   | Critical **BLL** flows **Active** (per [deployment post-deploy checklist](./DEPLOYMENT_RUNBOOK.md#post-deploy-validation-checklist)) | As listed in runbook                                    |             |       |
| 2   | Run **onboarding create** screen flow on a test opportunity                                                                          | Onboarding + requirements created (allow async delay)   |             |       |
| 3   | One **requirement** evidence update path                                                                                             | Subject / parent status moves as expected               |             |       |
| 4   | **Error_Log\_\_c** spot check                                                                                                        | No new unexplained spike Provider `OnboardingV2`        |             |       |
| 5   | Optional: one **communication** event in UAT                                                                                         | Template resolves; send or intentional block documented |             |       |

## Smoke tests (extensions)

Add rows only if this release touched these areas; see [FAQ — Admins](../support/FAQ_ADMINS.md) for meaning.

| #   | Area                   | Test                                                        | Pass / fail |
| --- | ---------------------- | ----------------------------------------------------------- | ----------- |
|     | Approval gate          | Approve onboarding; deferred **VPR** rows create            |             |
|     | Program-specific comms | **Vendor_Program_Key\_\_c** matches normalized program Name |             |
|     | LearnUpon / Adobe      | One contract or enrollment path                             |             |

## Sign-off

| Role         | Name | Date |
| ------------ | ---- | ---- |
| Deployer     |      |      |
| QA / product |      |      |
