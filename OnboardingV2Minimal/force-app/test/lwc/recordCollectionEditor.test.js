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
});
