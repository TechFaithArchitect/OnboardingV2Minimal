# Deployment Runbook

## Preconditions

- Gearset pipeline configured for this repository
- Required permission sets and metadata dependencies included
- Test strategy defined for changed automation paths
- Backout plan identified for high-risk changes

## Gearset Pipeline Model

Primary deployment path is Gearset, not direct CLI deploy.

Use these companion docs:

- Gearset include baseline: [GEARSET_INCLUDE_LIST.md](./GEARSET_INCLUDE_LIST.md)
- UAT deactivation targets from org comparison: [UAT_FLOW_DEACTIVATION_CANDIDATES.md](./UAT_FLOW_DEACTIVATION_CANDIDATES.md)

## Recommended Deploy Sequence

1. Validate source formatting/lint/tests locally.
2. Build Gearset comparison against target pipeline stage.
3. Confirm include/exclude set using the Gearset include baseline.
4. Apply planned flow deactivations in target stage where required.
5. Deploy through Gearset.
6. Run targeted Apex tests and smoke tests.
7. Promote through remaining pipeline stages.

## Core Commands

The following commands are for local validation and diagnostics:

```bash
sf org list
sf config get target-org
sf project deploy start --target-org <alias> --source-dir force-app
sf apex run test --target-org <alias> --test-level RunLocalTests
```

For scoped deploys:

```bash
sf project deploy start --target-org <alias> --source-dir force-app/main/default/flows
sf project deploy start --target-org <alias> --source-dir force-app/main/default/classes
```

## Post-Deploy Validation Checklist

- Confirm key flows are Active and latest version is deployed.
- Confirm planned UAT deactivation candidates are deactivated where applicable.
- Run onboarding creation smoke path from sales screen flow.
- Validate requirement expansion and subject creation.
- Validate evidence update path updates subject and parent requirement status.
- Validate onboarding status evaluator updates lifecycle correctly.
- Confirm fault handler still logs expected errors into `Error_Log__c`.


## Rollback Strategy

- Redeploy previous known-good metadata package.
- If data side effects occurred, run data correction scripts before re-enabling automation.
- Document rollback trigger conditions and incident details.
