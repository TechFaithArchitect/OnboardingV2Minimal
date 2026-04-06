/**
 * Object Related List Controller
 * 
 * Provides a reusable way to query related records for any object.
 * Supports dynamic SOQL queries with configurable fields and relationships.
 * 
 * Security: Uses WITH SECURITY_ENFORCED to respect FLS and sharing rules.
 */
public with sharing class ObjectRelatedListController {
    
    // Order direction constants
    private static final String ORDER_ASC = 'ASC';
    private static final String ORDER_DESC = 'DESC';
    
    // Performance constants
    private static final Integer DEFAULT_QUERY_LIMIT = 2000;
    private static final Integer MAX_QUERY_LIMIT = 10000;
    private static final Integer DEFAULT_OPTIONS_LIMIT = 500;
    private static final Integer MAX_OPTIONS_LIMIT = 2000;
    private static final String API_NAME_PATTERN = '^[A-Za-z][A-Za-z0-9_]*$';
    
    /**
     * Query configuration wrapper class
     */
    public class QueryConfig {
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String parentFieldApiName { get; set; }
        @AuraEnabled public Id parentRecordId { get; set; }
        @AuraEnabled public List<String> fieldApiNames { get; set; }
        @AuraEnabled public List<String> relationshipFieldApiNames { get; set; }
        @AuraEnabled public String orderByField { get; set; }
        @AuraEnabled public String orderDirection { get; set; } // 'ASC' or 'DESC'
        @AuraEnabled public Integer recordLimit { get; set; } // Optional limit (defaults to DEFAULT_QUERY_LIMIT)
    }

    /**
     * Generic lookup option DTO for combobox-friendly responses.
     */
    public class LookupOption {
        @AuraEnabled public Id value { get; set; }
        @AuraEnabled public String label { get; set; }
    }

    /**
     * Returns related records for a parent record using dynamic SOQL.
     * 
     * @param config Query configuration object
     * @return List of SObject records (must be cast to specific type by caller)
     * @throws AuraHandledException if required parameters are missing or invalid
     */
    @AuraEnabled(cacheable=true)
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static List<SObject> getRelatedRecords(QueryConfig config) {
        try {
            // Validate configuration
            if (config == null) {
                throw new OnboardingDomainException('Query configuration is required');
            }
            if (String.isBlank(config.objectApiName)) {
                throw new OnboardingDomainException('Object API name is required');
            }
            if (String.isBlank(config.parentFieldApiName)) {
                throw new OnboardingDomainException('Parent field API name is required');
            }
            if (config.parentRecordId == null) {
                throw new OnboardingDomainException('Parent record ID is required');
            }
            if (config.fieldApiNames == null || config.fieldApiNames.isEmpty()) {
                throw new OnboardingDomainException(
                    'At least one field API name is required'
                );
            }

            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (!globalDescribe.containsKey(config.objectApiName)) {
                throw new OnboardingDomainException(
                    'Invalid object API name: ' + config.objectApiName
                );
            }

            Schema.DescribeSObjectResult objectDescribe =
                globalDescribe.get(config.objectApiName).getDescribe();
            if (!objectDescribe.isAccessible()) {
                throw new OnboardingDomainException(
                    'Object is not accessible: ' + config.objectApiName
                );
            }
            Map<String, Schema.SObjectField> objectFieldMap =
                objectDescribe.fields.getMap();
            String validatedParentField = requireFieldPath(
                objectDescribe,
                config.parentFieldApiName,
                'Parent field'
            );
            
            // Build field list
            Set<String> fields = new Set<String>();
            fields.add('Id'); // Always include Id
            if (
                objectFieldMap.containsKey('Name') &&
                objectFieldMap.get('Name').getDescribe().isAccessible()
            ) {
                fields.add('Name');
            }
            
            // Add specified fields
            for (String field : config.fieldApiNames) {
                if (String.isNotBlank(field)) {
                    String normalizedField = field.trim();
                    if (normalizedField.contains('.')) {
                        fields.add(
                            requireFieldPath(
                                objectDescribe,
                                normalizedField,
                                'Requested field'
                            )
                        );
                    } else {
                        fields.add(
                            requireSimpleField(
                                objectFieldMap,
                                normalizedField,
                                'Requested field',
                                true
                            )
                        );
                    }
                }
            }
            
            // Add relationship fields
            if (config.relationshipFieldApiNames != null) {
                for (String relField : config.relationshipFieldApiNames) {
                    if (String.isNotBlank(relField)) {
                        fields.add(
                            requireFieldPath(
                                objectDescribe,
                                relField,
                                'Relationship field'
                            )
                        );
                    }
                }
            }
            
            // Build SOQL query with bind variable
            String fieldList = String.join(new List<String>(fields), ', ');
            String parentField = validatedParentField;
            String objectName = objectDescribe.getName();
            Id parentId = config.parentRecordId;
            
            String soql = 'SELECT ' + fieldList
                        + ' FROM ' + objectName
                        + ' WHERE ' + parentField + ' = :parentId'
                        + ' WITH SECURITY_ENFORCED';
            
            // Add ORDER BY if specified
            if (String.isNotBlank(config.orderByField)) {
                String direction =
                    (config.orderDirection == ORDER_ASC) ? ORDER_ASC : ORDER_DESC;
                String validatedOrderBy = requireFieldPath(
                    objectDescribe,
                    config.orderByField,
                    'Order by field'
                );
                soql +=
                    ' ORDER BY ' + validatedOrderBy + ' ' + direction + ' NULLS LAST';
            }
            
            // Add LIMIT for performance (prevent query timeouts with large datasets)
            Integer limitValue = config.recordLimit != null
                ? config.recordLimit
                : DEFAULT_QUERY_LIMIT;
            // Enforce maximum limit for safety
            if (limitValue > MAX_QUERY_LIMIT) {
                limitValue = MAX_QUERY_LIMIT;
            }
            if (limitValue <= 0) {
                limitValue = DEFAULT_QUERY_LIMIT;
            }
            soql += ' LIMIT ' + limitValue;
            
            return Database.query(soql);
        } catch (OnboardingDomainException domainException) {
            throw ExceptionUtil.domainError(
                'ObjectRelatedListController.getRelatedRecords',
                domainException
            );
        } catch (Exception unexpectedException) {
            throw ExceptionUtil.unexpectedAuraError(
                'ObjectRelatedListController.getRelatedRecords',
                unexpectedException,
                'Unable to load related records.'
            );
        }
    }

    /**
     * Returns generic lookup options for any object using Id + a label field.
     * Designed for reusable LWC combobox selectors to reduce per-object Apex.
     */
    @AuraEnabled(cacheable=true)
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static List<LookupOption> getLookupOptions(
        String objectApiName,
        String labelFieldApiName,
        String orderByField,
        String orderDirection,
        Integer recordLimit
    ) {
        try {
            if (String.isBlank(objectApiName)) {
                throw new OnboardingDomainException('Object API name is required');
            }
            if (String.isBlank(labelFieldApiName)) {
                throw new OnboardingDomainException('Label field API name is required');
            }

            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (!globalDescribe.containsKey(objectApiName)) {
                throw new OnboardingDomainException(
                    'Invalid object API name: ' + objectApiName
                );
            }

            Schema.DescribeSObjectResult objectDescribe =
                globalDescribe.get(objectApiName).getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();

            if (!objectDescribe.isAccessible()) {
                throw new OnboardingDomainException(
                    'Object is not accessible: ' + objectApiName
                );
            }
            if (!fieldMap.containsKey(labelFieldApiName)) {
                throw new OnboardingDomainException(
                    'Invalid label field: ' + labelFieldApiName
                );
            }
            if (!fieldMap.get(labelFieldApiName).getDescribe().isAccessible()) {
                throw new OnboardingDomainException(
                    'Field is not accessible: ' + labelFieldApiName
                );
            }

            String validatedLabelField = requireSimpleField(
                fieldMap,
                labelFieldApiName,
                'Label field',
                true
            );

            String sortField = validatedLabelField;
            if (String.isNotBlank(orderByField)) {
                String normalizedOrderBy = orderByField.trim();
                if (
                    Pattern.matches(API_NAME_PATTERN, normalizedOrderBy) &&
                    fieldMap.containsKey(normalizedOrderBy) &&
                    fieldMap.get(normalizedOrderBy).getDescribe().isAccessible()
                ) {
                    sortField = normalizedOrderBy;
                }
            }
            String direction = (orderDirection == ORDER_DESC) ? ORDER_DESC : ORDER_ASC;

            Integer limitValue =
                (recordLimit == null) ? DEFAULT_OPTIONS_LIMIT : recordLimit;
            if (limitValue <= 0) {
                limitValue = DEFAULT_OPTIONS_LIMIT;
            }
            if (limitValue > MAX_OPTIONS_LIMIT) {
                limitValue = MAX_OPTIONS_LIMIT;
            }

            String soql =
                'SELECT Id, ' + validatedLabelField +
                ' FROM ' + objectDescribe.getName() +
                ' WHERE ' + validatedLabelField + ' != NULL' +
                ' WITH SECURITY_ENFORCED' +
                ' ORDER BY ' + sortField + ' ' + direction +
                ' LIMIT ' + limitValue;

            List<SObject> records = Database.query(soql);

            List<LookupOption> options = new List<LookupOption>();
            for (SObject row : records) {
                LookupOption option = new LookupOption();
                option.value = (Id)row.get('Id');
                option.label = (String)row.get(validatedLabelField);
                options.add(option);
            }
            return options;
        } catch (OnboardingDomainException domainException) {
            throw ExceptionUtil.domainError(
                'ObjectRelatedListController.getLookupOptions',
                domainException
            );
        } catch (Exception unexpectedException) {
            throw ExceptionUtil.unexpectedAuraError(
                'ObjectRelatedListController.getLookupOptions',
                unexpectedException,
                'Unable to load lookup options.'
            );
        }
    }

    private static String requireSimpleField(
        Map<String, Schema.SObjectField> fieldMap,
        String fieldApiName,
        String label,
        Boolean requireAccessible
    ) {
        String normalized = fieldApiName == null ? null : fieldApiName.trim();
        if (String.isBlank(normalized) || !Pattern.matches(API_NAME_PATTERN, normalized)) {
            throw new OnboardingDomainException('Invalid ' + label + ': ' + fieldApiName);
        }
        if (!fieldMap.containsKey(normalized)) {
            throw new OnboardingDomainException('Invalid ' + label + ': ' + normalized);
        }
        if (requireAccessible && !fieldMap.get(normalized).getDescribe().isAccessible()) {
            throw new OnboardingDomainException(label + ' is not accessible: ' + normalized);
        }
        return normalized;
    }

    private static String requireFieldPath(
        Schema.DescribeSObjectResult rootDescribe,
        String fieldPath,
        String label
    ) {
        String normalized = fieldPath == null ? null : fieldPath.trim();
        if (String.isBlank(normalized)) {
            throw new OnboardingDomainException('Invalid ' + label + ': ' + fieldPath);
        }

        List<String> parts = normalized.split('\\.');
        Schema.DescribeSObjectResult currentDescribe = rootDescribe;

        for (Integer i = 0; i < parts.size(); i++) {
            String part = parts[i];
            if (String.isBlank(part) || !Pattern.matches(API_NAME_PATTERN, part)) {
                throw new OnboardingDomainException('Invalid ' + label + ': ' + normalized);
            }

            Boolean isLast = (i == parts.size() - 1);
            if (isLast) {
                Map<String, Schema.SObjectField> fieldMap = currentDescribe.fields.getMap();
                if (!fieldMap.containsKey(part)) {
                    throw new OnboardingDomainException('Invalid ' + label + ': ' + normalized);
                }
                if (!fieldMap.get(part).getDescribe().isAccessible()) {
                    throw new OnboardingDomainException(label + ' is not accessible: ' + normalized);
                }
            } else {
                currentDescribe = resolveRelationshipDescribe(currentDescribe, part);
                if (currentDescribe == null) {
                    throw new OnboardingDomainException('Invalid ' + label + ': ' + normalized);
                }
            }
        }

        return normalized;
    }

    private static Schema.DescribeSObjectResult resolveRelationshipDescribe(
        Schema.DescribeSObjectResult describeResult,
        String relationshipName
    ) {
        for (Schema.SObjectField sField : describeResult.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = sField.getDescribe();
            if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
                continue;
            }
            if (fieldDescribe.getRelationshipName() != relationshipName) {
                continue;
            }
            List<Schema.SObjectType> referenceTypes = fieldDescribe.getReferenceTo();
            if (referenceTypes == null || referenceTypes.isEmpty()) {
                continue;
            }
            return referenceTypes[0].getDescribe();
        }
        return null;
    }
    
    /**
     * Convenience method for Program Dates (maintains backward compatibility)
     * @deprecated Use getRelatedRecords with QueryConfig instead
     */
    @AuraEnabled(cacheable=true)
    public static List<Program_Dates__c> getProgramDates(Id accountId) {
        if (accountId == null) {
            throw ExceptionUtil.domainError(
                'ObjectRelatedListController.getProgramDates',
                new OnboardingDomainException('Account Id is required')
            );
        }
        
        QueryConfig config = new QueryConfig();
        config.objectApiName = 'Program_Dates__c';
        config.parentFieldApiName = 'Account__c';
        config.parentRecordId = accountId;
        config.fieldApiNames = new List<String>{
            'Partner_Category__c',
            'Inception_Date__c',
            'Program_ID__c',
            'Program_Active_Flag__c',
            'Program_Date__c',
            'Program_Deactivated_Flag__c',
            'Program_Deactivated_Date__c',
            'Program_Deactivated_Reason__c',
            'Program_Reactivated_Date__c',
            'Program_Reactivated_Flag__c',
            'Vendor_Program__c'
        };
        config.relationshipFieldApiNames = new List<String>{
            'Vendor_Program__r.Label__c'
        };
        config.orderByField = 'Program_Date__c';
        config.orderDirection = 'DESC';
        
        return (List<Program_Dates__c>)ObjectRelatedListController.getRelatedRecords(config);
    }
}
