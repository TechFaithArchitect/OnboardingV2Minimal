/**
 * Scheduled processor for onboarding background retry jobs.
 */
public with sharing class OnboardingBackgroundRetryScheduler implements Schedulable {
    public static final String JOB_NAME = 'Onboarding Background Retry Scheduler';
    public static final String CRON_EVERY_10_MIN = '0 0/10 * * * ?';

    public void execute(SchedulableContext context) {
        OnboardingBackgroundRetryService.processDueJobs(null);
    }
}
