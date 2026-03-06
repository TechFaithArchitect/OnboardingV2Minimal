@isTest
private class VendorOnboardingServiceTest {
    private static final Set<String> NON_BLOCKING_STATUSES = new Set<String>{
        'DENIED',
        'CANCELED',
        'CANCELLED'
    };

    @isTest
    static void testGetEligibleVendorsReturnsCorrectDTOs() {
        // Setup account
        Account acct = new Account(Name = 'Service Test Account');
        insert acct;

        // Setup vendor
        Vendor__c vendor = new Vendor__c(Name = 'Service Vendor', Active__c = true);
        insert vendor;

        // Setup customization
        Vendor_Customization__c vc = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Retail_Option__c = 'National Agent',
            Business_Vertical__c = 'D2D'
        );
        insert vc;

        Test.startTest();
        List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(new List<Id>{ acct.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one result list for one account');
        System.assertEquals(1, result[0].size(), 'Should return one vendor option');
        
        VendorOptionDTO dto = result[0][0];
        System.assertEquals(vendor.Id, dto.vendorId);
        System.assertEquals('Service Vendor', dto.vendorName);
        System.assertEquals('National Agent', dto.retailOption);
        System.assert(dto.businessVerticals.contains('D2D'));
    }

    @isTest
    static void testGetEligibleVendorsWithOnboardedVendorReturnsNone() {
        // Setup account and vendor
        Account acct = new Account(Name = 'Already Onboarded Account');
        insert acct;

        Vendor__c vendor = new Vendor__c(Name = 'Already Onboarded Vendor', Active__c = true);
        insert vendor;

        Vendor_Customization__c vc = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Retail_Option__c = 'National Agent',
            Business_Vertical__c = 'D2D'
        );
        insert vc;

        // Use a blocking status so this onboarding record is considered ineligible.
        String blockingStatus = pickBlockingStatus(getPicklistValues(Onboarding__c.Onboarding_Status__c));
        insert new Onboarding__c(
            Account__c = acct.Id,
            Vendor_Customization__c = vc.Id,
            Onboarding_Status__c = blockingStatus
        );

        Test.startTest();
        List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(new List<Id>{ acct.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one list');
        System.assertEquals(0, result[0].size(), 'Should not return onboarded vendors');
    }

    @isTest
    static void testGetEligibleVendorsHandlesEmptyList() {
        Test.startTest();
        List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for no accounts');
    }

    private static List<String> getPicklistValues(Schema.SObjectField fieldToken) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : fieldToken.getDescribe().getPicklistValues()) {
            values.add(entry.getValue());
        }
        return values;
    }

    private static String pickBlockingStatus(List<String> statuses) {
        for (String status : statuses) {
            if (String.isBlank(status)) {
                continue;
            }

            String normalized = status.trim().toUpperCase();
            if (!NON_BLOCKING_STATUSES.contains(normalized)) {
                return status;
            }
        }

        return statuses.isEmpty() ? null : statuses[0];
    }
}
