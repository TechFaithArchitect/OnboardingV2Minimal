@isTest
public class TestTrainingSystemFactory {
    public static Training_System__c create(Boolean doInsert) {
        // Generate a truly unique name by combining timestamp and random number
        // This ensures uniqueness even if validation rule checks against existing records
        String timestamp = String.valueOf(DateTime.now().getTime());
        String randomId = String.valueOf(Math.abs(Crypto.getRandomLong()));
        String uniqueName = 'Test LMS System ' + timestamp + '_' + randomId;
        
        Training_System__c trainingSystem = new Training_System__c(
            Name = uniqueName,
            Active__c = true,
            System_Type__c = 'External'
        );
        if (doInsert) insert trainingSystem;
        return trainingSystem;
    }
}