# Salesforce Flows

## Overview

The onboarding system uses Salesforce Flows for automation across three architectural layers: Application Layer, Business Logic Layer, and Domain Layer. Flows follow a consistent naming convention and handle various automation scenarios.

## Naming Convention

### Application Layer Flows
**Pattern**: `APP_[Object]_[Description]`

**Examples:**
- `APP_Onboarding` - Main onboarding orchestration flow

### Business Logic Layer Flows
**Pattern**: `BLL_[Object]_[Trigger]_[Description]`

**Examples:**
- `BLL_Training_Assignment_Credential_RCD_Unique_Key_Creation` - Creates unique keys
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records` - Updates related records
- `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements` - Executes supplemental requirements
- `BLL_Order_RCD_GET_Onboarding_Record` - Gets onboarding record from order

### Domain Layer Flows
**Pattern**: `DOMAIN_[Object]_[Type]_[Operation]_[Description]`

**Types:**
- `SFL` - Subflow
- `RCD` - Record-triggered flow

**Operations:**
- `CREATE` - Create records
- `UPDATE` - Update records
- `GET` - Get/query records
- `SEND` - Send communications

**Examples:**
- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order` - Creates order
- `DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record` - Updates onboarding record
- `DOMAIN_Onboarding_SFL_GET_Records` - Gets onboarding records
- `DOMAIN_Onboarding_SFL_Send_Email_Notification` - Sends email notifications
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record` - Creates training assignment
- `DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates` - Prevents duplicates

## Key Flows

### APP_Onboarding

**Type**: Orchestrated Flow  
**Trigger**: Record-triggered on Onboarding__c

**Purpose**: Main application layer flow that orchestrates onboarding record updates.

**Stages:**
1. **Create Order for Onboarding Record** - Creates order and assigns products
2. **Send Email Notification** - Sends notification emails
3. **Close All Onboarding Tasks** - Closes related tasks
4. Additional orchestrated stages for various operations

**Key Subflows:**
- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order`
- `DOMAIN_Onboarding_SFL_Send_Email_Notification`
- `Onboarding_Autolaunch_Close_All_Tasks`

### Onboarding_Record_Trigger_Update_Onboarding_Status

**Type**: Record-Triggered Flow  
**Trigger**: After Save on Onboarding__c

**Purpose**: Updates onboarding status based on rules engine.

**Logic:**
1. Checks bypass conditions:
   - User has `Onboarding_Bypass_Flow` permission
   - Status is "Setup Complete", "Expired", or "Denied"
2. If not bypassed, calls Apex:
   - `OnboardingStatusEvaluator.evaluateAndApplyStatus()`

**Bypass Conditions:**
- Permission: `Onboarding_Bypass_Flow`
- Status: "Setup Complete"
- Status: "Expired"
- Status: "Denied"

### DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order

**Type**: Subflow  
**Purpose**: Creates order record and assigns products for onboarding.

**Input Variables:**
- `OnboardingRecord` - Onboarding record

**Operations:**
1. Creates Order record
2. Assigns products to order
3. Updates onboarding record with order reference

### DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record

**Type**: Subflow  
**Purpose**: Updates onboarding record fields.

**Input Variables:**
- `OnboardingRecord` - Onboarding record to update
- Update fields as needed

### DOMAIN_Onboarding_SFL_GET_Records

**Type**: Subflow  
**Purpose**: Queries and returns onboarding-related records.

**Output Variables:**
- Returns collection of records

### DOMAIN_Onboarding_SFL_Send_Email_Notification

**Type**: Subflow  
**Purpose**: Sends email notifications for onboarding events.

**Input Variables:**
- `OnboardingRecord` - Onboarding record
- `EmailTemplate` - Email template to use
- `Recipients` - Recipient list

### DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record

**Type**: Subflow  
**Purpose**: Creates training assignment records for contacts based on credentials.

**Logic:**
1. Checks if onboarding record exists
2. Gets account associated with contact
3. Gets active onboarding records
4. Creates training assignment record

### DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates

**Type**: Record-Triggered Flow (Before Save)  
**Trigger**: Before Save on POE_External_Contact_Credential__c

**Purpose**: Prevents duplicate credential records.

**Logic:**
1. Creates unique key from contact and credential type
2. Checks for existing records with same unique key
3. Prevents save if duplicate found

### DOMAIN_External_Contact_Credential_Type_RCD_Before_Save_Flow_to_Prevent_Duplicate

**Type**: Record-Triggered Flow (Before Save)  
**Trigger**: Before Save on External_Contact_Credential_Type__c

**Purpose**: Prevents duplicate credential types.

### Onboarding_Subflow_Create_Related_Onboarding_Records

**Type**: Subflow  
**Purpose**: Creates related onboarding records.

### Onboarding_Subflow_Update_Status

**Type**: Subflow  
**Purpose**: Updates onboarding status.

### Onboarding_Subflow_LearnUpon_Contact_Creation

**Type**: Subflow  
**Purpose**: Creates LearnUpon contact records.

## Flow Categories

### Record-Triggered Flows

**Before Save:**
- Validation and duplicate prevention
- Unique key creation
- Field calculations

**After Save:**
- Status updates
- Related record creation
- Email notifications

### Autolaunched Flows

**Purpose**: Background automation
- Task management
- Record updates
- Data synchronization

### Screen Flows

**Purpose**: User interaction
- Contact creation
- Opportunity creation
- Onboarding record updates

### Subflows

**Purpose**: Reusable flow logic
- Common operations
- Data transformations
- Business rule execution

## Flow Best Practices

### Naming
- Follow naming convention
- Use descriptive names
- Include operation type (CREATE, UPDATE, GET, etc.)

### Error Handling
- Use decision elements for error conditions
- Provide clear error messages
- Log errors appropriately

### Performance
- Use bulkified operations
- Minimize SOQL queries
- Use collections efficiently

### Maintainability
- Document flow purpose
- Use clear element labels
- Organize flows by layer

## Related Documentation

- [Architecture Layers](../architecture/layers.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Data Model](../architecture/data-model.md)
