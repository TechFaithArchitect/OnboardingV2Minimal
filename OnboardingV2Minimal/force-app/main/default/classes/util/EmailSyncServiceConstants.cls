/**
 * Constants used by email sync services.
 * Follows the "Avoid Magic Numbers" principle.
 */
public with sharing class EmailSyncServiceConstants {
    
    // Time conversion constant
    public static final Decimal MILLISECONDS_TO_SECONDS = 1000.0;
    
    // Prevent instantiation
    private EmailSyncServiceConstants() {
        System.assert(false, 'EmailSyncServiceConstants class should not be instantiated');
    }
}