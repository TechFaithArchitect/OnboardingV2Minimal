import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import RecordCollectionEditor from 'c/recordCollectionEditor';
import getConfig from '@salesforce/apex/RecordCollectionEditorConfigService.getConfig';

const getConfigAdapter = registerApexTestWireAdapter(getConfig);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-record-collection-editor', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('requires configKey in connectedCallback', async () => {
        const element = createElement('c-record-collection-editor', { is: RecordCollectionEditor });
        document.body.appendChild(element);
        await flushPromises();

        expect(element.errorMessage).toBe('Config key is required.');
    });

    it('surfaces Apex wire error from getConfig on the public errorMessage', async () => {
        const element = createElement('c-record-collection-editor', { is: RecordCollectionEditor });
        element.configKey = 'Test_Config';
        document.body.appendChild(element);
        await flushPromises();

        getConfigAdapter.error({
            body: { message: 'Configuration not found' },
            status: 500,
            ok: false
        });
        await flushPromises();

        // Apex wire adapter may normalize errors; component falls back to a generic message.
        expect(element.errorMessage).toMatch(/Configuration not found|Error loading record collection editor configuration/);
    });

    it('rebuilds rows when existingRecordsJson changes after config loads', async () => {
        const element = createElement('c-record-collection-editor', { is: RecordCollectionEditor });
        element.configKey = 'CONTACT_ON_OPPORTUNITY';
        element.existingRecordsJson = '[]';
        document.body.appendChild(element);
        await flushPromises();

        const mockOcrConfig = {
            objectApiName: 'OpportunityContactRole',
            parentFieldApiName: 'OpportunityId',
            fields: [
                {
                    fieldApiName: 'ContactId',
                    label: 'Contact',
                    required: true,
                    dataType: 'lookup',
                    readOnly: true,
                    lookupObjectApiName: 'Contact'
                },
                {
                    fieldApiName: 'Role',
                    label: 'Role',
                    required: true,
                    dataType: 'picklist',
                    picklistValues: ['Decision Maker', 'Evaluator']
                },
                {
                    fieldApiName: 'IsPrimary',
                    label: 'Primary',
                    required: true,
                    dataType: 'checkbox'
                }
            ],
            relationshipFields: [],
            roleConstraints: null
        };
        getConfigAdapter.emit(mockOcrConfig);
        await flushPromises();

        expect(JSON.parse(element.recordsToCreate).length).toBeGreaterThanOrEqual(1);

        element.existingRecordsJson = JSON.stringify([
            {
                child: { Id: '003000000000000AAA', FirstName: 'Pat', LastName: 'Lee' },
                relationship: {}
            }
        ]);
        await flushPromises();

        const after = JSON.parse(element.recordsToCreate);
        expect(after.length).toBe(1);
        expect(after[0].Id).toBe('003000000000000AAA');
    });

    it('defaults first CONTACT_ON_ACCOUNT relationship role to Principal Owner when configured', async () => {
        const element = createElement('c-record-collection-editor', { is: RecordCollectionEditor });
        element.configKey = 'CONTACT_ON_ACCOUNT';
        document.body.appendChild(element);
        await flushPromises();

        const mockContactConfig = {
            objectApiName: 'Contact',
            parentFieldApiName: 'AccountId',
            fields: [
                { fieldApiName: 'FirstName', label: 'First', required: true, dataType: 'text' },
                { fieldApiName: 'LastName', label: 'Last', required: true, dataType: 'text' }
            ],
            relationshipFields: [
                {
                    fieldApiName: 'Roles',
                    label: 'Role',
                    required: true,
                    dataType: 'picklist',
                    picklistValues: ['Principal Owner', 'Authorized Signer']
                }
            ],
            roleConstraints: {
                singlePerAccountRoles: ['Principal Owner'],
                requiresPermissionRoles: ['Authorized Signer'],
                roleFieldApiName: 'Roles',
                canAssignAuthorizedSigner: true
            }
        };
        getConfigAdapter.emit(mockContactConfig);
        await flushPromises();

        const payload = JSON.parse(element.recordsToCreate);
        expect(payload.length).toBeGreaterThanOrEqual(1);
        expect(payload[0].relationship.Roles).toBe('Principal Owner');
    });

    it('does not rebuild rows when parent echoes recordsToCreate (keeps focus while typing)', async () => {
        const element = createElement('c-record-collection-editor', { is: RecordCollectionEditor });
        element.configKey = 'CONTACT_ON_ACCOUNT';
        document.body.appendChild(element);
        await flushPromises();

        const mockContactConfig = {
            objectApiName: 'Contact',
            parentFieldApiName: 'AccountId',
            fields: [
                { fieldApiName: 'FirstName', label: 'First', required: true, dataType: 'text' },
                { fieldApiName: 'Phone', label: 'Phone', required: false, dataType: 'phone' }
            ],
            relationshipFields: [],
            roleConstraints: null
        };
        getConfigAdapter.emit(mockContactConfig);
        await flushPromises();

        const snapshot = element.recordsToCreate;
        expect(snapshot).toBeTruthy();
        element.existingRecordsJson = snapshot;
        await flushPromises();

        expect(element.recordsToCreate).toBe(snapshot);
    });
});
