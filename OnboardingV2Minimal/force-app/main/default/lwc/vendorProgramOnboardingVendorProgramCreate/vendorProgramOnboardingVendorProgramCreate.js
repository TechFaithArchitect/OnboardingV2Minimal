import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import finalizeVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.finalizeVendorProgram';
import getRetailOptionPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getRetailOptionPicklistValues';
import getBusinessVerticalPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getBusinessVerticalPicklistValues';

const FIELDS = ['Vendor_Customization__c.Label__c', 'Vendor_Customization__c.Retail_Option__c', 'Vendor_Customization__c.Business_Vertical__c'];

export default class VendorProgramOnboardingVendorProgramCreate extends OnboardingStepBase {
  stepName = 'Create Vendor Program';
  
  @api vendorProgramId;
  @api vendorId;
  @api programGroupId;
  @api requirementGroupId;

  @track label = '';
  @track retailOption = '';
  @track businessVertical = '';
  @track retailOptionOptions = [];
  @track businessVerticalOptions = [];
  @track nextDisabled = false;
  @track isLoading = true;

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
  }

  handleFooterNextClick() {
    // Override: trigger finalize when footer Next is clicked
    if (this.canProceed) {
      this.finalizeProgram();
    }
  }

  get canProceed() {
    return this.isFormValid;
  }

  proceedToNext() {
    // Called from finalizeProgram after completion
    this.dispatchNextEvent({ vendorProgramId: this.vendorProgramId });
  }

  @wire(getRecord, { recordId: '$vendorProgramId', fields: FIELDS })
  wiredVendorProgram({ error, data }) {
    if (data) {
      this.label = data.fields.Label__c?.value || '';
      this.retailOption = data.fields.Retail_Option__c?.value || '';
      this.businessVertical = data.fields.Business_Vertical__c?.value || '';
      this.isLoading = false;
    } else if (error) {
      this.handleError(error, 'Failed to load vendor program');
      this.isLoading = false;
    }
  }

  @wire(getRetailOptionPicklistValues)
  wiredRetailOptions({ error, data }) {
    if (data) {
      this.retailOptionOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Retail Option picklist values');
    }
  }

  @wire(getBusinessVerticalPicklistValues)
  wiredBusinessVerticals({ error, data }) {
    if (data) {
      this.businessVerticalOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Business Vertical picklist values');
    }
  }

  handleLabelChange(event) {
    this.label = event.target.value;
    this.dispatchValidationState();
  }

  handleRetailOptionChange(event) {
    this.retailOption = event.detail.value;
    this.dispatchValidationState();
  }

  handleBusinessVerticalChange(event) {
    this.businessVertical = event.detail.value;
    this.dispatchValidationState();
  }

  get isFormValid() {
    return this.label && this.label.trim().length > 0;
  }

  async finalizeProgram() {
    if (!this.isFormValid) {
      this.dispatchEvent(new ShowToastEvent({
        title: 'Validation Error',
        message: 'Label is required',
        variant: 'error'
      }));
      return;
    }

    try {
      this.nextDisabled = true;

      // Update the three fields
      const fields = {
        Id: this.vendorProgramId,
        Label__c: this.label,
        Retail_Option__c: this.retailOption || null,
        Business_Vertical__c: this.businessVertical || null
      };

      const recordInput = { fields };
      await updateRecord(recordInput);

      // Finalize vendor program (link to groups)
      await finalizeVendorProgram({
        vendorProgramId: this.vendorProgramId,
        vendorId: this.vendorId,
        vendorProgramGroupId: this.programGroupId,
        vendorProgramRequirementGroupId: this.requirementGroupId
      });

      this.showToast('Success', 'Vendor Program updated successfully', 'success');

      // Pass vendorProgramId back to flow
      this.proceedToNext();
    } catch (error) {
      this.handleError(error, 'Failed to finalize vendor program');
      this.nextDisabled = false;
    }
  }

}
