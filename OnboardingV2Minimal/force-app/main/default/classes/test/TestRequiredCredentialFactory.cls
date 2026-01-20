@isTest
public class TestRequiredCredentialFactory {
    public static Required_Credential__c create(Boolean doInsert, Vendor_Customization__c customization) {
        Required_Credential__c requiredCredential = new Required_Credential__c(
            External_Contact_Credential_Type__c = null,
            Is_Required__c = true,
            Notes__c = 'Test credential requirement',
            Sequence__c = 1,
            Vendor_Customization__c = customization.Id
        );
        if (doInsert) insert requiredCredential;
        return requiredCredential;
    }
}