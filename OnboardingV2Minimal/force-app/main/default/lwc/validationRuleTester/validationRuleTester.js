import { LightningElement, track } from 'lwc';
import getRequirementFields from '@salesforce/apex/ValidationRuleBuilderController.getRequirementFields';
import testValue from '@salesforce/apex/ValidationRuleTesterController.testValue';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ValidationRuleTester extends LightningElement {
    @track fieldOptions = [];
    @track selectedField;
    @track testValue;
    @track result;
    @track isTesting = false;

    connectedCallback() {
        this.loadFields();
    }

    async loadFields() {
        try {
            const fields = await getRequirementFields();
            this.fieldOptions = fields.map(f => ({
                label: f.label + (f.apiName ? ` (${f.apiName})` : ''),
                value: f.apiName
            }));
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        }
    }

    handleFieldChange(event) {
        this.selectedField = event.detail.value;
    }

    handleValueChange(event) {
        this.testValue = event.detail.value;
    }

    async handleTest() {
        if (!this.selectedField) {
            this.showToast('Error', 'Select a requirement field.', 'error');
            return;
        }
        this.isTesting = true;
        this.result = null;
        try {
            const res = await testValue({ requirementFieldApiName: this.selectedField, value: this.testValue });
            this.result = res;
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        } finally {
            this.isTesting = false;
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

    formatError(err) {
        if (err && err.body && err.body.message) {
            return err.body.message;
        }
        return err && err.message ? err.message : 'Unknown error';
    }
}
