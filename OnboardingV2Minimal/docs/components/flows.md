# Salesforce Flows

## Overview

The onboarding system uses Salesforce Flows for automation across three architectural layers: Application Layer, Business Logic Layer, and Domain Layer. Flows follow a consistent naming convention and handle various automation scenarios.

**Note:** Flow implementations are being redesigned for V2 and will be rebuilt around the updated object model. Treat the flow references here as provisional; documentation will be updated after the redesign.

## Naming Convention

### Application Layer Flows
**Pattern**: `APP_[Object]_[Description]`

**Examples:**
- `APP_Onboarding` - Main onboarding orchestration flow

### Business Logic Layer Flows
**Pattern**: `BLL_[Object]_[Trigger]_[Description]`

**Examples:**
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records` - Updates related records
- `BLL_External_Contact_Credential_RCD_Logical_Process` - Runs supplemental onboarding logic
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
- `DOMAIN_Onboarding_SFL_Get_Records` - Gets onboarding records
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

**Purpose**: Updates onboarding status (and related Contract application status) based on agreement, contract, opportunity, and ERP setup signals.

**Logic:**
1. Skips processing when the user has `Onboarding_Bypass_Flow` permission or the record is already in a terminal status (Setup Complete, Expired, Denied, or Cancelled).
2. Otherwise evaluates conditions in sequence and updates `Onboarding_Status__c` (plus matching `Contract.Application_Status__c`):
   - Denied: background/credit/compliance checks fail.
   - Paperwork Sent: agreement is sent or out for signature.
   - Pending Initial Review: agreement signed and contract/opportunity not finalized.
   - Setup Complete: ERP setup complete with an activated contract and qualifying contract type/retail option.
   - Pending Sales: assigned team is Sales.
   - In Process: contract/opportunity checks indicate active processing.
   - New: agreement is draft or missing.
   - Cancelled or Expired: agreement status indicates cancellation or expiration.

**Bypass Conditions:**
- Permission: `Onboarding_Bypass_Flow`
- Status: Setup Complete, Expired, Denied, or Cancelled
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

### DOMAIN_Onboarding_SFL_Get_Records

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

### DOMAIN_External_Contact_Credential_Type_RCD_Before_Save_Flow_to_Prevent_Duplicat

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

## Flow Inventory (Repo)

This list reflects the current contents of `force-app/main/default/flows`.

- `APP_Onboarding` - APPLICATION LAYER - Onboarding Object - This flow invokes the business logic layer and the domain layer to update and maintain the Onboarding Object records.
- `Action_Plan_Subflow_Create_Action_Plan` - Action Plan - Subflow - Create Action Plan
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records` - Business Logic Layer - Contact Training Assignment Object - Record Trigger - Update Related Records
- `BLL_External_Contact_Credential_RCD_Logical_Process` - Business Logic Layer - External Contact Credential Object - Record Trigger - Logical Process
- `BLL_Order_RCD_GET_Onboarding_Record` - Business Logic Layer - Order Object - Record - GET - Onboarding Record
- `Contact_ScreenFlow_Create_Contacts_on_Accounts` - Contact - ScreenFlow - Create Contacts on Accounts
- `Contract_Onboarding_Age_Count_flow` - Record-triggered on Contract to stamp onboarding milestone dates (application, ACH/W9, agreement, background check, base account).
- `Create_Representative_User` - This flow creates the representative user when Activate Representative button is clicked
- `DOMAIN_Contact_SFL_CREATE_Training_Assignment_Records` - DOMAIN LAYER - Contact Object - Subflow - CREATE - Training Assignment Records
- `DOMAIN_Contact_SFL_GET_Account_Information_from_Contact_Record` - DOMAIN LAYER - Contact Object - SFL - GET - Account Information from Contact Record
- `DOMAIN_Contact_SFL_UPDATE_Contact_Fields_with_ECC_Information` - DOMAIN LAYER - Contact Object - Subflow - UPDATE - Contact Fields with ECC Information
- `DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates` - DOMAIN LAYER - External Contact Credential Object - Record Trigger - Before the Record is Saved Create the external Contact Credential Record's Unique Key and check to make sure it doesn't exist already.
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record` - DOMAIN LAYER - External Contact Credential Object - Sublfow - CREATE - Contact Training Assignment Record
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Required_External_Contact_Credenti` - DOMAIN LAYER - External Contact Credential Object - Subflow - CREATE - Required External Contact Credential
- `DOMAIN_External_Contact_Credential_SFL_GET_Contact_Record` - DOMAIN LAYER - External Contact Credential Object - Subflow - Get Contact Record
- `DOMAIN_External_Contact_Credential_SFL_GET_Vendor_Customization` - DOMAIN LAYER - External Contact Credential Object - Subflow - GET - Vendor Customization
- `DOMAIN_External_Contact_Credential_SFL_Send_Email_Communication` - DOMAIN LAYER - External Contact Credential Object - Subflow - Send Email Communication
- `DOMAIN_External_Contact_Credential_SFL_UPDATE_Process_Status_Per_Business` - DOMAIN LAYER - External Contact Credential Object - Subflow - UPDATE - Process Status Per Business Rule
- `DOMAIN_External_Contact_Credential_Type_RCD_Before_Save_Flow_to_Prevent_Duplicat` - DOMAIN LAYER - External Contact Credential Type Object - Record Trigger - Before a record is saved this flow checks to make sure that this value has not been created before and if it has been created before it will be prevented from being created.
- `DOMAIN_LearnUponContactEnrollment_SFL_CREATE_Contact_Training_Assignment_Record` - DOMAIN LAYER - LearnUponContactEnrollment Object - Subflow - Create the related Contact Training Assignment Record
- `DOMAIN_LearnUponContactEnrollment_SFL_UPDATE_Contact_Training_Assignment_Record` - DOMAIN LAYER - LearnUponContactEnrollment Object - Subflow - Update the related Contact Training Assignment Record
- `DOMAIN_Onboarding_SFL_CREATE_External_Contact_Credentials` - DOMAIN LAYER - Onboarding Object - Subflow - CREATE - External Contact Credentials
- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order` - DOMAIN LAYER - Onboarding Object - Subflow - CREATE - Order and Assign Product to Order
- `DOMAIN_Onboarding_SFL_Get_Records` - DOMAIN LAYER - Onboarding Object - Subflow - Get Records
- `DOMAIN_Onboarding_SFL_Send_Email_Notification` - DOMAIN LAYER - Onboarding Record - Subflow - Send Email Notification
- `DOMAIN_Onboarding_SFL_UPDATE_Onboarding_Record` - DOMAIN - Onboarding - SFL - UPDATE - Onboarding Record
- `DOMAIN_Onboarding_SFL_Update_Onboarding_Record_s_Training_Status` - DOMAIN LAYER - Onboarding Object - Subflow - Update the Onboarding Record's Training Status to Complete if all LearnUponContactEnrollment Classes are passed.
- `DOM_Contact_Training_Assignment_SFL_UPDATE_External_Contact_Credential_Record` - DOMAIN LAYER - Contact Training Assignment Object - Subflow - UPDATE - External Contact Credential Record
- `DOM_LearnUponContactEnrollment_SFL_Connect_LearnUponContactEnrollment_to_Onbo` - DOMAIN LAYER - LearnUponContactEnrollment Object - Subflow - Connect LearnUponContactEnrollment to Onboarding
- `DOM_LearnUponContactEnrollment_SFL_GET_Contact_Training_Assignment_Record` - DOMAIN LAYER - LearnUponContactEnrollment Object - Subflow - Get the Related Contact Training Assignment Record if it exists.
- `DOM_Onboarding_SFL_CREATE_Training_Assignment_Records` - DOMAIN LAYER - Onboarding Object - Subflow - CREATE - Training Assignment Records
- `DOM_Onboarding_SFL_GET_Order_Status_Details` - DOMAIN LAYER - Onboarding Object - Subflow - GET - Order Status Details
- `Deactivate_Chuzo_Agent` - This flow is used by Account Services to deactivate Chuzo agents. [PER-3665 - PER-3865]
- `EXP_Contact_SCR_Select_Opportunity_Contact` - EXPERIENCE LAYER - Contact Object - Screen Flow - Select Opportunity Contact
- `EXP_Contact_SCR_Set_Up_Agent_Vendor_Programs` - EXPERIENCE LAYER - Contact Object - Screen Flow - Set Up Agent Vendor Programs
- `FSL_ServiceAppointment_RecordTriggeredInsert_SendDCCWelcomeNotification` - After ServiceAppointment insert, sends DCC welcome and reminder notifications (email/SMS).
- `FSL_WorkOrder_RecordTriggeredInsert_SendDCCWellcomeNotification` - After WorkOrder insert, sends DCC welcome and reminder notifications (email/SMS) for related Service Appointments.
- `LearnUpon_Portal_Membership_AutoLaunch_Assign_LearnUpon_Group_Number` - LearnUpon Portal Membership - AutoLaunch - Assign LearnUpon Group Number
- `LearnUpon_Record_Trigger_Update_LearnUponContactEnrollment_with_Onboarding_Recor` - LearnUpon - Record Trigger - Update LearnUponContactEnrollment with Onboarding Record
- `LearnUpon_Subflow_Send_Training_Email` - LearnUpon - Subflow - Send Training Email
- `New_Customer_Time_Based_Marketing_Emails` - New Customer Time Based Marketing Emails
- `Onboarding_Autolaunch_Close_All_Tasks` - Onboarding - Autolaunch - Close All Tasks
- `Onboarding_LearnUpon_Create_LearnUpon_Record_Assign_Group` - Onboarding - LearnUpon - Create LearnUpon Record / Assign Group
- `Onboarding_Record_Trigger_Update_Onboarding_Status` - Onboarding - Record Trigger - Update Onboarding Status
- `Onboarding_Subflow_Create_Related_Onboarding_Records` - Onboarding - Subflow - Create Related Onboarding Records
- `Onboarding_Subflow_Gather_Record_Details` - Onboarding - Subflow - Gather Record Details
- `Onboarding_Subflow_LearnUpon_Contact_Creation` - Onboarding - Subflow - LearnUpon Contact Creation
- `Onboarding_Subflow_Update_Status` - Onboarding - Subflow - Update Status
- `Opportunity_Flow_Orchestration` - Opportunity - Flow Orchestration
- `Opportunity_Screen_Flow_Create_New_Opportunity_Account_Record_For_Transfer` - Opportunity - Screen Flow - Create New Opportunity - Account Record
- `POE_Alternate_Email_Request` - Screen flow that emails the Office Owner to request an alternate contact email address.
- `Program_Compliance_Flows` - Program Compliance Flow
- `Service_Resource_Share` - ServiceResourceShareBatch to the Public Groups

## Related Documentation

- [Architecture Layers](../architecture/layers.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Data Model](../architecture/data-model.md)
