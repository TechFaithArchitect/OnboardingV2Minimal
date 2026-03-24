/**
 * Lightweight logging helper to centralize debug formatting.
 */
public with sharing class LoggingUtil {
    private static final Integer LEVEL_ERROR = 0;
    private static final Integer LEVEL_WARN = 1;
    private static final Integer LEVEL_INFO = 2;
    private static final Integer LEVEL_DEBUG = 3;

    private static final Boolean DEFAULT_LOGGING_ENABLED = true;
    private static final Integer DEFAULT_LOG_LEVEL = LEVEL_WARN;
    private static final Boolean DEFAULT_REDACT_PII = true;
    private static final String DEFAULT_CONFIG_DEVELOPER_NAME = 'Default';

    private static Boolean configLoaded = false;
    private static Boolean cachedLoggingEnabled = DEFAULT_LOGGING_ENABLED;
    private static Integer cachedVerbosityLevel = LEVEL_WARN;
    private static Boolean cachedRedactionEnabled = true;

    @TestVisible
    private static Boolean testLoggingEnabledOverride;
    @TestVisible
    private static Integer testVerbosityLevelOverride;
    @TestVisible
    private static Boolean testRedactionEnabledOverride;

    public static void info(String msg) {
        log(LEVEL_INFO, LoggingLevel.INFO, msg);
    }

    public static void warn(String msg) {
        log(LEVEL_WARN, LoggingLevel.WARN, msg);
    }

    public static void error(String msg) {
        log(LEVEL_ERROR, LoggingLevel.ERROR, msg);
    }

    public static void debug(String msg) {
        log(LEVEL_DEBUG, LoggingLevel.DEBUG, msg);
    }

    private static String prefix() {
        return '[Onboarding] ';
    }

    private static void log(Integer severityLevel, LoggingLevel platformLevel, String msg) {
        if (!shouldLog(severityLevel)) {
            return;
        }
        System.debug(platformLevel, prefix() + sanitize(msg));
    }

    private static Boolean shouldLog(Integer severityLevel) {
        return isLoggingEnabled() && severityLevel <= getVerbosityLevel();
    }

    private static Boolean isLoggingEnabled() {
        if (testLoggingEnabledOverride != null) {
            return testLoggingEnabledOverride;
        }
        ensureConfigLoaded();
        return cachedLoggingEnabled;
    }

    private static Integer getVerbosityLevel() {
        if (testVerbosityLevelOverride != null) {
            return testVerbosityLevelOverride;
        }
        ensureConfigLoaded();
        return cachedVerbosityLevel;
    }

    private static Boolean shouldRedactPii() {
        if (testRedactionEnabledOverride != null) {
            return testRedactionEnabledOverride;
        }
        ensureConfigLoaded();
        return cachedRedactionEnabled;
    }

    private static void ensureConfigLoaded() {
        if (configLoaded) {
            return;
        }

        try {
            List<Onboarding_Logging_Config__mdt> settings = [
                SELECT Enabled__c, Minimum_Level__c, Redact_PII__c
                FROM Onboarding_Logging_Config__mdt
                WHERE DeveloperName = :DEFAULT_CONFIG_DEVELOPER_NAME
                LIMIT 1
            ];
            if (!settings.isEmpty()) {
                Onboarding_Logging_Config__mdt setting = settings[0];
                cachedLoggingEnabled = setting.Enabled__c == null
                    ? DEFAULT_LOGGING_ENABLED
                    : setting.Enabled__c;
                cachedVerbosityLevel = parseVerbosityLevel(setting.Minimum_Level__c);
                cachedRedactionEnabled = setting.Redact_PII__c == null
                    ? DEFAULT_REDACT_PII
                    : setting.Redact_PII__c;
            } else {
                setDefaults();
            }
        } catch (Exception ex) {
            setDefaults();
            System.debug(
                LoggingLevel.WARN,
                prefix() +
                'Logging config not available, using defaults. ' +
                ex.getTypeName() +
                ': ' +
                ex.getMessage()
            );
        }
        configLoaded = true;
    }

    private static void setDefaults() {
        cachedLoggingEnabled = DEFAULT_LOGGING_ENABLED;
        cachedVerbosityLevel = DEFAULT_LOG_LEVEL;
        cachedRedactionEnabled = DEFAULT_REDACT_PII;
    }

    /**
     * Redacts common PII patterns before persisting diagnostics (e.g. Error_Log__c).
     */
    public static String redactPii(String msg) {
        return sanitize(msg);
    }

    private static String sanitize(String msg) {
        String safe = msg == null ? 'null' : msg;
        if (!shouldRedactPii()) {
            return safe;
        }

        safe = safe.replaceAll(
            '(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}',
            '[REDACTED_EMAIL]'
        );
        safe = safe.replaceAll(
            '(?:\\+?1[-.\\s]?)?\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}',
            '[REDACTED_PHONE]'
        );
        safe = safe.replaceAll(
            '\\b\\d{3}-\\d{2}-\\d{4}\\b',
            '[REDACTED_SSN]'
        );
        safe = safe.replaceAll(
            '(?i)(password|token|secret|auth|api[_-]?key)\\s*[:=]\\s*[^,;\\s]+',
            '[REDACTED_SECRET]'
        );
        return safe;
    }

    @TestVisible
    private static void setTestLoggingEnabled(Boolean enabled) {
        testLoggingEnabledOverride = enabled;
    }

    @TestVisible
    private static void setTestVerbosity(String verbosityName) {
        testVerbosityLevelOverride = parseVerbosityLevel(verbosityName);
    }

    @TestVisible
    private static void setTestRedactionEnabled(Boolean enabled) {
        testRedactionEnabledOverride = enabled;
    }

    @TestVisible
    private static Boolean shouldLogForTest(String levelName) {
        return shouldLog(parseVerbosityLevel(levelName));
    }

    @TestVisible
    private static String sanitizeForTest(String msg) {
        return sanitize(msg);
    }

    @TestVisible
    private static void resetTestOverrides() {
        testLoggingEnabledOverride = null;
        testVerbosityLevelOverride = null;
        testRedactionEnabledOverride = null;
        configLoaded = false;
        setDefaults();
    }

    private static Integer parseVerbosityLevel(String levelName) {
        if (String.isBlank(levelName)) {
            return LEVEL_WARN;
        }
        String normalized = levelName.trim().toUpperCase();
        if (normalized == 'ERROR') {
            return LEVEL_ERROR;
        }
        if (normalized == 'WARN' || normalized == 'WARNING') {
            return LEVEL_WARN;
        }
        if (normalized == 'INFO') {
            return LEVEL_INFO;
        }
        if (normalized == 'DEBUG') {
            return LEVEL_DEBUG;
        }
        return LEVEL_WARN;
    }
}
