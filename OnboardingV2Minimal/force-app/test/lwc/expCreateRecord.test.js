import { createElement } from 'lwc';
import ExpCreateRecord from 'c/expCreateRecord';
import loadContext from '@salesforce/apex/ExpOpportunityCreateRecord.loadContext';

jest.mock(
    '@salesforce/apex/ExpOpportunityCreateRecord.loadContext',
    () => ({
        __esModule: true,
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/ExpOpportunityCreateRecord.saveContactsAndPrepareOcr',
    () => ({
        __esModule: true,
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/ExpOpportunityCreateRecord.submitCreateRecord',
    () => ({
        __esModule: true,
        default: jest.fn()
    }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

async function flushUntilReady() {
    await flushPromises();
    await flushPromises();
    await flushPromises();
}

function errorBannerMessage(element) {
    const root = element.shadowRoot;
    if (!root) {
        return null;
    }
    const banner = root.querySelector('.slds-alert_error');
    if (!banner) {
        return null;
    }
    const spans = banner.querySelectorAll('span');
    return spans.length > 1 ? spans[spans.length - 1].textContent.trim() : null;
}

describe('c-exp-create-record', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('surfaces Account Id required when no account context is available', async () => {
        const element = createElement('c-exp-create-record', { is: ExpCreateRecord });
        document.body.appendChild(element);
        await flushUntilReady();

        expect(errorBannerMessage(element)).toBe('Account Id is required.');
        expect(loadContext).not.toHaveBeenCalled();
    });

    it('maps loadContext Apex failure to errorMessage', async () => {
        loadContext.mockResolvedValueOnce({
            success: false,
            errorMessage: 'Account not found'
        });

        const element = createElement('c-exp-create-record', { is: ExpCreateRecord });
        element.flowAccountId = '001000000000001AAA';
        document.body.appendChild(element);
        await flushUntilReady();

        expect(loadContext).toHaveBeenCalled();
        expect(errorBannerMessage(element)).toBe('Account not found');
    });

    it('maps loadContext exception body.message to errorMessage', async () => {
        loadContext.mockRejectedValueOnce({
            body: { message: 'INSUFFICIENT_ACCESS' }
        });

        const element = createElement('c-exp-create-record', { is: ExpCreateRecord });
        element.flowAccountId = '001000000000001AAA';
        document.body.appendChild(element);
        await flushUntilReady();

        expect(errorBannerMessage(element)).toBe('INSUFFICIENT_ACCESS');
    });
});
