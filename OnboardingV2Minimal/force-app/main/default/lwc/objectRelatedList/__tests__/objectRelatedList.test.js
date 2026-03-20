import { createElement } from 'lwc';
import { registerApexTestWireAdapter, registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import ObjectRelatedList from 'c/objectRelatedList';
import getRelatedRecords from '@salesforce/apex/ObjectRelatedListController.getRelatedRecords';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

const getRelatedRecordsAdapter = registerApexTestWireAdapter(getRelatedRecords);
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);
const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);

const flushPromises = () => Promise.resolve();

function createComponent() {
    return createElement('c-object-related-list', {
        is: ObjectRelatedList
    });
}

describe('c-object-related-list dotted path compatibility', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('passes dotted query inputs to the getRelatedRecords wire config', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.childObjectApiName = 'Onboarding_Requirement__History';
        element.parentFieldApiName = 'Parent.Onboarding__c';
        element.fieldApiNamesCsv = 'CreatedBy.Name, Parent.Requirement_Type__c, OldValue';
        element.relationshipFieldApiNamesCsv = 'Parent.Requirement_Type__c';
        element.excludeRowsWhereCsv = 'Parent.Requirement_Type__c=Agreement';
        element.orderByField = 'Parent.Requirement_Type__c';
        element.orderDirection = 'ASC';
        element.recordLimit = 50;

        document.body.appendChild(element);
        await flushPromises();

        // Trigger object-info branch so RecordTypeId inclusion path is exercised.
        getObjectInfoAdapter.emit({
            apiName: 'Onboarding_Requirement__History',
            fields: {
                RecordTypeId: {
                    apiName: 'RecordTypeId'
                }
            }
        });
        await flushPromises();

        const lastConfig = getRelatedRecordsAdapter.getLastConfig();
        expect(lastConfig).toBeDefined();
        expect(lastConfig.config.objectApiName).toBe('Onboarding_Requirement__History');
        expect(lastConfig.config.parentFieldApiName).toBe('Parent.Onboarding__c');
        expect(lastConfig.config.parentRecordId).toBe('a1DRL0000001ABCYAA');
        expect(lastConfig.config.orderByField).toBe('Parent.Requirement_Type__c');
        expect(lastConfig.config.orderDirection).toBe('ASC');
        expect(lastConfig.config.recordLimit).toBe(50);
        expect(lastConfig.config.fieldApiNames).toEqual(
            expect.arrayContaining(['CreatedBy.Name', 'Parent.Requirement_Type__c', 'OldValue', 'RecordTypeId'])
        );
        expect(lastConfig.config.relationshipFieldApiNames).toEqual(
            expect.arrayContaining(['Parent.Requirement_Type__c'])
        );
    });

    it('supports dotted parentRecordIdSourceFieldApiName for parentId resolution', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.objectApiName = 'Onboarding__c';
        element.childObjectApiName = 'Onboarding_Requirement__History';
        element.parentFieldApiName = 'Parent.Onboarding__c';
        element.parentRecordIdSourceFieldApiName = 'Account.ParentId';
        element.fieldApiNamesCsv = 'CreatedBy.Name,OldValue';

        document.body.appendChild(element);
        await flushPromises();

        // Validate dotted source field is used by getRecord wire.
        const parentSourceConfig = getRecordAdapter.getLastConfig();
        expect(parentSourceConfig.fields).toEqual(['Account.ParentId']);

        // Provide source field record; component extracts terminal token ParentId.
        getRecordAdapter.emit({
            fields: {
                ParentId: {
                    value: '001RL0000000XYZYA2'
                }
            }
        });
        await flushPromises();

        const lastConfig = getRelatedRecordsAdapter.getLastConfig();
        expect(lastConfig).toBeDefined();
        expect(lastConfig.config.parentRecordId).toBe('001RL0000000XYZYA2');
        expect(lastConfig.config.parentFieldApiName).toBe('Parent.Onboarding__c');
    });

    it('renders filtered rows using dotted exclusion fields and dotted transformed values', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.childObjectApiName = 'Onboarding_Requirement__History';
        element.parentFieldApiName = 'Parent.Onboarding__c';
        element.fieldApiNamesCsv = 'CreatedBy.Name,OldValue';
        element.columnFieldApiNamesCsv = 'CreatedBy.Name,OldValue';
        element.excludeRowsWhereCsv = 'CreatedBy.Name=Jason Murray';

        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a0',
                OldValue: 'Draft',
                CreatedBy: { Name: 'Jason Murray' }
            },
            {
                Id: 'a1',
                OldValue: 'Complete',
                CreatedBy: { Name: 'Another User' }
            }
        ]);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('c-object-related-list-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].Id).toBe('a1');
        expect(datatable.data[0]['CreatedBy.Name']).toBe('Another User');
        expect(datatable.data[0].recordLink).toBe('/a1');
    });
});
