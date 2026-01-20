/**
 * Repository for Account data access operations
 * Handles all SOQL queries for Account records
 */
public with sharing class AccountRepository {
    
    /**
     * Gets accounts with basic fields for onboarding eligibility checks
     * @param limitCount Maximum number of records to return
     * @return List of Account records
     */
    public static List<Account> getAccountsForOnboarding(Integer limitCount) {
        Integer limitValue = limitCount != null && limitCount > 0 ? limitCount : 50;
        
        return [
            SELECT Id, Name, Territory__c, Region__c
            FROM Account
            ORDER BY Name
            LIMIT :limitValue
        ];
    }
}