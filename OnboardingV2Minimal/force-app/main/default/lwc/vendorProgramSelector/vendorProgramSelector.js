import { api, LightningElement, wire } from 'lwc';
import getVendorCustomizations from '@salesforce/apex/VendorProgramService.getVendorProgramsForSelection';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import VENDOR_PROGRAM_FIELD from '@salesforce/schema/Program_Dates__c.Vendor_Program__c';

const PROGRAM_DATES_FIELDS = [VENDOR_PROGRAM_FIELD];

export default class VendorProgramSelector extends LightningElement {
    @api recordId;

    options = [];
    selectedVendorProgramId;
    currentVendorProgramId;
    isSaving = false;
    selectionInitialized = false;
    vendorCustomizationsWireResult;
    programDatesWireResult;

    @wire(getVendorCustomizations)
    wiredVendorCustomizations(result) {
        this.vendorCustomizationsWireResult = result;
        if (result.data) {
            this.options = result.data.map((item) => ({
                label: item.Label__c || 'Unlabeled',
                value: item.Id
            }));

            if (!this.selectionInitialized && this.currentVendorProgramId) {
                this.selectedVendorProgramId = this.currentVendorProgramId;
                this.selectionInitialized = true;
            }
        } else if (result.error) {
            this.options = [];
            this.showToast(
                'Error loading vendor customizations',
                this.reduceErrors(result.error).join(', '),
                'error'
            );
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: PROGRAM_DATES_FIELDS })
    wiredProgramDates(result) {
        this.programDatesWireResult = result;
        if (result.data) {
            this.currentVendorProgramId = getFieldValue(result.data, VENDOR_PROGRAM_FIELD);

            if (!this.selectionInitialized) {
                this.selectedVendorProgramId = this.currentVendorProgramId;
                this.selectionInitialized = true;
            }
        } else if (result.error) {
            this.showToast('Error loading record', this.reduceErrors(result.error).join(', '), 'error');
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
        fields[VENDOR_PROGRAM_FIELD.fieldApiName] = this.selectedVendorProgramId;

        updateRecord({ fields })
            .then(() => {
                this.currentVendorProgramId = this.selectedVendorProgramId;
                this.showToast('Success', 'Vendor customization updated.', 'success');
                return Promise.all([refreshApex(this.programDatesWireResult)]);
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
