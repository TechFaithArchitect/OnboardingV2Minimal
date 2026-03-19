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
    public static List<SObject> getRelatedRecords(QueryConfig config) {
        // Validate configuration
        if (config == null) {
            throw new AuraHandledException('Query configuration is required');
        }
        if (String.isBlank(config.objectApiName)) {
            throw new AuraHandledException('Object API name is required');
        }
        if (String.isBlank(config.parentFieldApiName)) {
            throw new AuraHandledException('Parent field API name is required');
        }
        if (config.parentRecordId == null) {
            throw new AuraHandledException('Parent record ID is required');
        }
        if (config.fieldApiNames == null || config.fieldApiNames.isEmpty()) {
            throw new AuraHandledException('At least one field API name is required');
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (!globalDescribe.containsKey(config.objectApiName)) {
            throw new AuraHandledException('Invalid object API name: ' + config.objectApiName);
        }

        Schema.DescribeSObjectResult objectDescribe =
            globalDescribe.get(config.objectApiName).getDescribe();
        if (!objectDescribe.isAccessible()) {
            throw new AuraHandledException('Object is not accessible: ' + config.objectApiName);
        }
        Map<String, Schema.SObjectField> objectFieldMap = objectDescribe.fields.getMap();
        
        // Build field list
        Set<String> fields = new Set<String>();
        fields.add('Id'); // Always include Id
        if (objectFieldMap.containsKey('Name')) {
            fields.add('Name');
        }
        
        // Add specified fields
        for (String field : config.fieldApiNames) {
            if (String.isNotBlank(field)) {
                fields.add(field.trim());
            }
        }
        
        // Add relationship fields
        if (config.relationshipFieldApiNames != null) {
            for (String relField : config.relationshipFieldApiNames) {
                if (String.isNotBlank(relField)) {
                    fields.add(relField.trim());
                }
            }
        }
        
        // Build SOQL query with bind variable
        String fieldList = String.join(new List<String>(fields), ', ');
        String parentField = String.escapeSingleQuotes(config.parentFieldApiName);
        String objectName = String.escapeSingleQuotes(config.objectApiName);
        Id parentId = config.parentRecordId;
        
        String soql = 'SELECT ' + fieldList 
                    + ' FROM ' + objectName
                    + ' WHERE ' + parentField + ' = :parentId'
                    + ' WITH SECURITY_ENFORCED';
        
        // Add ORDER BY if specified
        if (String.isNotBlank(config.orderByField)) {
            String direction = (config.orderDirection == ORDER_ASC) ? ORDER_ASC : ORDER_DESC;
            soql += ' ORDER BY ' + String.escapeSingleQuotes(config.orderByField) + ' ' + direction + ' NULLS LAST';
        }
        
        // Add LIMIT for performance (prevent query timeouts with large datasets)
        Integer limitValue = config.recordLimit != null ? config.recordLimit : DEFAULT_QUERY_LIMIT;
        // Enforce maximum limit for safety
        if (limitValue > MAX_QUERY_LIMIT) {
            limitValue = MAX_QUERY_LIMIT;
        }
        if (limitValue <= 0) {
            limitValue = DEFAULT_QUERY_LIMIT;
        }
        soql += ' LIMIT ' + limitValue;
        
        // Execute query with bind variable
        try {
            return Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Error querying records: ' + e.getMessage());
        }
    }

    /**
     * Returns generic lookup options for any object using Id + a label field.
     * Designed for reusable LWC combobox selectors to reduce per-object Apex.
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupOption> getLookupOptions(
        String objectApiName,
        String labelFieldApiName,
        String orderByField,
        String orderDirection,
        Integer recordLimit
    ) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API name is required');
        }
        if (String.isBlank(labelFieldApiName)) {
            throw new AuraHandledException('Label field API name is required');
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (!globalDescribe.containsKey(objectApiName)) {
            throw new AuraHandledException('Invalid object API name: ' + objectApiName);
        }

        Schema.DescribeSObjectResult objectDescribe = globalDescribe.get(objectApiName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();

        if (!objectDescribe.isAccessible()) {
            throw new AuraHandledException('Object is not accessible: ' + objectApiName);
        }
        if (!fieldMap.containsKey(labelFieldApiName)) {
            throw new AuraHandledException('Invalid label field: ' + labelFieldApiName);
        }
        if (!fieldMap.get(labelFieldApiName).getDescribe().isAccessible()) {
            throw new AuraHandledException('Field is not accessible: ' + labelFieldApiName);
        }

        String sortField = String.isNotBlank(orderByField) && fieldMap.containsKey(orderByField)
            ? orderByField
            : labelFieldApiName;
        if (!fieldMap.get(sortField).getDescribe().isAccessible()) {
            sortField = labelFieldApiName;
        }
        String direction = (orderDirection == ORDER_DESC) ? ORDER_DESC : ORDER_ASC;

        Integer limitValue = (recordLimit == null) ? DEFAULT_OPTIONS_LIMIT : recordLimit;
        if (limitValue <= 0) {
            limitValue = DEFAULT_OPTIONS_LIMIT;
        }
        if (limitValue > MAX_OPTIONS_LIMIT) {
            limitValue = MAX_OPTIONS_LIMIT;
        }

        String soql =
            'SELECT Id, ' + labelFieldApiName +
            ' FROM ' + objectApiName +
            ' WHERE ' + labelFieldApiName + ' != NULL' +
            ' WITH SECURITY_ENFORCED' +
            ' ORDER BY ' + sortField + ' ' + direction +
            ' LIMIT ' + limitValue;

        List<SObject> records;
        try {
            records = Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Error querying lookup options: ' + e.getMessage());
        }

        List<LookupOption> options = new List<LookupOption>();
        for (SObject row : records) {
            LookupOption option = new LookupOption();
            option.value = (Id)row.get('Id');
            option.label = (String)row.get(labelFieldApiName);
            options.add(option);
        }
        return options;
    }
    
    /**
     * Convenience method for Program Dates (maintains backward compatibility)
     * @deprecated Use getRelatedRecords with QueryConfig instead
     */
    @AuraEnabled(cacheable=true)
    public static List<Program_Dates__c> getProgramDates(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required');
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
