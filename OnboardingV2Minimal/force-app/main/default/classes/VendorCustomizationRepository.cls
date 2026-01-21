public with sharing class VendorCustomizationRepository {
    
    /**
     * Fetches a Vendor_Customization__c record by ID with standard fields.
     * @param recordId The record ID
     * @return The Vendor_Customization__c record
     */
    public static Vendor_Customization__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Vendor_Customization__c> vendorCustomizationRecords = [
            SELECT Id, Status__c, Active__c, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return vendorCustomizationRecords.isEmpty() ? null : vendorCustomizationRecords[0];
    }
    
    /**
     * Fetches multiple Vendor_Customization__c records by IDs.
     * @param recordIds Set of record IDs
     * @return List of Vendor_Customization__c records
     */
    public static List<Vendor_Customization__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new List<Vendor_Customization__c>();
        }
        return [
            SELECT Id, Status__c, Active__c, Previous_Version__c
            FROM Vendor_Customization__c
            WHERE Id IN :recordIds
        ];
    }

    /**
     * Fetches active Vendor_Customization__c records for eligibility checks.
     * @param vendorIds Optional vendor filter
     * @param programIds Optional program filter
     * @return List of active Vendor_Customization__c records
     */
    public static List<Vendor_Customization__c> getActiveVendorPrograms(
        List<Id> vendorIds,
        List<Id> programIds
    ) {
        List<String> conditions = new List<String>{
            'Active__c = true'
        };

        if (vendorIds != null && !vendorIds.isEmpty()) {
            conditions.add('Vendor__c IN :vendorIds');
        }

        if (programIds != null && !programIds.isEmpty()) {
            conditions.add('Id IN :programIds');
        }

        String whereClause = String.join(conditions, ' AND ');
        String query = 'SELECT Id, Vendor__c FROM Vendor_Customization__c WHERE ' + whereClause;

        return Database.query(query);
    }
    
    /**
     * Fetches active sibling records by parent version ID.
     * @param parentVersionId The Previous_Version__c ID
     * @param excludeIds Set of IDs to exclude from results
     * @return List of active sibling Vendor_Customization__c records
     */
    public static List<Vendor_Customization__c> getActiveSiblingsByParentVersion(
        Id parentVersionId, 
        Set<Id> excludeIds
    ) {
        if (parentVersionId == null) {
            return new List<Vendor_Customization__c>();
        }
        
        if (excludeIds != null && !excludeIds.isEmpty()) {
            return [
                SELECT Id, Active__c, Previous_Version__c
                FROM Vendor_Customization__c
                WHERE Previous_Version__c = :parentVersionId
                AND Active__c = true
                AND Id NOT IN :excludeIds
            ];
        } else {
            return [
                SELECT Id, Active__c, Previous_Version__c
                FROM Vendor_Customization__c
                WHERE Previous_Version__c = :parentVersionId
                AND Active__c = true
            ];
        }
    }
    
    /**
     * Updates Vendor_Customization__c records.
     * @param records List of records to update
     */
    public static void updateRecords(List<Vendor_Customization__c> vendorCustomizationRecords) {
        if (vendorCustomizationRecords != null && !vendorCustomizationRecords.isEmpty()) {
            update vendorCustomizationRecords;
        }
    }
    
    /**
     * Updates a single Vendor_Customization__c record.
     * @param vendorCustomizationRecord The record to update
     */
    public static void updateRecord(Vendor_Customization__c vendorCustomizationRecord) {
        if (vendorCustomizationRecord != null) {
            update vendorCustomizationRecord;
        }
    }
    
    /**
     * Fetches a Vendor_Customization__c record by ID with basic fields (Id, Vendor__c, Name).
     * @param recordId The record ID
     * @return The Vendor_Customization__c record or null if not found
     */
    public static Vendor_Customization__c getBasicById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Vendor_Customization__c> vendorCustomizationRecords = [
            SELECT Id, Vendor__c, Name
            FROM Vendor_Customization__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return vendorCustomizationRecords.isEmpty() ? null : vendorCustomizationRecords[0];
    }
    
    /**
     * Fetches a Vendor_Customization__c record by ID with metadata fields (ownership and timestamps).
     * @param recordId The record ID
     * @return The Vendor_Customization__c record or null if not found
     */
    public static Vendor_Customization__c getMetadataById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Vendor_Customization__c> vendorCustomizationRecords = [
            SELECT Id, Name, CreatedById, CreatedBy.Name, CreatedDate,
                   LastModifiedById, LastModifiedBy.Name, LastModifiedDate
            FROM Vendor_Customization__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return vendorCustomizationRecords.isEmpty() ? null : vendorCustomizationRecords[0];
    }
}