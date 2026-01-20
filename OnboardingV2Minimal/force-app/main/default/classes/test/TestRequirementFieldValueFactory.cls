@isTest
public class TestRequirementFieldValueFactory {

    public static Requirement_Field_Value__c create(
        Requirement_Field__c requirementField,
        Onboarding_Requirement__c onboardingRequirement,
        String value,
        String validationStatus,
        Boolean doInsert
    ) {
        Requirement_Field_Value__c fieldValue = new Requirement_Field_Value__c(
            Requirement_Field__c = requirementField != null ? requirementField.Id : null,
            Onboarding_Requirement__c = onboardingRequirement != null ? onboardingRequirement.Id : null,
            Value__c = value
        );

        if (String.isNotBlank(validationStatus)) {
            List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
                Requirement_Field_Value__c.SObjectType,
                'Validation_Status__c'
            );
            if (validStatuses.contains(validationStatus)) {
                fieldValue.Validation_Status__c = validationStatus;
            } else {
                fieldValue.Validation_Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                    Requirement_Field_Value__c.SObjectType,
                    'Validation_Status__c'
                );
            }
        } else {
            fieldValue.Validation_Status__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Requirement_Field_Value__c.SObjectType,
                'Validation_Status__c'
            );
        }

        TestDataFactoryUtil.maybeInsert(fieldValue, doInsert);
        return fieldValue;
    }

    public static Requirement_Field_Value__c create(
        Requirement_Field__c requirementField,
        Onboarding_Requirement__c onboardingRequirement,
        Boolean doInsert
    ) {
        return create(requirementField, onboardingRequirement, null, null, doInsert);
    }

    public static Requirement_Field_Value__c create(
        Requirement_Field__c requirementField,
        Onboarding_Requirement__c onboardingRequirement,
        String value,
        Boolean doInsert
    ) {
        return create(requirementField, onboardingRequirement, value, null, doInsert);
    }
}