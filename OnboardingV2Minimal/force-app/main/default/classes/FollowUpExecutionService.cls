/**
 * Service for executing follow-up actions (SMS, Email, etc.)
 * Handles retry logic and integrates with Salesforce Messaging API
 */
public with sharing class FollowUpExecutionService {

    /**
     * Send SMS follow-up via Salesforce Messaging
     * @param followUpQueueId Follow_Up_Queue__c record ID
     */
    public static void sendSMSFollowUp(Id followUpQueueId) {
        if (followUpQueueId == null) {
            throw new IllegalArgumentException('Follow-up queue ID is required');
        }

        Follow_Up_Queue__c followUp = [
            SELECT Id, Onboarding__c, Onboarding__r.Account__c,
                   Follow_Up_Type__c, Status__c, Follow_Up_Rule__c,
                   Attempt_Count__c, Last_Attempt_Date__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        if (followUp.Onboarding__r.Account__c == null) {
            markFollowUpFailed(followUpQueueId, 'No Account found for onboarding');
            return;
        }

        // Get Contact from Account
        Contact dealerContact = FollowUpMessagingService.getPrimaryContact(followUp.Onboarding__r.Account__c);

        if (dealerContact == null) {
            markFollowUpFailed(followUpQueueId, 'No contact found for account');
            return;
        }

        Follow_Up_Rule__mdt followUpRule = getRuleByDeveloperName(followUp.Follow_Up_Rule__c);
        Communication_Template__c commTemplate = getCommTemplate(followUpRule);

        // Determine SMS provider (prefers SMS_Provider__c field, falls back to Messaging Channel presence)
        String smsProvider = determineSMSProvider(followUpRule, commTemplate);
        
        // Build provider configuration based on provider type
        Map<String, Object> providerConfig = buildProviderConfig(smsProvider, followUpRule, commTemplate);
        
        // Validate provider configuration (fail fast before callout)
        String configError = validateProviderConfig(smsProvider, providerConfig);
        if (configError != null) {
            markFollowUpFailed(followUpQueueId, configError);
            return;
        }

        // Check if Contact has active messaging endpoint
        if (!FollowUpMessagingService.hasActiveMessagingEndpoint(dealerContact.Id, smsProvider, providerConfig)) {
            markFollowUpFailed(followUpQueueId, 'No active messaging endpoint for contact');
            return;
        }
        
        // If provider is Twilio, ensure Salesforce Messaging path is not used
        if (smsProvider == 'Twilio' && providerConfig.containsKey('messagingChannelId')) {
            providerConfig.remove('messagingChannelId');
        }

        try {
            // Get message content
            String messageContent = getMessageContent(followUp, followUpRule, commTemplate);

            // Send SMS using provider strategy
            String smsId = FollowUpMessagingService.sendSMS(
                dealerContact.Id,
                messageContent,
                smsProvider,
                providerConfig
            );

            // Update Follow_Up_Queue__c
            followUp.Status__c = 'Sent';
            followUp.Last_Attempt_Date__c = DateTime.now();
            followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
            followUp.Consecutive_Failures__c = 0; // Reset on success
            
            // Store SMS tracking ID (MessagingSession ID) if available
            // Note: If Messaging_Session__c field exists on Follow_Up_Queue__c, uncomment:
            // try {
            //     followUp.Messaging_Session__c = (Id)smsId;
            // } catch (Exception e) {
            //     // Field may not exist - ignore
            // }
            
            update followUp;

            // Update attempt tracking
            FollowUpFatigueService.updateAttemptTracking(followUpQueueId, true);
        } catch (Exception ex) {
            markFollowUpFailed(followUpQueueId, 'Error sending SMS: ' + ex.getMessage());
            FollowUpFatigueService.updateAttemptTracking(followUpQueueId, false);
            throw ex;
        }
    }

    /**
     * Send email follow-up
     * @param followUpQueueId Follow_Up_Queue__c record ID
     */
    public static void sendEmailFollowUp(Id followUpQueueId) {
        if (followUpQueueId == null) {
            throw new IllegalArgumentException('Follow-up queue ID is required');
        }

        Follow_Up_Queue__c followUp = [
            SELECT Id, Onboarding__c, Onboarding__r.Account__c,
                   Follow_Up_Type__c, Status__c, Follow_Up_Rule__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        Follow_Up_Rule__mdt followUpRule = getRuleByDeveloperName(followUp.Follow_Up_Rule__c);
        Communication_Template__c commTemplate = getCommTemplate(followUpRule);

        Contact dealerContact = FollowUpMessagingService.getPrimaryContact(followUp.Onboarding__r.Account__c);
        if (dealerContact == null || String.isBlank(dealerContact.Email)) {
            markFollowUpFailed(followUpQueueId, 'No contact email available for onboarding account');
            return;
        }

        // Build email from communication template
        String emailTemplateId = commTemplate != null ? commTemplate.Email_Template_Id__c : null;
        if (String.isBlank(emailTemplateId)) {
            markFollowUpFailed(followUpQueueId, 'No email template configured for follow-up');
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSaveAsActivity(true);
        mail.setTemplateId(emailTemplateId);
        mail.setTargetObjectId(dealerContact.Id);
        mail.setWhatId(followUp.Onboarding__c);
        mail.setUseSignature(false);

        try {
            Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { mail }
            );
            if (emailResults == null || emailResults.isEmpty() || !emailResults[0].isSuccess()) {
                String errorMsg = (emailResults != null && !emailResults.isEmpty() && emailResults[0].getErrors().size() > 0)
                    ? emailResults[0].getErrors()[0].getMessage()
                    : 'Unknown error';
                markFollowUpFailed(followUpQueueId, 'Email send failed: ' + errorMsg);
                return;
            }
        } catch (Exception ex) {
            markFollowUpFailed(followUpQueueId, 'Email send failed: ' + ex.getMessage());
            return;
        }

        // Update follow-up on success
        followUp.Status__c = 'Sent';
        followUp.Last_Attempt_Date__c = DateTime.now();
        followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
        followUp.Consecutive_Failures__c = 0;
        update followUp;

        FollowUpFatigueService.updateAttemptTracking(followUpQueueId, true);
    }

    /**
     * Retry failed follow-ups
     * Called by FollowUpRetryHandler when Platform Event is received
     * @param followUpQueueIds List of Follow_Up_Queue__c record IDs to retry
     */
    public static void retryFailedFollowUps(List<Id> followUpQueueIds) {
        if (followUpQueueIds == null || followUpQueueIds.isEmpty()) {
            return;
        }

        List<Follow_Up_Queue__c> followUps = [
            SELECT Id, Follow_Up_Type__c, Onboarding__c,
                   Attempt_Count__c, Last_Attempt_Date__c, Status__c
            FROM Follow_Up_Queue__c
            WHERE Id IN :followUpQueueIds
              AND Status__c = 'Pending Retry'
        ];

        if (followUps.isEmpty()) {
            return;
        }

        for (Follow_Up_Queue__c fq : followUps) {
            try {
                if (fq.Follow_Up_Type__c == 'SMS') {
                    sendSMSFollowUp(fq.Id);
                } else if (fq.Follow_Up_Type__c == 'Email') {
                    sendEmailFollowUp(fq.Id);
                } else {
                    markFollowUpFailed(fq.Id, 'Unknown follow-up type: ' + fq.Follow_Up_Type__c);
                }
            } catch (Exception ex) {
                markFollowUpFailed(fq.Id, 'Retry failed: ' + ex.getMessage());
                // LoggingUtil.logError('FollowUpRetry', 'retryFailedFollowUps', ex.getMessage(), ex.getStackTraceString());
            }
        }
    }

    /**
     * Mark follow-up as failed
     * @param followUpQueueId Follow_Up_Queue__c record ID
     * @param errorMessage Error message
     */
    public static void markFollowUpFailed(Id followUpQueueId, String errorMessage) {
        Follow_Up_Queue__c followUp = [
            SELECT Id, Status__c, Consecutive_Failures__c, Attempt_Count__c, Last_Attempt_Date__c, Error_Message__c
            FROM Follow_Up_Queue__c
            WHERE Id = :followUpQueueId
            LIMIT 1
        ];

        followUp.Status__c = 'Failed';
        followUp.Consecutive_Failures__c = (followUp.Consecutive_Failures__c == null ? 0 : followUp.Consecutive_Failures__c) + 1;
        followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
        followUp.Last_Attempt_Date__c = DateTime.now();
        followUp.Error_Message__c = errorMessage;
        
        update followUp;
    }

    /**
     * Get message content for follow-up
     * TODO: Get from Follow_Up_Rule__mdt template when available
     * @param followUp Follow_Up_Queue__c record
     * @return Message content string
     */
    private static String getMessageContent(Follow_Up_Queue__c followUp, Follow_Up_Rule__mdt followUpRule, Communication_Template__c commTemplate) {
        if (commTemplate != null && !String.isBlank(commTemplate.Message_Body__c)) {
            return commTemplate.Message_Body__c;
        }
        if (followUpRule != null && !String.isBlank(followUpRule.Trigger_Condition__c)) {
            return 'Reminder: ' + followUpRule.Trigger_Condition__c;
        }
        return 'Please complete your onboarding requirement. If you have questions, contact your onboarding representative.';
    }

    /**
     * Get default messaging channel ID
     * TODO: Get from Custom Metadata or Custom Setting
     * @return MessagingChannel ID or null
     */
    private static Id getIdIfValid(String maybeId) {
        if (String.isBlank(maybeId)) {
            return null;
        }
        try {
            return (Id)maybeId;
        } catch (Exception ex) {
            return null;
        }
    }

    /**
     * Determine SMS provider from rule or template
     * Prefers SMS_Provider__c field on rule, otherwise falls back to Messaging Channel presence
     */
    private static String determineSMSProvider(Follow_Up_Rule__mdt followUpRule, Communication_Template__c commTemplate) {
        // Prefer SMS_Provider__c field if set on rule
        if (followUpRule != null) {
            try {
                String smsProvider = (String)followUpRule.get('SMS_Provider__c');
                if (String.isNotBlank(smsProvider)) {
                    return smsProvider;
                }
            } catch (Exception ex) {
                // Field may not exist yet - fall through to default logic
                System.debug('SMS_Provider__c field not accessible: ' + ex.getMessage());
            }
        }
        
        // Fallback: Check if Messaging Channel is configured
        Id messagingChannelId = getIdIfValid(
            commTemplate != null ? commTemplate.Messaging_Channel_Id__c : 
            followUpRule != null ? followUpRule.Messaging_Channel__c : null
        );
        
        // If Messaging Channel is configured, use Salesforce Messaging
        // Otherwise, default to Twilio
        return messagingChannelId != null ? 'SalesforceMessaging' : 'Twilio';
    }

    /**
     * Build provider configuration map based on provider type
     * Includes fromPhone, accountSid, and namedCredential for Twilio
     */
    private static Map<String, Object> buildProviderConfig(
        String providerType,
        Follow_Up_Rule__mdt followUpRule,
        Communication_Template__c commTemplate
    ) {
        Map<String, Object> config = new Map<String, Object>();
        
        if (providerType == 'SalesforceMessaging') {
            Id messagingChannelId = getIdIfValid(
                commTemplate != null ? commTemplate.Messaging_Channel_Id__c : 
                followUpRule != null ? followUpRule.Messaging_Channel__c : null
            );
            config.put('messagingChannelId', messagingChannelId);
            
            Id templateId = getIdIfValid(
                commTemplate != null ? commTemplate.Messaging_Template_Id__c : 
                followUpRule != null ? followUpRule.Messaging_Template__c : null
            );
            if (templateId != null) {
                config.put('templateId', templateId);
            }
        } else if (providerType == 'Twilio') {
            // Get from phone number: rule/template first, then active Twilio config
            String fromPhone = getTwilioFromPhone(followUpRule, commTemplate);
            if (String.isNotBlank(fromPhone)) {
                config.put('fromPhoneNumber', fromPhone);
            }
            
            // Get Account SID: rule/template first, then active Twilio config
            String accountSid = getTwilioAccountSid(followUpRule, commTemplate);
            if (String.isNotBlank(accountSid)) {
                config.put('accountSid', accountSid);
            }
            
            // Get Named Credential: rule/template first, then active Twilio config
            String namedCredential = getTwilioNamedCredential(followUpRule, commTemplate);
            if (String.isNotBlank(namedCredential)) {
                config.put('namedCredential', namedCredential);
            }
        }
        
        return config;
    }

    /**
     * Get Twilio from phone number
     * Priority: rule/template field > active Twilio_Configuration__mdt
     */
    private static String getTwilioFromPhone(Follow_Up_Rule__mdt followUpRule, Communication_Template__c commTemplate) {
        // Check rule first
        if (followUpRule != null) {
            try {
                String fromPhone = (String)followUpRule.get('Twilio_From_Phone__c');
                if (String.isNotBlank(fromPhone)) {
                    return fromPhone;
                }
            } catch (Exception ex) {
                // Field may not exist - continue
                System.debug('Twilio_From_Phone__c field not accessible: ' + ex.getMessage());
            }
        }
        
        // Fallback to active Twilio_Configuration__mdt
        try {
            List<Twilio_Configuration__mdt> configs = [
                SELECT From_Phone_Number__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            
            if (!configs.isEmpty() && String.isNotBlank(configs[0].From_Phone_Number__c)) {
                return configs[0].From_Phone_Number__c;
            }
        } catch (Exception ex) {
            System.debug('Twilio_Configuration__mdt not found or not accessible: ' + ex.getMessage());
        }
        
        return null;
    }

    /**
     * Get Twilio Account SID
     * Priority: rule field > active Twilio_Configuration__mdt
     * NOTE: Account SID is required for Twilio API calls (used in URL path)
     */
    private static String getTwilioAccountSid(Follow_Up_Rule__mdt followUpRule, Communication_Template__c commTemplate) {
        // Check rule first
        if (followUpRule != null) {
            try {
                String accountSid = (String)followUpRule.get('Twilio_Account_SID__c');
                if (String.isNotBlank(accountSid)) {
                    return accountSid;
                }
            } catch (Exception ex) {
                // Field may not exist - continue
                System.debug('Twilio_Account_SID__c field not accessible: ' + ex.getMessage());
            }
        }
        
        // Fallback to active Twilio_Configuration__mdt
        try {
            List<Twilio_Configuration__mdt> configs = [
                SELECT Account_SID__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            
            if (!configs.isEmpty() && String.isNotBlank(configs[0].Account_SID__c)) {
                return configs[0].Account_SID__c;
            }
        } catch (Exception ex) {
            System.debug('Could not get Account SID from Twilio_Configuration__mdt: ' + ex.getMessage());
        }
        
        return null;
    }

    /**
     * Get Twilio Named Credential name
     * Priority: rule field > active Twilio_Configuration__mdt > default 'Twilio_API'
     */
    private static String getTwilioNamedCredential(Follow_Up_Rule__mdt followUpRule, Communication_Template__c commTemplate) {
        // Check rule first
        if (followUpRule != null) {
            try {
                String namedCredential = (String)followUpRule.get('Twilio_Named_Credential__c');
                if (String.isNotBlank(namedCredential)) {
                    return namedCredential;
                }
            } catch (Exception ex) {
                // Field may not exist - continue
                System.debug('Twilio_Named_Credential__c field not accessible: ' + ex.getMessage());
            }
        }
        
        // Fallback to active Twilio_Configuration__mdt
        try {
            List<Twilio_Configuration__mdt> configs = [
                SELECT Named_Credential__c
                FROM Twilio_Configuration__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            
            if (!configs.isEmpty() && String.isNotBlank(configs[0].Named_Credential__c)) {
                return configs[0].Named_Credential__c;
            }
        } catch (Exception ex) {
            System.debug('Could not get Named Credential from Twilio_Configuration__mdt: ' + ex.getMessage());
        }
        
        // Default to 'Twilio_API' if nothing is configured
        return 'Twilio_API';
    }

    /**
     * Validate provider configuration
     * Returns precise error messages when required fields are missing
     */
    private static String validateProviderConfig(String providerType, Map<String, Object> providerConfig) {
        if (providerType == 'SalesforceMessaging') {
            Id messagingChannelId = (Id)providerConfig.get('messagingChannelId');
            if (messagingChannelId == null) {
                return 'No messaging channel configured for Salesforce Messaging. Configure Messaging_Channel__c on Follow_Up_Rule__mdt or Communication_Template__c.';
            }
        } else if (providerType == 'Twilio') {
            String fromPhone = (String)providerConfig.get('fromPhoneNumber');
            if (String.isBlank(fromPhone)) {
                return 'From phone number is required for Twilio. Configure Twilio_From_Phone__c on Follow_Up_Rule__mdt or ensure an active Twilio_Configuration__mdt record exists with From_Phone_Number__c.';
            }
            
            String accountSid = (String)providerConfig.get('accountSid');
            if (String.isBlank(accountSid)) {
                return 'Account SID is required for Twilio API calls. Configure Twilio_Account_SID__c on Follow_Up_Rule__mdt or ensure an active Twilio_Configuration__mdt record exists with Account_SID__c. Alternatively, store Account SID in Named Credential username.';
            }
            
            // Named Credential is optional (has default), but validate it's provided or default exists
            String namedCredential = (String)providerConfig.get('namedCredential');
            if (String.isBlank(namedCredential)) {
                return 'Named Credential is required for Twilio. Configure Twilio_Named_Credential__c on Follow_Up_Rule__mdt or ensure an active Twilio_Configuration__mdt record exists with Named_Credential__c.';
            }
        }
        return null; // Valid
    }

    private static Follow_Up_Rule__mdt getRuleByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }
        List<Follow_Up_Rule__mdt> followUpRules = [
            SELECT DeveloperName, Trigger_Condition__c, Follow_Up_Type__c,
                   Initial_Delay_Days__c, Escalation_Schedule__c,
                   Messaging_Channel__c, Messaging_Template__c,
                   Max_Attempts_Per_Window__c, Fatigue_Window_Days__c, Fatigue_Suppression_Enabled__c,
                   Active__c,
                   SMS_Provider__c, Twilio_From_Phone__c, Twilio_Account_SID__c, Twilio_Named_Credential__c
            FROM Follow_Up_Rule__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        return followUpRules.isEmpty() ? null : followUpRules[0];
    }

    private static Communication_Template__c getCommTemplate(Follow_Up_Rule__mdt followUpRule) {
        if (followUpRule == null || String.isBlank(followUpRule.Messaging_Template__c)) {
            return null;
        }
        List<Communication_Template__c> comms = [
            SELECT Id, Name, Communication_Type__c,
                   Email_Subject__c, Email_Template_Id__c,
                   Messaging_Template_Id__c, Messaging_Channel_Id__c, Message_Body__c
            FROM Communication_Template__c
            WHERE Id = :followUpRule.Messaging_Template__c
            LIMIT 1
        ];
        return comms.isEmpty() ? null : comms[0];
    }
}