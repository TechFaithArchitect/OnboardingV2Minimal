import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getConditions from '@salesforce/apex/OnboardingStatusRuleController.getConditions';
import deleteCondition from '@salesforce/apex/OnboardingStatusRuleController.deleteCondition';
import { extractErrorMessage } from 'c/utils';

export default class RequirementConditionList extends LightningElement {
    @api ruleId;
    @track conditions = [];

    columns = [
        { label: 'Sequence', fieldName: 'Sequence__c', type: 'number' },
        { label: 'Requirement', fieldName: 'requirementName' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Delete',
                name: 'delete',
                variant: 'destructive'
            }
        }
    ];

    @wire(getConditions, { ruleId: '$ruleId' })
    wiredConditions(result) {
        this.wiredConditionsResult = result; // Store result for refreshApex
        const { error, data } = result;
        if (data) {
            this.conditions = data.map(row => ({
                ...row,
                requirementName: row.Vendor_Program_Requirement__r.Name
            }));
        } else if (error) {
            // Surface the error via a custom event for parent to handle
            this.dispatchEvent(
                new CustomEvent('error', {
                    detail: {
                        message: extractErrorMessage(error, 'Failed to load requirement conditions.')
                    },
                    bubbles: true,
                    composed: true
                })
            );
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            deleteCondition({ conditionId: row.Id })
                .then(() => {
                    if (this.wiredConditionsResult) {
                        return refreshApex(this.wiredConditionsResult);
                    }
                    return this.refreshData();
                })
                .catch(error => {
                    this.dispatchEvent(
                        new CustomEvent('error', {
                            detail: {
                                message: extractErrorMessage(error, 'Failed to delete condition.')
                            },
                            bubbles: true,
                            composed: true
                        })
                    );
                });
        }
    }

    addCondition() {
        // Ideally open a modal or navigation to a child record form
        alert('Add Condition – not yet implemented');
    }

    async refreshData() {
        try {
            const data = await getConditions({ ruleId: this.ruleId });
            this.conditions = (data || []).map(row => ({
                ...row,
                requirementName: row.Vendor_Program_Requirement__r.Name
            }));
        } catch (error) {
            this.dispatchEvent(
                new CustomEvent('error', {
                    detail: {
                        message: extractErrorMessage(error, 'Failed to refresh requirement conditions.')
                    },
                    bubbles: true,
                    composed: true
                })
            );
        }
    }
}
