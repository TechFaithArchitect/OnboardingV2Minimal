/**
 * Queueable worker that processes due onboarding background retry jobs.
 */
public with sharing class OnboardingBackgroundRetryWorker implements Queueable, Finalizer {
    public void execute(QueueableContext context) {
        System.attachFinalizer(this);
        OnboardingBackgroundRetryService.processDueJobs(null);
    }

    public void execute(FinalizerContext context) {
        if (context == null || context.getResult() != ParentJobResult.UNHANDLED_EXCEPTION) {
            return;
        }
        Exception ex = context.getException();
        LoggingUtil.error(
            'OnboardingBackgroundRetryWorker finalizer captured unhandled exception: '
            + (ex == null ? 'Unknown error.' : ex.getTypeName() + ': ' + ex.getMessage())
        );
    }
}
