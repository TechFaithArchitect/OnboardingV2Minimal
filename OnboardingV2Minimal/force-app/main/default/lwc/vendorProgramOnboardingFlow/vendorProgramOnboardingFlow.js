import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getProcessIdForVendorProgram from '@salesforce/apex/OnboardingApplicationService.getProcessIdForVendorProgram';

export default class VendorProgramOnboardingFlow extends NavigationMixin(LightningElement) {
  @api recordId;
  @api vendorProgramId; // Allow passing vendor program ID directly

  @wire(CurrentPageReference)
  pageRef;

  // Use vendorProgramId if provided, otherwise fall back to recordId, then try URL param
  get effectiveVendorProgramId() {
    if (this.vendorProgramId) {
      return this.vendorProgramId;
    }
    if (this.recordId) {
      return this.recordId;
    }
    // Try to get from URL parameter
    if (this.pageRef?.state?.c__vendorProgramId) {
      return this.pageRef.state.c__vendorProgramId;
    }
    return null;
  }

  @wire(getProcessIdForVendorProgram, { vendorProgramId: '$effectiveVendorProgramId' })
  processIdResult;

  get hasProcessId() {
    return !!this.processIdResult?.data;
  }

  get processId() {
    return this.processIdResult?.data;
  }

  get error() {
    return this.processIdResult?.error;
  }

  get hasError() {
    // Show error if wire returned an error, or if data is explicitly null/undefined (meaning no process found)
    // Only show error after wire has completed (not undefined)
    if (this.processIdResult?.data === undefined && !this.processIdResult?.error) {
      return false; // Still loading
    }
    // Show error if there's an actual error, or if data is null (no process found)
    return !!this.processIdResult?.error || this.processIdResult?.data === null;
  }

  get showWizard() {
    // Show wizard if we have a process ID
    return !!this.processId;
  }

  handleGoToDashboard() {
    // Navigate to the home dashboard
    this[NavigationMixin.Navigate]({
      type: 'standard__namedPage',
      attributes: {
        pageName: 'home'
      }
    });
  }
}
