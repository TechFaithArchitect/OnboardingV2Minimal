# Test and Quality

## What “Good” Looks Like

- Users can create onboarding records without flow failures.
- Requirements and subjects are created once (no duplicate fan-out).
- Status moves correctly when evidence changes.
- No new unexplained `Error_Log__c` spikes after release.

## Current testing footprint (from source)

Numbers change as classes are added or removed. **Authoritative totals** for the checkout in front of you:

```bash
npm run doc:metrics
```

Recent baseline (example output shape):

- **Total** `.cls` files in `force-app/main/default/classes`
- **`*Test.cls`** name pattern count (common “test class” file name)
- **`Test*Factory*.cls`** pattern count (test data helpers)

Richer taxonomy (production vs test categories, invocable counts): [Apex Class Inventory](../developer/APEX_CLASS_INVENTORY.md).

**LWC:** Jest is configured via `@salesforce/sfdx-lwc-jest` in `package.json` (`npm run test:unit`).

| LWC bundle | Apex / wires exercised in tests | Test file |
| --- | --- | --- |
| `expCreateRecord` | `ExpOpportunityCreateRecord.loadContext` (imperative; success + error paths) | `force-app/test/lwc/expCreateRecord.test.js` |
| `recordCollectionEditor` | `RecordCollectionEditorConfigService.getConfig` (`@wire`; missing key + error) | `force-app/test/lwc/recordCollectionEditor.test.js` |
| `objectRelatedList` | `ObjectRelatedListController.getRelatedRecords`, LDS picklist / record wires | `force-app/test/lwc/objectRelatedList.test.js` |
| `programDatesRelatedList` | `ObjectRelatedListController.getRelatedRecords` (Program Dates config), LDS | `force-app/test/lwc/programDatesRelatedList.test.js` |
| `programDatesQuickAction` | `getLookupOptions` | `force-app/test/lwc/programDatesQuickAction.test.js` |

**Supporting mock:** `jest.config.js` maps `lightning/flowSupport` for screen-flow components under Jest (`force-app/test/jest-mocks/lightning/flowSupport.js`).

## Existing Quality Tooling

From `package.json`:

- `npm run lint`
- `npm run test:unit`
- `npm run test:unit:coverage`
- `npm run prettier:verify`
- `npm run pmd:apex` (production classes)
- `npm run pmd:apex:test` (test hygiene: `ApexUnitTestShouldNotUseSeeAllData`)
- `npm run audit:apex:security` (inventory report for dynamic SOQL + DML mode posture)

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
