public class ContactECCPicklistOptionWrapper {
  @AuraEnabled
  public String label;
  @AuraEnabled
  public String value;

  public ContactECCPicklistOptionWrapper(String label, String value) {
    this.label = label;
    this.value = value;
  }
}
