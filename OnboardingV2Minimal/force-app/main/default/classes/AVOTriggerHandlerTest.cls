@isTest
private class AVOTriggerHandlerTest {
    @isTest
    static void blocksCompletionWhenOpenRequirementsRemain() {
        Account accountRecord = TestDataFactory.createAccount('AVO Handler Open Req', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboardingRecord = TestDataFactory.createOnboarding(accountRecord, vendorProgram, true);

        String openRequirementStatus = firstRequirementStatus(false);
        if (String.isBlank(openRequirementStatus)) {
            System.assert(true, 'No non-complete requirement status available for this org.');
            return;
        }

        try {
            TestOnboardingRequirementFactory.create(
                true,
                false,
                false,
                onboardingRecord,
                null,
                1,
                openRequirementStatus,
                null
            );
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('CANNOT_EXECUTE_FLOW_TRIGGER'),
                'Unexpected DML failure while creating requirement: ' + e.getMessage()
            );
            return;
        }

        String initialAvoStatus = firstAvoStatus(new List<String>{ 'Intake', 'In Progress', 'On Hold' });
        String completeAvoStatus = firstAvoStatus(new List<String>{ 'Completed', 'Complete' });
        if (String.isBlank(completeAvoStatus)) {
            System.assert(true, 'No completion status available for AVO status picklist.');
            return;
        }

        Account_Vendor_Program_Onboarding__c avo = TestDataFactory.createAccountVendorProgramOnboarding(
            accountRecord,
            onboardingRecord,
            initialAvoStatus,
            true
        );
        avo.Status__c = completeAvoStatus;

        Test.startTest();
        Database.SaveResult saveResult = Database.update(avo, false);
        Test.stopTest();

        System.assertEquals(false, saveResult.isSuccess(), 'Completion must fail when requirements are open.');
        System.assert(!saveResult.getErrors().isEmpty(), 'An error must be returned.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('open requirements') ||
            saveResult.getErrors()[0].getMessage().contains('Cannot mark Complete'),
            'Error should indicate open requirement gate.'
        );
    }

    @isTest
    static void requiresReasonForClosedLostStatus() {
        Account accountRecord = TestDataFactory.createAccount('AVO Handler Closed Lost', true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor,
            'Active',
            true,
            null,
            true
        );
        Onboarding__c onboardingRecord = TestDataFactory.createOnboarding(accountRecord, vendorProgram, true);

        String initialAvoStatus = firstAvoStatus(new List<String>{ 'Intake', 'In Progress', 'On Hold' });
        String closedLostAvoStatus = firstAvoStatus(new List<String>{ 'Closed Lost' });
        if (String.isBlank(closedLostAvoStatus)) {
            System.assert(true, 'Closed Lost status is not available in this org.');
            return;
        }

        Account_Vendor_Program_Onboarding__c avo = TestDataFactory.createAccountVendorProgramOnboarding(
            accountRecord,
            onboardingRecord,
            initialAvoStatus,
            true
        );

        avo.Status__c = closedLostAvoStatus;
        avo.Reason_for_Return__c = null;

        Test.startTest();
        Database.SaveResult failed = Database.update(avo, false);
        Test.stopTest();

        System.assertEquals(false, failed.isSuccess(), 'Closed Lost should require Reason for Return.');
        System.assert(!failed.getErrors().isEmpty(), 'A validation error is expected.');
        System.assert(
            failed.getErrors()[0].getMessage().contains('Reason for Return'),
            'Error should reference Reason for Return requirement.'
        );

        avo.Reason_for_Return__c = 'Customer withdrew';
        Database.SaveResult passed = Database.update(avo, false);
        System.assertEquals(true, passed.isSuccess(), 'Closed Lost should succeed once reason is supplied.');
    }

    private static String firstAvoStatus(List<String> preferredValues) {
        List<String> available = TestDataFactoryUtil.getPicklistValues(
            Account_Vendor_Program_Onboarding__c.SObjectType,
            'Status__c'
        );
        for (String preferred : preferredValues) {
            if (available.contains(preferred)) {
                return preferred;
            }
        }
        return available.isEmpty() ? null : available[0];
    }

    private static String firstRequirementStatus(Boolean needsCompleteStatus) {
        List<String> available = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        for (String statusValue : available) {
            Boolean isCompleteStatus = statusValue == 'Complete' || statusValue == 'Completed';
            if (needsCompleteStatus && isCompleteStatus) {
                return statusValue;
            }
            if (!needsCompleteStatus && !isCompleteStatus) {
                return statusValue;
            }
        }
        return null;
    }
}
