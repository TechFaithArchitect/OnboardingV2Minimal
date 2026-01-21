/**
 * Utility for simple custom metadata retrieval with in-memory caching.
 */
public with sharing class CustomMetadataUtil {
    private static Map<String, SObject> cache = new Map<String, SObject>();

    public static SObject getByDeveloperName(Schema.SObjectType mdtType, String developerName) {
        if (mdtType == null || String.isBlank(developerName)) {
            return null;
        }
        String cacheKey = mdtType.getDescribe().getName() + ':' + developerName;
        if (cache.containsKey(cacheKey)) {
            return cache.get(cacheKey);
        }
        String soql = 'SELECT Id, DeveloperName, MasterLabel FROM ' +
                      mdtType.getDescribe().getName() +
                      ' WHERE DeveloperName = :developerName LIMIT 1';
        SObject customMetadataRecord = null;
        try {
            List<SObject> queryResults = Database.query(soql);
            customMetadataRecord = queryResults.isEmpty() ? null : queryResults[0];
        } catch (Exception ex) {
            System.debug('CustomMetadataUtil query failed: ' + ex.getMessage());
        }
        cache.put(cacheKey, customMetadataRecord);
        return customMetadataRecord;
    }

    public static void clearCache() {
        cache.clear();
    }
}