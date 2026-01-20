# Security Model

This document describes the security architecture for OnboardingV2, including object-level security, field-level security, sharing rules, and permission sets.

## Overview

The OnboardingV2 security model follows a layered approach:

1. **Object-Level Security**: Controlled by sharing model and profiles
2. **Field-Level Security**: Managed through permission sets and profiles
3. **Record-Level Security**: Controlled by parent relationships and sharing rules
4. **Apex Security**: Enforced through `with sharing` and `without sharing` keywords

## Object-Level Security

### Sharing Models

#### ReadWrite (Public Read/Write)

Most configuration objects use ReadWrite sharing, allowing all users with object permissions to read and write:

- `Vendor_Program_Group__c`
- `Vendor_Program_Group_Member__c`
- `Onboarding_Application_Process__c`
- `Onboarding_Application_Stage__c`
- `Onboarding_Component_Library__c`
- `Onboarding_Status_Rules_Engine__c`
- `Onboarding_Status_Rule__c`
- `Training_System__c`
- `External_Contact_Credential_Type__c`
- `ECC_Field_Configuration_Group__c`
- `ECC_Field_Display_Configuration__c`
- `Training_Assignment__c`

**Rationale**: These are configuration objects that need to be accessible to administrators and power users for setup and management.

#### ControlledByParent

Data objects inherit sharing from their parent records:

- `Onboarding__c` - Controlled by Account (Master-Detail)
- `Vendor_Customization__c` - Controlled by parent Vendor__c
- `Onboarding_Requirement__c` - Controlled by Onboarding__c
- `POE_External_Contact_Credential__c` - Controlled by Contact
- `Training_Requirement__c` - Controlled by parent
- `Required_Credential__c` - Controlled by parent

**Rationale**: These objects contain sensitive business data that should follow the same access rules as their parent records.

#### Private

Some objects use Private sharing (no explicit sharing rules found):

- Most objects default to org-wide defaults
- Access controlled through permission sets and profiles

## Field-Level Security

### Approach

Field-Level Security (FLS) is managed through:

1. **Permission Sets**: Role-based access control
2. **Profiles**: Base access levels
3. **Apex Classes**: Enforce FLS with `with sharing`

### Key Fields Requiring FLS

#### Sensitive Data Fields

- **Onboarding Status**: `Onboarding__c.Onboarding_Status__c`
- **Requirement Status**: `Onboarding_Requirement__c.Status__c`
- **Vendor Program Configuration**: `Vendor_Customization__c.*`
- **Credential Information**: `POE_External_Contact_Credential__c.*`

#### Configuration Fields

- **Rules Engine Logic**: `Onboarding_Status_Rules_Engine__c.Custom_Evaluation_Logic__c`
- **Process Configuration**: `Onboarding_Application_Process__c.*`
- **Stage Configuration**: `Onboarding_Application_Stage__c.*`

### FLS Enforcement

Apex classes use `with sharing` to enforce FLS:

```apex
public with sharing class OnboardingApplicationService {
    // FLS automatically enforced
}
```

**Note**: All service and controller classes use `with sharing` to ensure FLS is respected.

## Permission Sets

### Onboarding_Account_Services

**Purpose**: Permissions for Account Services team members

**Key Permissions**:
- Full access to Onboarding__c records
- Access to Vendor_Customization__c
- Access to Onboarding_Requirement__c
- Apex class access for onboarding controllers
- LWC component access

**Use Case**: Team members who manage onboarding processes and requirements

### Onboarding_Compliance_Team

**Purpose**: Permissions for Compliance team members

**Key Permissions**:
- Read/Write access to Onboarding__c
- Access to requirement status management
- Access to status rules configuration
- View access to vendor program data

**Use Case**: Team members who review and approve onboarding requirements

### Onboarding_Program_Sales_Team

**Purpose**: Permissions for Program Specialists (Sales)

**Key Permissions**:
- Access to Vendor_Customization__c (Vendor Program) records
- Access to onboarding flow components
- Read access to onboarding status
- Limited write access

**Use Case**: Program Specialists who sell programs to Dealers (Accounts) and initiate onboarding processes

### Onboarding_Program_Specialists

**Purpose**: Permissions for Program Managers (permission set name retained for legacy reasons)

**Key Permissions**:
- Full access to vendor program configuration
- Access to status rules management
- Access to requirement groups
- Configuration management permissions

**Use Case**: Program Managers who manage vendor relationships and configure vendor program requirements, rules engines, and onboarding setup

### Onboarding_Customer_Service

**Purpose**: Permissions for Customer Service team

**Key Permissions**:
- Read access to onboarding records
- Limited write access to requirement statuses
- Access to contact credential management
- View access to vendor program data

**Use Case**: Customer service representatives who assist with onboarding

### Onboarding_Finance_Team

**Purpose**: Permissions for Finance team

**Key Permissions**:
- Read access to onboarding records
- Access to financial-related fields
- View access to vendor program data
- Limited configuration access

**Use Case**: Finance team members who review financial aspects of onboarding

### PV_Standard_User

**Purpose**: Base permissions for all PV users

**Key Permissions**:
- Basic object access
- Standard field permissions
- Application visibility
- Base functionality access

**Use Case**: Default permissions for all users in the system

## Sharing Rules

### Current State

**No explicit sharing rules are configured** in the codebase. This is intentional and follows these principles:

1. **Parent-Controlled Sharing**: Most data objects use ControlledByParent, inheriting access from parent records
2. **Permission Set Based**: Access is primarily controlled through permission sets
3. **Profile Based**: Base access is managed through profiles

### When to Add Sharing Rules

Consider adding sharing rules if:

1. **Cross-Hierarchy Access**: Users need access to records outside their normal hierarchy
2. **Public Read Access**: Certain records need to be readable by all users
3. **Role-Based Sharing**: Access needs to be granted based on user roles
4. **Criteria-Based Sharing**: Access based on record criteria

### Recommended Sharing Rules (If Needed)

If sharing rules are required in the future:

1. **Public Read for Configuration Objects**:
   - Allow all users to read `Onboarding_Component_Library__c`
   - Allow all users to read `Onboarding_Application_Process__c` (if processes are public)

2. **Role-Based Sharing for Onboarding Records**:
   - Share Onboarding__c records with users in same role hierarchy
   - Share based on Account ownership

3. **Team-Based Sharing**:
   - Share vendor programs with team members
   - Share onboarding records with assigned teams

## Apex Security

### With Sharing Enforcement

All service and controller classes use `with sharing`:

```apex
public with sharing class OnboardingApplicationService {
    // Automatically enforces FLS and sharing rules
}
```

**Classes Using `with sharing`**:
- `OnboardingApplicationService`
- `OnboardingRulesService`
- `OnboardingRequirementsPanelController`
- `OnboardingStatusRulesEngineController`
- `OnboardingStatusRuleController`
- All other service and controller classes

### Without Sharing

Some utility classes may use `without sharing` for system operations, but these should be:
- Clearly documented
- Used only when necessary
- Protected by proper validation

## Data Access Patterns

### Master-Detail Relationships

Objects with Master-Detail relationships inherit sharing:

- `Onboarding__c` → `Account__c` (Master-Detail)
  - Sharing controlled by Account
  - Users with Account access can access Onboarding records

### Lookup Relationships

Objects with Lookup relationships require explicit sharing:

- `Onboarding_Requirement__c` → `Onboarding__c` (Lookup)
  - Access to requirements follows onboarding access
  - May need sharing rules if cross-account access required

### Parent-Controlled Sharing

Objects using ControlledByParent:

- `Onboarding__c` - Controlled by Account
- `Vendor_Customization__c` - Controlled by Vendor__c
- `POE_External_Contact_Credential__c` - Controlled by Contact

## Security Best Practices

### 1. Least Privilege Principle

- Grant minimum necessary permissions
- Use permission sets for role-based access
- Avoid granting "View All" or "Modify All" unless necessary

### 2. Regular Audits

- Review permission set assignments quarterly
- Audit field-level security settings
- Review sharing rule effectiveness
- Check for over-privileged users

### 3. Documentation

- Document all permission sets and their purposes
- Maintain list of users with elevated permissions
- Document any `without sharing` usage and rationale

### 4. Testing

- Test with different user profiles
- Verify FLS enforcement in Apex
- Test sharing rule behavior
- Validate permission set assignments

## Security Checklist for New Deployments

### Pre-Deployment

- [ ] Review all custom object sharing models
- [ ] Verify FLS settings for sensitive fields
- [ ] Check permission set assignments
- [ ] Review Apex class sharing keywords
- [ ] Validate profile permissions

### Post-Deployment

- [ ] Assign permission sets to appropriate users
- [ ] Verify object access for each user profile
- [ ] Test FLS enforcement
- [ ] Validate sharing rule behavior (if applicable)
- [ ] Review audit logs for access issues

### Ongoing

- [ ] Quarterly permission set review
- [ ] Annual security audit
- [ ] Monitor for security-related errors
- [ ] Update documentation as security model evolves

## Common Security Scenarios

### Scenario 1: User Needs to View All Onboardings

**Solution**: 
- Assign `Onboarding_Account_Services` permission set
- Or create sharing rule to share based on criteria
- Or grant "View All" on Onboarding__c object

### Scenario 2: User Needs to Configure Rules

**Solution**:
- Assign `Onboarding_Program_Specialists` permission set
- Grants access to rules engine configuration objects
- Provides necessary Apex class access

### Scenario 3: External User Needs Limited Access

**Solution**:
- Create custom permission set with minimal permissions
- Grant read-only access to specific objects
- Use ControlledByParent sharing for data isolation
- Restrict field access through FLS

### Scenario 4: Team-Based Access

**Solution**:
- Use permission sets for team membership
- Create sharing rules based on team assignment
- Or use public groups and sharing rules

## Troubleshooting Security Issues

### Issue: User Cannot See Onboarding Records

**Check**:
1. Object permissions in profile/permission set
2. Account access (if ControlledByParent)
3. Sharing rules (if configured)
4. Record ownership
5. Field-level security on key fields

### Issue: User Cannot Edit Requirements

**Check**:
1. Edit permission on Onboarding_Requirement__c
2. FLS on Status__c field
3. Apex class access (if using controllers)
4. Parent record access (Onboarding__c)

### Issue: Component Not Appearing

**Check**:
1. LWC component access in permission set
2. Apex class access for wire adapters
3. Object read permissions
4. Field read permissions for displayed data

## Related Documentation

- [Installation Guide](../setup/installation.md)
- [Configuration Guide](../setup/configuration.md)
- [Architecture Overview](../architecture/overview.md)
- [Apex Classes](../components/apex-classes.md)
