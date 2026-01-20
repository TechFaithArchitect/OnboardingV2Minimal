/**
 * Utility class for retrieving picklist values
 * Eliminates code duplication and provides consistent picklist handling
 */
public with sharing class PicklistHelper {
    
    /**
     * Gets picklist values for a field using schema describe
     * @param objectApiName The API name of the object (e.g., 'Vendor_Program_Group__c')
     * @param fieldApiName The API name of the field (e.g., 'Logic_Type__c')
     * @return List of maps with 'label' and 'value' keys
     */
    public static List<Map<String, String>> getPicklistValues(String objectApiName, String fieldApiName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return options;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Schema.SObjectField field = objectDescribe.fields.getMap().get(fieldApiName);
            
            if (field == null) {
                return options;
            }
            
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception ex) {
            System.debug('Error getting picklist values for ' + objectApiName + '.' + fieldApiName + ': ' + ex.getMessage());
        }
        
        return options;
    }
    
    /**
     * Gets picklist values for a field with fallback values
     * @param objectApiName The API name of the object
     * @param fieldApiName The API name of the field
     * @param fallbackValues List of fallback values to use if schema describe fails
     * @return List of maps with 'label' and 'value' keys
     */
    public static List<Map<String, String>> getPicklistValuesWithFallback(
        String objectApiName, 
        String fieldApiName, 
        List<String> fallbackValues
    ) {
        List<Map<String, String>> options = getPicklistValues(objectApiName, fieldApiName);
        
        // If no values found, use fallback
        if (options.isEmpty() && fallbackValues != null) {
            for (String value : fallbackValues) {
                options.add(new Map<String, String>{
                    'label' => value,
                    'value' => value
                });
            }
        }
        
        return options;
    }
    
    /**
     * Gets picklist values for a field using direct field reference (faster for known types)
     * @param fieldToken The field token (e.g., Vendor_Program_Group__c.Logic_Type__c)
     * @param fallbackValues Optional fallback values if schema describe fails
     * @return List of maps with 'label' and 'value' keys
     */
    public static List<Map<String, String>> getPicklistValuesByField(
        Schema.SObjectField fieldToken, 
        List<String> fallbackValues
    ) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        try {
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception ex) {
            System.debug('Error getting picklist values: ' + ex.getMessage());
        }
        
        // If no values found and fallback provided, use fallback
        if (options.isEmpty() && fallbackValues != null) {
            for (String value : fallbackValues) {
                options.add(new Map<String, String>{
                    'label' => value,
                    'value' => value
                });
            }
        }
        
        return options;
    }

    public static Boolean isPicklistValueValid(String objectApiName, String fieldApiName, String value) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName) || String.isBlank(value)) {
            return false;
        }

        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return false;
            }

            Schema.SObjectField field = sObjectType.getDescribe().fields.getMap().get(fieldApiName);
            if (field == null) {
                return false;
            }

            for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
                if (entry.isActive() && entry.getValue() == value) {
                    return true;
                }
            }
        } catch (Exception ex) {
            System.debug('Error validating picklist value for ' + objectApiName + '.' + fieldApiName + ': ' + ex.getMessage());
        }

        return false;
    }

    public static String getValidPicklistValue(String objectApiName, String fieldApiName, String preferredValue) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            return preferredValue;
        }

        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return preferredValue;
            }

            Schema.SObjectField field = sObjectType.getDescribe().fields.getMap().get(fieldApiName);
            if (field == null) {
                return preferredValue;
            }

            String defaultValue;
            String firstActive;
            for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
                if (!entry.isActive()) {
                    continue;
                }
                if (firstActive == null) {
                    firstActive = entry.getValue();
                }
                if (entry.isDefaultValue()) {
                    defaultValue = entry.getValue();
                }
                if (preferredValue != null && entry.getValue() == preferredValue) {
                    return preferredValue;
                }
            }

            if (defaultValue != null) {
                return defaultValue;
            }
            if (firstActive != null) {
                return firstActive;
            }
        } catch (Exception ex) {
            System.debug('Error getting picklist value for ' + objectApiName + '.' + fieldApiName + ': ' + ex.getMessage());
        }

        return preferredValue;
    }
}