/**
 * Centralized, minimal logging for validation outcomes.
 * Stores status and metadata only—no field values/PII.
 */
public with sharing class RequirementValidationLogger {

    public class LogEntry {
        public Id fieldValueId;
        public String fieldApiName;
        public String validationResult;
        public String validationType;
        public String message;
        public String ruleName;
        public String correlationId;
        public Datetime validatedOn;
    }

    public static void log(List<LogEntry> entries) {
        if (entries == null || entries.isEmpty()) {
            return;
        }
        List<Validation_Failure__c> validationFailureRecords = new List<Validation_Failure__c>();
        for (LogEntry logEntry : entries) {
            if (logEntry == null || logEntry.fieldValueId == null) {
                continue;
            }
            Validation_Failure__c validationFailure = new Validation_Failure__c();
            validationFailure.Requirement_Field_Value__c = logEntry.fieldValueId;
            validationFailure.Requirement_Field__c = logEntry.fieldApiName;
            String normalizedResult = normalizeValidationResult(logEntry.validationResult);
            if (String.isNotBlank(normalizedResult)) {
                validationFailure.Validation_Result__c = normalizedResult;
            }
            String normalizedType = normalizeValidationType(logEntry.validationType);
            if (String.isNotBlank(normalizedType)) {
                validationFailure.Validation_Type__c = normalizedType;
            }
            validationFailure.Message__c = logEntry.message;
            validationFailure.Rule_Name__c = logEntry.ruleName;
            validationFailure.Correlation_Id__c = logEntry.correlationId;
            validationFailure.Validated_On__c = logEntry.validatedOn != null ? logEntry.validatedOn : Datetime.now();
            validationFailureRecords.add(validationFailure);
        }
        if (!validationFailureRecords.isEmpty()) {
            insert validationFailureRecords;
        }
    }

    private static String normalizeValidationType(String validationType) {
        if (String.isBlank(validationType)) {
            return null;
        }
        String lowered = validationType.toLowerCase();
        if (lowered.startsWith('external')) {
            return 'External';
        }
        if (lowered.contains('cross')) {
            return 'Cross-Field';
        }
        if (lowered == 'format') {
            return 'Format';
        }
        return 'Other';
    }

    private static String normalizeValidationResult(String validationResult) {
        if (String.isBlank(validationResult)) {
            return null;
        }
        String normalized = validationResult.replace('_', ' ').trim();
        if (normalized.equalsIgnoreCase('pending')) {
            return 'Pending';
        }
        if (normalized.equalsIgnoreCase('valid')) {
            return 'Valid';
        }
        if (normalized.equalsIgnoreCase('invalid')) {
            return 'Invalid';
        }
        if (normalized.equalsIgnoreCase('needs correction')) {
            return 'Needs Correction';
        }
        if (normalized.equalsIgnoreCase('failed')) {
            return 'Failed';
        }
        return null;
    }
}