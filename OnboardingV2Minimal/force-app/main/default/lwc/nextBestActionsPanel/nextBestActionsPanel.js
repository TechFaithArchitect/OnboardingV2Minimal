import { LightningElement, api, wire } from "lwc";
import getRequirements from "@salesforce/apex/OnboardingRequirementsPanelController.getRequirements";

/**
 * nextBestActionsPanel
 * - Component to display next best actions for onboarding
 * - Used in Dealer Experience to suggest next steps
 * - Placeholder implementation using getRequirements as example
 */
export default class NextBestActionsPanel extends LightningElement {
  @api recordId;
  @api parentId;

  @wire(getRequirements, { onboardingId: "$parentId" })
  wiredActions({ error, data }) {
    if (error) {
      console.error("Error loading requirements (placeholder):", error);
    } else if (data) {
      this.processActionsData(data);
    }
  }

  processActionsData(data) {
    // Process the data for display - this is a placeholder implementation
    console.log("Next best actions loaded (placeholder):", data);
  }
}
