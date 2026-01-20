import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getTwilioConfigurations from '@salesforce/apex/TwilioSettingsController.getTwilioConfigurations';
import validateConfiguration from '@salesforce/apex/TwilioSettingsController.validateConfiguration';

export default class TwilioSettings extends LightningElement {
    @track configurations = [];
    @track isLoading = false;
    @track showEditModal = false;
    @track editingConfig = null;
    @track showAccessDenied = false;
    
    wiredConfigurationsResult;
    
    columns = [
        { label: 'Label', fieldName: 'masterLabel', type: 'text' },
        { label: 'From Phone', fieldName: 'fromPhoneNumber', type: 'phone' },
        { label: 'Named Credential', fieldName: 'namedCredential', type: 'text' },
        { label: 'Account SID', fieldName: 'accountSid', type: 'text' },
        { 
            label: 'Active', 
            fieldName: 'active', 
            type: 'boolean',
            cellAttributes: { class: { fieldName: 'activeClass' } }
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];
    
    @wire(getTwilioConfigurations)
    wiredConfigurations(result) {
        this.wiredConfigurationsResult = result;
        const { data, error } = result;
        
        if (data) {
            this.showAccessDenied = false;
            this.configurations = data.map(config => ({
                ...config,
                activeClass: config.active ? 'slds-text-color_success' : ''
            }));
        } else if (error) {
            const errorMessage = this.formatError(error);
            // Check if it's an access denied error
            if (errorMessage.includes('Access denied') || errorMessage.includes('restricted')) {
                this.showAccessDenied = true;
            } else {
                this.showToast('Error', errorMessage, 'error');
            }
            this.configurations = [];
        }
    }
    
    get hasConfigurations() {
        return this.configurations && this.configurations.length > 0;
    }
    
    get activeConfigCount() {
        return this.configurations.filter(c => c.active).length;
    }
    
    get validationMessage() {
        if (this.activeConfigCount === 0) {
            return 'No active configuration. At least one active configuration is required.';
        }
        if (this.activeConfigCount > 1) {
            return 'Multiple active configurations found. Only one should be active at a time.';
        }
        return null;
    }
    
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        if (actionName === 'edit') {
            this.editConfiguration(row);
        }
    }
    
    editConfiguration(config) {
        // Note: Custom Metadata cannot be edited via UI in standard way
        // This would require Metadata API deployment
        // For now, show a message directing admin to use Setup UI or Metadata API
        this.showToast(
            'Info',
            'Custom Metadata records must be edited via Setup > Custom Metadata Types or Metadata API. Developer Name: ' + config.developerName,
            'info'
        );
    }
    
    async handleValidate() {
        this.isLoading = true;
        try {
            const result = await validateConfiguration();
            if (result.isValid) {
                this.showToast('Success', 'Configuration is valid.', 'success');
            } else {
                this.showToast('Validation Failed', result.errorMessage, 'warning');
            }
        } catch (error) {
            this.showToast('Error', this.formatError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleRefresh() {
        this.isLoading = true;
        try {
            if (this.wiredConfigurationsResult) {
                await refreshApex(this.wiredConfigurationsResult);
            }
            this.showToast('Success', 'Configuration refreshed.', 'success');
        } catch (error) {
            this.showToast('Error', this.formatError(error), 'error');
        } finally {
            this.isLoading = false;
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
    
    formatError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return error && error.message ? error.message : 'Unknown error';
    }
}

