public with sharing class RecordCollectionEditorConfigService {

    public class FieldConfig {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String label;
        @AuraEnabled public String dataType;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String columnSize;
        @AuraEnabled public List<String> picklistValues;
        @AuraEnabled public String lookupObjectApiName;
    }

    public class RecordCollectionConfig {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String parentFieldApiName;
        @AuraEnabled public List<FieldConfig> fields;
        @AuraEnabled public List<FieldConfig> relationshipFields;
        @AuraEnabled public RoleConstraintsConfig roleConstraints;
    }

    public class RoleConstraintsConfig {
        @AuraEnabled public List<String> singlePerAccountRoles;
        @AuraEnabled public List<String> requiresPermissionRoles;
        @AuraEnabled public String authorizedSignerPermission;
        @AuraEnabled public Boolean canAssignAuthorizedSigner;
        @AuraEnabled public String roleFieldApiName;
    }

    public class CreateFromJsonRequest {
        @InvocableVariable(required=true label='Config Key')
        public String configKey;
        @InvocableVariable(required=true label='Records JSON')
        public String recordsJson;
    }

    public class CreateFromJsonResult {
        @InvocableVariable(label='Created Records' description='Primary records created (Contact, OpportunityContactRole, etc.). Map to your SObject collection.')
        public List<SObject> createdRecords;
        @InvocableVariable(label='Created Relationship Records' description='Relationship records when applicable (AccountContactRelation); empty for flat configs.')
        public List<SObject> createdRelationshipRecords;
        @InvocableVariable(label='Error Messages')
        public List<String> errorMessages;
    }

    @AuraEnabled(cacheable=true)
    public static RecordCollectionConfig getConfig(String developerName) {
        try {
            if (String.isBlank(developerName)) {
                throw new OnboardingDomainException('Config developer name is required.');
            }

            List<Child_Record_Editor_Config__mdt> records = [
                SELECT Id, DeveloperName, Object_API_Name__c, Parent_Field_API_Name__c, Fields_JSON__c,
                    Relationship_Object_API_Name__c, Relationship_Fields_JSON__c, Role_Constraints_JSON__c
                FROM Child_Record_Editor_Config__mdt
                WHERE DeveloperName = :developerName
                LIMIT 1
            ];

            if (records.isEmpty()) {
                throw new OnboardingDomainException(
                    'No Child_Record_Editor_Config__mdt found for key: ' +
                    developerName
                );
            }

            Child_Record_Editor_Config__mdt cmdt = records[0];
            String objectApiName = cmdt.Object_API_Name__c;
            String parentFieldApiName = cmdt.Parent_Field_API_Name__c;

            if (String.isBlank(objectApiName) || String.isBlank(parentFieldApiName)) {
                throw new OnboardingDomainException(
                    'Object_API_Name__c and Parent_Field_API_Name__c must be populated for config: ' +
                    developerName
                );
            }

            Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sobjectType == null) {
                throw new OnboardingDomainException(
                    'Unknown object API name: ' + objectApiName
                );
            }

            Map<String, Schema.SObjectField> fieldMap =
                sobjectType.getDescribe().fields.getMap();

            List<FieldConfig> fieldConfigs = new List<FieldConfig>();

            String fieldsJson = cmdt.Fields_JSON__c;
            if (String.isBlank(fieldsJson)) {
                throw new OnboardingDomainException(
                    'Fields_JSON__c is empty for config ' +
                    developerName +
                    '. Add a valid JSON array of field configs.'
                );
            }
            List<Object> rawFields;
            try {
                rawFields = (List<Object>) JSON.deserializeUntyped(fieldsJson.trim());
            } catch (Exception e) {
                throw new OnboardingDomainException(
                    'Invalid Fields_JSON__c for config ' + developerName + '.'
                );
            }

            for (Object raw : rawFields) {
                Map<String, Object> rawField = (Map<String, Object>) raw;
                String fieldApiName = (String) rawField.get('fieldApiName');
                if (String.isBlank(fieldApiName)) {
                    continue;
                }

                Schema.SObjectField sfield = fieldMap.get(fieldApiName);
                if (sfield == null) {
                    continue;
                }

                Schema.DescribeFieldResult dfr = sfield.getDescribe();
                if (!dfr.isAccessible()) {
                    continue;
                }

                FieldConfig fc = new FieldConfig();
                fc.fieldApiName = fieldApiName;
                fc.label = (String) (rawField.containsKey('label') && rawField.get('label') != null
                    ? rawField.get('label')
                    : dfr.getLabel());
                fc.required = (Boolean) (rawField.containsKey('required') && rawField.get('required') != null
                    ? rawField.get('required')
                    : !dfr.isNillable() && !dfr.isDefaultedOnCreate());
                fc.readOnly = parseBoolean(rawField.get('readOnly'), false);

                fc.columnSize = (String) rawField.get('columnSize');

                String configuredType = (String) rawField.get('type');
                if (!String.isBlank(configuredType)) {
                    fc.dataType = configuredType;
                } else {
                    fc.dataType = mapDescribeToDataType(dfr);
                }

                if (dfr.getType() == Schema.DisplayType.Picklist || dfr.getType() == Schema.DisplayType.MultiPicklist) {
                    fc.picklistValues = new List<String>();
                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                        fc.picklistValues.add(pe.getValue());
                    }
                }
                if (dfr.getType() == Schema.DisplayType.Reference) {
                    List<Schema.SObjectType> refTypes = dfr.getReferenceTo();
                    if (refTypes != null && !refTypes.isEmpty()) {
                        fc.lookupObjectApiName = refTypes[0].getDescribe().getName();
                    }
                }

                fieldConfigs.add(fc);
            }

            List<FieldConfig> relationshipFieldConfigs = new List<FieldConfig>();
            String relObjectName = cmdt.Relationship_Object_API_Name__c;
            String relFieldsJson = cmdt.Relationship_Fields_JSON__c;
            if (!String.isBlank(relObjectName) && !String.isBlank(relFieldsJson)) {
                Schema.SObjectType relType = Schema.getGlobalDescribe().get(relObjectName);
                if (relType != null) {
                    Map<String, Schema.SObjectField> relFieldMap =
                        relType.getDescribe().fields.getMap();
                    List<Object> rawRelFields;
                    try {
                        rawRelFields =
                            (List<Object>) JSON.deserializeUntyped(relFieldsJson.trim());
                    } catch (Exception e) {
                        rawRelFields = new List<Object>();
                    }
                    for (Object raw : rawRelFields) {
                        Map<String, Object> rawField = (Map<String, Object>) raw;
                        String fieldApiName = (String) rawField.get('fieldApiName');
                        if (String.isBlank(fieldApiName)) {
                            continue;
                        }
                        Schema.SObjectField sfield = relFieldMap.get(fieldApiName);
                        if (sfield == null) {
                            continue;
                        }
                        Schema.DescribeFieldResult dfr = sfield.getDescribe();
                        if (!dfr.isAccessible()) {
                            continue;
                        }
                        FieldConfig fc = new FieldConfig();
                        fc.fieldApiName = fieldApiName;
                        fc.label = (String) (rawField.containsKey('label') && rawField.get('label') != null ? rawField.get('label') : dfr.getLabel());
                        fc.required = (Boolean) (rawField.containsKey('required') && rawField.get('required') != null ? rawField.get('required') : !dfr.isNillable() && !dfr.isDefaultedOnCreate());
                        fc.readOnly = parseBoolean(rawField.get('readOnly'), false);
                        fc.columnSize = (String) rawField.get('columnSize');
                        String configuredType = (String) rawField.get('type');
                        fc.dataType = !String.isBlank(configuredType) ? configuredType : mapDescribeToDataType(dfr);
                        if (dfr.getType() == Schema.DisplayType.Picklist || dfr.getType() == Schema.DisplayType.MultiPicklist) {
                            fc.picklistValues = new List<String>();
                            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                                fc.picklistValues.add(pe.getValue());
                            }
                        }
                        if (dfr.getType() == Schema.DisplayType.Reference) {
                            List<Schema.SObjectType> refTypes = dfr.getReferenceTo();
                            if (refTypes != null && !refTypes.isEmpty()) {
                                fc.lookupObjectApiName = refTypes[0].getDescribe().getName();
                            }
                        }
                        relationshipFieldConfigs.add(fc);
                    }
                }
            }

            RoleConstraintsConfig roleConstraints = parseRoleConstraints(
                cmdt.Role_Constraints_JSON__c
            );

            RecordCollectionConfig config = new RecordCollectionConfig();
            config.objectApiName = objectApiName;
            config.parentFieldApiName = parentFieldApiName;
            config.fields = fieldConfigs;
            config.relationshipFields = relationshipFieldConfigs;
            config.roleConstraints = roleConstraints;
            return config;
        } catch (OnboardingDomainException domainException) {
            throw ExceptionUtil.domainError(
                'RecordCollectionEditorConfigService.getConfig',
                domainException
            );
        } catch (Exception unexpectedException) {
            throw ExceptionUtil.unexpectedAuraError(
                'RecordCollectionEditorConfigService.getConfig',
                unexpectedException,
                'Unable to load record collection editor configuration.'
            );
        }
    }

    private static RoleConstraintsConfig parseRoleConstraints(String jsonStr) {
        RoleConstraintsConfig rc = new RoleConstraintsConfig();
        rc.singlePerAccountRoles = new List<String>();
        rc.requiresPermissionRoles = new List<String>();
        rc.authorizedSignerPermission = null;
        rc.canAssignAuthorizedSigner = true;
        rc.roleFieldApiName = null;
        if (String.isBlank(jsonStr)) return rc;
        try {
            Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(jsonStr.trim());
            if (raw.containsKey('singlePerAccountRoles')) {
                List<Object> arr = (List<Object>) raw.get('singlePerAccountRoles');
                for (Object o : arr) rc.singlePerAccountRoles.add(String.valueOf(o));
            }
            if (raw.containsKey('requiresPermissionRoles')) {
                List<Object> arr = (List<Object>) raw.get('requiresPermissionRoles');
                for (Object o : arr) rc.requiresPermissionRoles.add(String.valueOf(o));
            }
            rc.authorizedSignerPermission = (String) raw.get('authorizedSignerPermission');
            if (String.isNotBlank(rc.authorizedSignerPermission)) {
                rc.canAssignAuthorizedSigner = FeatureManagement.checkPermission(rc.authorizedSignerPermission);
            }
            rc.roleFieldApiName = (String) raw.get('roleFieldApiName');
        } catch (Exception e) { }
        return rc;
    }

    private static List<String> getRoleValuesFromRelFields(Map<String, Object> relFields, String roleFieldApiName) {
        List<String> roles = new List<String>();
        if (roleFieldApiName != null && relFields.containsKey(roleFieldApiName)) {
            Object val = relFields.get(roleFieldApiName);
            if (val != null && String.isNotBlank(String.valueOf(val))) {
                for (String part : String.valueOf(val).split(';')) {
                    String trimmed = part.trim();
                    if (String.isNotBlank(trimmed)) roles.add(trimmed);
                }
            }
        } else {
            for (String key : new List<String>{ 'Role', 'Roles' }) {
                if (relFields.containsKey(key)) {
                    Object val = relFields.get(key);
                    if (val != null && String.isNotBlank(String.valueOf(val))) {
                        for (String part : String.valueOf(val).split(';')) {
                            String trimmed = part.trim();
                            if (String.isNotBlank(trimmed)) roles.add(trimmed);
                        }
                    }
                    break;
                }
            }
        }
        return roles;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean getCanAssignAuthorizedSigner(String configKey) {
        if (String.isBlank(configKey)) return true;
        List<Child_Record_Editor_Config__mdt> records = [
            SELECT Role_Constraints_JSON__c FROM Child_Record_Editor_Config__mdt
            WHERE DeveloperName = :configKey LIMIT 1
        ];
        if (records.isEmpty()) return true;
        String jsonStr = records[0].Role_Constraints_JSON__c;
        if (String.isBlank(jsonStr)) return true;
        try {
            Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(jsonStr.trim());
            String perm = (String) raw.get('authorizedSignerPermission');
            if (String.isBlank(perm)) return true;
            return FeatureManagement.checkPermission(perm);
        } catch (Exception e) { return true; }
    }

    @InvocableMethod(
        label='Create Records from JSON'
        description='Creates records from JSON produced by the Record Collection Editor LWC. Returns created records for Flow Record Collection variable.'
    )
    public static List<CreateFromJsonResult> createRecordsFromJson(List<CreateFromJsonRequest> requests) {
        List<CreateFromJsonResult> results = new List<CreateFromJsonResult>();

        if (requests == null) {
            return results;
        }

        for (CreateFromJsonRequest requestItem : requests) {
            CreateFromJsonResult singleResult = new CreateFromJsonResult();
            singleResult.createdRecords = new List<SObject>();
            singleResult.createdRelationshipRecords = new List<SObject>();
            singleResult.errorMessages = new List<String>();

            if (requestItem == null || String.isBlank(requestItem.configKey) || String.isBlank(requestItem.recordsJson)) {
                singleResult.errorMessages.add('configKey and recordsJson are required.');
                results.add(singleResult);
                continue;
            }

            List<Child_Record_Editor_Config__mdt> configList = [
                SELECT Id, Object_API_Name__c, Parent_Field_API_Name__c,
                    Relationship_Object_API_Name__c, Relationship_Parent_Field__c, Relationship_Child_Field__c,
                    Role_Constraints_JSON__c
                FROM Child_Record_Editor_Config__mdt
                WHERE DeveloperName = :requestItem.configKey
                LIMIT 1
            ];

            if (configList.isEmpty()) {
                singleResult.errorMessages.add('No Child_Record_Editor_Config__mdt found for key: ' + requestItem.configKey);
                results.add(singleResult);
                continue;
            }

            Child_Record_Editor_Config__mdt cmdt = configList[0];
            String objectApiName = cmdt.Object_API_Name__c;
            if (String.isBlank(objectApiName)) {
                singleResult.errorMessages.add('Object_API_Name__c must be populated for config: ' + requestItem.configKey);
                results.add(singleResult);
                continue;
            }

            Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sobjectType == null) {
                singleResult.errorMessages.add('Unknown object API name: ' + objectApiName);
                results.add(singleResult);
                continue;
            }

            List<Object> rawRecords;
            try {
                rawRecords = (List<Object>) JSON.deserializeUntyped(requestItem.recordsJson);
            } catch (Exception parseException) {
                singleResult.errorMessages.add('Failed to parse recordsJson: ' + parseException.getMessage());
                results.add(singleResult);
                continue;
            }

            if (rawRecords == null || rawRecords.isEmpty()) {
                results.add(singleResult);
                continue;
            }

            List<Map<String, Object>> childDataList = new List<Map<String, Object>>();
            List<Map<String, Object>> relationshipDataList = new List<Map<String, Object>>();
            for (Object rawRecord : rawRecords) {
                Map<String, Object> recordData = (Map<String, Object>) rawRecord;
                if (recordData.containsKey('child')) {
                    childDataList.add((Map<String, Object>) recordData.get('child'));
                    relationshipDataList.add(recordData.containsKey('relationship')
                        ? (Map<String, Object>) recordData.get('relationship')
                        : new Map<String, Object>());
                } else {
                    childDataList.add(recordData);
                    relationshipDataList.add(new Map<String, Object>());
                }
            }

            Map<String, Schema.SObjectField> childFieldMap = sobjectType.getDescribe().fields.getMap();

            List<SObject> toInsert = new List<SObject>();
            List<SObject> toUpdate = new List<SObject>();
            List<Integer> insertIndices = new List<Integer>();
            List<Integer> updateIndices = new List<Integer>();

            for (Integer i = 0; i < childDataList.size(); i++) {
                Map<String, Object> childData = childDataList[i];
                Object idObj = childData.get('Id');
                Boolean isUpdate = idObj != null && String.isNotBlank(String.valueOf(idObj));

                SObject rec = sobjectType.newSObject();
                for (String fieldApiName : childData.keySet()) {
                    if (fieldApiName == 'Id') {
                        if (isUpdate) {
                            rec.put('Id', childData.get('Id'));
                        }
                        continue;
                    }
                    Schema.SObjectField sfield = childFieldMap.get(fieldApiName);
                    if (sfield == null) continue;
                    Schema.DescribeFieldResult dfr = sfield.getDescribe();
                    if (isUpdate && !dfr.isUpdateable()) continue;
                    if (!isUpdate && !dfr.isCreateable()) continue;
                    Object val = convertRelationshipFieldValue(sobjectType, fieldApiName, childData.get(fieldApiName));
                    if (val != null) rec.put(fieldApiName, val);
                }
                if (isUpdate) {
                    toUpdate.add(rec);
                    updateIndices.add(i);
                } else {
                    toInsert.add(rec);
                    insertIndices.add(i);
                }
            }

            Map<Integer, Id> indexToChildId = new Map<Integer, Id>();

            if (!toUpdate.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(toUpdate, false, AccessLevel.USER_MODE);
                for (Integer i = 0; i < updateResults.size(); i++) {
                    if (updateResults[i].isSuccess()) {
                        singleResult.createdRecords.add(toUpdate[i]);
                        indexToChildId.put(updateIndices[i], toUpdate[i].Id);
                    } else {
                        for (Database.Error err : updateResults[i].getErrors()) {
                            singleResult.errorMessages.add('Update: ' + err.getMessage());
                        }
                    }
                }
            }

            if (!toInsert.isEmpty()) {
                Database.SaveResult[] insertResults = Database.insert(toInsert, false, AccessLevel.USER_MODE);
                for (Integer i = 0; i < insertResults.size(); i++) {
                    if (insertResults[i].isSuccess()) {
                        singleResult.createdRecords.add(toInsert[i]);
                        indexToChildId.put(insertIndices[i], toInsert[i].Id);
                    } else {
                        for (Database.Error err : insertResults[i].getErrors()) {
                            singleResult.errorMessages.add(err.getMessage());
                        }
                    }
                }
            }

            RoleConstraintsConfig roleConstraints = parseRoleConstraints(cmdt.Role_Constraints_JSON__c);
            if (roleConstraints.requiresPermissionRoles != null && !roleConstraints.requiresPermissionRoles.isEmpty() &&
                String.isNotBlank(roleConstraints.authorizedSignerPermission) &&
                !FeatureManagement.checkPermission(roleConstraints.authorizedSignerPermission)) {
                for (Map<String, Object> relFields : relationshipDataList) {
                    for (String roleVal : getRoleValuesFromRelFields(relFields, roleConstraints.roleFieldApiName)) {
                        if (roleConstraints.requiresPermissionRoles.contains(roleVal)) {
                            singleResult.errorMessages.add(System.Label.RecordCollectionEditor_AuthorizedSignerPermissionDenied);
                            break;
                        }
                    }
                }
            }
            if (roleConstraints.singlePerAccountRoles != null && !roleConstraints.singlePerAccountRoles.isEmpty()) {
                Map<String, Integer> roleCounts = new Map<String, Integer>();
                for (String role : roleConstraints.singlePerAccountRoles) {
                    roleCounts.put(role, 0);
                }
                for (Map<String, Object> relFields : relationshipDataList) {
                    for (String roleVal : getRoleValuesFromRelFields(relFields, roleConstraints.roleFieldApiName)) {
                        if (roleCounts.containsKey(roleVal)) {
                            roleCounts.put(roleVal, roleCounts.get(roleVal) + 1);
                        }
                    }
                }
                for (String role : roleConstraints.singlePerAccountRoles) {
                    if (roleCounts.get(role) > 1) {
                        singleResult.errorMessages.add(role == 'Principal Owner'
                            ? System.Label.Principal_Owner_Conflict
                            : 'Only one contact can have the "' + role + '" role per account.');
                    }
                }
            }
            if (!singleResult.errorMessages.isEmpty()) {
                results.add(singleResult);
                continue;
            }

            String relObjectName = cmdt.Relationship_Object_API_Name__c;
            String relParentField = cmdt.Relationship_Parent_Field__c;
            String relChildField = cmdt.Relationship_Child_Field__c;
            Object parentIdObj = childDataList[0].get(cmdt.Parent_Field_API_Name__c);
            if (!singleResult.createdRecords.isEmpty() &&
                !String.isBlank(relObjectName) && !String.isBlank(relParentField) && !String.isBlank(relChildField) &&
                parentIdObj != null && String.isNotBlank(String.valueOf(parentIdObj))) {

                Id parentId = Id.valueOf(String.valueOf(parentIdObj));
                Schema.SObjectType relType = Schema.getGlobalDescribe().get(relObjectName);
                if (relType != null) {
                    List<SObject> relRecordsToInsert = new List<SObject>();
                    List<SObject> relRecordsToUpdate = new List<SObject>();
                    Map<String, Schema.SObjectField> relFieldMap =
                        relType.getDescribe().fields.getMap();
                    Schema.SObjectField startDateField = relFieldMap.get('StartDate');
                    if (!relFieldMap.containsKey(relParentField) || !relFieldMap.containsKey(relChildField)) {
                        singleResult.errorMessages.add(
                            'Relationship config fields are invalid: parent=' +
                            relParentField + ', child=' + relChildField + '.'
                        );
                        results.add(singleResult);
                        continue;
                    }

                    Set<Id> childIdsToQuery = new Set<Id>();
                    for (Integer i = 0; i < childDataList.size(); i++) {
                        Id childId = indexToChildId.get(i);
                        if (childId == null) {
                            continue;
                        }
                        Map<String, Object> relFields = relationshipDataList[i];
                        if (relFields == null || relFields.isEmpty()) {
                            continue;
                        }
                        childIdsToQuery.add(childId);
                    }

                    Map<String, SObject> existingByParentAndChild = new Map<String, SObject>();
                    if (!childIdsToQuery.isEmpty()) {
                        String existingQuery =
                            'SELECT Id, ' + relParentField + ', ' + relChildField +
                            ' FROM ' + relObjectName +
                            ' WHERE ' + relChildField + ' IN :childIdsToQuery' +
                            ' AND ' + relParentField + ' = :parentId' +
                            ' WITH SECURITY_ENFORCED';
                        for (SObject existingRel : Database.query(existingQuery)) {
                            Id existingChildId = (Id) existingRel.get(relChildField);
                            Id existingParentId = (Id) existingRel.get(relParentField);
                            if (existingChildId == null || existingParentId == null) {
                                continue;
                            }
                            existingByParentAndChild.put(
                                relationshipPairKey(existingParentId, existingChildId),
                                existingRel
                            );
                        }
                    }

                    for (Integer i = 0; i < childDataList.size(); i++) {
                        Id childId = indexToChildId.get(i);
                        if (childId == null) continue;
                        Map<String, Object> relFields = relationshipDataList[i];
                        if (relFields.isEmpty()) continue;

                        SObject existing = existingByParentAndChild.get(
                            relationshipPairKey(parentId, childId)
                        );
                        if (existing != null) {
                            SObject acr = relType.newSObject();
                            acr.put('Id', existing.get('Id'));
                            for (String fName : relFields.keySet()) {
                                Schema.SObjectField relSField = relFieldMap.get(fName);
                                if (relSField == null) continue;
                                if (!relSField.getDescribe().isUpdateable()) continue;
                                Object fVal = relFields.get(fName);
                                Object converted = convertRelationshipFieldValue(relType, fName, fVal);
                                if (converted != null) {
                                    acr.put(fName, converted);
                                }
                            }
                            relRecordsToUpdate.add(acr);
                        } else {
                            SObject relRec = relType.newSObject();
                            relRec.put(relParentField, parentId);
                            relRec.put(relChildField, childId);
                            for (String fName : relFields.keySet()) {
                                Schema.SObjectField relSField = relFieldMap.get(fName);
                                if (relSField == null) continue;
                                if (!relSField.getDescribe().isCreateable()) continue;
                                Object fVal = relFields.get(fName);
                                if (startDateField != null && 'StartDate'.equals(fName) &&
                                    (fVal == null || String.isBlank(String.valueOf(fVal)))) {
                                    fVal = Date.today();
                                }
                                Object converted = convertRelationshipFieldValue(relType, fName, fVal);
                                if (converted != null) {
                                    relRec.put(fName, converted);
                                }
                            }
                            if (startDateField != null && startDateField.getDescribe().isCreateable()) {
                                Object existingStart = relRec.get('StartDate');
                                if (existingStart == null) {
                                    relRec.put('StartDate', Date.today());
                                }
                            }
                            relRecordsToInsert.add(relRec);
                        }
                    }

                    if (!relRecordsToUpdate.isEmpty()) {
                        Database.SaveResult[] relUpdateResults = Database.update(relRecordsToUpdate, false, AccessLevel.USER_MODE);
                        for (Integer j = 0; j < relUpdateResults.size(); j++) {
                            if (relUpdateResults[j].isSuccess()) {
                                singleResult.createdRelationshipRecords.add(relRecordsToUpdate[j]);
                            } else {
                                for (Database.Error err : relUpdateResults[j].getErrors()) {
                                    singleResult.errorMessages.add('Relationship update: ' + err.getMessage());
                                }
                            }
                        }
                    }
                    if (!relRecordsToInsert.isEmpty()) {
                        Database.SaveResult[] relInsertResults = Database.insert(relRecordsToInsert, false, AccessLevel.USER_MODE);
                        for (Integer j = 0; j < relInsertResults.size(); j++) {
                            if (relInsertResults[j].isSuccess()) {
                                singleResult.createdRelationshipRecords.add(relRecordsToInsert[j]);
                            } else {
                                for (Database.Error err : relInsertResults[j].getErrors()) {
                                    singleResult.errorMessages.add('Relationship: ' + err.getMessage());
                                }
                            }
                        }
                    }
                }
            }

            results.add(singleResult);
        }

        return results;
    }

    private static String relationshipPairKey(Id parentId, Id childId) {
        return String.valueOf(parentId) + '|' + String.valueOf(childId);
    }

    private static Object convertRelationshipFieldValue(Schema.SObjectType sobjectType, String fieldName, Object fVal) {
        if (fVal == null) return null;
        if (fVal instanceof Boolean || fVal instanceof Date || fVal instanceof DateTime) return fVal;
        if (fVal instanceof Id) return fVal;
        String strVal = String.valueOf(fVal);
        if (String.isBlank(strVal)) return null;

        Schema.SObjectField sfield = sobjectType.getDescribe().fields.getMap().get(fieldName);
        if (sfield == null) return fVal;

        Schema.DescribeFieldResult dfr = sfield.getDescribe();
        Schema.DisplayType dt = dfr.getType();

        if (dt == Schema.DisplayType.Date) {
            try {
                return Date.valueOf(strVal);
            } catch (Exception e) {
                return null;
            }
        }
        if (dt == Schema.DisplayType.DateTime) {
            try {
                return DateTime.valueOfGmt(strVal.replace('Z', ''));
            } catch (Exception e) {
                return null;
            }
        }
        if (dt == Schema.DisplayType.Boolean) {
            return 'true'.equalsIgnoreCase(strVal);
        }
        if (dt == Schema.DisplayType.Reference || dt == Schema.DisplayType.Id) {
            try {
                return Id.valueOf(strVal);
            } catch (Exception e) {
                return null;
            }
        }
        return fVal;
    }

    private static Boolean parseBoolean(Object rawValue, Boolean defaultValue) {
        if (rawValue == null) return defaultValue;
        if (rawValue instanceof Boolean) return (Boolean) rawValue;
        String normalized = String.valueOf(rawValue).trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
        return defaultValue;
    }

    private static String mapDescribeToDataType(Schema.DescribeFieldResult dfr) {
        Schema.DisplayType t = dfr.getType();
        switch on t {
            when Email {
                return 'email';
            }
            when Phone {
                return 'tel';
            }
            when Date {
                return 'date';
            }
            when DateTime {
                return 'datetime';
            }
            when Integer {
                return 'number';
            }
            when Double {
                return 'number';
            }
            when Currency {
                return 'number';
            }
            when Boolean {
                return 'checkbox';
            }
            when Picklist {
                return 'picklist';
            }
            when MultiPicklist {
                return 'multipicklist';
            }
            when Id {
                return 'id';
            }
            when Reference {
                return 'lookup';
            }
            when String {
                return 'text';
            }
            when TextArea {
                return 'textarea';
            }
            when Url {
                return 'url';
            }
            when else {
                return 'text';
            }
        }
    }
}
