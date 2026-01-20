import { LightningElement, track } from 'lwc';
import getValidationFailures from '@salesforce/apex/OnboardingAdminDashboardController.getValidationFailures';

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Rule', fieldName: 'ruleName' },
    { label: 'Field API', fieldName: 'requirementFieldApiName' },
    { label: 'Result', fieldName: 'result' },
    { label: 'Message', fieldName: 'message' },
    { label: 'Validated On', fieldName: 'validatedOn', type: 'date' },
    { label: 'Created By', fieldName: 'createdBy' },
    { label: 'Created', fieldName: 'createdDate', type: 'date' }
];

export default class ValidationFailuresPanel extends LightningElement {
    @track failures = [];
    @track dateRange = 'LAST_7_DAYS';
    @track validationType = '';
    @track isLoading = false;

    columns = columns;

    dateRangeOptions = [
        { label: 'Last 24 Hours', value: 'LAST_24_HOURS' },
        { label: 'Last 7 Days', value: 'LAST_7_DAYS' },
        { label: 'Last 30 Days', value: 'LAST_30_DAYS' },
        { label: 'All Time', value: 'ALL_TIME' }
    ];

    validationTypeOptions = [
        { label: 'All', value: '' },
        { label: 'Format', value: 'Format' },
        { label: 'Cross-Field', value: 'Cross-Field' },
        { label: 'External', value: 'External' },
        { label: 'Other', value: 'Other' }
    ];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            const filters = {
                dateRange: this.dateRange,
                validationType: this.validationType || null
            };
            this.failures = await getValidationFailures({ groupBy: null, filters });
        } catch (err) {
            // swallow for now
        } finally {
            this.isLoading = false;
        }
    }

    handleDateRangeChange(event) {
        this.dateRange = event.detail.value;
        this.loadData();
    }

    handleValidationTypeChange(event) {
        this.validationType = event.detail.value;
        this.loadData();
    }
}
