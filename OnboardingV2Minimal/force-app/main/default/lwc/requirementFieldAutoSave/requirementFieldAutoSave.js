import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveFieldValue from '@salesforce/apex/RequirementFieldValueController.saveFieldValue';

export default class RequirementFieldAutoSave extends LightningElement {
    @api requirementFieldValueId;
    @api requirementFieldId;
    @api requirementRecordId; // Renamed from onboardingRequirementId - properties starting with "on" are reserved for event handlers
    @api fieldApiName;
    @api fieldType;
    @api isEncrypted;
    @api autoSaveInterval = 30000; // 30 seconds default

    @track fieldValue = '';
    @track isSaving = false;
    @track lastSaved = null;
    @track saveTimer;
    @api fieldLabel;

    connectedCallback() {
        // Start auto-save timer
        this.startAutoSaveTimer();
    }

    disconnectedCallback() {
        // Save on unmount
        this.saveFieldValue();
        // Clear timer
        if (this.saveTimer) {
            clearInterval(this.saveTimer);
        }
    }

    handleValueChange(event) {
        this.fieldValue = event.target.value;
        // Reset auto-save timer
        this.resetAutoSaveTimer();
    }

    handleFieldBlur() {
        // Save immediately on blur
        this.saveFieldValue();
    }

    startAutoSaveTimer() {
        // Clear existing timer
        if (this.saveTimer) {
            clearInterval(this.saveTimer);
        }

        // Set new timer
        this.saveTimer = setInterval(() => {
            if (this.fieldValue && !this.isSaving) {
                this.saveFieldValue();
            }
        }, this.autoSaveInterval);
    }

    resetAutoSaveTimer() {
        this.startAutoSaveTimer();
    }

    saveFieldValue() {
        if (!this.fieldValue || this.isSaving) {
            return;
        }

        this.isSaving = true;
        this.showSavingIndicator();

        saveFieldValue({
            requirementFieldValueId: this.requirementFieldValueId,
            requirementFieldId: this.requirementFieldId,
            onboardingRequirementId: this.requirementRecordId,
            fieldApiName: this.fieldApiName,
            value: this.fieldValue,
            isEncrypted: this.isEncrypted || false
        })
        .then(result => {
            this.isSaving = false;
            this.lastSaved = new Date();
            this.requirementFieldValueId = result.id;
            this.showSavedConfirmation();
        })
        .catch(error => {
            this.isSaving = false;
            console.error('Error saving field value:', error);
            this.showError('Failed to save: ' + (error.body?.message || error.message));
        });
    }

    showSavingIndicator() {
        // Dispatch event to parent to show saving indicator
        this.dispatchEvent(new CustomEvent('saving', {
            detail: { fieldApiName: this.fieldApiName }
        }));
    }

    showSavedConfirmation() {
        // Dispatch event to parent to show saved confirmation
        this.dispatchEvent(new CustomEvent('saved', {
            detail: { 
                fieldApiName: this.fieldApiName,
                timestamp: this.lastSaved
            }
        }));

        // Also show toast
        this.dispatchEvent(new ShowToastEvent({
            title: 'Saved',
            message: 'Field value saved successfully',
            variant: 'success',
            mode: 'sticky'
        }));
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    get saveStatusText() {
        if (this.isSaving) {
            return 'Saving...';
        }
        if (this.lastSaved) {
            const secondsAgo = Math.floor((new Date() - this.lastSaved) / 1000);
            if (secondsAgo < 60) {
                return `Saved ${secondsAgo}s ago`;
            }
            return `Saved at ${this.lastSaved.toLocaleTimeString()}`;
        }
        return '';
    }

    get saveStatusIcon() {
        return this.isSaving ? 'utility:spinner' : 'utility:success';
    }

    get saveStatusClass() {
        return this.isSaving ? 'slds-icon-text-default' : 'slds-icon-text-success';
    }
}

