/*
 * AdminDev seed script for Vendor Program / Vendor Customization data model.
 * Safe to re-run: it creates missing records and updates core flags when needed.
 *
 * Add one or more vendor names in vendorNamesInput, then run:
 *   sf apex run --target-org AdminDev --file scripts/apex/seedVendorProgramCustomizationData.apex
 */

List<String> vendorNamesInput = new List<String>{
    'AdminDev ECC Seed Vendor'
};

String vendorProgramLabel = 'Verizon Fios D2D';
String eccGroupName = 'AdminDev ECC Default Group';

// Two credential types so dependency logic can be exercised.
Map<String, Integer> credentialTypeSortOrder = new Map<String, Integer>{
    'Background Check' => 1,
    'Sales Portal Access' => 2
};

String dependencyTypeName = 'Sales Portal Access';
String dependsOnTypeName = 'Background Check';

List<Map<String, Object>> displayFieldConfigs = new List<Map<String, Object>>{
    new Map<String, Object>{
        'apiName' => 'POE_Process_Status__c',
        'label' => 'Process Status',
        'readOnly' => false,
        'visible' => true,
        'sortOrder' => 1
    },
    new Map<String, Object>{
        'apiName' => 'POE_Username__c',
        'label' => 'Username',
        'readOnly' => false,
        'visible' => true,
        'sortOrder' => 2
    },
    new Map<String, Object>{
        'apiName' => 'Activation_Date__c',
        'label' => 'Activation Date',
        'readOnly' => false,
        'visible' => true,
        'sortOrder' => 3
    },
    new Map<String, Object>{
        'apiName' => 'Training_Sent_Date__c',
        'label' => 'Training Sent Date',
        'readOnly' => true,
        'visible' => true,
        'sortOrder' => 4
    }
};

class VendorProgramSeeder {
    public static void seedForVendor(
        String vendorName,
        String vendorProgramLabel,
        String eccGroupName,
        Map<String, Integer> credentialTypeSortOrder,
        String dependencyTypeName,
        String dependsOnTypeName,
        List<Map<String, Object>> displayFieldConfigs
    ) {
        // 1) Vendor
        Vendor__c vendor;
        List<Vendor__c> existingVendors = [
            SELECT Id, Name, Active__c
            FROM Vendor__c
            WHERE Name = :vendorName
            LIMIT 1
        ];

        if (existingVendors.isEmpty()) {
            vendor = new Vendor__c(
                Name = vendorName,
                Active__c = true
            );
            insert vendor;
        } else {
            vendor = existingVendors[0];
            if (!vendor.Active__c) {
                vendor.Active__c = true;
                update vendor;
            }
        }

        // 2) Vendor Program (Vendor_Customization__c)
        Vendor_Customization__c vendorProgram;
        List<Vendor_Customization__c> existingPrograms = [
            SELECT Id, Vendor__c, Label__c, Retail_Option__c, Business_Vertical__c
            FROM Vendor_Customization__c
            WHERE Vendor__c = :vendor.Id
            AND Label__c = :vendorProgramLabel
            LIMIT 1
        ];

        if (existingPrograms.isEmpty()) {
            vendorProgram = new Vendor_Customization__c(
                Vendor__c = vendor.Id,
                Label__c = vendorProgramLabel,
                Retail_Option__c = 'National Agent',
                Business_Vertical__c = 'D2D',
                Order_Entry_Platform__c = true
            );
            insert vendorProgram;
        } else {
            vendorProgram = existingPrograms[0];
            Boolean needsProgramUpdate = false;

            if (vendorProgram.Retail_Option__c != 'National Agent') {
                vendorProgram.Retail_Option__c = 'National Agent';
                needsProgramUpdate = true;
            }
            if (vendorProgram.Business_Vertical__c != 'D2D') {
                vendorProgram.Business_Vertical__c = 'D2D';
                needsProgramUpdate = true;
            }

            if (needsProgramUpdate) {
                update vendorProgram;
            }
        }

        // 3) External Contact Credential Types
        Map<String, External_Contact_Credential_Type__c> existingTypeByName = new Map<String, External_Contact_Credential_Type__c>();
        for (External_Contact_Credential_Type__c t : [
            SELECT Id, Name, Active__c, Sort_Order__c, Vendor__c, Vendor_Customization__c
            FROM External_Contact_Credential_Type__c
            WHERE Vendor_Customization__c = :vendorProgram.Id
            AND Name IN :credentialTypeSortOrder.keySet()
        ]) {
            if (!existingTypeByName.containsKey(t.Name)) {
                existingTypeByName.put(t.Name, t);
            }
        }

        List<External_Contact_Credential_Type__c> typesToInsert = new List<External_Contact_Credential_Type__c>();
        List<External_Contact_Credential_Type__c> typesToUpdate = new List<External_Contact_Credential_Type__c>();

        for (String typeName : credentialTypeSortOrder.keySet()) {
            Integer sortOrder = credentialTypeSortOrder.get(typeName);
            External_Contact_Credential_Type__c existingType = existingTypeByName.get(typeName);

            if (existingType == null) {
                typesToInsert.add(new External_Contact_Credential_Type__c(
                    Name = typeName,
                    Active__c = true,
                    Sort_Order__c = sortOrder,
                    Vendor__c = vendor.Id,
                    Vendor_Customization__c = vendorProgram.Id,
                    Unique_Key__c = vendor.Name + '|' + vendorProgram.Label__c + '|' + typeName
                ));
            } else {
                Boolean needsTypeUpdate = false;
                if (!existingType.Active__c) {
                    existingType.Active__c = true;
                    needsTypeUpdate = true;
                }
                if (existingType.Sort_Order__c == null || existingType.Sort_Order__c.intValue() != sortOrder) {
                    existingType.Sort_Order__c = sortOrder;
                    needsTypeUpdate = true;
                }
                if (existingType.Vendor__c != vendor.Id) {
                    existingType.Vendor__c = vendor.Id;
                    needsTypeUpdate = true;
                }
                if (existingType.Vendor_Customization__c != vendorProgram.Id) {
                    existingType.Vendor_Customization__c = vendorProgram.Id;
                    needsTypeUpdate = true;
                }

                if (needsTypeUpdate) {
                    typesToUpdate.add(existingType);
                }
            }
        }

        if (!typesToInsert.isEmpty()) insert typesToInsert;
        if (!typesToUpdate.isEmpty()) update typesToUpdate;

        Map<String, Id> typeIdByName = new Map<String, Id>();
        for (External_Contact_Credential_Type__c t : [
            SELECT Id, Name
            FROM External_Contact_Credential_Type__c
            WHERE Vendor_Customization__c = :vendorProgram.Id
            AND Name IN :credentialTypeSortOrder.keySet()
        ]) {
            typeIdByName.put(t.Name, t.Id);
        }

        // 4) Required Credential entries
        Set<Id> typeIds = new Set<Id>(typeIdByName.values());
        Set<String> existingRequiredCredentialKeys = new Set<String>();

        if (!typeIds.isEmpty()) {
            for (Required_Credential__c rc : [
                SELECT Id, Vendor_Customization__c, External_Contact_Credential_Type__c
                FROM Required_Credential__c
                WHERE Vendor_Customization__c = :vendorProgram.Id
                AND External_Contact_Credential_Type__c IN :typeIds
            ]) {
                existingRequiredCredentialKeys.add(
                    rc.Vendor_Customization__c + '|' + rc.External_Contact_Credential_Type__c
                );
            }
        }

        List<Required_Credential__c> requiredCredentialsToInsert = new List<Required_Credential__c>();
        for (String typeName : typeIdByName.keySet()) {
            Id typeId = typeIdByName.get(typeName);
            String key = vendorProgram.Id + '|' + typeId;
            if (!existingRequiredCredentialKeys.contains(key)) {
                requiredCredentialsToInsert.add(new Required_Credential__c(
                    Vendor_Customization__c = vendorProgram.Id,
                    External_Contact_Credential_Type__c = typeId,
                    Is_Required__c = true,
                    Sequence__c = credentialTypeSortOrder.get(typeName)
                ));
            }
        }
        if (!requiredCredentialsToInsert.isEmpty()) insert requiredCredentialsToInsert;

        // 5) Dependency (Sales Portal Access depends on Background Check)
        Id dependencyTypeId = typeIdByName.get(dependencyTypeName);
        Id dependsOnTypeId = typeIdByName.get(dependsOnTypeName);

        if (dependencyTypeId != null && dependsOnTypeId != null) {
            Integer dependencyCount = [
                SELECT COUNT()
                FROM External_Credential_Type_Dependency__c
                WHERE Vendor_Program__c = :vendorProgram.Id
                AND Credential_Type__c = :dependencyTypeId
                AND Depends_On__c = :dependsOnTypeId
            ];

            if (dependencyCount == 0) {
                insert new External_Credential_Type_Dependency__c(
                    Vendor_Program__c = vendorProgram.Id,
                    Credential_Type__c = dependencyTypeId,
                    Depends_On__c = dependsOnTypeId
                );
            }
        }

        // 6) ECC Field Configuration Group + Mapping
        ECC_Field_Configuration_Group__c eccGroup;
        List<ECC_Field_Configuration_Group__c> existingGroups = [
            SELECT Id, Name, Is_Active__c
            FROM ECC_Field_Configuration_Group__c
            WHERE Name = :eccGroupName
            LIMIT 1
        ];

        if (existingGroups.isEmpty()) {
            eccGroup = new ECC_Field_Configuration_Group__c(
                Name = eccGroupName,
                Is_Active__c = true
            );
            insert eccGroup;
        } else {
            eccGroup = existingGroups[0];
            if (!eccGroup.Is_Active__c) {
                eccGroup.Is_Active__c = true;
                update eccGroup;
            }
        }

        Integer mappingCount = [
            SELECT COUNT()
            FROM ECC_Field_Configuration_Group_Mapping__c
            WHERE Vendor_Program__c = :vendorProgram.Id
            AND ECC_Field_Configuration_Group__c = :eccGroup.Id
        ];

        if (mappingCount == 0) {
            insert new ECC_Field_Configuration_Group_Mapping__c(
                Vendor_Program__c = vendorProgram.Id,
                ECC_Field_Configuration_Group__c = eccGroup.Id
            );
        }

        // 7) ECC Field Display Config rows (per credential type)
        Set<String> apiNames = new Set<String>();
        for (Map<String, Object> cfg : displayFieldConfigs) {
            apiNames.add((String) cfg.get('apiName'));
        }

        Map<String, ECC_Field_Display_Configuration__c> existingDisplayConfigByKey = new Map<String, ECC_Field_Display_Configuration__c>();
        if (!typeIds.isEmpty()) {
            for (ECC_Field_Display_Configuration__c cfg : [
                SELECT Id,
                       ECC_Field_Configuration_Group__c,
                       External_Contact_Credential_Type__c,
                       Field_API_Name__c,
                       Field_Label__c,
                       Read_Only__c,
                       Visible__c,
                       Sort_Order__c
                FROM ECC_Field_Display_Configuration__c
                WHERE ECC_Field_Configuration_Group__c = :eccGroup.Id
                AND External_Contact_Credential_Type__c IN :typeIds
                AND Field_API_Name__c IN :apiNames
            ]) {
                String key = cfg.External_Contact_Credential_Type__c + '|' + cfg.Field_API_Name__c;
                if (!existingDisplayConfigByKey.containsKey(key)) {
                    existingDisplayConfigByKey.put(key, cfg);
                }
            }
        }

        List<ECC_Field_Display_Configuration__c> displayConfigsToInsert = new List<ECC_Field_Display_Configuration__c>();
        List<ECC_Field_Display_Configuration__c> displayConfigsToUpdate = new List<ECC_Field_Display_Configuration__c>();

        for (String typeName : typeIdByName.keySet()) {
            Id typeId = typeIdByName.get(typeName);

            for (Map<String, Object> targetCfg : displayFieldConfigs) {
                String apiName = (String) targetCfg.get('apiName');
                String key = typeId + '|' + apiName;
                ECC_Field_Display_Configuration__c existingCfg = existingDisplayConfigByKey.get(key);

                String targetLabel = (String) targetCfg.get('label');
                Boolean targetReadOnly = (Boolean) targetCfg.get('readOnly');
                Boolean targetVisible = (Boolean) targetCfg.get('visible');
                Integer targetSortOrder = (Integer) targetCfg.get('sortOrder');

                if (existingCfg == null) {
                    displayConfigsToInsert.add(new ECC_Field_Display_Configuration__c(
                        ECC_Field_Configuration_Group__c = eccGroup.Id,
                        External_Contact_Credential_Type__c = typeId,
                        Field_API_Name__c = apiName,
                        Field_Label__c = targetLabel,
                        Read_Only__c = targetReadOnly,
                        Visible__c = targetVisible,
                        Sort_Order__c = targetSortOrder
                    ));
                } else {
                    Boolean needsDisplayUpdate = false;

                    if (existingCfg.Field_Label__c != targetLabel) {
                        existingCfg.Field_Label__c = targetLabel;
                        needsDisplayUpdate = true;
                    }
                    if (existingCfg.Read_Only__c != targetReadOnly) {
                        existingCfg.Read_Only__c = targetReadOnly;
                        needsDisplayUpdate = true;
                    }
                    if (existingCfg.Visible__c != targetVisible) {
                        existingCfg.Visible__c = targetVisible;
                        needsDisplayUpdate = true;
                    }
                    if (existingCfg.Sort_Order__c == null || existingCfg.Sort_Order__c.intValue() != targetSortOrder) {
                        existingCfg.Sort_Order__c = targetSortOrder;
                        needsDisplayUpdate = true;
                    }

                    if (needsDisplayUpdate) {
                        displayConfigsToUpdate.add(existingCfg);
                    }
                }
            }
        }

        if (!displayConfigsToInsert.isEmpty()) insert displayConfigsToInsert;
        if (!displayConfigsToUpdate.isEmpty()) update displayConfigsToUpdate;

        System.debug(LoggingLevel.INFO, 'Seed complete for vendor: ' + vendorName);
        System.debug(LoggingLevel.INFO, 'Vendor Id: ' + vendor.Id);
        System.debug(LoggingLevel.INFO, 'Vendor Program (Vendor_Customization__c) Id: ' + vendorProgram.Id);
        System.debug(LoggingLevel.INFO, 'Credential Type Ids: ' + typeIdByName);
        System.debug(LoggingLevel.INFO, 'Inserted Required Credentials: ' + requiredCredentialsToInsert.size());
        System.debug(LoggingLevel.INFO, 'Inserted Display Configs: ' + displayConfigsToInsert.size());
    }
}

Set<String> dedupedVendorNames = new Set<String>();
for (String nameValue : vendorNamesInput) {
    if (!String.isBlank(nameValue)) {
        dedupedVendorNames.add(nameValue.trim());
    }
}

List<String> vendorNames = new List<String>(dedupedVendorNames);
vendorNames.sort();

if (vendorNames.isEmpty()) {
    System.debug(LoggingLevel.WARN, 'No vendor names were provided in vendorNamesInput. Nothing to seed.');
} else {
    for (String vendorName : vendorNames) {
        VendorProgramSeeder.seedForVendor(
            vendorName,
            vendorProgramLabel,
            eccGroupName,
            credentialTypeSortOrder,
            dependencyTypeName,
            dependsOnTypeName,
            displayFieldConfigs
        );
    }
}
