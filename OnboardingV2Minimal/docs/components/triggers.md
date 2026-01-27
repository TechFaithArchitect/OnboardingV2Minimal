# Apex Triggers

## Overview

The onboarding system uses Apex triggers sparingly, following best practices by delegating logic to handler classes. Triggers are kept thin and focus on calling appropriate handlers.

## Trigger Pattern

All triggers follow the handler pattern:
1. Trigger is thin and delegates to handler
2. Handler contains business logic
3. Handler methods are bulkified

## Triggers

### EnforceSingleTargetProgramPerGroup

**Location:** `force-app/main/default/triggers/EnforceSingleTargetProgramPerGroup.trigger`

**Object:** Vendor_Program_Group__c

**Events:** Before Insert, Before Update

**Purpose:** Ensures only one target program per group.

**Handler:** `EnforceSingleTargetProgramPerGroupTriggerHandler.beforeInsertOrUpdate(...)`

### OnboardingRequirementTrigger

**Location:** `force-app/main/default/triggers/OnboardingRequirementTrigger.trigger`

**Object:** Onboarding_Requirement__c

**Events:** After Insert, After Update

**Purpose:** Detects status changes and evaluates follow-up rules.

**Handler:** `OnboardingRequirementTriggerHandler.handleAfterSave(...)`

### TerritoryAssignmentsTrigger

**Location:** `force-app/main/default/triggers/TerritoryAssignmentsTrigger.trigger`

**Object:** Territory_Assignments__c

**Events:** After Insert, After Update

**Purpose:** Syncs communication territory roles for assigned users.

**Handler:** `EmailCommTerritoryRoleHelper.syncRoles(...)`

### VendorProgramGroupMemberTrigger

**Location:** `force-app/main/default/triggers/VendorProgramGroupMemberTrigger.trigger`

**Object:** Vendor_Program_Group_Member__c

**Events:** Before Insert, Before Update

**Purpose:** Applies onboarding rule engine logic for group member changes.

**Handler:** `OnboardingAppRuleEngineHandler.apply(...)`

### VersioningTrigger

**Location:** `force-app/main/default/triggers/VersioningTrigger.trigger`

**Object:** Vendor_Customization__c

**Events:** Before Insert, Before Update, After Insert

**Purpose:** Applies versioning logic and post-insert updates for vendor programs.

**Handler:** `VersioningTriggerHandler.run(...)`, `VersioningTriggerHandler.afterInsert(...)`

## Best Practices

### Trigger Design

1. **Thin Triggers**: Keep trigger logic minimal
2. **Handler Pattern**: Delegate to handler classes
3. **Bulkification**: Handle bulk operations
4. **Error Handling**: Proper exception handling

### Handler Pattern

trigger ExampleTrigger on Object__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ExampleHandler.handleBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ExampleHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
### Bulkification

- Always process collections, not single records
- Use maps for efficient lookups
- Minimize SOQL queries in loops

## Related Documentation

- [Apex Classes](./apex-classes.md)
- [Architecture Overview](../architecture/overview.md)
