/**
 * Evaluates active Onboarding_Next_Step_Rule__mdt when onboarding reaches Setup Complete.
 * Auto Create: inserts a sibling Onboarding__c for Scope_Key__c (target Vendor_Customization__c) when the
 * field path (from the triggering onboarding row) matches Expected_Value__c with Operator__c Equals.
 * Each auto-created onboarding gets a new Draft Contract on the same Account and Opportunity as the source.
 *
 * Runs without sharing so CMDT-driven reads (target Vendor_Customization__c, contract record-type reference) are not
 * hidden from the running user. Sibling Contract uses SYSTEM_MODE insert first for the vendor-program RecordType, then
 * aligns RecordTypeId after insert if needed; Retailer_Type__c is copied from Vendor_Customization__c.Retail_Option__c
 * so validation (e.g. required Retailer type on New Dealer Application (DOM)) matches DOMAIN_OmniSObject_SFL_CREATE_Contract.
 * If the vendor-program record type cannot be inserted, we do not fall back to a default-type contract (which would
 * silently violate the vendor program). Onboarding__c remains insert as user.
 *
 * If Contract.RecordTypeId is left unset, Salesforce applies the running user profile default Contract record type
 * (e.g. System Administrator often defaults to NDA). We avoid creating a misleading sibling when the vendor program
 * has Contract_Record_Type__c set but RecordTypeId cannot be resolved from Contract_Record_Type_Reference__c.
 */
public without sharing class OnboardingNextStepRuleService {
  /** Test and production use: in-memory view of a CMDT rule row. */
  public class RuleSnapshot {
    public String developerName;
    public String action;
    public String scopeKey;
    public String fieldApiName;
    public String expectedValue;
    public String operator;
  }

  /** Populated by applyAfterSetupCompleteSwallowingFaultsWithOutcome for Flow (errors + user-facing warnings). */
  public class ApplyOutcome {
    public String errorMessage;
    public String warningMessage;
  }

  @TestVisible
  private class ForcedTestException extends Exception {
  }

  private class VendorProgramContractRtResolve {
    Id recordTypeId;
    boolean hasContractRecordTypeLookup;
    String retailOption;
  }

  private class RuleTargetMatch {
    RuleSnapshot rule;
    Id targetVendorProgramId;
  }

  private static final String STATUS_SETUP_COMPLETE = 'Setup Complete';
  private static final String ACTION_AUTO_CREATE = 'Auto Create';
  private static final String OP_EQUALS = 'Equals';
  private static final Pattern SAFE_FIELD_PATH = Pattern.compile('^[a-zA-Z0-9_]+(\\.[a-zA-Z0-9_]+)*$');
  private static final String ACR_ROLE_PRINCIPAL_OWNER = 'Principal Owner';

  @TestVisible
  static Boolean forceThrowForTest = false;

  /** Same as applyAfterSetupComplete but never throws; returns an error message for Flow/debug or blank on success. */
  public static String applyAfterSetupCompleteSwallowingFaults(Id onboardingId) {
    ApplyOutcome o = applyAfterSetupCompleteSwallowingFaultsWithOutcome(onboardingId);
    return o.errorMessage == null ? '' : o.errorMessage;
  }

  /**
   * Never throws. ApplyOutcome.errorMessage is set when an exception occurs;
   * ApplyOutcome.warningMessage when a rule matched but linked onboarding/contract could not be created (e.g. no primary responsible contact).
   */
  public static ApplyOutcome applyAfterSetupCompleteSwallowingFaultsWithOutcome(Id onboardingId) {
    ApplyOutcome outcome = new ApplyOutcome();
    try {
      applyAfterSetupComplete(onboardingId, outcome);
    } catch (Exception ex) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.applyAfterSetupCompleteSwallowingFaults failed for Onboarding=' +
          String.valueOf(onboardingId) +
          ': ' +
          ex.getMessage()
      );
      outcome.errorMessage = ex.getMessage();
    }
    return outcome;
  }

  public static void applyAfterSetupComplete(Id onboardingId) {
    applyAfterSetupComplete(onboardingId, null);
  }

  private static void applyAfterSetupComplete(Id onboardingId, ApplyOutcome outcome) {
    if (onboardingId == null) {
      return;
    }
    if (forceThrowForTest) {
      throw new ForcedTestException('OnboardingNextStepRuleService: forced test throw');
    }
    List<RuleSnapshot> rules = loadActiveRulesFromCmdt();
    if (rules.isEmpty()) {
      return;
    }
    applyRuleSnapshots(onboardingId, rules, outcome);
  }

  @TestVisible
  static void applyRuleSnapshotsForTest(Id onboardingId, List<RuleSnapshot> rules) {
    applyRuleSnapshotsForTest(onboardingId, rules, null);
  }

  @TestVisible
  static void applyRuleSnapshotsForTest(Id onboardingId, List<RuleSnapshot> rules, ApplyOutcome outcome) {
    if (onboardingId == null || rules == null || rules.isEmpty()) {
      return;
    }
    applyRuleSnapshots(onboardingId, rules, outcome);
  }

  private static List<RuleSnapshot> loadActiveRulesFromCmdt() {
    List<RuleSnapshot> out = new List<RuleSnapshot>();
    if (!Schema.SObjectType.Onboarding_Next_Step_Rule__mdt.isAccessible()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.loadActiveRulesFromCmdt: missing read access to Onboarding_Next_Step_Rule__mdt; skipping rule load.'
      );
      return out;
    }
    for (Onboarding_Next_Step_Rule__mdt r : [
      SELECT
        DeveloperName,
        Action__c,
        Scope_Key__c,
        Field_API_Name__c,
        Expected_Value__c,
        Operator__c,
        Sequence__c
      FROM Onboarding_Next_Step_Rule__mdt
      WHERE Active__c = TRUE
      WITH USER_MODE
      ORDER BY Sequence__c NULLS LAST, DeveloperName
    ]) {
      RuleSnapshot s = new RuleSnapshot();
      s.developerName = r.DeveloperName;
      s.action = r.Action__c;
      s.scopeKey = r.Scope_Key__c;
      s.fieldApiName = r.Field_API_Name__c;
      s.expectedValue = r.Expected_Value__c;
      s.operator = r.Operator__c;
      out.add(s);
    }
    return out;
  }

  private static void applyRuleSnapshots(Id onboardingId, List<RuleSnapshot> rules, ApplyOutcome outcome) {
    if (!Schema.SObjectType.Onboarding__c.isAccessible()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.applyRuleSnapshots: missing read access to Onboarding__c; skipping evaluation.'
      );
      return;
    }
    Set<String> selectFields = new Set<String>{
      'Id',
      'Account__c',
      'Vendor_Customization__c',
      'Opportunity__c',
      'Contract__c',
      'Onboarding_Status__c'
    };
    for (RuleSnapshot rule : rules) {
      String path = rule == null ? null : rule.fieldApiName;
      if (String.isNotBlank(path) && SAFE_FIELD_PATH.matcher(path.trim()).matches()) {
        selectFields.add(path.trim());
      }
    }

    List<Onboarding__c> rows = queryOnboardingWithDynamicFields(selectFields, onboardingId);
    if (rows.isEmpty()) {
      return;
    }
    Onboarding__c onboarding = rows[0];
    if (onboarding.Onboarding_Status__c != STATUS_SETUP_COMPLETE) {
      return;
    }
    if (onboarding.Account__c == null) {
      return;
    }
    if (!Schema.SObjectType.Vendor_Customization__c.isAccessible()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.applyRuleSnapshots: missing read access to Vendor_Customization__c; skipping target program checks.'
      );
      return;
    }

    List<RuleTargetMatch> matchedRules = new List<RuleTargetMatch>();
    Set<Id> matchedTargetVendorProgramIds = new Set<Id>();
    for (RuleSnapshot rule : rules) {
      if (rule == null || String.isBlank(rule.action)) {
        continue;
      }
      if (!ACTION_AUTO_CREATE.equalsIgnoreCase(rule.action.trim())) {
        continue;
      }
      if (String.isBlank(rule.fieldApiName) || String.isBlank(rule.expectedValue)) {
        continue;
      }
      if (String.isNotBlank(rule.operator) && !OP_EQUALS.equalsIgnoreCase(rule.operator.trim())) {
        continue;
      }
      String path = rule.fieldApiName.trim();
      if (!SAFE_FIELD_PATH.matcher(path).matches()) {
        continue;
      }

      String actual = readPathAsString(onboarding, path);
      String expected = rule.expectedValue.trim();
      String actualTrimmed = actual == null ? null : actual.trim();
      if (actualTrimmed == null || !expected.equals(actualTrimmed)) {
        continue;
      }

      Id targetVendorProgramId = tryParseId(rule.scopeKey);
      if (targetVendorProgramId == null) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService: rule ' +
            String.valueOf(rule.developerName) +
            ' has invalid Scope_Key__c; skipped.'
        );
        continue;
      }

      RuleTargetMatch match = new RuleTargetMatch();
      match.rule = rule;
      match.targetVendorProgramId = targetVendorProgramId;
      matchedRules.add(match);
      matchedTargetVendorProgramIds.add(targetVendorProgramId);
    }

    if (matchedRules.isEmpty()) {
      return;
    }

    Set<Id> existingTargetVendorProgramIds = new Set<Id>();
    for (Vendor_Customization__c targetVp : [
      SELECT Id
      FROM Vendor_Customization__c
      WHERE Id IN :matchedTargetVendorProgramIds
      WITH USER_MODE
    ]) {
      existingTargetVendorProgramIds.add(targetVp.Id);
    }

    for (RuleTargetMatch match : matchedRules) {
      if (!existingTargetVendorProgramIds.contains(match.targetVendorProgramId)) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService: rule ' +
            String.valueOf(match.rule.developerName) +
            ' Scope_Key__c is not a Vendor_Customization__c Id in this org; skipped.'
        );
        continue;
      }
      createLinkedOnboardingIfNeeded(onboarding, match.targetVendorProgramId, outcome);
    }
  }

  @SuppressWarnings('PMD.ApexSOQLInjection')
  private static List<Onboarding__c> queryOnboardingWithDynamicFields(Set<String> selectFields, Id onboardingId) {
    String soql =
      'SELECT ' +
      String.join(new List<String>(selectFields), ', ') +
      ' FROM Onboarding__c WHERE Id = :onboardingId LIMIT 1';
    return Database.query(soql);
  }

  @TestVisible
  static String readPathAsStringForTest(SObject root, String path) {
    return readPathAsString(root, path);
  }

  private static String readPathAsString(SObject root, String path) {
    if (root == null || String.isBlank(path)) {
      return null;
    }
    List<String> parts = path.trim().split('\\.');
    SObject current = root;
    for (Integer i = 0; i < parts.size(); i++) {
      String segment = parts[i];
      if (i == parts.size() - 1) {
        Object v = current.get(segment);
        return v == null ? null : String.valueOf(v);
      }
      current = current.getSObject(segment);
      if (current == null) {
        return null;
      }
    }
    return null;
  }

  private static void createLinkedOnboardingIfNeeded(
    Onboarding__c source,
    Id targetVendorProgramId,
    ApplyOutcome outcome
  ) {
    if (targetVendorProgramId == null || source.Vendor_Customization__c == targetVendorProgramId) {
      return;
    }
    if (!Schema.SObjectType.Onboarding__c.isAccessible()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.createLinkedOnboardingIfNeeded: missing read access to Onboarding__c; cannot detect existing sibling.'
      );
      return;
    }

    List<Onboarding__c> existing = [
      SELECT Id
      FROM Onboarding__c
      WHERE
        Account__c = :source.Account__c
        AND Vendor_Customization__c = :targetVendorProgramId
        AND Opportunity__c = :source.Opportunity__c
      WITH USER_MODE
      LIMIT 1
    ];
    if (!existing.isEmpty()) {
      return;
    }

    Id newContractId = insertSiblingContract(source, targetVendorProgramId, outcome);
    if (newContractId == null) {
      return;
    }

    Onboarding__c linkedOnb = new Onboarding__c(
      Account__c = source.Account__c,
      Vendor_Customization__c = targetVendorProgramId,
      Opportunity__c = source.Opportunity__c,
      Contract__c = newContractId
    );
    insert as user linkedOnb;
  }

  /**
   * New Draft contract, same Account and Opportunity as the source onboarding (contract-centric sibling).
   * Order of operations: (1) Load Contract RecordTypeId from targetVendorProgramId (CMDT Scope_Key__c =
   * sibling Vendor_Customization__c Id)—the new Onboarding row does not exist yet and is not used for this lookup.
   * (2) Insert Contract. (3) Insert sibling Onboarding__c with that Contract and targetVendorProgramId.
   * Vendor-program RecordType uses SYSTEM_MODE insert first, then verify/correct RecordTypeId after insert, because
   * insert as user can leave RecordTypeId unset and apply the user profile default (e.g. System Admin → NDA).
   * Reuses ContractTerm and Principal Owner from the source contract when present; otherwise resolves
   * Contract.Principal_Owner__c from primary OpportunityContactRole or AccountContactRelation Principal Owner.
   */
  private static Id insertSiblingContract(Onboarding__c source, Id targetVendorProgramId, ApplyOutcome outcome) {
    if (source.Account__c == null) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.insertSiblingContract: source onboarding has no Account__c; skipped.'
      );
      return null;
    }

    Id principalOwnerId;
    Integer contractTermMonths = 12;
    VendorProgramContractRtResolve rtResolve = resolveVendorProgramContractRecordType(targetVendorProgramId);
    String retailerTypeFromVp = rtResolve.retailOption;
    if (rtResolve.hasContractRecordTypeLookup && rtResolve.recordTypeId == null) {
      String msg =
        'The linked onboarding and its contract were not created: the target vendor program has Contract Record Type configured, but Contract_Record_Type_Reference__c.RecordTypeId__c could not be read or parsed. ' +
        'Leaving Contract.RecordTypeId blank would apply your user profile default Contract record type (System Administrator is often NDA), which does not match the vendor program.';
      LoggingUtil.warn('OnboardingNextStepRuleService.insertSiblingContract: ' + msg);
      appendOutcomeWarning(outcome, msg);
      return null;
    }

    Id recordTypeFromTarget = rtResolve.recordTypeId;
    if (recordTypeFromTarget == null) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.insertSiblingContract: target Vendor_Customization__c has no Contract_Record_Type__c; ' +
          'Contract.RecordTypeId will be omitted so Salesforce applies the running user profile default (System Administrator is typically NDA). ' +
          'Set Contract Record Type on the vendor program for an explicit record type.'
      );
    }

    if (source.Contract__c != null) {
      if (!Schema.SObjectType.Contract.isAccessible()) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService.insertSiblingContract: missing read access to Contract; cannot read template contract fields.'
        );
        return null;
      }
      List<Contract> templates = [
        SELECT Principal_Owner__c, ContractTerm
        FROM Contract
        WHERE Id = :source.Contract__c
        WITH USER_MODE
        LIMIT 1
      ];
      if (!templates.isEmpty()) {
        Contract t = templates[0];
        principalOwnerId = t.Principal_Owner__c;
        if (t.ContractTerm != null) {
          contractTermMonths = t.ContractTerm;
        }
      }
    }

    if (principalOwnerId == null) {
      principalOwnerId = resolvePrincipalOwnerForSiblingContract(source, outcome);
      if (principalOwnerId == null) {
        return null;
      }
    }

    DmlException lastDex = null;

    if (recordTypeFromTarget != null) {
      Id contractId;
      try {
        contractId = insertDraftContractSystemMode(
          source.Account__c,
          source.Opportunity__c,
          principalOwnerId,
          contractTermMonths,
          recordTypeFromTarget,
          retailerTypeFromVp
        );
      } catch (DmlException dexSys) {
        lastDex = dexSys;
        LoggingUtil.warn(
          'OnboardingNextStepRuleService.insertSiblingContract: SYSTEM_MODE insert failed for vendor-program Contract RecordType ' +
            String.valueOf(recordTypeFromTarget) +
            ': ' +
            dexSys.getDmlMessage(0) +
            '. Retrying as user.'
        );
        try {
          contractId = insertDraftContractAsUser(
            source.Account__c,
            source.Opportunity__c,
            principalOwnerId,
            contractTermMonths,
            recordTypeFromTarget,
            retailerTypeFromVp
          );
        } catch (DmlException dexUsr) {
          lastDex = dexUsr;
          contractId = null;
          LoggingUtil.warn(
            'OnboardingNextStepRuleService.insertSiblingContract: insert as user also failed for vendor-program Contract RecordType ' +
              String.valueOf(recordTypeFromTarget) +
              ': ' +
              dexUsr.getDmlMessage(0)
          );
        }
      }
      if (contractId != null) {
        alignContractRecordTypeIfNeeded(contractId, recordTypeFromTarget, outcome);
        return contractId;
      }
      String abortMsg =
        'The linked onboarding and its contract were not created: the sibling contract could not be inserted with the vendor program record type (check validation rules and required fields such as Retailer_Type__c / Vendor_Customization__c.Retail_Option__c). ' +
        (lastDex != null ? lastDex.getDmlMessage(0) : '');
      LoggingUtil.warn('OnboardingNextStepRuleService.insertSiblingContract: ' + abortMsg);
      appendOutcomeWarning(outcome, abortMsg);
      return null;
    }

    try {
      return insertDraftContractAsUser(
        source.Account__c,
        source.Opportunity__c,
        principalOwnerId,
        contractTermMonths,
        null,
        retailerTypeFromVp
      );
    } catch (DmlException dex) {
      lastDex = dex;
    }

    try {
      Id contractId = insertDraftContractSystemMode(
        source.Account__c,
        source.Opportunity__c,
        principalOwnerId,
        contractTermMonths,
        null,
        retailerTypeFromVp
      );
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.insertSiblingContract: sibling Contract created with default RecordType (SYSTEM_MODE) after failures with vendor-program type.'
      );
      return contractId;
    } catch (DmlException dex3) {
      lastDex = dex3;
    }

    LoggingUtil.warn(
      'OnboardingNextStepRuleService.insertSiblingContract: all Contract insert attempts failed: ' +
        (lastDex != null ? lastDex.getMessage() : 'unknown')
    );
    throw lastDex;
  }

  /**
   * User-mode insert can succeed but omit RecordTypeId (profile default, e.g. NDA). Re-query and update when wrong.
   */
  private static void alignContractRecordTypeIfNeeded(Id contractId, Id expectedRecordTypeId, ApplyOutcome outcome) {
    if (contractId == null || expectedRecordTypeId == null) {
      return;
    }
    if (!Schema.SObjectType.Contract.isAccessible()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.alignContractRecordTypeIfNeeded: missing read access to Contract; skipping alignment verification.'
      );
      return;
    }
    Contract row = [SELECT RecordTypeId FROM Contract WHERE Id = :contractId WITH USER_MODE LIMIT 1];
    if (row.RecordTypeId == expectedRecordTypeId) {
      return;
    }
    LoggingUtil.warn(
      'OnboardingNextStepRuleService.alignContractRecordTypeIfNeeded: Contract ' +
        String.valueOf(contractId) +
        ' has RecordTypeId ' +
        String.valueOf(row.RecordTypeId) +
        ' but vendor program requires ' +
        String.valueOf(expectedRecordTypeId) +
        '; correcting.'
    );
    try {
      update as user new Contract(Id = contractId, RecordTypeId = expectedRecordTypeId);
    } catch (DmlException dex) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.alignContractRecordTypeIfNeeded: update as user failed: ' + dex.getDmlMessage(0)
      );
      Database.update(
        new List<Contract>{ new Contract(Id = contractId, RecordTypeId = expectedRecordTypeId) },
        true,
        AccessLevel.SYSTEM_MODE
      );
    }
    row = [SELECT RecordTypeId FROM Contract WHERE Id = :contractId WITH USER_MODE LIMIT 1];
    if (row.RecordTypeId != expectedRecordTypeId) {
      String msg =
        'Contract ' +
        String.valueOf(contractId) +
        ' record type could not be aligned to the vendor program (' +
        String.valueOf(expectedRecordTypeId) +
        ').';
      appendOutcomeWarning(outcome, msg);
      LoggingUtil.warn('OnboardingNextStepRuleService.alignContractRecordTypeIfNeeded: ' + msg);
    }
  }

  private static Contract buildDraftContract(
    Id accountId,
    Id opportunityId,
    Id principalOwnerId,
    Integer contractTermMonths,
    Id recordTypeId,
    String retailerType
  ) {
    Contract c = new Contract(
      AccountId = accountId,
      Status = 'Draft',
      StartDate = Date.today(),
      ContractTerm = contractTermMonths,
      Principal_Owner__c = principalOwnerId,
      Opportunity_to_Contract__c = opportunityId
    );
    if (recordTypeId != null) {
      c.RecordTypeId = recordTypeId;
      if (String.isNotBlank(retailerType)) {
        c.Retailer_Type__c = retailerType;
      }
    }
    return c;
  }

  private static Id insertDraftContractAsUser(
    Id accountId,
    Id opportunityId,
    Id principalOwnerId,
    Integer contractTermMonths,
    Id recordTypeId,
    String retailerType
  ) {
    Contract c = buildDraftContract(
      accountId,
      opportunityId,
      principalOwnerId,
      contractTermMonths,
      recordTypeId,
      retailerType
    );
    insert as user c;
    return c.Id;
  }

  private static Id insertDraftContractSystemMode(
    Id accountId,
    Id opportunityId,
    Id principalOwnerId,
    Integer contractTermMonths,
    Id recordTypeId,
    String retailerType
  ) {
    Contract c = buildDraftContract(
      accountId,
      opportunityId,
      principalOwnerId,
      contractTermMonths,
      recordTypeId,
      retailerType
    );
    Database.insert(new List<Contract>{ c }, true, AccessLevel.SYSTEM_MODE);
    return c.Id;
  }

  /**
   * Contract.RecordTypeId from Vendor_Customization__c → Contract_Record_Type__c → RecordTypeId__c (text).
   * If the relationship subquery does not hydrate, loads Contract_Record_Type_Reference__c by lookup Id.
   */
  private static VendorProgramContractRtResolve resolveVendorProgramContractRecordType(Id vendorCustomizationId) {
    VendorProgramContractRtResolve out = new VendorProgramContractRtResolve();
    if (vendorCustomizationId == null) {
      return out;
    }
    if (!Schema.SObjectType.Vendor_Customization__c.isAccessible()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.resolveVendorProgramContractRecordType: missing read access to Vendor_Customization__c.'
      );
      return out;
    }
    List<Vendor_Customization__c> rows = [
      SELECT Contract_Record_Type__c, Contract_Record_Type__r.RecordTypeId__c, Retail_Option__c
      FROM Vendor_Customization__c
      WHERE Id = :vendorCustomizationId
      WITH USER_MODE
      LIMIT 1
    ];
    if (rows.isEmpty()) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.resolveVendorProgramContractRecordType: Vendor_Customization__c not found ' +
          String.valueOf(vendorCustomizationId)
      );
      return out;
    }
    Vendor_Customization__c row = rows[0];
    out.retailOption = row.Retail_Option__c;
    out.hasContractRecordTypeLookup = row.Contract_Record_Type__c != null;
    String raw = null;
    if (row.Contract_Record_Type__r != null) {
      raw = row.Contract_Record_Type__r.RecordTypeId__c;
    }
    if (String.isBlank(raw) && row.Contract_Record_Type__c != null) {
      if (!Schema.SObjectType.Contract_Record_Type_Reference__c.isAccessible()) {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService.resolveVendorProgramContractRecordType: missing read access to Contract_Record_Type_Reference__c.'
        );
        return out;
      }
      List<Contract_Record_Type_Reference__c> refs = [
        SELECT RecordTypeId__c
        FROM Contract_Record_Type_Reference__c
        WHERE Id = :row.Contract_Record_Type__c
        WITH USER_MODE
        LIMIT 1
      ];
      if (!refs.isEmpty()) {
        raw = refs[0].RecordTypeId__c;
      }
    }
    if (String.isBlank(raw) && out.hasContractRecordTypeLookup) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.resolveVendorProgramContractRecordType: Vendor_Customization__c ' +
          String.valueOf(vendorCustomizationId) +
          ' has Contract_Record_Type__c=' +
          String.valueOf(row.Contract_Record_Type__c) +
          ' but RecordTypeId__c is blank on the reference.'
      );
    }
    out.recordTypeId = tryParseId(raw);
    if (out.recordTypeId == null && String.isNotBlank(raw)) {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.resolveVendorProgramContractRecordType: could not parse RecordTypeId__c text: ' +
          raw
      );
    }
    return out;
  }

  /**
   * (1) OpportunityContactRole on the opportunity with IsPrimary = true,
   * (2) AccountContactRelation with Roles including Principal Owner.
   */
  private static Id resolvePrincipalOwnerForSiblingContract(Onboarding__c source, ApplyOutcome outcome) {
    if (source.Opportunity__c != null) {
      if (Schema.SObjectType.OpportunityContactRole.isAccessible()) {
        List<OpportunityContactRole> primaryOcr = [
          SELECT ContactId
          FROM OpportunityContactRole
          WHERE OpportunityId = :source.Opportunity__c AND IsPrimary = TRUE
          WITH USER_MODE
          LIMIT 1
        ];
        if (!primaryOcr.isEmpty() && primaryOcr[0].ContactId != null) {
          return primaryOcr[0].ContactId;
        }
      } else {
        LoggingUtil.warn(
          'OnboardingNextStepRuleService.resolvePrincipalOwnerForSiblingContract: missing read access to OpportunityContactRole; skipping primary OCR lookup.'
        );
      }
    }

    String principalOwnerRole = ACR_ROLE_PRINCIPAL_OWNER;
    if (Schema.SObjectType.AccountContactRelation.isAccessible()) {
      List<AccountContactRelation> rels = [
        SELECT ContactId
        FROM AccountContactRelation
        WHERE
          AccountId = :source.Account__c
          AND IsActive = TRUE
          AND Roles INCLUDES (:principalOwnerRole)
        WITH USER_MODE
        LIMIT 1
      ];
      if (!rels.isEmpty()) {
        return rels[0].ContactId;
      }
    } else {
      LoggingUtil.warn(
        'OnboardingNextStepRuleService.resolvePrincipalOwnerForSiblingContract: missing read access to AccountContactRelation; skipping principal-owner relationship lookup.'
      );
    }

    String msg =
      'The linked onboarding and its contract were not created for source Onboarding ' +
      String.valueOf(source.Id) +
      ' because no Primary Responsible Contact was found. Mark a contact as primary on the Opportunity Contact Role for the related Opportunity, ' +
      'or assign the Principal Owner role on an Account Contact Relationship for this account.';
    LoggingUtil.warn('OnboardingNextStepRuleService: ' + msg);
    appendOutcomeWarning(outcome, msg);
    return null;
  }

  private static void appendOutcomeWarning(ApplyOutcome outcome, String msg) {
    if (outcome == null || String.isBlank(msg)) {
      return;
    }
    if (String.isNotBlank(outcome.warningMessage)) {
      outcome.warningMessage += '\n';
    }
    outcome.warningMessage += msg;
  }

  private static Id tryParseId(String raw) {
    if (String.isBlank(raw)) {
      return null;
    }
    String t = raw.trim();
    try {
      return Id.valueOf(t);
    } catch (Exception ignored) {
      try {
        return (Id) t;
      } catch (Exception ignored2) {
        return null;
      }
    }
  }
}
