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
        return createExternalContactCredential(
            contact,
            username,
            vendorProgramName,
            processStatus,
            credentialType,
            null,
            doInsert
        );
    }

    public static POE_External_Contact_Credential__c createExternalContactCredential(
        Contact contact,
        String username,
        String vendorProgramName,
        String processStatus,
        External_Contact_Credential_Type__c credentialType,
        Vendor_Customization__c vendorProgram,
        Boolean doInsert
    ) {
        String resolvedProgramName = vendorProgramName;
        if (String.isBlank(resolvedProgramName) && vendorProgram != null) {
            resolvedProgramName = String.isNotBlank(vendorProgram.Label__c)
                ? vendorProgram.Label__c
                : vendorProgram.Name;
        }
        if (String.isBlank(resolvedProgramName)) {
            resolvedProgramName = firstActiveProgramValue();
        }

        POE_External_Contact_Credential__c externalContactCredential = new POE_External_Contact_Credential__c(
            POE_Contact__c = contact.Id,
            POE_Username__c = username,
            POE_Program__c = resolvedProgramName,
            POE_Process_Status__c = processStatus,
            External_Contact_Credential_Type__c = credentialType.Id,
            Vendor_Program__c = vendorProgram == null ? null : vendorProgram.Id
        );
        TestDataFactoryUtil.maybeInsert(externalContactCredential, doInsert);
        return externalContactCredential;
    }

    private static String firstActiveProgramValue() {
        for (Schema.PicklistEntry entry :
            POE_External_Contact_Credential__c.POE_Program__c.getDescribe().getPicklistValues()
        ) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return 'Verizon Fios D2D';
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
