# Refactoring Alignment with Existing Codebase

## Summary

This document outlines the refactoring changes needed to align the Onboarding Console v1 scaffolding with the existing codebase architecture. The original blueprint introduced parallel data models (Enrollment\*, etc.) that conflict with the established Onboarding**c + Onboarding_Requirement**c paradigm.

## Key Changes Made

### 1. Data Model Alignment

**Before (Blueprint):**

- Introduced `Enrollment__c` and `Enrollment_Requirement__c` objects
- Parallel deduplication logic at enrollment level

**After (Aligned):**

- Leverage existing `Onboarding__c` + `Onboarding_Requirement__c` model
- Use `Vendor_Program_Requirement__c` as the canonical requirement reference
- Deduplication handled at VPR level within existing Onboarding records

### 2. Apex Service Integration

**Before (Blueprint):**

- New `OnboardingBlueprintServices.cls` with invocable methods
- Parallel logic to existing controllers

**After (Aligned):**

- Remove `OnboardingBlueprintServices.cls` to avoid duplication
- Delegates to existing controllers:
  - `OnboardingRequirementsPanelController.getRequirements()` for checklist data
  - `OnboardingRequirementsPanelController.updateRequirementStatuses()` for form updates
  - `VendorOnboardingWizardController.createOnboardingWithRequirements()` for program enrollment
  - Add new `OnboardingRequirementDueDateController` for due date overrides

### 3. LWC Component Updates

**Before (Blueprint):**

- GraphQL wire with TODO placeholders
- Stub implementations

**After (Aligned):**

- `@wire(OnboardingRequirementsPanelController.getRequirements)` for data
- Proper integration with existing Apex DTOs
- Maintains same component structure and API

## Implementation Details

### Requirement Checklist Component

**File:** `force-app/main/default/lwc/requirementChecklist/requirementChecklist.js`

**Changes:**

1. Replaced GraphQL wire with Apex wire
2. Updated to use existing `OnboardingRequirementsPanelController.getRequirements()`
3. Added `onboardingId` input parameter
4. Maintained same output structure for UI compatibility

### Due Date Override Controller

**New File:** `force-app/main/default/classes/controllers/OnboardingRequirementDueDateController.cls`

**Purpose:**

- Dedicated endpoint for due date overrides
- Implements FLS checks and audit logging
- Follows existing controller patterns with `@AuraEnabled` methods
- Integrates with `OnboardingRequirementService` for user-mode DML

### Component API Changes

**Before:**

```javascript
// GraphQL query with TODOs
const QUERY = gql`
query DealerChecklist($dealerId: ID!) {
  // ...
}
`;

// Event dispatch for form opens
handleOpenForm(event) {
    const requirementId = event.detail?.requirementId;
    this.dispatchEvent(new CustomEvent('openform', { detail: { requirementId } }));
}
```

**After:**

```javascript
// Apex wire to existing service
@wire(OnboardingRequirementsPanelController.getRequirements, { onboardingId: '$onboardingId' })
wiredRequirements({ error, data }) {
    // Handle existing Apex DTOs
}

// Event dispatch for form opens (same interface)
handleOpenForm(event) {
    const requirementId = event.detail?.requirementId;
    this.dispatchEvent(new CustomEvent('openform', { detail: { requirementId } }));
}
```

## Benefits of Alignment

1. **Single Source of Truth:** Maintains consistency with existing rules engine and requirement management
2. **Reduced Maintenance:** Eliminates redundant code paths and services
3. **Faster Delivery:** Leverages existing tested components and flows
4. **Architectural Consistency:** Follows established patterns in `controllers/`, `services/`, `repository/` layers
5. **Scalability:** Preserves existing performance optimizations and bulkification patterns

## Future Considerations

1. **Progress/Risk Computation:** Can be added as a small helper service or computed in LWC
2. **Multi-Program Handling:** Implemented via multiple Onboarding\_\_c records per dealer
3. **Audit Trail:** Due date overrides will write to Audit\_\_c or rely on Field History

## Testing Strategy

1. **Existing Tests:** All existing Apex tests continue to pass
2. **New Controller Tests:** Added `OnboardingReqDueDateControllerTest.cls`
3. **Integration Tests:** Verify LWC components work with existing Apex services
4. **End-to-End:** Validate Dealer checklist flows work with real data

This alignment ensures the Onboarding Console v1 will integrate seamlessly with the existing system while preserving all architectural decisions and performance optimizations that have been carefully considered.
