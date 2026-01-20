import { LightningElement, api, track } from "lwc";

export default class VendorOnboardingPicker extends LightningElement {
  @track vendorData;

  @track vendorOptions = [];
  @track retailOptions = [];
  @track verticalOptions = [];

  @track selectedVendorId;
  @track selectedVendorName;
  @track selectedRetailOption;
  @track selectedVertical;

  @track selectedVendorRecord;

  @track showRetailOptions = false;
  @track showVerticalOptions = false;

  @api vendorDataJson;

  connectedCallback() {
    try {
      this.vendorData = JSON.parse(this.vendorDataJson);
      this.vendorOptions = this.vendorData.map((v) => ({
        label: v.vendorName,
        value: v.vendorId
      }));
    } catch (e) {
      console.error("Error parsing vendor data JSON:", e);
    }
  }

  handleVendorChange(event) {
    this.selectedVendorId = event.detail.value;
    this.selectedVendorRecord = this.vendorData.find(
      (v) => v.vendorId === this.selectedVendorId
    );
    this.selectedVendorName = this.selectedVendorRecord?.vendorName;

    this.retailOptions = (
      this.selectedVendorRecord?.availableRetailOptions || []
    ).map((ro) => ({
      label: ro,
      value: ro
    }));

    this.selectedRetailOption = null;
    this.selectedVertical = null;
    this.verticalOptions = [];

    this.showRetailOptions = this.retailOptions.length > 0;
    this.showVerticalOptions = false;

    this.dispatchToFlow();
  }

  handleRetailChange(event) {
    this.selectedRetailOption = event.detail.value;
    this.selectedVertical = null;

    const selectedGroup = this.selectedVendorRecord?.retailOptionGroups.find(
      (g) => g.retailOption === this.selectedRetailOption
    );

    this.verticalOptions = (selectedGroup?.businessVerticals || []).map(
      (v) => ({
        label: v,
        value: v
      })
    );

    this.showVerticalOptions = this.verticalOptions.length > 0;
    this.dispatchToFlow();
  }

  handleVerticalChange(event) {
    this.selectedVertical = event.detail.value;
    this.dispatchToFlow();
  }

  dispatchToFlow() {
    this.dispatchEvent(
      new CustomEvent("flowvalueselected", {
        detail: {
          vendorId: this.selectedVendorId,
          vendorName: this.selectedVendorName,
          retailOption: this.selectedRetailOption,
          vertical: this.selectedVertical
        }
      })
    );
  }
}
