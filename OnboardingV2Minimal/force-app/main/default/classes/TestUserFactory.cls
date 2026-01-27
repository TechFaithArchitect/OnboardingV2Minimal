@isTest
public class TestUserFactory {

    public static User createTechnicianUser(Boolean doInsert, Contact contact) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = '#FS Service Resource (Partner Community)' LIMIT 1].Id;
        String unique = String.valueOf(DateTime.now().getTime());

        User user = new User(
            FirstName = 'Test_',
            LastName = 'User',
            PortalRole = 'Manager',
            Email = 'PV_TestDataFactory' + unique + '@hikko.com',
            Alias = 'tst',
            Username = 'PV_TestDataFactory' + unique + '@hikko.com',
            CommunityNickname = 'tstuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            PostalCode = '35401',
            ProfileId = profileId,
            ContactId = contact.Id
        );
        TestDataFactoryUtil.maybeInsert(user, doInsert);
        return user;
    }

    public static User createStandardUser(Boolean doInsert) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String unique = String.valueOf(DateTime.now().getTime()) + String.valueOf(Math.mod(Crypto.getRandomInteger(), 10000));

        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'standarduser+' + unique + '@example.com',
            Username = 'standarduser' + unique + '@example.com',
            Alias = 'suser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        TestDataFactoryUtil.maybeInsert(user, doInsert);
        return user;
    }
}