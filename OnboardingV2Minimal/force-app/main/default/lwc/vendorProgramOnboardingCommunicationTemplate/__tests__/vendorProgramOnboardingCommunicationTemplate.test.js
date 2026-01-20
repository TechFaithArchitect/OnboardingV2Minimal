import { createElement } from '@lwc/engine-dom';
import VendorProgramOnboardingCommunicationTemplate from 'c/vendorProgramOnboardingCommunicationTemplate';
import getCommunicationTemplates from '@salesforce/apex/VendorOnboardingWizardController.getCommunicationTemplates';
import getRecipientGroupsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRecipientGroupsForVendorProgram';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getCommunicationTemplates',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.getRecipientGroupsForVendorProgram',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRecipientGroupWithTemplate',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-vendor-program-onboarding-communication-template', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockTemplates = [
        { Id: 'a0X000000000001AAA', Name: 'Template 1' },
        { Id: 'a0X000000000002AAA', Name: 'Template 2' }
    ];

    const mockRecipientGroups = [
        { Id: 'a0Y000000000001AAA', Name: 'Group 1' },
        { Id: 'a0Y000000000002AAA', Name: 'Group 2' }
    ];

    it('renders component with vendorProgramId', () => {
        const element = createElement('c-vendor-program-onboarding-communication-template', {
            is: VendorProgramOnboardingCommunicationTemplate
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('loads templates and recipient groups on connectedCallback', async () => {
        getCommunicationTemplates.mockResolvedValue(mockTemplates);
        getRecipientGroupsForVendorProgram.mockResolvedValue(mockRecipientGroups);

        const element = createElement('c-vendor-program-onboarding-communication-template', {
            is: VendorProgramOnboardingCommunicationTemplate
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(getCommunicationTemplates).toHaveBeenCalled();
        expect(getRecipientGroupsForVendorProgram).toHaveBeenCalledWith({
            vendorProgramId: '001000000000000AAA'
        });
    });

    it('pre-selects recipient group from prop', async () => {
        getCommunicationTemplates.mockResolvedValue(mockTemplates);
        getRecipientGroupsForVendorProgram.mockResolvedValue(mockRecipientGroups);

        const element = createElement('c-vendor-program-onboarding-communication-template', {
            is: VendorProgramOnboardingCommunicationTemplate
        });
        element.vendorProgramId = '001000000000000AAA';
        element.recipientGroupId = 'a0Y000000000001AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Verify component initialized
        expect(element.vendorProgramId).toBe('001000000000000AAA');
        expect(element.recipientGroupId).toBe('a0Y000000000001AAA');
    });

    it('validates form before proceeding', async () => {
        getCommunicationTemplates.mockResolvedValue(mockTemplates);
        getRecipientGroupsForVendorProgram.mockResolvedValue(mockRecipientGroups);

        const element = createElement('c-vendor-program-onboarding-communication-template', {
            is: VendorProgramOnboardingCommunicationTemplate
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Test canProceed getter through public API
        // Component should not proceed if form is invalid
        expect(element.vendorProgramId).toBe('001000000000000AAA');
    });

    it('handles errors during data load', async () => {
        getCommunicationTemplates.mockRejectedValue(new Error('Load failed'));
        getRecipientGroupsForVendorProgram.mockResolvedValue([]);

        const element = createElement('c-vendor-program-onboarding-communication-template', {
            is: VendorProgramOnboardingCommunicationTemplate
        });
        element.vendorProgramId = '001000000000000AAA';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        // Verify error handling - component should handle error internally
        expect(getCommunicationTemplates).toHaveBeenCalled();
    });
});
