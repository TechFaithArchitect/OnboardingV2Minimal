import { LightningElement, api } from 'lwc';

export default class ExpFlowStepWrapper extends LightningElement {
    @api heading;
    @api helperText;
    @api variant = 'default';

    get hasHeading() {
        return this.hasValue(this.heading);
    }

    get hasHelperText() {
        return this.hasValue(this.helperText);
    }

    get headerClass() {
        const normalized = (this.variant || 'default').toLowerCase();
        if (normalized === 'shade') {
            return 'step-header slds-box slds-theme_shade';
        }
        if (normalized === 'info') {
            return 'step-header slds-box slds-theme_info';
        }
        if (normalized === 'warning') {
            return 'step-header slds-box slds-theme_warning';
        }
        if (normalized === 'error') {
            return 'step-header slds-box slds-theme_error';
        }
        if (normalized === 'success') {
            return 'step-header slds-box slds-theme_success';
        }
        return 'step-header step-header_plain';
    }

    hasValue(value) {
        return value !== null && value !== undefined && String(value).trim() !== '';
    }
}
