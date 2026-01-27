public with sharing class AllStatusRuleGroupMustBeActiveRule
  implements OnboardingAppActivationRule {

  public void apply(Id recordId, String objectApiName) {
    applyBulk(new Set<Id>{ recordId }, objectApiName);
  }

  public void applyBulk(Set<Id> recordIds, String objectApiName) {
    if (recordIds == null || recordIds.isEmpty()) {
      return;
    }

    Map<Id, Onboarding_Status_Rules_Engine__c> enginesById =
      new Map<Id, Onboarding_Status_Rules_Engine__c>([
        SELECT Id, Vendor_Program_Group__c, Vendor_Program_Group__r.Active__c
        FROM Onboarding_Status_Rules_Engine__c
        WHERE Id IN :recordIds
      ]);

    for (Id engineId : recordIds) {
      Onboarding_Status_Rules_Engine__c engine = enginesById.get(engineId);
      if (
        engine == null ||
        engine.Vendor_Program_Group__c == null ||
        engine.Vendor_Program_Group__r.Active__c != true
      ) {
        throw new AuraHandledException(
          'Cannot activate Rules Engine because the Vendor Program Group is not active.'
        );
      }
    }
  }
}
