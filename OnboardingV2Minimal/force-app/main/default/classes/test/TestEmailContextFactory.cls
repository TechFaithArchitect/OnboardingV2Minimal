@isTest
public class TestEmailContextFactory {

    public static TestDataFactoryWrapper.EmailTestContextWrapper create(Boolean doInsert) {
        // Create Account + Contact using TestDataFactory
        Account account = TestDataFactory.createAccount('EmailAcc', doInsert);
        Contact contact = TestDataFactory.createContact('Email', 'User', doInsert, account);

        // Create Template using TestDataFactory
        Communication_Template__c template = TestDataFactory.createCommTemplate(doInsert);

        // Create Vendor and Vendor Program for Onboarding
        Vendor__c vendor = TestDataFactory.createVendor(doInsert);
        Vendor_Customization__c vendorProgram = TestDataFactory.createVendorCustomization(
            vendor, 'Active', true, null, doInsert
        );

        // Create Onboarding using TestDataFactory
        Onboarding__c onboarding = TestDataFactory.createOnboarding(account, vendorProgram, doInsert);

        return new TestDataFactoryWrapper.EmailTestContextWrapper(
            account, contact, template, onboarding
        );
    }
}