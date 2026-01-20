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

**Location:** `force-app/unpackaged/triggers/EnforceSingleTargetProgramPerGroup.trigger`

**Object:** Vendor_Program_Group__c

**Events:** Before Insert, Before Update

**Purpose:** Ensures only one target program per group.

**Handler:** Logic implemented directly in trigger (consider refactoring to handler)

**Logic:**
- Validates that only one target program is assigned per group
- Prevents duplicate target program assignments

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

Bulkification
Always process collections, not single records
Use maps for efficient lookups
Minimize SOQL queries in loops
Related Documentation
Apex Classes
Architecture Overview
