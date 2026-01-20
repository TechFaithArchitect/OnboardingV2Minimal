@isTest
public class TestVendorProgramGroupFactory {

    public static Vendor_Program_Group__c create(Boolean doInsert,
                                                 String label,
                                                 Vendor_Program_Requirement_Group__c defaultRequirementGroup,
                                                 Vendor_Program_Group__c parentVendorProgramGroup) {
        Vendor_Program_Group__c vendorProgramGroup = new Vendor_Program_Group__c(
            Label__c = label,
            Active__c = true,
            Logic_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Group__c.SObjectType, 
                'Logic_Type__c'
            ),
            Default_Requirement_Group__c = defaultRequirementGroup != null ? defaultRequirementGroup.Id : null,
            Parent_Group__c = parentVendorProgramGroup != null ? parentVendorProgramGroup.Id : null
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramGroup, doInsert);
        return vendorProgramGroup;
    }

    public static Vendor_Program_Group__c create(Boolean doInsert) {
        Vendor_Program_Group__c vendorProgramGroup = new Vendor_Program_Group__c(
            Name = 'Program Group ' + DateTime.now().getTime(),
            Label__c = 'Test Program Group ' + DateTime.now().getTime(),
            Logic_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Group__c.SObjectType, 
                'Logic_Type__c'
            )
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramGroup, doInsert);
        return vendorProgramGroup;
    }

    public static Vendor_Program_Group__c create(Boolean doInsert, String name) {
        Vendor_Program_Group__c vendorProgramGroup = new Vendor_Program_Group__c(
            Name = name,
            Label__c = name != null ? name : 'Test Program Group ' + DateTime.now().getTime(),
            Logic_Type__c = TestDataFactoryUtil.getDefaultPicklistValue(
                Vendor_Program_Group__c.SObjectType, 
                'Logic_Type__c'
            )
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramGroup, doInsert);
        return vendorProgramGroup;
    }
}