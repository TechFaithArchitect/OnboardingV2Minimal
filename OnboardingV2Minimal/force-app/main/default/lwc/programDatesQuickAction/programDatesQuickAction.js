import { api, LightningElement, wire } from 'lwc';
import getVendorPrograms from '@salesforce/apex/VendorProgramService.getVendorProgramsForSelection';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import PROGRAM_DATES_OBJECT from '@salesforce/schema/Program_Dates__c';
import ACCOUNT_FIELD from '@salesforce/schema/Program_Dates__c.Account__c';
import PARTNER_CATEGORY_FIELD from '@salesforce/schema/Program_Dates__c.Partner_Category__c';
import PROGRAM_ID_FIELD from '@salesforce/schema/Program_Dates__c.Program_ID__c';
import PROGRAM_ACTIVE_FLAG_FIELD from '@salesforce/schema/Program_Dates__c.Program_Active_Flag__c';
import PROGRAM_DATE_FIELD from '@salesforce/schema/Program_Dates__c.Program_Date__c';
import PROGRAM_DEACTIVATED_DATE_FIELD from '@salesforce/schema/Program_Dates__c.Program_Deactivated_Date__c';
import PROGRAM_DEACTIVATED_FLAG_FIELD from '@salesforce/schema/Program_Dates__c.Program_Deactivated_Flag__c';
import PROGRAM_DEACTIVATED_REASON_FIELD from '@salesforce/schema/Program_Dates__c.Program_Deactivated_Reason__c';
import PROGRAM_REACTIVATED_FLAG_FIELD from '@salesforce/schema/Program_Dates__c.Program_Reactivated_Flag__c';
import PROGRAM_REACTIVATED_DATE_FIELD from '@salesforce/schema/Program_Dates__c.Program_Reactivated_Date__c';
import VENDOR_PROGRAM_FIELD from '@salesforce/schema/Program_Dates__c.Vendor_Program__c';

export default class ProgramDatesQuickAction extends LightningElement {
    @api recordId; // Account Id when launched from Account related list/action

    objectApiName = PROGRAM_DATES_OBJECT;
    defaultAccountId;
    vendorOptions = [];
    selectedVendorProgramId;
    isSaving = false;
    ACCOUNT_FIELD = ACCOUNT_FIELD;
    PARTNER_CATEGORY_FIELD = PARTNER_CATEGORY_FIELD;
    PROGRAM_ID_FIELD = PROGRAM_ID_FIELD;
    PROGRAM_ACTIVE_FLAG_FIELD = PROGRAM_ACTIVE_FLAG_FIELD;
    PROGRAM_DATE_FIELD = PROGRAM_DATE_FIELD;
    PROGRAM_DEACTIVATED_DATE_FIELD = PROGRAM_DEACTIVATED_DATE_FIELD;
    PROGRAM_DEACTIVATED_FLAG_FIELD = PROGRAM_DEACTIVATED_FLAG_FIELD;
    PROGRAM_DEACTIVATED_REASON_FIELD = PROGRAM_DEACTIVATED_REASON_FIELD;
    PROGRAM_REACTIVATED_FLAG_FIELD = PROGRAM_REACTIVATED_FLAG_FIELD;
    PROGRAM_REACTIVATED_DATE_FIELD = PROGRAM_REACTIVATED_DATE_FIELD;

    @wire(getVendorPrograms)
    wiredVendors({ data, error }) {
        if (data) {
            this.vendorOptions = data.map((item) => ({
                label: item.Label__c || 'Unlabeled',
                value: item.Id
            }));
        } else if (error) {
            this.showToast('Error loading vendor programs', this.reduceErrors(error).join(', '), 'error');
        }
    }

    connectedCallback() {
        this.defaultAccountId = this.recordId;
    }

    handleVendorChange(event) {
        this.selectedVendorProgramId = event.detail.value;
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = { ...event.detail.fields };
        fields[ACCOUNT_FIELD.fieldApiName] = this.defaultAccountId;
        fields[VENDOR_PROGRAM_FIELD.fieldApiName] = this.selectedVendorProgramId || null;

        this.isSaving = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess() {
        this.isSaving = false;
        this.showToast('Success', 'Program Dates record created.', 'success');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(event) {
        this.isSaving = false;
        this.showToast('Error creating record', this.reduceErrors(event.detail || event).join(', '), 'error');
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    get hasVendorOptions() {
        return this.vendorOptions && this.vendorOptions.length > 0;
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
