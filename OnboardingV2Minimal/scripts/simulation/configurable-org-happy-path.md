# Configurable Org Happy-Path Simulation

This runner validates onboarding happy-path behavior using **existing org data** (for vendor program and requirement selection), then executes flow automation and verifies results with configurable SOQL assertions.

## Files

- `run-configurable-org-happy-path.sh` - main scenario runner
- `templates/run-org-happy-path.apex.tmpl` - Apex execution template
- `scenarios/org-happy-path.json` - default scenario config

## What It Does

1. Reads scenario JSON.
2. Resolves vendor program and requirement from org data (or uses IDs you provide).
3. Executes:
   - `DOMAIN_OmniSObject_SFL_CREATE_Opportunity`
   - `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record`
4. Validates built-in expectations:
   - onboarding completion flag
   - minimum requirement count
   - minimum subject count
   - selected requirement propagation (optional)
5. Runs post-run assertions from scenario SOQL queries.

## Run

From repo root:

```bash
scripts/simulation/run-configurable-org-happy-path.sh --org OnboardV2
```

Or with make:

```bash
make simulate-org-happy-path ORG_ALIAS=OnboardV2
```

Use a custom scenario file:

```bash
scripts/simulation/run-configurable-org-happy-path.sh --org OnboardV2 --config scripts/simulation/scenarios/org-happy-path.json
```

## Scenario Config

Path: `scripts/simulation/scenarios/org-happy-path.json`

Main sections:

- `selection`:
  - SOQL used to discover org records when explicit IDs are not supplied
- `inputs`:
  - optional explicit IDs (`accountId`, `vendorProgramId`, `requirementId`)
  - opportunity inputs (`opportunityStageName`, `closeDateOffsetDays`, `programBaseSelection`, `programType`)
- `expectations`:
  - core pass/fail checks enforced in Apex
- `assertions`:
  - post-run SOQL assertions enforced in shell

## Token Replacement

You can use these tokens in `selection.requirementSoql`, assertion `soql`, and assertion `expected` values:

- `{{vendorProgramId}}`
- `{{requirementId}}`
- `{{requirementType}}`
- `{{accountId}}`
- `{{opportunityId}}`
- `{{onboardingId}}`

## Assertion Operators

Supported operators:

- `eq`
- `ne`
- `gt`
- `gte`
- `lt`
- `lte`
- `contains`
- `not_contains`

`actualField` options:

- Field API name from first returned row
- `__totalSize__` to assert query row count
- Omit to use the first non-`attributes` field in the first row

## Notes

- Runner creates a new account when `inputs.accountId` is null.
- Vendor program and requirement are resolved from org data by default.
- Use sandbox/scratch orgs for repeated simulation runs.
