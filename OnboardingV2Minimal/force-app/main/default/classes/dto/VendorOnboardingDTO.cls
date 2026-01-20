public class VendorOnboardingDTO {
  @InvocableVariable
  public Id vendorId;
  @InvocableVariable
  public String vendorName;
  @InvocableVariable
  public List<String> availableRetailOptions;
  @InvocableVariable
  public List<VendorRetailOptionGroupDTO> retailOptionGroups;
}
