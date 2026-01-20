@isTest
private class RecipientGroupEmailRequestDTOTest {

    @isTest
    static void testRecipientGroupEmailRequestDTO_CanBeInstantiated() {
        // Test that the DTO can be instantiated and its field can be set
        RecipientGroupEmailRequestDTO dto = new RecipientGroupEmailRequestDTO();
        
        Id testId = TestDataFactory.createVendor(true).Id;
        dto.vendorProgramId = testId;
        
        System.assertEquals(testId, dto.vendorProgramId, 'Vendor Program ID should be set correctly');
    }

    @isTest
    static void testRecipientGroupEmailRequestDTO_WithNullId() {
        // Test that the DTO can handle null values
        RecipientGroupEmailRequestDTO dto = new RecipientGroupEmailRequestDTO();
        dto.vendorProgramId = null;
        
        System.assertEquals(null, dto.vendorProgramId, 'Vendor Program ID can be null');
    }
}