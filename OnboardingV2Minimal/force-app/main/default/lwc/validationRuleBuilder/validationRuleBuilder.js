import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRequirementFields from '@salesforce/apex/ValidationRuleBuilderController.getRequirementFields';
import validateExpression from '@salesforce/apex/ValidationRuleBuilderController.validateExpression';
import saveValidationRule from '@salesforce/apex/ValidationRuleBuilderController.saveValidationRule';
import testRuleExpression from '@salesforce/apex/ValidationRuleBuilderController.testRuleExpression';

export default class ValidationRuleBuilder extends LightningElement {
    @api recordId; // For editing existing rules

    @track rule = {
        name: '',
        description: '',
        validationType: 'Format',
        expression: '',
        errorMessage: '',
        validationMode: 'Active',
        requirementFieldId: null,
        externalServiceId: null
    };

    @track requirementFields = [];
    @track isLoading = false;
    @track validationResult = null;
    @track testResult = null;
    @track showExpressionBuilder = false;
    @track showTestPanel = false;

    validationTypeOptions = [
        { label: 'Format', value: 'Format' },
        { label: 'Cross-Field', value: 'Cross-Field' },
        { label: 'External', value: 'External' }
    ];

    validationModeOptions = [
        { label: 'Active', value: 'Active' },
        { label: 'Test', value: 'Test' },
        { label: 'Disabled', value: 'Disabled' }
    ];

    commonPatterns = [
        { label: 'SSN Format (XXX-XX-XXXX)', value: 'REGEX(Value__c, "\\\\d{3}-\\\\d{2}-\\\\d{4}")' },
        { label: 'Email Format', value: 'REGEX(Value__c, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\\\.[a-zA-Z]{2,}")' },
        { label: 'Phone Format (XXX-XXX-XXXX)', value: 'REGEX(Value__c, "\\\\d{3}-\\\\d{3}-\\\\d{4}")' },
        { label: 'Not Blank', value: 'NOT(ISBLANK(Value__c))' },
        { label: 'Length Check (Min 5)', value: 'LEN(Value__c) >= 5' }
    ];

    get commonPatternOptions() {
        return this.commonPatterns.map(p => ({
            label: p.label,
            value: p.value
        }));
    }

    get expressionBuilderLabel() {
        return this.showExpressionBuilder ? 'Hide Expression Help' : 'Show Expression Help';
    }

    get testPanelLabel() {
        return this.showTestPanel ? 'Hide Test Panel' : 'Show Test Panel';
    }

    connectedCallback() {
        this.loadRequirementFields();
        if (this.recordId) {
            this.loadExistingRule();
        }
    }

    loadRequirementFields() {
        getRequirementFields()
            .then(result => {
                this.requirementFields = result;
            })
            .catch(error => {
                console.error('Error loading requirement fields:', error);
                this.showError('Failed to load requirement fields');
            });
    }

    loadExistingRule() {
        // TODO: Load existing rule when editing
        // This will be implemented when metadata retrieval is available
    }

    handleFieldChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.rule[field] = value;

        // Clear validation when expression changes
        if (field === 'expression') {
            this.validationResult = null;
        }
    }

    handlePatternSelect(event) {
        const pattern = event.target.value;
        if (pattern) {
            this.rule.expression = pattern;
            this.handleFieldChange({ target: { name: 'expression', value: pattern } });
        }
    }

    handleValidateExpression() {
        if (!this.rule.expression) {
            this.showWarning('Please enter a validation expression');
            return;
        }

        this.isLoading = true;
        validateExpression({
            expression: this.rule.expression,
            validationType: this.rule.validationType
        })
        .then(result => {
            this.isLoading = false;
            this.validationResult = result;
            if (result.isValid) {
                this.showSuccess('Expression syntax is valid');
            } else {
                this.showError('Expression syntax error: ' + result.errorMessage);
            }
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error validating expression:', error);
            this.showError('Failed to validate expression: ' + (error.body?.message || error.message));
        });
    }

    handleTestRule() {
        if (!this.rule.expression) {
            this.showWarning('Please enter a validation expression first');
            return;
        }

        this.isLoading = true;
        this.showTestPanel = true;

        // Get test value from input
        const testInput = this.template.querySelector('lightning-input[name="testValue"]');
        const testValue = testInput ? testInput.value : '';
        
        // Build test values map
        const testValues = {
            'Value': testValue,
            'Value__c': testValue
        };
        
        testRuleExpression({
            expression: this.rule.expression,
            testValues: testValues
        })
        .then(result => {
            this.isLoading = false;
            this.testResult = result;
            if (result.isValid) {
                this.showSuccess('Test passed: ' + (result.message || 'Validation passed'));
            } else {
                this.showWarning('Test failed: ' + (result.errorMessage || 'Validation failed'));
            }
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error testing rule:', error);
            this.showError('Failed to test rule: ' + (error.body?.message || error.message));
        });
    }

    handleSave() {
        // Validate required fields
        if (!this.rule.name || !this.rule.expression || !this.rule.errorMessage) {
            this.showError('Please fill in all required fields (Name, Expression, Error Message)');
            return;
        }

        this.isLoading = true;
        saveValidationRule({
            ruleData: this.rule,
            recordId: this.recordId
        })
        .then(result => {
            this.isLoading = false;
            this.showSuccess('Validation rule saved successfully');
            // Dispatch event to refresh parent or navigate
            this.dispatchEvent(new CustomEvent('saved', {
                detail: { ruleId: result.id }
            }));
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error saving validation rule:', error);
            this.showError('Failed to save validation rule: ' + (error.body?.message || error.message));
        });
    }

    toggleExpressionBuilder() {
        this.showExpressionBuilder = !this.showExpressionBuilder;
    }

    toggleTestPanel() {
        this.showTestPanel = !this.showTestPanel;
    }

    get fieldOptions() {
        return this.requirementFields.map(field => ({
            label: field.label,
            value: field.apiName
        }));
    }

    get canSave() {
        return this.rule.name && 
               this.rule.expression && 
               this.rule.errorMessage &&
               (!this.validationResult || this.validationResult.isValid);
    }

    get isSaveDisabled() {
        return this.isLoading || !this.canSave;
    }

    get showExternalServiceField() {
        return this.rule.validationType === 'External';
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning'
        }));
    }
}

