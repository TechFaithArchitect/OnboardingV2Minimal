# Metadata Drift Checklist

Use this on a recurring schedule (for example monthly per environment tier, or before major releases) to catch silent differences between orgs and source.

## Owner and frequency

| Role                        | Suggested cadence                                  |
| --------------------------- | -------------------------------------------------- |
| Release / DevOps            | Before production promotion; after hotfix restores |
| Salesforce admin / platform | Monthly on sandbox; quarterly documentation pass   |

## What to compare

1. **Source vs target org**
   - Compare against the same branch/tag you intend to deploy (Gearset comparison or `sf project deploy preview` / validation deploy as appropriate for your pipeline).
   - Confirm the comparison includes flows, Apex, CMDT, Custom Objects/fields, and permission sets relevant to onboarding.

2. **Sibling environments (sandbox vs sandbox, UAT vs staging)**
   - Run the same comparison or a saved Gearset filter.
   - Pay special attention to **active flow version** and **flow status** (Active vs Draft), not only presence of metadata.

3. **Operational toggles**
   - `Onboarding_Performance_Config__mdt` and other high-impact CMDT: confirm values match the intended stage (for example deferred tail on/off).
   - Communication policies and template assignments: confirm `Active__c` and program linkage match the documented model in [ADMIN_OPERATIONS_RUNBOOK.md](./ADMIN_OPERATIONS_RUNBOOK.md).

## Definition of “good”

- No unexpected differences in record-triggered flows that own onboarding, requirement, or sync behavior without a linked change ticket.
- CMDT row counts and developer-names for critical types match expectations, or differences are listed in release notes.
- Post-deploy checklist items in [DEPLOYMENT_RUNBOOK.md](./DEPLOYMENT_RUNBOOK.md) still pass in the target org.

## When drift is found

1. Classify: intentional (documented release), accidental (manual edit in org), or unknown.
2. For accidental org-only changes: retrieve or recreate in source, then redeploy; avoid leaving org-only “fix” unversioned.
3. Log outcome and update [KNOWN_GAPS_AND_BACKLOG.md](../reference/KNOWN_GAPS_AND_BACKLOG.md) only if the drift exposed a process gap.

## Related docs

- [Deployment Runbook](./DEPLOYMENT_RUNBOOK.md)
- [Admin Operations Runbook](./ADMIN_OPERATIONS_RUNBOOK.md)
- [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md)
