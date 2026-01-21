/**
 * Service for handling follow-up fatigue and suppression logic
 * Prevents overwhelming dealers with repeated follow-ups
 */
public with sharing class FollowUpFatigueService {

    /**
     * Check if a follow-up should be suppressed due to fatigue
     * @param onboardingRequirementId The Onboarding_Requirement__c record ID
     * @param followUpRuleId The Follow_Up_Rule__mdt DeveloperName (if available)
     * @return Boolean indicating if follow-up should be suppressed
     */
    public static Boolean shouldSuppressDueToFatigue(
        Id onboardingRequirementId,
        String followUpRuleDeveloperName
    ) {
        if (onboardingRequirementId == null) {
            return false;
        }

        // Get follow-up rule metadata (if available)
        Integer maxAttempts = 3;
        Integer fatigueWindowDays = 7;
        Boolean fatigueEnabled = true;

        if (String.isNotBlank(followUpRuleDeveloperName)) {
            Follow_Up_Rule__mdt followUpRule = FollowUpRuleRepository.getRuleByDeveloperName(followUpRuleDeveloperName);
            if (followUpRule != null) {
                if (followUpRule.Fatigue_Suppression_Enabled__c == false) {
                    return false;
                }
                maxAttempts = followUpRule.Max_Attempts_Per_Window__c != null ? followUpRule.Max_Attempts_Per_Window__c.intValue() : maxAttempts;
                fatigueWindowDays = followUpRule.Fatigue_Window_Days__c != null ? followUpRule.Fatigue_Window_Days__c.intValue() : fatigueWindowDays;
            }
        }

        // Suppression windows (holiday/manual/system) via metadata
        Id accountId = FollowUpRuleRepository.getAccountIdForRequirement(onboardingRequirementId);
        if (accountId != null && isSuppressedAccount(accountId)) {
            return true;
        }

        if (!fatigueEnabled) {
            return false;
        }

        // Calculate date threshold
        Date thresholdDate = Date.today().addDays(-fatigueWindowDays);
        DateTime thresholdDateTime = DateTime.newInstance(thresholdDate, Time.newInstance(0, 0, 0, 0));

        // Query recent follow-ups for this requirement
        List<Follow_Up_Queue__c> recentFollowUps = FollowUpRuleRepository.getRecentFollowUps(
            onboardingRequirementId,
            thresholdDateTime
        );

        if (recentFollowUps.isEmpty()) {
            return false;
        }

        // Calculate total attempts in the window
        Integer totalAttempts = 0;
        for (Follow_Up_Queue__c fq : recentFollowUps) {
            totalAttempts += (fq.Attempt_Count__c != null ? fq.Attempt_Count__c.intValue() : 0);
        }

        // Check if threshold exceeded
        if (totalAttempts >= maxAttempts) {
            return true;
        }

        // Also check consecutive failures
        for (Follow_Up_Queue__c fq : recentFollowUps) {
            if (fq.Consecutive_Failures__c != null && fq.Consecutive_Failures__c >= 3) {
                return true;
            }
        }

        return false;
    }

    /**
     * Check suppression windows for an Account via Follow_Up_Suppression__mdt.
     */
    public static Boolean isSuppressedAccount(Id accountId) {
        if (accountId == null) {
            return false;
        }
        List<Follow_Up_Suppression__mdt> suppressions = FollowUpRuleRepository.getActiveSuppressions();
        if (suppressions.isEmpty()) {
            return false;
        }

        for (Follow_Up_Suppression__mdt sup : suppressions) {
            Map<String, Object> meta = new Map<String, Object>{
                'Start_Date__c' => sup.Start_Date__c,
                'End_Date__c' => sup.End_Date__c,
                'Timezone_Aware__c' => sup.Timezone_Aware__c
            };
            if (isWithinSuppressionWindow(accountId, meta)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Apply fatigue suppression to a follow-up queue record
     * @param followUpQueueId The Follow_Up_Queue__c record ID
     * @param reason The reason for suppression
     */
    public static void applyFatigueSuppression(Id followUpQueueId, String reason) {
        if (followUpQueueId == null) {
            return;
        }

        Follow_Up_Queue__c followUp = FollowUpRuleRepository.getFollowUpQueue(followUpQueueId);
        if (followUp == null) {
            return;
        }

        followUp.Fatigue_Suppressed__c = true;
        followUp.Suppression_Reason__c = reason;
        if (PicklistHelper.isPicklistValueValid('Follow_Up_Queue__c', 'Status__c', 'Suppressed')) {
            followUp.Status__c = 'Suppressed';
        }
        
        update followUp;
    }

    /**
     * Check if suppression should be applied based on timezone-aware rules
     * @param accountId The Account ID (to get timezone)
     * @param suppressionMetadata Follow_Up_Suppression__mdt record
     * @return Boolean indicating if currently within suppression window
     */
    public static Boolean isWithinSuppressionWindow(Id accountId, Map<String, Object> suppressionMetadata) {
        if (accountId == null || suppressionMetadata == null) {
            return false;
        }

        Boolean timezoneAware = (Boolean)suppressionMetadata.get('Timezone_Aware__c');
        if (!timezoneAware) {
            // Use org timezone
            Date startDate = (Date)suppressionMetadata.get('Start_Date__c');
            Date endDate = (Date)suppressionMetadata.get('End_Date__c');
            Date today = Date.today();
            return today >= startDate && today <= endDate;
        }

        // Get dealer timezone from Account
        String timezoneStr = getDealerTimezone(accountId);
        if (String.isBlank(timezoneStr)) {
            // Fallback: Use org timezone if Account timezone not set
            // Note: Consider using Field Service timezone as alternative fallback
            timezoneStr = UserInfo.getTimeZone().getID();
        }

        TimeZone dealerTZ = TimeZone.getTimeZone(timezoneStr);
        DateTime nowInDealerTZ = convertToDealerTimezone(DateTime.now(), dealerTZ);
        Date dealerDate = nowInDealerTZ.date();

        Date startDate = (Date)suppressionMetadata.get('Start_Date__c');
        Date endDate = (Date)suppressionMetadata.get('End_Date__c');

        return dealerDate >= startDate && dealerDate <= endDate;
    }

    /**
     * Get dealer timezone from Account
     * Uses Account__c.Time_zone__pc (Person Account field with Global Value Set PV_TimeZone)
     * 
     * Alternative: Could use Field Service timezone from:
     * - ServiceTerritory.OperatingHours.TimeZone (if Account has Service Territory)
     * - ServiceResource.TimeZoneSidKey (if Account has assigned Service Resource)
     * 
     * @param accountId The Account ID
     * @return Timezone string (e.g., 'America/New_York')
     */
    private static String getDealerTimezone(Id accountId) {
        try {
            Account accountRecord = [
                SELECT Time_zone__pc
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            if (String.isNotBlank(accountRecord.Time_zone__pc)) {
                // Time_zone__pc uses Global Value Set PV_TimeZone
                // The value should be a valid timezone ID (e.g., 'America/New_York')
                return accountRecord.Time_zone__pc;
            }

            // Fallback: Could check Field Service timezone here
            // TODO: Consider querying ServiceTerritory or ServiceResource timezone if needed
            // For now, return null to let caller handle fallback
            return null;
        } catch (Exception ex) {
            System.debug('Error getting dealer timezone: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * Convert DateTime to dealer timezone
     * @param dt DateTime to convert
     * @param tz Target timezone
     * @return DateTime in target timezone
     */
    private static DateTime convertToDealerTimezone(DateTime dt, TimeZone tz) {
        // Convert to dealer timezone
        Long offset = tz.getOffset(dt);
        // addSeconds takes Integer, not Long
        Integer offsetSeconds = (offset / 1000).intValue();
        return dt.addSeconds(offsetSeconds);
    }

    /**
     * Update attempt tracking on follow-up queue record
     * @param followUpQueueId The Follow_Up_Queue__c record ID
     * @param wasSuccessful Whether the attempt was successful
     */
    public static void updateAttemptTracking(Id followUpQueueId, Boolean wasSuccessful) {
        if (followUpQueueId == null) {
            return;
        }

        Follow_Up_Queue__c followUp = FollowUpRuleRepository.getFollowUpQueueForTracking(followUpQueueId);
        if (followUp == null) {
            return;
        }

        // Update attempt count
        followUp.Attempt_Count__c = (followUp.Attempt_Count__c == null ? 0 : followUp.Attempt_Count__c) + 1;
        followUp.Last_Attempt_Date__c = DateTime.now();

        // Update consecutive failures
        if (wasSuccessful) {
            followUp.Consecutive_Failures__c = 0;
        } else {
            followUp.Consecutive_Failures__c = (followUp.Consecutive_Failures__c == null ? 0 : followUp.Consecutive_Failures__c) + 1;
        }

        update followUp;
    }

    /**
     * Check if follow-up is suppressed (fatigue or other reasons)
     * @param followUpQueueId The Follow_Up_Queue__c record ID
     * @return Boolean indicating if suppressed
     */
    public static Boolean isSuppressed(Id followUpQueueId) {
        if (followUpQueueId == null) {
            return false;
        }

        Follow_Up_Queue__c followUp = FollowUpRuleRepository.getFollowUpQueueForTracking(followUpQueueId);
        if (followUp == null) {
            return false;
        }

        return followUp.Fatigue_Suppressed__c == true || followUp.Status__c == 'Suppressed';
    }

    /**
     * Remove suppression from follow-up queue record
     * @param followUpQueueId The Follow_Up_Queue__c record ID
     */
    public static void removeSuppression(Id followUpQueueId) {
        if (followUpQueueId == null) {
            return;
        }

        Follow_Up_Queue__c followUp = FollowUpRuleRepository.getFollowUpQueueForTracking(followUpQueueId);
        if (followUp == null) {
            return;
        }

        followUp.Fatigue_Suppressed__c = false;
        followUp.Suppression_Reason__c = null;
        
        if (followUp.Status__c == 'Suppressed') {
            followUp.Status__c = 'Pending';
        }

        update followUp;
    }
}