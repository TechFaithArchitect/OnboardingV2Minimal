@isTest
public class TestProfileFactory {

    public static Profile getProfileByName(String profileName) {
        return [SELECT Id, Name FROM Profile WHERE Name = :profileName LIMIT 1];
    }

    public static User createUserWithProfile(String profileName, String alias, Boolean doInsert) {
        Profile profile = getProfileByName(profileName);

        User user = new User(
            FirstName = 'Test',
            LastName = 'ProfileUser',
            Email = alias + '@test.com',
            Username = alias + '@test.com',
            Alias = alias,
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