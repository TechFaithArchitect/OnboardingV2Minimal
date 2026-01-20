# Twilio & Messaging UI Plan

## Goals
- Enable configurable SMS provider setup (Twilio vs Salesforce Messaging) without code deployments.
- Improve admin/operator UX for work queue triage and messaging issue resolution.
- Add safety nets (validation + tests) to prevent broken SMS sends and UI regressions.

## Current Gaps
- Twilio config is only in metadata; no UI to edit Active/From Number/Named Credential/Account SID or to map rules/templates to providers.
- Provider config passed to `TwilioSMSProvider` omits `accountSid`/`namedCredential`, so Twilio sends always fail.
- Follow-up rules default to Twilio when no messaging channel is set; no `SMS_Provider__c` field to override.
- No custom metadata records seeded for `Twilio_Configuration__mdt`, so from-number validation fails in runtime.
- UI gaps: work queue lacks filters/paging/legends and responsive states; messaging issues panel lacks navigation, pagination, action disabling during async, and no-results state.
- Front-end tests missing for key surfaces (`onboardingWorkQueue`, `messagingIssuesPanel`) and Twilio provider flow.

## Work Plan (prioritized)
1) **Configuration Model**
   - Add fields to `Follow_Up_Rule__mdt` (or templates if preferred): `SMS_Provider__c` (picklist), `Twilio_From_Phone__c` (phone), `Twilio_Account_SID__c` (text), `Twilio_Named_Credential__c` (text).
   - Seed `customMetadata/Twilio_Configuration__mdt.*` with an active record: `From_Phone_Number__c`, `Named_Credential__c`, `Account_SID__c` (if stored there), `Active__c=true`.
   - Migration/validation: add a preflight script or validation rule to ensure one active record and required fields are populated before enabling Twilio.
2) **Service Logic Fixes**
   - `determineSMSProvider`: prefer `SMS_Provider__c`, else fallback on Messaging Channel presence.
   - `buildProviderConfig`: surface `fromPhone` (rule/template first, then active Twilio config), `accountSid` (rule/template or Twilio config), and `namedCredential` (rule/template or Twilio config). Remove dead TODOs.
   - Validation: return precise messages when required Twilio fields are missing; fail fast before callout. Make Salesforce Messaging path no-op when provider is Twilio.
3) **Admin UI**
   - New LWC + flexipage to view/edit Twilio settings: list active/inactive configs, edit from-number, account SID, named credential, active toggle, and default provider choice.
   - Add contextual help text, inline validation, and optimistic save with toast feedback. Honor FLS/CRUD and handle running user without Twilio access.
   - Optional: expose rule-level provider selector in the same page (lookup to `Follow_Up_Rule__mdt`) for quicker overrides.
4) **Operator UI Enhancements**
   - `onboardingWorkQueue`: add filters (status/blocked/age), sorting/paging or virtual scroll, row badges/legend for blocked/at-risk, actionable empty/loading states, and responsive layout tweaks for tablet/mobile.
   - `messagingIssuesPanel`: add record navigation links, inline detail drawer (attempt history, last error), disable Retry/Dismiss during async, pagination/lazy load, no-results state, and row-level status feedback (e.g., pill/badge).
5) **Testing**
   - Jest: cover new admin settings LWC and enhanced `onboardingWorkQueue`/`messagingIssuesPanel` for loading/error/empty states, filter changes, and action handling.
   - Apex: tests for provider selection, Twilio config validation, and happy-path callout using `HttpCalloutMock`; ensure graceful failure when config missing.

## Risks & Assumptions
- Assumes Twilio Named Credential already exists (`Twilio_API` or configured name) with SID/Auth Token.
- If Account SID must remain in Named Credential username, we need a way to read it or require explicit entry in metadata.
- Deployment sequencing: new metadata fields + seed records must deploy before code that relies on them.

## Open Questions
- Where should provider preference live long-term: rule-level, template-level, or global default?
- Can we read Account SID from the Named Credential securely, or must admins re-enter it in metadata?
- Should operators be able to override provider per message/queue item, or is it fixed by rule? 
