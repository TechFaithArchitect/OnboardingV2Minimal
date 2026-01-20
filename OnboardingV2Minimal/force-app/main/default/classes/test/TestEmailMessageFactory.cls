@isTest
public class TestEmailMessageFactory {

    public static EmailMessage create(Boolean doInsert) {
        EmailMessage emailMessage = new EmailMessage(
            Subject = 'Test Subject',
            ToAddress = 'test@example.com',
            FromAddress = 'noreply@example.com',
            TextBody = 'This is a test email.',
            Status = '3'
        );

        if (doInsert) insert emailMessage;
        return emailMessage;
    }
}