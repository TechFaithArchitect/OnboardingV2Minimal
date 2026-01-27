# Onboarding Objects Sharing Model (MVP)

## Overview

This document summarizes organization''‘wide defaults (OWD) and access patterns for MVP onboarding objects.

## Object Sharing Models

### Onboarding__c

**OWD**: `ControlledByParent` (Master''‘Detail to Account)

**Rationale**:
- Onboarding records follow Account access.

### Onboarding_Requirement__c

**OWD**: `ControlledByParent` (Lookup to Onboarding__c, enforced by parent access)

**Rationale**:
- Requirement records inherit access from the onboarding record.

### Vendor_Customization__c (Vendor Program)

**OWD**: `ControlledByParent` (Master''‘Detail or Lookup to Vendor__c depending on org config)

**Rationale**:
- Program access follows Vendor ownership and sharing rules.

### Vendor_Program_Requirement__c

**OWD**: `ControlledByParent` (Lookup to Vendor_Customization__c)

**Rationale**:
- Requirements are configuration scoped to a program.

### Follow_Up_Queue__c

**OWD**: `Private`

**Rationale**:
- Contains operational messaging state for SMS/email follow''‘ups.

## Experience Cloud Access (If Applicable)

- Dealer users inherit access through their Account.
- Use criteria''‘based sharing on `Onboarding__c` if dealer self''‘service is enabled.

## Related Documentation

- [Security Model](../security/security-model.md)
- [Data Model](./data-model.md)
