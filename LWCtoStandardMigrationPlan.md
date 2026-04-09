## Implementation Plan: Native Flow Refactor for `EXP_Opportunity_SCR_Create_Record`

### Summary
- Refactor the flow from one monolithic Screen LWC (`c:expCreateRecord`) to native Flow screens/components.
- Keep existing business/domain logic in Apex (hybrid approach), but move UI orchestration and step navigation into Flow.
- Use a single-release cutover for the flow, and deprecate old LWCs for one release before deletion.
- Replace both `recordCollectionEditor` and `vendorSelector` in this flow with native controls.

### Public Interfaces and Type Changes
- Add Apex-defined DTO types in a new class `ExpOppCreateFlowTypes.cls`:
- `VendorOptionRow`: `vendorId`, `vendorName`, `retailOption`, `businessVertical`, `displayLabel`.
- `ContactRow`: `contactId`, `firstName`, `middleName`, `lastName`, `title`, `email`, `phone`, `roles`, `startDate`, `isExisting`.
- `OcrRow`: `contactId`, `contactName`, `role`, `isPrimary`.
- Add 3 invocable action classes (one invocable method per class):
- `ExpOppCreateFlowLoadAction.cls` returns native-flow-ready payload (routing flags, defaults, vendor options, contact rows, OCR rows).
- `ExpOppCreateFlowSaveContactsAction.cls` accepts `ContactRow[]`, persists contacts/ACR, returns refreshed `ContactRow[]` and `OcrRow[]`.
- `ExpOppCreateFlowSubmitAction.cls` accepts final account/opportunity/`OcrRow[]`/vendor selections and submits create-chain.
- Keep `ExpOpportunityCreateRecord.cls` methods intact in release N for compatibility, but have new invocables call shared logic there (or extracted shared helpers) to avoid behavior drift.

### Implementation Changes
- Rebuild `EXP_Opportunity_SCR_Create_Record` (new active version) as 4 native screens plus action/decision nodes:
- Screen 1 `Account`: native input fields for Account name/phone/billing/shipping.
- Screen 2 `Opportunity`: native fields, path selector, vendor selector (native choice controls), and conditional visibility using existing routing variables.
- Screen 3 `Contacts`: editable native grid based on `ContactRow[]` (Apex-defined collection); allow add/remove/edit rows.
- Action `SaveContacts`: call `ExpOppCreateFlowSaveContactsAction`; if zero eligible signer rows returned, route to error/message screen then back to Contacts.
- Screen 4 `Opportunity Contact Roles`: editable native grid using `OcrRow[]`; enforce one primary + required role.
- Action `Submit`: call `ExpOppCreateFlowSubmitAction`; route to success or error message screen.
- Replace old→new behavior explicitly:
- `c:expCreateRecord` step state machine -> Flow screen sequence + Decisions + Assignment nodes.
- Custom banner/error markup -> Spring ’26 Message component with conditional visibility.
- `c:vendorSelector` JSON input/output -> native choice controls bound to `VendorOptionRow[]`.
- `c:recordCollectionEditor` JSON payloads -> Apex-defined collections (`ContactRow[]`, `OcrRow[]`) bound to native editable grid controls.
- Keep existing early flow routing calls (`Evaluate_OnboardingOrchestrator`, vendor option retrieval, onboarding flags) as upstream decision inputs; do not duplicate logic in screen formulas.
- Release-N cleanup:
- Remove all references to `c:expCreateRecord`, `c:vendorSelector`, `c:recordCollectionEditor` from this flow.
- Add `@deprecated` doc comments and release note annotations on those LWCs as “unused by active flow”.
- Release N+1 cleanup:
- Delete deprecated LWC bundles and obsolete Jest tests once post-release validation confirms no runtime references.

### Test Plan
- Apex unit tests:
- `ExpOppCreateFlowLoadActionTest`: routing flags, vendor option mapping, contact/OCR seed hydration, permission-sensitive branches.
- `ExpOppCreateFlowSaveContactsActionTest`: happy path, missing account, role constraint failures, no-signer outcome, error propagation format.
- `ExpOppCreateFlowSubmitActionTest`: active pipeline block, missing required docs-ready/path/vendor inputs, submit success, queue/chain failure messaging.
- Flow-level validation:
- Path variants: `OFFER_CHUZO_CREATE`, `PROMPT_PATH_SELECTION`, `REQUIRE_NDA`, vendor-only, blocked pipeline.
- Vendor required/not required conditional paths.
- Contacts with/without Principal Owner and Authorized Signer permission.
- OCR role editing, single primary enforcement, submit success/failure.
- Regression:
- Keep existing `ExpOpportunityCreateRecordTest` passing.
- Keep old LWC Jest tests passing during deprecation window (release N), then remove in N+1 with corresponding test cleanup PR.

### Assumptions and Defaults
- Target org/runtime includes Winter ’26 + Spring ’26 Flow features used here (Apex-defined collections in Data Table, editable Data Table runtime, Message component improvements).
- No object schema changes are required for v1 cutover.
- Cutover is single-release by activating the new flow version; rollback path is re-activating previous flow version.
- Existing business rule outcomes and submit-chain behavior must remain functionally identical to current production logic.
