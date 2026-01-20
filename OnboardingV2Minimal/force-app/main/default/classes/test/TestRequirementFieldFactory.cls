@isTest
public class TestRequirementFieldFactory {

    public static Requirement_Field__c create(
        String fieldApiName,
        String validationType,
        Boolean required,
        Boolean doInsert
    ) {
        Requirement_Field__c reqField = new Requirement_Field__c(
            Field_API_Name__c = fieldApiName,
            Required__c = required != null ? required : false
        );

        if (String.isNotBlank(validationType)) {
            List<String> validTypes = TestDataFactoryUtil.getPicklistValues(
                Requirement_Field__c.SObjectType,
                'Validation_Type__c'
            );
            if (validTypes.contains(validationType)) {
                reqField.Validation_Type__c = validationType;
            } else {
                String normalizedType = validationType != null ? validationType.toLowerCase() : null;
                for (String candidate : validTypes) {
                    if (candidate != null && normalizedType != null &&
                        candidate.toLowerCase().startsWith(normalizedType)) {
                        reqField.Validation_Type__c = candidate;
                        break;
                    }
                }
                if (String.isBlank(reqField.Validation_Type__c)) {
                    reqField.Validation_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                        Requirement_Field__c.SObjectType,
                        'Validation_Type__c'
                    );
                }
            }
        } else {
            reqField.Validation_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Requirement_Field__c.SObjectType,
                'Validation_Type__c'
            );
        }

        if (String.isNotBlank(fieldApiName)) {
            reqField.Name = fieldApiName.replace('__c', '').replace('_', ' ');
        } else if (String.isBlank(reqField.Name)) {
            reqField.Name = 'Test Field';
        }

        if (String.isBlank(reqField.Field_Type__c)) {
            reqField.Field_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Requirement_Field__c.SObjectType,
                'Field_Type__c'
            );
        }

        if (TestDataFactoryUtil.isFieldRequired(Requirement_Field__c.SObjectType, 'Vendor_Program_Requirement__c') &&
            reqField.Vendor_Program_Requirement__c == null) {
            Vendor_Program_Requirement__c vendorProgramRequirement = TestVendorProgramRequirementFactory.create(true);
            reqField.Vendor_Program_Requirement__c = vendorProgramRequirement.Id;
        }

        TestDataFactoryUtil.maybeInsert(reqField, doInsert);
        return reqField;
    }

    public static Requirement_Field__c create(
        String fieldApiName,
        String validationType,
        Boolean required,
        Id requirementFieldGroupId,
        Integer sequence,
        Boolean doInsert
    ) {
        Requirement_Field__c reqField = create(fieldApiName, validationType, required, false);
        if (requirementFieldGroupId != null) {
            reqField.Requirement_Field_Group__c = requirementFieldGroupId;
        }
        if (sequence != null) {
            reqField.Sequence__c = sequence;
        }
        TestDataFactoryUtil.maybeInsert(reqField, doInsert);
        return reqField;
    }

    public static Requirement_Field__c create(
        String fieldApiName,
        Boolean doInsert
    ) {
        return create(fieldApiName, null, null, doInsert);
    }
}