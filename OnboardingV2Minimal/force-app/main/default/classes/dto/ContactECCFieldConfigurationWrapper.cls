public class ContactECCFieldConfigurationWrapper {
  public class FieldDisplayConfig {
    @AuraEnabled
    public String apiName;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean readOnly;

    public FieldDisplayConfig(String apiName, String label, Boolean readOnly) {
      this.apiName = apiName;
      this.label = label;
      this.readOnly = readOnly;
    }
  }

  /**
   * Returns a map of Vendor Customization Id → List of FieldDisplayConfig
   */
  @AuraEnabled(cacheable=true)
  public static Map<Id, List<FieldDisplayConfig>> getFieldConfigurationsByVendorAndType(
    List<POE_External_Contact_Credential__c> eccRecords
  ) {
    Map<Id, List<FieldDisplayConfig>> result = new Map<Id, List<FieldDisplayConfig>>();

    if (eccRecords.isEmpty())
      return result;

    // Step 1: Build VC → Group map
    Set<Id> vendorCustomizationIds = new Set<Id>();
    for (POE_External_Contact_Credential__c ecc : eccRecords) {
      if (
        ecc.External_Contact_Credential_Type__r?.Vendor_Customization__c != null
      ) {
        vendorCustomizationIds.add(
          ecc.External_Contact_Credential_Type__r.Vendor_Customization__c
        );
      }
    }

    Map<Id, Id> vcToGroupMap = new Map<Id, Id>();
    for (ECC_Field_Configuration_Group_Mapping__c mapping : [
      SELECT Vendor_Program__c, ECC_Field_Configuration_Group__c
      FROM ECC_Field_Configuration_Group_Mapping__c
      WHERE Vendor_Program__c IN :vendorCustomizationIds
    ]) {
      vcToGroupMap.put(
        mapping.Vendor_Program__c,
        mapping.ECC_Field_Configuration_Group__c
      );
    }

    // Step 2: Query all config records for those groups
    Set<Id> groupIds = new Set<Id>(vcToGroupMap.values());

    List<ECC_Field_Display_Configuration__c> configs = [
      SELECT
        ECC_Field_Configuration_Group__c,
        External_Contact_Credential_Type__c,
        Field_API_Name__c,
        Field_Label__c,
        Read_Only__c,
        Visible__c
      FROM ECC_Field_Display_Configuration__c
      WHERE ECC_Field_Configuration_Group__c IN :groupIds AND Visible__c = TRUE
    ];

    // Step 3: Build Group+Type → List<FieldDisplayConfig>
    Map<String, List<FieldDisplayConfig>> groupTypeToFields = new Map<String, List<FieldDisplayConfig>>();
    for (ECC_Field_Display_Configuration__c cfg : configs) {
      String key =
        cfg.ECC_Field_Configuration_Group__c +
        ':' +
        cfg.External_Contact_Credential_Type__c;
      if (!groupTypeToFields.containsKey(key)) {
        groupTypeToFields.put(key, new List<FieldDisplayConfig>());
      }
      groupTypeToFields.get(key)
        .add(
          new FieldDisplayConfig(
            cfg.Field_API_Name__c,
            cfg.Field_Label__c,
            cfg.Read_Only__c
          )
        );
    }

    // Step 4: Map ECC Id → relevant fields
    for (POE_External_Contact_Credential__c ecc : eccRecords) {
      Id eccId = ecc.Id;
      Id vendorId = ecc.External_Contact_Credential_Type__r
        ?.Vendor_Customization__c;
      Id eccTypeId = ecc.External_Contact_Credential_Type__c;
      Id groupId = vcToGroupMap.get(vendorId);
      String key = groupId + ':' + eccTypeId;

      if (groupTypeToFields.containsKey(key)) {
        result.put(eccId, groupTypeToFields.get(key));
      } else {
        result.put(eccId, new List<FieldDisplayConfig>());
      }
    }

    return result;
  }
}
