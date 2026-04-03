public with sharing class RecordCollectionEditorGetRecordsService {

    private static final String PRINCIPAL_OWNER_ACR_ROLE = 'Principal Owner';

    @TestVisible
    private static Boolean forceOuterExceptionForTest = false;

    public class GetRecordsJsonRequest {
        @InvocableVariable(required=true label='Config Key')
        public String configKey;
        @InvocableVariable(required=true label='Records')
        public List<SObject> records;
        @InvocableVariable(label='Relationship Records')
        public List<SObject> relationshipRecords;
    }

    public class GetRecordsJsonResult {
        @InvocableVariable(label='Records JSON')
        public String recordsJson;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Records JSON for Editor'
        description='Converts a Record Collection to JSON for the Record Collection Editor. Use before the screen when editing existing records.'
    )
    public static List<GetRecordsJsonResult> getRecordsJsonForEditor(List<GetRecordsJsonRequest> requests) {
        List<GetRecordsJsonResult> results = new List<GetRecordsJsonResult>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        for (GetRecordsJsonRequest req : requests) {
            GetRecordsJsonResult res = new GetRecordsJsonResult();
            try {
                if (forceOuterExceptionForTest) {
                    throw new IllegalArgumentException('forced editor failure for test');
                }
                if (req == null || String.isBlank(req.configKey) || req.records == null || req.records.isEmpty()) {
                    res.errorMessage = 'configKey and records are required.';
                    results.add(res);
                    continue;
                }

                List<Child_Record_Editor_Config__mdt> configList = new List<Child_Record_Editor_Config__mdt>();
                if (Schema.sObjectType.Child_Record_Editor_Config__mdt.isAccessible()) {
                    configList = [
                        SELECT Id, Object_API_Name__c, Parent_Field_API_Name__c,
                            Relationship_Object_API_Name__c, Relationship_Parent_Field__c, Relationship_Child_Field__c,
                            Relationship_Fields_JSON__c, Fields_JSON__c
                        FROM Child_Record_Editor_Config__mdt
                        WHERE DeveloperName = :req.configKey
                        LIMIT 1
                    ];
                }
                if (configList.isEmpty()) {
                    res.errorMessage = 'No config found for key: ' + req.configKey;
                    results.add(res);
                    continue;
                }

                Child_Record_Editor_Config__mdt cmdt = configList[0];
                Schema.SObjectType recordsType = req.records[0].getSObjectType();
                Map<String, Schema.SObjectField> childFieldMap =
                    recordsType.getDescribe().fields.getMap();

                if ('CONTACT_ON_OPPORTUNITY'.equals(req.configKey) && recordsType == Contact.SObjectType) {
                    Set<Id> contactIds = new Set<Id>();
                    Map<Id, Id> contactIdToAccountId = new Map<Id, Id>();
                    for (SObject con : req.records) {
                        Id contactId = (Id) con.get('Id');
                        Id accountId = (Id) con.get('AccountId');
                        if (contactId == null) {
                            continue;
                        }
                        contactIds.add(contactId);
                        if (accountId != null) {
                            contactIdToAccountId.put(contactId, accountId);
                        }
                    }

                    Set<Id> principalOwnerContactIds = new Set<Id>();
                    if (!contactIds.isEmpty() && !contactIdToAccountId.isEmpty()) {
                        for (AccountContactRelation acr : [
                            SELECT ContactId, AccountId
                            FROM AccountContactRelation
                            WHERE
                                ContactId IN :contactIds
                                AND AccountId IN :contactIdToAccountId.values()
                                AND IsActive = TRUE
                                AND Roles INCLUDES (:PRINCIPAL_OWNER_ACR_ROLE)
                            WITH SECURITY_ENFORCED
                        ]) {
                            if (contactIdToAccountId.get(acr.ContactId) == acr.AccountId) {
                                principalOwnerContactIds.add(acr.ContactId);
                            }
                        }
                    }

                    Boolean primaryAssigned = false;
                    List<Map<String, Object>> output = new List<Map<String, Object>>();
                    for (SObject con : req.records) {
                        Id contactId = (Id) con.get('Id');
                        if (contactId == null) {
                            continue;
                        }
                        Boolean isPrincipalOwner = principalOwnerContactIds.contains(contactId);
                        Boolean isPrimary = isPrincipalOwner && !primaryAssigned;
                        if (isPrimary) {
                            primaryAssigned = true;
                        }
                        output.add(
                            new Map<String, Object>{
                                'ContactId' => contactId,
                                'Role' => isPrincipalOwner ? PRINCIPAL_OWNER_ACR_ROLE : null,
                                'IsPrimary' => isPrimary
                            }
                        );
                    }
                    res.recordsJson = JSON.serialize(output);
                    results.add(res);
                    continue;
                }

                Set<String> childFieldNames = new Set<String>();
                List<Object> rawFields;
                try {
                    rawFields = (List<Object>) JSON.deserializeUntyped(cmdt.Fields_JSON__c.trim());
                } catch (Exception e) {
                    res.errorMessage = 'Invalid Fields_JSON__c: ' + e.getMessage();
                    results.add(res);
                    continue;
                }
                for (Object raw : rawFields) {
                    Map<String, Object> f = (Map<String, Object>) raw;
                    String apiName = (String) f.get('fieldApiName');
                    if (String.isBlank(apiName)) {
                        continue;
                    }
                    Schema.SObjectField childField = childFieldMap.get(apiName);
                    if (childField == null || !childField.getDescribe().isAccessible()) {
                        continue;
                    }
                    childFieldNames.add(apiName);
                }
                childFieldNames.add('Id');
                childFieldNames.add(cmdt.Parent_Field_API_Name__c);

                List<String> relFieldNames = new List<String>();
                String relObjName = cmdt.Relationship_Object_API_Name__c;
                String relChildField = cmdt.Relationship_Child_Field__c;
                String relParentField = cmdt.Relationship_Parent_Field__c;
                String relFieldsJson = cmdt.Relationship_Fields_JSON__c;
                Map<String, Schema.SObjectField> relFieldMap = new Map<String, Schema.SObjectField>();
                if (String.isNotBlank(relObjName) && String.isNotBlank(relFieldsJson)) {
                    Schema.SObjectType relType = Schema.getGlobalDescribe().get(relObjName);
                    relFieldMap = relType == null
                        ? new Map<String, Schema.SObjectField>()
                        : relType.getDescribe().fields.getMap();
                    try {
                        List<Object> rawRel = (List<Object>) JSON.deserializeUntyped(relFieldsJson.trim());
                        for (Object raw : rawRel) {
                            Map<String, Object> f = (Map<String, Object>) raw;
                            String apiName = (String) f.get('fieldApiName');
                            if (String.isBlank(apiName)) {
                                continue;
                            }
                            Schema.SObjectField relField = relFieldMap.get(apiName);
                            if (relField == null || !relField.getDescribe().isAccessible()) {
                                continue;
                            }
                            relFieldNames.add(apiName);
                        }
                    } catch (Exception e) { }
                }

                Map<String, SObject> acrByChildAndParent = new Map<String, SObject>();
                if (req.relationshipRecords != null && !req.relationshipRecords.isEmpty()) {
                    for (SObject acr : req.relationshipRecords) {
                        Id childId = (Id) acr.get(relChildField);
                        Id parentId = (Id) acr.get(relParentField);
                        if (childId != null && parentId != null) {
                            acrByChildAndParent.put(relationshipPairKey(parentId, childId), acr);
                        }
                    }
                }

                if (!relFieldNames.isEmpty() && String.isNotBlank(relObjName)) {
                    if (
                        String.isBlank(relChildField) ||
                        String.isBlank(relParentField) ||
                        !relFieldMap.containsKey(relChildField) ||
                        !relFieldMap.containsKey(relParentField)
                    ) {
                        res.errorMessage = 'Invalid relationship field configuration for key: ' + req.configKey;
                        results.add(res);
                        continue;
                    }

                    Set<Id> fallbackChildIds = new Set<Id>();
                    Set<Id> fallbackParentIds = new Set<Id>();
                    for (SObject rec : req.records) {
                        Id childId = tryCastToId(safeGetFieldValue(rec, 'Id'));
                        Id parentId = tryCastToId(safeGetFieldValue(rec, cmdt.Parent_Field_API_Name__c));
                        if (childId == null || parentId == null) {
                            continue;
                        }
                        if (!acrByChildAndParent.containsKey(relationshipPairKey(parentId, childId))) {
                            fallbackChildIds.add(childId);
                            fallbackParentIds.add(parentId);
                        }
                    }

                    if (!fallbackChildIds.isEmpty() && !fallbackParentIds.isEmpty()) {
                        Set<String> selectFieldSet = new Set<String>{
                            'Id',
                            relChildField,
                            relParentField
                        };
                        selectFieldSet.addAll(relFieldNames);
                        List<String> selectFieldList = new List<String>(selectFieldSet);
                        selectFieldList.sort();

                        String q = 'SELECT ' + String.join(selectFieldList, ', ') + ' FROM ' + relObjName +
                            ' WHERE ' + relChildField + ' IN :fallbackChildIds' +
                            ' AND ' + relParentField + ' IN :fallbackParentIds' +
                            ' WITH SECURITY_ENFORCED';

                        for (SObject acr : Database.query(q)) {
                            Id childId = tryCastToId(safeGetFieldValue(acr, relChildField));
                            Id parentId = tryCastToId(safeGetFieldValue(acr, relParentField));
                            if (childId != null && parentId != null) {
                                acrByChildAndParent.put(relationshipPairKey(parentId, childId), acr);
                            }
                        }
                    }
                }

                List<Map<String, Object>> output = new List<Map<String, Object>>();
                for (SObject rec : req.records) {
                    Map<String, Object> childData = new Map<String, Object>();
                    for (String fName : childFieldNames) {
                        if (rec.getSObjectType().getDescribe().fields.getMap().containsKey(fName)) {
                            Object val = safeGetFieldValue(rec, fName);
                            if (val != null) childData.put(fName, val);
                        }
                    }
                    if (!childData.containsKey('Id')) childData.put('Id', rec.Id);

                    Map<String, Object> relData = new Map<String, Object>();
                    if (!relFieldNames.isEmpty() && String.isNotBlank(relObjName)) {
                        Id childId = tryCastToId(safeGetFieldValue(rec, 'Id'));
                        Id parentId = tryCastToId(safeGetFieldValue(rec, cmdt.Parent_Field_API_Name__c));
                        if (childId != null && parentId != null) {
                            SObject acr = acrByChildAndParent.isEmpty()
                                ? null
                                : acrByChildAndParent.get(relationshipPairKey(parentId, childId));
                            if (acr != null) {
                                for (String fName : relFieldNames) {
                                    Object val = safeGetFieldValue(acr, fName);
                                    if (val != null) relData.put(fName, val);
                                }
                            }
                        }
                    }

                    if (relFieldNames.isEmpty()) {
                        output.add(childData);
                    } else {
                        output.add(new Map<String, Object>{ 'child' => childData, 'relationship' => relData });
                    }
                }

                res.recordsJson = JSON.serialize(output);
            } catch (Exception e) {
                String technical =
                    RecordCollectionEditorGetRecordsService.class.getName() +
                    ' | ' + e.getTypeName() + ': ' + e.getMessage() +
                    '\n' + e.getStackTraceString();
                OnboardingErrorLogService.FaultInput faultIn = new OnboardingErrorLogService.FaultInput();
                faultIn.technicalDetail = technical;
                faultIn.userMessageBase = 'Unable to prepare records for editor.';
                faultIn.errorLogType = 'Apex';
                faultIn.providerSubtypeOverrideText = 'Record Collection Editor';
                faultIn.sourceFlowApiName = RecordCollectionEditorGetRecordsService.class.getName();
                faultIn.sourceElementApiName = RecordCollectionEditorGetRecordsService.class.getName();
                OnboardingErrorLogService.FaultOutcome outcome = OnboardingErrorLogService.persistFault(faultIn);
                res.errorMessage = outcome.userFacingMessage;
                LoggingUtil.error(
                    'RecordCollectionEditorGetRecordsService.getRecordsJsonForEditor [' +
                    outcome.errorLogId + ']: ' + e.getMessage()
                );
            }
            results.add(res);
        }
        return results;
    }

    private static String relationshipPairKey(Id parentId, Id childId) {
        return String.valueOf(parentId) + '|' + String.valueOf(childId);
    }

    private static Object safeGetFieldValue(SObject record, String fieldApiName) {
        if (record == null || String.isBlank(fieldApiName)) {
            return null;
        }
        try {
            return record.get(fieldApiName);
        } catch (SObjectException ex) {
            return null;
        }
    }

    private static Id tryCastToId(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Id) {
            return (Id) value;
        }
        try {
            return Id.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }

}
