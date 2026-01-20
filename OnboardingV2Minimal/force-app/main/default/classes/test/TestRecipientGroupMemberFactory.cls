@isTest
public class TestRecipientGroupMemberFactory {

    public static Recipient_Group_Member__c create(Boolean doInsert, User user) {
        if (user == null) {
            user = TestUserFactory.createStandardUser(doInsert);
        }

        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(doInsert);

        Recipient_Group_Member__c recipientGroupMember = new Recipient_Group_Member__c(
            Recipient_Group__c = recipientGroup.Id,
            Member_Type__c = 'User',
            Recipient_Type__c = 'To',
            Recipient_User__c = user.Id
        );

        if (doInsert) insert recipientGroupMember;
        return recipientGroupMember;
    }
}