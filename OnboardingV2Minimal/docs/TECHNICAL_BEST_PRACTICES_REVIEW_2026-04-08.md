# Technical Best Practices Review (Code-Focused) — Onboarding V2

Purpose
- This document captures a code-focused review of the current implementation against Salesforce engineering best practices. It complements, but differs from, the existing “best-practices” documentation by:
  - Referencing concrete code patterns and files in this repository.
  - Providing prescriptive, actionable remediations with code snippets.
  - Calling out security, performance, and operational risks discovered during the review.
- It is intended for engineers performing day-to-day development and code review, not for general administrators.

Scope
- Focused on Apex, Flow integration patterns, LWC server interfaces, and security controls in:
  - force-app/main/default/classes/ObjectRelatedListController.cls
  - force-app/main/default/classes/RecordCollectionEditorConfigService.cls
- Findings are representative; apply the same standards repo-wide.

Summary of Strengths
- Security-by-default
  - Uses WITH SECURITY_ENFORCED on dynamic SOQL.
  - Enforces isAccessible/isCreateable/isUpdateable checks before field access and DML.
  - DML executed with AccessLevel.USER_MODE in user-initiated paths.
  - Classes generally use “with sharing”.
- Dynamic SOQL hardening
  - Strict API name validation and relationship traversal checks prevent injection.
- Flow/LWC compatibility
  - Clear separation of domain vs unexpected errors via ExceptionUtil for user-safe messaging.
  - Invocable request/response DTOs return structured results and error lists (flow-friendly).
- Bulk and governor awareness
  - Batched Database.insert/update calls with SaveResult aggregation and no DML-in-loops.

High-Priority Recommendations

1) Enforce input and transaction-size caps on JSON-driven operations
File(s): RecordCollectionEditorConfigService.cls
- Risk: A Flow or LWC could send hundreds/thousands of records/fields, causing CPU/heap timeouts.
- Action:
  - Add ceilings and reject with a user-friendly message.
  - Track cumulative limits and short-circuit when nearing limits.

Suggested pattern:
private static final Integer MAX_RECORDS_PER_REQUEST = 200;
private static final Integer MAX_REL_RECORDS = 500;
private static final Integer MAX_FIELDS_PER_RECORD = 150;

if (rawRecords.size() > MAX_RECORDS_PER_REQUEST) {
  singleResult.errorMessages.add('Too many records in a single request. Limit is ' + MAX_RECORDS_PER_REQUEST + '.');
  results.add(singleResult);
  continue;
}

// Guard near governor limits (example thresholds; tune as needed)
if (Limits.getCpuTime() > 9000 || Limits.getHeapSize() > 5_000_000) {
  singleResult.errorMessages.add('Request is too large to process. Submit fewer records.');
  results.add(singleResult);
  continue;
}

2) Harden ORDER BY control to curb performance regressions
File(s): ObjectRelatedListController.cls
- Risk: Arbitrary order fields can degrade selectivity or cause slow queries.
- Action:
  - Introduce a safe allowlist or CMDT-configured set per object, default deny.

Example:
private static final Set<String> SAFE_ORDER_FIELDS = new Set<String>{ 'Name', 'CreatedDate', 'LastModifiedDate' };
...
if (String.isNotBlank(config.orderByField) && SAFE_ORDER_FIELDS.contains(config.orderByField)) {
  // build ORDER BY
} else if (String.isNotBlank(config.orderByField)) {
  throw new OnboardingDomainException('Unsupported orderBy field: ' + config.orderByField);
}

3) Add duplicate-proofing for relationship inserts
File(s): RecordCollectionEditorConfigService.cls
- Risk: Parallel transactions may still insert duplicates despite the pre-query.
- Action:
  - Add a “last-chance” select-before-insert or handle DUPLICATE_VALUE SaveResults by skipping and logging a specific message.
  - Where feasible, prefer a unique external Id on the relationship object (e.g., parentId-childId composite).

Handle DML error:
for (Database.Error err : relInsertResults[j].getErrors()) {
  if (err.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
    // Skip; treat as idempotent success
  } else {
    singleResult.errorMessages.add('Relationship: ' + err.getMessage());
  }
}

4) Cache field describes within the transaction
File(s): RecordCollectionEditorConfigService.cls (convertRelationshipFieldValue), ObjectRelatedListController.cls
- Risk: Repeated describe calls add CPU overhead.
- Action:
  - Add a static Map<String, Map<String, Schema.SObjectField>> describeCache keyed by SObject API name.
  - Pass precomputed maps down to helpers.

Pattern:
private static Map<String, Map<String, Schema.SObjectField>> DESCRIBE_CACHE = new Map<String, Map<String, Schema.SObjectField>>();
private static Map<String, Schema.SObjectField> getDescribeFieldMapCached(Schema.SObjectType st) {
  String key = st.getDescribe().getName();
  if (!DESCRIBE_CACHE.containsKey(key)) {
    DESCRIBE_CACHE.put(key, st.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap());
  }
  return DESCRIBE_CACHE.get(key);
}

5) Formalize deprecation for getProgramDates
File(s): ObjectRelatedListController.cls
- Action:
  - Add @Deprecated annotation where supported; if not supported in target org, keep `@deprecated` docblock + runtime warning and track migration.
  - Keep a test asserting the method returns expected records via the generic path.

// Use @Deprecated where platform/compiler supports it.
// In this org, use the @deprecated docblock + runtime warning path.
@AuraEnabled(cacheable=true)
public static List<Program_Dates__c> getProgramDates(Id accountId) { ... }

6) Standardize security posture repo-wide
File(s): Many (pattern audit)
- Action:
  - Ensure all dynamic SOQL includes WITH SECURITY_ENFORCED.
  - Ensure all field reads/writes check isAccessible/isCreateable/isUpdateable.
  - Prefer USER_MODE DML for user workflows; document rationale for SYSTEM_MODE uses.
  - PMD rules: enable ApexCRUDViolation, ApexUnitTestShouldNotUseSeeAllData, AvoidDmlStatementsInLoops, AvoidSoqlInLoops, OperationWithLimitsInLoop, Security rules.

CI and Tooling Recommendations
- PMD: Expand pmd-ruleset.xml to include the security and bulkification rules above; fail build on violations.
- Pre-commit hooks: Add sf scanner or pmd via Makefile, plus ESLint/Jest for LWC.
- Test coverage: Maintain factory-based test data and negative-path tests for:
  - Permission denied paths (FeatureManagement.checkPermission false).
  - Invalid field names/paths rejected by validators.
  - Large-payload rejection (new caps).

Operational Playbook Additions
- When adding a new Flow/LWC path that calls Apex:
  - Decide USER_MODE vs SYSTEM_MODE based on business need.
  - Register fields in CMDT or safe lists if exposed via dynamic queries.
  - Add unit tests for unauthorized access to ensure graceful user messaging.
- When adding relationship types:
  - Add unique key strategy (External Id or composite natural key).
  - Add duplicate handling logic as per section 3.

Quick Review Checklist (for PRs)
- Security
  - [ ] WITH SECURITY_ENFORCED on SELECT
  - [ ] isAccessible/isCreateable/isUpdateable checks
  - [ ] with sharing (or explicit without sharing with justification)
  - [ ] USER_MODE vs SYSTEM_MODE rationale documented
- Bulk/Performance
  - [ ] No SOQL/DML in loops
  - [ ] Caps on record/field counts for JSON-driven endpoints
  - [ ] Describe caching or reuse
- Stability
  - [ ] Clear domain vs unexpected exception handling
  - [ ] Idempotent relationship upserts (duplicate-safe)
- API Contracts
  - [ ] DTOs and error messages Flow/LWC-friendly
  - [ ] Deprecated paths annotated and migration tracked

Execution Status (OnboardV2, 2026-04-08 implementation)
- Security
  - [x] WITH SECURITY_ENFORCED on SELECT
  - [x] isAccessible/isCreateable/isUpdateable checks
  - [x] with sharing (or explicit without sharing with justification)
  - [x] USER_MODE vs SYSTEM_MODE rationale documented
- Bulk/Performance
  - [x] No SOQL/DML in loops
  - [x] Caps on record/field counts for JSON-driven endpoints
  - [x] Describe caching or reuse
- Stability
  - [x] Clear domain vs unexpected exception handling
  - [x] Idempotent relationship upserts (duplicate-safe)
- API Contracts
  - [x] DTOs and error messages Flow/LWC-friendly
  - [x] Deprecated path migration tracked (`getProgramDates` wrapper retained, runtime deprecation warning added, parity test maintained)
  - [x] Note: Apex `@Deprecated` annotation on this method is not supported by the target org compiler for this class type; docblock deprecation marker is used instead.

UI Follow-up Status (OnboardV2, 2026-04-08 post-implementation)
- [x] Removed fixed polling from `onboardingCompletionProgress`; refresh now occurs on scoped related-list change events and manual refresh action.
- [x] Added scoped browser-event contract (`objectrelatedlistchange`) from `objectRelatedList` save/create/delete to refresh dependent UI (progress bar) without full page reload.
- [x] Improved inline-save perceived responsiveness in `objectRelatedList` by applying draft values to visible rows immediately, then reconciling with background refresh.

Appendix: Observed Good Patterns
- Field path validation using Schema and API name regex to prevent injection.
- Structured invocable results with error list aggregation instead of throwing in flows.
- Relationship pre-query and hashing to prevent duplicates.

Change Log
- Created by: Engineering review, 2026-04-08
- Updated by: implementation pass, 2026-04-08 (OnboardV2 status + deprecation exception note)
- Updated by: UI refresh/responsiveness follow-up, 2026-04-08 (event-driven progress updates, no polling, optimistic row merge on inline save)
- Next review: Quarterly or upon major feature changes.
