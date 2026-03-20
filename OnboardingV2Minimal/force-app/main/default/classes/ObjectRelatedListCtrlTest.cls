@isTest
private class ObjectRelatedListCtrlTest {
    @testSetup
    static void setupData() {
        Account accOne = new Account(Name = 'ORL Test Account One');
        Account accTwo = new Account(Name = 'ORL Test Account Two');
        insert new List<Account>{ accOne, accTwo };

        insert new List<Contact>{
            new Contact(LastName = 'Zephyr', Email = 'zephyr@example.com', AccountId = accOne.Id),
            new Contact(LastName = 'Alpha', Email = 'alpha@example.com', AccountId = accOne.Id),
            new Contact(LastName = 'Other', Email = 'other@example.com', AccountId = accTwo.Id)
        };
    }

    @isTest
    static void testGetRelatedRecordsWithRelationshipField() {
        Account accOne = [SELECT Id, Name FROM Account WHERE Name = 'ORL Test Account One' LIMIT 1];

        ObjectRelatedListController.QueryConfig config =
            new ObjectRelatedListController.QueryConfig();
        config.objectApiName = 'Contact';
        config.parentFieldApiName = 'AccountId';
        config.parentRecordId = accOne.Id;
        config.fieldApiNames = new List<String>{ 'LastName', 'Email' };
        config.relationshipFieldApiNames = new List<String>{ 'Account.Name' };
        config.orderByField = 'LastName';
        config.orderDirection = 'ASC';
        config.recordLimit = 200;

        List<SObject> rows = ObjectRelatedListController.getRelatedRecords(config);

        System.assertEquals(2, rows.size(), 'Only contacts for the selected account should be returned');
        Contact firstRow = (Contact)rows[0];
        Contact secondRow = (Contact)rows[1];

        System.assertEquals('Alpha', firstRow.LastName, 'Rows should be sorted ascending by LastName');
        System.assertEquals('Zephyr', secondRow.LastName, 'Rows should be sorted ascending by LastName');
        System.assertEquals(
            accOne.Name,
            (String)firstRow.getSObject('Account').get('Name'),
            'Relationship field should be queried and populated'
        );
    }

    @isTest
    static void testGetRelatedRecordsWithParentRelationshipPath() {
        Account accOne = [SELECT Id FROM Account WHERE Name = 'ORL Test Account One' LIMIT 1];

        ObjectRelatedListController.QueryConfig config =
            new ObjectRelatedListController.QueryConfig();
        config.objectApiName = 'Contact';
        config.parentFieldApiName = 'Account.Id';
        config.parentRecordId = accOne.Id;
        config.fieldApiNames = new List<String>{ 'LastName' };
        config.relationshipFieldApiNames = new List<String>{ 'Account.Name' };
        config.orderByField = 'LastName';
        config.orderDirection = 'ASC';
        config.recordLimit = 200;

        List<SObject> rows = ObjectRelatedListController.getRelatedRecords(config);
        System.assertEquals(
            2,
            rows.size(),
            'Relationship-path parent filter should remain supported (for cases like Parent.Onboarding__c)'
        );
    }

    @isTest
    static void testGetRelatedRecordsWithRelationshipPathInFieldApiNames() {
        Account accOne = [SELECT Id, Name FROM Account WHERE Name = 'ORL Test Account One' LIMIT 1];

        ObjectRelatedListController.QueryConfig config =
            new ObjectRelatedListController.QueryConfig();
        config.objectApiName = 'Contact';
        config.parentFieldApiName = 'AccountId';
        config.parentRecordId = accOne.Id;
        config.fieldApiNames = new List<String>{ 'LastName', 'Account.Name' };
        config.relationshipFieldApiNames = new List<String>();
        config.orderByField = 'LastName';
        config.orderDirection = 'ASC';
        config.recordLimit = 200;

        List<SObject> rows = ObjectRelatedListController.getRelatedRecords(config);
        System.assertEquals(
            2,
            rows.size(),
            'Relationship paths in fieldApiNames must remain backward-compatible for App Builder configs'
        );
        System.assertEquals(
            accOne.Name,
            (String)((Contact)rows[0]).getSObject('Account').get('Name'),
            'Account relationship field should be queried when configured in fieldApiNames'
        );
    }

    @isTest
    static void testGetRelatedRecordsRejectsInvalidOrderFieldPath() {
        Account accOne = [SELECT Id FROM Account WHERE Name = 'ORL Test Account One' LIMIT 1];

        ObjectRelatedListController.QueryConfig config =
            new ObjectRelatedListController.QueryConfig();
        config.objectApiName = 'Contact';
        config.parentFieldApiName = 'AccountId';
        config.parentRecordId = accOne.Id;
        config.fieldApiNames = new List<String>{ 'LastName' };
        config.orderByField = 'LastName DESC NULLS LAST';
        config.orderDirection = 'ASC';
        config.recordLimit = 50;

        try {
            ObjectRelatedListController.getRelatedRecords(config);
            System.assert(false, 'Expected AuraHandledException for invalid order field path');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'Exception should be thrown');
        }
    }

    @isTest
    static void testGetLookupOptionsValidAndInvalidInputs() {
        List<ObjectRelatedListController.LookupOption> limitedOptions =
            ObjectRelatedListController.getLookupOptions(
                'Account',
                'Name',
                'Name',
                'ASC',
                1
            );
        System.assertEquals(1, limitedOptions.size(), 'Limit should be respected');
        System.assertNotEquals(null, limitedOptions[0].value, 'Value should be Id');
        System.assertNotEquals(null, limitedOptions[0].label, 'Label should be populated');

        List<ObjectRelatedListController.LookupOption> fallbackSortOptions =
            ObjectRelatedListController.getLookupOptions(
                'Account',
                'Name',
                'Name DESC NULLS LAST',
                'DESC',
                5
            );
        System.assert(
            fallbackSortOptions.size() > 0,
            'Invalid sort field input should safely fall back to label field sorting'
        );

        try {
            ObjectRelatedListController.getLookupOptions(
                'Account',
                'Name;DROP',
                null,
                null,
                5
            );
            System.assert(false, 'Expected AuraHandledException for invalid label field');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'Exception should be thrown');
        }
    }

    @isTest
    static void testValidationGuards() {
        try {
            ObjectRelatedListController.getRelatedRecords(null);
            System.assert(false, 'Expected error for null config');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e);
        }

        try {
            ObjectRelatedListController.getLookupOptions(null, 'Name', null, null, 5);
            System.assert(false, 'Expected error for missing object name');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e);
        }

        try {
            ObjectRelatedListController.getProgramDates(null);
            System.assert(false, 'Expected error for missing account id');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e);
        }
    }

    @isTest
    static void testGetRelatedRecordsLimitAndDirectionGuards() {
        Account accOne = [SELECT Id FROM Account WHERE Name = 'ORL Test Account One' LIMIT 1];

        ObjectRelatedListController.QueryConfig config =
            new ObjectRelatedListController.QueryConfig();
        config.objectApiName = 'Contact';
        config.parentFieldApiName = 'AccountId';
        config.parentRecordId = accOne.Id;
        config.fieldApiNames = new List<String>{ 'LastName' };
        config.orderByField = 'LastName';
        config.orderDirection = null;
        config.recordLimit = 0;

        List<SObject> defaultLimitedRows = ObjectRelatedListController.getRelatedRecords(config);
        System.assertEquals(2, defaultLimitedRows.size(), 'Default limit path should still return matching rows');

        config.recordLimit = 200000;
        List<SObject> maxLimitedRows = ObjectRelatedListController.getRelatedRecords(config);
        System.assertEquals(2, maxLimitedRows.size(), 'Max limit clamp path should still return matching rows');
    }
}
