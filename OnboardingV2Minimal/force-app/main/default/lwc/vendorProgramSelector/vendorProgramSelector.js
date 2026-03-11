import { api, LightningElement, wire } from 'lwc';
import getLookupOptions from '@salesforce/apex/ObjectRelatedListController.getLookupOptions';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const VENDOR_PROGRAM_FIELD_API_NAME = 'Vendor_Program__c';
const PROGRAM_DATES_FIELDS = ['Program_Dates__c.Vendor_Program__c'];

export default class VendorProgramSelector extends LightningElement {
    @api recordId;

    options = [];
    selectedVendorProgramId;
    currentVendorProgramId;
    isSaving = false;

    @wire(getLookupOptions, {
        objectApiName: 'Vendor_Customization__c',
        labelFieldApiName: 'Label__c',
        orderByField: 'Label__c',
        orderDirection: 'ASC',
        recordLimit: 500
    })
    wiredVendorCustomizations({ data, error }) {
        if (data) {
            this.options = data.map((item) => ({
                label: item.label || item.Label__c || 'Unlabeled',
                value: item.value || item.Id
            }));
        } else if (error) {
            this.options = [];
            this.showToast(
                'Error loading vendor customizations',
                this.reduceErrors(error).join(', '),
                'error'
            );
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: PROGRAM_DATES_FIELDS })
    wiredProgramDates({ data, error }) {
        if (data) {
            this.currentVendorProgramId = data.fields?.Vendor_Program__c?.value || null;
            if (!this.selectedVendorProgramId) {
                this.selectedVendorProgramId = this.currentVendorProgramId;
            }
        } else if (error) {
            this.showToast('Error loading record', this.reduceErrors(error).join(', '), 'error');
        }
    }

    get hasOptions() {
        return this.options && this.options.length > 0;
    }

    get selectedLabel() {
        if (!this.selectedVendorProgramId) {
            return 'None';
        }
        const selected = this.options.find((option) => option.value === this.selectedVendorProgramId);
        return selected ? selected.label : 'None';
    }

    get isSaveDisabled() {
        return (
            this.isSaving ||
            !this.selectedVendorProgramId ||
            this.selectedVendorProgramId === this.currentVendorProgramId ||
            !this.recordId
        );
    }

    handleSelectionChange(event) {
        this.selectedVendorProgramId = event.detail.value;
    }

    handleSave() {
        if (!this.selectedVendorProgramId) {
            this.showToast('Select a vendor customization', 'Choose an option before saving.', 'warning');
            return;
        }

        this.isSaving = true;

        const fields = {
            Id: this.recordId
        };
        fields[VENDOR_PROGRAM_FIELD_API_NAME] = this.selectedVendorProgramId;

        updateRecord({ fields })
            .then(() => {
                this.currentVendorProgramId = this.selectedVendorProgramId;
                this.showToast('Success', 'Vendor customization updated.', 'success');
            })
            .catch((error) => {
                this.showToast('Error updating record', this.reduceErrors(error).join(', '), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    reduceErrors(errors) {
        if (!errors) {
            return ['Unknown error'];
        }
        if (Array.isArray(errors)) {
            return errors.flatMap((error) => this.reduceErrors(error));
        }
        if (errors.body && Array.isArray(errors.body.pageErrors) && errors.body.pageErrors.length) {
            return errors.body.pageErrors.map((error) => error.message);
        }
        if (errors.body && errors.body.message) {
            return [errors.body.message];
        }
        if (typeof errors.message === 'string') {
            return [errors.message];
        }
        return ['Unknown error'];
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
