# Code Simplification Proposal

## Executive Summary

This document proposes a simplification strategy to reduce the number of Apex classes and layers in the Onboarding V2 system. The current architecture has **~300+ Apex classes** organized across 15+ directories, which creates complexity and maintenance overhead.

## Current State Analysis

### Class Count by Directory

- **services/**: 71 classes (largest category)
- **test/**: 78 classes (test classes)
- **repository/**: 39 classes
- **controllers/**: 36 classes
- **dto/**: 22 classes
- **handlers/**: 21 classes
- **rules/**: 27 classes
- **orchestrators/**: 10 classes
- **strategies/**: 8 classes
- **util/**: 16 classes
- **helpers/**: 4 classes
- **actions/**: 7 classes
- **jobs/**: 7 classes
- **resolver/**: 2 classes
- **schedulers/**: 1 class

**Total: ~350+ classes** (excluding test classes: ~270+ classes)

### Key Issues Identified

1. **Unnecessary Orchestrator Layer**
   - Many orchestrators just call a single service
   - Example: `OnboardingAppActivationOrchestrator` → `OnboardingAppActivationService`
   - Can be eliminated by moving logic directly to controllers or services

2. **Thin Controller Layer**
   - Many controllers are 1-3 line wrappers
   - Example: `OnboardingAppActivationController` just calls orchestrator
   - Can merge controllers directly into services with `@AuraEnabled` methods

3. **Facade Pattern Overuse**
   - `VendorOnboardingWizardService` is a 975-line facade that just delegates
   - Adds indirection without value
   - Controllers should call domain services directly

4. **Multiple Adapter Layers**
   - `VendorOnboardingLWCAdapter`, `VendorOnboardingJsonAdapter`, `VendorOnboardingFlowAdapter`
   - These seem to transform data between layers unnecessarily
   - Can be consolidated or eliminated

5. **Over-Granular Domain Services**
   - Separate services for: Vendor, VendorProgram, VendorProgramGroup, VendorProgramRequirement, etc.
   - Could be consolidated into 2-3 larger services

6. **DTO Proliferation**
   - 22 DTO classes for data transfer
   - Many might be unnecessary if we simplify layers

## Proposed Simplification Strategy

### Phase 1: Eliminate Orchestrator Layer (High Impact)

**Target**: Remove 10 orchestrator classes

**Approach**:

- Move orchestrator logic directly into services
- Controllers call services directly
- Keep orchestrators only for complex multi-service workflows

**Example Transformation**:

```apex
// BEFORE: Controller → Orchestrator → Service
OnboardingAppActivationController.activate()
  → OnboardingAppActivationOrchestrator.activate()
    → OnboardingAppActivationService.activateRecord()

// AFTER: Controller → Service
OnboardingAppActivationController.activate()
  → OnboardingAppActivationService.activate()
```

**Estimated Reduction**: 10 classes → 0-2 classes (keep only complex orchestrators)

### Phase 2: Merge Thin Controllers into Services (High Impact)

**Target**: Reduce 36 controllers to ~15-20 controllers

**Approach**:

- Add `@AuraEnabled` methods directly to services
- Keep controllers only for:
  - Complex UI-specific logic
  - Multiple service coordination
  - Special error handling requirements

**Example Transformation**:

```apex
// BEFORE: Separate controller
public class OnboardingAppActivationController {
    @AuraEnabled
    public static void activate(Id recordId, String objectApiName) {
        OnboardingAppActivationOrchestrator.activate(recordId, objectApiName);
    }
}

// AFTER: Service with @AuraEnabled
public class OnboardingAppActivationService {
    @AuraEnabled
    public static void activate(Id recordId, String objectApiName) {
        // Direct implementation
    }
}
```

**Estimated Reduction**: 36 controllers → 15-20 controllers (reduce by ~45%)

### Phase 3: Consolidate Domain Services (Medium Impact)

**Target**: Reduce 71 services to ~40-50 services

**Approach**:

- Group related domain services:
  - **VendorDomainService**: Vendor, VendorProgram, VendorProgramGroup
  - **RequirementDomainService**: VendorProgramRequirement, OnboardingRequirement, RequirementSet
  - **OnboardingDomainService**: OnboardingApplication, OnboardingStatus, OnboardingRules
  - **CommunicationDomainService**: CommunicationTemplate, RecipientGroup, EmailTemplate

**Example Consolidation**:

```apex
// BEFORE: 3 separate services
VendorService.searchVendors()
VendorProgramService.searchVendorPrograms()
VendorProgramGroupService.searchVendorProgramGroups()

// AFTER: 1 consolidated service
VendorDomainService.searchVendors()
VendorDomainService.searchVendorPrograms()
VendorDomainService.searchVendorProgramGroups()
```

**Estimated Reduction**: 71 services → 40-50 services (reduce by ~30%)

### Phase 4: Remove Facade Services (Low Impact)

**Target**: Remove `VendorOnboardingWizardService` facade

**Approach**:

- Update all callers to use domain services directly
- Remove the 975-line facade class
- Controllers call domain services directly

**Estimated Reduction**: 1 large facade class removed

### Phase 5: Consolidate Adapter Classes (Medium Impact)

**Target**: Reduce adapter classes from 3+ to 1 or eliminate

**Approach**:

- Review if adapters are necessary
- If needed, consolidate into a single transformation utility
- If not needed, move transformation logic into services

**Estimated Reduction**: 3 adapter classes → 0-1 classes

### Phase 6: Simplify DTO Layer (Low Impact)

**Target**: Reduce DTOs from 22 to ~10-15

**Approach**:

- Remove DTOs that are just pass-throughs
- Keep only DTOs that add value (complex transformations, aggregations)
- Use SObjects directly where possible

**Estimated Reduction**: 22 DTOs → 10-15 DTOs (reduce by ~30%)

## Proposed New Architecture

### Simplified Layer Structure

```
┌─────────────────────────────────────────┐
│ APPLICATION LAYER                      │
│ (LWC Components)                        │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ SERVICE LAYER (with @AuraEnabled)      │
│ - Domain Services (consolidated)       │
│ - Business Logic Services              │
│ - Controllers (only for complex cases) │
└─────────────────────────────────────────┘
↓
┌─────────────────────────────────────────┐
│ REPOSITORY LAYER                       │
│ - Data Access Only                     │
└─────────────────────────────────────────┘
```

### New Directory Structure

```
force-app/main/default/classes/
├── services/          # Business logic + @AuraEnabled methods (40-50 classes)
│   ├── domain/       # Domain-specific services (consolidated)
│   ├── business/     # Business logic services
│   └── shared/       # Shared utility services
├── repository/       # Data access only (39 classes - keep as-is)
├── controllers/      # Only complex controllers (15-20 classes)
├── handlers/         # Trigger handlers (21 classes - keep as-is)
├── rules/            # Validation rules (27 classes - keep as-is)
├── strategies/       # Strategy pattern (8 classes - keep as-is)
├── dto/              # Data transfer objects (10-15 classes)
├── util/             # Utilities (16 classes - keep as-is)
├── jobs/             # Scheduled/batch jobs (7 classes - keep as-is)
├── actions/          # Flow actions (7 classes - keep as-is)
└── test/             # Test classes (co-located)
```

## Implementation Plan

### Phase 1: Quick Wins (Week 1-2)

1. ✅ Remove thin orchestrators (10 classes)
2. ✅ Merge simple controllers into services (15-20 classes)
3. ✅ Remove facade service (1 class)

**Estimated Reduction**: ~25-30 classes

### Phase 2: Service Consolidation (Week 3-4)

1. ✅ Consolidate Vendor domain services (3 → 1)
2. ✅ Consolidate Requirement domain services (3 → 1)
3. ✅ Consolidate Onboarding domain services (5 → 2)

**Estimated Reduction**: ~10-15 classes

### Phase 3: Cleanup (Week 5-6)

1. ✅ Consolidate/remove adapters (3 → 0-1)
2. ✅ Simplify DTO layer (22 → 10-15)
3. ✅ Update all references
4. ✅ Update tests

**Estimated Reduction**: ~10-15 classes

### Total Estimated Reduction

- **Before**: ~270 production classes
- **After**: ~200-220 production classes
- **Reduction**: ~50-70 classes (~20-25% reduction)

## Benefits

1. **Reduced Complexity**: Fewer classes to understand and maintain
2. **Faster Development**: Less indirection, easier to find code
3. **Better Performance**: Fewer method calls, less overhead
4. **Easier Onboarding**: New developers can understand the system faster
5. **Maintained Functionality**: All features preserved, just reorganized

## Risks & Mitigations

### Risk 1: Breaking Changes

- **Mitigation**: Update all references in phases, comprehensive testing

### Risk 2: Loss of Separation of Concerns

- **Mitigation**: Keep clear boundaries (Services vs Repositories), maintain naming conventions

### Risk 3: Larger Service Classes

- **Mitigation**: Use inner classes or private methods to organize code within services

### Risk 4: Test Updates

- **Mitigation**: Update tests incrementally, maintain test coverage

## Success Metrics

- [ ] Reduce total classes by 20-25%
- [ ] Reduce average call stack depth by 1-2 levels
- [ ] Maintain 100% test coverage
- [ ] No functionality regressions
- [ ] Improved developer feedback (simpler codebase)

## Next Steps

1. **Review & Approve**: Get stakeholder approval for simplification approach
2. **Create Branch**: Create feature branch for refactoring work
3. **Phase 1 Implementation**: Start with quick wins (orchestrators, thin controllers)
4. **Incremental Testing**: Test after each phase
5. **Documentation Update**: Update architecture docs as we go

## Questions for Discussion

1. Are there any orchestrators that MUST stay separate?
2. Are there any controllers with complex logic that should remain?
3. Which domain services are most critical to keep separate?
4. What's the acceptable timeline for this refactoring?
