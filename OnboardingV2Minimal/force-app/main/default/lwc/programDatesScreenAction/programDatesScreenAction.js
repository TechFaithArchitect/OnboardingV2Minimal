/**
 * Program Dates Form Component (Child Component)
 *
 * This component provides the form fields and business logic for creating
 * Program Dates records. It works as a child component within the
 * relatedObjectActionModal parent component.
 */
import { api, LightningElement, wire, track } from 'lwc';
import getLookupOptions from '@salesforce/apex/ObjectRelatedListController.getLookupOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';

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

const REQUIRED_FIELDS_ERROR = 'Account and Vendor Program are required fields.';
const DEFAULT_VENDOR_LABEL = 'Unlabeled';
const VENDOR_PROGRAM_FIELD_API_NAME = 'Vendor_Program__c';
const PROGRAM_FIELD_CONFIG = [
    { name: 'programActiveFlag', schema: PROGRAM_ACTIVE_FLAG_FIELD, isBoolean: true },
    { name: 'programDate', schema: PROGRAM_DATE_FIELD, isBoolean: false },
    { name: 'programDeactivatedDate', schema: PROGRAM_DEACTIVATED_DATE_FIELD, isBoolean: false },
    { name: 'programDeactivatedFlag', schema: PROGRAM_DEACTIVATED_FLAG_FIELD, isBoolean: true },
    { name: 'programDeactivatedReason', schema: PROGRAM_DEACTIVATED_REASON_FIELD, isBoolean: false },
    { name: 'programReactivatedFlag', schema: PROGRAM_REACTIVATED_FLAG_FIELD, isBoolean: true },
    { name: 'programReactivatedDate', schema: PROGRAM_REACTIVATED_DATE_FIELD, isBoolean: false }
];

export default class ProgramDatesScreenAction extends LightningElement {
    @api recordId;

    objectApiName = PROGRAM_DATES_OBJECT;
    saveAndNew = false;

    partnerCategory = '';
    programId = '';
    accountId = '';
    selectedVendorProgramId = '';

    @track vendorOptions = [];

    @track programFields = [
        { name: 'programActiveFlag', label: 'Program Active Flag', type: 'checkbox', value: false },
        { name: 'programDate', label: 'Program Date', type: 'date', value: '' },
        { name: 'programDeactivatedFlag', label: 'Program Deactivated Flag', type: 'checkbox', value: false },
        { name: 'programDeactivatedDate', label: 'Program Deactivated Date', type: 'date', value: '' },
        { name: 'programDeactivatedReason', label: 'Program Deactivated Reason', type: 'text', value: '' },
        { name: 'programReactivatedFlag', label: 'Program Reactivated Flag', type: 'checkbox', value: false },
        { name: 'programReactivatedDate', label: 'Program Reactivated Date', type: 'date', value: '' }
    ];

    @wire(getLookupOptions, {
        objectApiName: 'Vendor_Customization__c',
        labelFieldApiName: 'Label__c',
        orderByField: 'Label__c',
        orderDirection: 'ASC',
        recordLimit: 500
    })
    wiredVendors({ data, error }) {
        if (data) {
            this.vendorOptions = data.map((item) => ({
                label: item.label || item.Label__c || DEFAULT_VENDOR_LABEL,
                value: item.value || item.Id
            }));
        } else if (error) {
            this.showToast('Error loading vendor programs', this.reduceErrors(error).join(', '), 'error');
        }
    }

    connectedCallback() {
        this.accountId = this.isAccountId(this.recordId) ? this.recordId : '';
        this.notifyValidity();
    }

    handleChange(event) {
        const { name, value, type, checked } = event.target;

        if (name === 'partnerCategory') {
            this.partnerCategory = value;
        } else if (name === 'programId') {
            this.programId = value;
        } else {
            this.programFields = this.programFields.map((field) =>
                field.name === name
                    ? { ...field, value: type === 'checkbox' ? checked : value }
                    : field
            );
        }
    }

    handleVendorChange(event) {
        this.selectedVendorProgramId = event.detail.value;
        this.notifyValidity();
    }

    @api
    triggerSave() {
        this.saveAndNew = false;
        this.submitForm();
    }

    @api
    triggerSaveAndNew() {
        this.saveAndNew = true;
        this.submitForm();
    }

    async submitForm() {
        if (!this.isFormValid()) {
            this.showToast('Validation Error', REQUIRED_FIELDS_ERROR, 'error');
            this.dispatchEvent(new CustomEvent('error', { detail: { message: 'Required fields missing' } }));
            return;
        }

        const fields = this.buildFieldsObject();

        try {
            const result = await createRecord({
                apiName: PROGRAM_DATES_OBJECT.objectApiName,
                fields
            });
            this.handleSaveSuccess(result.id);
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    isFormValid() {
        return !!this.accountId && !!this.selectedVendorProgramId;
    }

    buildFieldsObject() {
        const fields = {
            [ACCOUNT_FIELD.fieldApiName]: this.accountId,
            [VENDOR_PROGRAM_FIELD_API_NAME]: this.selectedVendorProgramId
        };

        this.addOptionalTextField(fields, this.partnerCategory, PARTNER_CATEGORY_FIELD);
        this.addOptionalTextField(fields, this.programId, PROGRAM_ID_FIELD);
        this.addProgramFields(fields);

        return fields;
    }

    addOptionalTextField(fields, value, fieldSchema) {
        if (value) {
            fields[fieldSchema.fieldApiName] = value;
        }
    }

    addProgramFields(fields) {
        PROGRAM_FIELD_CONFIG.forEach((config) => {
            const fieldValue = this.getFieldValue(config.name);

            if (config.isBoolean) {
                if (fieldValue !== null && fieldValue !== undefined) {
                    fields[config.schema.fieldApiName] = fieldValue;
                }
            } else if (fieldValue) {
                fields[config.schema.fieldApiName] = fieldValue;
            }
        });
    }

    handleSaveSuccess(recordId) {
        this.dispatchEvent(
            new CustomEvent('success', {
                detail: {
                    id: recordId,
                    recordId,
                    saveAndNew: this.saveAndNew
                }
            })
        );

        if (this.saveAndNew) {
            this.resetForm();
            this.saveAndNew = false;
        }
    }

    handleSaveError(error) {
        this.dispatchEvent(new CustomEvent('error', { detail: error }));
        this.showToast('Error creating record', this.reduceErrors(error).join(', '), 'error');
    }

    getFieldValue(name) {
        const field = this.programFields.find((item) => item.name === name);
        return field ? field.value : null;
    }

    get programFieldValues() {
        const values = {};
        this.programFields.forEach((item) => {
            values[item.name] = item.value;
        });
        return values;
    }

    get getProgramFieldValue() {
        return this.programFieldValues;
    }

    handleAccountChange(event) {
        this.accountId = event.detail.value;
        this.notifyValidity();
    }

    notifyValidity() {
        const isValid = this.isFormValid();
        this.dispatchEvent(
            new CustomEvent('validitychange', {
                detail: { isValid },
                bubbles: true,
                composed: true
            })
        );
    }

    handleCancel() {
        this.resetForm();
    }

    resetForm() {
        this.partnerCategory = '';
        this.programId = '';
        this.selectedVendorProgramId = '';
        this.programFields = this.programFields.map((item) => ({
            ...item,
            value: item.type === 'checkbox' ? false : ''
        }));
        this.accountId = this.isAccountId(this.recordId) ? this.recordId : '';
        this.notifyValidity();
    }

    isAccountId(value) {
        return typeof value === 'string' && value.startsWith('001');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(errors) {
        if (!errors) return ['Unknown error'];
        if (Array.isArray(errors)) return errors.flatMap((error) => this.reduceErrors(error));
        if (errors.body?.pageErrors?.length) return errors.body.pageErrors.map((item) => item.message);
        if (errors.body?.message) return [errors.body.message];
        if (typeof errors.message === 'string') return [errors.message];
        return ['Unknown error'];
    }
}