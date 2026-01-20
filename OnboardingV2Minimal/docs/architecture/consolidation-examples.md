# Consolidation Examples

This document provides specific examples of how classes can be consolidated to simplify the codebase.

## Example 1: Eliminate Thin Orchestrator

### Current Structure (3 classes)

**OnboardingAppActivationController.cls** (6 lines)

```apex
public with sharing class OnboardingAppActivationController {
  @AuraEnabled
  public static void activate(Id recordId, String objectApiName) {
    OnboardingAppActivationOrchestrator.activate(recordId, objectApiName);
  }
}
```

**OnboardingAppActivationOrchestrator.cls** (15 lines)

```apex
public with sharing class OnboardingAppActivationOrchestrator {
  public static void activate(Id recordId, String objectApiName) {
    ValidationHelper.requireNotBlank(objectApiName, 'Object API Name');
    ValidationHelper.requireId(recordId, 'Record Id');
    ActivationStrategy strategy = ActivationStrategyFactory.getStrategy(
      objectApiName
    );
    strategy.activate(recordId);
  }
}
```

**OnboardingAppActivationService.cls** (131 lines)

```apex
public with sharing class OnboardingAppActivationService {
  public static void activateRecord(String objectApiName, Id recordId) {
    // ... implementation
  }
}
```

### Simplified Structure (1 class)

**OnboardingAppActivationService.cls** (with @AuraEnabled)

```apex
public with sharing class OnboardingAppActivationService {
  @AuraEnabled
  public static void activate(Id recordId, String objectApiName) {
    ValidationHelper.requireNotBlank(objectApiName, 'Object API Name');
    ValidationHelper.requireId(recordId, 'Record Id');

    ActivationStrategy strategy = ActivationStrategyFactory.getStrategy(
      objectApiName
    );
    strategy.activate(recordId);
  }

  // Keep existing activateRecord method for internal use
  public static void activateRecord(String objectApiName, Id recordId) {
    // ... existing implementation
  }
}
```

**Result**: 3 classes → 1 class (67% reduction)

---

## Example 2: Consolidate Vendor Domain Services

### Current Structure (3 separate services)

**VendorService.cls**

```apex
public with sharing class VendorService {
    public static List<Vendor__c> searchVendors(String vendorName) { ... }
    public static Id createVendor(Vendor__c vendor) { ... }
    public static List<Vendor__c> getVendorsWithPrograms() { ... }
}
```

**VendorProgramService.cls**

```apex
public with sharing class VendorProgramService {
    public static List<Vendor_Customization__c> searchVendorPrograms(String name) { ... }
    public static Id createVendorProgram(...) { ... }
    public static List<Vendor_Customization__c> searchVendorProgramsForAccount(...) { ... }
}
```

**VendorProgramGroupService.cls**

```apex
public with sharing class VendorProgramGroupService {
    public static List<Vendor_Program_Group__c> searchVendorProgramGroups(String name) { ... }
    public static Id createVendorProgramGroup(...) { ... }
}
```

### Simplified Structure (1 consolidated service)

**VendorDomainService.cls**

```apex
public with sharing class VendorDomainService {
    // Vendor operations
    public static List<Vendor__c> searchVendors(String vendorName) { ... }
    public static Id createVendor(Vendor__c vendor) { ... }
    public static List<Vendor__c> getVendorsWithPrograms() { ... }

    // Vendor Program operations
    public static List<Vendor_Customization__c> searchVendorPrograms(String name) { ... }
    public static Id createVendorProgram(...) { ... }
    public static List<Vendor_Customization__c> searchVendorProgramsForAccount(...) { ... }

    // Vendor Program Group operations
    public static List<Vendor_Program_Group__c> searchVendorProgramGroups(String name) { ... }
    public static Id createVendorProgramGroup(...) { ... }
}
```

**Result**: 3 classes → 1 class (67% reduction)

---

## Example 3: Remove Facade Service

### Current Structure

**VendorOnboardingWizardService.cls** (975 lines - just delegates)

```apex
public with sharing class VendorOnboardingWizardService {
  public static List<Vendor__c> searchVendors(String vendorName) {
    return VendorService.searchVendors(vendorName);
  }

  public static List<Vendor_Customization__c> searchVendorPrograms(
    String name
  ) {
    return VendorProgramService.searchVendorPrograms(name);
  }

  // ... 100+ more delegation methods
}
```

**VendorOnboardingWizardController.cls**

```apex
public class VendorOnboardingWizardController {
  @AuraEnabled
  public static List<Vendor__c> searchVendors(String vendorName) {
    return VendorOnboardingWizardService.searchVendors(vendorName);
  }
}
```

### Simplified Structure

**VendorOnboardingWizardController.cls** (calls domain services directly)

```apex
public class VendorOnboardingWizardController {
  @AuraEnabled
  public static List<Vendor__c> searchVendors(String vendorName) {
    return VendorDomainService.searchVendors(vendorName);
  }

  @AuraEnabled
  public static List<Vendor_Customization__c> searchVendorPrograms(
    String name
  ) {
    return VendorDomainService.searchVendorPrograms(name);
  }
}
```

**Result**: Remove 975-line facade, controllers call domain services directly

---

## Example 4: Consolidate Adapter Classes

### Current Structure (3 adapter classes)

**VendorOnboardingLWCAdapter.cls**

```apex
public class VendorOnboardingLWCAdapter {
    public static SomeDTO adaptForLWC(SObject record) { ... }
}
```

**VendorOnboardingJsonAdapter.cls**

```apex
public class VendorOnboardingJsonAdapter {
    public static String adaptToJson(SObject record) { ... }
}
```

**VendorOnboardingFlowAdapter.cls**

```apex
public class VendorOnboardingFlowAdapter {
    public static Map<String, Object> adaptForFlow(SObject record) { ... }
}
```

### Simplified Structure (1 utility or inline)

**Option A: Single Transformation Utility**

```apex
public class VendorOnboardingTransformer {
    public static SomeDTO toLWC(SObject record) { ... }
    public static String toJson(SObject record) { ... }
    public static Map<String, Object> toFlow(SObject record) { ... }
}
```

**Option B: Inline in Service**

```apex
public class VendorDomainService {
  @AuraEnabled(cacheable=true)
  public static List<SomeDTO> getVendorsForLWC() {
    List<Vendor__c> vendors = VendorRepository.getAll();
    // Transform inline
    List<SomeDTO> dtos = new List<SomeDTO>();
    for (Vendor__c v : vendors) {
      dtos.add(new SomeDTO(v));
    }
    return dtos;
  }
}
```

**Result**: 3 classes → 0-1 classes

---

## Example 5: Merge Email Sync Orchestrator

### Current Structure

**EmailTemplateSyncController.cls** (Schedulable)

```apex
public class EmailTemplateSyncController implements Schedulable {
  public void execute(SchedulableContext ctx) {
    EmailTemplateSyncOrchestrator.run(false);
  }
}
```

**EmailTemplateSyncOrchestrator.cls**

```apex
public class EmailTemplateSyncOrchestrator {
  public static void run(Boolean isManual) {
    Sync_Log__c logRec = UtilitiesSyncLogHelper.createLogRecord(
      'Email Template Sync',
      isManual
    );
    try {
      EmailSyncSummaryDTO summary = EmailTemplateSyncService.syncAllTemplates(
        logRec.Id
      );
      UtilitiesSyncLogHelper.updateLogRecord(logRec.Id, summary);
    } catch (Exception ex) {
      UtilitiesSyncLogHelper.markFailed(logRec.Id, ex);
    }
  }
}
```

**EmailTemplateSyncService.cls**

```apex
public class EmailTemplateSyncService {
  public EmailSyncSummaryDTO syncAllTemplates(Id jobId) {
    // ... actual sync logic
  }
}
```

### Simplified Structure

**EmailTemplateSyncService.cls** (with scheduling support)

```apex
public class EmailTemplateSyncService implements Schedulable {
  public void execute(SchedulableContext ctx) {
    run(false);
  }

  public static void run(Boolean isManual) {
    Sync_Log__c logRec = UtilitiesSyncLogHelper.createLogRecord(
      'Email Template Sync',
      isManual
    );
    try {
      EmailSyncSummaryDTO summary = syncAllTemplates(logRec.Id);
      UtilitiesSyncLogHelper.updateLogRecord(logRec.Id, summary);
    } catch (Exception ex) {
      UtilitiesSyncLogHelper.markFailed(logRec.Id, ex);
    }
  }

  public static EmailSyncSummaryDTO syncAllTemplates(Id jobId) {
    // ... existing sync logic
  }
}
```

**Result**: 3 classes → 1 class (67% reduction)

---

## Summary of Consolidation Opportunities

| Category        | Current | Proposed   | Reduction |
| --------------- | ------- | ---------- | --------- |
| Orchestrators   | 10      | 0-2        | 80-100%   |
| Controllers     | 36      | 15-20      | 45%       |
| Domain Services | 15+     | 5-7        | 50-60%    |
| Facade Services | 1       | 0          | 100%      |
| Adapters        | 3+      | 0-1        | 67-100%   |
| **Total**       | **~65** | **~25-30** | **~55%**  |

## Migration Checklist

For each consolidation:

- [ ] Identify all callers of the class to be removed
- [ ] Update callers to use the consolidated class
- [ ] Move any unique logic from removed class to consolidated class
- [ ] Update tests to reference new class
- [ ] Verify all functionality still works
- [ ] Delete the old class files
- [ ] Update documentation

## Testing Strategy

1. **Unit Tests**: Update test classes to reference consolidated classes
2. **Integration Tests**: Run full test suite to catch any missed references
3. **Manual Testing**: Test critical user flows to ensure no regressions
4. **Code Review**: Review consolidated classes for maintainability
