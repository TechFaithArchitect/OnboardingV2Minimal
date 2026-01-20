@isTest
public class TestRecipientGroupFactory {

    public static Recipient_Group__c create(Boolean doInsert, String groupType) {
        Recipient_Group__c recipientGroup = new Recipient_Group__c(
            Name = 'Test Recipient Group ' + DateTime.now().getTime(),
            Group_Type__c = groupType,
            Is_Active__c = true
        );
        if (doInsert) insert recipientGroup;
        return recipientGroup;
    }

    // Overload with default value
    public static Recipient_Group__c create(Boolean doInsert) {
        return create(doInsert, 'User'); // default to valid Group_Type__c
    }
}