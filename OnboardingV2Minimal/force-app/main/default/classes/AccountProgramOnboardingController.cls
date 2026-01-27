public with sharing class AccountProgramOnboardingController {
  @AuraEnabled(cacheable=true)
  public static VendorProgramEligibilityResult getVendorProgramEligibilityForAccount(
    Id accountId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    VendorOnboardingWizardRepository.AccountEligibility eligibility = VendorOnboardingWizardRepository.getAccountOnboardingEligibility(
      accountId
    );

    Boolean eligible = eligibility.hasNda && eligibility.hasProgramBase;
    String message;
    if (eligible) {
      message = 'Eligible for all vendor programs.';
    } else if (!eligibility.hasNda && !eligibility.hasProgramBase) {
      message = 'NDA and Program Base Application must be completed.';
    } else if (!eligibility.hasNda) {
      message = 'NDA must be completed.';
    } else {
      message = 'Program Base Application must be completed.';
    }

    VendorProgramEligibilityResult eligibilityResult = new VendorProgramEligibilityResult();
    eligibilityResult.eligibilityPassed = eligible;
    eligibilityResult.hasNda = eligibility.hasNda;
    eligibilityResult.hasProgramBase = eligibility.hasProgramBase;
    eligibilityResult.message = message;
    return eligibilityResult;
  }

  @AuraEnabled(cacheable=true)
  public static List<Vendor_Customization__c> searchVendorProgramsForAccount(
    Id accountId,
    String vendorProgramNameSearchText,
    Boolean eligibilityPassed,
    Boolean accountHasNda,
    Boolean accountHasProgramBase
  ) {
    return VendorDomainService.searchVendorProgramsForAccount(
      accountId,
      vendorProgramNameSearchText,
      eligibilityPassed,
      accountHasNda,
      accountHasProgramBase
    );
  }

  @AuraEnabled(cacheable=true)
  public static List<ContactRoleDTO> getAccountContactsWithRoles(
    Id accountId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    List<VendorOnboardingWizardRepository.ContactRoleInfo> infos = VendorOnboardingWizardRepository.getAccountContactsWithRoles(
      accountId
    );
    List<ContactRoleDTO> contactRoleDTOList = new List<ContactRoleDTO>();
    for (
      VendorOnboardingWizardRepository.ContactRoleInfo contactRoleInfo : infos
    ) {
      ContactRoleDTO contactRoleDTO = new ContactRoleDTO();
      contactRoleDTO.contactId = contactRoleInfo.contactId;
      contactRoleDTO.name = contactRoleInfo.name;
      contactRoleDTO.email = contactRoleInfo.email;
      contactRoleDTO.role = contactRoleInfo.role;
      contactRoleDTO.hasAcr = contactRoleInfo.hasAcr;
      contactRoleDTOList.add(contactRoleDTO);
    }
    return contactRoleDTOList;
  }

  @AuraEnabled
  public static Id upsertAccountContactRelation(
    Id accountId,
    Id contactId,
    String role
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    ValidationHelper.requireId(contactId, 'Contact ID');
    if (String.isBlank(role)) {
      throw new AuraHandledException(
        'Role is required for Contact ' + String.valueOf(contactId)
      );
    }
    return VendorOnboardingWizardRepository.upsertAccountContactRelation(
      accountId,
      contactId,
      role
    );
  }

  @AuraEnabled
  public static Id createOnboardingOpportunity(
    Id accountId,
    String name,
    String stageName,
    Date closeDate,
    Id recordTypeId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    if (String.isBlank(name)) {
      throw new AuraHandledException('Opportunity Name is required.');
    }
    Opportunity opp = new Opportunity(
      AccountId = accountId,
      Name = name,
      StageName = stageName,
      CloseDate = closeDate
    );
    if (recordTypeId != null) {
      opp.RecordTypeId = recordTypeId;
    }
    opp = DefaultValueHelper.applyOnboardingOpportunityDefaults(opp);
    insert opp;
    return opp.Id;
  }

  @AuraEnabled
  public static Id upsertOpportunityContactRole(
    Id opportunityId,
    Id contactId,
    String role,
    Boolean isPrimary
  ) {
    ValidationHelper.requireId(opportunityId, 'Opportunity ID');
    ValidationHelper.requireId(contactId, 'Contact ID');
    OpportunityContactRole ocr = new OpportunityContactRole(
      OpportunityId = opportunityId,
      ContactId = contactId,
      Role = role,
      IsPrimary = isPrimary == null ? false : isPrimary
    );
    insert ocr;
    return ocr.Id;
  }

  @AuraEnabled
  public static OnboardingWithRequirementsResult createOnboardingWithRequirements(
    Id accountId,
    Id vendorProgramId,
    Id opportunityId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    ValidationHelper.requireId(vendorProgramId, 'Vendor Program ID');
    VendorOnboardingWizardRepository.OnboardingWithRequirementsResult result = VendorOnboardingWizardRepository.createOnboardingWithRequirements(
      accountId,
      vendorProgramId,
      opportunityId
    );
    OnboardingWithRequirementsResult response = new OnboardingWithRequirementsResult();
    response.onboardingId = result.onboardingId;
    response.requirementCount = result.requirementCount;
    return response;
  }

  @AuraEnabled
  public static Id createAccountVendorProgramOnboarding(
    Id accountId,
    Id onboardingId,
    Id opportunityId,
    String status,
    Id primaryContactId
  ) {
    ValidationHelper.requireId(accountId, 'Account ID');
    ValidationHelper.requireId(onboardingId, 'Onboarding ID');
    Account_Vendor_Program_Onboarding__c avo = new Account_Vendor_Program_Onboarding__c(
      Account__c = accountId,
      Onboarding__c = onboardingId,
      Opportunity__c = opportunityId,
      Status__c = String.isNotBlank(status) ? status : 'Intake',
      Primary_Contact__c = primaryContactId
    );
    insert avo;
    return avo.Id;
  }

  public class ContactRoleDTO {
    @AuraEnabled
    public Id contactId;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String email;
    @AuraEnabled
    public String role;
    @AuraEnabled
    public Boolean hasAcr;
  }

  public class VendorProgramEligibilityResult {
    @AuraEnabled
    public Boolean eligibilityPassed;
    @AuraEnabled
    public Boolean hasNda;
    @AuraEnabled
    public Boolean hasProgramBase;
    @AuraEnabled
    public String message;
  }

  public class OnboardingWithRequirementsResult {
    @AuraEnabled
    public Id onboardingId;
    @AuraEnabled
    public Integer requirementCount;
  }
}
