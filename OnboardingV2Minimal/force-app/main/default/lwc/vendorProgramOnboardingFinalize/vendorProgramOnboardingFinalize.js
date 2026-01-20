import { api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import OnboardingStepBase from 'c/onboardingStepBase';

export default class VendorProgramOnboardingFinalize extends NavigationMixin(OnboardingStepBase) {
  stepName = 'Finalize';
  
  @api vendorProgramId;
  @api stageId;

  @track isLoading = false;

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
  }

  handleFooterNextClick() {
    // Override: trigger complete when footer Next is clicked
    if (this.canProceed) {
      this.handleComplete();
    }
  }

  get canProceed() {
    // Finalize step can always proceed
    return true;
  }

  proceedToNext() {
    // Not used - handleComplete handles navigation directly
    this.dispatchNextEvent({});
  }

  handleComplete() {
    this.isLoading = true;
    
    // Show success message
    this.showToast('Success', 'Vendor Program Onboarding completed successfully!', 'success');

    // Navigate to the Vendor Program record
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.vendorProgramId,
        actionName: 'view'
      }
    });
  }


}

