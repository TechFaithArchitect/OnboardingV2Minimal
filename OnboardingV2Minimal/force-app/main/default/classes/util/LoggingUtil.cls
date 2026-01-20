/**
 * Lightweight logging helper to centralize debug formatting.
 */
public with sharing class LoggingUtil {
    public static void info(String msg) {
        System.debug(LoggingLevel.INFO, prefix() + msg);
    }

    public static void warn(String msg) {
        System.debug(LoggingLevel.WARN, prefix() + msg);
    }

    public static void error(String msg) {
        System.debug(LoggingLevel.ERROR, prefix() + msg);
    }

    public static void debug(String msg) {
        System.debug(LoggingLevel.DEBUG, prefix() + msg);
    }

    private static String prefix() {
        return '[Onboarding] ';
    }
}