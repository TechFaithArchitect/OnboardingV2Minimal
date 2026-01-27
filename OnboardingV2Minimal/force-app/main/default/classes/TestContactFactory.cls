@isTest
public class TestContactFactory {

    public static Contact create(String firstName, String lastName, Account account, Boolean doInsert) {
        String uniqueSuffix = String.valueOf(DateTime.now().getTime()) + 
                              Math.mod(Crypto.getRandomInteger(), 1000);

        Contact contact = new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = account.Id,
            Email = lastName + '+' + uniqueSuffix + '@yopmail.com',
            Time_zone__c = 'America/New_York',
            MailingPostalCode = '672001',
            MailingCity = 'City 1',
            MailingStreet = 'StreetTest',
            MailingCountry = 'United States',
            MailingState = 'Texas'
        );

        TestDataFactoryUtil.maybeInsert(contact, doInsert);
        return contact;
    }
}