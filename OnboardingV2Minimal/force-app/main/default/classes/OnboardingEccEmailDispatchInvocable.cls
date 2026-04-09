public with sharing class OnboardingEccEmailDispatchInvocable {
  private static final Integer MAX_ERROR_MESSAGE_LENGTH = 3000;

  private static final String TOKEN_ECC_SUMMARY = '{{ECC_SUMMARY}}';
  private static final String TOKEN_ECC_TABLE = '{{ECC_TABLE}}';
  private static final String TOKEN_ECC_ROWS = '{{ECC_ROWS}}';
  private static final String TOKEN_ECC_TYPE_VALUE_TABLE = '{{ECC_TYPE_VALUE_TABLE}}';
  private static final String TOKEN_ECC_TYPE_VALUE_ROWS = '{{ECC_TYPE_VALUE_ROWS}}';
  private static final String TOKEN_ECC_REQUIRED_TOTAL = '{{ECC_REQUIRED_TOTAL}}';
  private static final String TOKEN_ECC_COMPLETE_TOTAL = '{{ECC_COMPLETE_TOTAL}}';
  private static final String TOKEN_ECC_MISSING_TOTAL = '{{ECC_MISSING_TOTAL}}';
  private static final String TOKEN_ECC_VALUE_PREFIX = '{{ECC_VALUE:';
  private static final String TOKEN_ECC_TYPE_VALUE_PREFIX = '{{ECC_TYPE_VALUE:';
  private static final String TOKEN_PART_SEPARATOR = '|';

  private static final Map<String, String> ALLOWED_DYNAMIC_FIELD_BY_KEY = new Map<String, String>{
    'poe_username__c' => 'POE_Username__c',
    'poe_n_number__c' => 'POE_N_Number__c',
    'poe_code__c' => 'POE_Code__c',
    'poe_process_status__c' => 'POE_Process_Status__c',
    'training_sent_date__c' => 'Training_Sent_Date__c',
    'activation_date__c' => 'Activation_Date__c',
    'poe_program__c' => 'POE_Program__c'
  };

  private static final Set<String> COMPLETE_STATUSES = new Set<String>{
    'complete',
    'completed',
    'setup complete',
    'active'
  };

  public class DispatchRequest {
    @InvocableVariable(label='Onboarding Id')
    public Id onboardingId;

    @InvocableVariable(label='Vendor Program Id')
    public Id vendorProgramId;

    @InvocableVariable(required=true label='Recipient Contact Id')
    public Id recipientContactId;

    @InvocableVariable(required=true label='Communication Template Id')
    public Id communicationTemplateId;

    @InvocableVariable(label='Default Sender Address')
    public String defaultSenderAddress;

    @InvocableVariable(
      label='Append ECC Payload When Tokens Missing'
      description='Defaults to true. When no ECC placeholder tokens are present in template output, appends ECC details to the email body.'
    )
    public Boolean appendPayloadWhenTokensMissing;
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

    @InvocableVariable(label='Onboarding Id')
    public Id onboardingId;

    @InvocableVariable(label='Vendor Program Id')
    public Id vendorProgramId;

    @InvocableVariable(label='Recipient Contact Id')
    public Id recipientContactId;
  }

  private class RequiredTypeInfo {
    public Id typeId;
    public String typeName;
    public String typeUniqueKey;

    public RequiredTypeInfo(Id typeId, String typeName, String typeUniqueKey) {
      this.typeId = typeId;
      this.typeName = typeName;
      this.typeUniqueKey = typeUniqueKey;
    }
  }

  private class DynamicTokenSpec {
    public String typeLookupKey;
    public String fieldApiName;
  }

  private class SelectedCredential {
    public POE_External_Contact_Credential__c record;
    public Integer score;

    public SelectedCredential(POE_External_Contact_Credential__c record, Integer score) {
      this.record = record;
      this.score = score;
    }
  }

  private class EccPayload {
    public String summary;
    public String htmlTable;
    public String textRows;
    public String typeValueHtmlTable;
    public String typeValueTextRows;
    public Integer requiredTotal;
    public Integer completeTotal;
    public Integer missingTotal;
    public Map<String, String> valueByTypeNameNormalized = new Map<String, String>();
    public Map<String, String> typeDisplayByTypeNameNormalized = new Map<String, String>();
    public Map<String, POE_External_Contact_Credential__c> recordByTypeNameNormalized =
      new Map<String, POE_External_Contact_Credential__c>();
  }

  @InvocableMethod(
    label='Dispatch ECC Email (Per Contact)'
    description='Renders a Salesforce Email Template, injects ECC payload tokens, and sends one personalized email per request.'
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
    result.sentCount = 0;
    result.failedCount = 0;
    result.diagnosticMessage = '';

    if (request == null) {
      fail(result, 'Request is required.');
      return result;
    }
    result.onboardingId = request.onboardingId;
    result.vendorProgramId = request.vendorProgramId;
    result.recipientContactId = request.recipientContactId;

    if (request.recipientContactId == null) {
      fail(result, 'recipientContactId is required.');
      return result;
    }
    if (request.communicationTemplateId == null) {
      fail(result, 'communicationTemplateId is required.');
      return result;
    }
    if (request.onboardingId == null && request.vendorProgramId == null) {
      fail(result, 'Either onboardingId or vendorProgramId is required.');
      return result;
    }

    try {
      Onboarding__c onboarding;
      if (request.onboardingId != null) {
        onboarding = loadOnboarding(request.onboardingId);
        if (onboarding == null) {
          fail(result, 'Onboarding record not found or not accessible.');
          return result;
        }
      }

      Contact recipient = loadContact(request.recipientContactId);
      if (recipient == null) {
        fail(result, 'Recipient contact not found or not accessible.');
        return result;
      }
      if (String.isBlank(recipient.Email)) {
        fail(result, 'Recipient contact has no email address.');
        return result;
      }

      Communication_Template__c communicationTemplate = loadCommunicationTemplate(
        request.communicationTemplateId
      );
      if (communicationTemplate == null) {
        fail(result, 'Communication template not found or not accessible.');
        return result;
      }
      if (communicationTemplate.Active__c != true) {
        fail(result, 'Communication template is inactive.');
        return result;
      }
      if (String.isBlank(communicationTemplate.Email_Template_Id__c)) {
        fail(result, 'Communication template is missing Email_Template_Id__c.');
        return result;
      }

      Id emailTemplateId = tryParseId(communicationTemplate.Email_Template_Id__c);
      if (emailTemplateId == null) {
        fail(result, 'Communication template Email_Template_Id__c is not a valid Id.');
        return result;
      }

      Id vendorProgramId = request.vendorProgramId;
      if (vendorProgramId == null && onboarding != null) {
        vendorProgramId = onboarding.Vendor_Customization__c;
      }
      if (vendorProgramId == null) {
        fail(result, 'Unable to determine vendor program context. Provide vendorProgramId or onboarding with Vendor_Customization__c.');
        return result;
      }
      result.vendorProgramId = vendorProgramId;

      Vendor_Customization__c vendorProgram = loadVendorProgram(vendorProgramId);
      if (vendorProgram == null) {
        fail(result, 'Vendor program not found or not accessible.');
        return result;
      }

      EccPayload payload = buildEccPayload(vendorProgram, recipient.Id);

      Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(
        emailTemplateId,
        recipient.Id,
        onboarding == null ? null : onboarding.Id
      );

      String subject = rendered == null ? null : rendered.getSubject();
      String htmlBody = rendered == null ? null : rendered.getHtmlBody();
      String plainTextBody = rendered == null ? null : rendered.getPlainTextBody();

      Boolean appendWhenMissing = request.appendPayloadWhenTokensMissing == null
        ? true
        : request.appendPayloadWhenTokensMissing;
      Boolean hadTokens = containsToken(subject) || containsToken(htmlBody) || containsToken(plainTextBody);

      subject = replaceTokens(subject, payload, false);
      htmlBody = replaceTokens(htmlBody, payload, true);
      plainTextBody = replaceTokens(plainTextBody, payload, false);

      if (appendWhenMissing && !hadTokens) {
        if (String.isNotBlank(htmlBody)) {
          htmlBody += '<br/><br/>' + escapeHtml(payload.summary) + '<br/>' + payload.htmlTable;
        }
        if (String.isNotBlank(plainTextBody)) {
          plainTextBody += '\n\n' + payload.summary + '\n' + payload.textRows;
        }
      }

      if (String.isBlank(htmlBody) && String.isBlank(plainTextBody)) {
        plainTextBody = payload.summary + '\n' + payload.textRows;
      }

      Messaging.SingleEmailMessage outbound = new Messaging.SingleEmailMessage();
      if (String.isNotBlank(subject)) {
        outbound.setSubject(subject);
      }
      if (String.isNotBlank(htmlBody)) {
        outbound.setHtmlBody(htmlBody);
      }
      if (String.isNotBlank(plainTextBody)) {
        outbound.setPlainTextBody(plainTextBody);
      }
      outbound.setTargetObjectId(recipient.Id);
      outbound.setTreatTargetObjectAsRecipient(true);
      outbound.setSaveAsActivity(true);
      if (onboarding != null) {
        outbound.setWhatId(onboarding.Id);
      }

      if (String.isNotBlank(request.defaultSenderAddress)) {
        Id orgWideEmailAddressId = resolveOrgWideEmailAddressId(request.defaultSenderAddress);
        if (orgWideEmailAddressId != null) {
          outbound.setOrgWideEmailAddressId(orgWideEmailAddressId);
        }
      }

      Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ outbound },
        false
      );
      if (sendResults.isEmpty()) {
        fail(result, 'sendEmail returned no result.');
        return result;
      }

      Messaging.SendEmailResult sendResult = sendResults[0];
      if (sendResult.isSuccess()) {
        result.ranSuccessfully = true;
        result.sentCount = 1;
        return result;
      }

      result.failedCount = 1;
      fail(result, formatSendErrors(sendResult));
      return result;
    } catch (Exception ex) {
      fail(result, 'ECC email dispatch failed: ' + ex.getMessage());
      return result;
    }
  }

  private static Onboarding__c loadOnboarding(Id onboardingId) {
    List<Onboarding__c> rows = [
      SELECT Id, Vendor_Customization__c, Vendor_Customization__r.Name, Vendor_Customization__r.Label__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      WITH USER_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static Vendor_Customization__c loadVendorProgram(Id vendorProgramId) {
    List<Vendor_Customization__c> rows = [
      SELECT Id, Name, Label__c
      FROM Vendor_Customization__c
      WHERE Id = :vendorProgramId
      WITH USER_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static Contact loadContact(Id contactId) {
    List<Contact> rows = [
      SELECT Id, Email
      FROM Contact
      WHERE Id = :contactId
      WITH USER_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static Communication_Template__c loadCommunicationTemplate(Id communicationTemplateId) {
    List<Communication_Template__c> rows = [
      SELECT Id, Active__c, Email_Template_Id__c
      FROM Communication_Template__c
      WHERE Id = :communicationTemplateId
      WITH USER_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static EccPayload buildEccPayload(Vendor_Customization__c vendorProgram, Id contactId) {
    Id vendorProgramId = vendorProgram == null ? null : vendorProgram.Id;
    Set<Id> requiredTypeIds = new Set<Id>();
    List<RequiredTypeInfo> requiredTypesOrdered = new List<RequiredTypeInfo>();
    Set<Id> seenRequiredTypeIds = new Set<Id>();

    if (vendorProgramId != null) {
      for (Required_Credential__c requiredCredential : [
        SELECT
          External_Contact_Credential_Type__c,
          External_Contact_Credential_Type__r.Name,
          External_Contact_Credential_Type__r.Unique_Key__c
        FROM Required_Credential__c
        WHERE Vendor_Customization__c = :vendorProgramId
          AND Is_Required__c = true
          AND External_Contact_Credential_Type__c != null
        ORDER BY Sequence__c ASC, External_Contact_Credential_Type__r.Name ASC
      ]) {
        Id typeId = requiredCredential.External_Contact_Credential_Type__c;
        if (typeId == null || seenRequiredTypeIds.contains(typeId)) {
          continue;
        }
        seenRequiredTypeIds.add(typeId);
        requiredTypeIds.add(typeId);
        requiredTypesOrdered.add(
          new RequiredTypeInfo(
            typeId,
            requiredCredential.External_Contact_Credential_Type__r == null
              ? null
              : requiredCredential.External_Contact_Credential_Type__r.Name,
            requiredCredential.External_Contact_Credential_Type__r == null
              ? null
              : requiredCredential.External_Contact_Credential_Type__r.Unique_Key__c
          )
        );
      }
    }

    Map<Id, SelectedCredential> selectedByTypeId = new Map<Id, SelectedCredential>();

    if (!requiredTypeIds.isEmpty() && contactId != null) {
      for (POE_External_Contact_Credential__c credential : [
        SELECT
          Id,
          External_Contact_Credential_Type__c,
          POE_Process_Status__c,
          POE_Username__c,
          POE_N_Number__c,
          POE_Code__c,
          Training_Sent_Date__c,
          Activation_Date__c,
          POE_Program__c,
          Vendor_Program__c,
          CreatedDate
        FROM POE_External_Contact_Credential__c
        WHERE POE_Contact__c = :contactId
          AND Vendor_Program__c = :vendorProgramId
        ORDER BY CreatedDate DESC
      ]) {
        Id typeId = credential.External_Contact_Credential_Type__c;
        if (typeId == null || !requiredTypeIds.contains(typeId)) {
          continue;
        }

        Integer score = credential.Vendor_Program__c == vendorProgramId ? 3 : 1;
        SelectedCredential current = selectedByTypeId.get(typeId);
        if (current == null || score > current.score) {
          selectedByTypeId.put(typeId, new SelectedCredential(credential, score));
        }
      }
    }

    EccPayload payload = new EccPayload();
    payload.requiredTotal = requiredTypesOrdered.size();
    payload.completeTotal = 0;
    payload.missingTotal = 0;

    List<String> textLines = new List<String>();
    List<String> htmlRows = new List<String>();
    List<String> typeValueTextLines = new List<String>();
    List<String> typeValueHtmlRows = new List<String>();

    for (RequiredTypeInfo requiredType : requiredTypesOrdered) {
      SelectedCredential selected = selectedByTypeId.get(requiredType.typeId);
      POE_External_Contact_Credential__c record = selected == null ? null : selected.record;

      String typeName = String.isBlank(requiredType.typeName) ? 'Unknown Type' : requiredType.typeName;
      String statusValue = record == null || String.isBlank(record.POE_Process_Status__c)
        ? 'Missing'
        : record.POE_Process_Status__c;

      if (record == null) {
        payload.missingTotal++;
      } else if (isCompleteStatus(statusValue)) {
        payload.completeTotal++;
      }

      String usernameValue = record == null ? null : record.POE_Username__c;
      String nNumberValue = record == null ? null : record.POE_N_Number__c;
      String codeValue = record == null ? null : record.POE_Code__c;
      String trainingSentDateValue = record == null || record.Training_Sent_Date__c == null
        ? null
        : String.valueOf(record.Training_Sent_Date__c);
      String activationDateValue = record == null || record.Activation_Date__c == null
        ? null
        : String.valueOf(record.Activation_Date__c);
      String programValue = record == null
        ? null
        : deriveProgramDisplayValue(record);
      String resolvedTypeValue = resolveTypeValue(record);
      if (String.isBlank(resolvedTypeValue)) {
        resolvedTypeValue = 'Missing';
      }
      Set<String> lookupKeys = buildLookupKeys(requiredType.typeId, typeName, requiredType.typeUniqueKey);
      for (String lookupKey : lookupKeys) {
        payload.valueByTypeNameNormalized.put(lookupKey, resolvedTypeValue);
        payload.typeDisplayByTypeNameNormalized.put(lookupKey, typeName);
        payload.recordByTypeNameNormalized.put(lookupKey, record);
      }

      textLines.add(
        '- ' + typeName +
          ': ' + statusValue +
          optionalPair('Username', usernameValue) +
          optionalPair('N#', nNumberValue) +
          optionalPair('Code', codeValue) +
          optionalPair('Training Sent', trainingSentDateValue) +
          optionalPair('Activation', activationDateValue) +
          optionalPair('Program', programValue)
      );

      htmlRows.add(
        '<tr>' +
          '<td>' + escapeHtml(typeName) + '</td>' +
          '<td>' + escapeHtml(statusValue) + '</td>' +
          '<td>' + escapeHtml(blankToDash(usernameValue)) + '</td>' +
          '<td>' + escapeHtml(blankToDash(nNumberValue)) + '</td>' +
          '<td>' + escapeHtml(blankToDash(codeValue)) + '</td>' +
          '<td>' + escapeHtml(blankToDash(trainingSentDateValue)) + '</td>' +
          '<td>' + escapeHtml(blankToDash(activationDateValue)) + '</td>' +
          '<td>' + escapeHtml(blankToDash(programValue)) + '</td>' +
          '</tr>'
      );

      typeValueTextLines.add('- ' + typeName + ': ' + resolvedTypeValue);
      typeValueHtmlRows.add(
        '<tr>' +
          '<td>' + escapeHtml(typeName) + '</td>' +
          '<td>' + escapeHtml(blankToDash(resolvedTypeValue)) + '</td>' +
        '</tr>'
      );
    }

    Integer pendingTotal = payload.requiredTotal - payload.completeTotal;
    payload.summary =
      'Required credentials: ' + payload.requiredTotal +
      ' | Complete: ' + payload.completeTotal +
      ' | Pending/Missing: ' + pendingTotal;

    if (payload.requiredTotal == 0) {
      payload.textRows = 'No required credential types were found for this vendor program.';
      payload.htmlTable =
        '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;">' +
          '<tbody><tr><td>No required credential types were found for this vendor program.</td></tr></tbody>' +
        '</table>';
      payload.typeValueTextRows = 'No required credential types were found for this vendor program.';
      payload.typeValueHtmlTable =
        '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;">' +
          '<tbody><tr><td>No required credential types were found for this vendor program.</td></tr></tbody>' +
        '</table>';
      return payload;
    }

    payload.textRows = String.join(textLines, '\n');
    payload.htmlTable =
      '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;">' +
        '<thead>' +
          '<tr>' +
            '<th>Credential Type</th>' +
            '<th>Status</th>' +
            '<th>Username</th>' +
            '<th>N#</th>' +
            '<th>Code</th>' +
            '<th>Training Sent</th>' +
            '<th>Activation</th>' +
            '<th>Program</th>' +
          '</tr>' +
        '</thead>' +
        '<tbody>' + String.join(htmlRows, '') + '</tbody>' +
      '</table>';
    payload.typeValueTextRows = String.join(typeValueTextLines, '\n');
    payload.typeValueHtmlTable =
      '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;">' +
        '<thead>' +
          '<tr>' +
            '<th>Credential Type</th>' +
            '<th>Value</th>' +
          '</tr>' +
        '</thead>' +
        '<tbody>' + String.join(typeValueHtmlRows, '') + '</tbody>' +
      '</table>';

    return payload;
  }

  @TestVisible
  private static Map<String, String> buildTokenMapForTest(Id onboardingId, Id contactId) {
    Onboarding__c onboarding = loadOnboarding(onboardingId);
    Vendor_Customization__c vendorProgram = onboarding == null || onboarding.Vendor_Customization__c == null
      ? null
      : loadVendorProgram(onboarding.Vendor_Customization__c);
    EccPayload payload = buildEccPayload(vendorProgram, contactId);
    Map<String, String> tokenMap = new Map<String, String>();
    tokenMap.put(TOKEN_ECC_SUMMARY, payload.summary);
    tokenMap.put(TOKEN_ECC_TABLE, payload.htmlTable);
    tokenMap.put(TOKEN_ECC_ROWS, payload.textRows);
    tokenMap.put(TOKEN_ECC_TYPE_VALUE_TABLE, payload.typeValueHtmlTable);
    tokenMap.put(TOKEN_ECC_TYPE_VALUE_ROWS, payload.typeValueTextRows);
    tokenMap.put(TOKEN_ECC_REQUIRED_TOTAL, String.valueOf(payload.requiredTotal));
    tokenMap.put(TOKEN_ECC_COMPLETE_TOTAL, String.valueOf(payload.completeTotal));
    tokenMap.put(TOKEN_ECC_MISSING_TOTAL, String.valueOf(payload.missingTotal));
    return tokenMap;
  }

  private static String deriveProgramDisplayValue(POE_External_Contact_Credential__c credential) {
    if (credential == null) {
      return null;
    }
    return credential.POE_Program__c;
  }

  @TestVisible
  private static String renderTemplateForTest(String content, Id onboardingId, Id contactId, Boolean isHtml) {
    Onboarding__c onboarding = loadOnboarding(onboardingId);
    Vendor_Customization__c vendorProgram = onboarding == null || onboarding.Vendor_Customization__c == null
      ? null
      : loadVendorProgram(onboarding.Vendor_Customization__c);
    EccPayload payload = buildEccPayload(vendorProgram, contactId);
    return replaceTokens(content, payload, isHtml);
  }

  private static String replaceTokens(String content, EccPayload payload, Boolean isHtml) {
    if (content == null) {
      return null;
    }

    String replaced = content;
    replaced = replaced.replace(TOKEN_ECC_SUMMARY, payload.summary);
    replaced = replaced.replace(TOKEN_ECC_REQUIRED_TOTAL, String.valueOf(payload.requiredTotal));
    replaced = replaced.replace(TOKEN_ECC_COMPLETE_TOTAL, String.valueOf(payload.completeTotal));
    replaced = replaced.replace(TOKEN_ECC_MISSING_TOTAL, String.valueOf(payload.missingTotal));
    replaced = replaced.replace(
      TOKEN_ECC_TYPE_VALUE_TABLE,
      isHtml ? payload.typeValueHtmlTable : payload.typeValueTextRows
    );
    replaced = replaced.replace(TOKEN_ECC_TYPE_VALUE_ROWS, payload.typeValueTextRows);

    String tableOrRows = isHtml ? payload.htmlTable : payload.textRows;
    replaced = replaced.replace(TOKEN_ECC_TABLE, tableOrRows);
    replaced = replaced.replace(TOKEN_ECC_ROWS, payload.textRows);
    replaced = replaceDynamicTypeTokens(replaced, payload, isHtml, TOKEN_ECC_VALUE_PREFIX, false);
    replaced = replaceDynamicTypeTokens(replaced, payload, isHtml, TOKEN_ECC_TYPE_VALUE_PREFIX, true);
    return replaced;
  }

  private static String replaceDynamicTypeTokens(
    String content,
    EccPayload payload,
    Boolean isHtml,
    String tokenPrefix,
    Boolean includeTypeName
  ) {
    if (String.isBlank(content) || payload == null || String.isBlank(tokenPrefix)) {
      return content;
    }

    String replaced = content;
    Integer tokenStart = replaced.indexOf(tokenPrefix);
    while (tokenStart >= 0) {
      Integer tokenValueStart = tokenStart + tokenPrefix.length();
      Integer tokenEnd = replaced.indexOf('}}', tokenValueStart);
      if (tokenEnd < 0) {
        break;
      }

      String typeNameFromToken = replaced.substring(tokenValueStart, tokenEnd);
      DynamicTokenSpec tokenSpec = parseDynamicTokenSpec(typeNameFromToken);
      String normalizedTypeName = normalize(tokenSpec.typeLookupKey);
      String displayTypeName = payload.typeDisplayByTypeNameNormalized.containsKey(normalizedTypeName)
        ? payload.typeDisplayByTypeNameNormalized.get(normalizedTypeName)
        : tokenSpec.typeLookupKey;
      String resolvedValue;
      if (String.isBlank(tokenSpec.fieldApiName)) {
        resolvedValue = payload.valueByTypeNameNormalized.containsKey(normalizedTypeName)
          ? payload.valueByTypeNameNormalized.get(normalizedTypeName)
          : 'Missing';
      } else {
        POE_External_Contact_Credential__c record = payload.recordByTypeNameNormalized.containsKey(normalizedTypeName)
          ? payload.recordByTypeNameNormalized.get(normalizedTypeName)
          : null;
        resolvedValue = resolveFieldValue(record, tokenSpec.fieldApiName);
      }
      if (String.isBlank(resolvedValue)) {
        resolvedValue = 'Missing';
      }

      String replacement = includeTypeName
        ? displayTypeName + ': ' + resolvedValue
        : resolvedValue;
      if (isHtml) {
        replacement = escapeHtml(replacement);
      }

      replaced =
        replaced.substring(0, tokenStart) +
        replacement +
        replaced.substring(tokenEnd + 2);
      tokenStart = replaced.indexOf(tokenPrefix, tokenStart + replacement.length());
    }
    return replaced;
  }

  private static Boolean containsToken(String value) {
    if (String.isBlank(value)) {
      return false;
    }
    return value.contains(TOKEN_ECC_SUMMARY) ||
      value.contains(TOKEN_ECC_TABLE) ||
      value.contains(TOKEN_ECC_ROWS) ||
      value.contains(TOKEN_ECC_TYPE_VALUE_TABLE) ||
      value.contains(TOKEN_ECC_TYPE_VALUE_ROWS) ||
      value.contains(TOKEN_ECC_REQUIRED_TOTAL) ||
      value.contains(TOKEN_ECC_COMPLETE_TOTAL) ||
      value.contains(TOKEN_ECC_MISSING_TOTAL) ||
      value.contains(TOKEN_ECC_VALUE_PREFIX) ||
      value.contains(TOKEN_ECC_TYPE_VALUE_PREFIX);
  }

  private static Boolean isCompleteStatus(String statusValue) {
    return COMPLETE_STATUSES.contains(normalize(statusValue));
  }

  private static String optionalPair(String label, String value) {
    if (String.isBlank(value)) {
      return '';
    }
    return ' | ' + label + ': ' + value;
  }

  private static String blankToDash(String value) {
    return String.isBlank(value) ? '-' : value;
  }

  private static String resolveTypeValue(POE_External_Contact_Credential__c record) {
    if (record == null) {
      return null;
    }
    if (String.isNotBlank(record.POE_Username__c)) {
      return record.POE_Username__c;
    }
    if (String.isNotBlank(record.POE_N_Number__c)) {
      return record.POE_N_Number__c;
    }
    if (String.isNotBlank(record.POE_Code__c)) {
      return record.POE_Code__c;
    }
    return null;
  }

  private static String resolveFieldValue(
    POE_External_Contact_Credential__c record,
    String requestedFieldApiName
  ) {
    if (record == null) {
      return 'Missing';
    }
    String normalizedRequestedField = normalize(requestedFieldApiName);
    String canonicalFieldApiName = ALLOWED_DYNAMIC_FIELD_BY_KEY.get(normalizedRequestedField);
    if (String.isBlank(canonicalFieldApiName)) {
      return 'Missing';
    }

    try {
      Object rawValue = record.get(canonicalFieldApiName);
      return rawValue == null ? 'Missing' : String.valueOf(rawValue);
    } catch (Exception ignored) {
      return 'Missing';
    }
  }

  private static DynamicTokenSpec parseDynamicTokenSpec(String tokenValue) {
    DynamicTokenSpec spec = new DynamicTokenSpec();
    spec.typeLookupKey = tokenValue;
    spec.fieldApiName = null;

    if (String.isBlank(tokenValue)) {
      spec.typeLookupKey = '';
      return spec;
    }

    Integer separatorIndex = tokenValue.lastIndexOf(TOKEN_PART_SEPARATOR);
    if (separatorIndex < 0) {
      spec.typeLookupKey = tokenValue.trim();
      return spec;
    }

    String rawFieldApiName = tokenValue.substring(separatorIndex + TOKEN_PART_SEPARATOR.length());
    String normalizedFieldApiName = normalize(rawFieldApiName);
    if (!ALLOWED_DYNAMIC_FIELD_BY_KEY.containsKey(normalizedFieldApiName)) {
      spec.typeLookupKey = tokenValue.trim();
      return spec;
    }

    spec.typeLookupKey = tokenValue.substring(0, separatorIndex).trim();
    spec.fieldApiName = String.isBlank(rawFieldApiName) ? null : rawFieldApiName.trim();
    return spec;
  }

  private static Set<String> buildLookupKeys(Id typeId, String typeName, String typeUniqueKey) {
    Set<String> keys = new Set<String>();
    addLookupKey(keys, typeName);
    addLookupKey(keys, typeUniqueKey);
    addLookupKey(keys, typeId == null ? null : String.valueOf(typeId));
    return keys;
  }

  private static void addLookupKey(Set<String> keys, String rawKey) {
    String normalized = normalize(rawKey);
    if (String.isNotBlank(normalized)) {
      keys.add(normalized);
    }
  }

  private static String normalize(String value) {
    if (String.isBlank(value)) {
      return '';
    }
    return value.trim().toLowerCase();
  }

  private static String escapeHtml(String raw) {
    if (raw == null) {
      return '';
    }
    return raw
      .replace('&', '&amp;')
      .replace('<', '&lt;')
      .replace('>', '&gt;')
      .replace('"', '&quot;')
      .replace('\'', '&#39;');
  }

  private static Id resolveOrgWideEmailAddressId(String address) {
    if (String.isBlank(address)) {
      return null;
    }
    String normalizedAddress = address.trim().toLowerCase();
    List<OrgWideEmailAddress> rows = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = :normalizedAddress
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0].Id;
  }

  private static String formatSendErrors(Messaging.SendEmailResult sendResult) {
    if (sendResult == null || sendResult.getErrors() == null || sendResult.getErrors().isEmpty()) {
      return 'Unknown email send failure.';
    }
    List<String> messages = new List<String>();
    for (Messaging.SendEmailError error : sendResult.getErrors()) {
      if (error == null) {
        continue;
      }
      String status = String.valueOf(error.getStatusCode());
      String message = error.getMessage();
      messages.add(status + (String.isBlank(message) ? '' : ': ' + message));
    }
    return String.join(messages, ' | ');
  }

  private static Id tryParseId(String value) {
    if (String.isBlank(value)) {
      return null;
    }
    try {
      return (Id) value.trim();
    } catch (Exception ignored) {
      return null;
    }
  }

  private static void fail(DispatchResult result, String message) {
    result.ranSuccessfully = false;
    result.failedCount = Math.max(result.failedCount, 1);
    appendDiagnostic(result, message);
  }

  private static void appendDiagnostic(DispatchResult result, String message) {
    if (result == null || String.isBlank(message)) {
      return;
    }
    if (String.isBlank(result.diagnosticMessage)) {
      result.diagnosticMessage = message.left(MAX_ERROR_MESSAGE_LENGTH);
      return;
    }
    String combined = result.diagnosticMessage + ' || ' + message;
    result.diagnosticMessage = combined.left(MAX_ERROR_MESSAGE_LENGTH);
  }
}
