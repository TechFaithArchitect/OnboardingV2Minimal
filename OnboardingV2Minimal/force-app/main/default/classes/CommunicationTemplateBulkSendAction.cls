public with sharing class CommunicationTemplateBulkSendAction {

  private static final Integer MAX_EMAILS_PER_SEND_CALL = 10;
  private static final Integer MAX_ERROR_MESSAGE_LENGTH = 3000;

  public class BulkSendRequest {
    @InvocableVariable(required=true label='Communication Template Ids')
    public List<String> communicationTemplateIds;

    @InvocableVariable(required=true label='Recipient Ids')
    public List<String> recipientIds;

    @InvocableVariable(label='Onboarding Ids')
    public List<String> onboardingIds;

    @InvocableVariable(label='Default Sender Address')
    public String defaultSenderAddress;
  }

  public class BulkSendResult {
    @InvocableVariable(label='Send Failed')
    public Boolean sendFailed;

    @InvocableVariable(label='Error Message')
    public String errorMessage;

    @InvocableVariable(label='Sent Count')
    public Integer sentCount;

    @InvocableVariable(label='Failed Count')
    public Integer failedCount;
  }

  private class RequestRow {
    public Integer index;
    public Id communicationTemplateId;
    public Id recipientId;
    public Id onboardingId;

    public RequestRow(Integer index, Id communicationTemplateId, Id recipientId, Id onboardingId) {
      this.index = index;
      this.communicationTemplateId = communicationTemplateId;
      this.recipientId = recipientId;
      this.onboardingId = onboardingId;
    }
  }

  private class PendingEmail {
    public Integer requestIndex;
    public Messaging.SingleEmailMessage message;

    public PendingEmail(Integer requestIndex, Messaging.SingleEmailMessage message) {
      this.requestIndex = requestIndex;
      this.message = message;
    }
  }

  @InvocableMethod(
    label='Send Communication Templates (Bulk)'
    description='Sends communication-template emails in bulk using Communication_Template__c + EmailTemplate. Returns aggregate send status.'
  )
  public static List<BulkSendResult> sendBulk(List<BulkSendRequest> invocations) {
    List<BulkSendResult> results = new List<BulkSendResult>();
    if (invocations == null || invocations.isEmpty()) {
      return results;
    }

    for (BulkSendRequest invocation : invocations) {
      BulkSendResult result = new BulkSendResult();
      result.sendFailed = false;
      result.errorMessage = '';
      result.sentCount = 0;
      result.failedCount = 0;

      List<String> templateIdsRaw =
        invocation == null || invocation.communicationTemplateIds == null
          ? new List<String>()
          : invocation.communicationTemplateIds;
      List<String> recipientIdsRaw =
        invocation == null || invocation.recipientIds == null
          ? new List<String>()
          : invocation.recipientIds;
      List<String> onboardingIdsRaw =
        invocation == null || invocation.onboardingIds == null
          ? new List<String>()
          : invocation.onboardingIds;

      Integer templateCount = templateIdsRaw.size();
      Integer recipientCount = recipientIdsRaw.size();
      Integer onboardingCount = onboardingIdsRaw.size();
      Integer requestCount = Math.max(templateCount, recipientCount);

      if (requestCount == 0) {
        results.add(result);
        continue;
      }

      if (templateCount != recipientCount) {
        appendError(
          result,
          'Input size mismatch: communicationTemplateIds=' + templateCount +
            ', recipientIds=' + recipientCount + '.'
        );
      }

      try {
        Set<Id> templateIds = new Set<Id>();
        Set<String> senderAddresses = new Set<String>();
        List<RequestRow> requestRows = new List<RequestRow>();

        if (String.isNotBlank(invocation.defaultSenderAddress)) {
          senderAddresses.add(invocation.defaultSenderAddress.trim().toLowerCase());
        }

        for (Integer index = 0; index < requestCount; index++) {
          String templateIdRaw = index < templateCount ? templateIdsRaw[index] : null;
          String recipientIdRaw = index < recipientCount ? recipientIdsRaw[index] : null;
          String onboardingIdRaw = index < onboardingCount ? onboardingIdsRaw[index] : null;

          Id communicationTemplateId = parseId(templateIdRaw);
          Id recipientId = parseId(recipientIdRaw);
          Id onboardingId = parseId(onboardingIdRaw);

          if (String.isBlank(templateIdRaw)) {
            result.failedCount++;
            appendError(result, 'Request #' + index + ': communicationTemplateIds value is required.');
            continue;
          }
          if (communicationTemplateId == null) {
            result.failedCount++;
            appendError(result, 'Request #' + index + ': communicationTemplateIds value is not a valid Id.');
            continue;
          }

          if (String.isBlank(recipientIdRaw)) {
            result.failedCount++;
            appendError(result, 'Request #' + index + ': recipientIds value is required.');
            continue;
          }
          if (recipientId == null) {
            result.failedCount++;
            appendError(result, 'Request #' + index + ': recipientIds value is not a valid Id.');
            continue;
          }

          if (!String.isBlank(onboardingIdRaw) && onboardingId == null) {
            result.failedCount++;
            appendError(result, 'Request #' + index + ': onboardingIds value is not a valid Id.');
            continue;
          }

          templateIds.add(communicationTemplateId);
          requestRows.add(new RequestRow(index, communicationTemplateId, recipientId, onboardingId));
        }

        Map<Id, Communication_Template__c> templateById = new Map<Id, Communication_Template__c>();
        if (!templateIds.isEmpty()) {
          for (Communication_Template__c template : [
            SELECT Id, Email_Template_Id__c
            FROM Communication_Template__c
            WHERE Id IN :templateIds
          ]) {
            templateById.put(template.Id, template);
          }
        }

        Map<String, Id> orgWideByAddress = new Map<String, Id>();
        if (!senderAddresses.isEmpty()) {
          for (OrgWideEmailAddress orgWide : [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address IN :senderAddresses
          ]) {
            orgWideByAddress.put(orgWide.Address.toLowerCase(), orgWide.Id);
          }
        }

        List<PendingEmail> pendingEmails = new List<PendingEmail>();
        for (RequestRow row : requestRows) {
          Communication_Template__c template = templateById.get(row.communicationTemplateId);
          if (template == null) {
            result.failedCount++;
            appendError(
              result,
              'Request #' + row.index + ': Communication_Template__c not found (' +
                String.valueOf(row.communicationTemplateId) + ').'
            );
            continue;
          }
          if (template.Email_Template_Id__c == null) {
            result.failedCount++;
            appendError(
              result,
              'Request #' + row.index + ': template is missing Email_Template_Id__c (' +
                String.valueOf(template.Id) + ').'
            );
            continue;
          }

          try {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTemplateId(template.Email_Template_Id__c);
            message.setTargetObjectId(row.recipientId);
            message.setTreatTargetObjectAsRecipient(true);
            message.setSaveAsActivity(true);

            if (row.onboardingId != null) {
              message.setWhatId(row.onboardingId);
            }

            if (String.isNotBlank(invocation.defaultSenderAddress)) {
              Id orgWideId = orgWideByAddress.get(invocation.defaultSenderAddress.trim().toLowerCase());
              if (orgWideId != null) {
                message.setOrgWideEmailAddressId(orgWideId);
              }
            }

            pendingEmails.add(new PendingEmail(row.index, message));
          } catch (Exception messageEx) {
            result.failedCount++;
            appendError(
              result,
              'Request #' + row.index + ': failed while preparing email (' + messageEx.getMessage() + ').'
            );
          }
        }

        Integer remainingEmailInvocations =
          Limits.getLimitEmailInvocations() - Limits.getEmailInvocations();

        if (remainingEmailInvocations <= 0) {
          result.failedCount += pendingEmails.size();
          appendError(
            result,
            'Email invocation limit reached before send. No prepared emails were attempted in this transaction.'
          );
          results.add(result);
          continue;
        }

        Integer maxSendableEmails = Math.min(
          pendingEmails.size(),
          remainingEmailInvocations * MAX_EMAILS_PER_SEND_CALL
        );
        if (maxSendableEmails < pendingEmails.size()) {
          Integer droppedCount = pendingEmails.size() - maxSendableEmails;
          result.failedCount += droppedCount;
          appendError(
            result,
            'Email invocation guard applied. Attempting ' + maxSendableEmails +
              ' of ' + pendingEmails.size() + ' prepared emails; ' + droppedCount +
              ' were skipped to stay within Apex sendEmail invocation limits.'
          );
        }

        for (Integer start = 0; start < maxSendableEmails; start += MAX_EMAILS_PER_SEND_CALL) {
          Integer endExclusive = Math.min(start + MAX_EMAILS_PER_SEND_CALL, maxSendableEmails);
          List<Messaging.SingleEmailMessage> emailChunk = new List<Messaging.SingleEmailMessage>();
          List<PendingEmail> pendingChunk = new List<PendingEmail>();

          for (Integer i = start; i < endExclusive; i++) {
            pendingChunk.add(pendingEmails[i]);
            emailChunk.add(pendingEmails[i].message);
          }

          try {
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailChunk, false);
            for (Integer i = 0; i < sendResults.size(); i++) {
              Messaging.SendEmailResult sendResult = sendResults[i];
              Integer requestIndex = pendingChunk[i].requestIndex;

              if (sendResult.isSuccess()) {
                result.sentCount++;
              } else {
                result.failedCount++;
                appendError(result, formatSendError(requestIndex, sendResult));
              }
            }
          } catch (Exception sendEx) {
            for (PendingEmail pending : pendingChunk) {
              result.failedCount++;
              appendError(
                result,
                'Request #' + pending.requestIndex + ': email send exception (' + sendEx.getMessage() + ').'
              );
            }
          }
        }
      } catch (Exception ex) {
        result.sendFailed = true;
        appendError(result, 'Bulk send failed: ' + ex.getMessage());
      }

      if (result.failedCount > 0 || String.isNotBlank(result.errorMessage)) {
        result.sendFailed = true;
      }
      results.add(result);
    }

    return results;
  }

  private static Id parseId(String value) {
    if (String.isBlank(value)) {
      return null;
    }

    try {
      return (Id) value.trim();
    } catch (Exception ignored) {
      return null;
    }
  }

  private static String formatSendError(Integer requestIndex, Messaging.SendEmailResult sendResult) {
    if (sendResult == null || sendResult.getErrors() == null || sendResult.getErrors().isEmpty()) {
      return 'Request #' + requestIndex + ': unknown email failure.';
    }

    List<String> messages = new List<String>();
    for (Messaging.SendEmailError err : sendResult.getErrors()) {
      if (err == null) {
        continue;
      }
      String statusCode = String.valueOf(err.getStatusCode());
      String message = err.getMessage();
      messages.add(statusCode + (String.isBlank(message) ? '' : ': ' + message));
    }

    return 'Request #' + requestIndex + ': ' + String.join(messages, ' | ');
  }

  private static void appendError(BulkSendResult result, String nextError) {
    if (result == null || String.isBlank(nextError)) {
      return;
    }

    String current = result.errorMessage;
    if (String.isBlank(current)) {
      result.errorMessage = nextError.left(MAX_ERROR_MESSAGE_LENGTH);
      return;
    }

    String combined = current + ' || ' + nextError;
    result.errorMessage = combined.left(MAX_ERROR_MESSAGE_LENGTH);
  }
}
