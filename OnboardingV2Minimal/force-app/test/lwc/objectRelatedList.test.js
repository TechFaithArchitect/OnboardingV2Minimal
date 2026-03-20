import { createElement } from 'lwc';
import { registerApexTestWireAdapter, registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import ObjectRelatedList from 'c/objectRelatedList';
import getRelatedRecords from '@salesforce/apex/ObjectRelatedListController.getRelatedRecords';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

const getRelatedRecordsAdapter = registerApexTestWireAdapter(getRelatedRecords);
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);
const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);
const getPicklistValuesByRecordTypeAdapter = registerLdsTestWireAdapter(getPicklistValuesByRecordType);

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

    it('renders keyboard-accessible header and view-all controls for relationship navigation', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.childObjectApiName = 'Onboarding_Requirement__c';
        element.parentFieldApiName = 'Onboarding__c';
        element.relationshipApiName = 'Onboarding_Requirements__r';
        element.fieldApiNamesCsv = 'Name';
        element.columnFieldApiNamesCsv = 'Name';

        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Requirement 1'
            }
        ]);
        await flushPromises();

        const headerButton = element.shadowRoot.querySelector('button.header-link');
        expect(headerButton).not.toBeNull();
        expect(headerButton.getAttribute('type')).toBe('button');

        const viewAllButton = element.shadowRoot.querySelector('button.text-link-button');
        expect(viewAllButton).not.toBeNull();
        expect(viewAllButton.textContent).toContain('View All');

        const statusText = element.shadowRoot.querySelector('.status-text');
        expect(statusText.getAttribute('aria-live')).toBe('polite');
    });

    it('loads picklist options by record type and tracks success telemetry', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.childObjectApiName = 'Onboarding_Requirement__c';
        element.parentFieldApiName = 'Onboarding__c';
        element.fieldApiNamesCsv = 'Status__c,Requirement_Type__c';
        element.columnFieldApiNamesCsv = 'Status__c,Requirement_Type__c';
        element.enablePicklistTelemetry = true;

        document.body.appendChild(element);
        await flushPromises();

        getObjectInfoAdapter.emit({
            apiName: 'Onboarding_Requirement__c',
            fields: {
                RecordTypeId: { apiName: 'RecordTypeId' },
                Status__c: {
                    apiName: 'Status__c',
                    label: 'Status',
                    dataType: 'Picklist',
                    updateable: true,
                    picklistValues: [
                        { label: 'Draft', value: 'Draft', active: true },
                        { label: 'Complete', value: 'Complete', active: true }
                    ]
                },
                Requirement_Type__c: {
                    apiName: 'Requirement_Type__c',
                    label: 'Requirement Type',
                    dataType: 'String',
                    updateable: false
                }
            }
        });
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Status__c: 'Draft',
                Requirement_Type__c: 'Agreement',
                RecordTypeId: '012RTA'
            }
        ]);
        await flushPromises();
        await flushPromises();

        const firstPicklistRequest = getPicklistValuesByRecordTypeAdapter.getLastConfig();
        expect(firstPicklistRequest).toBeDefined();
        expect(firstPicklistRequest.recordTypeId).toBe('012RTA');
        expect(firstPicklistRequest.objectApiName).toBe('Onboarding_Requirement__c');

        getPicklistValuesByRecordTypeAdapter.emit({
            picklistFieldValues: {
                Status__c: {
                    values: [
                        { label: 'Draft', value: 'Draft' },
                        { label: 'Complete', value: 'Complete' }
                    ]
                }
            }
        });
        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('c-object-related-list-datatable');
        const options = datatable.data[0].__picklistOptions_Status__c;
        expect(options).toEqual([
            { label: 'Draft', value: 'Draft' },
            { label: 'Complete', value: 'Complete' }
        ]);
    });

    it('falls back to object-info picklist values on recordType wire error', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.childObjectApiName = 'Onboarding_Requirement__c';
        element.parentFieldApiName = 'Onboarding__c';
        element.fieldApiNamesCsv = 'Status__c';
        element.columnFieldApiNamesCsv = 'Status__c';
        element.enablePicklistTelemetry = true;

        document.body.appendChild(element);
        await flushPromises();

        getObjectInfoAdapter.emit({
            apiName: 'Onboarding_Requirement__c',
            fields: {
                RecordTypeId: { apiName: 'RecordTypeId' },
                Status__c: {
                    apiName: 'Status__c',
                    label: 'Status',
                    dataType: 'Picklist',
                    updateable: true,
                    picklistValues: [
                        { label: 'Fallback One', value: 'FallbackOne', active: true },
                        { label: 'Fallback Two', value: 'FallbackTwo', active: true }
                    ]
                }
            }
        });
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a02',
                Status__c: 'FallbackOne',
                RecordTypeId: '012RTB'
            }
        ]);
        await flushPromises();
        await flushPromises();

        const erroredPicklistRequest = getPicklistValuesByRecordTypeAdapter.getLastConfig();
        expect(erroredPicklistRequest).toBeDefined();
        expect(erroredPicklistRequest.recordTypeId).toBe('012RTB');

        getPicklistValuesByRecordTypeAdapter.error({
            body: {
                message: 'Session expired or invalid'
            }
        });
        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('c-object-related-list-datatable');
        const options = datatable.data[0].__picklistOptions_Status__c;
        expect(options).toEqual([
            { label: 'Fallback One', value: 'FallbackOne' },
            { label: 'Fallback Two', value: 'FallbackTwo' }
        ]);
    });

    it('releases queue and advances to next record type after each picklist response', async () => {
        const element = createComponent();
        element.recordId = 'a1DRL0000001ABCYAA';
        element.childObjectApiName = 'Onboarding_Requirement__c';
        element.parentFieldApiName = 'Onboarding__c';
        element.fieldApiNamesCsv = 'Status__c';
        element.columnFieldApiNamesCsv = 'Status__c';
        element.enablePicklistTelemetry = true;

        document.body.appendChild(element);
        await flushPromises();

        getObjectInfoAdapter.emit({
            apiName: 'Onboarding_Requirement__c',
            fields: {
                RecordTypeId: { apiName: 'RecordTypeId' },
                Status__c: {
                    apiName: 'Status__c',
                    label: 'Status',
                    dataType: 'Picklist',
                    updateable: true,
                    picklistValues: [{ label: 'Draft', value: 'Draft', active: true }]
                }
            }
        });
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            { Id: 'a11', Status__c: 'Draft', RecordTypeId: '012RTA' },
            { Id: 'a12', Status__c: 'Complete', RecordTypeId: '012RTB' }
        ]);
        await flushPromises();
        await flushPromises();

        const firstPicklistRequest = getPicklistValuesByRecordTypeAdapter.getLastConfig();
        expect(firstPicklistRequest).toBeDefined();
        expect(firstPicklistRequest.recordTypeId).toBe('012RTA');

        getPicklistValuesByRecordTypeAdapter.emit({
            picklistFieldValues: {
                Status__c: {
                    values: [{ label: 'Draft', value: 'Draft' }]
                }
            }
        });
        await flushPromises();
        await flushPromises();

        // Queue should advance and request the second record type.
        const secondPicklistRequest = getPicklistValuesByRecordTypeAdapter.getLastConfig();
        expect(secondPicklistRequest).toBeDefined();
        expect(secondPicklistRequest.recordTypeId).toBe('012RTB');

        getPicklistValuesByRecordTypeAdapter.emit({
            picklistFieldValues: {
                Status__c: {
                    values: [{ label: 'Complete', value: 'Complete' }]
                }
            }
        });
        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('c-object-related-list-datatable');
        expect(datatable.data[0].__picklistOptions_Status__c).toEqual([{ label: 'Draft', value: 'Draft' }]);
        expect(datatable.data[1].__picklistOptions_Status__c).toEqual([{ label: 'Complete', value: 'Complete' }]);
    });
});
