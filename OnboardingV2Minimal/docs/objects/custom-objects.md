# Custom Objects (Repo)

This list is generated from `force-app/main/default/objects` and reflects the objects present in this repo.
Managed-package objects and org-only objects (e.g., LearnUpon managed objects, `Program_Dates__c`) are **not** listed here because they are not stored in this repo.

| API Name | Label | Description |
| --- | --- | --- |
| `Account` | Account |  |
| `AccountContactRelation` | AccountContactRelation |  |
| `Account_Vendor_Program_Onboarding__c` | Account Vendor Program Onboarding | Junction object linking an Account (Dealer, Infrastructure Supplier, etc.) to a Vendor Program Onboarding engagement; supports repeat enrollments with optional Opportunity linkage. |
| `Audit__c` | Audit |  |
| `Background_Check__c` | Background Check | This object stores all the background checks ever performed by a contact and account. |
| `Chuzo_Agreement__c` | Chuzo Agreement |  |
| `Clearing_House__c` | Clearing House | This object is for storing all forms used by PerfectVision in order to pay dealers. |
| `Collection_Team_Page__c` | Collection Team Page |  |
| `Commercial_L_I_Information__c` | Connected Solutions Quotes/Orders | This is the object that will house issues regarding commercial systems as well as quotes for the systems.  All communication regarding commercial/L&I systems should be logged within this object. |
| `Commercial_MSO__c` | Commercial MSO |  |
| `Communication_Template__c` | Communication Template | Stores and mirrors the system classic email templates for use with onboarding. All fields are read only and is synced nightly or by a manual sync. |
| `Contact` | Contact |  |
| `Contract` | Contract |  |
| `Contract_Record_Type_Reference__c` | Contract Record Type Reference |  |
| `Credit_Check__c` | Credit Check | This object stores each and every occurrence a credit check has been performed on the account and contact. |
| `Deactivate_Chuzo_Only_Agent__e` | Deactivate Chuzo-Only Agent | Used to deactivate an User from Deactivate_Chuzo_Agent flow [PER-3665]. |
| `Dealer_Compliance__c` | Dealer Compliance |  |
| `Dealer_Insurance_Detail__c` | Dealer Insurance Detail |  |
| `Dealer_Insurance__c` | Dealer Insurance |  |
| `ECC_Field_Configuration_Group_Mapping__c` | ECC_Field_Configuration_Group_Mapping__c |  |
| `ECC_Field_Configuration_Group__c` | ECC_Field_Configuration_Group__c |  |
| `ECC_Field_Display_Configuration__c` | ECC_Field_Display_Configuration__c |  |
| `ERP_Setup__c` | ERP Setup | This object tracks which accounts have been setup in our ERP system. |
| `External_Contact_Credential_Type__c` | External_Contact_Credential_Type__c |  |
| `External_Credential_Type_Dependency__c` | External_Credential_Type_Dependency__c |  |
| `Follow_Up_Queue__c` | Follow Up Queue | Tracks pending/failed onboarding follow-ups (SMS/Email) with status, attempts, next attempt date, and error details. |
| `Follow_Up_Rule__mdt` | Follow Up Rule | Defines follow-up rules for automated messaging/escalation. |
| `Follow_Up_Suppression__mdt` | Follow Up Suppression |  |
| `Infrastructure_Ship_to_Sales__c` | Ship to Sales |  |
| `Interview__c` | Interview |  |
| `Labor_Form__c` | Labor Form | This object is for storing all employment / 1099 forms used by PerfectVision. |
| `License__c` | License | This object stores all the different types of licenses needed by PerfectVision and our Vendors and relates it back to the Dealer. |
| `Net_Terms__c` | Net Terms |  |
| `Onboarding_Requirement__c` | Onboarding Requirement | Dealer-specific instance of each required task (status, file, etc.) |
| `Onboarding_Status_Rule__c` | Onboarding Status Rule | Individual condition row within a status rules engine to drive onboarding status changes. |
| `Onboarding_Status_Rules_Engine__c` | Onboarding Status Rules Engine | Configurable Rules Engine that evaluates the status of an onboarding record. |
| `Onboarding__c` | Onboarding__c |  |
| `Opportunity` | Opportunity |  |
| `OpportunityContactRole` | OpportunityContactRole |  |
| `Order__c` | PV-Order |  |
| `POE_Clicker_Event_Track__c` | Clicker Event Track |  |
| `POE_Clicker_Retail_Track__c` | Clicker Retail Track | Object for keeping track of the actions on the Clicker Page - for Retail users |
| `POE_Dealer_Code__c` | Dealer Code | Stores dealer codes for DTV FFL and NFFL sales |
| `POE_External_Contact_Credential__c` | POE_External_Contact_Credential__c |  |
| `Personal_Guarantee__c` | Personal Guarantee |  |
| `Program_Compliance__c` | Program Compliance |  |
| `Referral_Code__c` | Referral Code |  |
| `Required_Credential__c` | Required_Credential__c |  |
| `Required_External_Contact_Credential__c` | Required_External_Contact_Credential__c |  |
| `Territory_Assignments__c` | Territory Assignments |  |
| `Territory_Role_Assignment__c` | Territory Role Assignment | Metadata-driven pivot between Territory_Assignment__c and Role Label (synced, not manually maintained). |
| `Training_Assignment__c` | Training_Assignment__c |  |
| `Training_Requirement__c` | Training_Requirement__c |  |
| `Training_System__c` | Training_System__c |  |
| `Twilio_Configuration__mdt` | Twilio Configuration | Configuration for Twilio SMS provider settings |
| `Vendor_Customization__c` | Vendor_Customization__c |  |
| `Vendor_Order_Entry_Platform__c` | Vendor Order Entry Platform |  |
| `Vendor_Program_Group_Member__c` | Vendor_Program_Group_Member__c |  |
| `Vendor_Program_Group__c` | Vendor Program Group | Logical grouping of vendor program configurations that share requirement sets, rules, and stage dependencies; used by the onboarding wizard for selection and inheritance. |
| `Vendor_Program_Requirement__c` | Vendor Program Requirement | This object lets each Vendor Program add, remove, or override requirements from a group. |
| `Vendor__c` | Vendor | This is a full list of every vendor we work with |
