@IsTest
private class RecordCollectionEditorConfigServiceTest {
    @IsTest
    static void getConfig_returnsConfiguredFieldMetadata() {
        RecordCollectionEditorConfigService.RecordCollectionConfig config =
            RecordCollectionEditorConfigService.getConfig('CONTACT_ON_ACCOUNT');

        System.assertEquals('Contact', config.objectApiName, 'Expected contact object config.');
        System.assertEquals('AccountId', config.parentFieldApiName, 'Expected account parent field.');
        System.assertNotEquals(null, config.fields, 'Expected child field configs.');
        System.assertNotEquals(null, config.relationshipFields, 'Expected relationship field configs.');
        System.assertEquals('Roles', config.roleConstraints.roleFieldApiName, 'Expected relationship role field.');

        Set<String> fieldNames = new Set<String>();
        for (RecordCollectionEditorConfigService.FieldConfig fieldConfig : config.fields) {
            fieldNames.add(fieldConfig.fieldApiName);
        }

        System.assert(fieldNames.contains('FirstName'), 'Expected FirstName field in config.');
        System.assert(fieldNames.contains('LastName'), 'Expected LastName field in config.');
        System.assert(fieldNames.contains('Email'), 'Expected Email field in config.');
    }

    @IsTest
    static void createRecordsFromJson_createsContactAndRelationship() {
        Account accountRecord = new Account(Name = 'Record Editor Account');
        insert accountRecord;

        String payload =
            '[{"child":{"AccountId":"' + accountRecord.Id + '","FirstName":"Ada","LastName":"Lovelace",' +
            '"Email":"ada@example.com","Phone":"555-555-1212"},' +
            '"relationship":{"Roles":"Owner","StartDate":""}}]';

        RecordCollectionEditorConfigService.CreateFromJsonRequest requestItem =
            new RecordCollectionEditorConfigService.CreateFromJsonRequest();
        requestItem.configKey = 'CONTACT_ON_ACCOUNT';
        requestItem.recordsJson = payload;

        List<RecordCollectionEditorConfigService.CreateFromJsonResult> results =
            RecordCollectionEditorConfigService.createRecordsFromJson(
                new List<RecordCollectionEditorConfigService.CreateFromJsonRequest>{ requestItem }
            );

        System.assertEquals(1, results.size(), 'Expected one result payload.');
        System.assertEquals(
            0,
            results[0].errorMessages.size(),
            'Expected no DML or security errors. Actual: ' + String.join(results[0].errorMessages, ' | ')
        );
        System.assertEquals(1, results[0].createdRecords.size(), 'Expected one contact record.');
        System.assertEquals(1, results[0].createdRelationshipRecords.size(), 'Expected one relationship record.');

        Id createdContactId = (Id) results[0].createdRecords[0].get('Id');
        System.assertNotEquals(null, createdContactId, 'Expected inserted contact Id.');

        Contact createdContact = [
            SELECT Id, AccountId, FirstName, LastName, Email, Phone
            FROM Contact
            WHERE Id = :createdContactId
            LIMIT 1
        ];
        System.assertEquals(accountRecord.Id, createdContact.AccountId, 'Expected contact tied to account.');
        System.assertEquals('Ada', createdContact.FirstName, 'Expected first name to persist.');

        AccountContactRelation relationshipRecord = [
            SELECT Id, AccountId, ContactId, Roles, StartDate
            FROM AccountContactRelation
            WHERE AccountId = :accountRecord.Id AND ContactId = :createdContactId
            LIMIT 1
        ];
        System.assertEquals('Owner', relationshipRecord.Roles, 'Expected relationship role to persist.');
        System.assertNotEquals(null, relationshipRecord.Id, 'Expected relationship row to exist.');
    }

    @IsTest
    static void createRecordsFromJson_handlesMultipleRowsForSameParent() {
        Account accountRecord = new Account(Name = 'Record Editor Bulk Account');
        insert accountRecord;

        String payload =
            '[' +
            '{"child":{"AccountId":"' + accountRecord.Id + '","FirstName":"FirstOwner","LastName":"LastOwner","Email":"firstowner.bulk@example.com","Phone":"555-0001"},' +
            '"relationship":{"Roles":"Owner","StartDate":""}},' +
            '{"child":{"AccountId":"' + accountRecord.Id + '","FirstName":"FirstPrincipal","LastName":"LastPrincipal","Email":"firstprincipal.bulk@example.com","Phone":"555-0002"},' +
            '"relationship":{"Roles":"Principal Owner","StartDate":""}}' +
            ']';

        RecordCollectionEditorConfigService.CreateFromJsonRequest requestItem =
            new RecordCollectionEditorConfigService.CreateFromJsonRequest();
        requestItem.configKey = 'CONTACT_ON_ACCOUNT';
        requestItem.recordsJson = payload;

        List<RecordCollectionEditorConfigService.CreateFromJsonResult> results =
            RecordCollectionEditorConfigService.createRecordsFromJson(
                new List<RecordCollectionEditorConfigService.CreateFromJsonRequest>{ requestItem }
            );

        System.assertEquals(1, results.size(), 'Expected one bulk result payload.');
        System.assertEquals(
            0,
            results[0].errorMessages.size(),
            'Expected no bulk DML errors. Actual: ' + String.join(results[0].errorMessages, ' | ')
        );
        System.assertEquals(2, results[0].createdRecords.size(), 'Expected two created contacts.');
        System.assertEquals(2, results[0].createdRelationshipRecords.size(), 'Expected two created relationships.');
    }

    @IsTest
    static void getRecordsJsonForEditor_serializesRelationshipData() {
        Account accountRecord = new Account(Name = 'Editor Serialize Account');
        insert accountRecord;

        Contact contactRecord = new Contact(
            FirstName = 'Grace',
            LastName = 'Hopper',
            Email = 'grace@example.com',
            Phone = '555-0100',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        AccountContactRelation relationshipRecord = [
            SELECT Id, AccountId, ContactId, Roles, StartDate
            FROM AccountContactRelation
            WHERE AccountId = :accountRecord.Id AND ContactId = :contactRecord.Id
            LIMIT 1
        ];
        relationshipRecord.Roles = 'Owner';
        update relationshipRecord;

        RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest requestItem =
            new RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest();
        requestItem.configKey = 'CONTACT_ON_ACCOUNT';
        requestItem.records = new List<SObject>{
            [
                SELECT Id, AccountId, FirstName, LastName, Email, Phone
                FROM Contact
                WHERE Id = :contactRecord.Id
                LIMIT 1
            ]
        };

        List<RecordCollectionEditorGetRecordsService.GetRecordsJsonResult> results =
            RecordCollectionEditorGetRecordsService.getRecordsJsonForEditor(
                new List<RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest>{ requestItem }
            );

        System.assertEquals(1, results.size(), 'Expected one serialization result.');
        System.assertEquals(null, results[0].errorMessage, 'Expected serialization to succeed.');
        System.assertNotEquals(null, results[0].recordsJson, 'Expected JSON payload.');
        System.assert(results[0].recordsJson.contains('"child"'), 'Expected child wrapper in payload.');
        System.assert(results[0].recordsJson.contains('"relationship"'), 'Expected relationship wrapper in payload.');
        System.assert(results[0].recordsJson.contains('"Roles":"Owner"'), 'Expected serialized role value.');
        System.assert(results[0].recordsJson.contains('"Email":"grace@example.com"'), 'Expected serialized child field value.');
    }

    @IsTest
    static void getRecordsJsonForEditor_contactOnOpportunity_defaultsPrincipalOwnerPrimary() {
        Account accountRecord = new Account(Name = 'OCR PO Account');
        insert accountRecord;

        Contact contactRecord = new Contact(FirstName = 'Pat', LastName = 'Owner', AccountId = accountRecord.Id);
        insert contactRecord;

        AccountContactRelation acr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountRecord.Id AND ContactId = :contactRecord.Id
            LIMIT 1
        ];
        acr.Roles = 'Principal Owner';
        update acr;

        RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest requestItem =
            new RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest();
        requestItem.configKey = 'CONTACT_ON_OPPORTUNITY';
        requestItem.records = new List<SObject>{
            [SELECT Id, AccountId FROM Contact WHERE Id = :contactRecord.Id]
        };

        List<RecordCollectionEditorGetRecordsService.GetRecordsJsonResult> results =
            RecordCollectionEditorGetRecordsService.getRecordsJsonForEditor(
                new List<RecordCollectionEditorGetRecordsService.GetRecordsJsonRequest>{ requestItem }
            );

        System.assertEquals(1, results.size(), 'Expected one serialization result.');
        System.assertEquals(
            null,
            results[0].errorMessage,
            'Unexpected serialization error: ' + String.valueOf(results[0].errorMessage)
        );
        System.assert(
            results[0].recordsJson.contains('"IsPrimary":true'),
            'Expected Principal Owner contact to default as primary: ' + results[0].recordsJson
        );
        System.assert(
            results[0].recordsJson.contains('"Role":"Principal Owner"'),
            'Expected Principal Owner role prefilled: ' + results[0].recordsJson
        );
    }

    @IsTest
    static void getConfig_supportsAddressAndConfiguredPicklists() {
        RecordCollectionEditorConfigService.RecordCollectionConfig accountConfig =
            RecordCollectionEditorConfigService.getConfig('ACCOUNT_CREATE_RECORD');

        System.assertEquals('Account', accountConfig.objectApiName, 'Expected Account config.');
        System.assertEquals('Id', accountConfig.parentFieldApiName, 'Expected Id parent field for account update.');

        RecordCollectionEditorConfigService.FieldConfig billingAddressConfig;
        for (RecordCollectionEditorConfigService.FieldConfig fieldConfig : accountConfig.fields) {
            if (fieldConfig.fieldApiName == 'BillingAddress') {
                billingAddressConfig = fieldConfig;
                break;
            }
        }

        System.assertNotEquals(null, billingAddressConfig, 'Expected BillingAddress field config.');
        System.assertEquals('address', billingAddressConfig.dataType, 'Expected address data type.');
        System.assertEquals('Billing', billingAddressConfig.addressPrefix, 'Expected Billing address prefix.');
        System.assertEquals(true, billingAddressConfig.showAddressLookup, 'Expected address lookup enabled.');

        RecordCollectionEditorConfigService.RecordCollectionConfig opportunityConfig =
            RecordCollectionEditorConfigService.getConfig('OPPORTUNITY_CREATE_RECORD');
        RecordCollectionEditorConfigService.FieldConfig documentsReadyConfig;
        for (RecordCollectionEditorConfigService.FieldConfig fieldConfig : opportunityConfig.fields) {
            if (fieldConfig.fieldApiName == 'Documents_Ready__c') {
                documentsReadyConfig = fieldConfig;
                break;
            }
        }

        System.assertNotEquals(null, documentsReadyConfig, 'Expected documents-ready field config.');
        System.assertEquals('picklist', documentsReadyConfig.dataType, 'Expected explicit picklist type.');
        System.assertEquals(true, documentsReadyConfig.picklistValues.contains('Yes'), 'Expected Yes option.');
        System.assertEquals(true, documentsReadyConfig.picklistValues.contains('No'), 'Expected No option.');
    }
}
