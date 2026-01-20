import { LightningElement, wire, track } from 'lwc';
import getRules from '@salesforce/apex/OnboardingStatusRuleController.getRules';

export default class OnboardingStatusRuleList extends LightningElement {
    @track rules = [];
    @track selectedVendorGroup = null;

    vendorGroupOptions = [
        { label: 'Group A', value: '001XXXXXXX' },
        { label: 'Group B', value: '001YYYYYYY' },
        // Ideally dynamically fetched
    ];

    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Logic Type', fieldName: 'Evaluation_Logic__c' },
        { label: 'Override Status', fieldName: 'Override_Status__c' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Edit',
                name: 'edit',
                title: 'Edit',
                variant: 'brand'
            }
        }
    ];

    @wire(getRules, { vendorProgramGroupId: '$selectedVendorGroup' })
    wiredRules({ error, data }) {
        if (data) {
            this.rules = data;
        }
    }

    handleVendorGroupChange(event) {
        this.selectedVendorGroup = event.detail.value;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === 'edit') {
            // TODO: Fire event to parent or route to editor
            // Edit functionality to be implemented
        }
    }
}
