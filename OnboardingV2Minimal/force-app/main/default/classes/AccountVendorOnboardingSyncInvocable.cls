public with sharing class AccountVendorOnboardingSyncInvocable {
    private static final Set<String> ALLOWED_PRIMARY_CONTACT_ROLES = new Set<String>{
        'Principal Owner',
        'Owner',
        'Authorized Signer'
    };

    private static Set<String> avoStatusValuesCache;

    public class Request {
        @InvocableVariable(required=true)
        public Id onboardingId;
    }

    public class Response {
        @InvocableVariable
        public Id onboardingId;

        @InvocableVariable
        public Id accountVendorProgramOnboardingId;

        @InvocableVariable
        public Boolean created;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Sync Account Vendor Program Onboarding'
        description='Creates or updates Account Vendor Program Onboarding records from Onboarding records.'
    )
    public static List<Response> sync(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Id> onboardingIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.onboardingId != null) {
                onboardingIds.add(req.onboardingId);
            }
        }

        Map<Id, Response> responseByOnboardingId = new Map<Id, Response>();
        if (onboardingIds.isEmpty()) {
            for (Request req : requests) {
                Response res = baseResponse(req == null ? null : req.onboardingId);
                res.created = false;
                res.message = 'No onboardingId supplied.';
                responses.add(res);
            }
            return responses;
        }

        Map<Id, Onboarding__c> onboardingById = new Map<Id, Onboarding__c>([
            SELECT Id, Account__c, Opportunity__c, Onboarding_Status__c
            FROM Onboarding__c
            WHERE Id IN :onboardingIds
            WITH SECURITY_ENFORCED
        ]);

        Map<Id, Account_Vendor_Program_Onboarding__c> avoByOnboardingId =
            new Map<Id, Account_Vendor_Program_Onboarding__c>();
        for (Account_Vendor_Program_Onboarding__c avo : [
            SELECT Id, Account__c, Onboarding__c, Opportunity__c, Primary_Contact__c,
                   Status__c, Is_Active__c, Reason_for_Return__c
            FROM Account_Vendor_Program_Onboarding__c
            WHERE Onboarding__c IN :onboardingIds
            WITH SECURITY_ENFORCED
        ]) {
            avoByOnboardingId.put(avo.Onboarding__c, avo);
        }

        Set<Id> opportunityIds = new Set<Id>();
        for (Onboarding__c onboarding : onboardingById.values()) {
            if (onboarding.Opportunity__c != null) {
                opportunityIds.add(onboarding.Opportunity__c);
            }
        }

        Map<Id, Id> primaryContactByOpportunityId = new Map<Id, Id>();
        if (!opportunityIds.isEmpty()) {
            for (OpportunityContactRole ocr : [
                SELECT OpportunityId, ContactId, Role
                FROM OpportunityContactRole
                WHERE OpportunityId IN :opportunityIds
                  AND IsPrimary = true
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
            ]) {
                if (!ALLOWED_PRIMARY_CONTACT_ROLES.contains(ocr.Role)) {
                    continue;
                }
                if (!primaryContactByOpportunityId.containsKey(ocr.OpportunityId)) {
                    primaryContactByOpportunityId.put(ocr.OpportunityId, ocr.ContactId);
                }
            }
        }

        List<Account_Vendor_Program_Onboarding__c> toInsert = new List<Account_Vendor_Program_Onboarding__c>();
        List<Id> insertOnboardingIds = new List<Id>();
        List<Account_Vendor_Program_Onboarding__c> toUpdate = new List<Account_Vendor_Program_Onboarding__c>();
        List<Id> updateOnboardingIds = new List<Id>();

        for (Id onboardingId : onboardingIds) {
            Onboarding__c onboarding = onboardingById.get(onboardingId);
            Response res = baseResponse(onboardingId);
            responseByOnboardingId.put(onboardingId, res);

            if (onboarding == null) {
                res.created = false;
                res.message = 'Onboarding record not found.';
                continue;
            }

            Account_Vendor_Program_Onboarding__c existing = avoByOnboardingId.get(onboardingId);
            Id desiredPrimaryContactId = onboarding.Opportunity__c == null
                ? null
                : primaryContactByOpportunityId.get(onboarding.Opportunity__c);
            String desiredStatus = deriveAvoStatus(
                onboarding.Onboarding_Status__c,
                existing == null ? null : existing.Status__c,
                existing == null ? null : existing.Reason_for_Return__c
            );
            Boolean desiredIsActive = !isTerminalStatus(desiredStatus);

            if (existing == null) {
                Account_Vendor_Program_Onboarding__c created = new Account_Vendor_Program_Onboarding__c(
                    Account__c = onboarding.Account__c,
                    Onboarding__c = onboarding.Id,
                    Opportunity__c = onboarding.Opportunity__c,
                    Primary_Contact__c = desiredPrimaryContactId,
                    Status__c = desiredStatus,
                    Is_Active__c = desiredIsActive
                );
                toInsert.add(created);
                insertOnboardingIds.add(onboardingId);
                continue;
            }

            Boolean changed = false;
            if (existing.Account__c != onboarding.Account__c) {
                existing.Account__c = onboarding.Account__c;
                changed = true;
            }
            if (existing.Opportunity__c != onboarding.Opportunity__c) {
                existing.Opportunity__c = onboarding.Opportunity__c;
                changed = true;
            }
            if (existing.Primary_Contact__c != desiredPrimaryContactId) {
                existing.Primary_Contact__c = desiredPrimaryContactId;
                changed = true;
            }
            if (existing.Status__c != desiredStatus) {
                existing.Status__c = desiredStatus;
                changed = true;
            }
            if (existing.Is_Active__c != desiredIsActive) {
                existing.Is_Active__c = desiredIsActive;
                changed = true;
            }

            if (changed) {
                toUpdate.add(existing);
                updateOnboardingIds.add(onboardingId);
            } else {
                res.created = false;
                res.accountVendorProgramOnboardingId = existing.Id;
                res.message = 'No changes.';
            }
        }

        if (!toInsert.isEmpty()) {
            List<SObject> sanitizedForCreate = Security.stripInaccessible(
                AccessType.CREATABLE,
                toInsert
            ).getRecords();
            Database.SaveResult[] insertResults = Database.insert(
                (List<Account_Vendor_Program_Onboarding__c>) sanitizedForCreate,
                false
            );
            for (Integer i = 0; i < insertResults.size(); i++) {
                Id onboardingId = insertOnboardingIds[i];
                Response res = responseByOnboardingId.get(onboardingId);
                if (insertResults[i].isSuccess()) {
                    res.created = true;
                    res.accountVendorProgramOnboardingId = insertResults[i].getId();
                    res.message = 'Created.';
                } else {
                    res.created = false;
                    res.message = firstErrorMessage(insertResults[i]);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            List<SObject> sanitizedForUpdate = Security.stripInaccessible(
                AccessType.UPDATABLE,
                toUpdate
            ).getRecords();
            Database.SaveResult[] updateResults = Database.update(
                (List<Account_Vendor_Program_Onboarding__c>) sanitizedForUpdate,
                false
            );
            for (Integer i = 0; i < updateResults.size(); i++) {
                Id onboardingId = updateOnboardingIds[i];
                Response res = responseByOnboardingId.get(onboardingId);
                if (updateResults[i].isSuccess()) {
                    res.created = false;
                    res.accountVendorProgramOnboardingId = toUpdate[i].Id;
                    res.message = 'Updated.';
                } else {
                    res.created = false;
                    res.accountVendorProgramOnboardingId = toUpdate[i].Id;
                    res.message = firstErrorMessage(updateResults[i]);
                }
            }
        }

        for (Request req : requests) {
            Id onboardingId = req == null ? null : req.onboardingId;
            Response res = responseByOnboardingId.get(onboardingId);
            if (res == null) {
                res = baseResponse(onboardingId);
                res.created = false;
                res.message = onboardingId == null
                    ? 'No onboardingId supplied.'
                    : 'Onboarding was not processed.';
            }
            responses.add(res);
        }
        return responses;
    }

    private static Response baseResponse(Id onboardingId) {
        Response res = new Response();
        res.onboardingId = onboardingId;
        return res;
    }

    private static String firstErrorMessage(Database.SaveResult saveResult) {
        if (saveResult == null || saveResult.getErrors() == null || saveResult.getErrors().isEmpty()) {
            return 'Unknown DML failure.';
        }
        return saveResult.getErrors()[0].getMessage();
    }

    private static Boolean isTerminalStatus(String statusValue) {
        if (String.isBlank(statusValue)) {
            return false;
        }
        String normalized = statusValue.trim().toLowerCase();
        return normalized == 'closed lost' || normalized == 'complete' || normalized == 'completed';
    }

    private static String deriveAvoStatus(
        String onboardingStatus,
        String existingAvoStatus,
        String existingReasonForReturn
    ) {
        if (String.isBlank(onboardingStatus)) {
            return firstSupportedStatus(
                new List<String>{ existingAvoStatus, 'Intake', 'In Progress', 'On Hold' },
                existingAvoStatus
            );
        }

        String normalized = onboardingStatus.trim().toLowerCase();
        if (normalized == 'closed lost' || normalized == 'lost') {
            if (!String.isBlank(existingReasonForReturn)) {
                return firstSupportedStatus(new List<String>{ 'Closed Lost' }, existingAvoStatus);
            }
            return firstSupportedStatus(
                new List<String>{ existingAvoStatus, 'On Hold', 'In Progress', 'Intake' },
                existingAvoStatus
            );
        }
        if (normalized.contains('complete')) {
            return firstSupportedStatus(new List<String>{ 'Completed', 'Complete' }, existingAvoStatus);
        }
        if (normalized == 'on hold' || normalized == 'hold') {
            return firstSupportedStatus(new List<String>{ 'On Hold' }, existingAvoStatus);
        }
        if (normalized == 'intake' || normalized == 'not started' || normalized == 'new') {
            return firstSupportedStatus(new List<String>{ 'Intake' }, existingAvoStatus);
        }
        if (normalized == 'in progress' || normalized == 'in process' || normalized == 'processing') {
            return firstSupportedStatus(new List<String>{ 'In Progress' }, existingAvoStatus);
        }

        return firstSupportedStatus(
            new List<String>{ existingAvoStatus, 'In Progress', 'Intake' },
            existingAvoStatus
        );
    }

    private static String firstSupportedStatus(List<String> candidates, String fallback) {
        Set<String> allowedValues = getAvoStatusValues();
        for (String candidate : candidates) {
            if (String.isBlank(candidate)) {
                continue;
            }
            if (allowedValues.contains(candidate)) {
                return candidate;
            }
        }
        if (!String.isBlank(fallback) && allowedValues.contains(fallback)) {
            return fallback;
        }
        if (allowedValues.contains('Intake')) {
            return 'Intake';
        }
        for (String allowed : allowedValues) {
            return allowed;
        }
        return fallback;
    }

    private static Set<String> getAvoStatusValues() {
        if (avoStatusValuesCache == null) {
            avoStatusValuesCache = new Set<String>();
            for (Schema.PicklistEntry entry :
                Account_Vendor_Program_Onboarding__c.Status__c.getDescribe().getPicklistValues()
            ) {
                if (entry.isActive()) {
                    avoStatusValuesCache.add(entry.getValue());
                }
            }
        }
        return avoStatusValuesCache;
    }
}
