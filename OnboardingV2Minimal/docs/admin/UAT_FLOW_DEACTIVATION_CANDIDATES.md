# UAT Flow Deactivation Candidates

## Rule Used

A flow belongs on this list only when:

- It is Active in `UAT`
- It is Inactive in `OnboardV2`

Excluded by rule:

- Inactive in `OnboardV2` but not active in `UAT`
- Not present in `UAT`

## Comparison Method (2026-03-26)

- Queried full Tooling API `FlowDefinition` in both orgs (`DeveloperName`, `ActiveVersionId`)
- Compared by `DeveloperName`
- Total matches for this rule: `61`

## Deactivate In UAT

- `Agreement_Orchestration_Sync_Onboarding_Records`
- `Agreement_Processes`
- `Agreement_Subflow_Update_Related_Records`
- `BLL_Contact_Training_Assignment_RCD_Update_Related_Records`
- `BLL_External_Contact_Credential_RCD_Execute_Supplemental_Onboarding_Requirements`
- `Contact_LearnUpon_Group_Enrollment`
- `Contact_LearnUpon_User_Email_Address_Update`
- `Contact_LearnUpon_User_Enrollment`
- `Contact_Record_Trigger_Ensure_One_Principle_Owner`
- `Contact_Record_Trigger_Mark_Account_As_Principal_Owner_Changed`
- `Contact_ScreenFlow_Create_Contacts_on_Accounts`
- `Contact_Subflow_Find_Principle_Owner_on_Account`
- `Contract_Automation`
- `Contract_Onboarding_Age_Count_flow`
- `Contract_Subflow_Get_Contract_Record_Information`
- `Contract_Subflow_Get_Related_Contract_Information`
- `Contract_Subflow_Territory_Assignment`
- `DOMAIN_Contact_SFL_CREATE_Training_Assignment_Records`
- `DOMAIN_Contact_SFL_UPDATE_Contact_Fields_with_ECC_Information`
- `DOMAIN_External_Contact_Credential_RCD_Before_Save_Flow_to_Prevent_Duplicates`
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Contact_Training_Assignment_Record`
- `DOMAIN_External_Contact_Credential_SFL_CREATE_Required_External_Contact_Credenti`
- `DOMAIN_External_Contact_Credential_SFL_GET_Contact_Record`
- `DOMAIN_External_Contact_Credential_SFL_GET_Vendor_Customization`
- `DOMAIN_External_Contact_Credential_SFL_Send_Email_Communication`
- `DOMAIN_External_Contact_Credential_SFL_UPDATE_Process_Status_Per_Business`
- `DOMAIN_External_Contact_Credential_Type_RCD_Before_Save_Flow_to_Prevent_Duplicates`
- `DOMAIN_LearnUponContactEnrollment_SFL_CREATE_Contact_Training_Assignment_Record`
- `DOMAIN_LearnUponContactEnrollment_SFL_UPDATE_Contact_Training_Assignment_Record`
- `DOMAIN_Onboarding_SFL_CREATE_External_Contact_Credentials`
- `DOMAIN_Onboarding_SFL_CREATE_Order_and_Assign_Product_to_Order`
- `DOMAIN_Onboarding_SFL_Send_Email_Notification`
- `DOMAIN_Onboarding_SFL_Update_Onboarding_Record_s_Training_Status`
- `DOM_Contract_SFL_Get_Opportunity_Record_Related_to_Contract`
- `DOM_LearnUponContactEnrollment_SFL_Connect_LearnUponContactEnrollment_to_Onbo`
- `DOM_LearnUponContactEnrollment_SFL_GET_Contact_Training_Assignment_Record`
- `DOM_Onboarding_SFL_CREATE_Training_Assignment_Records`
- `DOM_Onboarding_SFL_GET_Order_Status_Details`
- `Dealer_Insurance_Subflow_Sync_Dealer_Insurance_Records`
- `EXP_Contact_SCR_Select_Opportunity_Contact`
- `LearnUpon_Enrollment`
- `LearnUpon_Group_Assignments`
- `LearnUpon_Record_Update_Onboarding_Record`
- `New_Dealer_Training_Automations`
- `Onboarding_Autolaunch_Close_All_Tasks`
- `Onboarding_Autolaunch_Dealer_Welcome_Emails`
- `Onboarding_Autolaunch_Update_Dealer_Insurance_Record`
- `Onboarding_Get_Customization_Records`
- `Onboarding_Get_Territory_Assignments`
- `Onboarding_Screenflow_Change_Principal_Owner_Contact`
- `Onboarding_Subflow_Gather_Record_Details`
- `Opportunity_Creation_Subflow`
- `Opportunity_Processes_Flow`
- `Opportunity_Screen_Flow_Create_New_Opportunity_Account_Record_For_Transfer`
- `Opportunity_Subflow_Assign_Opportunity_Contacts`
- `Product_Consumed_Record_Trigger_Prevent_Users_from_Changing_Product_Consumed`
- `Product_Consumed_Record_Trigger_Prevent_Users_from_Deleting`
- `Training_Reminder_Email_Alerts`
- `Update_Contract_Record_Type_Reference`
