import { LightningElement, api, track } from "lwc";
import getRequiredCredentials from "@salesforce/apex/OnboardingAppECCService.getRequiredCredentials";
import getAvailableCredentialTypes from "@salesforce/apex/OnboardingAppECCService.getAvailableCredentialTypes";
import createCredentialType from "@salesforce/apex/OnboardingAppECCService.createCredentialType";
import linkCredentialTypeToRequiredCredential from "@salesforce/apex/OnboardingAppECCService.linkCredentialTypeToRequiredCredential";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class OnboardingAppVendorProgramECCManager extends LightningElement {
  @api recordId; // Vendor_Customization__c Id

  @track requiredCredentials = [];
  @track credentialTypeOptions = [];
  @track selectedRequiredCredentialId = null;
  @track selectedCredentialTypeId = null;

  @track showModal = false;
  @track newCredentialTypeName = "";

  columns = [
    {
      label: "Required Credential",
      fieldName: "Name"
    },
    {
      label: "Linked Credential Type",
      fieldName: "External_Contact_Credential_Type__r.Name",
      type: "text"
    },
    {
      type: "button",
      label: "Manage",
      typeAttributes: {
        label: "Manage",
        name: "manage",
        variant: "base"
      }
    }
  ];

  connectedCallback() {
    this.loadData();
  }

  async loadData() {
    try {
      const [credentials, types] = await Promise.all([
        getRequiredCredentials({ vendorProgramId: this.recordId }),
        getAvailableCredentialTypes()
      ]);

      this.requiredCredentials = credentials;
      this.credentialTypeOptions = types.map((t) => ({
        label: t.Name,
        value: t.Id
      }));
    } catch (error) {
      this.showError("Error loading data", error);
    }
  }

  handleRowAction(event) {
    if (event.detail.action.name === "manage") {
      this.selectedRequiredCredentialId = event.detail.row.Id;
      this.selectedCredentialTypeId =
        event.detail.row.External_Contact_Credential_Type__c || null;
    }
  }

  handleCredentialTypeChange(event) {
    this.selectedCredentialTypeId = event.detail.value;
  }

  async handleLinkCredential() {
    try {
      await linkCredentialTypeToRequiredCredential({
        requiredCredentialId: this.selectedRequiredCredentialId,
        credentialTypeId: this.selectedCredentialTypeId
      });
      this.showToast("Credential Type Linked");
      this.loadData();
    } catch (error) {
      this.showError("Linking failed", error);
    }
  }

  handleShowModal() {
    this.newCredentialTypeName = "";
    this.showModal = true;
  }

  handleCloseModal() {
    this.showModal = false;
  }

  handleNameInput(event) {
    this.newCredentialTypeName = event.target.value;
  }

  async handleCreateCredentialType() {
    try {
      // Use a default sort order (can be improved to calculate max sort order)
      const result = await createCredentialType({
        name: this.newCredentialTypeName,
        sortOrder: 1,
        vendorCustomizationId: this.recordId
      });
      this.selectedCredentialTypeId = result.Id;
      this.showToast("New Credential Type Created");
      this.handleCloseModal();
      this.loadData();
    } catch (error) {
      this.showError("Creation failed", error);
    }
  }

  showToast(message) {
    this.dispatchEvent(
      new ShowToastEvent({ title: "Success", message, variant: "success" })
    );
  }

  showError(title, error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message: error.body?.message || error.message || "An error occurred",
        variant: "error"
      })
    );
  }
}
