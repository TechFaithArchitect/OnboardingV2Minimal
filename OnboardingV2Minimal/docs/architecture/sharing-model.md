# Onboarding Objects Sharing Model

## Overview

This document describes the Organization-Wide Defaults (OWD), sharing rules, and access patterns for the onboarding-related custom objects. The sharing model ensures data security while enabling appropriate access for internal users and Experience Cloud users (dealers).

## Object Sharing Models

### Requirement_Field_Value__c

**OWD**: `ControlledByParent` (automatic - Master-Detail to Onboarding_Requirement__c)

**Parent Relationship**: Master-Detail to `Onboarding_Requirement__c`

**Rationale**: 
- Contains sensitive data (SSN, encrypted values)
- Dealer-specific data
- Access controlled by parent Onboarding_Requirement__c
- Automatic cascade delete when parent is deleted

**Sharing Rules**:
- **Requirement_Field_Value_Dealer_Access** (Criteria-Based)
  - Criteria: `Onboarding_Requirement__r.Onboarding__r.Account__c = $User.AccountId AND Onboarding_Requirement__r.Onboarding__r.Account__r.RecordType.DeveloperName = 'Dealer'`
  - Access Level: Read/Write
  - Purpose: Allow Experience Cloud users to view and edit their own field values

**Access Patterns**:
- Internal Users: Access via Onboarding_Requirement__c parent record access
- Experience Cloud Users: Access via sharing rule based on Account relationship
- System/Integration: Full access via integration user profiles

### Requirement_Field__c

**OWD**: `ControlledByParent` (automatic - Master-Detail to Vendor_Program_Requirement__c)

**Parent Relationship**: Master-Detail to `Vendor_Program_Requirement__c`

**Rationale**:
- Metadata-like object (defines field structure)
- Shared across vendor programs
- Access controlled by parent Vendor_Program_Requirement__c
- Automatic cascade delete when parent is deleted

**Sharing Rules**: None required (metadata-like, accessed via parent)

**Access Patterns**:
- Internal Users: Access via Vendor_Program_Requirement__c parent record access
- Experience Cloud Users: Indirect access via Requirement_Field_Value__c (read-only view of field definitions)
- System/Integration: Full access via integration user profiles

### Requirement_Field_Group__c

**OWD**: `ControlledByParent` (automatic - Master-Detail to Vendor_Program_Requirement__c)

**Parent Relationship**: Master-Detail to `Vendor_Program_Requirement__c`

**Rationale**:
- Metadata-like object (defines field groupings)
- Shared across vendor programs
- Access controlled by parent Vendor_Program_Requirement__c
- Automatic cascade delete when parent is deleted

**Sharing Rules**: None required (metadata-like, accessed via parent)

**Access Patterns**:
- Internal Users: Access via Vendor_Program_Requirement__c parent record access
- Experience Cloud Users: Indirect access via Requirement_Field_Value__c (read-only view of groupings)
- System/Integration: Full access via integration user profiles

### Follow_Up_Queue__c

**OWD**: `Private`

**Parent Relationships**: 
- Lookup to `Onboarding_Requirement__c` (optional)
- Lookup to `Onboarding__c` (required)

**Rationale**:
- Contains communication history (SMS, Email, In-App notifications)
- Dealer-specific data
- Private OWD ensures only owners and explicitly shared records are accessible
- Manual sharing or sharing rules required for access

**Sharing Rules**:
- **Follow_Up_Queue_Dealer_Read_Access** (Criteria-Based)
  - Criteria: `Onboarding__r.Account__c = $User.AccountId AND Onboarding__r.Account__r.RecordType.DeveloperName = 'Dealer'`
  - Access Level: Read Only
  - Purpose: Allow Experience Cloud users to view (but not edit) their own follow-up queue records

**Access Patterns**:
- Internal Users: Access via record ownership or manual sharing
- Experience Cloud Users: Read-only access via sharing rule based on Account relationship
- System/Integration: Full access via integration user profiles

## Master-Detail Relationships

### Cascade Delete Behavior

When a parent record is deleted, all child records are automatically deleted:

1. **Onboarding_Requirement__c** deleted → All `Requirement_Field_Value__c` records deleted
2. **Vendor_Program_Requirement__c** deleted → All `Requirement_Field__c` and `Requirement_Field_Group__c` records deleted

**Testing**: Verify cascade delete behavior in test classes.

## Experience Cloud Access

### User Context

Experience Cloud users have:
- `$User.AccountId` - References the Contact's Account
- `$User.ContactId` - References the Contact record

### Sharing Rule Criteria

Sharing rules use cross-object relationship traversal:
- `Onboarding_Requirement__r.Onboarding__r.Account__c` - Traverses from Requirement_Field_Value__c → Onboarding_Requirement__c → Onboarding__c → Account__c
- `Onboarding__r.Account__c` - Traverses from Follow_Up_Queue__c → Onboarding__c → Account__c

### RecordType Filtering

All sharing rules filter by `RecordType.DeveloperName = 'Dealer'` to ensure only dealer accounts are included.

**Note**: Verify the actual RecordType DeveloperName in your org (may be 'Dealer' or 'POE_Dealer').

## Manual Sharing Scenarios

### When Manual Sharing is Required

1. **Temporary Access**: Granting temporary access to specific records for troubleshooting
2. **Cross-Account Collaboration**: Rare scenarios where dealers need to collaborate
3. **Admin Override**: Admins granting access for support purposes

### Manual Sharing Process

1. Navigate to record detail page
2. Click "Sharing" button
3. Add users or public groups
4. Set access level (Read/Read & Write)
5. Save

## Testing Procedures

### Test Scenarios

1. **Cascade Delete Test**:
   - Create parent record with child records
   - Delete parent record
   - Verify all child records are deleted

2. **Experience Cloud Access Test**:
   - Create Experience Cloud user with Contact → Account relationship
   - Create Onboarding__c record linked to Account
   - Create Requirement_Field_Value__c and Follow_Up_Queue__c records
   - Log in as Experience Cloud user
   - Verify user can see their own records
   - Verify user cannot see other dealers' records

3. **Sharing Rule Test**:
   - Create test data matching sharing rule criteria
   - Verify records are automatically shared
   - Test edge cases (null Account, wrong RecordType, etc.)

### Test Classes

Create test classes to validate:
- `RequirementFieldValueSharingTest.cls` - Test Requirement_Field_Value__c sharing
- `FollowUpQueueSharingTest.cls` - Test Follow_Up_Queue__c sharing
- `CascadeDeleteTest.cls` - Test Master-Detail cascade delete

## Security Considerations

### Sensitive Data

- **Requirement_Field_Value__c.Encrypted_Value__c**: Uses Shield Platform Encryption
- Field-level security (FLS) should be enforced in Apex code
- Use `FLSCheckUtil.cls` for bulk-safe FLS checks

### Audit Trail

- Track History enabled on key fields (Validation_Status__c, Follow_Up_Type__c, Status__c)
- Sharing changes are logged in Setup → Security → Sharing → Sharing History

### Compliance

- Sharing rules ensure dealers only see their own data
- No cross-dealer data leakage
- All access is logged and auditable

## Maintenance

### Regular Reviews

- Quarterly review of sharing rules effectiveness
- Monitor sharing rule performance (Setup → Sharing → Sharing Rules → View Performance)
- Review manual sharing records for cleanup

### Updates

When updating sharing rules:
1. Document changes in this file
2. Test in sandbox first
3. Update test classes
4. Deploy to production during maintenance window

## Related Documentation

- [OWD Configuration Guide](../reports/Phase_0_OWD_Configuration_Guide.md)
- [Sharing Rules Setup Guide](../reports/Phase_0_Sharing_Rules_Setup_Guide.md)
- [Field-Level Security Documentation](./field-level-security.md) (to be created)

