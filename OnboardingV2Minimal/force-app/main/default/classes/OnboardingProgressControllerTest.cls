@isTest
private class OnboardingProgressControllerTest {
    private static final String NORMALIZED_SETUP_COMPLETE = 'Setup Complete';
    private static final String NORMALIZED_SIGNED = 'Signed';
    private static final String NORMALIZED_COMPLETE = 'Complete';
    private static final String NORMALIZED_IGNORE = 'Ignore';

    private class RequirementStatusPair {
        String requirementType;
        String terminalStatus;
        String nonTerminalStatus;
    }

    private static Onboarding__c createOnboardingRecord() {
        Account accountRecord = new Account(Name = 'Progress Test Account');
        insert accountRecord;

        TestDataFactoryWrapper.VendorCustomizationWrapper vendorWrap =
            TestVendorProgramFactory.createVendorWithCustomization(true);

        Onboarding__c onboardingRecord = new Onboarding__c(
            Account__c = accountRecord.Id,
            Vendor_Customization__c = vendorWrap.customization.Id
        );
        insert onboardingRecord;
        return onboardingRecord;
    }

    private static String discoverInsertableRequirementType(Id onboardingId) {
        return discoverInsertableRequirementTypeExcluding(onboardingId, new Set<String>());
    }

    private static String discoverInsertableRequirementTypeExcluding(
        Id onboardingId,
        Set<String> excludedTypes
    ) {
        Set<String> excluded = excludedTypes == null ? new Set<String>() : excludedTypes;
        List<String> values = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Requirement_Type__c'
        );

        for (String candidate : values) {
            if (String.isBlank(candidate)) {
                continue;
            }
            if (excluded.contains(candidate)) {
                continue;
            }
            Database.SaveResult probeResult = Database.insert(
                new Onboarding_Requirement__c(
                    Onboarding__c = onboardingId,
                    Requirement_Type__c = candidate,
                    Is_Overridden__c = false
                ),
                false
            );
            if (probeResult.isSuccess()) {
                delete new Onboarding_Requirement__c(Id = probeResult.getId());
                return candidate;
            }
        }
        return null;
    }

    private static String discoverDifferentProgramRequirementType(String excludedType) {
        List<String> values = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Requirement__c.SObjectType,
            'Requirement_Type__c'
        );
        for (String candidate : values) {
            if (String.isBlank(candidate)) {
                continue;
            }
            if (excludedType != null && excludedType.equalsIgnoreCase(candidate)) {
                continue;
            }
            return candidate;
        }
        return null;
    }

    private static RequirementStatusPair discoverRequirementStatusPair(Id onboardingId) {
        List<String> requirementTypes = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Requirement_Type__c'
        );
        for (String requirementType : requirementTypes) {
            if (String.isBlank(requirementType)) {
                continue;
            }
            String terminalStatus = discoverInsertableStatusByTerminality(
                onboardingId,
                requirementType,
                true
            );
            if (terminalStatus == null) {
                continue;
            }
            String nonTerminalStatus = discoverInsertableStatusByTerminality(
                onboardingId,
                requirementType,
                false
            );
            if (nonTerminalStatus == null) {
                continue;
            }

            RequirementStatusPair pair = new RequirementStatusPair();
            pair.requirementType = requirementType;
            pair.terminalStatus = terminalStatus;
            pair.nonTerminalStatus = nonTerminalStatus;
            return pair;
        }
        return null;
    }

    private static String discoverInsertableStatusByTerminality(
        Id onboardingId,
        String requirementType,
        Boolean shouldBeTerminal
    ) {
        List<String> statusValues = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Requirement__c.SObjectType,
            'Status__c'
        );
        Map<String, String> normalizationMap =
            OnboardingStatusNormalizationService.loadActiveNormalizationMap();

        for (String statusValue : statusValues) {
            if (String.isBlank(statusValue)) {
                continue;
            }
            String normalizedStatus = OnboardingStatusNormalizationService.normalize(
                requirementType,
                statusValue,
                normalizationMap
            );
            if (isTerminalNormalizedStatus(normalizedStatus) != shouldBeTerminal) {
                continue;
            }

            Database.SaveResult probeResult = Database.insert(
                new Onboarding_Requirement__c(
                    Onboarding__c = onboardingId,
                    Requirement_Type__c = requirementType,
                    Status__c = statusValue,
                    Sequence__c = 999,
                    Is_Overridden__c = false
                ),
                false
            );
            if (probeResult.isSuccess()) {
                delete new Onboarding_Requirement__c(Id = probeResult.getId());
                return statusValue;
            }
        }

        return null;
    }

    private static Boolean isTerminalNormalizedStatus(String normalizedStatus) {
        if (String.isBlank(normalizedStatus)) {
            return false;
        }
        return NORMALIZED_SETUP_COMPLETE.equalsIgnoreCase(normalizedStatus) ||
            NORMALIZED_SIGNED.equalsIgnoreCase(normalizedStatus) ||
            NORMALIZED_COMPLETE.equalsIgnoreCase(normalizedStatus) ||
            NORMALIZED_IGNORE.equalsIgnoreCase(normalizedStatus);
    }

    private static void insertRequirement(
        Id onboardingId,
        String requirementType,
        String statusValue,
        Integer sequence
    ) {
        Database.SaveResult insertResult = Database.insert(
            new Onboarding_Requirement__c(
                Onboarding__c = onboardingId,
                Requirement_Type__c = requirementType,
                Status__c = statusValue,
                Sequence__c = sequence,
                Is_Overridden__c = false
            ),
            false
        );

        System.assert(
            insertResult != null && insertResult.isSuccess(),
            'Expected requirement insert to succeed for status ' + statusValue
        );
    }

    @isTest
    static void getCompletionPercent_returnsZeroWhenRecordIdIsNull() {
        Test.startTest();
        Integer percent = OnboardingProgressController.getCompletionPercent(null);
        Test.stopTest();

        System.assertEquals(0, percent, 'Null record id should return 0%.');
    }

    @isTest
    static void getCompletionPercent_returnsZeroWhenNoRequirementsExist() {
        Onboarding__c onboardingRecord = createOnboardingRecord();

        Test.startTest();
        Integer percent = OnboardingProgressController.getCompletionPercent(onboardingRecord.Id);
        Test.stopTest();

        System.assertEquals(0, percent, 'No requirements should return 0%.');
    }

    @isTest
    static void getCompletionPercent_usesNormalizedTerminalRatio() {
        Onboarding__c onboardingRecord = createOnboardingRecord();
        RequirementStatusPair statusPair = discoverRequirementStatusPair(onboardingRecord.Id);
        if (statusPair == null) {
            String requirementType = discoverInsertableRequirementType(onboardingRecord.Id);
            System.assertNotEquals(
                null,
                requirementType,
                'Expected at least one insertable requirement type in this org context.'
            );
            Database.SaveResult fallbackInsert = Database.insert(
                new Onboarding_Requirement__c(
                    Onboarding__c = onboardingRecord.Id,
                    Requirement_Type__c = requirementType,
                    Sequence__c = 1,
                    Is_Overridden__c = false
                ),
                false
            );
            System.assert(
                fallbackInsert != null && fallbackInsert.isSuccess(),
                'Expected fallback requirement insert to succeed.'
            );

            Test.startTest();
            Integer fallbackPercent = OnboardingProgressController.getCompletionPercent(
                onboardingRecord.Id
            );
            Test.stopTest();

            System.assertEquals(
                0,
                fallbackPercent,
                'When no terminal normalization path exists, progress should remain 0%.'
            );
            return;
        }

        String requirementType = statusPair.requirementType;
        String terminalStatus = statusPair.terminalStatus;
        String nonTerminalStatus = statusPair.nonTerminalStatus;
        System.assertNotEquals(
            null,
            requirementType,
            'Expected at least one insertable requirement type in this org context.'
        );

        System.assertNotEquals(
            null,
            terminalStatus,
            'Expected an insertable terminal status in this org context.'
        );
        System.assertNotEquals(
            null,
            nonTerminalStatus,
            'Expected an insertable non-terminal status in this org context.'
        );

        insertRequirement(onboardingRecord.Id, requirementType, terminalStatus, 1);
        insertRequirement(onboardingRecord.Id, requirementType, terminalStatus, 2);
        insertRequirement(onboardingRecord.Id, requirementType, nonTerminalStatus, 3);

        Test.startTest();
        Integer percent = OnboardingProgressController.getCompletionPercent(onboardingRecord.Id);
        Test.stopTest();

        System.assertEquals(
            67,
            percent,
            'Expected rounded completion percent based on normalized terminal count.'
        );
    }

    @isTest
    static void getCompletionPercent_doesNotOverrideFromParentOnboardingStatus() {
        Onboarding__c onboardingRecord = createOnboardingRecord();
        String requirementType = discoverInsertableRequirementType(onboardingRecord.Id);
        System.assertNotEquals(
            null,
            requirementType,
            'Expected at least one insertable requirement type in this org context.'
        );

        String nonTerminalStatus = discoverInsertableStatusByTerminality(
            onboardingRecord.Id,
            requirementType,
            false
        );
        if (nonTerminalStatus == null) {
            Database.SaveResult fallbackInsert = Database.insert(
                new Onboarding_Requirement__c(
                    Onboarding__c = onboardingRecord.Id,
                    Requirement_Type__c = requirementType,
                    Sequence__c = 1,
                    Is_Overridden__c = false
                ),
                false
            );
            System.assert(
                fallbackInsert != null && fallbackInsert.isSuccess(),
                'Expected fallback requirement insert to succeed.'
            );
        } else {
            insertRequirement(onboardingRecord.Id, requirementType, nonTerminalStatus, 1);
        }

        onboardingRecord.Onboarding_Status__c = NORMALIZED_SETUP_COMPLETE;
        update onboardingRecord;

        Test.startTest();
        Integer percent = OnboardingProgressController.getCompletionPercent(onboardingRecord.Id);
        Test.stopTest();

        System.assertEquals(
            0,
            percent,
            'Parent onboarding status should not override requirement-derived completion percent.'
        );
    }

    @isTest
    static void getCompletionPercent_fallsBackWhenTemplateTypesDoNotMatchRows() {
        Onboarding__c onboardingRecord = createOnboardingRecord();
        RequirementStatusPair statusPair = discoverRequirementStatusPair(onboardingRecord.Id);
        System.assertNotEquals(
            null,
            statusPair,
            'Expected to discover terminal + non-terminal statuses for at least one requirement type.'
        );

        String unmatchedTemplateType = discoverDifferentProgramRequirementType(
            statusPair.requirementType
        );
        System.assertNotEquals(
            null,
            unmatchedTemplateType,
            'Expected a second program requirement type for template mismatch coverage.'
        );

        TestVendorProgramRequirementFactory.createForProgram(
            new Vendor_Customization__c(Id = onboardingRecord.Vendor_Customization__c),
            unmatchedTemplateType,
            1,
            true,
            true,
            true
        );

        insertRequirement(onboardingRecord.Id, statusPair.requirementType, statusPair.terminalStatus, 1);

        Test.startTest();
        Integer percent = OnboardingProgressController.getCompletionPercent(onboardingRecord.Id);
        Test.stopTest();

        System.assertEquals(
            100,
            percent,
            'When template types do not match any onboarding rows, percent should fallback to all rows.'
        );
    }
}
