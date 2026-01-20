public class CredentialDependencyWrapper {
  @AuraEnabled
  public String credentialType;
  @AuraEnabled
  public List<String> dependsOn;

  public CredentialDependencyWrapper(
    String credentialType,
    List<String> dependsOn
  ) {
    this.credentialType = credentialType;
    this.dependsOn = dependsOn;
  }
}
