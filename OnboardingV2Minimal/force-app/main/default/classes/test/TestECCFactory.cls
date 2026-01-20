@isTest
public class TestECCFactory {

    public static POE_External_Contact_Credential__c createExternalContactCredential(
        Contact contact,
        String username,
        String vendorProgramName,
        String processStatus,
        External_Contact_Credential_Type__c credentialType,
        Boolean doInsert
    ) {
        POE_External_Contact_Credential__c externalContactCredential = new POE_External_Contact_Credential__c(
            POE_Contact__c = contact.Id,
            POE_Username__c = username,
            POE_Program__c = vendorProgramName,
            POE_Process_Status__c = processStatus,
            External_Contact_Credential_Type__c = credentialType.Id
        );
        TestDataFactoryUtil.maybeInsert(externalContactCredential, doInsert);
        return externalContactCredential;
    }

    public static ECC_Field_Configuration_Group__c createFieldConfigurationGroup(String groupName, Boolean doInsert) {
        ECC_Field_Configuration_Group__c eccFieldConfigurationGroup = new ECC_Field_Configuration_Group__c(Name = groupName);
        TestDataFactoryUtil.maybeInsert(eccFieldConfigurationGroup, doInsert);
        return eccFieldConfigurationGroup;
    }

    public static ECC_Field_Configuration_Group_Mapping__c createGroupMapping(
        ECC_Field_Configuration_Group__c eccFieldConfigurationGroup,
        Vendor_Customization__c vendorCustomization,
        Boolean doInsert
    ) {
        ECC_Field_Configuration_Group_Mapping__c eccFieldConfigurationGroupMapping = new ECC_Field_Configuration_Group_Mapping__c(
            ECC_Field_Configuration_Group__c = eccFieldConfigurationGroup.Id,
            Vendor_Program__c = vendorCustomization.Id
        );
        TestDataFactoryUtil.maybeInsert(eccFieldConfigurationGroupMapping, doInsert);
        return eccFieldConfigurationGroupMapping;
    }

    public static ECC_Field_Display_Configuration__c createDisplayConfiguration(
        ECC_Field_Configuration_Group__c eccFieldConfigurationGroup,
        String fieldApiName,
        String fieldLabel,
        Boolean isReadOnly,
        Boolean isVisible,
        Boolean doInsert
    ) {
        ECC_Field_Display_Configuration__c eccFieldDisplayConfiguration = new ECC_Field_Display_Configuration__c(
            ECC_Field_Configuration_Group__c = eccFieldConfigurationGroup.Id,
            Field_API_Name__c = fieldApiName,
            Field_Label__c = fieldLabel,
            Read_Only__c = isReadOnly,
            Visible__c = isVisible
        );
        TestDataFactoryUtil.maybeInsert(eccFieldDisplayConfiguration, doInsert);
        return eccFieldDisplayConfiguration;
    }
}