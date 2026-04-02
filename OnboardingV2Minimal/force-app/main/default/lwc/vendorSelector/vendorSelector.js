import { LightningElement, api, track } from 'lwc';

export default class VendorSelector extends LightningElement {
    @api recordId;

    _vendorOptionsJson;

    @api
    get vendorOptionsJson() {
        return this._vendorOptionsJson;
    }

    set vendorOptionsJson(value) {
        this._vendorOptionsJson = value;
        this.parseVendorOptions();
    }

    @track vendorOptions = [];
    @track vendors = [];
    @track retailOptions = [];
    @track businessVerticals = [];

    @track selectedVendorId = null;
    @track selectedRetailOption = null;
    @track selectedBusinessVertical = null;

    connectedCallback() {
        this.parseVendorOptions();
    }

    parseVendorOptions() {
        try {
            this.vendorOptions = JSON.parse(this.vendorOptionsJson || '[]');

            const vendorMap = new Map();
            this.vendorOptions.forEach(opt => {
                if (!vendorMap.has(opt.vendorId)) {
                    vendorMap.set(opt.vendorId, opt.vendorName);
                }
            });

            this.vendors = [...vendorMap.entries()].map(([id, name]) => ({
                label: name,
                value: id
            }));
            this.selectedVendorId = null;
            this.selectedRetailOption = null;
            this.selectedBusinessVertical = null;
            this.retailOptions = [];
            this.businessVerticals = [];
            this.notifySelectionChange();
        } catch (err) {
            this.vendorOptions = [];
            this.vendors = [];
            this.notifySelectionChange();
        }
    }

    handleVendorChange(event) {
        this.selectedVendorId = event.detail.value;
        this.selectedRetailOption = null;
        this.selectedBusinessVertical = null;

        const filtered = this.vendorOptions.filter(
            opt => opt.vendorId === this.selectedVendorId
        );

        const uniqueRetail = [...new Set(filtered.map(opt => opt.retailOption))];
        this.retailOptions = uniqueRetail.map(ro => ({
            label: ro,
            value: ro
        }));

        this.businessVerticals = [];
        this.notifySelectionChange();
    }

    handleRetailChange(event) {
        this.selectedRetailOption = event.detail.value;
        this.selectedBusinessVertical = null;

        const filtered = this.vendorOptions.filter(
            opt =>
                opt.vendorId === this.selectedVendorId &&
                opt.retailOption === this.selectedRetailOption
        );

        const verticalSet = new Set();
        filtered.forEach(opt => {
            if (opt.businessVerticals) {
                opt.businessVerticals.forEach(v => verticalSet.add(v));
            }
        });

        this.businessVerticals = [...verticalSet].map(v => ({
            label: v,
            value: v
        }));
        this.notifySelectionChange();
    }

    handleVerticalChange(event) {
        this.selectedBusinessVertical = event.detail.value;
        this.notifySelectionChange();
    }

    @api get outputVendorId() {
        return this.selectedVendorId;
    }

    @api get outputVendorName() {
        const match = this.vendors.find(v => v.value === this.selectedVendorId);
        return match ? match.label : null;
    }

    @api get outputRetailOption() {
        return this.selectedRetailOption;
    }

    @api get outputBusinessVertical() {
        return this.selectedBusinessVertical;
    }

    hasValue(value) {
        return value !== null && value !== undefined && String(value).trim() !== '';
    }

    notifySelectionChange() {
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                selectedVendorId: this.selectedVendorId,
                selectedRetailOption: this.selectedRetailOption,
                selectedBusinessVertical: this.selectedBusinessVertical,
                hasRequiredValues:
                    this.hasValue(this.selectedVendorId) &&
                    this.hasValue(this.selectedRetailOption) &&
                    this.hasValue(this.selectedBusinessVertical)
            },
            bubbles: true,
            composed: true
        }));
    }
}
