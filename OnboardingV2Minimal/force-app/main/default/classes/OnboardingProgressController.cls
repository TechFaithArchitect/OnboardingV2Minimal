public with sharing class OnboardingProgressController {
    private static final String NORMALIZED_SETUP_COMPLETE = 'Setup Complete';
    private static final String NORMALIZED_SIGNED = 'Signed';
    private static final String NORMALIZED_COMPLETE = 'Complete';
    private static final String NORMALIZED_IGNORE = 'Ignore';

    @AuraEnabled
    public static Integer getCompletionPercent(Id recordId) {
        if (recordId == null) {
            return 0;
        }

        List<Onboarding_Requirement__c> requirements = [
            SELECT Requirement_Type__c, Status__c
            FROM Onboarding_Requirement__c
            WHERE Onboarding__c = :recordId
            WITH SECURITY_ENFORCED
        ];

        if (requirements.isEmpty()) {
            return 0;
        }

        Set<String> applicableRequirementTypesLowercase =
            loadApplicableProgramRequirementTypesLowercase(recordId);
        Map<String, String> normalizationMap =
            OnboardingStatusNormalizationService.loadActiveNormalizationMap();

        Integer scopedTotalCount = 0;
        Integer scopedTerminalCount = 0;
        Boolean hasApplicableTemplateTypes = !applicableRequirementTypesLowercase.isEmpty();

        for (Onboarding_Requirement__c requirementRecord : requirements) {
            String requirementType = requirementRecord.Requirement_Type__c == null
                ? null
                : requirementRecord.Requirement_Type__c.trim();
            Boolean inScope = !hasApplicableTemplateTypes ||
                (
                    !String.isBlank(requirementType) &&
                    applicableRequirementTypesLowercase.contains(requirementType.toLowerCase())
                );
            if (!inScope) {
                continue;
            }

            scopedTotalCount++;
            String normalizedStatus = OnboardingStatusNormalizationService.normalize(
                requirementType,
                requirementRecord.Status__c,
                normalizationMap
            );
            if (isTerminalNormalizedStatus(normalizedStatus)) {
                scopedTerminalCount++;
            }
        }

        // Match evaluator fallback: if template types are present but none match row requirement types,
        // evaluate all onboarding requirement rows instead of returning 0.
        if (hasApplicableTemplateTypes && scopedTotalCount == 0) {
            for (Onboarding_Requirement__c requirementRecord : requirements) {
                scopedTotalCount++;
                String requirementType = requirementRecord.Requirement_Type__c == null
                    ? null
                    : requirementRecord.Requirement_Type__c.trim();
                String normalizedStatus = OnboardingStatusNormalizationService.normalize(
                    requirementType,
                    requirementRecord.Status__c,
                    normalizationMap
                );
                if (isTerminalNormalizedStatus(normalizedStatus)) {
                    scopedTerminalCount++;
                }
            }
        }

        return Math.round(
            (Decimal.valueOf(scopedTerminalCount) / Decimal.valueOf(scopedTotalCount)) * 100
        );
    }

    private static Set<String> loadApplicableProgramRequirementTypesLowercase(Id recordId) {
        Set<String> applicableTypes = new Set<String>();
        List<Onboarding__c> onboardingRecords = [
            SELECT Vendor_Customization__c
            FROM Onboarding__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (
            onboardingRecords.isEmpty() ||
            onboardingRecords[0].Vendor_Customization__c == null
        ) {
            return applicableTypes;
        }

        for (Vendor_Program_Requirement__c requirementTemplate : [
            SELECT Requirement_Type__c
            FROM Vendor_Program_Requirement__c
            WHERE
                Vendor_Program__c = :onboardingRecords[0].Vendor_Customization__c
                AND Active__c = true
                AND Is_Required__c = true
            WITH SECURITY_ENFORCED
        ]) {
            if (String.isBlank(requirementTemplate.Requirement_Type__c)) {
                continue;
            }
            applicableTypes.add(requirementTemplate.Requirement_Type__c.trim().toLowerCase());
        }
        return applicableTypes;
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
}
