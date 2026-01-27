import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { extractErrorMessage } from "c/utils";
import getVendorProgramGroups from "@salesforce/apex/OnboardingStatusRulesEngineController.getVendorProgramGroups";
import getRules from "@salesforce/apex/OnboardingStatusRulesEngineController.getRules";
import saveRules from "@salesforce/apex/OnboardingStatusRulesEngineController.saveRules";
import getOnboardingOptions from "@salesforce/apex/OnboardingStatusRulesEngineController.getOnboardingOptions";

export default class OnboardingStatusRulesEngine extends LightningElement {
  @track vendorProgramGroupOptions = [];
  @track onboardingOptions = [];
  @track rules = [];
  @track draftValues = [];
  @track showPreviewModal = false;
  @track selectedOnboardingId = null;

  selectedVendorProgramGroup;

  columns = [
    { label: "Name", fieldName: "Name", editable: false },
    {
      label: "Target Status",
      fieldName: "Target_Onboarding_Status__c",
      editable: true
    },
    {
      label: "Evaluation Logic",
      fieldName: "Evaluation_Logic__c",
      editable: true
    },
    {
      label: "Custom Evaluation Logic",
      fieldName: "Custom_Evaluation_Logic__c",
      editable: true
    }
  ];

  get isPreviewDisabled() {
    return (
      this.selectedOnboardingId == null || this.selectedOnboardingId === ""
    );
  }

  connectedCallback() {
    Promise.all([
      getVendorProgramGroups(),
      getOnboardingOptions({ limitCount: 50 })
    ])
      .then(([vendorGroups, onboardingOpts]) => {
        this.vendorProgramGroupOptions = vendorGroups;
        this.onboardingOptions = onboardingOpts || [];
      })
      .catch((error) => {
        this.showToast(
          "Error",
          extractErrorMessage(error, "Failed to load status rule groups."),
          "error"
        );
      });
  }

  handleVendorProgramGroupChange(event) {
    this.selectedVendorProgramGroup = event.detail.value;
  }

  async loadRules() {
    if (!this.selectedVendorProgramGroup) {
      this.showToast(
        "Selection Required",
        "Please select a Vendor Program Group before loading rules.",
        "warning"
      );
      return;
    }

    try {
      const result = await getRules({
        vendorProgramGroupId: this.selectedVendorProgramGroup
      });
      this.rules = result || [];
      this.draftValues = [];
    } catch (error) {
      this.showToast(
        "Error",
        extractErrorMessage(error, "Failed to load status rules."),
        "error"
      );
    }
  }

  async handleSave(event) {
    const updatedFields = event.detail.draftValues;
    if (!updatedFields || !updatedFields.length) {
      return;
    }

    try {
      await saveRules({ statusRulesEngineRecords: updatedFields });
      await this.loadRules();
      this.showToast("Success", "Status rules saved.", "success");
    } catch (error) {
      this.showToast(
        "Error",
        extractErrorMessage(error, "Failed to save status rules."),
        "error"
      );
    }
  }

  handlePreviewClick() {
    if (!this.selectedOnboardingId) {
      this.showToast(
        "Selection Required",
        "Please select an onboarding record to preview evaluation.",
        "warning"
      );
      return;
    }
    this.showPreviewModal = true;
  }

  handleOnboardingSelection(event) {
    this.selectedOnboardingId = event.detail.value;
  }

  handlePreviewModalClose() {
    this.showPreviewModal = false;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}
