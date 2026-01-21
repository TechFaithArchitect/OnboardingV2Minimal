/**
 * Handler for Onboarding_Requirement_Set__c trigger logic
 * Handles Display_Label__c population using junction objects
 */
public with sharing class RequirementSetTriggerHandler {
    
    // Static flag to prevent recursion
    private static Boolean isUpdatingDisplayLabel = false;
    
    /**
     * Before insert/update logic
     * Sets default Display_Label__c if not provided
     */
    public static void run(List<Onboarding_Requirement_Set__c> newList, Map<Id, Onboarding_Requirement_Set__c> oldMap) {
        for (Onboarding_Requirement_Set__c reqSet : newList) {
            // Set a default Display_Label__c if not provided
            // This will be updated by afterInsert/afterUpdate when junction records exist
            if (String.isBlank(reqSet.Display_Label__c)) {
                // Try to get Version__c if it exists
                Decimal version = 1;
                try {
                    Object versionObj = reqSet.get('Version__c');
                    if (versionObj != null) {
                        if (versionObj instanceof Decimal) {
                            version = (Decimal)versionObj;
                        } else if (versionObj instanceof String) {
                            String versionStr = (String)versionObj;
                            if (String.isNotBlank(versionStr)) {
                                version = Decimal.valueOf(versionStr);
                            }
                        }
                    }
                } catch (Exception ex) {
                    // Version__c field doesn't exist or can't be read - use default
                }
                reqSet.Display_Label__c = 'Requirements - v' + version;
            }
        }
    }
    
    /**
     * After insert logic - populate Display_Label__c
     * Note: Must query fresh records to update, as trigger.new records are read-only in after context
     */
    public static void afterInsert(List<Onboarding_Requirement_Set__c> newList) {
        if (isUpdatingDisplayLabel) {
            return; // Prevent recursion
        }
        
        // Query fresh records to update (trigger.new is read-only in after context)
        Set<Id> requirementSetIds = new Set<Id>();
        for (Onboarding_Requirement_Set__c reqSet : newList) {
            requirementSetIds.add(reqSet.Id);
        }
        
        if (!requirementSetIds.isEmpty()) {
            List<Onboarding_Requirement_Set__c> toUpdate = [
                SELECT Id, Display_Label__c
                FROM Onboarding_Requirement_Set__c
                WHERE Id IN :requirementSetIds
            ];
            // Only auto-update Display Labels that are blank or auto-generated
            updateDisplayLabels(toUpdate);
        }
    }
    
    /**
     * After update logic - update Display_Label__c if Version__c changed
     * Only updates if Display_Label__c is blank or auto-generated (preserves user-manual entries)
     * Note: Must query fresh records to update, as trigger.new records are read-only in after context
     */
    public static void afterUpdate(List<Onboarding_Requirement_Set__c> newList, Map<Id, Onboarding_Requirement_Set__c> oldMap) {
        if (isUpdatingDisplayLabel) {
            return; // Prevent recursion
        }
        
        Set<Id> requirementSetIdsToUpdate = new Set<Id>();
        
        for (Onboarding_Requirement_Set__c reqSet : newList) {
            // Handle case where oldMap might be null (insert context) or Id doesn't exist
            Onboarding_Requirement_Set__c oldReqSet = (oldMap != null && oldMap.containsKey(reqSet.Id)) 
                ? oldMap.get(reqSet.Id) 
                : null;
            
            // Check if Version__c changed (if field exists)
            // Note: Version__c might not exist - handle gracefully
            try {
                if (oldReqSet != null && reqSet.get('Version__c') != oldReqSet.get('Version__c')) {
                    requirementSetIdsToUpdate.add(reqSet.Id);
                }
            } catch (Exception ex) {
                // Version__c field doesn't exist - ignore
            }
        }
        
        if (!requirementSetIdsToUpdate.isEmpty()) {
            // Query fresh records to update (trigger.new is read-only in after context)
            // Include Display_Label__c so we can check if it was manually set
            List<Onboarding_Requirement_Set__c> toUpdate = [
                SELECT Id, Display_Label__c, Version__c
                FROM Onboarding_Requirement_Set__c
                WHERE Id IN :requirementSetIdsToUpdate
            ];
            // Only auto-update Display Labels that are blank or auto-generated
            updateDisplayLabels(toUpdate);
        }
    }
    
    /**
     * Updates Display_Label__c for requirement sets based on junction objects.
     * Called from Vendor_Program_Requirement_Set__c trigger when junction records change.
     */
    public static void updateDisplayLabelsFromJunction(
        List<Vendor_Program_Requirement_Set__c> junctions, 
        Map<Id, Vendor_Program_Requirement_Set__c> oldMap
    ) {
        if (isUpdatingDisplayLabel) {
            return; // Prevent recursion
        }
        
        Set<Id> requirementSetIds = new Set<Id>();
        
        if (junctions != null && !junctions.isEmpty()) {
            for (Vendor_Program_Requirement_Set__c junction : junctions) {
                if (junction.Onboarding_Requirement_Set__c != null) {
                    requirementSetIds.add(junction.Onboarding_Requirement_Set__c);
                }
            }
        }
        
        // Also check old map for deleted records
        if (oldMap != null && !oldMap.isEmpty()) {
            for (Vendor_Program_Requirement_Set__c oldJunction : oldMap.values()) {
                if (oldJunction.Onboarding_Requirement_Set__c != null) {
                    requirementSetIds.add(oldJunction.Onboarding_Requirement_Set__c);
                }
            }
        }
        
        if (requirementSetIds.isEmpty()) {
            return;
        }
        
        List<Onboarding_Requirement_Set__c> requirementSets = [
            SELECT Id, Display_Label__c
            FROM Onboarding_Requirement_Set__c
            WHERE Id IN :requirementSetIds
        ];
        
        if (!requirementSets.isEmpty()) {
            // Only auto-update Display Labels that are blank or auto-generated
            updateDisplayLabels(requirementSets);
        }
    }
    
    /**
     * Updates Display_Label__c for requirement sets based on linked vendor programs via junction.
     * Formula: First Vendor Program Label + " Requirements - v" + Version (if exists)
     * If multiple vendor programs, uses first one alphabetically by Label.
     * 
     * IMPORTANT: Only updates Display_Label__c if it's blank/null or matches the auto-generated pattern.
     * This preserves user-manually-entered Display Labels.
     */
    private static void updateDisplayLabels(List<Onboarding_Requirement_Set__c> requirementSets) {
        if (requirementSets == null || requirementSets.isEmpty()) {
            return;
        }
        
        Set<Id> requirementSetIds = new Set<Id>();
        for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
            requirementSetIds.add(reqSet.Id);
        }
        
        // Get vendor programs linked via junction
        Map<Id, String> vendorProgramLabelByRequirementSet = new Map<Id, String>();
        
        for (Vendor_Program_Requirement_Set__c junction : [
            SELECT Onboarding_Requirement_Set__c, 
                   Vendor_Program__r.Label__c
            FROM Vendor_Program_Requirement_Set__c
            WHERE Onboarding_Requirement_Set__c IN :requirementSetIds
            ORDER BY Vendor_Program__r.Label__c ASC NULLS LAST
        ]) {
            // Store first vendor program label (sorted alphabetically)
            if (!vendorProgramLabelByRequirementSet.containsKey(junction.Onboarding_Requirement_Set__c) &&
                junction.Vendor_Program__r.Label__c != null) {
                vendorProgramLabelByRequirementSet.put(
                    junction.Onboarding_Requirement_Set__c, 
                    junction.Vendor_Program__r.Label__c
                );
            }
        }
        
        // Query requirement sets with Version__c and Display_Label__c to check if user manually set it
        List<Onboarding_Requirement_Set__c> reqSetsToUpdate = new List<Onboarding_Requirement_Set__c>();
        
        try {
            // Try to query with Version__c and Display_Label__c
            Map<Id, Onboarding_Requirement_Set__c> reqSetsMap = new Map<Id, Onboarding_Requirement_Set__c>([
                SELECT Id, Version__c, Display_Label__c
                FROM Onboarding_Requirement_Set__c
                WHERE Id IN :requirementSetIds
            ]);
            
            for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
                Onboarding_Requirement_Set__c fullReqSet = reqSetsMap.get(reqSet.Id);
                if (fullReqSet == null) {
                    continue;
                }
                
                // Only update Display_Label__c if:
                // 1. It's blank/null, OR
                // 2. It matches the auto-generated pattern (starts with "Requirements - v")
                // This preserves user-manually-entered labels
                String currentDisplayLabel = fullReqSet.Display_Label__c;
                Boolean shouldUpdate = String.isBlank(currentDisplayLabel) || 
                                       currentDisplayLabel.startsWith('Requirements - v');
                
                if (shouldUpdate) {
                    String vendorProgramLabel = vendorProgramLabelByRequirementSet.get(reqSet.Id);
                    String displayLabel = buildDisplayLabel(vendorProgramLabel, fullReqSet.Version__c);
                    
                    reqSet.Display_Label__c = displayLabel;
                    reqSetsToUpdate.add(reqSet);
                }
            }
        } catch (Exception ex) {
            // Version__c or Display_Label__c field doesn't exist - build without version
            for (Onboarding_Requirement_Set__c reqSet : requirementSets) {
                String vendorProgramLabel = vendorProgramLabelByRequirementSet.get(reqSet.Id);
                String displayLabel = buildDisplayLabel(vendorProgramLabel, null);
                
                reqSet.Display_Label__c = displayLabel;
                reqSetsToUpdate.add(reqSet);
            }
        }
        
        if (!reqSetsToUpdate.isEmpty()) {
            // Set flag to prevent recursion
            isUpdatingDisplayLabel = true;
            try {
                update reqSetsToUpdate;
            } finally {
                isUpdatingDisplayLabel = false;
            }
        }
    }
    
    /**
     * Builds the display label string.
     * Format: "Vendor Program Label Requirements - v{Version}" or "Requirements - v{Version}" if no vendor program
     * @param vendorProgramLabel The vendor program label (can be null)
     * @param version The version (can be Decimal, String, or null)
     */
    private static String buildDisplayLabel(String vendorProgramLabel, Object version) {
        String versionText = '1';
        
        if (version != null) {
            if (version instanceof Decimal) {
                versionText = String.valueOf((Decimal)version);
            } else if (version instanceof String) {
                String versionStr = (String)version;
                versionText = String.isNotBlank(versionStr) ? versionStr : '1';
            } else {
                versionText = String.valueOf(version);
            }
        }
        
        if (String.isNotBlank(vendorProgramLabel)) {
            return vendorProgramLabel + ' Requirements - v' + versionText;
        } else {
            return 'Requirements - v' + versionText;
        }
    }
}