/**
 * Object Related List Component
 * 
 * A reusable component for displaying related records in a datatable format.
 * Accepts configuration via public properties for maximum flexibility.
 * 
 * Usage:
 * 1. Pass objectApiName to determine the object
 * 2. Pass columns array for datatable columns
 * 3. Pass parentFieldApiName to specify the lookup field
 * 4. Pass fieldApiNames array for fields to query
 * 5. Optionally pass relationshipFieldApiNames for related object fields
 * 6. Optionally pass childComponent name for the modal form
 * 7. Optionally pass rowTransform function name (handled in parent wrapper)
 */
import { LightningElement, api, wire } from 'lwc';
import getRelatedRecords from '@salesforce/apex/ObjectRelatedListController.getRelatedRecords';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class ObjectRelatedList extends NavigationMixin(LightningElement) {
    /** Parent record ID (e.g., Account Id) */
    @api recordId;
    
    /** Object API name for the related records (e.g., 'Program_Dates__c') */
    @api objectApiName;
    
    /** Parent field API name that links to the parent record (e.g., 'Account__c') */
    @api parentFieldApiName;
    
    /** Array of field API names to query and display */
    @api fieldApiNames = [];
    
    /** Array of relationship field API names (e.g., ['Vendor_Program__r.Label__c']) */
    @api relationshipFieldApiNames = [];
    
    /** Array of column definitions for lightning-datatable */
    @api columns = [];
    
    /** Field API name to use for ordering (e.g., 'Program_Date__c') */
    @api orderByField;
    
    /** Order direction: 'ASC' or 'DESC' (default: 'DESC') */
    @api orderDirection = 'DESC';
    
    /** Child component name for the modal form (e.g., 'programDatesScreenAction') */
    @api childComponent;
    
    /** Modal title override (defaults to object label + 'New') */
    @api modalTitle;
    
    /** Object label override (defaults to object info label) */
    @api objectLabel;
    
    /** Custom text for the header title (defaults to object label + count) */
    @api headerTitleOverride;
    
    /** Custom text for item count label */
    @api itemCountLabelOverride;
    
    /** Relationship API name for navigation (e.g., 'Program_Dates__r') */
    @api relationshipApiName;
    
    /** Optional limit for number of records to query (defaults to 2000) */
    @api recordLimit;

    rows = [];
    draftValues = [];
    error;
    showNewModal = false;
    wiredResult;
    objectInfo;

    /**
     * Builds query configuration for Apex controller.
     * Returns undefined if required properties are missing (prevents unnecessary wire calls).
     */
    get queryConfig() {
        if (!this.objectApiName || !this.parentFieldApiName || !this.recordId || !this.fieldApiNames?.length) {
            return undefined;
        }
        
        return {
            objectApiName: this.objectApiName,
            parentFieldApiName: this.parentFieldApiName,
            parentRecordId: this.recordId,
            fieldApiNames: this.fieldApiNames,
            relationshipFieldApiNames: this.relationshipFieldApiNames || [],
            orderByField: this.orderByField,
            orderDirection: this.orderDirection || 'DESC',
            recordLimit: this.recordLimit
        };
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            // Safe to ignore; will fall back to default icon
            this.objectInfo = undefined;
        }
    }

    @wire(getRelatedRecords, { config: '$queryConfig' })
    wiredRelatedRecords(value) {
        this.wiredResult = value;
        const { data, error } = value;
        if (data) {
            this.rows = this.transformRows(data);
            this.error = undefined;
            this.draftValues = [];
        } else if (error) {
            this.rows = [];
            this.error = this.reduceErrors(error).join(', ');
        }
    }

    /**
     * Transforms raw query results into display rows.
     * Adds recordLink field for navigation.
     * @param {Array} data - Raw query results
     * @returns {Array} Transformed rows with recordLink
     */
    transformRows(data) {
        if (!Array.isArray(data)) {
            return [];
        }
        return data.map(row => ({
            ...row,
            recordLink: `/${row.Id || ''}`
        }));
    }

    get hasRows() {
        return this.rows && this.rows.length > 0;
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
        if (this.headerTitleOverride) {
            return this.headerTitleOverride.replace('{count}', this.recordCount);
        }
        const label = this.objectLabel || this.objectInfo?.label || this.objectApiName || 'Records';
        return `${label} (${this.recordCount})`;
    }

    get itemCountLabel() {
        if (this.itemCountLabelOverride) {
            return this.itemCountLabelOverride;
        }
        const count = this.recordCount;
        const suffix = count === 1 ? '' : 's';
        return `${count} item${suffix}`;
    }

    get displayModalTitle() {
        if (this.modalTitle) {
            return this.modalTitle;
        }
        const label = this.objectLabel || this.objectInfo?.label || 'Record';
        return `New ${label}`;
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
        return this.objectLabel || this.objectInfo?.label || this.objectApiName || 'Records';
    }

    handleHeaderClick(event) {
        event.preventDefault();
        if (this.relationshipApiName && this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: this.recordId,
                    relationshipApiName: this.relationshipApiName,
                    objectApiName: this.objectApiName,
                    actionName: 'view'
                }
            });
        }
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
    }

    handleRecordCreated() {
        this.showNewModal = false;
        const label = this.objectLabel || this.objectInfo?.label || 'Record';
        this.showToast('Success', `${label} record created.`, 'success');
        this.refreshList();
    }

    // Constants for row actions
    static ROW_ACTIONS = {
        VIEW: 'view',
        EDIT: 'edit',
        DELETE: 'delete'
    };

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case ObjectRelatedList.ROW_ACTIONS.VIEW:
                this.navigateToRecord(row.Id, 'view');
                break;
            case ObjectRelatedList.ROW_ACTIONS.EDIT:
                this.navigateToRecord(row.Id, 'edit');
                break;
            case ObjectRelatedList.ROW_ACTIONS.DELETE:
                this.deleteRow(row.Id);
                break;
            default:
                break;
        }
    }

    navigateToRecord(recordId, actionName) {
        if (!recordId || !this.objectApiName) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: this.objectApiName,
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
                const label = this.objectLabel || this.objectInfo?.label || 'Record';
                this.showToast('Deleted', `${label} record deleted.`, 'success');
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

