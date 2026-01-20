@isTest
private class VendorProgramReqGroupTriggerHandlerTest {

    @isTest
    static void assignsSequentialVersionsWithinBulkInsert() {
        Vendor_Program_Requirement_Group__c existing = new Vendor_Program_Requirement_Group__c(
            Name = 'Bulk Group',
            Version__c = 'v2',
            Status__c = 'Active',
            Active__c = true
        );
        insert existing;

        Vendor_Program_Requirement_Group__c g1 = new Vendor_Program_Requirement_Group__c(
            Name = 'Bulk Group',
            Status__c = 'Active',
            Active__c = true
        );
        Vendor_Program_Requirement_Group__c g2 = new Vendor_Program_Requirement_Group__c(
            Name = 'Bulk Group',
            Status__c = 'Active',
            Active__c = true
        );
        Vendor_Program_Requirement_Group__c gOther = new Vendor_Program_Requirement_Group__c(
            Name = 'Other Group',
            Status__c = 'Active',
            Active__c = true
        );

        Test.startTest();
        insert new List<Vendor_Program_Requirement_Group__c>{ g1, g2, gOther };
        Test.stopTest();

        Map<Id, Vendor_Program_Requirement_Group__c> inserted = new Map<Id, Vendor_Program_Requirement_Group__c>([
            SELECT Version__c, Name
            FROM Vendor_Program_Requirement_Group__c
            WHERE Id IN :new List<Id>{ g1.Id, g2.Id, gOther.Id }
        ]);

        System.assertEquals('v3', inserted.get(g1.Id).Version__c, 'First new record should pick up next version');
        System.assertEquals('v4', inserted.get(g2.Id).Version__c, 'Second record in same txn should increment further');
        System.assertEquals('v1', inserted.get(gOther.Id).Version__c, 'Unrelated name should start at v1');
    }

    @isTest
    static void keepsProvidedVersionValue() {
        Vendor_Program_Requirement_Group__c provided = new Vendor_Program_Requirement_Group__c(
            Name = 'Explicit Group',
            Version__c = 'v7',
            Status__c = 'Active',
            Active__c = true
        );
        Vendor_Program_Requirement_Group__c autoVersioned = new Vendor_Program_Requirement_Group__c(
            Name = 'Explicit Group',
            Status__c = 'Active',
            Active__c = true
        );

        Test.startTest();
        insert new List<Vendor_Program_Requirement_Group__c>{ provided, autoVersioned };
        Test.stopTest();

        Map<Id, Vendor_Program_Requirement_Group__c> inserted = new Map<Id, Vendor_Program_Requirement_Group__c>([
            SELECT Version__c, Name
            FROM Vendor_Program_Requirement_Group__c
            WHERE Id IN :new List<Id>{ provided.Id, autoVersioned.Id }
        ]);

        System.assertEquals('v7', inserted.get(provided.Id).Version__c, 'Explicit version should be preserved');
        System.assertEquals('v8', inserted.get(autoVersioned.Id).Version__c, 'Auto version should continue after provided value');
    }

    @isTest
    static void skipsWhenOldMapProvided() {
        Vendor_Program_Requirement_Group__c existing = new Vendor_Program_Requirement_Group__c(
            Name = 'Update Scenario',
            Status__c = 'Active',
            Active__c = true
        );
        insert existing;

        Vendor_Program_Requirement_Group__c pendingUpdate = existing.clone(false, true, false, false);
        pendingUpdate.Version__c = null;

        Map<Id, Vendor_Program_Requirement_Group__c> oldMap = new Map<Id, Vendor_Program_Requirement_Group__c>{
            existing.Id => existing
        };

        VendorProgramReqGroupTriggerHandler.handleVersioning(
            new List<Vendor_Program_Requirement_Group__c>{ pendingUpdate },
            oldMap
        );

        System.assertEquals(null, pendingUpdate.Version__c, 'Should not version when oldMap indicates update context');
    }

    @isTest
    static void noNamesDoesNothing() {
        Vendor_Program_Requirement_Group__c noName = new Vendor_Program_Requirement_Group__c(
            Name = null,
            Status__c = 'Active',
            Active__c = true
        );

        VendorProgramReqGroupTriggerHandler.handleVersioning(
            new List<Vendor_Program_Requirement_Group__c>{ noName },
            null
        );

        System.assertEquals(null, noName.Version__c, 'Should leave version blank when no name is provided');
    }

    @isTest
    static void invalidVersionFormatsAreIgnored() {
        // Existing record with invalid version string
        Vendor_Program_Requirement_Group__c badExisting = new Vendor_Program_Requirement_Group__c(
            Name = 'BadFormat',
            Version__c = 'vX',
            Status__c = 'Active',
            Active__c = true
        );
        insert badExisting;

        // New record providing invalid version should also be ignored
        Vendor_Program_Requirement_Group__c providedBad = new Vendor_Program_Requirement_Group__c(
            Name = 'BadFormat',
            Version__c = 'vx',
            Status__c = 'Active',
            Active__c = true
        );
        Vendor_Program_Requirement_Group__c needsAuto = new Vendor_Program_Requirement_Group__c(
            Name = 'BadFormat',
            Status__c = 'Active',
            Active__c = true
        );

        Test.startTest();
        insert new List<Vendor_Program_Requirement_Group__c>{ providedBad, needsAuto };
        Test.stopTest();

        needsAuto = [
            SELECT Version__c
            FROM Vendor_Program_Requirement_Group__c
            WHERE Id = :needsAuto.Id
        ];

        // Since invalid versions are ignored, numbering should start at v1 for the new records
        System.assertEquals('v1', needsAuto.Version__c, 'Invalid formats should not affect auto numbering');
    }
}