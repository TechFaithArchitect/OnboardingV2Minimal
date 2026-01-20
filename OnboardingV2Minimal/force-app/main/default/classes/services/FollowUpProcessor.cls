public with sharing class FollowUpProcessor implements Queueable {

    /**
     * Processes pending follow-ups whose Next_Attempt_Date__c is due.
     */
    public void execute(QueueableContext qc) {
        List<Follow_Up_Queue__c> due = [
            SELECT Id, Follow_Up_Type__c, Status__c, Next_Attempt_Date__c, Attempt_Count__c, Follow_Up_Rule__c
            FROM Follow_Up_Queue__c
            WHERE Status__c IN ('Pending', 'Pending Retry')
              AND Next_Attempt_Date__c <= :DateTime.now()
              AND Is_Archived__c = false
            LIMIT 200
        ];

        for (Follow_Up_Queue__c fq : due) {
            Follow_Up_Rule__mdt followUpRule = getRule(fq.Follow_Up_Rule__c);
            List<Integer> schedule = parseSchedule(followUpRule != null ? followUpRule.Escalation_Schedule__c : null);

            try {
                if (fq.Follow_Up_Type__c == 'SMS') {
                    FollowUpExecutionService.sendSMSFollowUp(fq.Id);
                } else if (fq.Follow_Up_Type__c == 'Email') {
                    FollowUpExecutionService.sendEmailFollowUp(fq.Id);
                } else {
                    // Unknown type; mark failed
                    FollowUpExecutionService.markFollowUpFailed(fq.Id, 'Unknown follow-up type: ' + fq.Follow_Up_Type__c);
                }
            } catch (Exception ex) {
                FollowUpExecutionService.markFollowUpFailed(fq.Id, 'Processing failed: ' + ex.getMessage());
            } finally {
                // Set next attempt based on escalation schedule if still retriable
                if (!schedule.isEmpty()) {
                    Follow_Up_Queue__c refreshed = [
                        SELECT Status__c, Attempt_Count__c
                        FROM Follow_Up_Queue__c
                        WHERE Id = :fq.Id
                        LIMIT 1
                    ];
                    Integer attempt = refreshed.Attempt_Count__c == null ? 0 : refreshed.Attempt_Count__c.intValue();
                    if (attempt < schedule.size() && refreshed.Status__c != 'Sent') {
                        Integer days = schedule[attempt];
                        DateTime next = DateTime.now().addDays(days);
                        Follow_Up_Queue__c updateFq = new Follow_Up_Queue__c(
                            Id = fq.Id,
                            Next_Attempt_Date__c = next,
                            Status__c = refreshed.Status__c == 'Failed' ? 'Pending Retry' : refreshed.Status__c
                        );
                        update updateFq;
                    }
                }
            }
        }
    }

    public static void enqueue() {
        System.enqueueJob(new FollowUpProcessor());
    }

    private static Follow_Up_Rule__mdt getRule(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }
        List<Follow_Up_Rule__mdt> followUpRules = [
            SELECT DeveloperName, Escalation_Schedule__c
            FROM Follow_Up_Rule__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        return followUpRules.isEmpty() ? null : followUpRules[0];
    }

    @TestVisible
    private static List<Integer> parseSchedule(String jsonSchedule) {
        List<Integer> schedule = new List<Integer>();
        if (String.isBlank(jsonSchedule)) {
            return schedule;
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonSchedule);
            if (parsed instanceof List<Object>) {
                for (Object entry : (List<Object>)parsed) {
                    if (entry instanceof Map<String, Object>) {
                        Map<String, Object> mapEntry = (Map<String, Object>)entry;
                        if (mapEntry.containsKey('days') && mapEntry.get('days') != null) {
                            Object daysObj = mapEntry.get('days');
                            if (daysObj instanceof Integer) {
                                schedule.add((Integer)daysObj);
                            } else if (daysObj instanceof Decimal) {
                                schedule.add(((Decimal)daysObj).intValue());
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            // ignore parsing errors; return whatever was parsed
        }
        return schedule;
    }
}