@isTest
public class TestVendorProgramFactory {

    public static TestDataFactoryWrapper.VendorCustomizationWrapper createVendorWithCustomization(Boolean doInsert) {
        Vendor__c vendor = createVendor(doInsert);
        Vendor_Customization__c customization = createVendorCustomization(
            vendor, 'Draft', true, null, doInsert
        );
        return new TestDataFactoryWrapper.VendorCustomizationWrapper(vendor, customization);
    }

    public static Vendor__c createVendor(Boolean doInsert) {
        return TestVendorFactory.createVendor(doInsert);
    }

    public static Vendor_Customization__c createCustomizationOnly(
        Vendor__c vendor, String status, Boolean isActive, Id parentVersionId, Boolean doInsert
    ) {
        return createVendorCustomization(vendor, status, isActive, parentVersionId, doInsert);
    }

    public static Vendor_Customization__c createVendorCustomization(
        Vendor__c vendor, String status, Boolean isActive, Id parentVersionId, Boolean doInsert
    ) {
        return TestVendorFactory.createVendorCustomization(vendor, status, isActive, parentVersionId, doInsert);
    }

    public static Vendor_Customization__c createRootAndActiveChildCustomization(Vendor__c vendor, Boolean doInsert) {
        Vendor_Customization__c rootCustomization = createVendorCustomization(vendor, 'Draft', true, null, doInsert);
        Vendor_Customization__c activeChild = createVendorCustomization(vendor, 'Active', true, rootCustomization.Id, doInsert);
        return activeChild;
    }

    public class VersionChainWrapper {
        public Vendor__c vendor;
        public Vendor_Customization__c parentVersion;
        public Vendor_Customization__c childVersion;

        public VersionChainWrapper(Vendor__c vendor, Vendor_Customization__c parent, Vendor_Customization__c child) {
            this.vendor = vendor;
            this.parentVersion = parent;
            this.childVersion = child;
        }
    }

    public static VersionChainWrapper createVersionChain(Boolean doInsert) {

        Vendor__c vendor = createVendor(doInsert); 

        Vendor_Customization__c parent = createVendorCustomization(
            vendor,
            'Approved',
            true,
            null,
            doInsert
        );

        Vendor_Customization__c child = createVendorCustomization(
            vendor,
            'Active',
            true,
            parent.Id,
            doInsert
        );

        return new VersionChainWrapper(vendor, parent, child);
    }

}