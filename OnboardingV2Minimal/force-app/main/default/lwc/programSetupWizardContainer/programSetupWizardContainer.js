import { LightningElement, api, wire } from "lwc";
import getRequirements from "@salesforce/apex/OnboardingRequirementsPanelController.getRequirements";

/**
 * programSetupWizardContainer
 * - Container component for Vendor Program Setup Wizard
 * - Manages the wizard flow for program setup
 * - Placeholder implementation using getRequirements as example
 */
export default class ProgramSetupWizardContainer extends LightningElement {
  @api recordId;
  @api programId;

  // Wizard step management
  currentStep = 1;
  totalSteps = 4;

  @wire(getRequirements, { onboardingId: "$recordId" })
  wiredRequirements({ error, data }) {
    if (error) {
      console.error("Error loading requirements (placeholder):", error);
    } else if (data) {
      this.processRequirementsData(data);
    }
  }

  processRequirementsData(data) {
    // Process requirements data for wizard
    console.log("Wizard requirements loaded (placeholder):", data);
  }

  // Navigation methods
  handleNext() {
    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
    }
  }

  handlePrevious() {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  handleFinish() {
    // Finish the wizard process
    console.log("Wizard finished");
  }
}
