# OnboardV2 Active Flow True-Up (2026-03-12)

- Source org: `OnboardV2`
- Manifest used: `manifest/onboardv2-active-flows.xml`
- Active flow definitions in org: `274`
- Active vs latest version mismatch count: `16`
- Flow files changed in repo immediately after retrieve: `192`
  - Modified: `31`
  - Added: `161`
- Cleanup applied: removed newly added flows with active `CreatedDate < 2026-01-01`
  - Files removed: `50`
  - Remaining added flows: `111`
  - Remaining total flow file changes: `142`

## Active But Missing In Repo (23)

- `AA_Custom_NotificationFlow`
- `AA_New_Booking_Flow`
- `Account_Engagement_Bulk_Asset_Copy_Flow`
- `Account_Engagement_Sandbox_Production_Bulk_Asset_Copy_Flow`
- `Add_Asset_to_Maintenance_Plan`
- `Create_Service_Report_and_Document_Recipient`
- `FSK_Cancelation_Canned_Notification`
- `FSK_Canned_Notification_Dispatched`
- `FSK_Exclude_Resource_On_Rejection`
- `FSK_Populate_Custom_Work_Order_Lookup`
- `FSK_Resource_Deactivation`
- `FSK_Set_Gantt_Label_Concatenation`
- `FSK_Update_Work_Order_Child_Records`
- `FSK_Work_Order_Process`
- `Permatrix_Notification_Profile_Conversion_Complete`
- `Retrieve_by_specific_Reference_ID`
- `Self_Service_Scheduling_AuthenticationFlow`
- `Send_Session_Invite`
- `VRA_End_User_Session_Request`
- `VRA_Retrieve_Session_Recording_Screen_Flow`
- `VRA_Session_Request_Channel`
- `VRA_Trigger_Retrieval_of_Session_Recording`
- `Visual_Remote_Assistant_Reports`

## Active-Version Mismatch In Org (16)

- `Account_Flow_Handler`
- `AccountUpdates`
- `Bulk_Convert_Lead_Flow`
- `Case_Record_Trigger_Case_Creation_Update`
- `Case_Subflow_Email_Sending`
- `Chuzo_Referral_Form`
- `Create_Representative_User`
- `Customer_Service_Information_Requirement`
- `POE_ConvertLeadFlow`
- `PV_Customer_Service_Permission_Set_Assignment`
- `Service_Resource_Share`
- `Subflow_Assign_Chuzo_Permission_Sets_By_Representative_Type`
- `Update_Opportunity_Dealer`
- `Update_Order_Dealer`
- `Update_Representative_Type_Flow`
- `User_After_Create_Add_Agent_to_Public_Group`

## Notes

- Missing-in-repo entries are typically managed/package-provided flows or metadata not retrievable into this source format.
- This true-up intentionally pulled active flow definitions from OnboardV2 and updated local flow metadata accordingly.
