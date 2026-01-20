import { api, track } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import getCommunicationTemplates from '@salesforce/apex/VendorOnboardingWizardController.getCommunicationTemplates';
import getRecipientGroupsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRecipientGroupsForVendorProgram';
import createVendorProgramRecipientGroupWithTemplate from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRecipientGroupWithTemplate';

export default class VendorProgramOnboardingCommunicationTemplate extends OnboardingStepBase {
  stepName = 'Communication Template';
  
  @api vendorProgramId;
  @api stageId;
  @api recipientGroupId; // From Step 9 (optional)

  @track templates = [];
  @track recipientGroups = [];
  @track selectedTemplateId = '';
  @track selectedRecipientGroupId = '';
  @track triggerCondition = '';
  @track isLoading = false;

  get hasTemplates() {
    return this.templates?.length > 0;
  }

  get hasRecipientGroups() {
    return this.recipientGroups?.length > 0;
  }

  get isFormValid() {
    return this.selectedTemplateId && this.selectedRecipientGroupId && this.triggerCondition?.trim();
  }

  async connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    this.isLoading = true;
    try {
      [this.templates, this.recipientGroups] = await Promise.all([
        getCommunicationTemplates(),
        getRecipientGroupsForVendorProgram({ vendorProgramId: this.vendorProgramId })
      ]);

      // Pre-select recipient group from Step 9 if provided
      if (this.recipientGroupId) {
        this.selectedRecipientGroupId = this.recipientGroupId;
      }
    } catch (error) {
      this.handleError(error, 'Failed to load communication templates and recipient groups');
    } finally {
      this.isLoading = false;
    }
  }

  handleFooterNextClick() {
    // Override: trigger save and continue when footer Next is clicked
    if (this.canProceed) {
      this.handleSaveClick();
    }
  }

  get canProceed() {
    return this.isFormValid;
  }

  proceedToNext() {
    // Called from handleSaveClick after successful save
    this.dispatchNextEvent({
      vendorProgramId: this.vendorProgramId,
      communicationTemplateId: this.selectedTemplateId,
      recipientGroupId: this.selectedRecipientGroupId,
      triggerCondition: this.triggerCondition
    });
  }

  handleTemplateChange(event) {
    this.selectedTemplateId = event.detail.value;
    this.dispatchValidationState();
  }

  handleRecipientGroupChange(event) {
    this.selectedRecipientGroupId = event.detail.value;
    this.dispatchValidationState();
  }

  handleTriggerConditionChange(event) {
    this.triggerCondition = event.target.value;
    this.dispatchValidationState();
  }

  async handleSaveClick() {
    if (!this.isFormValid) {
      this.showToast('Required Fields Missing', 'Please select Communication Template, Recipient Group, and enter a Trigger Condition.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      await createVendorProgramRecipientGroupWithTemplate({
        vendorProgramId: this.vendorProgramId,
        recipientGroupId: this.selectedRecipientGroupId,
        communicationTemplateId: this.selectedTemplateId,
        triggerCondition: this.triggerCondition.trim()
      });

      this.showToast('Success', 'Communication Template linked with Recipient Group and trigger condition!', 'success');

      this.proceedToNext();
    } catch (error) {
      this.handleError(error, 'Failed to link communication template with recipient group');
    } finally {
      this.isLoading = false;
    }
  }

  get templateOptions() {
    return this.templates.map(t => ({
      label: t.Name || t.label,
      value: t.Id || t.value
    }));
  }

  get recipientGroupOptions() {
    return this.recipientGroups.map(rg => ({
      label: rg.Recipient_Group__r?.Name || rg.Name,
      value: rg.Recipient_Group__c || rg.Id
    }));
  }

  get isSaveDisabled() {
    return !this.isFormValid;
  }

}
