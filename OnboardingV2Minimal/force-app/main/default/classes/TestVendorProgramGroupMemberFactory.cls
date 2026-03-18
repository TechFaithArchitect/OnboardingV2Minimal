@isTest
public class TestVendorProgramGroupMemberFactory {

    public static Vendor_Program_Group_Member__c create(Boolean doInsert,
                                                        Vendor_Program_Group__c vendorProgramGroup,
                                                        Vendor_Customization__c vendorProgram,
                                                        Boolean isTarget) {
        Vendor_Program_Group_Member__c vendorProgramGroupMember = new Vendor_Program_Group_Member__c(
            Vendor_Program_Group__c = vendorProgramGroup != null ? vendorProgramGroup.Id : null,
            Required_Program__c = vendorProgram != null ? vendorProgram.Id : null,
            Is_Target__c = isTarget,
            Active__c = true
        );
        TestDataFactoryUtil.maybeInsert(vendorProgramGroupMember, doInsert);
        return vendorProgramGroupMember;
    }

    public static Vendor_Program_Group_Member__c create(Boolean doInsert) {
        return create(doInsert, null, null, true);
    }
}