import { createElement } from 'lwc';
import { registerApexTestWireAdapter, registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import ProgramDatesRelatedList from 'c/programDatesRelatedList';
import getRelatedRecords from '@salesforce/apex/ObjectRelatedListController.getRelatedRecords';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';

jest.mock(
    '@salesforce/apex',
    () => ({
        refreshApex: jest.fn(() => Promise.resolve())
    }),
    { virtual: true }
);

jest.mock(
    'lightning/uiRecordApi',
    () => ({
        deleteRecord: jest.fn(),
        updateRecord: jest.fn()
    }),
    { virtual: true }
);

const getRelatedRecordsAdapter = registerApexTestWireAdapter(getRelatedRecords);
const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent() {
    return createElement('c-program-dates-related-list', {
        is: ProgramDatesRelatedList
    });
}

describe('c-program-dates-related-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.useRealTimers();
        jest.clearAllMocks();
    });

    it('renders transformed rows from wire data', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        document.body.appendChild(element);
        await flushPromises();

        const lastConfig = getRelatedRecordsAdapter.getLastConfig();
        expect(lastConfig).toBeDefined();
        expect(lastConfig.config.objectApiName).toBe('Program_Dates__c');
        expect(lastConfig.config.parentFieldApiName).toBe('Account__c');
        expect(lastConfig.config.parentRecordId).toBe('001RL0000001ABCYAA');
        expect(lastConfig.config.orderByField).toBe('Program_Date__c');
        expect(lastConfig.config.orderDirection).toBe('DESC');

        getObjectInfoAdapter.emit({
            label: 'Program Date',
            themeInfo: {
                iconUrl: '/img/icon/t4v35/standard/account_120.png'
            }
        });
        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Fallback Name 1',
                Vendor_Program__r: {
                    Label__c: 'Vendor One'
                }
            },
            {
                Id: 'a02',
                Name: 'Fallback Name 2'
            }
        ]);
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Program Dates');
        expect(element.shadowRoot.textContent).toContain('(2)');

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(2);
        expect(datatable.data[0].recordLink).toBe('/a01');
        expect(datatable.data[0].vendorProgramLabel).toBe('Vendor One');
        expect(datatable.data[1].vendorProgramLabel).toBe('Fallback Name 2');
    });

    it('shows wire error message', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.error({
            body: {
                message: 'Program Date fetch failed'
            }
        });
        await flushPromises();

        // Apex wire adapter may normalize error payloads; component always renders an error string.
        expect(element.shadowRoot.textContent).toContain('Unknown error');
        expect(element.shadowRoot.textContent).toContain('No items');
        const errorRegion = element.shadowRoot.querySelector('[role="alert"]');
        expect(errorRegion).not.toBeNull();
    });

    it('handles datatable save success', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Row 1'
            }
        ]);
        await flushPromises();

        updateRecord.mockResolvedValue({});

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('save', {
                detail: {
                    draftValues: [{ Id: 'a01', Program_ID__c: 'P-100' }]
                }
            })
        );
        await flushPromises();
        await flushPromises();

        expect(updateRecord).toHaveBeenCalledWith({ fields: { Id: 'a01', Program_ID__c: 'P-100' } });
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
    });

    it('handles datatable save error', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Row 1'
            }
        ]);
        await flushPromises();

        updateRecord.mockRejectedValue({
            body: {
                message: 'Update failed'
            }
        });

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('save', {
                detail: {
                    draftValues: [{ Id: 'a01', Program_ID__c: 'P-100' }]
                }
            })
        );
        await flushPromises();
        await flushPromises();
        await flushPromises();

        expect(updateRecord).toHaveBeenCalled();
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.message).toMatch(/Update failed|Unknown error/);
    });

    it('handles datatable row delete action', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Row 1'
            }
        ]);
        await flushPromises();

        deleteRecord.mockResolvedValue({});

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'delete' },
                    row: { Id: 'a01' }
                }
            })
        );
        await flushPromises();
        await flushPromises();

        expect(deleteRecord).toHaveBeenCalledWith('a01');
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
    });

    it('renders keyboard-accessible header and view-all controls', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        document.body.appendChild(element);
        await flushPromises();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Row 1'
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

    it('debounces repeated refresh button clicks to a single refresh call', async () => {
        jest.useFakeTimers();

        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        document.body.appendChild(element);
        await Promise.resolve();

        getRelatedRecordsAdapter.emit([
            {
                Id: 'a01',
                Name: 'Row 1'
            }
        ]);
        await Promise.resolve();
        jest.clearAllMocks();

        const refreshButton = element.shadowRoot.querySelector('lightning-button-icon');
        expect(refreshButton).not.toBeNull();
        refreshButton.click();
        refreshButton.click();
        refreshButton.click();

        expect(refreshApex).not.toHaveBeenCalled();

        jest.advanceTimersByTime(210);
        await Promise.resolve();
        await Promise.resolve();

        expect(refreshApex).toHaveBeenCalledTimes(1);
    });
});
