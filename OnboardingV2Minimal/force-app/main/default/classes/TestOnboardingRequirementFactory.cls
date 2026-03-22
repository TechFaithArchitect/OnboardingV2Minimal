@isTest
public class TestOnboardingRequirementFactory {
    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Boolean completed,
        Boolean isOverridden,
        Onboarding__c onboarding,
        String requirementType,
        Integer sequence,
        String status,
        Vendor_Program_Requirement__c vendorProgramRequirement
    ) {
        return create(
            doInsert,
            completed,
            isOverridden,
            onboarding,
            requirementType,
            sequence,
            status,
            vendorProgramRequirement,
            null
        );
    }

    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Boolean completed,
        Boolean isOverridden,
        Onboarding__c onboarding,
        String requirementType,
        Integer sequence,
        String status,
        Vendor_Program_Requirement__c vendorProgramRequirement,
        Id recordTypeId
    ) {
        Onboarding_Requirement__c onboardingRequirement = new Onboarding_Requirement__c(
            Completed__c = completed != null ? completed : false,
            Is_Overridden__c = isOverridden != null ? isOverridden : false,
            Onboarding__c = onboarding != null ? onboarding.Id : null,
            Sequence__c = sequence != null ? sequence : 1,
            Vendor_Program_Requirement__c = vendorProgramRequirement != null ? vendorProgramRequirement.Id : null
        );

        if (recordTypeId != null) {
            onboardingRequirement.RecordTypeId = recordTypeId;
        }

        if (String.isNotBlank(requirementType)) {
            onboardingRequirement.Requirement_Type__c = requirementType;
        }

        if (!doInsert) {
            if (String.isNotBlank(status)) {
                onboardingRequirement.Status__c = status;
            }
            return onboardingRequirement;
        }

        TestDataFactoryUtil.maybeInsert(onboardingRequirement, doInsert);

        if (String.isNotBlank(status)) {
            applyStatusIfValid(onboardingRequirement.Id, status);
            onboardingRequirement = [
                SELECT
                    Id,
                    Completed__c,
                    Is_Overridden__c,
                    Onboarding__c,
                    Sequence__c,
                    Vendor_Program_Requirement__c,
                    Requirement_Type__c,
                    Status__c
                FROM Onboarding_Requirement__c
                WHERE Id = :onboardingRequirement.Id
                LIMIT 1
            ];
        }

        return onboardingRequirement;
    }

    public static Onboarding_Requirement__c create(
        Boolean doInsert,
        Onboarding__c onboarding,
        Vendor_Program_Requirement__c vendorProgramRequirement
    ) {
        return create(
            doInsert,
            false,      
            false,           
            onboarding,
            null,   // Will use default from picklist      
            1,          
            null,   // Will use default from picklist
            vendorProgramRequirement
        );
    }

    public static Onboarding_Requirement__c create(Boolean doInsert) {
        Onboarding__c onboarding = TestOnboardingFactory.create(
            TestDataFactory.createAccount('Acct', doInsert),
            TestVendorProgramFactory.createVendorWithCustomization(doInsert).customization,
            doInsert
        );

        Vendor_Program_Requirement__c vendorProgramRequirement = TestVendorProgramRequirementFactory.create(doInsert);

        return create(doInsert, onboarding, vendorProgramRequirement);
    }

    @TestVisible
    private static Boolean applyStatusIfValid(Id onboardingRequirementId, String statusValue) {
        if (onboardingRequirementId == null || String.isBlank(statusValue)) {
            return false;
        }

        Database.SaveResult saveResult = Database.update(
            new Onboarding_Requirement__c(
                Id = onboardingRequirementId,
                Status__c = statusValue
            ),
            false
        );
        return saveResult != null && saveResult.isSuccess();
    }
}
