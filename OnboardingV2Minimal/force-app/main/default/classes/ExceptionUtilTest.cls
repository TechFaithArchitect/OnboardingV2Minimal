@isTest
public class ExceptionUtilTest {
    @isTest
    static void publishException_positive() {
        Test.startTest();
        ExceptionUtil.publishException('ExceptionUtil', 15, 'Test message', 'Test stackTrace String');
        Test.getEventBus().deliver();
        Test.stopTest();
        List<PV_Error_Log__c> lst_Exception = [SELECT Id FROM PV_Error_Log__c WHERE Type_Name__c = 'ExceptionUtil'];
        System.assert(!lst_Exception.isEmpty(), 'ErrorLog__c records');
    }

    @isTest
    static void publishExceptionsTest() {
        List<Error_Alert__e> errorAlerts = new List<Error_Alert__e>();
        Error_Alert__e errorAlert = ExceptionUtil.prepareException('ExceptionUtil', 15, 'Test message', 'Test stackTrace String');
        errorAlerts.add(errorAlert);

        Test.startTest();
        ExceptionUtil.publishExceptions(errorAlerts);
        Test.getEventBus().deliver();
        Test.stopTest();

        List<PV_Error_Log__c> lst_Exception = [SELECT Id FROM PV_Error_Log__c WHERE Type_Name__c = 'ExceptionUtil'];
        System.assert(!lst_Exception.isEmpty(), 'ErrorLog__c records');
    }

    @isTest
    static void publishFSLExceptionTest() {
        Test.startTest();
        ExceptionUtil.publishFSLException('Internal Error', 'FSL', ExceptionUtilTest.class.getName(), 'Test error message');
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Component__c = :ExceptionUtilTest.class.getName()];
        Assert.isTrue(!errorLogs.isEmpty(), 'No logs created in Error_Log__c.');
    }

    @isTest
    static void domainError_returnsExpectedMessage() {
        OnboardingDomainException domainException =
            new OnboardingDomainException('Readable validation message');

        AuraHandledException handled = ExceptionUtil.domainError(
            'ExceptionUtilTest.domainError_returnsExpectedMessage',
            domainException
        );

        System.assertNotEquals(null, handled, 'Expected AuraHandledException instance.');
        System.assertNotEquals(
            null,
            handled.getMessage(),
            'Expected a user-facing message payload.'
        );
    }

    @isTest
    static void unexpectedUserMessage_includesReferenceCode() {
        Exception captured;
        try {
            Integer zero = 0;
            Integer fail = 1 / zero;
            System.assertEquals(0, fail);
        } catch (Exception ex) {
            captured = ex;
        }

        String userMessage = ExceptionUtil.unexpectedUserMessage(
            'ExceptionUtilTest.unexpectedUserMessage_includesReferenceCode',
            captured,
            'Unable to process request.'
        );

        System.assert(
            userMessage.contains('Unable to process request.'),
            'Expected caller-facing message prefix.'
        );
        System.assert(
            userMessage.contains('Reference: ONB-'),
            'Expected reference code suffix for supportability.'
        );
    }
}
