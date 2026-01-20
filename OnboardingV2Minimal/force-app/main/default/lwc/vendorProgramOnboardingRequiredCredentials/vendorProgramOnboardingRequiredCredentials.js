import { api, track, wire } from "lwc";
import OnboardingStepBase from "c/onboardingStepBase";
import { refreshApex } from "@salesforce/apex";
import getRequiredCredentials from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.getRequiredCredentials";
import createRequiredCredential from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.createRequiredCredential";
import getCredentialTypes from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.getCredentialTypes";
import createCredentialType from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.createCredentialType";
import updateRequiredCredentials from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.updateRequiredCredentials";

export default class VendorProgramOnboardingRequiredCredentials extends OnboardingStepBase {
  stepName = "Required Credentials";

  @api vendorProgramId;
  @api stageId;

  @track credentials = [];
  @track newCredential = {};
  @track isLoading = false;
  @track showForm = false;
  @track error;
  @track credentialsNeeded = null; // null = not answered, true = yes, false = no
  @track credentialTypeOptions = [];
  @track credentialTypeMap = {};
  @track showCredentialTypeForm = false;
  @track newCredentialType = { Active__c: true };
  wiredCredentialTypesResult;
  wiredRequiredCredsResult;
  @track draftValues = [];

  columns = [
    { label: "Credential Type", fieldName: "CredentialTypeName" },
    { label: "Notes", fieldName: "Notes__c", editable: true },
    {
      label: "Is Required",
      fieldName: "Is_Required__c",
      type: "boolean",
      editable: true
    },
    {
      label: "Sequence",
      fieldName: "Sequence__c",
      type: "number",
      editable: true
    }
  ];

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    // Dispatch initial validation state
    Promise.resolve().then(() => {
      this.dispatchValidationState();
    });
  }

  handleFooterNextClick() {
    // Override: Handle Next button click
    if (this.canProceed) {
      this.proceedToNext();
    } else {
      // Provide feedback when Next is clicked but validation fails
      if (this.credentialsNeeded === null) {
        this.showToast(
          "Required Field Missing",
          "Please select whether Required Credentials are needed.",
          "warning"
        );
      } else if (
        this.credentialsNeeded === true &&
        (!this.credentials || this.credentials.length === 0)
      ) {
        this.showToast(
          "Required Action",
          "Please add at least one Required Credential before proceeding.",
          "warning"
        );
      }
      // Ensure validation state is dispatched
      this.dispatchValidationState();
    }
  }

  get canProceed() {
    // Can proceed if:
    // - "No" is selected (can skip)
    // - "Yes" is selected AND at least one credential has been added
    if (this.credentialsNeeded === false) {
      return true; // "No" selected - can proceed
    }
    if (this.credentialsNeeded === true) {
      // "Yes" selected - must have at least one credential
      return this.credentials && this.credentials.length > 0;
    }
    // Nothing selected - cannot proceed
    return false;
  }

  @wire(getRequiredCredentials, { vendorProgramId: "$vendorProgramId" })
  wiredRequiredCreds(result) {
    this.wiredRequiredCredsResult = result;
    if (result.data) {
      this.credentials = (result.data || []).map((c) => ({
        ...c,
        CredentialTypeName: c.External_Contact_Credential_Type__r?.Name || ""
      }));
      this.dispatchValidationState();
    } else if (result.error) {
      this.credentials = [];
      this.handleError(result.error, "Failed to load required credentials");
    }
  }

  handleFieldChange(event) {
    const field = event.target;
    const { name } = field;
    const value = field.type === "checkbox" ? field.checked : field.value;
    this.newCredential = { ...this.newCredential, [name]: value };
  }

  async handleCreate() {
    const record = {
      ...this.newCredential,
      Vendor_Customization__c: this.vendorProgramId
    };

    try {
      await createRequiredCredential({ newRequirement: record });
      this.newCredential = {};
      this.showForm = false;
      if (this.wiredRequiredCredsResult) {
        await refreshApex(this.wiredRequiredCredsResult);
      }
      this.dispatchValidationState();
    } catch (err) {
      this.handleError(err, "Failed to create required credential");
    }
  }

  @wire(getCredentialTypes)
  wiredCredentialTypes(result) {
    this.wiredCredentialTypesResult = result;
    if (result.data) {
      this.credentialTypeOptions = result.data.map((ct) => ({
        label: ct.Name,
        value: ct.Id
      }));
      this.credentialTypeMap = {};
      result.data.forEach((ct) => {
        this.credentialTypeMap[ct.Id] = ct;
      });
    } else if (result.error) {
      this.credentialTypeOptions = [];
      this.credentialTypeMap = {};
      this.handleError(result.error, "Failed to load credential types");
    }
  }

  async handleCreateCredentialType() {
    const record = {
      ...this.newCredentialType,
      Vendor_Customization__c: this.vendorProgramId
    };
    try {
      const created = await createCredentialType({ newType: record });
      this.showCredentialTypeForm = false;
      this.newCredentialType = { Active__c: true };
      if (this.wiredCredentialTypesResult) {
        await refreshApex(this.wiredCredentialTypesResult);
      }
      // Preselect the newly created type on the credential form
      this.newCredential = {
        ...this.newCredential,
        External_Contact_Credential_Type__c: created.Id
      };
    } catch (err) {
      this.handleError(err, "Failed to create credential type");
    }
  }

  handleCredentialsNeededChange(event) {
    const value = event.detail.value;
    this.credentialsNeeded =
      value === "yes" ? true : value === "no" ? false : null;

    // If "Yes" is selected, load existing credentials
    if (this.credentialsNeeded === true) {
      if (this.wiredRequiredCredsResult) {
        refreshApex(this.wiredRequiredCredsResult);
      }
    } else {
      // If "No" is selected, clear credentials list
      this.credentials = [];
    }

    // Update validation state after change
    this.dispatchValidationState();
  }

  proceedToNext() {
    // Called from footer Next button
    this.dispatchNextEvent({
      credentialsNeeded: this.credentialsNeeded,
      vendorProgramId: this.vendorProgramId
    });
  }

  toggleForm() {
    this.showForm = !this.showForm;
  }

  toggleCredentialTypeForm() {
    this.showCredentialTypeForm = !this.showCredentialTypeForm;
  }

  get credentialsNeededOptions() {
    return [
      { label: "Yes, Required Credentials are needed", value: "yes" },
      { label: "No, skip this step", value: "no" }
    ];
  }

  get credentialsNeededValue() {
    if (this.credentialsNeeded === true) return "yes";
    if (this.credentialsNeeded === false) return "no";
    return null;
  }

  get showCredentialsManagement() {
    // Show credentials management section when "Yes" is selected
    return this.credentialsNeeded === true;
  }

  get hasCredentials() {
    return this.credentials && this.credentials.length > 0;
  }

  handleCredentialTypeFieldChange(event) {
    const field = event.target;
    const { name } = field;
    const value = field.type === "checkbox" ? field.checked : field.value;
    this.newCredentialType = { ...this.newCredentialType, [name]: value };
  }

  async handleSave(event) {
    const updates = event.detail.draftValues.map((dv) => ({
      Id: dv.Id,
      Notes__c: dv.Notes__c,
      Is_Required__c: dv.Is_Required__c,
      Sequence__c: dv.Sequence__c
    }));

    try {
      await updateRequiredCredentials({ records: updates });
      this.draftValues = [];
      if (this.wiredRequiredCredsResult) {
        await refreshApex(this.wiredRequiredCredsResult);
      }
    } catch (err) {
      this.handleError(err, "Failed to update required credentials");
    }
  }
}
