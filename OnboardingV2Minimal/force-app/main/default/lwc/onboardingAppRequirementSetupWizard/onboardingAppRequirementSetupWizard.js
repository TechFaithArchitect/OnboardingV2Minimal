import { LightningElement, track, wire } from 'lwc';
import createOnboardingRequirementSet from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingRequirementSet';
import createOnboardingRequirementTemplate from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingRequirementTemplate';
import getRequirementTemplatesForSet from '@salesforce/apex/VendorOnboardingWizardController.getRequirementTemplatesForSet';
import REQUIREMENT_TYPE_FIELD from '@salesforce/schema/Vendor_Program_Onboarding_Req_Template__c.Requirement_Type__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';


export default class OnboardingAppRequirementSetupWizard extends LightningElement {
    @track requirementSetName = '';
    @track newTemplateName = '';
    @track newRequirementType = '';
    @track requirementTemplates = [];
    @track requirementSetId = null;
    @track requirementSetCreated = false;
    @track requirementTypeOptions = [];


    @wire(getPicklistValues, { fieldApiName: REQUIREMENT_TYPE_FIELD })
    picklistValuesHandler({ data, error }) {
        if (data) {
            this.requirementTypeOptions = data.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        } else if (error) {
            // Silently fail - requirementTypeOptions will remain empty
        }
    }

    get isDoneDisabled() {
        return this.requirementTemplates.length === 0;
    }

    handleRequirementSetNameChange(e) {
        this.requirementSetName = e.target.value;
    }

    handleNewTemplateNameChange(e) {
        this.newTemplateName = e.target.value;
    }

    handleRequirementTypeChange(e) {
        this.newRequirementType = e.detail.value;
    }

    async createRequirementSet() {
        try {
        const reqSet = { Name: this.requirementSetName };
        const id = await createOnboardingRequirementSet({ requirementSet: reqSet });
        this.requirementSetId = id;
        this.requirementSetCreated = true;
        } catch (err) {
        // Silently fail - requirement set will not be created
        }
    }

    async addRequirementTemplate() {
        if (!this.newTemplateName || !this.newRequirementType || !this.requirementSetId) return;

        try {
        await createOnboardingRequirementTemplate({
            template: {
            Name: this.newTemplateName,
            Requirement_Type__c: this.newRequirementType,
            Onboarding_Requirement_Set__c: this.requirementSetId
            }
        });

        const templates = await getRequirementTemplatesForSet({ requirementSetId: this.requirementSetId });
        this.requirementTemplates = templates;

        this.newTemplateName = '';
        this.newRequirementType = '';
        } catch (err) {
        // Silently fail - template will not be added
        }
    }

    finalizeSetup() {
        this.dispatchEvent(new CustomEvent('next', {
        detail: { requirementSetId: this.requirementSetId }
        }));
    }
}
