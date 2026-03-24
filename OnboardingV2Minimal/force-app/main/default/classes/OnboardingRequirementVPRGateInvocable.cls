/**
 * Flow entry: returns Vendor_Program_Requirement__c rows to materialize on this pass (idempotent, sequence-ordered),
 * and whether additional VPR rows remain after an approval gate (Block_Action__c on CMDT).
 */
public with sharing class OnboardingRequirementVPRGateInvocable {
  public class Request {
    @InvocableVariable(label='Onboarding Id')
    public Id onboardingId;

    @InvocableVariable(label='Vendor Program Id' description='Vendor_Customization__c Id')
    public Id vendorProgramId;
  }

  public class Result {
    @InvocableVariable(
      label='Vendor Program Requirements To Create'
      description='VPR rows to pass into DOMAIN_OmniSObject_SFL_CREATE_Onboarding_Requirements for this run.'
    )
    public List<Vendor_Program_Requirement__c> vendorProgramRequirements;

    @InvocableVariable(
      label='Deferred Requirements Remain'
      description='True when additional program requirements still need Onboarding_Requirement__c rows after this batch (approval gate).'
    )
    public Boolean deferredRequirementsRemain;

    @InvocableVariable(
      label='Gate Stopped This Batch'
      description='True when creation stopped due to Block_Action__c on a matched approval policy for a row in this batch.'
    )
    public Boolean gateStoppedThisBatch;
  }

  @InvocableMethod(
    label='Filter Vendor Program Requirements for Onboarding Gate'
    description='Skips VPRs that already have an onboarding requirement. Resolves CMDT Policy_Key from VPR.Approval_Policy_Key__c or Vendor_Customization__c.Approval_Policy_Key__c with Requirement_Type__c; when Block_Action__c matches, defers that row until Onboarding_Status__c is Approved, then creates it and stops the batch after that row.'
  )
  public static List<Result> filterForGate(List<Request> requests) {
    List<Result> results = new List<Result>();
    if (requests == null) {
      return results;
    }
    for (Request req : requests) {
      Result r = new Result();
      r.vendorProgramRequirements = new List<Vendor_Program_Requirement__c>();
      r.deferredRequirementsRemain = false;
      r.gateStoppedThisBatch = false;
      if (req == null || req.onboardingId == null || req.vendorProgramId == null) {
        results.add(r);
        continue;
      }
      OnboardingRequirementVPRGateService.GateOutcome outcome = OnboardingRequirementVPRGateService.buildGateOutcome(
        req.onboardingId,
        req.vendorProgramId
      );
      r.vendorProgramRequirements = outcome.vendorProgramRequirementsToCreate == null
        ? new List<Vendor_Program_Requirement__c>()
        : outcome.vendorProgramRequirementsToCreate;
      r.deferredRequirementsRemain = outcome.deferredRequirementsRemain == true;
      r.gateStoppedThisBatch = outcome.gateStoppedThisBatch == true;
      results.add(r);
    }
    return results;
  }
}
