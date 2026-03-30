# Flow Catalog

Generated from `force-app/main/default/flows` metadata.

## Coverage

- Total flows in repo: 85
- Domain flows (`DOMAIN_*`): 52

## All Flow Responsibilities

| Flow API Name | Layer | Status | Responsibility |
|---|---|---|---|
| `BLL_Agreement_RCD_Logical_Process` | `BLL` | `Active` | BLL - Agreement - RCD - Logical Process \| AutoLaunchedFlow \| Trigger: echosign_dev1__SIGN_Agreement__c Update RecordAfterSave |
| `BLL_BRE_Evaluate_Business_Rules` | `BLL` | `Active` | BLL - BRE - Evaluate Business Rules \| AutoLaunchedFlow |
| `BLL_External_Contact_Credential_RCD_Logical_Process` | `BLL` | `Active` | BLL - External Contact Credential - RCD - Logical Process \| AutoLaunchedFlow \| Trigger: POE_External_Contact_Credential__c Update RecordAfterSave |
| `BLL_External_Contact_Credential_RCD_Prevent_Duplicates` | `BLL` | `Active` | BLL - External Contact Credential - RCD - Prevent Duplicates \| AutoLaunchedFlow \| Trigger: POE_External_Contact_Credential__c CreateAndUpdate RecordBeforeSave |
| `BLL_External_Contact_Credential_Type_RCD_Prevent_Duplicates` | `BLL` | `Active` | BLL - External Contact Credential Type - RCD - Prevent Duplicates \| AutoLaunchedFlow \| Trigger: External_Contact_Credential_Type__c CreateAndUpdate RecordBeforeSave |
| `BLL_LearnUponContactEnrollment_RCD_Connect_Logical_Records` | `BLL` | `Active` | BLL - LearnUponContactEnrollment - RCD - Connect Logical Records \| AutoLaunchedFlow \| Trigger: LearnUponP__LearnUponContactEnrollment__c Create RecordAfterSave |
| `BLL_LearnUponContactEnrollment_SCD_Review_Assign_Missing_Onboarding_Records` | `BLL` | `Draft` | BLL - LearnUponContactEnrollment - SCD - Review & Assign Missing Onboarding Records \| AutoLaunchedFlow \| Trigger: LearnUponP__LearnUponContactEnrollment__c Scheduled |
| `BLL_LearnUpon_Portal_Membership_SCD_Review_Update_Portal_Memberships` | `BLL` | `Active` | BLL - LearnUpon Portal Membership - SCD - Review & Update Portal Memberships \| AutoLaunchedFlow \| Trigger: LearnUponP__LearnUpon_Portal_Membership__c Scheduled |
| `BLL_LearnUpon_SFL_Logical_Process` | `BLL` | `Active` | BLL - LearnUpon - SFL - Logical Process \| AutoLaunchedFlow |
| `BLL_OmniSObject_ACTION_Send_Adobe_Agreement` | `BLL` | `Active` | BLL - OmniSObject - ACTION - Send Adobe Agreement \| AutoLaunchedFlow |
| `BLL_OmniSObject_RCD_SYNC_Training_Assignments` | `BLL` | `Active` | BLL - OmniSObject - RCD - SYNC - Training Assignments \| AutoLaunchedFlow \| Trigger: Training_Assignment__c CreateAndUpdate RecordAfterSave |
| `BLL_Onboarding_RCD_Logical_Process` | `BLL` | `Active` | BLL - Onboarding - RCD - Logical Process \| AutoLaunchedFlow \| Trigger: Onboarding__c CreateAndUpdate RecordAfterSave |
| `BLL_Onboarding_RCD_Prevent_Duplicates` | `BLL` | `Active` | BLL - Onboarding - RCD - Prevent Duplicates \| AutoLaunchedFlow \| Trigger: Onboarding__c CreateAndUpdate RecordBeforeSave |
| `BLL_Onboarding_Requirement_RCD_Logical_Process` | `BLL` | `Active` | BLL - Onboarding Requirement - RCD - Logical Process \| AutoLaunchedFlow \| Trigger: Onboarding_Requirement__c CreateAndUpdate RecordAfterSave |
| `BLL_Onboarding_Requirement_Subject_RCD_Logical_Process` | `BLL` | `Active` | BLL - Onboarding Requirement Subject - RCD - Logical Process \| AutoLaunchedFlow \| Trigger: Onboarding_Requirement_Subject__c Update RecordAfterSave |
| `BLL_Onboarding_SCD_Review_and_Assign_Missing_Training_Records` | `BLL` | `Active` | BLL - Onboarding - SCD - Review & Assign Missing Training Records \| AutoLaunchedFlow \| Trigger: Onboarding__c Scheduled |
| `BLL_Onboarding_SFL_Assign_LearnUpon_Credentials` | `BLL` | `Active` | BLL - Onboarding - SFL - Assign LearnUpon Credentials \| AutoLaunchedFlow |
| `BLL_Onboarding_SFL_Dispatch_Communication_By_Context` | `BLL` | `Active` | BLL - Onboarding - SFL - Dispatch Communication By Context \| AutoLaunchedFlow |
| `BLL_Onboarding_SFL_Dispatch_Communication_By_Event` | `BLL` | `Active` | BLL - Onboarding - SFL - Dispatch Communication By Event \| AutoLaunchedFlow |
| `BLL_Opportunity_RCD_Logical_Process` | `BLL` | `Active` | BLL - Opportunity - RCD - Logical Process \| AutoLaunchedFlow \| Trigger: Opportunity Create RecordAfterSave |
| `BLL_Order_RCD_Business_Logic` | `BLL` | `Active` | BLL - Order - RCD - Business Logic \| AutoLaunchedFlow \| Trigger: Order Update RecordAfterSave |
| `BLL_Training_Assignment_Onboarding_RCD_Prevent_Duplicates` | `BLL` | `Active` | BLL - Training Assignment Onboarding - RCD - Prevent Duplicates \| AutoLaunchedFlow \| Trigger: Training_Assignment_Onboarding__c CreateAndUpdate RecordBeforeSave |
| `BLL_Training_Assignment_RCD_Populate_Unique_Assignment_Key` | `BLL` | `Active` | BLL - Training Assignment - RCD - Populate Unique Assignment Key \| AutoLaunchedFlow \| Trigger: Training_Assignment__c CreateAndUpdate RecordBeforeSave |
| `BLL_Training_Assignment_SCD_Training_Reminder_Emails` | `BLL` | `Active` | BLL - Training Assignment - SCD - Training Reminder Emails \| AutoLaunchedFlow |
| `BLL_Vendor_Program_Requirement_RCD_Enforce_Contract_Agreement_Sequence` | `BLL` | `Active` | BLL - Vendor Program Requirement - RCD - Enforce Contract Agreement Sequence \| AutoLaunchedFlow \| Trigger: Vendor_Program_Requirement__c CreateAndUpdate RecordBeforeSave |
| `BLL_Vendor_Program_Training_Requirement_RCD_Prevent_Duplicates` | `BLL` | `Active` | BLL - Vendor Program Training Requirement - RCD - Prevent Duplicates \| AutoLaunchedFlow \| Trigger: Vendor_Program_Training_Requirement__c CreateAndUpdate RecordBeforeSave |
| `DOMAIN_OmniSObject_ACTION_Send_Communication_Template` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - ACTION - Send Communication Template \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Agreement` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Agreement \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Contact_Fields_with_ECC_Information` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Contact Fields with ECC Information \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Contact_Training_Assignment_Record` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Contact Training Assignment Record \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Contract` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Contract \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Dealer_Training` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Dealer Training \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_External_Contact_Credentials` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - External Contact Credentials \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Fault Message \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_LearnUponContactEnrollment` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - LearnUponContactEnrollment \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_LearnUpon_Contact_Enrollment_Membership_Record` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - LearnUpon Contact Enrollment Membership Record \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_LearnUpon_Group_Membership` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - LearnUpon Group Membership \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Onboarding Record \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Onboarding Requirement Subjects \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Onboarding Requirements \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Opportunity` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Opportunity \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Opportunity_Contact_Role` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Opportunity Contact Role \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Process_Status_Per_Business` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Process Status Per Business Rule \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Related Onboarding Requirement Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Required_External_Contact_Credenti` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Required External Contact Credential \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_CREATE_Training_Assignment_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Training Assignment Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_Create_Contact` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - CREATE - Contact \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - EVAL - Onb Req Subjects - By Evidence \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_For_Onb_Rec` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - EVAL - Onboarding Requirement Subjects \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - EVAL - Onb Req Subjects - Parent \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Account_Contact_Relationship` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Account Contact Relationship \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Account_Record` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Account Record \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Agreements` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Agreements \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_All_Related_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - All Related Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Communication_Dispatch_Policy` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Communication Dispatch Policy \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Communication_Event_Policies` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Communication Event Policies \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Communication_Recipients` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Communication Recipients \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Communication_Template` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Communication Template \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Communication_Templates` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Communication Templates \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Contact_Record` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Contact Record \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Contract_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Contract Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_External_Contact_Credential_Types` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - External Contact Credential Types \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_LearnUponContactEnrollment_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - LearnUponContactEnrollment Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_LearnUpon_Portal_Membership` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - LearnUpon Portal Membership \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Onboarding_Fullfilment_Policy` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Onboarding Fullfilment Policy \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Onboarding_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Onboarding Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Onboarding Requirement \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement_Subjects` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Onboarding Requirement Subjects \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Opportunity_Record` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Opportunity Record \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Primary_Opportunity_Contact` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Opportunity Contact \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Training_Assignment_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Training Assignment Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Training_Requirement_Records` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Training Requirement Records \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Training_Systems` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Training Systems \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Vendor_Program` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Vendor Program \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Vendor_Program_Group_Members` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Vendor Program Group Members \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_GET_Vendor_Program_Requirements` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - GET - Vendor Program Requirements \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_Send_Email_Communication` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - Send Email Communication \| AutoLaunchedFlow |
| `DOMAIN_OmniSObject_SFL_Submit_for_Approval` | `DOMAIN` | `Active` | DOMAIN - OmniSObject - SFL - Submit for Approval \| AutoLaunchedFlow |
| `EXP_Contact_SCR_Create_Contact` | `EXP` | `Active` | EXP - Contact - SCR - Create Contact \| Flow |
| `EXP_Contract_ACTION_Send_Adobe_Agreement` | `EXP` | `Active` | EXP - Contract - ACTION - Send Adobe Agreement \| Flow |
| `EXP_Contract_SCR_Send_Adobe_Agreement` | `EXP` | `Active` | EXP - Contract - SCR - Send Adobe Agreement \| Flow |
| `EXP_Opportunity_Contacts_SCR_CREATE_Opportunity_Contacts` | `EXP` | `Active` | EXP - Opportunity Contacts - SCR - CREATE - Opportunity Contacts \| Flow |
| `EXP_Opportunity_SCR_Create_Record` | `EXP` | `Draft` | EXP - Opportunity - SCR - Create Record \| Flow |
| `Onboarding_Subflow_Create_Related_Onboarding_Records` | `Onboarding` | `Active` | Onboarding - Subflow - Create Related Onboarding Records \| AutoLaunchedFlow |
| `Opportunity_Subflow_Update_Onboarding_Records` | `Opportunity` | `Active` | Opportunity - Subflow - Update Onboarding Records \| AutoLaunchedFlow |

## Domain Flow Contracts

For each domain flow, inputs and outputs below represent variable contracts declared in metadata (`isInput` / `isOutput`).

### `DOMAIN_OmniSObject_ACTION_Send_Communication_Template`
- Responsibility: DOMAIN - OmniSObject - ACTION - Send Communication Template
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CommunicationTemplateRecord` | `Communication_Template__c` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `RecipientId` | `String` | `Single` |
| `VendorProgram` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ErrorMessage` | `String` | `Single` |
| `SendFailed` | `Boolean` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Agreement`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Agreement
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `ContractRecord` | `Contract` | `Single` |
| `VendorProgram` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Contact_Fields_with_ECC_Information`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Contact Fields with ECC Information
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |
| `ECCRecord` | `POE_External_Contact_Credential__c` | `Single` |
| `ECCRecordTypeName` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Contact_Training_Assignment_Record`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Contact Training Assignment Record
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `LearnUponContactEnrollmentRecord` | `LearnUponP__LearnUponContactEnrollment__c` | `Single` |
| `TrainingAssignmentRecord` | `Training_Assignment__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Contract`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Contract
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountRecord` | `Account` | `Single` |
| `ContractRecordCollection` | `Contract` | `Collection` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OpportunityContactRole` | `OpportunityContactRole` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `VendorProgram` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContractRecord` | `Contract` | `Single` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Dealer_Training`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Dealer Training
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ErrorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_External_Contact_Credentials`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - External Contact Credentials
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `PrincipalOwnerId` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `ExternalContactCredentalTypes` | `External_Contact_Credential_Type__c` | `Collection` |
| `ExternalContactCredentialRecords` | `POE_External_Contact_Credential__c` | `Collection` |
| `ExternalContactCredentialTypeRecord` | `External_Contact_Credential_Type__c` | `Single` |
| `RequiredCredentialRecordCollection` | `Required_Credential__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Fault_Message`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Fault Message
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContextKey` | `String` | `Single` |
| `DefaultErrorMessage` | `String` | `Single` |
| `FaultMessage` | `String` | `Single` |
| `InterviewGuid` | `String` | `Single` |
| `OnboardingId` | `String` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OpportunityId` | `String` | `Single` |
| `SourceElementApiName` | `String` | `Single` |
| `SourceElementLabel` | `String` | `Single` |
| `SourceFlowApiName` | `String` | `Single` |
| `UserFacingMessageOverride` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ErrorLogId` | `String` | `Single` |
| `FaultQueued` | `Boolean` | `Single` |
| `ResolvedFaultMessage` | `String` | `Single` |
| `ResolvedTriggerReason` | `String` | `Single` |
| `UserFacingMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_LearnUponContactEnrollment`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - LearnUponContactEnrollment
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `LearnUponContactEnrollment` | `LearnUponP__LearnUponContactEnrollment__c` | `Single` |
| `LearnUponContactEnrollmentCollection` | `LearnUponP__LearnUponContactEnrollment__c` | `Collection` |
| `LearnUponPortalMembershipRecord` | `LearnUponP__LearnUpon_Portal_Membership__c` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `TrainingRequirementRecord` | `Training_Requirement__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `LearnUponContactEnrollment` | `LearnUponP__LearnUponContactEnrollment__c` | `Single` |
| `LearnUponContactEnrollmentCollection` | `LearnUponP__LearnUponContactEnrollment__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_LearnUpon_Contact_Enrollment_Membership_Record`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - LearnUpon Contact Enrollment Membership Record
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `LearnUponPortalMembership` | `LearnUponP__LearnUpon_Portal_Membership__c` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_LearnUpon_Group_Membership`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - LearnUpon Group Membership
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `VendorTrainingRequirementRecord` | `Training_Requirement__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Record`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Onboarding Record
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountRecord` | `Account` | `Single` |
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `ContractRecord` | `Contract` | `Single` |
| `LearnUponContactEnrollment` | `LearnUponP__LearnUponContactEnrollment__c` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OnboardingRecordCollection` | `Onboarding__c` | `Collection` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `TrainingAssignmentRecord` | `Training_Assignment__c` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirement_Subjects`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Onboarding Requirement Subjects
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Onboarding Requirements
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `Approval_Gate_Deferred_Remain` | `Boolean` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `VendorProgramRequirements` | `Vendor_Program_Requirement__c` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Opportunity`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Opportunity
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountRecord` | `Account` | `Single` |
| `ContractRecord` | `Contract` | `Single` |
| `OpportunityIdList` | `String` | `Collection` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `OpportunityRecordCollection` | `Opportunity` | `Collection` |
| `PriorOpportunityRecordCollection` | `Opportunity` | `Collection` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Opportunity_Contact_Role`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Opportunity Contact Role
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `opportunityContactRecordsJSON` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CreateRecordsErrorMessages` | `String` | `Collection` |
| `OpportunityContactRoleCollection` | `OpportunityContactRole` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Process_Status_Per_Business`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Process Status Per Business Rule
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ECCRecord` | `POE_External_Contact_Credential__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Related_Onboarding_Requirement_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Related Onboarding Requirement Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountRecord` | `Account` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OnboardingRequirementRecord` | `Onboarding_Requirement__c` | `Single` |
| `OpportunityContactRoleRecord` | `OpportunityContactRole` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Required_External_Contact_Credenti`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Required External Contact Credential
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ExternalContactCredentialRecords` | `POE_External_Contact_Credential__c` | `Collection` |
| `ExternalContactCredentialTypes` | `External_Contact_Credential_Type__c` | `Collection` |
| `RequiredCredentialRecordCollection` | `Required_Credential__c` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_CREATE_Training_Assignment_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Training Assignment Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |
| `ExternalContactCredentialRecord` | `POE_External_Contact_Credential__c` | `Single` |
| `LearnUponContactEnrollmentRecord` | `LearnUponP__LearnUponContactEnrollment__c` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `TrainingRequirementRecord` | `Training_Requirement__c` | `Single` |
| `VendorCustomizationId` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactTrainingAssignment` | `Training_Assignment__c` | `Single` |
| `errorMessage` | `String` | `Single` |
| `TrainingAssignmentRecordCollection` | `Training_Assignment__c` | `Collection` |
| `TrainingRequirementRecordCollection` | `Training_Requirement__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_Create_Contact`
- Responsibility: DOMAIN - OmniSObject - SFL - CREATE - Contact
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `contactsToCreateJSONString` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountContactRelationshipCollection` | `AccountContactRelation` | `Collection` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_By_Evidence`
- Responsibility: DOMAIN - OmniSObject - SFL - EVAL - Onb Req Subjects - By Evidence
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountId` | `String` | `Single` |
| `ContactId` | `String` | `Single` |
| `EvidenceStatus` | `String` | `Single` |
| `RequirementType` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ChangedOnboardingRequirementIdCollection` | `String` | `Collection` |
| `errorMessage` | `String` | `Single` |
| `MatchedSubjectCount` | `Number` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_For_Onb_Rec`
- Responsibility: DOMAIN - OmniSObject - SFL - EVAL - Onboarding Requirement Subjects
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactIdOverride` | `String` | `Single` |
| `EvidenceStatus` | `String` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `RequirementType` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_EVAL_Onb_Req_Subjects_Parent`
- Responsibility: DOMAIN - OmniSObject - SFL - EVAL - Onb Req Subjects - Parent
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRequirementId` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Account_Contact_Relationship`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Account Contact Relationship
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountContactRelationshipId` | `String` | `Single` |
| `AccountRecord` | `Account` | `Single` |
| `AccountRecordCollection` | `Account` | `Collection` |
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountContactRelationshipRecord` | `AccountContactRelation` | `Single` |
| `AccountContactRelCollection` | `AccountContactRelation` | `Collection` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Account_Record`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Account Record
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `accountId` | `String` | `Single` |
| `AccountRecordList` | `String` | `Collection` |
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `AgreementRecordCollection` | `echosign_dev1__SIGN_Agreement__c` | `Collection` |
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `ContractRecord` | `Contract` | `Single` |
| `ContractRecordCollection` | `Contract` | `Collection` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OnboardingRecordCollection` | `Onboarding__c` | `Collection` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `OpportunityRecordCollection` | `Opportunity` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountRecord` | `Account` | `Single` |
| `AccountRecordCollection` | `Account` | `Collection` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Agreements`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Agreements
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContractRecord` | `Contract` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_All_Related_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - All Related Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `contactId` | `String` | `Single` |
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `ContactRecordList` | `String` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountRecord` | `Account` | `Single` |
| `AccountRecordCollection` | `Account` | `Collection` |
| `CompleteVendorOnboardingRecords` | `Vendor__c` | `Collection` |
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `errorMessage` | `String` | `Single` |
| `OnboardingRecordCollection` | `Onboarding__c` | `Collection` |
| `VendorProgramCollection` | `Vendor_Customization__c` | `Collection` |
| `VendorProgramIdList` | `String` | `Collection` |
| `VendorRecordCollection` | `Vendor__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Communication_Dispatch_Policy`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Communication Dispatch Policy
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CommunicationType` | `String` | `Single` |
| `RecipientType` | `String` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `DispatchAllowed` | `Boolean` | `Single` |
| `PolicyFound` | `Boolean` | `Single` |
| `PolicySource` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Communication_Event_Policies`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Communication Event Policies
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `EventKey` | `String` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `EventPolicyRecordCollection` | `Communication_Event_Policy__mdt` | `Collection` |
| `PolicySource` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Communication_Recipients`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Communication Recipients
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `RecipientType` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `RecipientIdCollection` | `String` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Communication_Template`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Communication Template
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CommunicationType` | `Picklist` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CommunicationTemplateRecord` | `Communication_Template__c` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Communication_Templates`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Communication Templates
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CommunicationType` | `String` | `Single` |
| `RecipientType` | `String` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `CommunicationTemplateRecordCollection` | `Communication_Template__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Contact_Record`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Contact Record
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountContactRelationship` | `AccountContactRelation` | `Single` |
| `AccountContactRelationshipCollection` | `AccountContactRelation` | `Collection` |
| `AccountRecord` | `Account` | `Single` |
| `ContactId` | `String` | `Single` |
| `ContactIdList` | `String` | `Collection` |
| `FilterForSigners` | `Boolean` | `Single` |
| `OpportunityContactRole` | `OpportunityContactRole` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountContactRelationship` | `AccountContactRelation` | `Single` |
| `AccountContactRelationshipCollection` | `AccountContactRelation` | `Collection` |
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Contract_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Contract Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountId` | `String` | `Single` |
| `AccountRecord` | `Account` | `Single` |
| `AgreementId` | `String` | `Single` |
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `ContactId` | `String` | `Single` |
| `ContactRecord` | `Contact` | `Single` |
| `contractId` | `String` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OpportunityId` | `String` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContractRecord` | `Contract` | `Single` |
| `ContractRecordCollection` | `Contract` | `Collection` |
| `errorMessage` | `String` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_External_Contact_Credential_Types`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - External Contact Credential Types
- Process type: `AutoLaunchedFlow`

Inputs:
- None declared

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ECCTypes` | `External_Contact_Credential_Type__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_LearnUponContactEnrollment_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - LearnUponContactEnrollment Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecordList` | `String` | `Collection` |
| `FilterOutCompletedOrPassed` | `Boolean` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `LUCERecordCollection` | `LearnUponP__LearnUponContactEnrollment__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_LearnUpon_Portal_Membership`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - LearnUpon Portal Membership
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `LearnUponPortalMembership` | `LearnUponP__LearnUpon_Portal_Membership__c` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Onboarding_Fullfilment_Policy`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Onboarding Fullfilment Policy
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `FulfillmentPolicyKey` | `String` | `Single` |
| `FulfillmentPolicyKeyCollection` | `String` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `FulfillmentPolicyRecord` | `Onboarding_Fulfillment_Policy__mdt` | `Single` |
| `FulfillmentPolicyRecordCollection` | `Onboarding_Fulfillment_Policy__mdt` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Onboarding_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Onboarding Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountId` | `String` | `Single` |
| `AccountRecord` | `Account` | `Single` |
| `AccountRecordCollection` | `Account` | `Collection` |
| `AccountRecordList` | `String` | `Collection` |
| `AgreementId` | `String` | `Single` |
| `AgreementRecord` | `echosign_dev1__SIGN_Agreement__c` | `Single` |
| `AgreementRecordCollection` | `echosign_dev1__SIGN_Agreement__c` | `Collection` |
| `AgreementRecordList` | `String` | `Collection` |
| `ContactId` | `String` | `Single` |
| `ContractId` | `String` | `Single` |
| `ContractRecord` | `Contract` | `Single` |
| `ContractRecordCollection` | `Contract` | `Collection` |
| `ContractRecordList` | `String` | `Collection` |
| `FindNotIncludedValues` | `Boolean` | `Single` |
| `OnboardingId` | `String` | `Single` |
| `OnboardingRequirementRecord` | `Onboarding_Requirement__c` | `Single` |
| `OpportunityId` | `String` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `OpportunityRecordCollection` | `Opportunity` | `Collection` |
| `OpportunityRecordList` | `String` | `Collection` |
| `TrainingAssignmentRecord` | `Training_Assignment__c` | `Single` |
| `TrainingAssignmentRecordCollection` | `Training_Assignment__c` | `Collection` |
| `VendorProgramId` | `String` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |
| `VendorProgramRecordCollection` | `Vendor_Customization__c` | `Collection` |
| `VendorProgramRecordList` | `String` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `HasAnyOboardingForAccount` | `Boolean` | `Single` |
| `HasChuzoOnboardingForOpportunity` | `Boolean` | `Single` |
| `HasNDAOnboardingForOpportunity` | `Boolean` | `Single` |
| `HasNonChuzoOnboardingForOpportunity` | `Boolean` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OnboardingRecordCollection` | `Onboarding__c` | `Collection` |
| `OnboardingRecordList` | `String` | `Collection` |
| `TotalOnboardingRecords` | `Number` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Onboarding Requirement
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OnboardingRequirementId` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `OnboardingRequirementRecord` | `Onboarding_Requirement__c` | `Single` |
| `OnboardingRequirementRecordCollection` | `Onboarding_Requirement__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Onboarding_Requirement_Subjects`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Onboarding Requirement Subjects
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountId` | `String` | `Single` |
| `ContactId` | `String` | `Single` |
| `OnboardingRequirementId` | `String` | `Single` |
| `RequirementType` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `OnboardingRequirementSubjectCollection` | `Onboarding_Requirement_Subject__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Opportunity_Record`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Opportunity Record
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `AccountId` | `String` | `Single` |
| `AccountRecord` | `Account` | `Single` |
| `AccountRecordCollection` | `Account` | `Collection` |
| `AccountRecordList` | `String` | `Collection` |
| `ContactRoleList` | `String` | `Collection` |
| `ContractId` | `String` | `Single` |
| `ContractRecord` | `Contract` | `Single` |
| `ContractRecordCollection` | `Contract` | `Collection` |
| `ContractRecordList` | `String` | `Collection` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OpportunityContactRole` | `OpportunityContactRole` | `Single` |
| `OpportunityContactRoleCollection` | `OpportunityContactRole` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `OpportunityRecordCollection` | `Opportunity` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Primary_Opportunity_Contact`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Opportunity Contact
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactId` | `String` | `Single` |
| `ContactRecord` | `Contact` | `Single` |
| `ContactRecordCollection` | `Contact` | `Collection` |
| `ContactRecordList` | `String` | `Collection` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `OpportunityContactRecord` | `OpportunityContactRole` | `Single` |
| `OpportunityContactRecordCollection` | `OpportunityContactRole` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Training_Assignment_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Training Assignment Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecordList` | `String` | `Collection` |
| `OnboardingRecordList` | `String` | `Collection` |
| `TrainingAssignmentList` | `String` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `TrainingAssignmentRecordCollection` | `Training_Assignment__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Training_Requirement_Records`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Training Requirement Records
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `VendorProgramList` | `String` | `Collection` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |
| `VendorProgramRecordCollection` | `Vendor_Customization__c` | `Collection` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `TrainingRequirementRecordCollection` | `Training_Requirement__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Training_Systems`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Training Systems
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `TrainingSystemName` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `TrainingSystemRecord` | `Training_System__c` | `Single` |
| `TrainingSystemRecordCollection` | `Training_System__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Vendor_Program`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Vendor Program
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `businessVertical` | `String` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `OpportunityRecord` | `Opportunity` | `Single` |
| `retailOption` | `String` | `Single` |
| `vendorId` | `String` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Vendor_Program_Group_Members`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Vendor Program Group Members
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `VendorProgramGroup` | `Vendor_Program_Group__c` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `VPGMemberRecordCollection` | `Vendor_Program_Group_Member__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_GET_Vendor_Program_Requirements`
- Responsibility: DOMAIN - OmniSObject - SFL - GET - Vendor Program Requirements
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRequirementRecord` | `Onboarding_Requirement__c` | `Single` |
| `VendorProgramRecord` | `Vendor_Customization__c` | `Single` |

Expected outputs:

| Variable | Type | Cardinality |
|---|---|---|
| `errorMessage` | `String` | `Single` |
| `VendorProgramRequirement` | `Vendor_Program_Requirement__c` | `Single` |
| `VPRCollection` | `Vendor_Program_Requirement__c` | `Collection` |

Given valid input selectors, these output variables are populated by the flow logic for downstream callers.

### `DOMAIN_OmniSObject_SFL_Send_Email_Communication`
- Responsibility: DOMAIN - OmniSObject - SFL - Send Email Communication
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `ContactRecord` | `Contact` | `Single` |
| `ExternalContactCredential` | `POE_External_Contact_Credential__c` | `Single` |
| `OnboardingRecord` | `Onboarding__c` | `Single` |

Expected outputs:
- None declared

### `DOMAIN_OmniSObject_SFL_Submit_for_Approval`
- Responsibility: DOMAIN - OmniSObject - SFL - Submit for Approval
- Process type: `AutoLaunchedFlow`

Inputs:

| Variable | Type | Cardinality |
|---|---|---|
| `OnboardingRecord` | `Onboarding__c` | `Single` |
| `recordId` | `String` | `Single` |

Expected outputs:
- None declared
