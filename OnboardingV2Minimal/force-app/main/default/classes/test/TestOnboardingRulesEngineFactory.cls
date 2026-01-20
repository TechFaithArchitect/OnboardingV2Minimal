@isTest
public class TestOnboardingRulesEngineFactory {

    public static Onboarding_Status_Rules_Engine__c create(Boolean doInsert,
                                                           Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup,
                                                           Vendor_Program_Group__c vendorProgramGroup,
                                                           String evaluationLogic,
                                                           String requiredStatus,
                                                           String targetStatus) {
        Onboarding_Status_Rules_Engine__c onboardingStatusRulesEngine = new Onboarding_Status_Rules_Engine__c(
            Name = 'Test Rules Engine ' + DateTime.now().getTime(),
            Active__c = true,
            Requirement_Group__c = vendorProgramRequirementGroup != null ? vendorProgramRequirementGroup.Id : null,
            Vendor_Program_Group__c = vendorProgramGroup != null ? vendorProgramGroup.Id : null,
            Evaluation_Logic__c = evaluationLogic != null ? evaluationLogic : 
                TestDataFactoryUtil.getFirstPicklistValue(
                    Onboarding_Status_Rules_Engine__c.SObjectType,
                    'Evaluation_Logic__c'
                ),
            Required_Status__c = requiredStatus != null ? requiredStatus : 
                TestDataFactoryUtil.getFirstPicklistValue(
                    Onboarding_Status_Rules_Engine__c.SObjectType,
                    'Required_Status__c'
                ),
            Target_Onboarding_Status__c = targetStatus != null ? targetStatus : 
                TestDataFactoryUtil.getFirstPicklistValue(
                    Onboarding_Status_Rules_Engine__c.SObjectType,
                    'Target_Onboarding_Status__c'
                )
        );
        TestDataFactoryUtil.maybeInsert(onboardingStatusRulesEngine, doInsert);
        return onboardingStatusRulesEngine;
    }

    public static Onboarding_Status_Rules_Engine__c create(Boolean doInsert) {
        Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup = TestVendorProgramRequirementGroupFactory.create(doInsert);
        Vendor_Program_Group__c vendorProgramGroup = TestVendorProgramGroupFactory.create(doInsert);

        return create(doInsert, vendorProgramRequirementGroup, vendorProgramGroup, null, null, null);
    }
}