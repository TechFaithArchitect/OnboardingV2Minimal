public with sharing class EmailCommTerritoryRoleSyncJob implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Query all fields including Name and any required fields
        List<Territory_Assignments__c> assignments = [
            SELECT Id, Name,
                   Account_Manager__c,
                   BB_Recruiter__c,
                   Inside_BB_BDM__c,
                   Inside_Sales_Specialist__c,
                   Inside_Sales_Specialist_2__c,
                   Inside_Sales_Supervisor__c,
                   National_Account_Manager__c,
                   Outside_Director__c,
                   Onboarding_Rep__c,
                   Onsite_Sales_Specialist__c,
                   Onsite_Sales_Supervisor__c,
                   Outside_BB_BDM__c,
                   Outside_Regional_Manager__c,
                   Regional_Sales_Manager__c,
                   Regional_COM_Mgr__c,
                   Sales_Support_Specialist__c,
                   Senior_Sales_Director__c,
                   MDP_T_Mobile_BDM__c,
                   Recruiter__c,
                   Inside_COM_BDM__c,
                   Base_App_OB_Rep__c
            FROM Territory_Assignments__c
            WHERE Id != null
        ];

        EmailCommTerritoryRoleHelper.syncRoles(assignments);
    }
}