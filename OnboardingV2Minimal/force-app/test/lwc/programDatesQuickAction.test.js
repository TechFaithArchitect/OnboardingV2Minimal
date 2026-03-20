import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import ProgramDatesQuickAction from 'c/programDatesQuickAction';
import getLookupOptions from '@salesforce/apex/ObjectRelatedListController.getLookupOptions';

const getLookupOptionsAdapter = registerApexTestWireAdapter(getLookupOptions);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent() {
    return createElement('c-program-dates-quick-action', {
        is: ProgramDatesQuickAction
    });
}

describe('c-program-dates-quick-action', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('maps vendor lookup options onto combobox', async () => {
        const element = createComponent();
        document.body.appendChild(element);
        await flushPromises();

        getLookupOptionsAdapter.emit([
            { value: 'a01', label: 'Vendor One' },
            { Id: 'a02', Label__c: 'Vendor Two' },
            { value: 'a03' }
        ]);
        await flushPromises();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(combobox.options).toEqual([
            { label: 'Vendor One', value: 'a01' },
            { label: 'Vendor Two', value: 'a02' },
            { label: 'Unlabeled', value: 'a03' }
        ]);
    });

    it('submits with account default and selected vendor', async () => {
        const element = createComponent();
        element.recordId = '001RL0000001ABCYAA';
        document.body.appendChild(element);
        await flushPromises();

        const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        form.submit = jest.fn();
        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        combobox.dispatchEvent(
            new CustomEvent('change', {
                detail: {
                    value: 'a0VRL0000001XYZYA2'
                }
            })
        );
        await flushPromises();

        const submitEvent = new CustomEvent('submit', {
            cancelable: true,
            detail: {
                fields: {
                    Program_ID__c: 'PROGRAM-1'
                }
            }
        });
        form.dispatchEvent(submitEvent);
        await flushPromises();

        expect(submitEvent.defaultPrevented).toBe(true);
        expect(form.submit).toHaveBeenCalledWith(
            expect.objectContaining({
                Program_ID__c: 'PROGRAM-1',
                Account__c: '001RL0000001ABCYAA',
                Vendor_Program__c: 'a0VRL0000001XYZYA2'
            })
        );
        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
    });

    it('submits without Account__c default when recordId is not an account', async () => {
        const element = createComponent();
        element.recordId = 'a0VRL0000001XYZYA2';
        document.body.appendChild(element);
        await flushPromises();

        const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        form.submit = jest.fn();

        const submitEvent = new CustomEvent('submit', {
            cancelable: true,
            detail: {
                fields: {
                    Program_ID__c: 'PROGRAM-2'
                }
            }
        });
        form.dispatchEvent(submitEvent);
        await flushPromises();

        const submittedFields = form.submit.mock.calls[0][0];
        expect(submittedFields.Program_ID__c).toBe('PROGRAM-2');
        expect(submittedFields.Account__c).toBeUndefined();
    });

    it('emits success toast and close event on form success', async () => {
        const element = createComponent();
        const toastHandler = jest.fn();
        const closeHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        element.addEventListener('close', closeHandler);
        document.body.appendChild(element);
        await flushPromises();

        const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        form.dispatchEvent(new CustomEvent('success'));
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
        expect(closeHandler).toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('emits error toast on form error', async () => {
        const element = createComponent();
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        form.dispatchEvent(
            new CustomEvent('error', {
                detail: {
                    body: {
                        message: 'Create failed'
                    }
                }
            })
        );
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.message).toContain('Create failed');
    });

    it('emits error toast when vendor lookup wire errors', async () => {
        const element = createComponent();
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);
        await flushPromises();

        getLookupOptionsAdapter.error({
            body: {
                message: 'Lookup failed'
            }
        });
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error loading vendor programs');
    });
});
