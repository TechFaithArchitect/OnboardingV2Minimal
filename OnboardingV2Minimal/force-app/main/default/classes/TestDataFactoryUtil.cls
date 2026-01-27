/**
 * Utility class for test data factories.
 * Provides helper methods for inserting records, generating unique values,
 * and dynamically retrieving picklist values to avoid hardcoded invalid values.
 * 
 * @example Getting picklist values:
 * // Method 1: Using SObjectType (recommended for new objects)
 * String status = TestDataFactoryUtil.getDefaultPicklistValue(
 *     Vendor_Program_Requirement__c.SObjectType, 
 *     'Status__c'
 * );
 * 
 * // Method 2: Using SObject instance (convenient when object already exists)
 * Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c();
 * req.Status__c = TestDataFactoryUtil.getDefaultPicklistValue(req, 'Status__c');
 * 
 * // Method 3: Get first active value instead of default
 * String logicType = TestDataFactoryUtil.getFirstPicklistValue(
 *     Vendor_Program_Group__c.SObjectType, 
 *     'Logic_Type__c'
 * );
 */
public class TestDataFactoryUtil {
    public static void maybeInsert(SObject sObj, Boolean doInsert) {
        if (doInsert) insert sObj;
    }

    public static void maybeInsert(List<SObject> sObjects, Boolean doInsert) {
        if (doInsert && !sObjects.isEmpty()) {
            insert sObjects;
        }
    }

    public static String generateUniqueEmail(String name) {
        return name + '+' + DateTime.now().getTime() + '@yopmail.com';
    }

    /**
     * Gets the first active picklist value for a field on an SObject type.
     * Useful for test factories to get valid picklist values dynamically.
     * 
     * @param sObjType The SObject type (e.g., Vendor_Program_Group__c.SObjectType)
     * @param fieldName The API name of the picklist field (e.g., 'Logic_Type__c')
     * @return The first active picklist value, or null if none found
     */
    public static String getFirstPicklistValue(Schema.SObjectType sObjType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = sObjType.getDescribe()
            .fields.getMap()
            .get(fieldName)
            ?.getDescribe();
        
        if (fieldDescribe == null || fieldDescribe.getType() != Schema.DisplayType.PICKLIST) {
            return null;
        }
        
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        
        return null;
    }

    /**
     * Gets the default picklist value for a field on an SObject type.
     * Falls back to the first active value if no default is set.
     * 
     * @param sObjType The SObject type (e.g., Vendor_Program_Group__c.SObjectType)
     * @param fieldName The API name of the picklist field (e.g., 'Logic_Type__c')
     * @return The default picklist value, or the first active value, or null if none found
     */
    public static String getDefaultPicklistValue(Schema.SObjectType sObjType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = sObjType.getDescribe()
            .fields.getMap()
            .get(fieldName)
            ?.getDescribe();
        
        if (fieldDescribe == null || fieldDescribe.getType() != Schema.DisplayType.PICKLIST) {
            return null;
        }
        
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive() && entry.isDefaultValue()) {
                return entry.getValue();
            }
        }
        
        // Fall back to first active value if no default
        return getFirstPicklistValue(sObjType, fieldName);
    }

    /**
     * Gets all active picklist values for a field on an SObject type.
     * 
     * @param sObjType The SObject type (e.g., Vendor_Program_Group__c.SObjectType)
     * @param fieldName The API name of the picklist field (e.g., 'Logic_Type__c')
     * @return List of active picklist values
     */
    public static List<String> getPicklistValues(Schema.SObjectType sObjType, String fieldName) {
        List<String> values = new List<String>();
        
        Schema.DescribeFieldResult fieldDescribe = sObjType.getDescribe()
            .fields.getMap()
            .get(fieldName)
            ?.getDescribe();
        
        if (fieldDescribe == null || fieldDescribe.getType() != Schema.DisplayType.PICKLIST) {
            return values;
        }
        
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        
        return values;
    }

    /**
     * Gets the reference type (SObject type) for a lookup/master-detail field.
     * Useful for test factories to determine what object type a lookup field expects.
     * 
     * @param sObjType The SObject type (e.g., Vendor_Program_Requirement__c.SObjectType)
     * @param fieldName The API name of the lookup field (e.g., 'Requirement_Group_Member__c')
     * @return The SObjectType that the field references, or null if not a lookup/master-detail field
     */
    public static Schema.SObjectType getLookupReferenceType(Schema.SObjectType sObjType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = sObjType.getDescribe()
            .fields.getMap()
            .get(fieldName)
            ?.getDescribe();
        
        if (fieldDescribe == null) {
            return null;
        }
        
        Schema.DisplayType fieldType = fieldDescribe.getType();
        if (fieldType == Schema.DisplayType.REFERENCE) {
            List<Schema.SObjectType> referenceTypes = fieldDescribe.getReferenceTo();
            if (!referenceTypes.isEmpty()) {
                return referenceTypes[0];
            }
        }
        
        return null;
    }

    /**
     * Checks if a field is required.
     * 
     * @param sObjType The SObject type (e.g., Vendor_Program_Requirement__c.SObjectType)
     * @param fieldName The API name of the field (e.g., 'Requirement_Group_Member__c')
     * @return true if the field is required, false otherwise
     */
    public static Boolean isFieldRequired(Schema.SObjectType sObjType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = sObjType.getDescribe()
            .fields.getMap()
            .get(fieldName)
            ?.getDescribe();
        
        if (fieldDescribe == null) {
            return false;
        }
        
        return fieldDescribe.isCreateable() && fieldDescribe.isNillable() == false;
    }

    /**
     * Convenience method to get a picklist value for a field on an SObject instance.
     * This is the easiest way to get picklist values - just pass the SObject and field name.
     * 
     * @param sObj The SObject instance (e.g., new Vendor_Program_Requirement__c())
     * @param fieldName The API name of the picklist field (e.g., 'Status__c')
     * @param preferDefault If true, returns default value; if false, returns first active value
     * @return A valid picklist value, or null if field is not a picklist or has no values
     * 
     * @example
     * Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c();
     * req.Status__c = TestDataFactoryUtil.getPicklistValue(req, 'Status__c', true);
     */
    public static String getPicklistValue(SObject sObj, String fieldName, Boolean preferDefault) {
        if (sObj == null || String.isBlank(fieldName)) {
            return null;
        }
        
        Schema.SObjectType sObjType = sObj.getSObjectType();
        if (preferDefault) {
            return getDefaultPicklistValue(sObjType, fieldName);
        } else {
            return getFirstPicklistValue(sObjType, fieldName);
        }
    }

    /**
     * Convenience method to get the default picklist value for a field on an SObject instance.
     * Shorthand for getPicklistValue(sObj, fieldName, true).
     * 
     * @param sObj The SObject instance (e.g., new Vendor_Program_Requirement__c())
     * @param fieldName The API name of the picklist field (e.g., 'Status__c')
     * @return The default picklist value, or first active value if no default, or null
     * 
     * @example
     * Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c();
     * req.Status__c = TestDataFactoryUtil.getDefaultPicklistValue(req, 'Status__c');
     */
    public static String getDefaultPicklistValue(SObject sObj, String fieldName) {
        return getPicklistValue(sObj, fieldName, true);
    }

    /**
     * Convenience method to get the first active picklist value for a field on an SObject instance.
     * Shorthand for getPicklistValue(sObj, fieldName, false).
     * 
     * @param sObj The SObject instance (e.g., new Vendor_Program_Requirement__c())
     * @param fieldName The API name of the picklist field (e.g., 'Status__c')
     * @return The first active picklist value, or null
     * 
     * @example
     * Vendor_Program_Requirement__c req = new Vendor_Program_Requirement__c();
     * req.Status__c = TestDataFactoryUtil.getFirstPicklistValue(req, 'Status__c');
     */
    public static String getFirstPicklistValue(SObject sObj, String fieldName) {
        return getPicklistValue(sObj, fieldName, false);
    }

    public static Boolean saveResultHasError(Database.SaveResult saveResult, String expectedSubstring) {
        if (saveResult == null || String.isBlank(expectedSubstring)) {
            return false;
        }

        for (Database.Error err : saveResult.getErrors()) {
            if (err != null && err.getMessage() != null && err.getMessage().contains(expectedSubstring)) {
                return true;
            }
        }

        return false;
    }

    public static String joinErrorMessages(Database.SaveResult saveResult) {
        if (saveResult == null) {
            return '';
        }

        List<String> messages = new List<String>();
        for (Database.Error err : saveResult.getErrors()) {
            if (err != null && err.getMessage() != null) {
                messages.add(err.getMessage());
            }
        }

        return String.join(messages, ' | ');
    }

}