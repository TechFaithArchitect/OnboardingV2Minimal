# Account Onboarding Quick Action (Dealer/Program Onboarding Linkage)

## Purpose
Single-modal Account quick action that:
- Enforces Account Contact Roles before onboarding.
- Gates Vendor Program selection based on NDA + Program Base Application eligibility (PerfectVision fallback).
- Creates Opportunity, Opportunity Contact Roles, Onboarding__c (with seeded Onboarding_Requirement__c from Vendor Program Requirements), and Account_Vendor_Program_Onboarding__c (AVO) in one flow.

See [User Journey Summary](../user-guides/user-journey-summary.md) for the end-to-end flow.

## User Flow (Modal)
1) Eligibility banner loads (NDA + Program Base Application check). If not eligible, only PerfectVision programs are returned.
2) Vendor Program search/pick (uses `searchVendorProgramsForAccount` gated by eligibility).
3) Contacts & Roles:
   - Lists Account Contacts with AccountContactRelation Roles.
   - Requires every contact to have a role; blocks Next if missing.
   - “New Contact” button opens standard New Contact prefilled with Account.
4) Opportunity defaults:
   - Stage picklist from Program Opportunity record type (fallback to default RT).
   - Close Date defaults to today+14 if not set (server-side default helper).
5) On Next:
   - Upsert ACRs (AccountContactRelation.Roles).
   - Create Opportunity.
   - Create OCRs for each contact/role.
   - Create Onboarding__c linked to Account, Opportunity, Vendor Program; seed Onboarding_Requirement__c from Vendor_Program_Requirement__c.
   - Create AVO linking Account + Onboarding + Opportunity (Status = Intake).
   - Emits `programselected` event with program/opportunity/onboarding/AVO ids.

## Key Apex Endpoints
- Eligibility: `getVendorProgramEligibilityForAccount(accountId)` → `eligibilityPassed`, `hasNda`, `hasProgramBase`, `message`
- Program search (gated): `searchVendorProgramsForAccount(accountId, searchText, eligibilityPassed)`
- Contacts/ACR: `getAccountContactsWithRoles(accountId)`, `upsertAccountContactRelation(accountId, contactId, role)`
- Opportunity: `createOnboardingOpportunity(accountId, name, stageName, closeDate, recordTypeId)` (defaults applied server-side)
- Onboarding + requirements: `createOnboardingWithRequirements(accountId, vendorProgramId, opportunityId)`
- AVO: `createAccountVendorProgramOnboarding(accountId, onboardingId, opportunityId, status)`

## LWC: `accountProgramOnboardingModal`
- Targets: `lightning__RecordAction` on Account.
- Uses wired `getObjectInfo` to find Program Opportunity record type; wired Stage picklist for that RT.
- Requires at least one Contact and role before proceeding.
- Toasts on errors; blocks Next during async work.

## Validation & Gatekeeping
- If NDA/Base Application incomplete → only PerfectVision programs selectable.
- Missing contacts or roles → blocks Next with toast.

## Natural Extensions
- Drive Opp stage/record type defaults from custom metadata/labels (instead of hardcoded Prospecting/default RT).
- Filter requirement seeding to active Vendor Program Requirements only, if needed.
- Add “use existing Opportunity” toggle if attaching to pre-created onboarding opps is desired.
