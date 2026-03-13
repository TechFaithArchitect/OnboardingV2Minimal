public with sharing class OnboardingInvocables {
  @TestVisible
  private static Boolean forceFailureForTests = false;

  public class VendorOptionsRequest {
    @InvocableVariable(required=true label='Account Id')
    public Id accountId;
  }

  public class VendorOptionsResult {
    @InvocableVariable(label='Account Id')
    public Id accountId;

    @InvocableVariable(label='Eligible Vendors JSON')
    public String eligibleVendorsJson;

    @InvocableVariable(label='Eligible Vendor Count')
    public Integer eligibleVendorCount;

    @InvocableVariable(label='Error Message')
    public String errorMessage;
  }

  @InvocableMethod(
    label='Get Eligible Vendors JSON (Typed)'
    description='Returns eligible vendors as JSON for each Account Id.'
  )
  public static List<VendorOptionsResult> getEligibleVendorsJson(
    List<VendorOptionsRequest> requests
  ) {
    List<VendorOptionsResult> results = new List<VendorOptionsResult>();
    if (requests == null || requests.isEmpty()) {
      return results;
    }

    for (VendorOptionsRequest requestItem : requests) {
      VendorOptionsResult resultItem = new VendorOptionsResult();
      resultItem.eligibleVendorsJson = '[]';
      resultItem.eligibleVendorCount = 0;
      resultItem.accountId = requestItem == null ? null : requestItem.accountId;

      if (requestItem == null || requestItem.accountId == null) {
        resultItem.errorMessage = 'Account Id is required.';
        results.add(resultItem);
        continue;
      }

      try {
        if (Test.isRunningTest() && forceFailureForTests) {
          throw new IllegalArgumentException('Forced test failure');
        }

        List<String> jsonResults = VendorOnboardingService.getVendorsAsJson(
          new List<Id>{ requestItem.accountId }
        );
        if (jsonResults != null && !jsonResults.isEmpty()) {
          resultItem.eligibleVendorsJson = jsonResults[0];
          resultItem.eligibleVendorCount = getJsonArraySize(
            resultItem.eligibleVendorsJson
          );
        }
      } catch (Exception ex) {
        resultItem.errorMessage = 'Unable to retrieve eligible vendors.';
        LoggingUtil.error(
          'OnboardingInvocables.getEligibleVendorsJson failed for account ' +
          String.valueOf(requestItem.accountId) +
          ': ' +
          ex.getMessage()
        );
      }

      results.add(resultItem);
    }

    return results;
  }

  private static Integer getJsonArraySize(String jsonPayload) {
    Object deserialized = JSON.deserializeUntyped(
      String.isBlank(jsonPayload) ? '[]' : jsonPayload
    );
    if (deserialized instanceof List<Object>) {
      return ((List<Object>)deserialized).size();
    }

    return 0;
  }
}
