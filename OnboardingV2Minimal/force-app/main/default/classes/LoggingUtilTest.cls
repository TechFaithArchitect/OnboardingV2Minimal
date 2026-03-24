@IsTest
private class LoggingUtilTest {
    @IsTest
    static void redactPii_publicMethod_matchesSanitizeForTest() {
        LoggingUtil.resetTestOverrides();
        LoggingUtil.setTestRedactionEnabled(true);
        String raw = 'Contact support@example.com for help.';
        String viaPublic = LoggingUtil.redactPii(raw);
        String viaTestHook = LoggingUtil.sanitizeForTest(raw);
        System.assertEquals(viaTestHook, viaPublic);
    }

    @IsTest
    static void sanitizeForTest_redactsPiiWhenEnabled() {
        LoggingUtil.resetTestOverrides();
        LoggingUtil.setTestLoggingEnabled(true);
        LoggingUtil.setTestRedactionEnabled(true);

        String rawMessage =
            'email=jane.doe@example.com phone=615-555-1212 ssn=123-45-6789 token=abc123';
        String sanitized = LoggingUtil.sanitizeForTest(rawMessage);

        System.assert(!sanitized.contains('jane.doe@example.com'));
        System.assert(!sanitized.contains('615-555-1212'));
        System.assert(!sanitized.contains('123-45-6789'));
        System.assert(!sanitized.contains('abc123'));
        System.assert(sanitized.contains('[REDACTED_EMAIL]'));
        System.assert(sanitized.contains('[REDACTED_PHONE]'));
        System.assert(sanitized.contains('[REDACTED_SSN]'));
        System.assert(sanitized.contains('[REDACTED_SECRET]'));
    }

    @IsTest
    static void sanitizeForTest_leavesPayloadUntouchedWhenDisabled() {
        LoggingUtil.resetTestOverrides();
        LoggingUtil.setTestLoggingEnabled(true);
        LoggingUtil.setTestRedactionEnabled(false);

        String rawMessage = 'email=jane.doe@example.com token=abc123';
        String sanitized = LoggingUtil.sanitizeForTest(rawMessage);

        System.assertEquals(rawMessage, sanitized);
    }

    @IsTest
    static void shouldLogForTest_respectsVerbosityAndToggle() {
        LoggingUtil.resetTestOverrides();
        LoggingUtil.setTestLoggingEnabled(true);
        LoggingUtil.setTestVerbosity('WARN');

        System.assertEquals(true, LoggingUtil.shouldLogForTest('ERROR'));
        System.assertEquals(true, LoggingUtil.shouldLogForTest('WARN'));
        System.assertEquals(false, LoggingUtil.shouldLogForTest('INFO'));
        System.assertEquals(false, LoggingUtil.shouldLogForTest('DEBUG'));

        LoggingUtil.setTestVerbosity('DEBUG');
        System.assertEquals(true, LoggingUtil.shouldLogForTest('INFO'));
        System.assertEquals(true, LoggingUtil.shouldLogForTest('DEBUG'));

        LoggingUtil.setTestLoggingEnabled(false);
        System.assertEquals(false, LoggingUtil.shouldLogForTest('ERROR'));
        System.assertEquals(false, LoggingUtil.shouldLogForTest('DEBUG'));
    }
}
