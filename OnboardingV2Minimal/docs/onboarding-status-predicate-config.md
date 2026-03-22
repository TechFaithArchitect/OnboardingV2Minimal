# Onboarding status evaluation — `Predicate_Config__c` (JSON)

Rules live on **`Onboarding_Status_Evaluation_Rule__mdt`**. Field **`Predicate_Config__c`** holds JSON evaluated by **`OnboardingStatusPredicateInterpreter`**. **`Rule_Order__c`** is ascending; **first matching** active rule wins. Targets come from the same row.

**`Predicate_Config__c` is required for a rule to match.** Blank or invalid JSON logs a warning/error and the rule is skipped. Optional **`Condition_Type__c`** is for labels or future admin UI only—not evaluated.

## Document structure

- **Composite AND:** `{ "all": [ <node>, ... ] }` — every child must be true.
- **Composite OR:** `{ "any": [ <node>, ... ] }` — at least one child true.
- **Leaf:** `{ "op": "<operator>", ...parameters }`

## Operators (`op`)

| `op` | Parameters | Meaning |
|------|----------------|--------|
| `reqAnyNormalizedEquals` | `normalized` | Any requirement’s normalized status equals value (case-insensitive). |
| `notReqAnyNormalizedEquals` | `normalized` | Negation of above. |
| `allRequirementsTerminal` | — | Every requirement normalized is one of: Setup Complete, Ignore, Signed, Complete. |
| `notAllRequirementsTerminal` | — | Negation of above. |
| `anyRequirementCanceledWithStageGate` | — | Any normalized Canceled/Cancelled, and opportunity null or canceled/lost stage. |
| `onlyRequirementTypeNormalizedInSet` | `requirementType`, `allowedNormalized` (array) | Rows of that type share one normalized value in the allowed set; other types only Ignore/empty. |
| `agreementAndContractCompleteOthersIgnored` | — | Agreement Signed or Setup Complete, contract Complete or Setup Complete, other types only Ignore/empty. |
| `assignedTeamEquals` | `team` | `Onboarding__c.Assigned_Team__c` equals `team` (case-insensitive). |
| `opportunityStageCanceled` | — | Opportunity stage is Canceled / Cancelled / Closed Lost. |

## Examples

**Any denied**

```json
{"op":"reqAnyNormalizedEquals","normalized":"Denied"}
```

**In process default**

```json
{"all":[
  {"op":"notReqAnyNormalizedEquals","normalized":"Denied"},
  {"op":"notAllRequirementsTerminal"}
]}
```

**Pending sales**

```json
{"all":[
  {"op":"notReqAnyNormalizedEquals","normalized":"Denied"},
  {"op":"notAllRequirementsTerminal"},
  {"op":"assignedTeamEquals","team":"Sales"}
]}
```

## Adding a new rule shape

1. Prefer composing existing `op` values with `all` / `any`.
2. If a **new** semantic is required, add a **single** new branch in **`OnboardingStatusPredicateInterpreter.evaluateOp`** (one place), document it here, and ship CMDT rows using the new `op`.

## Normalization

Normalized values come only from **`Onboarding_Status_Normalization__mdt`** via **`OnboardingStatusNormalizationService`**. Do not duplicate normalization in BRE for this path (see ADR-001).
