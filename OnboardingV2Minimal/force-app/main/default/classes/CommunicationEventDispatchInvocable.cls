public with sharing class CommunicationEventDispatchInvocable {

  private static final String DEFAULT_VENDOR_PROGRAM_KEY = 'DEFAULT';
  private static final String DEFAULT_RECIPIENT_TYPE = 'Contact';

  public class DispatchRequest {
    @InvocableVariable(required=true label='Event Key')
    public String eventKey;

    @InvocableVariable(label='Vendor Program Id')
    public Id vendorProgramId;

    @InvocableVariable(
      label='Recipient Type'
      description='Contact, PrincipalOwner, or Agent. Defaults to Contact.'
    )
    public String recipientType;

    @InvocableVariable(
      label='Recipient Ids'
      description='Optional explicit recipient Id list (Contact/User/Lead supported by email target-object rules).'
    )
    public List<String> recipientIds;

    @InvocableVariable(
      label='Account Ids'
      description='Optional Account Id list (001...). Active direct account-contact relationships are expanded into recipients.'
    )
    public List<String> accountIds;

    @InvocableVariable(
      label='Account Contact Role Contains'
      description='Optional role text filter when expanding account recipients (case-insensitive contains).'
    )
    public String accountContactRoleContains;

    @InvocableVariable(
      label='Communication Template Ids'
      description='Optional override list of Communication_Template__c Ids. If omitted, templates are resolved from assignment + communication type.'
    )
    public List<String> communicationTemplateIds;

    @InvocableVariable(
      label='Onboarding Id'
      description='Optional WhatId context for email logging.'
    )
    public Id onboardingId;

    @InvocableVariable(label='Default Sender Address')
    public String defaultSenderAddress;
  }

  public class DispatchResult {
    @InvocableVariable(label='Ran Successfully')
    public Boolean ranSuccessfully;

    @InvocableVariable(label='Diagnostic Message')
    public String diagnosticMessage;

    @InvocableVariable(label='Sent Count')
    public Integer sentCount;

    @InvocableVariable(label='Failed Count')
    public Integer failedCount;

    @InvocableVariable(label='Resolved Recipient Count')
    public Integer resolvedRecipientCount;

    @InvocableVariable(label='Resolved Template Count')
    public Integer resolvedTemplateCount;
  }

  @InvocableMethod(
    label='Dispatch Communication Event (Neutral)'
    description='Object-neutral event dispatch. Resolves event policy + dispatch policy and sends configured templates to explicit/contact-expanded recipients.'
  )
  public static List<DispatchResult> dispatch(List<DispatchRequest> requests) {
    List<DispatchResult> results = new List<DispatchResult>();
    if (requests == null || requests.isEmpty()) {
      return results;
    }

    for (DispatchRequest request : requests) {
      results.add(dispatchOne(request));
    }
    return results;
  }

  private static DispatchResult dispatchOne(DispatchRequest request) {
    DispatchResult result = new DispatchResult();
    result.ranSuccessfully = false;
    result.diagnosticMessage = '';
    result.sentCount = 0;
    result.failedCount = 0;
    result.resolvedRecipientCount = 0;
    result.resolvedTemplateCount = 0;

    if (request == null || String.isBlank(request.eventKey)) {
      result.diagnosticMessage = 'eventKey is required.';
      return result;
    }

    String recipientType = String.isBlank(request.recipientType)
      ? DEFAULT_RECIPIENT_TYPE
      : request.recipientType.trim();
    String vendorProgramKey = resolveVendorProgramKey(request.vendorProgramId);
    String eventKey = request.eventKey.trim();

    Set<Id> recipientIds = resolveRecipients(
      request.recipientIds,
      request.accountIds,
      request.accountContactRoleContains
    );
    if (recipientIds.isEmpty()) {
      result.diagnosticMessage = 'No recipient contacts were resolved from recipientIds/accountIds.';
      return result;
    }
    result.resolvedRecipientCount = recipientIds.size();

    List<Communication_Event_Policy__mdt> eventPolicies = resolveEventPolicies(
      eventKey,
      vendorProgramKey
    );
    if (eventPolicies.isEmpty()) {
      result.diagnosticMessage =
        'No active event policy rows found for eventKey=' +
        eventKey +
        ' (specific/default lookup).';
      return result;
    }

    Set<String> allowedCommunicationTypes = resolveAllowedCommunicationTypes(
      eventPolicies,
      recipientType,
      vendorProgramKey
    );
    if (allowedCommunicationTypes.isEmpty()) {
      result.diagnosticMessage =
        'Event policy rows are present, but dispatch policy blocked all communication types for recipientType=' +
        recipientType +
        '.';
      return result;
    }

    Set<Id> templateIds = resolveTemplates(
      request.vendorProgramId,
      request.communicationTemplateIds,
      allowedCommunicationTypes,
      recipientType
    );
    if (templateIds.isEmpty()) {
      result.diagnosticMessage =
        'No active communication templates resolved (override or assignment lookup).';
      return result;
    }
    result.resolvedTemplateCount = templateIds.size();

    CommunicationTemplateBulkSendAction.BulkSendRequest sendRequest =
      new CommunicationTemplateBulkSendAction.BulkSendRequest();
    sendRequest.communicationTemplateIds = new List<String>();
    sendRequest.recipientIds = new List<String>();
    sendRequest.onboardingIds = new List<String>();
    sendRequest.defaultSenderAddress = request.defaultSenderAddress;

    for (Id templateId : templateIds) {
      for (Id recipientId : recipientIds) {
        sendRequest.communicationTemplateIds.add((String) templateId);
        sendRequest.recipientIds.add((String) recipientId);
        if (request.onboardingId != null) {
          sendRequest.onboardingIds.add((String) request.onboardingId);
        }
      }
    }

    List<CommunicationTemplateBulkSendAction.BulkSendResult> sendResults =
      CommunicationTemplateBulkSendAction.sendBulk(
        new List<CommunicationTemplateBulkSendAction.BulkSendRequest>{ sendRequest }
      );
    if (!sendResults.isEmpty()) {
      CommunicationTemplateBulkSendAction.BulkSendResult sendResult = sendResults[0];
      result.sentCount = sendResult.sentCount == null ? 0 : sendResult.sentCount;
      result.failedCount = sendResult.failedCount == null ? 0 : sendResult.failedCount;
      result.ranSuccessfully = sendResult.sendFailed == null ? true : !sendResult.sendFailed;
      result.diagnosticMessage = sendResult.errorMessage;
    } else {
      result.diagnosticMessage = 'Bulk send returned no result.';
    }

    if (!result.ranSuccessfully && !String.isBlank(result.diagnosticMessage)) {
      LoggingUtil.warn(
        'CommunicationEventDispatchInvocable.dispatchOne failed for eventKey=' +
          eventKey +
          ': ' +
          result.diagnosticMessage
      );
    }

    return result;
  }

  private static Set<Id> resolveRecipients(
    List<String> explicitRecipientIdsRaw,
    List<String> accountIdsRaw,
    String accountContactRoleContains
  ) {
    Set<Id> recipientIds = parseIds(explicitRecipientIdsRaw, null);
    Set<Id> accountIds = parseIds(accountIdsRaw, '001');
    if (accountIds.isEmpty()) {
      return recipientIds;
    }

    String roleFilter = String.isBlank(accountContactRoleContains)
      ? null
      : accountContactRoleContains.trim().toLowerCase();
    for (AccountContactRelation relationship : [
      SELECT AccountId, ContactId, Roles
      FROM AccountContactRelation
      WHERE AccountId IN :accountIds
        AND IsActive = true
        AND IsDirect = true
        AND ContactId != null
    ]) {
      if (roleFilter != null) {
        String relationshipRoles = relationship.Roles == null
          ? ''
          : relationship.Roles.toLowerCase();
        if (!relationshipRoles.contains(roleFilter)) {
          continue;
        }
      }
      recipientIds.add(relationship.ContactId);
    }
    return recipientIds;
  }

  private static String resolveVendorProgramKey(Id vendorProgramId) {
    if (vendorProgramId == null) {
      return '';
    }
    List<Vendor_Customization__c> rows = [
      SELECT Name
      FROM Vendor_Customization__c
      WHERE Id = :vendorProgramId
      LIMIT 1
    ];
    if (rows.isEmpty() || String.isBlank(rows[0].Name)) {
      return '';
    }
    return normalizeVendorProgramKey(rows[0].Name);
  }

  private static String normalizeVendorProgramKey(String nameValue) {
    if (String.isBlank(nameValue)) {
      return '';
    }
    return nameValue.trim().toUpperCase().replace(' ', '_');
  }

  private static List<Communication_Event_Policy__mdt> resolveEventPolicies(
    String eventKey,
    String vendorProgramKey
  ) {
    if (String.isBlank(eventKey)) {
      return new List<Communication_Event_Policy__mdt>();
    }

    if (!String.isBlank(vendorProgramKey)) {
      List<Communication_Event_Policy__mdt> specificPolicies = [
        SELECT Event_Key__c, Communication_Type__c, Dispatch_Order__c, Send_Enabled__c
        FROM Communication_Event_Policy__mdt
        WHERE Active__c = true
          AND Event_Key__c = :eventKey
          AND Vendor_Program_Key__c = :vendorProgramKey
        ORDER BY Dispatch_Order__c ASC
      ];
      if (!specificPolicies.isEmpty()) {
        return specificPolicies;
      }
    }

    return [
      SELECT Event_Key__c, Communication_Type__c, Dispatch_Order__c, Send_Enabled__c
      FROM Communication_Event_Policy__mdt
      WHERE Active__c = true
        AND Event_Key__c = :eventKey
        AND Vendor_Program_Key__c = :DEFAULT_VENDOR_PROGRAM_KEY
      ORDER BY Dispatch_Order__c ASC
    ];
  }

  private static Set<String> resolveAllowedCommunicationTypes(
    List<Communication_Event_Policy__mdt> eventPolicies,
    String recipientType,
    String vendorProgramKey
  ) {
    Set<String> candidateTypes = new Set<String>();
    for (Communication_Event_Policy__mdt policy : eventPolicies) {
      if (policy.Send_Enabled__c != true || String.isBlank(policy.Communication_Type__c)) {
        continue;
      }
      candidateTypes.add(policy.Communication_Type__c);
    }
    if (candidateTypes.isEmpty()) {
      return new Set<String>();
    }

    Map<String, Boolean> dispatchByType = resolveDispatchEnabledByType(
      candidateTypes,
      recipientType,
      vendorProgramKey
    );
    Set<String> allowedTypes = new Set<String>();
    for (String communicationType : candidateTypes) {
      if (dispatchByType.get(communicationType) == true) {
        allowedTypes.add(communicationType);
      }
    }
    return allowedTypes;
  }

  private static Map<String, Boolean> resolveDispatchEnabledByType(
    Set<String> communicationTypes,
    String recipientType,
    String vendorProgramKey
  ) {
    Map<String, Boolean> dispatchByType = new Map<String, Boolean>();
    if (communicationTypes.isEmpty() || String.isBlank(recipientType)) {
      return dispatchByType;
    }

    if (!String.isBlank(vendorProgramKey)) {
      for (Communication_Dispatch_Policy__mdt specificPolicy : [
        SELECT Communication_Type__c, Send_Enabled__c
        FROM Communication_Dispatch_Policy__mdt
        WHERE Active__c = true
          AND Vendor_Program_Key__c = :vendorProgramKey
          AND Recipient_Type__c = :recipientType
          AND Communication_Type__c IN :communicationTypes
      ]) {
        dispatchByType.put(specificPolicy.Communication_Type__c, specificPolicy.Send_Enabled__c);
      }
    }

    Set<String> unresolvedTypes = new Set<String>(communicationTypes);
    unresolvedTypes.removeAll(dispatchByType.keySet());
    if (!unresolvedTypes.isEmpty()) {
      for (Communication_Dispatch_Policy__mdt defaultPolicy : [
        SELECT Communication_Type__c, Send_Enabled__c
        FROM Communication_Dispatch_Policy__mdt
        WHERE Active__c = true
          AND Vendor_Program_Key__c = :DEFAULT_VENDOR_PROGRAM_KEY
          AND Recipient_Type__c = :recipientType
          AND Communication_Type__c IN :unresolvedTypes
      ]) {
        dispatchByType.put(defaultPolicy.Communication_Type__c, defaultPolicy.Send_Enabled__c);
      }
    }
    return dispatchByType;
  }

  private static Set<Id> resolveTemplates(
    Id vendorProgramId,
    List<String> explicitTemplateIdsRaw,
    Set<String> communicationTypes,
    String recipientType
  ) {
    Set<Id> explicitTemplateIds = parseIds(explicitTemplateIdsRaw, null);
    if (!explicitTemplateIds.isEmpty()) {
      return explicitTemplateIds;
    }

    if (vendorProgramId == null || communicationTypes.isEmpty()) {
      return new Set<Id>();
    }

    Set<Id> assignedTemplateIds = new Set<Id>();
    for (Communication_Template_Assignment__c assignmentRow : [
      SELECT Communication_Template__c
      FROM Communication_Template_Assignment__c
      WHERE Vendor_Program__c = :vendorProgramId
        AND Active__c = true
    ]) {
      if (assignmentRow.Communication_Template__c != null) {
        assignedTemplateIds.add(assignmentRow.Communication_Template__c);
      }
    }
    if (assignedTemplateIds.isEmpty()) {
      return new Set<Id>();
    }

    Set<Id> templateIds = new Set<Id>();
    if (!String.isBlank(recipientType)) {
      for (Communication_Template__c templateRow : [
        SELECT Id
        FROM Communication_Template__c
        WHERE Id IN :assignedTemplateIds
          AND Active__c = true
          AND Communication_Type__c IN :communicationTypes
          AND Recipient_Type__c = :recipientType
      ]) {
        templateIds.add(templateRow.Id);
      }
    }

    if (!templateIds.isEmpty() || String.isBlank(recipientType)) {
      return templateIds;
    }

    for (Communication_Template__c templateRow : [
      SELECT Id
      FROM Communication_Template__c
      WHERE Id IN :assignedTemplateIds
        AND Active__c = true
        AND Communication_Type__c IN :communicationTypes
    ]) {
      templateIds.add(templateRow.Id);
    }
    return templateIds;
  }

  private static Set<Id> parseIds(List<String> rawValues, String expectedPrefix) {
    Set<Id> parsed = new Set<Id>();
    if (rawValues == null || rawValues.isEmpty()) {
      return parsed;
    }

    for (String rawValue : rawValues) {
      if (String.isBlank(rawValue)) {
        continue;
      }
      String trimmedValue = rawValue.trim();
      Id parsedId;
      try {
        parsedId = (Id) trimmedValue;
      } catch (Exception ex) {
        continue;
      }
      if (!String.isBlank(expectedPrefix) && !String.valueOf(parsedId).startsWith(expectedPrefix)) {
        continue;
      }
      parsed.add(parsedId);
    }
    return parsed;
  }
}
