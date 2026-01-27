@isTest
public class TestCredentialFactory {

    public static External_Contact_Credential_Type__c createCredentialType(
        String name,
        Integer sortOrder,
        Vendor_Customization__c vendorCustomization,
        Boolean isActive,
        Boolean doInsert
    ) {
        External_Contact_Credential_Type__c externalContactCredentialType = new External_Contact_Credential_Type__c(
            Name = name,
            Sort_Order__c = sortOrder,
            Vendor_Customization__c = vendorCustomization.Id,
            Active__c = isActive
        );
        TestDataFactoryUtil.maybeInsert(externalContactCredentialType, doInsert);
        return externalContactCredentialType;
    }

    public static Required_Credential__c createRequiredCredential(
        External_Contact_Credential_Type__c credentialType,
        Vendor_Customization__c vendorCustomization,
        Boolean isRequired, Boolean doInsert
    ) {
        Required_Credential__c requiredCredential = new Required_Credential__c(
            External_Contact_Credential_Type__c = credentialType.Id,
            Vendor_Customization__c = vendorCustomization.Id,
            Is_Required__c = isRequired
        );
        TestDataFactoryUtil.maybeInsert(requiredCredential, doInsert);
        return requiredCredential;
    }

    public static External_Credential_Type_Dependency__c createDependency(
        External_Contact_Credential_Type__c credentialType,
        External_Contact_Credential_Type__c dependentCredentialType,
        Vendor_Customization__c vendorCustomization,
        Boolean doInsert
    ) {
        External_Credential_Type_Dependency__c externalCredentialTypeDependency = new External_Credential_Type_Dependency__c(
            Credential_Type__c = credentialType.Id,
            Depends_On__c = dependentCredentialType.Id,
            Vendor_Program__c = vendorCustomization.Id
        );
        TestDataFactoryUtil.maybeInsert(externalCredentialTypeDependency, doInsert);
        return externalCredentialTypeDependency;
    }
}