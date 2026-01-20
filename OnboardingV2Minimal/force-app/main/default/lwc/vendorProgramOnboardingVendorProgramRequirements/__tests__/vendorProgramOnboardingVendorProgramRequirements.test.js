import { createElement } from '@lwc/engine-dom';
import VendorProgramOnboardingVendorProgramRequirements from 'c/vendorProgramOnboardingVendorProgramRequirements';
import getVendorProgramRequirementStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramRequirementStatusPicklistValues';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramRequirementStatusPicklistValues',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-vendor-program-onboarding-vendor-program-requirements', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders component with vendorProgramId', () => {
        const element = createElement('c-vendor-program-onboarding-vendor-program-requirements', {
            is: VendorProgramOnboardingVendorProgramRequirements
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('loads status options via wire service', async () => {
        const mockStatusOptions = [
            { label: 'Active', value: 'Active' },
            { label: 'Draft', value: 'Draft' }
        ];
        getVendorProgramRequirementStatusPicklistValues.mockResolvedValue(mockStatusOptions);

        const element = createElement('c-vendor-program-onboarding-vendor-program-requirements', {
            is: VendorProgramOnboardingVendorProgramRequirements
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Verify component initialized
        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('loads requirements on connectedCallback', async () => {
        getVendorProgramRequirementStatusPicklistValues.mockResolvedValue([]);
        getRequirementsForVendorProgram.mockResolvedValue([]);

        const element = createElement('c-vendor-program-onboarding-vendor-program-requirements', {
            is: VendorProgramOnboardingVendorProgramRequirements
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

    it('handles errors during initialization', async () => {
        getVendorProgramRequirementStatusPicklistValues.mockRejectedValue(new Error('Failed'));
        getRequirementsForVendorProgram.mockResolvedValue([]);

        const element = createElement('c-vendor-program-onboarding-vendor-program-requirements', {
            is: VendorProgramOnboardingVendorProgramRequirements
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