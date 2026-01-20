# Apex Class Architectural Patterns

## Overview

This document defines the architectural patterns and conventions that all Apex classes in the Onboarding V2 system must follow. These patterns ensure consistency, maintainability, and proper separation of concerns.

## Directory Organization

All Apex classes must be organized in the following directory structure:

```
force-app/main/default/classes/
├── actions/          # Flow action classes (*Action.cls)
├── controllers/      # LWC controllers (*Ctlr.cls or *Controller.cls)
├── dto/              # Data Transfer Objects (*DTO.cls)
├── handlers/         # Trigger/event handlers (*Hdlr.cls)
├── helpers/          # Utility helper classes (*Helper.cls)
├── jobs/             # Scheduled/batch jobs (*Job.cls)
├── orchestrators/    # Legacy orchestration logic (*Orch.cls) - Most consolidated into services
├── repository/       # Data access layer (*Repo.cls)
├── resolver/         # Resolution logic (*Resolver.cls)
├── services/         # Business logic services (*Service.cls)
├── strategies/       # Strategy pattern implementations (*Strategy.cls, *StrategyFactory.cls)
├── test/             # Test data factories (*Factory.cls)
├── util/             # Utility classes (*Util.cls)
└── wrappers/         # Wrapper classes (*Wrapper.cls)
```

**Rule**: Classes must be placed in their appropriate subdirectory based on their role. Classes in the root directory are only acceptable for:

- Legacy classes being migrated
- Shared base classes/interfaces
- Exception classes

## Naming Conventions

### Domain Service Classes

- **Pattern**: `*DomainService.cls`
- **Location**: `services/`
- **Example**: `VendorDomainService`, `RequirementDomainService`, `CommunicationDomainService`
- **Responsibilities**: Consolidated business logic for a domain, LWC/Flow integration
- **Must NOT**: Contain direct SOQL queries or DML operations (use repositories)
- **Should**: Include `@AuraEnabled` methods for LWC integration, `@InvocableMethod` for Flow integration

### Business Logic Service Classes

- **Pattern**: `*Service.cls`
- **Location**: `services/`
- **Example**: `OnboardingApplicationService`, `OnboardingRulesService`, `OnboardingAppActivationService`
- **Responsibilities**: Business logic, validation, coordination
- **Must NOT**: Contain direct SOQL queries or DML operations (use repositories)
- **May**: Include `@AuraEnabled` methods for direct LWC integration

### Controller Classes

- **Pattern**: `*Ctlr.cls` or `*Controller.cls`
- **Location**: `controllers/`
- **Example**: `OnboardingAppActivationController`, `OnboardingRequirementsPanelController`
- **Responsibilities**: Thin layer that delegates to services
- **Must NOT**: Contain business logic or direct data access

### Repository Classes

- **Pattern**: `*Repo.cls` or `*Repository.cls`
- **Location**: `repository/`
- **Example**: `OnboardingAppVendorProgramReqRepo`, `OnboardingAppECCRepository`
- **Responsibilities**: Data access only (SOQL, DML)
- **Must NOT**: Contain business logic

### Orchestrator Classes (Legacy)

- **Pattern**: `*Orch.cls`
- **Location**: `orchestrators/`
- **Example**: (Most orchestrators have been consolidated into services)
- **Responsibilities**: Coordinate multiple services for complex workflows
- **Must NOT**: Contain business logic or direct data access
- **Note**: Most orchestrators have been eliminated. Complex workflows are handled directly in services.

### Handler Classes

- **Pattern**: `*Hdlr.cls` or `*Handler.cls`
- **Location**: `handlers/`
- **Example**: `OnboardingAppVendorProgramReqHdlr`, `VersioningTriggerHandler`
- **Responsibilities**: Trigger/event handling, delegate to services
- **Must NOT**: Contain business logic (delegate to services)

### Action Classes

- **Pattern**: `*Action.cls`
- **Location**: `actions/`
- **Example**: `OnboardingAppActivationAction`, `EmailTemplateSyncFlowAction`
- **Responsibilities**: Flow-invocable actions
- **Must NOT**: Contain business logic (delegate to services/orchestrators)

### Strategy Classes

- **Pattern**: `*Strategy.cls` (implementations), `*StrategyFactory.cls` (factories)
- **Location**: `strategies/`
- **Example**: `ActivationStrategy`, `EmailSenderStrategy`, `ActivationStrategyFactory`
- **Responsibilities**: Encapsulate algorithms/behaviors that can vary independently
- **Purpose**: Follow Open/Closed Principle - extend functionality without modifying existing code
- **Must NOT**: Contain business logic (delegate to services), perform direct data access

### Test Classes

- **Pattern**: `*Test.cls`
- **Location**: Same directory as class being tested
- **Example**: `OnboardingApplicationServiceTest`
- **Responsibilities**: Unit tests for corresponding class

## Layered Architecture Pattern

### Layer Responsibilities

#### Application Layer (Controllers)

- **Purpose**: Interface between LWC components and business logic
- **Responsibilities**:
  - Receive requests from LWC components
  - Validate input parameters
  - Delegate to service layer
  - Return results to LWC
- **Must NOT**:
  - Contain business logic
  - Perform direct data access
  - Make multiple service calls (use orchestrator instead)

**Example Pattern (Simplified):**

```apex
// LWC components call services directly via @AuraEnabled methods
// Example: vendorProgramOnboardingVendor.js
import searchVendors from '@salesforce/apex/VendorDomainService.searchVendors';

// Services expose @AuraEnabled methods directly
public with sharing class VendorDomainService {
    @AuraEnabled(cacheable=true)
    public static List<Vendor__c> searchVendors(String vendorName) {
        return VendorOnboardingWizardRepository.searchVendors(vendorName);
    }
}

// Complex controllers only when needed for multi-service coordination
public with sharing class VendorOnboardingWizardController {
    @AuraEnabled
    public static void finalizeVendorProgram(Id vendorProgramId, Id vendorId, ...) {
        // Coordinates multiple domain services
        VendorDomainService.finalizeVendorProgram(...);
        RequirementDomainService.createVendorProgramRequirement(...);
    }
}
```

#### Business Logic Layer (Services)

- **Purpose**: Contains business rules and logic
- **Responsibilities**:
  - Business rule enforcement
  - Validation logic
  - Data transformation
  - Coordinate with repositories for data access
- **Must NOT**:
  - Contain direct SOQL queries (use repositories)
  - Contain direct DML operations (use repositories)
  - Handle UI concerns

**Example Pattern (Consolidated Domain Service):**

```apex
public with sharing class VendorDomainService {
  // LWC integration
  @AuraEnabled(cacheable=true)
  public static List<Vendor__c> searchVendors(String vendorName) {
    return VendorOnboardingWizardRepository.searchVendors(vendorName);
  }

  @AuraEnabled
  public static Id createVendor(Vendor__c vendor) {
    ValidationHelper.requireRecord(vendor, 'Vendor');
    ValidationHelper.requireField(vendor.Name, 'Vendor Name');
    DefaultValueHelper.applyVendorDefaults(vendor);
    return VendorOnboardingWizardRepository.insertVendor(vendor);
  }

  // Vendor Program operations in same service
  @AuraEnabled(cacheable=true)
  public static List<Vendor_Customization__c> searchVendorPrograms(
    String vendorProgramName
  ) {
    return VendorOnboardingWizardRepository.searchVendorPrograms(
      vendorProgramName
    );
  }
}
```

#### Data Access Layer (Repositories)

- **Purpose**: Handles all database operations
- **Responsibilities**:
  - SOQL queries
  - DML operations (insert, update, delete, upsert)
  - Query optimization
- **Must NOT**:
  - Contain business logic
  - Perform validation (except data integrity)
  - Transform data (except for query results)

**Example Pattern:**

```apex
public with sharing class OnboardingAppECCRepository {
  public static List<Required_Credential__c> fetchRequiredCredentials(
    Id vendorProgramId
  ) {
    return [
      SELECT
        Id,
        Name,
        External_Contact_Credential_Type__c,
        External_Contact_Credential_Type__r.Name
      FROM Required_Credential__c
      WHERE Vendor_Customization__c = :vendorProgramId
    ];
  }

  public static External_Contact_Credential_Type__c insertCredentialType(
    String name
  ) {
    External_Contact_Credential_Type__c newType = new External_Contact_Credential_Type__c(
      Name = name
    );
    insert newType;
    return newType;
  }
}
```

## Sharing Model Pattern

All classes must explicitly declare sharing model:

- **`with sharing`**: Default for all classes (enforces user's sharing rules)
- **`without sharing`**: Only when explicitly needed (e.g., system operations)

**Example:**

```apex
public with sharing class OnboardingApplicationService {
  // Class implementation
}
```

## Error Handling Pattern

### Exception Types

- **`AuraHandledException`**: For user-facing errors from controllers
- **`IllegalArgumentException`**: For invalid parameters
- **`Custom Exceptions`**: For domain-specific errors

### Error Handling Best Practices

1. Validate input parameters early
2. Provide meaningful error messages
3. Log errors for debugging
4. Never expose system details to users

**Example:**

```apex
public with sharing class OnboardingAppActivationOrchestrator {
  public static void activate(Id recordId, String objectApiName) {
    if (String.isBlank(objectApiName) || recordId == null) {
      throw new AuraHandledException(
        'Object API Name and Record Id are required.'
      );
    }
    try {
      OnboardingAppActivationService.activateRecord(objectApiName, recordId);
    } catch (Exception e) {
      throw new AuraHandledException('Activation failed: ' + e.getMessage());
    }
  }
}
```

## Service Layer Pattern

### Service Responsibilities

1. **Business Logic**: Core business rules and validation
2. **Coordination**: Coordinate between multiple repositories
3. **Transformation**: Transform data between layers
4. **Delegation**: Delegate data access to repositories

### Service Must NOT

1. ❌ Contain direct SOQL queries
2. ❌ Contain direct DML operations
3. ❌ Handle UI concerns
4. ❌ Make HTTP callouts (use separate service)

### Repository Pattern

All data access must go through repository classes:

- Services call repositories for data access
- Repositories handle all SOQL and DML
- Repositories are reusable across services

## Controller Pattern

### Controller Responsibilities

1. **Input Validation**: Validate parameters from LWC
2. **Multi-Service Coordination**: Coordinate multiple domain services for complex workflows
3. **Response Formatting**: Format responses for LWC

### Controller Must NOT

1. ❌ Contain business logic (delegate to services)
2. ❌ Perform direct data access
3. **Note**: Most thin controllers have been eliminated. LWC components call domain services directly via @AuraEnabled methods.

## Orchestrator Pattern (Legacy)

**Note**: Most orchestrators have been consolidated into services. Use orchestrators only for very complex multi-domain workflows that truly need separate coordination.

### When to Use Orchestrators (Rare)

- Very complex workflows spanning multiple unrelated domains
- Transaction management across many services
- When coordination logic is substantial enough to warrant separation

### Orchestrator Responsibilities

1. **Coordination**: Coordinate multiple services
2. **Workflow Management**: Manage complex workflows
3. **Error Handling**: Handle errors across services

**Simplified Approach**: Most coordination is now handled directly in domain services or controllers that coordinate multiple domain services.

## Strategy Pattern

### When to Use Strategy Pattern

The Strategy pattern should be used when:

- Multiple algorithms/behaviors exist for the same task
- You want to avoid switch/if-else statements that violate Open/Closed Principle
- Behavior needs to be selected at runtime
- You want to make the system extensible without modifying existing code

### Strategy Interface Pattern

All strategies implement a common interface:

```apex
public interface ActivationStrategy {
  void activate(Id recordId);
}
```

### Strategy Implementation Pattern

Each strategy encapsulates a specific behavior:

```apex
public with sharing class VendorCustomizationActivationStrategy implements ActivationStrategy {
    public void activate(Id recordId) {
        VendorProgramActivationService.activate(recordId);
    }
}

public with sharing class GenericActivationStrategy implements ActivationStrategy {
    private String objectApiName;

    public GenericActivationStrategy(String objectApiName) {
        this.objectApiName = objectApiName;
    }

    public void activate(Id recordId) {
        OnboardingAppActivationService.activateRecord(objectApiName, recordId);
    }
}
```

### Strategy Factory Pattern

Factories centralize strategy selection and creation:

```apex
public with sharing class ActivationStrategyFactory {
  private static final Map<String, ActivationStrategy> STRATEGY_CACHE = new Map<String, ActivationStrategy>();

  public static ActivationStrategy getStrategy(String objectApiName) {
    if (String.isBlank(objectApiName)) {
      throw new IllegalArgumentException('Object API name cannot be blank');
    }

    // Check cache first
    if (STRATEGY_CACHE.containsKey(objectApiName)) {
      return STRATEGY_CACHE.get(objectApiName);
    }

    // Create strategy based on object type
    ActivationStrategy strategy;
    switch on objectApiName {
      when 'Vendor_Customization__c' {
        strategy = new VendorCustomizationActivationStrategy();
      }
      when else {
        strategy = new GenericActivationStrategy(objectApiName);
      }
    }

    // Cache the strategy
    STRATEGY_CACHE.put(objectApiName, strategy);
    return strategy;
  }
}
```

### Using Strategies

Services use factories to get strategies:

```apex
public with sharing class OnboardingAppActivationService {
  @AuraEnabled
  public static void activate(Id recordId, String objectApiName) {
    ValidationHelper.requireNotBlank(objectApiName, 'Object API Name');
    ValidationHelper.requireId(recordId, 'Record Id');

    // Get the appropriate strategy for this object type
    ActivationStrategy strategy = ActivationStrategyFactory.getStrategy(
      objectApiName
    );
    strategy.activate(recordId);
  }
}
```

### Benefits of Strategy Pattern

1. **Open/Closed Principle**: Add new strategies without modifying existing code
2. **Single Responsibility**: Each strategy handles one specific behavior
3. **Testability**: Strategies can be tested independently
4. **Maintainability**: Behavior changes are isolated to specific strategies
5. **Extensibility**: New behaviors can be added by creating new strategy classes

### Current Strategy Implementations

- **Activation Strategies**: `ActivationStrategy`, `VendorCustomizationActivationStrategy`, `GenericActivationStrategy`
- **Email Sender Strategies**: `EmailSenderStrategy`, `CurrentUserSenderStrategy`, `OrgWideSenderStrategy`

## Validation Rule Pattern

### Registry Pattern

Validation rules are registered in a central registry:

```apex
public class OnboardingAppRuleRegistry {
  public static Map<String, List<OnboardingAppValidationRule>> getRules() {
    Map<String, List<OnboardingAppValidationRule>> rules = new Map<String, List<OnboardingAppValidationRule>>();
    rules.put(
      'Vendor_Program_Recipient_Group__c',
      new List<OnboardingAppValidationRule>{
        new RequireParentVersionOnActivationRule(),
        new OnlyOneActiveRecGrpPerPrgrmRule()
      }
    );
    return rules;
  }
}
```

### Validation Rule Interface

All validation rules implement `OnboardingAppValidationRule`:

```apex
public interface OnboardingAppValidationRule {
  Boolean validate(SObject record);
  String getErrorMessage();
}
```

## Current Pattern Violations

### Directory Organization Issues

The following classes are in the root directory but should be moved:

1. **Services** (should be in `services/`):
   - `OnboardingApplicationService.cls`
   - `OnboardingRulesService.cls`
   - `OnboardingAppECCService.cls`

2. **Controllers** (should be in `controllers/`):
   - `OnboardingRequirementsPanelController.cls`
   - `OnboardingStatusRulesEngineController.cls`
   - `OnboardingStatusRuleController.cls`
   - `VendorOnboardingWizardController.cls`

3. **Repositories** (should be in `repository/`):
   - `OnboardingAppECCRepository.cls`
   - `VendorOnboardingWizardRepository.cls`

4. **Handlers** (should be in `handlers/`):
   - `OnboardingAppRuleEngineHandler.cls`

5. **Validation Rules** (should be in `rules/` or `validation/`):
   - `RequireParentVersionOnActivationRule.cls`
   - `OnlyOneActiveRecGrpPerPrgrmRule.cls`
   - `RecipientAndProgramMustBeActiveRule.cls`
   - `PreventDupRecGrpAssignmentRule.cls`
   - `NoDuplicateRecipientGroupAssignmentRule.cls`

### Simplified Architecture Notes

- ✅ **Orchestrators**: Most orchestrators have been consolidated into services
- ✅ **Facade Services**: Large facade services (e.g., `VendorOnboardingWizardService`) have been eliminated
- ✅ **Thin Controllers**: Many thin controllers have been eliminated; LWC components call services directly
- ✅ **Domain Services**: Related services have been consolidated into domain services (e.g., `VendorDomainService`, `RequirementDomainService`)

### Service Layer Violations

1. **Direct SOQL in Services**:
   - `OnboardingApplicationService` - Contains direct SOQL queries
   - `OnboardingRulesService` - Contains direct SOQL queries
   - Should use repository pattern

2. **Direct DML in Services**:
   - `OnboardingApplicationService.saveProgress()` - Contains direct DML
   - `OnboardingRulesService.createOrUpdateRule()` - Contains direct DML
   - Should use repository pattern

3. **Direct Updates in Evaluators**:
   - `OnboardingStatusEvaluator` - Directly updates records
   - Should use repository pattern

## Migration Recommendations

### Phase 1: Directory Organization

1. Move classes to appropriate subdirectories
2. Update all references
3. Update package.xml if needed

### Phase 2: Repository Pattern Implementation

1. Create repositories for `OnboardingApplicationService`
2. Create repositories for `OnboardingRulesService`
3. Refactor services to use repositories
4. Update `OnboardingStatusEvaluator` to use repositories

### Phase 3: Validation

1. Create validation rule directory
2. Move validation rule classes
3. Ensure all follow interface pattern

## Best Practices Summary

1. ✅ **Always use `with sharing`** unless explicitly needed otherwise
2. ✅ **Domain services consolidate** related functionality (e.g., `VendorDomainService`)
3. ✅ **Services expose @AuraEnabled methods** for direct LWC integration
4. ✅ **Services expose @InvocableMethod** for Flow integration
5. ✅ **Services delegate to repositories** for all data access
6. ✅ **Controllers only for complex coordination** of multiple services
7. ✅ **Repositories handle** all SOQL and DML
8. ✅ **Strategies encapsulate** varying behaviors (follows OCP)
9. ✅ **Classes organized** in appropriate subdirectories
10. ✅ **Naming conventions** followed consistently
11. ✅ **Error handling** with meaningful messages
12. ✅ **Input validation** at service boundaries
13. ✅ **Test classes** co-located with source classes
14. ✅ **Eliminate unnecessary layers** - avoid thin orchestrators and facade services

## Related Documentation

- [Architecture Overview](./overview.md)
- [Layered Architecture](./layers.md)
- [Apex Classes Documentation](../components/apex-classes.md)
- [API Reference](../api/apex-api.md)
