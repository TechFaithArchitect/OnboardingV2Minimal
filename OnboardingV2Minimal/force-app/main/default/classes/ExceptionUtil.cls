public class ExceptionUtil {
    private static final String DEFAULT_DOMAIN_MESSAGE = 'Request could not be completed.';
    private static final String DEFAULT_UNEXPECTED_MESSAGE =
        'Something went wrong while processing your request.';

    public static void publishException(String typeName, Integer lineNumber, String message, String stackTrace) {
        Error_Alert__e pe = new Error_Alert__e();
        pe.Type_Name__c = typeName;
        pe.Line_Number__c = lineNumber;
        pe.Message__c = message;
        pe.Stack_Trace__c = stackTrace;
        EventBus.publish(pe);
    }

    public static void publishFSLException(String type, String provider, String component, String error) {
        FSL_Error_Alert__e event = new FSL_Error_Alert__e();
        event.Type__c = type;
        event.Provider__c = provider;
        event.Component__c = component;
        event.Error__c = error;
        EventBus.publish(event);
    }

    public static Error_Alert__e prepareException(String typeName, Integer lineNumber, String message, String stackTrace) {
        Error_Alert__e pe = new Error_Alert__e();
        pe.Type_Name__c = typeName;
        pe.Line_Number__c = lineNumber;
        pe.Message__c = message;
        pe.Stack_Trace__c = stackTrace;
        return pe;
    }

    public static void publishExceptions(List<Error_Alert__e> errorAlerts) {
        EventBus.publish(errorAlerts);
    }

    public static AuraHandledException domainError(
        String contextLabel,
        OnboardingDomainException domainException
    ) {
        String userMessage =
            domainException == null || String.isBlank(domainException.getMessage())
                ? DEFAULT_DOMAIN_MESSAGE
                : domainException.getMessage();
        if (domainException != null && !String.isBlank(domainException.getMessage())) {
            LoggingUtil.warn(contextLabel + ': ' + domainException.getMessage());
        }
        return new AuraHandledException(userMessage);
    }

    public static AuraHandledException unexpectedAuraError(
        String contextLabel,
        Exception cause,
        String userMessage
    ) {
        return new AuraHandledException(
            unexpectedUserMessage(contextLabel, cause, userMessage)
        );
    }

    public static String unexpectedUserMessage(
        String contextLabel,
        Exception cause,
        String userMessage
    ) {
        String referenceCode = buildReferenceCode();
        String resolvedUserMessage = String.isBlank(userMessage)
            ? DEFAULT_UNEXPECTED_MESSAGE
            : userMessage;

        String exceptionType = cause == null ? 'UnknownException' : cause.getTypeName();
        String exceptionMessage = cause == null ? 'No exception message.' : cause.getMessage();
        String stackTrace = cause == null ? '' : cause.getStackTraceString();

        LoggingUtil.error(
            contextLabel +
            ' [' + referenceCode + '] ' +
            exceptionType + ': ' + exceptionMessage +
            ' | stack=' + stackTrace
        );

        return resolvedUserMessage + ' Reference: ' + referenceCode;
    }

    @TestVisible
    private static String buildReferenceCode() {
        String timeComponent = DateTime.now().formatGMT('yyyyMMddHHmmssSSS');
        String randomComponent = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        if (String.isBlank(randomComponent)) {
            randomComponent = '000000';
        }
        if (randomComponent.length() > 6) {
            randomComponent = randomComponent.substring(randomComponent.length() - 6);
        }
        return 'ONB-' + timeComponent + '-' + randomComponent.leftPad(6, '0');
    }
}
