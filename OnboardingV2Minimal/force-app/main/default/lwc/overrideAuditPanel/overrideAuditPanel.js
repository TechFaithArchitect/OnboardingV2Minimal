import { LightningElement, track } from 'lwc';
import getOverrideLogs from '@salesforce/apex/OverrideAuditController.getOverrideLogs';

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Onboarding', fieldName: 'onboardingName' },
    { label: 'Action', fieldName: 'action' },
    { label: 'Source', fieldName: 'source' },
    { label: 'Request ID', fieldName: 'requestId' },
    { label: 'Allowed Programs', fieldName: 'allowedPrograms' },
    { label: 'Prev Status', fieldName: 'previousStatus' },
    { label: 'New Status', fieldName: 'newStatus' },
    { label: 'Requested By', fieldName: 'requestedBy' },
    { label: 'Processed By', fieldName: 'processedBy' },
    { label: 'Processed Date', fieldName: 'processedDate', type: 'date' }
];

export default class OverrideAuditPanel extends LightningElement {
    @track logs = [];
    @track dateRange = 'LAST_30_DAYS';
    @track isLoading = false;

    columns = columns;

    dateRangeOptions = [
        { label: 'Last 7 Days', value: 'LAST_7_DAYS' },
        { label: 'Last 30 Days', value: 'LAST_30_DAYS' },
        { label: 'Last 90 Days', value: 'LAST_90_DAYS' },
        { label: 'All Time', value: 'ALL_TIME' }
    ];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            this.logs = await getOverrideLogs({ dateRange: this.dateRange });
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
}
