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
   * Returns a map of ECC Id -> List of FieldDisplayConfig.
   * Vendor Program is resolved from POE_Program__c (program label).
   */
  @AuraEnabled(cacheable=true)
  public static Map<Id, List<FieldDisplayConfig>> getFieldConfigurationsByVendorAndType(
    List<POE_External_Contact_Credential__c> eccRecords
  ) {
    Map<Id, List<FieldDisplayConfig>> result = new Map<Id, List<FieldDisplayConfig>>();

    if (eccRecords == null || eccRecords.isEmpty())
      return result;

    Set<String> programNames = new Set<String>();
    for (POE_External_Contact_Credential__c ecc : eccRecords) {
      if (String.isNotBlank(ecc.POE_Program__c)) {
        programNames.add(ecc.POE_Program__c.trim());
      }
    }

    Map<String, Id> vendorProgramIdByLabel = new Map<String, Id>();
    if (!programNames.isEmpty()) {
      for (Vendor_Customization__c vendorProgram : [
        SELECT Id, Label__c
        FROM Vendor_Customization__c
        WHERE Label__c IN :programNames
        ORDER BY CreatedDate ASC, Id ASC
      ]) {
        if (!vendorProgramIdByLabel.containsKey(vendorProgram.Label__c)) {
          vendorProgramIdByLabel.put(vendorProgram.Label__c, vendorProgram.Id);
        }
      }
    }

    // Step 1: Build VC -> Group map
    Set<Id> vendorCustomizationIds = new Set<Id>(vendorProgramIdByLabel.values());
    Map<Id, Id> vcToGroupMap = new Map<Id, Id>();
    if (!vendorCustomizationIds.isEmpty()) {
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
    }

    // Step 2: Query all config records for those groups
    Set<Id> groupIds = new Set<Id>(vcToGroupMap.values());

    List<ECC_Field_Display_Configuration__c> configs =
      groupIds.isEmpty()
        ? new List<ECC_Field_Display_Configuration__c>()
        : [
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
      Id vendorId = String.isBlank(ecc.POE_Program__c)
        ? null
        : vendorProgramIdByLabel.get(ecc.POE_Program__c.trim());
      Id eccTypeId = ecc.External_Contact_Credential_Type__c;
      Id groupId = vendorId == null ? null : vcToGroupMap.get(vendorId);

      if (groupId == null || eccTypeId == null) {
        result.put(eccId, new List<FieldDisplayConfig>());
        continue;
      }

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
