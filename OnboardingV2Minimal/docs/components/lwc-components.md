# LWC Components

This list reflects the MVP onboarding experience. Wizard/process framework
components are grouped under **Legacy/Remove**.

## Core Entry Points
- `accountProgramOnboardingModal` - Quick action to start onboarding from an Account (program selection, contacts, opportunity).
- `onboardingHomeDashboard` - Main dashboard for onboarding reps and sales.

## Home Dashboard Composition
- `onboardingFilterChips` - Time/vendor/program/view filters.
- `onboardingKpiRow` - KPI tiles row used by the dashboard.
- `onboardingWorkQueue` - Queue list for active onboarding items.
- `onboardingVendorProgramGrid` - Vendor program table in the dashboard.
- `onboardingInsights` - Optional insights panel.
- `onboardingAtRiskPanel` - At-risk onboarding list.
- `onboardingRecentActivity` - Activity stream widget.
- `onboardingAdminToolsPanel` - Admin shortcuts (optional).
- `onboardingDealerOnboardingModal` - Modal used by "Start Dealer Onboarding."
- `messagingIssuesPanel` - Follow-up queue issues summary.

## Onboarding Records
- `onboardingRequirementsPanel` - Requirement list and status editor for a single Onboarding.
- `requirementChecklist` - Checklist-style requirement view.
- `requirementFormPanel` - Requirement detail editor.
- `requirementConditionsList` - Requirement conditions UI (if enabled).
- `onboardingOrderStatusViewer` - Order/training status summary (optional).
- `onboardingResumePanel` - Resume panel for in-progress onboarding.

## Status Rules Engine (Admin)
- `onboardingStatusRulesManager` - Status rules manager shell.
- `onboardingStatusRulesEngine` - Rules engine selector/editor.
- `onboardingStatusRuleList` - Status rule list.
- `onboardingStatusRuleForm` - Create/edit status rules.
- `onboardingRuleModal` - Modal wrapper for rule edits.
- `statusEvaluationPreviewModal` - Preview status evaluation.

## External Credentials & Training
- `onboardingECC` - External contact credential detail view.
- `onboardingAppVendorProgramECCManager` - Admin UI for credential types/requirements.

## Messaging & Admin
- `onboardingAdminDashboard` - Admin dashboard shell.
- `onboardingAppHeaderBar` - Shared header/navigation bar.
- `nextBestActionsPanel` - Suggested actions panel.
- `repDealerQueue` - Rep queue panel.
- `overrideAuditPanel` - Override audit log UI.
- `messagingIssuesTab` - Full issues list view (optional).
- `adobeSyncFailuresTab` - Adobe sync failures view (optional).
- `twilioSettings` - Twilio configuration UI.

## Utilities
- `utils` - Shared helpers used by multiple LWCs.
