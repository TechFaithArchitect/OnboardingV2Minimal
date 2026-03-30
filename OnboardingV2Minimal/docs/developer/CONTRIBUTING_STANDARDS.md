# Contributing Standards

## Design Standards

- Keep automation deterministic and explicit.
- Prefer composable domain flows over duplicated logic blocks.
- Keep business policy in CMDT when feasible.
- Avoid adding new legacy fallback behavior unless explicitly required.

## Flow Standards

- Use naming conventions aligned with current architecture (`EXP`, `BLL`, `DOMAIN`, `DOM`).
- No SOQL/DML inside flow loops unless technically unavoidable and documented.
- Wire all faults to `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` (or approved equivalent).
- Use collection/bulk patterns when record-triggered changes can fan out.

## Apex Standards

- Bulk-safe by default.
- Enforce sharing and access checks appropriately.
- Keep invocable methods stable and explicit in input/output contracts.
- Prefer service classes over logic in controllers/invocables.

## Security Standards

- Do not introduce references to deprecated legacy fields.
- Validate permission impact for any new object/field access.
- Keep logging redaction-safe and avoid direct PII leaks in error text.

## Testing Standards

- Add or update Apex tests for logic changes.
- Add or update Jest tests for LWC behavior changes.
- Include negative-path and bulk-path coverage for orchestrators/evaluators.

## Documentation Standards

Any meaningful change must update relevant docs:

- architecture and automation docs for behavior changes
- business/sales/admin guides for user workflow changes
- backlog/reference docs for known residual gaps
