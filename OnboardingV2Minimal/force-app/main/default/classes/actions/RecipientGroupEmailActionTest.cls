@isTest
public class RecipientGroupEmailActionTest {

    private static RecipientGroupEmailRequestDTO buildRequest(Id vendorProgramId) {
        RecipientGroupEmailRequestDTO recipientGroupEmailRequest = new RecipientGroupEmailRequestDTO();
        recipientGroupEmailRequest.vendorProgramId = vendorProgramId;
        return recipientGroupEmailRequest;
    }

    @isTest
    static void testFetchEmailsFromFlow() {
        // Arrange
        User standardUser = TestUserFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestRecipientGroupFactory.create(true, 'Queue');

        TestDataFactory.createVendorProgramRecipientGroup(
            vendorCustomization,
            recipientGroup,
            null, // Use default status
            '1.0',
            true,
            null,
            true
        );

        TestDataFactory.createRecipientGroupMember(true, recipientGroup, standardUser, 'User', 'To');

        // Act
        List<RecipientGroupEmailResultDTO> results = RecipientGroupEmailAction.fetchEmails(
            new List<RecipientGroupEmailRequestDTO>{ buildRequest(vendorCustomization.Id) }
        );

        // Assert
        System.assertEquals(1, results.size(), 'Should return one result object');
        System.assertEquals(1, results[0].emailAddresses.size(), 'Should contain one email address');
        System.assertEquals(standardUser.Email, results[0].emailAddresses[0], 'Should match the user email');
    }

    @isTest
    static void testReturnsEmptyResultDTO() {
        // Arrange
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        List<RecipientGroupEmailRequestDTO> requests = new List<RecipientGroupEmailRequestDTO>{
            buildRequest(vendorCustomization.Id)
        };

        // Act
        List<RecipientGroupEmailResultDTO> results = RecipientGroupEmailAction.fetchEmails(requests);

        // Assert
        System.assertEquals(1, results.size(), 'Should always return 1 result');
        System.assertEquals(0, results[0].emailAddresses.size(), 'Should return 0 emails when no matches');
    }
}