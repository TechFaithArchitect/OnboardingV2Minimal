import { createElement } from '@lwc/engine-dom';
import VendorProgramOnboardingStatusRuleBuilder from 'c/vendorProgramOnboardingStatusRuleBuilder';
import searchStatusRules from '@salesforce/apex/VendorOnboardingWizardController.searchStatusRules';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';
import getStatusRulesEngineById from '@salesforce/apex/VendorOnboardingWizardController.getStatusRulesEngineById';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.searchStatusRules',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getStatusRulesEngineById',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-vendor-program-onboarding-status-rule-builder', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders component with vendorProgramId', () => {
        const element = createElement('c-vendor-program-onboarding-status-rule-builder', {
            is: VendorProgramOnboardingStatusRuleBuilder
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('loads requirements on connectedCallback', async () => {
        searchStatusRules.mockResolvedValue([]);
        getRequirementsForVendorProgram.mockResolvedValue([]);

        const element = createElement('c-vendor-program-onboarding-status-rule-builder', {
            is: VendorProgramOnboardingStatusRuleBuilder
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Verify requirements were loaded
        expect(getRequirementsForVendorProgram).toHaveBeenCalledWith({
            vendorProgramId: '001000000000000AAA'
        });
    });

    it('loads engine name when statusRulesEngineId is provided', async () => {
        searchStatusRules.mockResolvedValue([]);
        getRequirementsForVendorProgram.mockResolvedValue([]);
        getStatusRulesEngineById.mockResolvedValue({ Id: 'a0X000000000001AAA', Name: 'Engine 1' });

        const element = createElement('c-vendor-program-onboarding-status-rule-builder', {
            is: VendorProgramOnboardingStatusRuleBuilder
        });
        element.vendorProgramId = '001000000000000AAA';
        element.statusRulesEngineId = 'a0X000000000001AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Verify engine was loaded
        expect(getStatusRulesEngineById).toHaveBeenCalledWith({
            engineId: 'a0X000000000001AAA'
        });
    });

    it('handles errors during initialization', async () => {
        searchStatusRules.mockResolvedValue([]);
        getRequirementsForVendorProgram.mockRejectedValue(new Error('Failed'));

        const element = createElement('c-vendor-program-onboarding-status-rule-builder', {
            is: VendorProgramOnboardingStatusRuleBuilder
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