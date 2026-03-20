public with sharing class AsyncFailureTelemetryFinalizer implements Finalizer {
    private static final String UNKNOWN_OPERATION = 'UnknownOperation';
    private static final String UNKNOWN_CONTEXT = 'none';

    private final String operationName;
    private final String contextSummary;

    public AsyncFailureTelemetryFinalizer(String operationName, String contextSummary) {
        this.operationName = normalizeOperation(operationName);
        this.contextSummary = normalizeContext(contextSummary);
    }

    public static void attach(String operationName, String contextSummary) {
        try {
            System.attachFinalizer(new AsyncFailureTelemetryFinalizer(operationName, contextSummary));
        } catch (Exception ex) {
            LoggingUtil.warn(
                buildHandledFailureMessage(
                    normalizeOperation(operationName),
                    normalizeContext(contextSummary),
                    ex,
                    'Unable to attach queueable finalizer'
                )
            );
        }
    }

    public static void logHandledFailure(
        String operationName,
        String contextSummary,
        Exception ex,
        String failureReason
    ) {
        LoggingUtil.error(
            buildHandledFailureMessage(
                normalizeOperation(operationName),
                normalizeContext(contextSummary),
                ex,
                String.isBlank(failureReason) ? 'Handled async failure' : failureReason
            )
        );
    }

    public void execute(FinalizerContext finalizerContext) {
        if (finalizerContext == null) {
            LoggingUtil.warn(
                'Async finalizer executed with null context. '
                + 'Operation=' + operationName
                + ', Context=' + contextSummary
            );
            return;
        }

        ParentJobResult result = finalizerContext.getResult();
        if (result == ParentJobResult.SUCCESS) {
            LoggingUtil.debug(
                'Async queueable completed successfully. '
                + 'Operation=' + operationName
                + ', JobId=' + String.valueOf(finalizerContext.getAsyncApexJobId())
                + ', Context=' + contextSummary
            );
            return;
        }

        LoggingUtil.error(
            buildFailureTelemetryMessage(
                operationName,
                finalizerContext.getAsyncApexJobId(),
                result,
                finalizerContext.getException(),
                contextSummary
            )
        );
    }

    @TestVisible
    private static String buildFailureTelemetryMessage(
        String operationName,
        Id asyncApexJobId,
        ParentJobResult result,
        Exception ex,
        String contextSummary
    ) {
        return 'Async queueable failed. '
            + 'Operation=' + normalizeOperation(operationName)
            + ', JobId=' + String.valueOf(asyncApexJobId)
            + ', Result=' + String.valueOf(result)
            + ', Context=' + normalizeContext(contextSummary)
            + ', Exception=' + summarizeException(ex);
    }

    @TestVisible
    private static String buildHandledFailureMessage(
        String operationName,
        String contextSummary,
        Exception ex,
        String failureReason
    ) {
        return String.valueOf(failureReason)
            + '. Operation=' + normalizeOperation(operationName)
            + ', Context=' + normalizeContext(contextSummary)
            + ', Exception=' + summarizeException(ex);
    }

    @TestVisible
    private static String summarizeException(Exception ex) {
        if (ex == null) {
            return 'None';
        }
        return ex.getTypeName() + ': ' + ex.getMessage();
    }

    private static String normalizeOperation(String operationName) {
        return String.isBlank(operationName) ? UNKNOWN_OPERATION : operationName.trim();
    }

    private static String normalizeContext(String contextSummary) {
        return String.isBlank(contextSummary) ? UNKNOWN_CONTEXT : contextSummary.trim();
    }
}
