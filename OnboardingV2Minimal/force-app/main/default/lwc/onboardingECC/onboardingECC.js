import { LightningElement, api, wire } from "lwc";
import getECCRecordsForOnboarding from "@salesforce/apex/ContactECCController.getECCRecordsForOnboarding";

export default class OnboardingECC extends LightningElement {
  @api recordId; // the Onboarding__c Id
  eccRecords;
  error;

  @wire(getECCRecordsForOnboarding, { onboardingId: "$recordId" })
  wiredECC({ data, error }) {
    if (data) {
      this.eccRecords = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.eccRecords = undefined;
    }
  }
}
