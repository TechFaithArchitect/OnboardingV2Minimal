import { LightningElement, api, wire, track } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import activateProgram from "@salesforce/apex/OnboardingAppActivationService.activate";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class VersionedRecordHeader extends LightningElement {
  // ===== API =====
  @api recordId;
  @api objectApiName;
  @api statusFieldApiName = "Status__c";
  @api isActiveFieldApiName = "Active__c";
  @api lastModifiedFieldApiName = "LastModifiedDate";

  // ===== State =====
  @track statusLabel;
  @track lastModifiedDate;
  @track isActive = false;
  @track hasUnsavedChanges = false;
  @track isMenuOpen = false;

  _handleOutsideClick;

  // ===== Lifecycle =====
  constructor() {
    super();
    // bind once so add/removeEventListener uses same fn ref
    this._handleOutsideClick = this.handleOutsideClick.bind(this);
  }

  disconnectedCallback() {
    document.removeEventListener("click", this._handleOutsideClick, true);
  }

  // ===== Data (wire) =====
  @wire(getObjectInfo, { objectApiName: "$objectApiName" })
  objectInfo;

  get fields() {
    // dynamic fields for getRecord
    return [
      `${this.objectApiName}.${this.isActiveFieldApiName}`,
      `${this.objectApiName}.${this.statusFieldApiName}`,
      `${this.objectApiName}.${this.lastModifiedFieldApiName}`
    ];
  }

  @wire(getRecord, { recordId: "$recordId", fields: "$fields" })
  wiredRecord({ error, data }) {
    if (data) {
      this.isActive = data.fields[this.isActiveFieldApiName].value;
      this.statusLabel = data.fields[this.statusFieldApiName].value;
      this.lastModifiedDate = new Date(
        data.fields[this.lastModifiedFieldApiName].value
      ).toLocaleString();
    } else if (error) {
      this.showToast("Error", "Failed to load record data.", "error");
    }
  }

  // ===== Getters (UI) =====
  get normalizedStatus() {
    return (this.statusLabel || "").toLowerCase();
  }
  get statusBadgeClass() {
    return `status-badge ${this.normalizedStatus}`;
  }
  get showActivateButton() {
    return (
      this.normalizedStatus === "draft" || this.normalizedStatus === "inactive"
    );
  }
  get showDeactivateButton() {
    return this.normalizedStatus === "active";
  }
  get saveButtonTooltip() {
    return this.isActive ? "Cannot save an active record" : "";
  }
  get objectLabel() {
    return this.objectInfo?.data?.label || "Record";
  }
  get cloneMenuText() {
    return `Clone ${this.objectLabel}`;
  }
  get createNewMenuText() {
    return `Create New ${this.objectLabel}`;
  }

  // ===== Actions (main buttons) =====
  handleSave() {
    const form = this.template.querySelector("lightning-record-edit-form");
    form?.submit();
  }

  async handleActivate() {
    try {
      await activateProgram({
        recordId: this.recordId,
        objectApiName: this.objectApiName
      });
      this.isActive = true;
      this.showToast("Activated", `${this.objectLabel} activated.`, "success");
    } catch (error) {
      this.showToast(
        "Activation Failed",
        error?.body?.message || error?.message || "Unknown error",
        "error"
      );
    }
  }

  handleDeactivate() {
    const fields = {
      Id: this.recordId,
      [this.isActiveFieldApiName]: false
    };
    updateRecord({ fields })
      .then(() =>
        this.showToast("Success", `${this.objectLabel} deactivated.`, "success")
      )
      .catch((error) =>
        this.showToast(
          "Error",
          error?.body?.message || error?.message || "Unknown error",
          "error"
        )
      );
  }

  handleFormChange() {
    this.hasUnsavedChanges = true;
  }

  handleMenuButtonClick() {
    this.showToast("Info", 'Launching "Save as New Version"...', "info");
  }

  // ===== Menu (open/close+accessibility) =====
  toggleMenu(event) {
    const next = !this.isMenuOpen;
    // always clean listener first
    document.removeEventListener("click", this._handleOutsideClick, true);

    this.isMenuOpen = next;
    event.currentTarget?.blur();

    if (this.isMenuOpen) {
      // capture phase so we detect outside across shadow DOM
      Promise.resolve().then(() => {
        document.addEventListener("click", this._handleOutsideClick, true);
        this.template.querySelector(".custom-dropdown a")?.focus();
      });
    }
  }

  handleOutsideClick(evt) {
    if (!this.isMenuOpen) return;

    const path =
      typeof evt.composedPath === "function" ? evt.composedPath() : [];
    const isInside = path.includes(this.template.host);

    if (!isInside) this.closeMenu();
  }

  handleKeyDown(event) {
    const items = Array.from(
      this.template.querySelectorAll(".custom-dropdown a")
    );
    const index = items.findIndex((el) => el === document.activeElement);

    switch (event.key) {
      case "Escape":
      case "Tab":
        this.closeMenu();
        break;
      case "ArrowDown":
        event.preventDefault();
        items[Math.min(index + 1, items.length - 1)]?.focus();
        break;
      case "ArrowUp":
        event.preventDefault();
        items[Math.max(index - 1, 0)]?.focus();
        break;
      default:
    }
  }

  closeMenu() {
    this.isMenuOpen = false;
    document.removeEventListener("click", this._handleOutsideClick, true);
  }

  // ===== Menu actions =====
  handleCloneVendorProgram() {
    this.closeMenu();
    this.showToast("Clone", `Cloning ${this.objectLabel}...`, "info");
  }
  handleNewVendorProgram() {
    this.closeMenu();
    this.showToast("Create", `Creating new ${this.objectLabel}...`, "info");
  }

  // ===== Utility =====
  showToast(title, message, variant = "info") {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
