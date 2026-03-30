# Business User Guide

## Who This Is For

- Onboarding specialists
- Compliance operators
- Account services users
- Customer service users supporting onboarding cases

## Daily Operating Workflow

### Review New/Active Onboarding Records

- Open `Onboarding__c` record page.
- Confirm linked account, opportunity, contract, and vendor program context.
- Validate `Onboarding_Status__c` and assigned team context.

### Review Requirements

- Open related `Onboarding_Requirement__c` rows.
- Verify status and completed flags align to current evidence.
- Escalate unexpected regressions to admin/support with record links.

### Review Requirement Subjects

- Inspect `Onboarding_Requirement_Subject__c` rows for responsibility and subject status.
- Confirm subject expansion reflects policy expectation for the vendor program requirement.
- If responsibility looks incorrect, verify fulfillment policy and contact role data.

### Work Exceptions

- Use `Error_Log__c` references for technical failure escalation when needed.

## Understanding Status Changes

Status changes are rule-driven, not manually sequenced by users. Status reflects:

- normalized requirement evidence
- rule order precedence
- targeted outcome from the first matching active rule

If status seems wrong, capture:

- onboarding id
- current onboarding status
- key requirement statuses
- relevant error log id (if present)

## Escalation Data Checklist

Provide the following in escalation tickets:

- Onboarding record id
- Requirement and subject ids affected
- Expected status versus actual status
- Timestamp of issue
- Error Log Id (if available)
- Recent user action path (screen flow or record update)
