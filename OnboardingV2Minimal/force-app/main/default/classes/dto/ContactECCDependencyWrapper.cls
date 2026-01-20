public class ContactECCDependencyWrapper {
  @AuraEnabled
  public List<ContactECCWithOptionsWrapper> records;
  @AuraEnabled
  public List<CredentialDependencyWrapper> dependencies;
  @AuraEnabled
  public Map<Id, List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig>> fieldConfigurations;

  public ContactECCDependencyWrapper(
    List<ContactECCWithOptionsWrapper> records,
    List<CredentialDependencyWrapper> dependencies,
    Map<Id, List<ContactECCFieldConfigurationWrapper.FieldDisplayConfig>> fieldConfigurations
  ) {
    this.records = records;
    this.dependencies = dependencies;
    this.fieldConfigurations = fieldConfigurations;
  }
}
