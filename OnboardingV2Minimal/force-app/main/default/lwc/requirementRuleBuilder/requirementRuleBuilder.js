import { LightningElement, track } from 'lwc';
import getValidationRules from '@salesforce/apex/ValidationRuleBuilderController.getValidationRules';
import saveValidationRule from '@salesforce/apex/ValidationRuleBuilderController.saveValidationRule';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Label', fieldName: 'label' },
    { label: 'Field', fieldName: 'requirementField' },
    { label: 'Type', fieldName: 'validationType' },
    { label: 'Active', fieldName: 'isActive', type: 'boolean' },
    {
        type: 'button',
        typeAttributes: {
            label: 'Edit',
            name: 'edit',
            variant: 'base'
        }
    }
];

const defaultForm = {
    developerName: null,
    label: '',
    requirementField: '',
    validationType: 'Format',
    validationMode: 'Live',
    validationExpression: '',
    errorMessage: '',
    externalService: '',
    sequence: null,
    description: '',
    isActive: true
};

export default class RequirementRuleBuilder extends LightningElement {
    @track rules = [];
    @track form = { ...defaultForm };
    @track editing = false;

    columns = columns;

    validationTypeOptions = [
        { label: 'Format', value: 'Format' },
        { label: 'Cross-Field', value: 'Cross-Field' },
        { label: 'External', value: 'External' }
    ];

    validationModeOptions = [
        { label: 'Live', value: 'Live' },
        { label: 'Test', value: 'Test' },
        { label: 'Disabled', value: 'Disabled' }
    ];

    connectedCallback() {
        this.loadRules();
    }

    get formTitle() {
        return this.form.developerName ? 'Edit Rule' : 'New Rule';
    }

    async loadRules() {
        try {
            this.rules = await getValidationRules();
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'edit') {
            this.form = { ...row };
            this.editing = true;
        }
    }

    handleNew() {
        this.form = { ...defaultForm };
        this.editing = true;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.form = { ...this.form, [field]: event.target.value };
    }

    handleCheckboxChange(event) {
        const field = event.target.dataset.field;
        this.form = { ...this.form, [field]: event.target.checked };
    }

    async handleSave() {
        if (!this.form.label || !this.form.requirementField || !this.form.validationExpression || !this.form.errorMessage) {
            this.showToast('Error', 'Label, Requirement Field, Validation Expression, and Error Message are required.', 'error');
            return;
        }
        try {
            const payload = {
                name: this.form.label,
                requirementField: this.form.requirementField,
                validationType: this.form.validationType,
                validationMode: this.form.validationMode,
                expression: this.form.validationExpression,
                errorMessage: this.form.errorMessage,
                externalServiceId: this.form.externalService,
                sequence: this.form.sequence,
                description: this.form.description,
                isActive: this.form.isActive
            };
            await saveValidationRule({ ruleData: payload, recordId: this.form.developerName });
            this.showToast('Success', 'Rule saved.', 'success');
            this.editing = false;
            this.loadRules();
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        }
    }

    handleCancel() {
        this.editing = false;
        this.form = { ...defaultForm };
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
        return err.message || 'Unknown error';
    }
}
