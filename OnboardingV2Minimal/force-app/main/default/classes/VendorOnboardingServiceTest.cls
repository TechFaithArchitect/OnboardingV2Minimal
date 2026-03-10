@isTest
private class VendorOnboardingServiceTest {
    private static final Set<String> NON_BLOCKING_STATUSES = new Set<String>{
        'DENIED',
        'CANCELED',
        'CANCELLED'
    };
    private static final Set<String> COMPLETED_STATUSES = new Set<String>{
        'COMPLETE',
        'COMPLETED',
        'SETUP COMPLETE',
        'SETUP COMPLETED'
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
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
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
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
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

    @isTest
    static void testBlockingStatusBlocksAllCustomizationsForSameVendorProgram() {
        Account acct = new Account(Name = 'Program Block Account');
        insert acct;

        Vendor__c vendor = new Vendor__c(Name = 'Program Block Vendor', Active__c = true);
        insert vendor;

        List<String> verticalValues = getPicklistValues(Vendor_Customization__c.Business_Vertical__c);
        String verticalValue = verticalValues.isEmpty() ? null : verticalValues[0];

        Vendor_Customization__c fiosOne = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
            Retail_Option__c = 'Fios',
            Business_Vertical__c = verticalValue
        );
        Vendor_Customization__c fiosTwo = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
            Retail_Option__c = 'Fios',
            Business_Vertical__c = verticalValue
        );
        Vendor_Customization__c mobile = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
            Retail_Option__c = 'Mobile FWA',
            Business_Vertical__c = verticalValue
        );
        insert new List<Vendor_Customization__c>{ fiosOne, fiosTwo, mobile };

        insert new Onboarding__c(
            Account__c = acct.Id,
            Vendor_Customization__c = fiosOne.Id,
            Onboarding_Status__c = pickBlockingStatus(getPicklistValues(Onboarding__c.Onboarding_Status__c))
        );

        Test.startTest();
        List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(new List<Id>{ acct.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one account result');
        Set<String> retailOptions = new Set<String>();
        for (VendorOptionDTO option : result[0]) {
            retailOptions.add(option.retailOption);
        }

        System.assert(!retailOptions.contains('Fios'), 'Fios should be hidden across duplicate customizations');
        System.assert(retailOptions.contains('Mobile FWA'), 'Other vendor programs should remain eligible');
    }

    @isTest
    static void testRuleBlocksVendorWhenAnyProgramCompleted() {
        Account acct = new Account(Name = 'Vendor Complete Block Account');
        insert acct;

        Vendor__c vendor = new Vendor__c(Name = 'Rule Driven Vendor', Active__c = true);
        insert vendor;

        List<String> verticalValues = getPicklistValues(Vendor_Customization__c.Business_Vertical__c);
        String verticalValue = verticalValues.isEmpty() ? null : verticalValues[0];

        Vendor_Customization__c fios = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
            Retail_Option__c = 'Fios',
            Business_Vertical__c = verticalValue
        );
        Vendor_Customization__c mobile = new Vendor_Customization__c(
            Vendor__c = vendor.Id,
            Status__c = getActiveVendorCustomizationStatus(),
            Active__c = true,
            Retail_Option__c = 'Mobile FWA',
            Business_Vertical__c = verticalValue
        );
        insert new List<Vendor_Customization__c>{ fios, mobile };

        insert new Onboarding__c(
            Account__c = acct.Id,
            Vendor_Customization__c = fios.Id,
            Onboarding_Status__c = pickCompletedStatus(getPicklistValues(Onboarding__c.Onboarding_Status__c))
        );

        Map<String, VendorOnboardingEligibilityRuleEngine.Rule> rulesByVendorName =
            new Map<String, VendorOnboardingEligibilityRuleEngine.Rule>{
                VendorOnboardingEligibilityRuleEngine.normalizeVendorName(vendor.Name) =>
                    new VendorOnboardingEligibilityRuleEngine.Rule(
                        VendorOnboardingEligibilityRuleEngine.BLOCK_MODE_VENDOR_ANY_COMPLETE,
                        true
                    )
            };
        VendorOnboardingEligibilityRuleEngine.setTestRulesByVendorName(rulesByVendorName);

        try {
            Test.startTest();
            List<List<VendorOptionDTO>> result = VendorOnboardingService.getEligibleVendors(
                new List<Id>{ acct.Id }
            );
            Test.stopTest();

            System.assertEquals(1, result.size(), 'Should return one account result');
            System.assertEquals(
                0,
                result[0].size(),
                'Vendor should be hidden when rule is Block Vendor On Any Complete'
            );
        } finally {
            VendorOnboardingEligibilityRuleEngine.clearTestRulesByVendorName();
        }
    }

    private static List<String> getPicklistValues(Schema.SObjectField fieldToken) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : fieldToken.getDescribe().getPicklistValues()) {
            values.add(entry.getValue());
        }
        return values;
    }

    private static String getActiveVendorCustomizationStatus() {
        List<String> statuses = getPicklistValues(Vendor_Customization__c.Status__c);
        if (statuses.isEmpty()) {
            return null;
        }

        for (String status : statuses) {
            if (String.isBlank(status)) {
                continue;
            }
            String normalized = status.trim().toUpperCase();
            if (normalized == 'ACTIVE' || (normalized.contains('ACTIVE') && !normalized.contains('INACTIVE'))) {
                return status;
            }
        }

        return statuses[0];
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

    private static String pickCompletedStatus(List<String> statuses) {
        for (String status : statuses) {
            if (String.isBlank(status)) {
                continue;
            }

            if (COMPLETED_STATUSES.contains(status.trim().toUpperCase())) {
                return status;
            }
        }

        return statuses.isEmpty() ? null : statuses[0];
    }
}
