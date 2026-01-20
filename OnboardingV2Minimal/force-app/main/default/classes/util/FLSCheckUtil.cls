/**
 * Utility for lightweight, bulk-safe field-level security checks.
 */
public with sharing class FLSCheckUtil {

    public static Boolean isReadable(Schema.SObjectType sObjectType, String fieldApiName) {
        return getFieldDescribe(sObjectType, fieldApiName)?.isAccessible() == true;
    }

    public static Boolean isUpdateable(Schema.SObjectType sObjectType, String fieldApiName) {
        return getFieldDescribe(sObjectType, fieldApiName)?.isUpdateable() == true;
    }

    public static Boolean isCreateable(Schema.SObjectType sObjectType, String fieldApiName) {
        return getFieldDescribe(sObjectType, fieldApiName)?.isCreateable() == true;
    }

    private static Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectType sObjectType, String fieldApiName) {
        if (sObjectType == null || String.isBlank(fieldApiName)) {
            return null;
        }
        Map<String, Schema.SObjectField> fields = sObjectType.getDescribe().fields.getMap();
        Schema.SObjectField field = fields.get(fieldApiName);
        return field != null ? field.getDescribe() : null;
    }
}