public with sharing class OnboardingStatusTrackerHandler {

     // existing cache
    private static Map<String, List<Onboarding_Status_Tracking_Config__mdt>> CONFIGS_BY_OBJECT;

    // ---- TEST HOOKS ----
    @TestVisible private static Map<String, List<Onboarding_Status_Tracking_Config__mdt>> TEST_CONFIGS;

    @TestVisible
    static void setTestConfigs(Map<String, List<Onboarding_Status_Tracking_Config__mdt>> configs) {
        TEST_CONFIGS = configs;
        CONFIGS_BY_OBJECT = null; // reset cache so handler uses injected configs
    }

    private static Map<String, List<Onboarding_Status_Tracking_Config__mdt>> getConfigsByObject() {
        if (Test.isRunningTest() && TEST_CONFIGS != null) {
            return TEST_CONFIGS;
        }
        if (CONFIGS_BY_OBJECT == null) {
            CONFIGS_BY_OBJECT = new Map<String, List<Onboarding_Status_Tracking_Config__mdt>>();
            for (Onboarding_Status_Tracking_Config__mdt c : [
                SELECT Object__c, Field__c, Lookup_To_Onboarding__c, IsActive__c
                FROM Onboarding_Status_Tracking_Config__mdt
                WHERE IsActive__c = TRUE
            ]) {
                if (!CONFIGS_BY_OBJECT.containsKey(c.Object__c)) {
                    CONFIGS_BY_OBJECT.put(c.Object__c, new List<Onboarding_Status_Tracking_Config__mdt>());
                }
                CONFIGS_BY_OBJECT.get(c.Object__c).add(c);
            }
        }
        return CONFIGS_BY_OBJECT;
    }

    // Simple carrier for detected changes
    private class Hit {
        String lookupField;
        String field;
        Id     targetId;
        String oldVal;
        String newVal;
    }

    public static void handleStatusTracking(Map<Id, SObject> oldMap, Map<Id, SObject> newMap, String objectApiName) {
        if (OnboardingExpirationEvaluator.bypassTracking) {
            System.debug('🚫 Skipping status tracking due to bypass flag');
            return;
        }

        Map<String, List<Onboarding_Status_Tracking_Config__mdt>> configsByObject = getConfigsByObject();
        if (!configsByObject.containsKey(objectApiName)) return;

        // Cache field describes once
        Map<String, SObjectField> fieldMap = newMap.values().isEmpty()
            ? new Map<String, SObjectField>()
            : newMap.values().iterator().next().getSObjectType().getDescribe().fields.getMap();

        // 1) Detect changes
        List<Hit> hits = new List<Hit>();
        for (Id recordId : newMap.keySet()) {
            SObject newRec = newMap.get(recordId);
            SObject oldRec = oldMap.get(recordId);

            for (Onboarding_Status_Tracking_Config__mdt cfg : configsByObject.get(objectApiName)) {
                String trackedField = cfg.Field__c;
                if (!fieldMap.containsKey(trackedField)) continue;

                Object oldV = oldRec.get(trackedField);
                Object newV = newRec.get(trackedField);

                Boolean changed = (oldV == null && newV != null)
                               || (oldV != null && newV != null && !oldV.equals(newV));
                if (!changed) continue;

                Id targetId = (Id)newRec.get('Id');
                if (targetId == null) continue;

                Hit h = new Hit();
                h.lookupField = cfg.Lookup_To_Onboarding__c;
                h.field       = trackedField;
                h.targetId    = targetId;
                h.oldVal      = String.valueOf(oldV);
                h.newVal      = String.valueOf(newV);
                hits.add(h);
            }
        }
        if (hits.isEmpty()) return;

        // 2) Group hits by lookup field -> Set of target Ids
        Map<String, Set<Id>> targetsByLookupField = new Map<String, Set<Id>>();
        for (Hit h : hits) {
            if (!targetsByLookupField.containsKey(h.lookupField)) {
                targetsByLookupField.put(h.lookupField, new Set<Id>());
            }
            targetsByLookupField.get(h.lookupField).add(h.targetId);
        }

        // 3) Query Onboarding__c in bulk per lookup field
        // Map<lookupField, Map<targetId, List<onboardingId>>>
        Map<String, Map<Id, List<Id>>> obByLookupThenTarget = new Map<String, Map<Id, List<Id>>>();

        for (String lookupField : targetsByLookupField.keySet()) {
            Set<Id> ids = targetsByLookupField.get(lookupField);
            if (ids.isEmpty()) continue;

            if (lookupField == 'Id') {
                if (!obByLookupThenTarget.containsKey(lookupField)) {
                    obByLookupThenTarget.put(lookupField, new Map<Id, List<Id>>());
                }
                Map<Id, List<Id>> targetMap = obByLookupThenTarget.get(lookupField);
                for (Id idVal : ids) {
                    if (!targetMap.containsKey(idVal)) {
                        targetMap.put(idVal, new List<Id>());
                    }
                    targetMap.get(idVal).add(idVal);   // onb maps to itself
                }
                continue; // skip dynamic SOQL
            }

            String soql = 'SELECT Id, ' + lookupField + ' FROM Onboarding__c WHERE ' + lookupField + ' IN :ids';
            for (Onboarding__c ob : Database.query(soql)) {
                Id key = (Id)ob.get(lookupField);
                if (key == null) continue; // Skip if lookup field is null
                
                if (!obByLookupThenTarget.containsKey(lookupField)) {
                    obByLookupThenTarget.put(lookupField, new Map<Id, List<Id>>());
                }
                Map<Id, List<Id>> targetMap = obByLookupThenTarget.get(lookupField);
                if (!targetMap.containsKey(key)) {
                    targetMap.put(key, new List<Id>());
                }
                targetMap.get(key).add(ob.Id);
            }
        }


        // 4) Build logs
        List<Onboarding_Status_Change__c> logsToInsert = new List<Onboarding_Status_Change__c>();
        String sourceLabel = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getLabel();

        for (Hit h : hits) {
            Map<Id, List<Id>> targetMap = obByLookupThenTarget.get(h.lookupField); // renamed from 'inner'
            if (targetMap == null) continue;
            List<Id> onboardingIds = targetMap.get(h.targetId);
            if (onboardingIds == null) continue;

            for (Id obId : onboardingIds) {
                logsToInsert.add(new Onboarding_Status_Change__c(
                    Onboarding__c      = obId,
                    Source_Object__c   = sourceLabel,
                    Field_Name__c      = h.field,
                    Old_Value__c       = h.oldVal,
                    New_Value__c       = h.newVal,
                    Changed_by_User__c = UserInfo.getUserId(),
                    Change_Date__c     = System.now()
                ));
            }
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
}