import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHistoricalGroupMembers from '@salesforce/apex/VendorOnboardingWizardController.getHistoricalGroupMembers';
import createRequirementGroupComponents from '@salesforce/apex/VendorOnboardingWizardController.createRequirementGroupComponents';

export default class VendorProgramOnboardingRequirementGroupLinking extends LightningElement {
  @api vendorProgramId;
  @api stageId;
  @api stepNumber;
  @api requirementSetId; // From Step 4

  @track useHistorical = false;
  @track historicalMembers = [];
  @track isLoading = false;
  @track nextDisabled = true;
  @track hasHistoricalData = false;

  connectedCallback() {
    this.checkHistoricalData();
  }

  async checkHistoricalData() {
    if (!this.requirementSetId) {
      // No requirement set selected, must create new
      this.useHistorical = false;
      this.nextDisabled = false;
      return;
    }

    this.isLoading = true;
    try {
      this.historicalMembers = await getHistoricalGroupMembers({ requirementSetId: this.requirementSetId });
      this.hasHistoricalData = this.historicalMembers && this.historicalMembers.length > 0;
      
      if (this.hasHistoricalData) {
        // Default to using historical if available
        this.useHistorical = true;
      }
      this.nextDisabled = false;
    } catch (err) {
      this.hasHistoricalData = false;
      this.useHistorical = false;
      this.nextDisabled = false;
    } finally {
      this.isLoading = false;
    }
  }

  handleUseHistoricalChange(event) {
    this.useHistorical = event.target.checked;
  }

  async handleCreateAndLink() {
    this.isLoading = true;
    this.nextDisabled = true;

    try {
      const groupMemberId = await createRequirementGroupComponents({
        vendorProgramId: this.vendorProgramId,
        requirementSetId: this.requirementSetId,
        useHistorical: this.useHistorical
      });

      this.showToast('Success', 'Requirement Group components created and linked successfully!', 'success');

      // Proceed to next step
      this.dispatchEvent(new CustomEvent('next', {
        detail: {
          vendorProgramId: this.vendorProgramId,
          requirementSetId: this.requirementSetId,
          groupMemberId: groupMemberId
        }
      }));
    } catch (err) {
      const errorMessage = err.body?.message || err.message || 'Unknown error';
      this.showToast('Error', 'Failed to create requirement group components. ' + errorMessage, 'error');
      this.nextDisabled = false;
    } finally {
      this.isLoading = false;
    }
  }

  handleBack() {
    this.dispatchEvent(new CustomEvent('back'));
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(evt);
  }

  get showHistoricalOption() {
    return this.hasHistoricalData && this.requirementSetId;
  }

  get historicalInfoText() {
    if (!this.hasHistoricalData) {
      return 'No historical data found. New components will be created.';
    }
    const member = this.historicalMembers[0];
    return `Historical data found: Group "${member.Vendor_Program_Group__r?.Label__c || 'N/A'}" and Requirement Group "${member.Inherited_Program_Requirement_Group__r?.Name || 'N/A'}"`;
  }

  get cardTitle() {
    const step = this.stepNumber || '?';
    return `Step ${step}: Create and Link Requirement Group Components`;
  }
}

