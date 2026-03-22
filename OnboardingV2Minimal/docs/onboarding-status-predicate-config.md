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
| `allRequirementsTerminal` | — | When **`Vendor_Program_Requirement__c`** defines active, **required** rows for the onboarding’s **`Vendor_Customization__c`**, for each such **requirement type** that has at least one **`Onboarding_Requirement__c`** row, **every** row of that type must have a **normalized** terminal status: Setup Complete, Ignore, Signed, or Complete. **Template types with zero onboarding rows are skipped**. If **no** template type matches any row (picklist / `Requirement_Type__c` mismatch between VPR and onboarding rows), the engine **falls back** to “**every** onboarding requirement row is terminal” so misaligned metadata does not block **Setup Complete** forever. If there is no qualifying program template (no vendor program, or no active required rows), **every** onboarding requirement row must be terminal. |
| `notAllRequirementsTerminal` | — | Negation of above. |
| `anyRequirementCanceledWithStageGate` | — | Any normalized Canceled/Cancelled on a requirement row, **and** either there is **no** linked Opportunity on context or the linked Opportunity’s stage is Canceled / Cancelled / Closed Lost. Avoids forcing **Canceled** onboarding while the deal is still open. |
| `onlyRequirementTypeNormalizedInSet` | `requirementType`, `allowedNormalized` (array) | Rows of that type share one normalized value in the allowed set; other types only Ignore/empty. |
| `agreementAndContractCompleteOthersIgnored` | — | Agreement Signed or Setup Complete, contract Complete or Setup Complete. Other requirement rows must be Ignore/empty **only if** their type is on the program template (same scoping as `allRequirementsTerminal`); off-template rows are ignored. |
| `agreementSignedContractNotStartedOthersIgnored` | — | Every **Agreement** row normalized Signed or Setup Complete; every **Contract** row normalized **Draft**, **New**, **Not Started**, or **In Approval Process** (after CMDT normalization, or raw picklist value when no CMDT row). Other requirement types are ignored. Requires at least one Agreement and one Contract row. |
| `assignedTeamEquals` | `team` | `Onboarding__c.Assigned_Team__c` equals `team` (case-insensitive). |
| `opportunityStageCanceled` | — | Linked Opportunity’s stage is Canceled / Cancelled / Closed Lost. Used with bundled rule **OPPORTUNITY_CANCELED** so onboarding can move to **Canceled** when the deal is lost even before requirement rows catch up (and works with **Denied** / other rules reordering when statuses change). |

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

**Pending Initial Review (Agreement signed, Contract in early milestone; other types ignored)**

```json
{"op":"agreementSignedContractNotStartedOthersIgnored"}
```

Contract requirement `Status__c` is often **Draft** (default on create) or **New** before flows set **Not Started** / **In Approval Process**; those states count as “pre-review” for **Pending Initial Review**. Keep the row aligned with the linked **Contract** via automation; the evaluator does not read `Contract.Status` directly.

## Troubleshooting (“why isn’t my status what I expect?”)

1. **First match wins** — Rules are evaluated in ascending **`Rule_Order__c`**. A higher-priority rule (e.g. **Denied**, **Setup Complete** if every *template* requirement is terminal) matches before **Pending Initial Review** (order **50**) or **In Process** default (order **80**).
2. **Setup Complete uses the vendor program template** — `allRequirementsTerminal` checks **active, required** **`Vendor_Program_Requirement__c`** types: for each type that **has** onboarding rows, those rows must be terminal. Types on the template with **no** onboarding row are **skipped** (so stray template lines do not block completion). If you need a type to **always** gate completion, ensure your create flows always insert that **`Onboarding_Requirement__c`** row for the program.
3. **See which rule won** — Call **`OnboardingStatusEvaluatorInvocable`** with **Apply Updates = false** and read **`Matched Rule Developer Name`** and **`Matched Rule Order`** on the result (or inspect Apex **`EvaluationResult`**). If you see **`IN_PROCESS_DEFAULT`** / order **80**, no earlier rule’s predicate was true (often: Contract row missing from context, wrong **Requirement_Type__c** text, or Contract normalized status outside Draft/New/Not Started/In Approval Process).
4. **Requirement rows must load** — Evaluation loads all child **`Onboarding_Requirement__c`** rows for the onboarding (same idea as program-template SOQL: automation should not get a partial set).

## Adding a new rule shape

1. Prefer composing existing `op` values with `all` / `any`.
2. If a **new** semantic is required, add a **single** new branch in **`OnboardingStatusPredicateInterpreter.evaluateOp`** (one place), document it here, and ship CMDT rows using the new `op`.

## Normalization

Normalized values come only from **`Onboarding_Status_Normalization__mdt`** via **`OnboardingStatusNormalizationService`**. Do not duplicate normalization in BRE for this path (see ADR-001).
