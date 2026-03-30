# Test and Quality

## Current Testing Footprint

- Apex classes: 131
- Apex test classes: 39
- Test factory classes: 27
- LWC Jest configured via `@salesforce/sfdx-lwc-jest`

## Existing Quality Tooling

From `package.json`:

- `npm run lint`
- `npm run test:unit`
- `npm run test:unit:coverage`
- `npm run prettier:verify`

## Recommended Validation Sequence

1. Prettier verification
2. ESLint for LWC/Aura JavaScript
3. LWC unit tests
4. Apex tests in target org for touched areas
5. Flow-level integration checks for critical paths

## Critical Regression Areas

- Opportunity create screen flow and deferred onboarding tail behavior
- Requirement subject expansion and evaluation
- Parent requirement roll-up and status fallback handling
- Onboarding status evaluator rule ordering and predicate outcomes
- Communication dispatch recipient resolution paths
- Error logging and fault-handler paths

## Bulk and Idempotency Focus

Areas already designed for bulk/idempotent behavior and should retain coverage:

- `OnbReqParentBulkEvalInvocable`
- `OnboardingRequirementSubjectInvocable` (unique-key skip behavior)
- Training assignment sync flows that process both single and collection onboarding contexts

## Exit Criteria for High-Risk Changes

- No unhandled flow faults in smoke test scenarios
- No status regression for onboarding lifecycle rules
- No duplicate requirement subject rows for repeated or retried runs
- No permission regression for onboarding operational permission sets
