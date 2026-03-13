public with sharing class RecordCollectionEditorGetRecordsService {

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
                if (req == null || String.isBlank(req.configKey) || req.records == null || req.records.isEmpty()) {
                    res.errorMessage = 'configKey and records are required.';
                    results.add(res);
                    continue;
                }

                List<Child_Record_Editor_Config__mdt> configList = [
                    SELECT Id, Object_API_Name__c, Parent_Field_API_Name__c,
                        Relationship_Object_API_Name__c, Relationship_Parent_Field__c, Relationship_Child_Field__c,
                        Relationship_Fields_JSON__c, Fields_JSON__c
                    FROM Child_Record_Editor_Config__mdt
                    WHERE DeveloperName = :req.configKey
                    LIMIT 1
                ];
                if (configList.isEmpty()) {
                    res.errorMessage = 'No config found for key: ' + req.configKey;
                    results.add(res);
                    continue;
                }

                Child_Record_Editor_Config__mdt cmdt = configList[0];
                Schema.SObjectType recordsType = req.records[0].getSObjectType();
                Schema.DescribeSObjectResult recordsDescribe = recordsType.getDescribe();
                Map<String, Schema.SObjectField> childFieldMap = recordsDescribe.fields.getMap();
                if (!recordsDescribe.isAccessible()) {
                    res.errorMessage = 'Object is not accessible for config: ' + req.configKey;
                    results.add(res);
                    continue;
                }

                if ('CONTACT_ON_OPPORTUNITY'.equals(req.configKey) && recordsType == Contact.SObjectType) {
                    List<Map<String, Object>> output = new List<Map<String, Object>>();
                    for (SObject con : req.records) {
                        Id contactId = (Id) con.get('Id');
                        if (contactId == null) continue;
                        output.add(new Map<String, Object>{
                            'ContactId' => contactId,
                            'Role' => null,
                            'IsPrimary' => false
                        });
                    }
                    res.recordsJson = JSON.serialize(output);
                    results.add(res);
                    continue;
                }

                Set<String> childFieldNames = new Set<String>();
                if (!childFieldMap.containsKey(cmdt.Parent_Field_API_Name__c) ||
                    !childFieldMap.get(cmdt.Parent_Field_API_Name__c).getDescribe().isAccessible()) {
                    res.errorMessage = 'Configured parent field is not accessible: ' + cmdt.Parent_Field_API_Name__c;
                    results.add(res);
                    continue;
                }

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
                    if (String.isNotBlank(apiName) &&
                        childFieldMap.containsKey(apiName) &&
                        childFieldMap.get(apiName).getDescribe().isAccessible()) {
                        childFieldNames.add(apiName);
                    }
                }
                childFieldNames.add('Id');
                childFieldNames.add(cmdt.Parent_Field_API_Name__c);

                List<String> relFieldNames = new List<String>();
                String relObjName = cmdt.Relationship_Object_API_Name__c;
                String relFieldsJson = cmdt.Relationship_Fields_JSON__c;
                Schema.SObjectType relType;
                Map<String, Schema.SObjectField> relFieldMap;
                if (String.isNotBlank(relObjName) && String.isNotBlank(relFieldsJson)) {
                    relType = Schema.getGlobalDescribe().get(relObjName);
                    if (relType == null || !relType.getDescribe().isAccessible()) {
                        res.errorMessage = 'Relationship object is not accessible: ' + relObjName;
                        results.add(res);
                        continue;
                    }
                    relFieldMap = relType.getDescribe().fields.getMap();
                    if (!relFieldMap.containsKey(cmdt.Relationship_Child_Field__c) ||
                        !relFieldMap.containsKey(cmdt.Relationship_Parent_Field__c) ||
                        !relFieldMap.get(cmdt.Relationship_Child_Field__c).getDescribe().isAccessible() ||
                        !relFieldMap.get(cmdt.Relationship_Parent_Field__c).getDescribe().isAccessible()) {
                        res.errorMessage = 'Relationship linking fields are not accessible for config: ' + req.configKey;
                        results.add(res);
                        continue;
                    }
                    try {
                        List<Object> rawRel = (List<Object>) JSON.deserializeUntyped(relFieldsJson.trim());
                        for (Object raw : rawRel) {
                            Map<String, Object> f = (Map<String, Object>) raw;
                            String apiName = (String) f.get('fieldApiName');
                            if (String.isNotBlank(apiName) &&
                                relFieldMap.containsKey(apiName) &&
                                relFieldMap.get(apiName).getDescribe().isAccessible()) {
                                relFieldNames.add(apiName);
                            }
                        }
                    } catch (Exception e) { }
                }

                Map<String, SObject> acrByChildAndParent = new Map<String, SObject>();
                if (req.relationshipRecords != null && !req.relationshipRecords.isEmpty()) {
                    for (SObject acr : req.relationshipRecords) {
                        Id childId = (Id) acr.get(cmdt.Relationship_Child_Field__c);
                        Id parentId = (Id) acr.get(cmdt.Relationship_Parent_Field__c);
                        if (childId != null && parentId != null) {
                            acrByChildAndParent.put(buildRelationshipKey(childId, parentId), acr);
                        }
                    }
                }

                if (!relFieldNames.isEmpty() && String.isNotBlank(relObjName)) {
                    Set<Id> childIdsToQuery = new Set<Id>();
                    Set<Id> parentIdsToQuery = new Set<Id>();
                    for (SObject rec : req.records) {
                        Id childId = (Id) rec.get('Id');
                        Id parentId = (Id) rec.get(cmdt.Parent_Field_API_Name__c);
                        if (childId == null || parentId == null) {
                            continue;
                        }
                        String relationshipKey = buildRelationshipKey(childId, parentId);
                        if (!acrByChildAndParent.containsKey(relationshipKey)) {
                            childIdsToQuery.add(childId);
                            parentIdsToQuery.add(parentId);
                        }
                    }

                    if (!childIdsToQuery.isEmpty() && !parentIdsToQuery.isEmpty()) {
                        acrByChildAndParent.putAll(
                            queryRelationshipRecords(
                                relObjName,
                                cmdt.Relationship_Child_Field__c,
                                cmdt.Relationship_Parent_Field__c,
                                relFieldNames,
                                childIdsToQuery,
                                parentIdsToQuery
                            )
                        );
                    }
                }

                List<Map<String, Object>> output = new List<Map<String, Object>>();
                for (SObject rec : req.records) {
                    Map<String, Object> populatedChildFields = rec.getPopulatedFieldsAsMap();
                    Map<String, Object> childData = new Map<String, Object>();
                    for (String fName : childFieldNames) {
                        if (populatedChildFields.containsKey(fName)) {
                            Object val = populatedChildFields.get(fName);
                            if (val != null) {
                                childData.put(fName, val);
                            }
                        }
                    }
                    if (!childData.containsKey('Id')) {
                        childData.put('Id', rec.Id);
                    }

                    Map<String, Object> relData = new Map<String, Object>();
                    if (!relFieldNames.isEmpty() && String.isNotBlank(relObjName)) {
                        Id childId = (Id) rec.get('Id');
                        Id parentId = (Id) rec.get(cmdt.Parent_Field_API_Name__c);
                        if (childId != null && parentId != null) {
                            SObject acr = acrByChildAndParent.get(buildRelationshipKey(childId, parentId));
                            if (acr != null) {
                                for (String fName : relFieldNames) {
                                    Object val = acr.get(fName);
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
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    private static Map<String, SObject> queryRelationshipRecords(
        String relObjectName,
        String relChildField,
        String relParentField,
        List<String> relFieldNames,
        Set<Id> childIds,
        Set<Id> parentIds
    ) {
        Map<String, SObject> relationshipsByKey = new Map<String, SObject>();
        List<String> selectFields = new List<String>{ 'Id', relChildField, relParentField };
        for (String relFieldName : relFieldNames) {
            if (!selectFields.contains(relFieldName)) {
                selectFields.add(relFieldName);
            }
        }

        String q =
            'SELECT ' + String.join(selectFields, ', ') +
            ' FROM ' + relObjectName +
            ' WHERE ' + relChildField + ' IN :childIds' +
            ' AND ' + relParentField + ' IN :parentIds' +
            ' WITH SECURITY_ENFORCED';

        for (SObject relationshipRecord : Database.query(q)) {
            Id childId = (Id) relationshipRecord.get(relChildField);
            Id parentId = (Id) relationshipRecord.get(relParentField);
            if (childId != null && parentId != null) {
                relationshipsByKey.put(buildRelationshipKey(childId, parentId), relationshipRecord);
            }
        }

        return relationshipsByKey;
    }

    private static String buildRelationshipKey(Id childId, Id parentId) {
        return String.valueOf(childId) + '|' + String.valueOf(parentId);
    }
}
