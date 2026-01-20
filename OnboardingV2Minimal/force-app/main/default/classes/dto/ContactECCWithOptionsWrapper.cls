public class ContactECCWithOptionsWrapper {
  @AuraEnabled
  public POE_External_Contact_Credential__c record;
  @AuraEnabled
  public List<ContactECCPicklistOptionWrapper> picklistOptions;
  @AuraEnabled
  public List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig> fieldConfigs;

  public ContactECCWithOptionsWrapper(
    POE_External_Contact_Credential__c rec,
    List<String> options,
    List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig> fieldConfigs
  ) {
    this.record = rec;
    this.picklistOptions = new List<ContactECCPicklistOptionWrapper>();
    this.fieldConfigs = fieldConfigs;

    for (String opt : options) {
      this.picklistOptions.add(new ContactECCPicklistOptionWrapper(opt, opt));
    }
  }
}
