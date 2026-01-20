@isTest
public class TestVendorProgramRequirementGroupFactory {

    public static Vendor_Program_Requirement_Group__c create(Boolean doInsert, String label) {
        Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup = new Vendor_Program_Requirement_Group__c(
            Name = label,
            Status__c = 'Active',
            Active__c = true
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramRequirementGroup, doInsert);
        return vendorProgramRequirementGroup;
    }

    public static Vendor_Program_Requirement_Group__c create(Boolean doInsert) {
        Vendor_Program_Requirement_Group__c vendorProgramRequirementGroup = new Vendor_Program_Requirement_Group__c(
            Name = 'Requirement Group ' + DateTime.now().getTime()
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramRequirementGroup, doInsert);
        return vendorProgramRequirementGroup;
    }
}