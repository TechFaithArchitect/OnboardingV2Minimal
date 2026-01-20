/**
 * DTO representing a single Retail Option and its associated Business Verticals
 * Used as part of the VendorOnboardingDTO
 */
public class VendorRetailOptionGroupDTO {
  @InvocableVariable(label='Retail Option')
  public String retailOption;

  @InvocableVariable(label='Business Verticals')
  public List<String> businessVerticals;
}
