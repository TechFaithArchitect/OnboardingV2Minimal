# Apex Triggers

## Overview

The onboarding system uses Apex triggers sparingly. Triggers are thin and delegate logic to handler classes.

## Triggers in This Repo

### TerritoryAssignmentsTrigger

**Location:** `force-app/main/default/triggers/TerritoryAssignmentsTrigger.trigger`

**Object:** `Territory_Assignments__c`

**Events:** After Insert, After Update

**Purpose:** Syncs communication territory roles for assigned users when territory assignments change.

**Handler:** `EmailCommTerritoryRoleHelper.syncRoles(...)`

## Trigger Pattern

1. Trigger is thin and delegates to handler
2. Handler contains business logic
3. Handler methods are bulkified

## Related Documentation

- [Apex Classes](./apex-classes.md)
- [Architecture Overview](../architecture/overview.md)
