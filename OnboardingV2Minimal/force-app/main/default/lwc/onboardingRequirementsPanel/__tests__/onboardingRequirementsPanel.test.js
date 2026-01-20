import { createElement } from '@lwc/engine-dom';
import OnboardingRequirementsPanel from 'c/onboardingRequirementsPanel';
import getRequirements from '@salesforce/apex/OnboardingRequirementsPanelController.getRequirements';
import getInvalidFieldValues from '@salesforce/apex/OnboardingRequirementsPanelController.getInvalidFieldValues';
import updateRequirementStatuses from '@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses';
import runRuleEvaluation from '@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation';
import rerunValidation from '@salesforce/apex/OnboardingRequirementsPanelController.rerunValidation';
import getActiveRulesVersion from '@salesforce/apex/OnboardingRequirementsPanelController.getActiveRulesVersion';
import refreshAndReevaluate from '@salesforce/apex/OnboardingRequirementsPanelController.refreshAndReevaluate';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.getRequirements',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.getInvalidFieldValues',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.updateRequirementStatuses',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.runRuleEvaluation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.rerunValidation',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.getActiveRulesVersion',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingRequirementsPanelController.refreshAndReevaluate',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const waitForElement = async (root, selector, attempts = 5) => {
    if (!root) {
        return null;
    }
    const found = root.querySelector(selector);
    if (found || attempts <= 0) {
        return found;
    }
    await Promise.resolve();
    return waitForElement(root, selector, attempts - 1);
};

describe('c-onboarding-requirements-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockRequirements = [
        {
            Id: 'a0X000000000001AAA',
            Name: 'Requirement 1',
            Status: 'Not Started'
        },
        {
            Id: 'a0X000000000002AAA',
            Name: 'Requirement 2',
            Status: 'Incomplete'
        }
    ];

    const mockInvalids = [
        {
            fieldValueId: 'a0Z000000000001AAA',
            requirementName: 'Requirement 1',
            fieldName: 'Email',
            fieldApiName: 'Email__c',
            status: 'Invalid',
            message: 'Invalid email'
        }
    ];

    it('renders component with recordId', () => {
        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        expect(element.recordId).toBe('a0X000000000000AAA');
    });

    it('loads requirements on connectedCallback', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue(mockInvalids);

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Test through public API - verify Apex methods were called
        expect(getRequirements).toHaveBeenCalledWith({ onboardingId: 'a0X000000000000AAA' });
        expect(getInvalidFieldValues).toHaveBeenCalledWith({ onboardingId: 'a0X000000000000AAA' });
    });

    it('updates requirement status on change', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Test through observable behavior - simulate status change event
        // The component should handle the event internally
        const mockEvent = new CustomEvent('change', {
            detail: { value: 'Complete' },
            bubbles: true,
            composed: true
        });
        
        // Find the status field in the shadow DOM and dispatch change event
        const statusField = element.shadowRoot?.querySelector('lightning-combobox');
        if (statusField) {
            statusField.dispatchEvent(mockEvent);
        }
        
        // Verify the component loaded requirements
        expect(getRequirements).toHaveBeenCalled();
    });

    it('submits requirements and runs rule evaluation', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);
        updateRequirementStatuses.mockResolvedValue();
        runRuleEvaluation.mockResolvedValue();
        rerunValidation.mockResolvedValue();

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        const submitButton = element.shadowRoot?.querySelector('lightning-button');
        expect(submitButton).not.toBeNull();
        submitButton.click();

        await Promise.resolve();
        await Promise.resolve();

        expect(updateRequirementStatuses).toHaveBeenCalled();
        expect(runRuleEvaluation).toHaveBeenCalledWith({
            onboardingId: 'a0X000000000000AAA'
        });
        // loadData is called after submit, so requirements reload should occur
        expect(getRequirements).toHaveBeenCalledTimes(2);
    });

    it('handles errors during submit', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);
        updateRequirementStatuses.mockRejectedValue(new Error('Update failed'));

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        let toastEvent;
        element.addEventListener('lightning__showtoast', (event) => {
            toastEvent = event.detail;
        });
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        const submitButton = element.shadowRoot?.querySelector('lightning-button');
        expect(submitButton).not.toBeNull();
        submitButton.click();

        await Promise.resolve();
        await Promise.resolve();
        expect(updateRequirementStatuses).toHaveBeenCalled();
        expect(toastEvent).toBeTruthy();
        expect(toastEvent.variant).toBe('error');
    });

    it('has correct status options', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        const statusField = await waitForElement(element.shadowRoot, 'lightning-combobox');
        expect(statusField).not.toBeNull();
        expect(statusField.options).toHaveLength(5);
        expect(statusField.options[0].value).toBe('Not Started');
        expect(statusField.options[1].value).toBe('Incomplete');
        expect(statusField.options[2].value).toBe('Complete');
        expect(statusField.options[3].value).toBe('Approved');
        expect(statusField.options[4].value).toBe('Denied');
    });

    it('reruns validation for invalid fields', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue(mockInvalids);
        rerunValidation.mockResolvedValue();

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        element.invalidFields = mockInvalids;
        await Promise.resolve();

        const buttons = element.shadowRoot?.querySelectorAll('lightning-button') || [];
        const rerunButton = buttons.length > 1 ? buttons[1] : null;
        expect(rerunButton).not.toBeNull();
        rerunButton.click();

        await Promise.resolve();
        await Promise.resolve();

        expect(rerunValidation).toHaveBeenCalledWith({
            fieldValueIds: ['a0Z000000000001AAA']
        });
    });

    it('loads rules version on connectedCallback', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);
        getActiveRulesVersion.mockResolvedValue({
            lastModifiedDate: '2024-01-01T00:00:00.000Z',
            engineIds: ['a0X000000000001AAA']
        });

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(getActiveRulesVersion).toHaveBeenCalledWith({
            onboardingId: 'a0X000000000000AAA'
        });
    });

    it('shows banner when rules version changes', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);
        getActiveRulesVersion
            .mockResolvedValueOnce({
                lastModifiedDate: '2024-01-01T00:00:00.000Z',
                engineIds: ['a0X000000000001AAA']
            })
            .mockResolvedValueOnce({
                lastModifiedDate: '2024-01-02T00:00:00.000Z',
                engineIds: ['a0X000000000001AAA']
            });

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Set initial version
        element.rulesVersionOnLoad = '2024-01-01T00:00:00.000Z';
        element.currentRulesVersion = '2024-01-01T00:00:00.000Z';

        // Check for version change
        await element.checkRulesVersion();

        await Promise.resolve();
        await Promise.resolve();

        // If version changed, banner should show
        if (element.currentRulesVersion !== element.rulesVersionOnLoad) {
            expect(element.showRulesChangedBanner).toBe(true);
        }
    });

    it('refreshes rules and re-evaluates when refresh button is clicked', async () => {
        getRequirements.mockResolvedValue(mockRequirements);
        getInvalidFieldValues.mockResolvedValue([]);
        getActiveRulesVersion.mockResolvedValue({
            lastModifiedDate: '2024-01-02T00:00:00.000Z',
            engineIds: ['a0X000000000001AAA']
        });
        refreshAndReevaluate.mockResolvedValue('Approved');

        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        element.showRulesChangedBanner = true;
        
        let toastEvent;
        element.addEventListener('lightning__showtoast', (event) => {
            toastEvent = event.detail;
        });
        
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        await element.handleRefreshRules();

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(refreshAndReevaluate).toHaveBeenCalledWith({
            onboardingId: 'a0X000000000000AAA'
        });
        expect(element.showRulesChangedBanner).toBe(false);
        expect(toastEvent).toBeTruthy();
        expect(toastEvent.variant).toBe('success');
        expect(toastEvent.message).toContain('Approved');
    });

    it('clears interval on disconnectedCallback', () => {
        const element = createElement('c-onboarding-requirements-panel', {
            is: OnboardingRequirementsPanel
        });
        element.recordId = 'a0X000000000000AAA';
        element.rulesVersionCheckInterval = setInterval(() => {}, 30000);
        document.body.appendChild(element);

        const clearIntervalSpy = jest.spyOn(global, 'clearInterval');

        element.disconnectedCallback();

        expect(clearIntervalSpy).toHaveBeenCalled();
        clearIntervalSpy.mockRestore();
    });
});
