import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import searchVendorPrograms from '@salesforce/apex/VendorOnboardingWizardController.searchVendorPrograms';
import createVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgram';
import getRetailOptionPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getRetailOptionPicklistValues';
import getBusinessVerticalPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getBusinessVerticalPicklistValues';

export default class VendorProgramOnboardingVendorProgramSearchOrCreate extends OnboardingStepBase {
    stepName = 'Vendor Program Search or Create';
    
    @api vendorId;
    @track searchText = '';
    @track programs = [];
    @track selectedProgramId = '';
    @track newProgramName = '';
    @track newProgramLabel = '';
    @track newProgramRetailOption = '';
    @track newProgramBusinessVertical = '';
    @track showCreateForm = false;
    @track nextDisabled = true;
    @track retailOptionOptions = [];
    @track businessVerticalOptions = [];

    connectedCallback() {
        super.connectedCallback(); // Call base class for event listeners
    }

    get canProceed() {
        return !this.nextDisabled;
    }

    @wire(getRetailOptionPicklistValues)
    wiredRetailOptions({ error, data }) {
        if (data) {
            this.retailOptionOptions = data;
        } else if (error) {
            this.handleError(error, 'Failed to load Retail Option options');
            this.retailOptionOptions = [];
        }
    }

    @wire(getBusinessVerticalPicklistValues)
    wiredBusinessVerticalOptions({ error, data }) {
        if (data) {
            this.businessVerticalOptions = data;
        } else if (error) {
            this.handleError(error, 'Failed to load Business Vertical options');
            this.businessVerticalOptions = [];
        }
    }

    handleSearchChange(e) {
        this.searchText = e.target.value;
    }

    handleSearchKeydown(e) {
        if (e.key === 'Enter' || e.keyCode === 13) {
            this.searchVendorPrograms();
        }
    }

    handleNewProgramChange(e) {
        this.newProgramName = e.target.value;
        this.validateCreateForm();
    }

    handleNewProgramLabelChange(e) {
        this.newProgramLabel = e.target.value;
        this.validateCreateForm();
    }

    handleRetailOptionChange(e) {
        this.newProgramRetailOption = e.detail.value;
        this.validateCreateForm();
    }

    handleBusinessVerticalChange(e) {
        this.newProgramBusinessVertical = e.detail.value;
        this.validateCreateForm();
    }

    validateCreateForm() {
        const hasSelectedProgram = !!this.selectedProgramId;
        const hasValidCreateForm = !!(this.newProgramName?.trim() && 
                                      this.newProgramLabel?.trim() && 
                                      this.newProgramRetailOption && 
                                      this.newProgramBusinessVertical);
        this.nextDisabled = !(hasSelectedProgram || hasValidCreateForm);
        this.dispatchValidationState();
    }

    async searchVendorPrograms() {
        if (!this.searchText || this.searchText.trim().length === 0) {
            this.programs = [];
            return;
        }
        try {
            this.programs = await searchVendorPrograms({ vendorProgramNameSearchText: this.searchText.trim() });
        } catch (err) {
            this.handleError(err, 'Failed to search vendor programs');
            this.programs = [];
        }
    }

    handleProgramSelect(e) {
        this.selectedProgramId = e.detail.value;
        this.newProgramName = '';
        this.newProgramLabel = '';
        this.newProgramRetailOption = '';
        this.newProgramBusinessVertical = '';
        this.showCreateForm = false;
        this.validateCreateForm();
    }

    toggleCreateForm() {
        this.showCreateForm = !this.showCreateForm;
        if (!this.showCreateForm) {
            this.newProgramName = '';
            this.newProgramLabel = '';
            this.newProgramRetailOption = '';
            this.newProgramBusinessVertical = '';
            this.validateCreateForm();
        }
    }

    async createProgram() {
        if (!this.newProgramName?.trim() || !this.newProgramLabel?.trim() || !this.newProgramRetailOption || !this.newProgramBusinessVertical || !this.vendorId) {
            this.showToast('Required Fields Missing', 'Please fill in all required fields: Name, Label, Retail Option, and Business Vertical.', 'warning');
            return;
        }

        try {
            const program = {
                Name: this.newProgramName.trim(),
                Label__c: this.newProgramLabel.trim(),
                Retail_Option__c: this.newProgramRetailOption,
                Business_Vertical__c: this.newProgramBusinessVertical
            };

            const programId = await createVendorProgram({
                vendorProgram: program,
                vendorId: this.vendorId
            });

            this.selectedProgramId = programId;
            this.programs = [];
            this.newProgramName = '';
            this.newProgramLabel = '';
            this.newProgramRetailOption = '';
            this.newProgramBusinessVertical = '';
            this.showCreateForm = false;
            this.nextDisabled = false;
            this.dispatchValidationState();
            this.showToast('Success', 'Vendor Program created successfully in Draft status!', 'success');
        } catch (err) {
            this.handleError(err, 'Failed to create vendor program');
        }
    }

    proceedToNext() {
        this.dispatchNextEvent({
            vendorProgramId: this.selectedProgramId,
            vendorId: this.vendorId
        });
    }

    get programOptions() {
        return this.programs.map(p => ({
            label: p.Name,
            value: p.Id
        }));
    }

    get createButtonLabel() {
        return this.showCreateForm ? 'Cancel Create' : 'Create New Draft Program';
    }

}
