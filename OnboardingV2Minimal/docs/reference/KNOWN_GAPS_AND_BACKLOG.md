# Known Gaps and Backlog

## High Priority

- Add validation hardening for single-owner business constraints in relationship data where required.
- Complete consolidation of overlapping requirement subject evaluation orchestration paths.
- Expand explicit operational dashboards for `Error_Log__c` and chain progress events.

## Medium Priority

- Expand automated test coverage for:
- negative flow fault scenarios
- bulk update fan-out scenarios
- permission-set constrained execution paths
- Continue reducing legacy references and historical fallback behavior after data cleanup scripts are available.

## Architecture Backlog

- Evaluate additional decomposition of large screen flow segments where complexity is concentrated.
- Continue migration of repeated logic blocks into domain subflows or invocable services.
- Standardize naming and retirement process for legacy/inactive flow definitions.

## Documentation Backlog

- Add screenshots and click-path maps for key screen flows.
- Add persona-specific quick-reference cards for support teams.
- Add environment-specific release checklists if multiple delivery tracks are used.

## Operational Backlog

- Add alert routing for repeated fault categories by subtype.
- Define SLOs for onboarding cycle-time and error resolution.
- Add periodic metadata drift audit between sandbox and production.
