import { LightningElement, api, wire } from 'lwc';
import getProgramDates from '@salesforce/apex/ObjectRelatedListController.getProgramDates';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import PROGRAM_DATES_OBJECT from '@salesforce/schema/Program_Dates__c';

const COLUMNS = [
    {
        label: 'Program Name',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'vendorProgramLabel' }, target: '_self' },
        wrapText: true,
        initialWidth: 200
    },
    { label: 'Partner Category', fieldName: 'Partner_Category__c', type: 'text', initialWidth: 180, editable: true },
    { label: 'Inception Date', fieldName: 'Inception_Date__c', type: 'date', initialWidth: 160, editable: true },
    { label: 'Program ID', fieldName: 'Program_ID__c', type: 'text', initialWidth: 150, editable: true },
    { label: 'Program Active Flag', fieldName: 'Program_Active_Flag__c', type: 'boolean', initialWidth: 170, editable: true },
    { label: 'Program Date', fieldName: 'Program_Date__c', type: 'date', initialWidth: 160, editable: true },
    { label: 'Program Deactivated Flag', fieldName: 'Program_Deactivated_Flag__c', type: 'boolean', initialWidth: 200, editable: true },
    { label: 'Program Deactivated Date', fieldName: 'Program_Deactivated_Date__c', type: 'date', initialWidth: 180, editable: true },
    { label: 'Program Deactivated Reason', fieldName: 'Program_Deactivated_Reason__c', type: 'text', wrapText: true, initialWidth: 220, editable: true },
    { label: 'Program Reactivated Date', fieldName: 'Program_Reactivated_Date__c', type: 'date', initialWidth: 180, editable: true }
];

export default class ProgramDatesRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;

    columns = COLUMNS;
    rows = [];
    draftValues = [];
    error;
    showNewModal = false;
    wiredResult;
    objectInfo;
    isChildSaving = false;

    @wire(getObjectInfo, { objectApiName: PROGRAM_DATES_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            // Safe to ignore; header will fall back to default icon
            this.objectInfo = undefined;
        }
    }

    @wire(getProgramDates, { accountId: '$recordId' })
    wiredProgramDates(value) {
        this.wiredResult = value;
        const { data, error } = value;
        if (data) {
            this.rows = data.map(row => ({
                ...row,
                recordLink: `/${row.Id}`,
                vendorProgramLabel: row?.Vendor_Program__r?.Label__c || row?.Name
            }));
            this.error = undefined;
            this.draftValues = [];
        } else if (error) {
            this.rows = [];
            this.error = this.reduceErrors(error).join(', ');
        }
    }

    get hasRows() {
        return Array.isArray(this.rows) && this.rows.length > 0;
    }

    get recordCount() {
        return Array.isArray(this.rows) ? this.rows.length : 0;
    }

    get recordCountLabel() {
        return `(${this.recordCount})`;
    }

    get countLabel() {
        const count = this.recordCount;
        return `${count} record${count === 1 ? '' : 's'}`;
    }

    get headerTitle() {
        return `Program Dates (${this.recordCount})`;
    }

    get itemCountLabel() {
        const count = this.recordCount;
        const suffix = count === 1 ? '' : 's';
        return `${count} item${suffix} • Sorted by Partner Category`;
    }

    /**
     * Extracts icon name from object info theme.
     * Supports both standard and custom icon paths.
     */
    getObjectIconName(themeInfo) {
        if (!themeInfo?.iconUrl) {
            return 'standard:record';
        }
        
        const iconUrl = themeInfo.iconUrl;
        const standardMatch = iconUrl.match(/\/standard\/([^_/]+)/);
        if (standardMatch) {
            return `standard:${standardMatch[1]}`;
        }
        
        const customMatch = iconUrl.match(/\/custom\/([^_/]+)/);
        if (customMatch) {
            return `custom:${customMatch[1]}`;
        }
        
        return 'standard:record';
    }

    get objectIconName() {
        return this.getObjectIconName(this.objectInfo?.themeInfo);
    }

    get iconAlt() {
        return this.objectInfo?.label || 'Program Dates';
    }

    handleHeaderClick(event) {
        event.preventDefault();
        // Navigate to the Program Dates list view filtered by this account
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: 'Program_Dates__r',
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    handleViewAll(event) {
        event.preventDefault();
        this.handleHeaderClick(event);
    }

    handleRefresh() {
        this.refreshList();
    }

    /**
     * Handles inline editing save from datatable.
     * Updates multiple records in batch.
     * @param {CustomEvent} event - Event with draftValues array
     */
    handleInlineSave(event) {
        const drafts = event.detail?.draftValues;
        if (!Array.isArray(drafts) || drafts.length === 0) {
            return;
        }

        const recordInputs = drafts.map((draft) => ({ fields: { ...draft } }));

        Promise.all(recordInputs.map((recordInput) => updateRecord(recordInput)))
            .then(() => {
                this.showToast('Success', 'Records updated', 'success');
                this.draftValues = [];
                this.refreshList();
            })
            .catch((error) => {
                this.showToast('Error updating records', this.reduceErrors(error).join(', '), 'error');
            });
    }

    handleNew() {
        this.showNewModal = true;
    }

    handleModalClose() {
        this.showNewModal = false;
        this.isChildSaving = false;
    }

    handleModalSave() {
        // Event bubbles up from child component
    }

    handleModalSaveAndNew() {
        // Event bubbles up from child component
    }

    handleRecordCreated() {
        this.showNewModal = false;
        this.showToast('Success', 'Program Dates record created.', 'success');
        this.refreshList();
    }

    handleFooterCancel() {
        const formCmp = this.template.querySelector('c-program-dates-screen-action');
        if (formCmp?.cancelAction) {
            formCmp.cancelAction();
        } else {
            this.handleModalClose();
        }
    }

    handleFooterSave() {
        const formCmp = this.template.querySelector('c-program-dates-screen-action');
        formCmp?.save();
    }

    handleFooterSaveAndNew() {
        const formCmp = this.template.querySelector('c-program-dates-screen-action');
        formCmp?.saveAndNew();
    }

    handleSavingChange(event) {
        this.isChildSaving = event.detail?.isSaving || false;
    }

    static ROW_ACTIONS = {
        VIEW: 'view',
        EDIT: 'edit',
        DELETE: 'delete'
    };

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case ProgramDatesRelatedList.ROW_ACTIONS.VIEW:
                this.navigateToRecord(row.Id, 'view');
                break;
            case ProgramDatesRelatedList.ROW_ACTIONS.EDIT:
                this.navigateToRecord(row.Id, 'edit');
                break;
            case ProgramDatesRelatedList.ROW_ACTIONS.DELETE:
                this.deleteRow(row.Id);
                break;
            default:
                break;
        }
    }

    navigateToRecord(recordId, actionName) {
        if (!recordId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'Program_Dates__c',
                actionName
            }
        });
    }

    deleteRow(recordId) {
        if (!recordId) {
            return;
        }
        deleteRecord(recordId)
            .then(() => {
                this.showToast('Deleted', 'Program Dates record deleted.', 'success');
                this.refreshList();
            })
            .catch((error) => {
                this.showToast('Error deleting record', this.reduceErrors(error).join(', '), 'error');
            });
    }

    refreshList() {
        if (this.wiredResult) {
            refreshApex(this.wiredResult);
        }
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
}