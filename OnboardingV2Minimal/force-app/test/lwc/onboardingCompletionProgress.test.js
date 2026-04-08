import { createElement } from 'lwc';
import OnboardingCompletionProgress from 'c/onboardingCompletionProgress';
import getCompletionPercent from '@salesforce/apex/OnboardingProgressController.getCompletionPercent';

jest.mock(
    '@salesforce/apex/OnboardingProgressController.getCompletionPercent',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent() {
    return createElement('c-onboarding-completion-progress', {
        is: OnboardingCompletionProgress
    });
}

describe('c-onboarding-completion-progress', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.useRealTimers();
        jest.clearAllMocks();
    });

    it('loads completion percent on init', async () => {
        getCompletionPercent.mockResolvedValue(17);

        const element = createComponent();
        element.recordId = 'aD1RL000001QT4D0AW';
        document.body.appendChild(element);
        await flushPromises();
        await flushPromises();

        expect(getCompletionPercent).toHaveBeenCalledWith({ recordId: 'aD1RL000001QT4D0AW' });
        expect(element.shadowRoot.textContent).toContain('17% Complete');
    });

    it('refresh button fetches updated percent without page reload', async () => {
        getCompletionPercent.mockResolvedValueOnce(17).mockResolvedValueOnce(33);

        const element = createComponent();
        element.recordId = 'aD1RL000001QT4D0AW';
        document.body.appendChild(element);
        await flushPromises();
        await flushPromises();

        const refreshButton = element.shadowRoot.querySelector('lightning-button-icon');
        expect(refreshButton).not.toBeNull();
        refreshButton.click();
        await flushPromises();
        await flushPromises();

        expect(getCompletionPercent).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.textContent).toContain('33% Complete');
    });

    it('refreshes only for onboarding requirement change events scoped to current record', async () => {
        getCompletionPercent.mockResolvedValueOnce(17).mockResolvedValueOnce(25);

        const element = createComponent();
        element.recordId = 'aD1RL000001QT4D0AW';
        document.body.appendChild(element);
        await flushPromises();
        await flushPromises();

        window.dispatchEvent(
            new CustomEvent('objectrelatedlistchange', {
                detail: {
                    objectApiName: 'Account',
                    parentRecordId: 'aD1RL000001QT4D0AW'
                }
            })
        );
        await flushPromises();
        expect(getCompletionPercent).toHaveBeenCalledTimes(1);

        window.dispatchEvent(
            new CustomEvent('objectrelatedlistchange', {
                detail: {
                    objectApiName: 'Onboarding_Requirement__c',
                    parentRecordId: 'aD1RL000001PAYH0A4'
                }
            })
        );
        await flushPromises();
        expect(getCompletionPercent).toHaveBeenCalledTimes(1);

        window.dispatchEvent(
            new CustomEvent('objectrelatedlistchange', {
                detail: {
                    objectApiName: 'Onboarding_Requirement__c',
                    parentRecordId: 'aD1RL000001QT4D0AW'
                }
            })
        );
        await flushPromises();
        await flushPromises();

        expect(getCompletionPercent).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.textContent).toContain('25% Complete');
    });
});
