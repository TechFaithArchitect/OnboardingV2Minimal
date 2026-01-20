@isTest
public class TestAVOFactory {

    /**
     * Creates an Account_Vendor_Program_Onboarding__c record
     * @param account Account record
     * @param onboarding Onboarding__c record
     * @param status Status picklist value (if null, uses default from picklist)
     * @param doInsert Whether to insert the record
     * @return Account_Vendor_Program_Onboarding__c record
     */
    public static Account_Vendor_Program_Onboarding__c create(
        Account account,
        Onboarding__c onboarding,
        String status,
        Boolean doInsert
    ) {
        Account_Vendor_Program_Onboarding__c avo = new Account_Vendor_Program_Onboarding__c(
            Account__c = account != null ? account.Id : null,
            Onboarding__c = onboarding != null ? onboarding.Id : null
        );
        
        // Use valid picklist value if status provided, otherwise get default
        if (String.isNotBlank(status)) {
            // Validate the status value against picklist
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Account_Vendor_Program_Onboarding__c.SObjectType,
                'Status__c'
            );
            if (validStatuses.contains(status)) {
                avo.Status__c = status;
            } else {
                // If provided status is invalid, use default
                avo.Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                    Account_Vendor_Program_Onboarding__c.SObjectType,
                    'Status__c'
                );
            }
        } else {
            // Get default picklist value
            avo.Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Account_Vendor_Program_Onboarding__c.SObjectType,
                'Status__c'
            );
        }
        
        TestDataFactoryUtil.maybeInsert(avo, doInsert);
        return avo;
    }

    /**
     * Creates an Account_Vendor_Program_Onboarding__c record with default status
     */
    public static Account_Vendor_Program_Onboarding__c create(
        Account account,
        Onboarding__c onboarding,
        Boolean doInsert
    ) {
        return create(account, onboarding, null, doInsert);
    }
}