# Code Simplification - Quick Reference

## What Changed?

The codebase has been simplified to reduce complexity and improve maintainability. Here's what you need to know:

## Key Changes

### 1. Orchestrators Eliminated

- **Before**: LWC → Controller → Orchestrator → Service → Repository
- **After**: LWC → Service → Repository
- **Impact**: 5 orchestrator classes removed, call stack reduced by 1-2 levels

### 2. Thin Controllers Eliminated

- **Before**: LWC → Controller → Service
- **After**: LWC → Service (via @AuraEnabled methods)
- **Impact**: 3 thin controller classes removed, direct service calls

### 3. Facade Service Removed

- **Before**: `VendorOnboardingWizardService` (975 lines) → Domain Services
- **After**: Controllers call domain services directly
- **Impact**: 1 large facade removed, ~975 lines eliminated

### 4. Domain Services Consolidated

- **VendorDomainService**: Consolidates VendorService, VendorProgramService, VendorProgramGroupService
- **RequirementDomainService**: Consolidates VendorProgramRequirementService, VendorProgramRequirementGroupService
- **CommunicationDomainService**: Consolidates CommunicationTemplateService, RecipientGroupService
- **VendorOnboardingService**: Consolidates 6 adapter/service classes
- **EmailSyncDomainService**: Consolidates EmailTemplateSyncService, OrgWideEmailSyncService

### 5. Adapters Consolidated

- All vendor onboarding adapters consolidated into `VendorOnboardingService`
- Methods available via @AuraEnabled (LWC) and @InvocableMethod (Flow)

## Updated Service Names

### Use These New Services:

- ✅ `VendorDomainService` - All vendor-related operations
- ✅ `RequirementDomainService` - All requirement-related operations
- ✅ `CommunicationDomainService` - All communication-related operations
- ✅ `VendorOnboardingService` - Vendor eligibility and onboarding
- ✅ `EmailSyncDomainService` - Email synchronization

### Old Services (Removed):

- ❌ `VendorService` → Use `VendorDomainService`
- ❌ `VendorProgramService` → Use `VendorDomainService`
- ❌ `VendorProgramGroupService` → Use `VendorDomainService`
- ❌ `VendorProgramRequirementService` → Use `RequirementDomainService`
- ❌ `VendorProgramRequirementGroupService` → Use `RequirementDomainService`
- ❌ `CommunicationTemplateService` → Use `CommunicationDomainService`
- ❌ `RecipientGroupService` → Use `CommunicationDomainService`
- ❌ `EmailTemplateSyncService` → Use `EmailSyncDomainService`
- ❌ `OrgWideEmailSyncService` → Use `EmailSyncDomainService`
- ❌ `VendorOnboardingWizardService` → Use domain services directly

## For Developers

### LWC Components

- Call domain services directly via `@salesforce/apex/VendorDomainService.methodName`
- No need for controller layer for simple operations
- Example: `import searchVendors from '@salesforce/apex/VendorDomainService.searchVendors';`

### Flows

- Use `@InvocableMethod` annotations on services directly
- Example: `VendorOnboardingService.getEligibleVendorsForFlow()`

### Controllers

- Only create controllers for complex multi-service coordination
- Most operations should go directly to domain services

## Migration Guide

If you're updating existing code:

1. **Replace service calls**: Update references from old services to new consolidated services
2. **Update LWC imports**: Change `@salesforce/apex/OldService.method` to `@salesforce/apex/NewDomainService.method`
3. **Remove orchestrator calls**: Call services directly instead
4. **Update Flow actions**: Use new service method names

## Documentation

- [Simplification Complete](./simplification-complete.md) - Full details of all changes
- [Phase 1](./simplification-phase1-part2-complete.md) - Orchestrator and controller consolidation
- [Phase 2](./simplification-phase2-complete.md) - Domain service consolidation
- [Phase 3](./simplification-phase3-complete.md) - Adapter consolidation
- [Phase 4](./simplification-phase4-complete.md) - Email sync consolidation

## Questions?

Refer to the updated architecture documentation:

- [Architecture Overview](./overview.md)
- [Layered Architecture](./layers.md)
- [Apex Patterns](./apex-patterns.md)
