# UAT Flow Deactivation Candidates

Use this list as a retirement checklist for UAT only.  
Each item below is active in UAT but intentionally inactive in OnboardV2 source.

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

## How To Execute This In UAT

1. Confirm release window and notify testers that legacy flows may be turned off.
2. Export current active flow state in UAT (for rollback reference).
3. Deactivate each flow in the list below in UAT.
4. Verify none of the listed flow definitions remain active.
5. Run smoke checks for onboarding create, requirement generation, status updates, and communications.
6. Record completion evidence in release notes (who, when, what verified).

## Verification Checklist

- All listed flows are inactive in UAT.
- No required modern OnboardV2 flows were accidentally deactivated.
- Key UAT business paths still work after deactivation.
- Any deactivation exceptions are documented with owner and follow-up date.

## Rollback Procedure

1. Reactivate only the specific flow(s) needed to recover business operations.
2. Re-run the failing scenario to confirm restoration.
3. Open an issue to resolve root cause before re-attempting retirement.
4. Update release notes with rollback reason and final state.

## Scenario Playbooks

### Scenario 1: A flow cannot be deactivated

1. Confirm whether active dependencies/interviews still reference the flow.
2. Resolve blockers (finish/cancel interviews or remove active references).
3. Retry deactivation and re-verify active status.

### Scenario 2: Business process breaks after deactivation

1. Identify exact failing path and impacted flow(s).
2. Reactivate minimum needed flow(s) as rollback.
3. Validate immediate business recovery.
4. Create follow-up to migrate dependency to supported OnboardV2 path.

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
