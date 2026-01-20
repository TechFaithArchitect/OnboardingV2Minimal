public class VendorProgramReqGroupTriggerHandler {
    
    /**
     * Handles versioning for Vendor_Program_Requirement_Group__c records.
     * Auto-increments Version field (v1, v2, v3, etc.) based on existing records with the same Name.
     */
    public static void handleVersioning(List<Vendor_Program_Requirement_Group__c> newRecords, Map<Id, Vendor_Program_Requirement_Group__c> oldMap) {
        // Only process inserts (new records)
        if (oldMap != null && !oldMap.isEmpty()) {
            return;
        }

        // Collect names we need to evaluate
        Set<String> groupNames = new Set<String>();
        for (Vendor_Program_Requirement_Group__c newRecord : newRecords) {
            if (String.isNotBlank(newRecord.Name)) {
                groupNames.add(newRecord.Name);
            }
        }

        if (groupNames.isEmpty()) {
            return;
        }

        // Query existing records with matching names to find highest version
        Map<String, Integer> nameToMaxVersion = new Map<String, Integer>();
        List<Vendor_Program_Requirement_Group__c> existingGroups = [
            SELECT Id, Name, Version__c
            FROM Vendor_Program_Requirement_Group__c
            WHERE Name IN :groupNames
            AND Version__c != null
        ];

        // Parse existing versions to find the maximum for each name
        for (Vendor_Program_Requirement_Group__c existingGroup : existingGroups) {
            if (String.isNotBlank(existingGroup.Version__c)) {
                String versionStr = existingGroup.Version__c.trim();
                // Extract number from "v1", "v2", etc.
                if (versionStr.startsWithIgnoreCase('v')) {
                    try {
                        Integer versionNum = Integer.valueOf(versionStr.substring(1));
                        String name = existingGroup.Name;
                        if (!nameToMaxVersion.containsKey(name) || nameToMaxVersion.get(name) < versionNum) {
                            nameToMaxVersion.put(name, versionNum);
                        }
                    } catch (Exception ex) {
                        // If version format is invalid, skip it
                        System.debug('Invalid version format: ' + versionStr);
                    }
                }
            }
        }

        // Include any provided versions in the same transaction so we keep incrementing from the highest value
        for (Vendor_Program_Requirement_Group__c newRecord : newRecords) {
            if (String.isNotBlank(newRecord.Version__c) && String.isNotBlank(newRecord.Name)) {
                String versionStr = newRecord.Version__c.trim();
                if (versionStr.startsWithIgnoreCase('v')) {
                    try {
                        Integer versionNum = Integer.valueOf(versionStr.substring(1));
                        if (!nameToMaxVersion.containsKey(newRecord.Name) || nameToMaxVersion.get(newRecord.Name) < versionNum) {
                            nameToMaxVersion.put(newRecord.Name, versionNum);
                        }
                    } catch (Exception ex) {
                        System.debug('Invalid provided version format: ' + versionStr);
                    }
                }
            }
        }

        // Assign versions sequentially within the current transaction to avoid duplicates
        Map<String, Integer> nextVersionByName = new Map<String, Integer>();
        for (Vendor_Program_Requirement_Group__c newRecord : newRecords) {
            if (String.isBlank(newRecord.Version__c) && String.isNotBlank(newRecord.Name)) {
                Integer nextVersion = nextVersionByName.get(newRecord.Name);
                if (nextVersion == null) {
                    Integer currentMax = nameToMaxVersion.containsKey(newRecord.Name)
                        ? nameToMaxVersion.get(newRecord.Name)
                        : 0;
                    nextVersion = currentMax + 1;
                }
                newRecord.Version__c = 'v' + nextVersion;
                nextVersionByName.put(newRecord.Name, nextVersion + 1);
            }
        }
    }
}