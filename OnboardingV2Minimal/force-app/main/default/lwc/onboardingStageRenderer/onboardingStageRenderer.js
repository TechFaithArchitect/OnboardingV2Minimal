import { LightningElement, api } from 'lwc';

export default class OnboardingStageRenderer extends LightningElement {
  @api componentName;
  @api context;

  // ✅ Extract individual props from context object for cleaner prop passing
  get vendorProgramId() {
    return this.context?.vendorProgramId;
  }

  get stageId() {
    return this.context?.stageId;
  }

  get stepNumber() {
    return this.context?.stepNumber;
  }

  get requirementSetId() {
    return this.context?.requirementSetId;
  }

  get requirementTemplateId() {
    return this.context?.requirementTemplateId;
  }

  get requirementGroupId() {
    return this.context?.requirementGroupId;
  }

  get statusRulesEngineId() {
    return this.context?.statusRulesEngineId;
  }

  // Note: vendorId comes from previous stage events, not context
  // Components that need vendorId will get it from the 'next' event detail

  // ✅ Getters to determine which component to show (LWC requires static conditional rendering)
  get showVendorProgramOnboardingVendor() {
    return this.componentName === 'vendorProgramOnboardingVendor';
  }

  get showVendorProgramOnboardingVendorProgramCreate() {
    return this.componentName === 'vendorProgramOnboardingVendorProgramCreate';
  }

  get showVendorProgramOnboardingVendorProgramGroup() {
    return this.componentName === 'vendorProgramOnboardingVendorProgramGroup';
  }

  get showVendorProgramOnboardingVendorProgramRequirementGroup() {
    return this.componentName === 'vendorProgramOnboardingVendorProgramRequirementGroup';
  }

  get showVendorProgramOnboardingVendorProgramRecipientGroup() {
    return this.componentName === 'vendorProgramOnboardingVendorProgramRecipientGroup';
  }

  get showVendorProgramOnboardingRecipientGroup() {
    return this.componentName === 'vendorProgramOnboardingRecipientGroup';
  }

  get showVendorProgramOnboardingRecipientGroupMembers() {
    return this.componentName === 'vendorProgramOnboardingRecipientGroupMembers';
  }

  get showVendorProgramOnboardingTrainingRequirements() {
    return this.componentName === 'vendorProgramOnboardingTrainingRequirements';
  }

  get showVendorProgramOnboardingRequiredCredentials() {
    return this.componentName === 'vendorProgramOnboardingRequiredCredentials';
  }

  get showVendorProgramOnboardingVendorProgramSearchOrCreate() {
    return this.componentName === 'vendorProgramOnboardingVendorProgramSearchOrCreate';
  }

  get showVendorProgramOnboardingVendorProgramRequirements() {
    return this.componentName === 'vendorProgramOnboardingVendorProgramRequirements';
  }

  get showVendorProgramOnboardingStatusRulesEngine() {
    return this.componentName === 'vendorProgramOnboardingStatusRulesEngine';
  }

  get showVendorProgramOnboardingStatusRuleBuilder() {
    return this.componentName === 'vendorProgramOnboardingStatusRuleBuilder';
  }

  get showVendorProgramOnboardingCommunicationTemplate() {
    return this.componentName === 'vendorProgramOnboardingCommunicationTemplate';
  }

  get showVendorProgramOnboardingRequirementSet() {
    return this.componentName === 'vendorProgramOnboardingRequirementSet';
  }

  get showVendorProgramOnboardingReqTemplate() {
    return this.componentName === 'vendorProgramOnboardingReqTemplate';
  }

  get showVendorProgramOnboardingRequirementSetOrCreate() {
    return this.componentName === 'vendorProgramOnboardingRequirementSetOrCreate';
  }

  get showVendorProgramOnboardingRequirementGroupLinking() {
    return this.componentName === 'vendorProgramOnboardingRequirementGroupLinking';
  }

  get showVendorProgramOnboardingFinalize() {
    return this.componentName === 'vendorProgramOnboardingFinalize';
  }


  // ✅ Check if component name matches any known component
  get hasValidComponent() {
    return this.showVendorProgramOnboardingVendor ||
           this.showVendorProgramOnboardingVendorProgramCreate ||
           this.showVendorProgramOnboardingVendorProgramGroup ||
           this.showVendorProgramOnboardingVendorProgramRequirementGroup ||
           this.showVendorProgramOnboardingVendorProgramRecipientGroup ||
           this.showVendorProgramOnboardingRecipientGroup ||
           this.showVendorProgramOnboardingRecipientGroupMembers ||
           this.showVendorProgramOnboardingTrainingRequirements ||
           this.showVendorProgramOnboardingRequiredCredentials ||
           this.showVendorProgramOnboardingVendorProgramSearchOrCreate ||
           this.showVendorProgramOnboardingRequirementSet ||
           this.showVendorProgramOnboardingReqTemplate ||
           this.showVendorProgramOnboardingRequirementSetOrCreate ||
           this.showVendorProgramOnboardingRequirementGroupLinking ||
           this.showVendorProgramOnboardingVendorProgramRequirements ||
           this.showVendorProgramOnboardingFinalize ||
           this.showVendorProgramOnboardingStatusRulesEngine ||
           this.showVendorProgramOnboardingStatusRuleBuilder ||
           this.showVendorProgramOnboardingCommunicationTemplate;
  }


  handleNext(event) {
    this.dispatchEvent(new CustomEvent('next', { 
      detail: event.detail,
      bubbles: true,
      composed: true
    }));
  }

  handleBack(event) {
    this.dispatchEvent(new CustomEvent('back', { 
      detail: event.detail,
      bubbles: true,
      composed: true
    }));
  }

  handleValidationChanged(event) {
    // Forward validationchanged events from step components
    this.dispatchEvent(new CustomEvent('validationchanged', { 
      detail: event.detail,
      bubbles: true,
      composed: true
    }));
  }

  // Public method to trigger next navigation (called by flow engine)
  @api
  triggerFooterNext() {
    // Forward to the currently active step component by dispatching event directly to it
    const stepComponent = this.template.querySelector('[data-step-component]');
    if (stepComponent) {
      // Dispatch event directly to the step component element
      stepComponent.dispatchEvent(new CustomEvent('footernavnext', {
        bubbles: true,
        composed: true
      }));
    }
  }

  // Public method to trigger back navigation (called by flow engine)
  @api
  triggerFooterBack() {
    // Forward to the currently active step component
    const stepComponent = this.template.querySelector('[data-step-component]');
    if (stepComponent) {
      // Dispatch event directly to the step component element
      stepComponent.dispatchEvent(new CustomEvent('footernavback', {
        bubbles: true,
        composed: true
      }));
    }
  }
}
