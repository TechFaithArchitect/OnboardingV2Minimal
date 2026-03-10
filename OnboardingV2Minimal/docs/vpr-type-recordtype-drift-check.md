# Vendor Program Requirement Type Drift Check

This check compares:

- `Vendor_Program_Requirement__c.Requirement_Type__c` distinct values (falls back to `Type__c` if needed)
- Active `Onboarding_Requirement__c` record type names

It reports drift when a requirement type has no matching active onboarding requirement record type.

## Script

`scripts/automation/check-vpr-type-recordtype-drift.sh`

## Usage

```bash
bash scripts/automation/check-vpr-type-recordtype-drift.sh OnboardV2 .analysis/automation-audit/nightly-vpr-type-drift-$(date +%F) true
```

Arguments:

1. target org alias/username (default: `OnboardV2`)
2. output directory (default: `.analysis/automation-audit/nightly-vpr-type-drift-YYYY-MM-DD`)
3. fail on drift (`true|false`, default: `true`)

Exit codes:

- `0`: no drift (or drift allowed via arg3=`false`)
- `2`: drift found and arg3=`true`
- `1`: query/runtime error

## Key outputs

- `vpr_type_recordtype_drift_summary.tsv`
- `vpr_types_missing_onboarding_recordtype.txt`
- `onboarding_recordtypes_without_vpr_usage.txt`
- `run_metadata.txt`
- `errors.log`

## Nightly scheduling example (cron)

```bash
0 2 * * * cd /Users/jasonmu/OnboardingV2Minimal/OnboardingV2Minimal && /bin/bash scripts/automation/check-vpr-type-recordtype-drift.sh OnboardV2 .analysis/automation-audit/nightly-vpr-type-drift-$(date +\%F) true >> .analysis/automation-audit/nightly-vpr-type-drift-cron.log 2>&1
```
