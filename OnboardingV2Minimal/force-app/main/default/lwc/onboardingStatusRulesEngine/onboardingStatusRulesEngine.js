import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { extractErrorMessage } from "c/utils";
import getVendorProgramGroups from "@salesforce/apex/OnboardingStatusRulesEngineController.getVendorProgramGroups";
import getRequirementGroups from "@salesforce/apex/OnboardingStatusRulesEngineController.getRequirementGroups";
import getRules from "@salesforce/apex/OnboardingStatusRulesEngineController.getRules";
import saveRules from "@salesforce/apex/OnboardingStatusRulesEngineController.saveRules";
import getOnboardingOptions from "@salesforce/apex/OnboardingStatusRulesEngineController.getOnboardingOptions";

export default class OnboardingStatusRulesEngine extends LightningElement {
  @track vendorProgramGroupOptions = [];
  @track requirementGroupOptions = [];
  @track onboardingOptions = [];
  @track rules = [];
  @track draftValues = [];
  @track showPreviewModal = false;
  @track selectedOnboardingId = null;

  selectedVendorProgramGroup;
  selectedRequirementGroup;

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
      getRequirementGroups(),
      getOnboardingOptions({ limitCount: 50 })
    ])
      .then(([vendorGroups, requirementGroups, onboardingOpts]) => {
        this.vendorProgramGroupOptions = vendorGroups;
        this.requirementGroupOptions = requirementGroups;
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

  handleRequirementGroupChange(event) {
    this.selectedRequirementGroup = event.detail.value;
  }

  async loadRules() {
    if (!this.selectedVendorProgramGroup || !this.selectedRequirementGroup) {
      this.showToast(
        "Selection Required",
        "Please select both a Vendor Program Group and a Requirement Group before loading rules.",
        "warning"
      );
      return;
    }

    try {
      const result = await getRules({
        vendorProgramGroupId: this.selectedVendorProgramGroup,
        requirementGroupId: this.selectedRequirementGroup
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
