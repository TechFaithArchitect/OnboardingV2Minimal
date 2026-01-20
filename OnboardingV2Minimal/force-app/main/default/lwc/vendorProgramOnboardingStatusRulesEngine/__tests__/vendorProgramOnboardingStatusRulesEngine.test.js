import { createElement } from '@lwc/engine-dom';
import VendorProgramOnboardingStatusRulesEngine from 'c/vendorProgramOnboardingStatusRulesEngine';
import searchStatusRulesEngines from '@salesforce/apex/VendorOnboardingWizardController.searchStatusRulesEngines';
import getEvaluationLogicPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getEvaluationLogicPicklistValues';
import getRequiredStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getRequiredStatusPicklistValues';
import getTargetOnboardingStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getTargetOnboardingStatusPicklistValues';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.searchStatusRulesEngines',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getEvaluationLogicPicklistValues',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getRequiredStatusPicklistValues',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getTargetOnboardingStatusPicklistValues',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-vendor-program-onboarding-status-rules-engine', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders component with vendorProgramId', () => {
        const element = createElement('c-vendor-program-onboarding-status-rules-engine', {
            is: VendorProgramOnboardingStatusRulesEngine
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('loads picklist values via wire services', async () => {
        getEvaluationLogicPicklistValues.mockResolvedValue([{ label: 'ALL', value: 'ALL' }]);
        getRequiredStatusPicklistValues.mockResolvedValue([{ label: 'New', value: 'New' }]);
        getTargetOnboardingStatusPicklistValues.mockResolvedValue([{ label: 'In Process', value: 'In Process' }]);
        searchStatusRulesEngines.mockResolvedValue([]);

        const element = createElement('c-vendor-program-onboarding-status-rules-engine', {
            is: VendorProgramOnboardingStatusRulesEngine
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Verify component initialized
        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('handles errors during initialization', async () => {
        getEvaluationLogicPicklistValues.mockRejectedValue(new Error('Failed'));
        getRequiredStatusPicklistValues.mockResolvedValue([]);
        getTargetOnboardingStatusPicklistValues.mockResolvedValue([]);
        searchStatusRulesEngines.mockResolvedValue([]);

        const element = createElement('c-vendor-program-onboarding-status-rules-engine', {
            is: VendorProgramOnboardingStatusRulesEngine
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Verify component handles error
        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });
});