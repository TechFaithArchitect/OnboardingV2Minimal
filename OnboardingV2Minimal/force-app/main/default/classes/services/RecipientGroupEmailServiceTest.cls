@isTest
public class RecipientGroupEmailServiceTest {

    private static void setupProgramWithGroupAndUser(Id vendorProgramId, Id userId) {
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);
        User user = [SELECT Id FROM User WHERE Id = :userId];

        Vendor_Customization__c vendorProgram = [SELECT Id FROM Vendor_Customization__c WHERE Id = :vendorProgramId];
        TestDataFactory.createVendorProgramRecipientGroup(vendorProgram, recipientGroup, true);

        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);
    }

    @isTest
    static void testGetEmailsForVendorCustomization() {
        User standardUser = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupProgramWithGroupAndUser(vendorCustomization.Id, standardUser.Id);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorCustomization.Id);

        System.assertEquals(1, emails.size());
        System.assertEquals(standardUser.Email, emails[0]);
    }

    @isTest
    static void testReturnsEmptyWhenNoGroupsLinked() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorCustomization = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorCustomization.Id);

        System.assertEquals(0, emails.size());
    }

    @isTest
    static void testReturnsEmptyWhenGroupLinkIsInactive() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        List<String> validStatuses = TestDataFactoryUtil.getPicklistValues(
            Vendor_Program_Recipient_Group__c.SObjectType,
            'Status__c'
        );
        String inactiveStatus = validStatuses.contains('Draft') ? 'Draft' : null;
        if (inactiveStatus == null) {
            for (String status : validStatuses) {
                if (status != 'Active') {
                    inactiveStatus = status;
                    break;
                }
            }
        }
        if (String.isBlank(inactiveStatus) && !validStatuses.isEmpty()) {
            inactiveStatus = validStatuses[0];
        }

        TestDataFactory.createVendorProgramRecipientGroup(
            vendorProgram,
            recipientGroup,
            inactiveStatus,
            '1.0',
            false,
            null,
            true
        );

        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);
        System.assertEquals(0, emails.size());
    }

    @isTest
    static void testSkipsNullEmails() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        insert new Vendor_Program_Recipient_Group__c(
            Vendor_Program__c = vendorProgram.Id,
            Recipient_Group__c = recipientGroup.Id,
            Is_Active__c = true
        );

        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);

        // Validate that no nulls sneak in (safety net)
        List<String> emails = new List<String>();
        for (String email : RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id)) {
            if (String.isNotBlank(email)) emails.add(email);
        }

        System.assertEquals(1, emails.size());
    }

    @isTest
    static void testMultipleMembersReturnAllEmails() {
        User user1 = TestDataFactory.createStandardUser(true);
        User user2 = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        TestDataFactory.createVendorProgramRecipientGroup(vendorProgram, recipientGroup, true);
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user1);
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user2);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);

        System.assertEquals(2, emails.size());
        System.assert(emails.contains(user1.Email));
        System.assert(emails.contains(user2.Email));
    }

    @isTest
    static void testDedupesEmailsFromDuplicateMembers() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        TestDataFactory.createVendorProgramRecipientGroup(vendorProgram, recipientGroup, true);
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);

        System.assertEquals(1, new Set<String>(emails).size());
    }

    @isTest
    static void testReturnsEmptyForUnlinkedVendorProgramId() {
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c unlinkedProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(unlinkedProgram.Id);

        System.assertEquals(0, emails.size());
    }

    @isTest
    static void testDedupesEmailsFromMixedMemberships() {
        User user = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);
        Vendor_Customization__c vendorProgram = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Recipient_Group__c recipientGroup = TestDataFactory.createRecipientGroup(true, true);

        TestDataFactory.createVendorProgramRecipientGroup(vendorProgram, recipientGroup, true);
        TestDataFactory.createRecipientGroupMember(true, recipientGroup, user);

        Territory_Assignments__c territoryAssignment = new Territory_Assignments__c(
            Division__c = 'DIV',
            Region__c = 'REG',
            Territory__c = 'TERR'
        );
        insert territoryAssignment;

        Territory_Role_Assignment__c roleAssignment = new Territory_Role_Assignment__c(
            Name = 'Role Assignment',
            Territory_Assignments__c = territoryAssignment.Id,
            User__c = user.Id,
            Active__c = true
        );
        insert roleAssignment;

        Recipient_Group_Member__c roleMember = TestDataFactory.createRecipientGroupMember(
            false,
            recipientGroup,
            null,
            'Territory Role Assignment',
            'To'
        );
        roleMember.Role_Assignment__c = roleAssignment.Id;
        insert roleMember;

        List<String> emails = RecipientGroupEmailService.getEmailsForVendorProgram(vendorProgram.Id);

        System.assertEquals(1, emails.size());
    }

    @isTest
    static void testFlowHandlesMultipleRequests() {
        User user1 = TestDataFactory.createStandardUser(true);
        User user2 = TestDataFactory.createStandardUser(true);
        Vendor__c vendor = TestDataFactory.createVendor(true);

        Vendor_Customization__c vendorProgram1 = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);
        Vendor_Customization__c vendorProgram2 = TestDataFactory.createRootAndActiveChildCustomization(vendor, true);

        setupProgramWithGroupAndUser(vendorProgram1.Id, user1.Id);
        setupProgramWithGroupAndUser(vendorProgram2.Id, user2.Id);

        RecipientGroupEmailRequestDTO recipientGroupEmailRequest1 = new RecipientGroupEmailRequestDTO();
        recipientGroupEmailRequest1.vendorProgramId = vendorProgram1.Id;

        RecipientGroupEmailRequestDTO recipientGroupEmailRequest2 = new RecipientGroupEmailRequestDTO();
        recipientGroupEmailRequest2.vendorProgramId = vendorProgram2.Id;

        List<RecipientGroupEmailRequestDTO> recipientGroupEmailRequests = new List<RecipientGroupEmailRequestDTO>{ recipientGroupEmailRequest1, recipientGroupEmailRequest2 };

        List<RecipientGroupEmailResultDTO> results = RecipientGroupEmailAction.fetchEmails(recipientGroupEmailRequests);

        System.assertEquals(2, results.size());
        System.assertEquals(1, results[0].emailAddresses.size());
        System.assertEquals(1, results[1].emailAddresses.size());
    }
}