import { api, track, wire } from "lwc";
import OnboardingStepBase from "c/onboardingStepBase";
import { refreshApex } from "@salesforce/apex";
import getTrainingRequirements from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.getTrainingRequirements";
import createTrainingRequirement from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.createTrainingRequirement";
import getTrainingSystems from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.getTrainingSystems";
import createTrainingSystem from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.createTrainingSystem";
import updateTrainingRequirementRequiredStatus from "@salesforce/apex/OnboardingAppVendorProgramReqSvc.updateTrainingRequirementRequiredStatus";

export default class VendorProgramOnboardingTrainingRequirements extends OnboardingStepBase {
  stepName = "Training Requirements";

  @api vendorProgramId;
  @api stageId;

  @track trainingRequirements = [];
  @track newTraining = {};
  @track isLoading = false;
  @track showForm = false;
  @track error;
  @track trainingSystemOptions = [];
  @track trainingSystemsMap = {}; // Map of ID to Training System for quick lookup
  @track showTrainingSystemForm = false;
  @track newTrainingSystem = { Active__c: true }; // Default to active
  @track selectedTrainingSystemType = null; // Track the selected Training System's type
  @track selectedTrainingRequirementIds = []; // Track selected Training Requirements for grouping
  @track trainingNeeded = null; // null = not answered, true = yes, false = no
  wiredTrainingSystemsResult;
  wiredTrainingRequirementsResult;
  preserveSelection = false;
  preservedSelectedIds = [];

  columnsExternal = [
    {
      type: "action",
      typeAttributes: {
        rowActions: [
          { label: "Edit", name: "edit" },
          { label: "Delete", name: "delete" }
        ]
      }
    },
    { label: "Name", fieldName: "Name" },
    {
      label: "Training System",
      fieldName: "Training_System_Name",
      type: "text"
    },
    { label: "Course Code", fieldName: "External_Course_Code__c" },
    { label: "Course Name", fieldName: "External_Course_Name__c" },
    { label: "Is Required", fieldName: "Is_Required__c", type: "boolean" },
    { label: "Sequence", fieldName: "Sequence__c", type: "number" }
  ];

  columnsInternal = [
    {
      type: "action",
      typeAttributes: {
        rowActions: [
          { label: "Edit", name: "edit" },
          { label: "Delete", name: "delete" }
        ]
      }
    },
    { label: "Name", fieldName: "Name" },
    {
      label: "Training System",
      fieldName: "Training_System_Name",
      type: "text"
    },
    { label: "Training Code", fieldName: "Training_Code__c" },
    { label: "Is Required", fieldName: "Is_Required__c", type: "boolean" }
  ];

  // Getter to check if there are any training requirements
  get hasTrainingRequirements() {
    return this.trainingRequirements && this.trainingRequirements.length > 0;
  }

  // Getter for required training requirements only (for bottom table)
  get requiredTrainingRequirements() {
    if (!this.trainingRequirements || this.trainingRequirements.length === 0) {
      return [];
    }
    return this.trainingRequirements.filter(
      (req) => req.Is_Required__c === true
    );
  }

  get externalRequirements() {
    return (this.trainingRequirements || []).filter((req) => req.isExternal);
  }

  get internalRequirements() {
    return (this.trainingRequirements || []).filter((req) => !req.isExternal);
  }

  get requiredExternalRequirements() {
    return this.externalRequirements.filter(
      (req) => req.Is_Required__c === true
    );
  }

  get requiredInternalRequirements() {
    return this.internalRequirements.filter(
      (req) => req.Is_Required__c === true
    );
  }

  get hasExternalRequirements() {
    return this.externalRequirements.length > 0;
  }

  get hasInternalRequirements() {
    return this.internalRequirements.length > 0;
  }

  get hasRequiredExternalRequirements() {
    return this.requiredExternalRequirements.length > 0;
  }

  get hasRequiredInternalRequirements() {
    return this.requiredInternalRequirements.length > 0;
  }

  // Getter to check if we have any required training requirements (for template condition)
  get hasRequiredTrainingRequirements() {
    return (
      this.requiredTrainingRequirements &&
      this.requiredTrainingRequirements.length > 0
    );
  }

  // Options for selectable Training Requirements
  // Note: lightning-dual-listbox automatically splits options based on value prop
  // Items in selectedTrainingRequirementIds appear in "Selected for Group"
  // Items not in selectedTrainingRequirementIds appear in "Available"
  get trainingRequirementOptions() {
    if (!this.trainingRequirements || this.trainingRequirements.length === 0) {
      return [];
    }
    return this.trainingRequirements.map((req) => ({
      label: `${req.Name || "N/A"} - ${req.External_Course_Name__c || req.External_Course_Code__c || "Training Requirement"}`,
      value: req.Id
    }));
  }

  @wire(getTrainingSystems)
  wiredTrainingSystems(result) {
    this.wiredTrainingSystemsResult = result;
    if (result.data) {
      this.trainingSystemOptions = result.data.map((system) => ({
        label: system.Name,
        value: system.Id
      }));
      // Build a map for quick lookup of System_Type__c
      this.trainingSystemsMap = {};
      result.data.forEach((system) => {
        this.trainingSystemsMap[system.Id] = system;
      });
    } else if (result.error) {
      this.trainingSystemOptions = [];
      this.trainingSystemsMap = {};
      this.handleError(result.error, "Failed to load training systems.");
    }
  }

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    // Dispatch initial validation state
    Promise.resolve().then(() => {
      this.dispatchValidationState();
    });
  }

  async refreshTrainingSystemsList() {
    // Use refreshApex to invalidate cache and reload the wired data
    if (this.wiredTrainingSystemsResult) {
      try {
        await refreshApex(this.wiredTrainingSystemsResult);
      } catch (err) {
        this.handleError(err, "Failed to refresh training systems.");
      }
    }
  }

  @wire(getTrainingRequirements, { vendorProgramId: "$vendorProgramId" })
  wiredTrainingRequirements(result) {
    this.wiredTrainingRequirementsResult = result;
    if (result.data) {
      const incoming = (result.data || []).map((req) => ({
        ...req,
        Training_System_Name: req.Training_System__r?.Name || "",
        Training_System_Type: req.Training_System__r?.System_Type__c,
        isExternal: req.Training_System__r?.System_Type__c === "External"
      }));

      if (this.preserveSelection && this.preservedSelectedIds) {
        const preserved = this.preservedSelectedIds;
        this.trainingRequirements = incoming.map((req) => ({
          ...req,
          Is_Required__c: preserved.includes(req.Id)
        }));
        this.selectedTrainingRequirementIds = [...preserved];
      } else {
        this.trainingRequirements = incoming;
        this.selectedTrainingRequirementIds = incoming
          .filter((req) => req.Is_Required__c === true)
          .map((req) => req.Id);
      }

      this.preserveSelection = false;
      this.preservedSelectedIds = [];
      this.dispatchValidationState();
    } else if (result.error) {
      this.trainingRequirements = [];
      this.selectedTrainingRequirementIds = [];
      this.handleError(result.error, "Failed to load training requirements.");
    }
  }

  async refreshTrainingRequirements(
    preserveSelection = false,
    preservedSelectedIds = []
  ) {
    this.preserveSelection = preserveSelection;
    this.preservedSelectedIds = preservedSelectedIds;
    if (this.wiredTrainingRequirementsResult) {
      this.isLoading = true;
      try {
        await refreshApex(this.wiredTrainingRequirementsResult);
      } finally {
        this.isLoading = false;
      }
    }
  }

  handleFieldChange(event) {
    const field = event.target;
    const name = field.name;
    const value = field.type === "checkbox" ? field.checked : field.value;
    this.newTraining = { ...this.newTraining, [name]: value };

    // If Training System changed, update the selected type
    if (name === "Training_System__c") {
      const selectedSystem = this.trainingSystemsMap[value];
      this.selectedTrainingSystemType = selectedSystem
        ? selectedSystem.System_Type__c
        : null;

      // If switching to External, clear Training Code
      if (this.selectedTrainingSystemType === "External") {
        this.newTraining = { ...this.newTraining, Training_Code__c: null };
      }
    }
  }

  handleTrainingSystemFieldChange(event) {
    const field = event.target;
    const name = field.name;
    const value = field.type === "checkbox" ? field.checked : field.value;
    this.newTrainingSystem = { ...this.newTrainingSystem, [name]: value };
  }

  async handleCreate() {
    // Validate required fields
    if (!this.vendorProgramId) {
      this.showError(
        "Vendor Program ID is missing. Please refresh the page and try again."
      );
      return;
    }

    if (!this.newTraining.Training_System__c) {
      this.showError(
        "Please select a Training System. This field is required."
      );
      return;
    }

    const record = {
      Training_System__c: this.newTraining.Training_System__c,
      External_Course_Code__c: this.newTraining.External_Course_Code__c,
      External_Course_Name__c: this.newTraining.External_Course_Name__c,
      Is_Required__c: this.newTraining.Is_Required__c || false,
      Sequence__c: this.newTraining.Sequence__c
        ? parseInt(this.newTraining.Sequence__c, 10)
        : null,
      // Master-Detail relationship - must be set
      Vendor_Customization__c: this.vendorProgramId
    };

    // Only include Training_Code__c if System_Type__c is NOT "External"
    if (
      this.selectedTrainingSystemType !== "External" &&
      this.newTraining.Training_Code__c
    ) {
      record.Training_Code__c = this.newTraining.Training_Code__c;
    }

    try {
      await createTrainingRequirement({ newRequirement: record });
      this.newTraining = {};
      this.showForm = false;

      await this.refreshTrainingRequirements();

      // Update validation state after training requirement is created
      this.dispatchValidationState();

      this.showSuccess(
        "Training requirement created successfully and added to the list below."
      );
    } catch (err) {
      this.handleError(err, "Failed to create training requirement.");
    }
  }

  /**
   * Centralized error handling utility.
   * Parses Salesforce error objects and extracts user-friendly error messages.
   * @param {Object} error - The error object from Apex or JavaScript
   * @param {String} defaultMessage - Default error message if parsing fails
   */
  handleError(error, defaultMessage) {
    let errorMessage = defaultMessage;

    // Parse Salesforce error structure
    if (error?.body) {
      if (Array.isArray(error.body) && error.body.length > 0) {
        errorMessage = error.body[0].message || errorMessage;
      } else if (error.body.message) {
        errorMessage = error.body.message;
      } else if (typeof error.body === "string") {
        errorMessage = error.body;
      }
    } else if (error?.message) {
      errorMessage = error.message;
    }

    this.showError(errorMessage);
  }

  showError(message) {
    this.showToast("Error", message, "error");
  }

  showSuccess(message) {
    this.showToast("Success", message, "success");
  }

  handleFooterNextClick() {
    // Override: Handle Next button click
    if (this.canProceed) {
      this.proceedToNext();
    } else {
      // Provide feedback when Next is clicked but validation fails
      if (this.trainingNeeded === null) {
        this.showToast(
          "Required Field Missing",
          "Please select whether Training Requirements are needed.",
          "warning"
        );
      } else if (
        this.trainingNeeded === true &&
        (!this.trainingRequirements || this.trainingRequirements.length === 0)
      ) {
        this.showToast(
          "Required Action",
          "Please add at least one Training Requirement before proceeding.",
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
    // - "Yes" is selected AND at least one training requirement has been added
    if (this.trainingNeeded === false) {
      return true; // "No" selected - can proceed
    }
    if (this.trainingNeeded === true) {
      // "Yes" selected - must have at least one training requirement
      return this.trainingRequirements && this.trainingRequirements.length > 0;
    }
    // Nothing selected - cannot proceed
    return false;
  }

  proceedToNext() {
    this.dispatchNextEvent({
      trainingNeeded: this.trainingNeeded,
      vendorProgramId: this.vendorProgramId
    });
  }

  toggleForm() {
    this.showForm = !this.showForm;
    if (!this.showForm) {
      this.newTraining = {};
      this.selectedTrainingSystemType = null;
    }
  }

  // Getter to check if selected Training System is External
  get isExternalTrainingSystem() {
    return this.selectedTrainingSystemType === "External";
  }

  async handleTrainingRequirementSelection(event) {
    // The dual-listbox automatically manages moving items between available and selected
    // event.detail.value contains the array of IDs that should be in "Selected for Group"
    // Items NOT in this array will appear in "Available"
    // This fires automatically when arrows are clicked in the dual-listbox

    const newSelectedIds = event.detail.value || [];
    const previousSelectedIds = this.selectedTrainingRequirementIds || [];

    // Update the selected IDs immediately for UI responsiveness
    this.selectedTrainingRequirementIds = newSelectedIds
      ? [...newSelectedIds]
      : [];

    // Find IDs that were added (moved to Selected for Group) - mark as Required
    const addedIds = newSelectedIds.filter(
      (id) => !previousSelectedIds.includes(id)
    );

    // Find IDs that were removed (moved to Available) - mark as Not Required
    const removedIds = previousSelectedIds.filter(
      (id) => !newSelectedIds.includes(id)
    );

    // If no changes, skip everything
    if (addedIds.length === 0 && removedIds.length === 0) {
      return;
    }

    // Update local state immediately so both dual-listbox and bottom table update together
    // This makes the UI update instantly before the API call completes
    this.updateLocalStateForSelection(addedIds, removedIds);

    try {
      // Execute both updates in parallel for better performance
      await this.persistSelectionChanges(addedIds, removedIds);

      // Reload with preservation - no delay needed, refreshApex handles caching
      await this.refreshTrainingRequirements(true, newSelectedIds);
    } catch (err) {
      this.handleSelectionError(err, previousSelectedIds, addedIds, removedIds);
    }
  }

  /**
   * Updates local state immediately when selection changes.
   * This provides instant UI feedback before the API call completes.
   * @param {Array} addedIds - IDs that were moved to "Selected for Group"
   * @param {Array} removedIds - IDs that were moved to "Available"
   */
  updateLocalStateForSelection(addedIds, removedIds) {
    if (!this.trainingRequirements || this.trainingRequirements.length === 0) {
      return;
    }

    // Map returns new array, which automatically triggers reactivity in LWC
    this.trainingRequirements = this.trainingRequirements.map((req) => {
      if (addedIds.includes(req.Id)) {
        // Item moved to Selected for Group - mark as Required immediately
        return { ...req, Is_Required__c: true };
      }
      if (removedIds.includes(req.Id)) {
        // Item moved to Available - mark as Not Required immediately
        return { ...req, Is_Required__c: false };
      }
      return req;
    });
  }

  /**
   * Persists selection changes to the database in parallel for better performance.
   * @param {Array} addedIds - IDs to mark as required
   * @param {Array} removedIds - IDs to mark as not required
   */
  async persistSelectionChanges(addedIds, removedIds) {
    const promises = [];

    // Execute updates in parallel for better performance
    if (addedIds.length > 0) {
      promises.push(
        updateTrainingRequirementRequiredStatus({
          trainingRequirementIds: addedIds,
          isRequired: true
        })
      );
    }

    if (removedIds.length > 0) {
      promises.push(
        updateTrainingRequirementRequiredStatus({
          trainingRequirementIds: removedIds,
          isRequired: false
        })
      );
    }

    // Execute in parallel - much faster than sequential
    if (promises.length > 0) {
      await Promise.all(promises);
    }
  }

  /**
   * Handles errors during selection changes and reverts UI state.
   * @param {Object} error - The error object
   * @param {Array} previousSelectedIds - Previous selection to revert to
   * @param {Array} addedIds - IDs that were added (need to revert)
   * @param {Array} removedIds - IDs that were removed (need to revert)
   */
  handleSelectionError(error, previousSelectedIds, addedIds, removedIds) {
    this.handleError(
      error,
      "Failed to update Training Requirement required status."
    );

    // Revert to previous selection on error
    this.selectedTrainingRequirementIds = previousSelectedIds;

    // Revert local state changes on error
    if (this.trainingRequirements && this.trainingRequirements.length > 0) {
      this.trainingRequirements = this.trainingRequirements.map((req) => {
        if (addedIds.includes(req.Id)) {
          // Revert: was added, now mark as not required
          return { ...req, Is_Required__c: false };
        }
        if (removedIds.includes(req.Id)) {
          // Revert: was removed, now mark as required
          return { ...req, Is_Required__c: true };
        }
        return req;
      });
    }
  }

  handleRowAction(event) {
    const action = event.detail.action;

    switch (action.name) {
      case "edit":
        // TODO: Implement edit functionality
        this.showSuccess("Edit functionality coming soon.");
        break;
      case "delete":
        // TODO: Implement delete functionality
        this.showSuccess("Delete functionality coming soon.");
        break;
      default:
        break;
    }
  }

  get minTrainingRequirements() {
    return 0;
  }

  get maxTrainingRequirements() {
    return this.trainingRequirements ? this.trainingRequirements.length : 0;
  }

  handleTrainingNeededChange(event) {
    const value = event.detail.value;
    this.trainingNeeded =
      value === "yes" ? true : value === "no" ? false : null;

    // If "Yes" is selected, load existing training requirements
    if (this.trainingNeeded === true) {
      this.refreshTrainingRequirements();
    } else {
      // If "No" is selected, clear training requirements list
      this.trainingRequirements = [];
      this.selectedTrainingRequirementIds = [];
    }

    // Update validation state after change
    this.dispatchValidationState();
  }

  get trainingNeededOptions() {
    return [
      { label: "Yes, Training Requirements are needed", value: "yes" },
      { label: "No, skip this step", value: "no" }
    ];
  }

  get trainingNeededValue() {
    if (this.trainingNeeded === true) return "yes";
    if (this.trainingNeeded === false) return "no";
    return null;
  }

  get showTrainingManagement() {
    // Show training management section when "Yes" is selected
    return this.trainingNeeded === true;
  }

  toggleTrainingSystemForm() {
    this.showTrainingSystemForm = !this.showTrainingSystemForm;
    if (!this.showTrainingSystemForm) {
      this.newTrainingSystem = { Active__c: true }; // Reset to default (active)
    }
  }

  async handleCreateTrainingSystem() {
    // Validate required fields
    if (!this.newTrainingSystem.Name || !this.newTrainingSystem.Name.trim()) {
      this.showError("Please enter a Name for the Training System.");
      return;
    }

    try {
      // Create clean object with all fields - respect user's Active__c choice
      const trainingSystemToCreate = {
        Name: this.newTrainingSystem.Name.trim()
      };

      // Include Active__c if set, otherwise let Apex default to true
      if (
        this.newTrainingSystem.Active__c !== undefined &&
        this.newTrainingSystem.Active__c !== null
      ) {
        trainingSystemToCreate.Active__c = this.newTrainingSystem.Active__c;
      }

      // Only add System_Type__c if provided
      if (this.newTrainingSystem.System_Type__c) {
        trainingSystemToCreate.System_Type__c =
          this.newTrainingSystem.System_Type__c;
      }

      const trainingSystemId = await createTrainingSystem({
        newTrainingSystem: trainingSystemToCreate
      });

      // Refresh the training systems list to invalidate cache and get the new one
      await this.refreshTrainingSystemsList();

      // Only auto-select if the Training System is active (will appear in dropdown)
      const isActive = trainingSystemToCreate.Active__c !== false;

      if (isActive) {
        // Auto-select the newly created training system
        // refreshApex handles the cache refresh, no delay needed
        this.newTraining = {
          ...this.newTraining,
          Training_System__c: trainingSystemId
        };

        this.showSuccess("Training System created successfully and selected.");
      } else {
        this.showSuccess(
          "Training System created successfully. Note: It is not marked as Active, so it will not appear in the dropdown. You can edit it later to activate it."
        );
      }

      // Close the form
      this.showTrainingSystemForm = false;
      this.newTrainingSystem = {};
    } catch (err) {
      this.handleError(err, "Failed to create training system.");
    }
  }
}
