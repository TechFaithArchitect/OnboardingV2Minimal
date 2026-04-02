/**
 * Queueable worker that processes due onboarding background retry jobs.
 */
public with sharing class OnboardingBackgroundRetryWorker implements Queueable {
    public void execute(QueueableContext context) {
        OnboardingBackgroundRetryService.processDueJobs(null);
    }
}
