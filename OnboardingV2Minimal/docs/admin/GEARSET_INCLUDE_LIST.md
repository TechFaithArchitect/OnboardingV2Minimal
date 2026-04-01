# Gearset Include List

## Purpose

This is the metadata include baseline for deploying this repository through a Gearset pipeline.

## Quick Rule

If you are unsure whether to include a metadata type, include it when the release changes behavior users can feel (flows, classes, CMDT, objects/fields, permission sets).  
If a type is unrelated to your ticket, keep it out to reduce deployment risk.

## Include Metadata Types

Use this as the default include set from `force-app/main/default`:

- `applications`
- `approvalProcesses`
- `aura`
- `classes`
- `contentassets`
- `customMetadata`
- `customPermissions`
- `decisionMatrixDefinition`
- `decisionMatrixVersion`
- `decisionTables`
- `duplicateRules`
- `email`
- `expressionSetDefinition`
- `flexipages`
- `flowDefinitions`
- `flows`
- `globalValueSets`
- `labels`
- `layouts`
- `lwc`
- `matchingRules`
- `objects`
- `pages`
- `permissionsets`
- `quickActions`
- `staticresources`
- `tabs`
- `triggers`
- `workflows`

## Mandatory Include Notes

- Include `customMetadata` when deploying any behavior that is rule/policy driven.
- Include `objects` whenever flow/Apex changes depend on object/field-level metadata.
- Include `permissionsets` whenever new fields/objects/invocables are introduced.

## Typical Exclude Candidates

These are frequently excluded unless intentionally part of the release scope:

- large static assets not changed for this release
- unrelated decision matrix artifacts not referenced in changed automation

## Validation Checklist Before Promote

- Compare package against active branch and confirm no unintended metadata types were pulled in.
- Confirm flow activation/deactivation intent is explicit.
- Confirm permission-set changes align with security plan.
- Confirm CMDT records required by changed automation are present in package.
