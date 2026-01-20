import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAdobeSyncFailures from '@salesforce/apex/OnboardingAdminDashboardController.getAdobeSyncFailures';
import retryAdobeSync from '@salesforce/apex/OnboardingAdminDashboardController.retryAdobeSync';
import resolveAdobeSyncFailure from '@salesforce/apex/OnboardingAdminDashboardController.resolveAdobeSyncFailure';

export default class AdobeSyncFailuresTab extends NavigationMixin(LightningElement) {
    @track failures = [];
    @track filteredFailures = [];
    @track isLoading = false;
    @track selectedRows = [];
    @track groupBy = 'type'; // Options: 'type', 'status', 'onboarding'
    @track filters = {
        type: null,
        status: null,
        dateRange: 'LAST_24_HOURS'
    };

    columns = [
        { label: 'Failure Type', fieldName: 'failureType', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'status', type: 'text', sortable: true },
        { label: 'Onboarding', fieldName: 'onboardingName', type: 'text' },
        { label: 'Account', fieldName: 'accountName', type: 'text' },
        { label: 'Error Message', fieldName: 'errorMessage', type: 'text', wrapText: true },
        { label: 'Retry Count', fieldName: 'retryCount', type: 'number' },
        { label: 'Last Retry', fieldName: 'lastRetryDate', type: 'date', typeAttributes: { 
            year: 'numeric', 
            month: 'short', 
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }},
        { label: 'Created Date', fieldName: 'createdDate', type: 'date', typeAttributes: { 
            year: 'numeric', 
            month: 'short', 
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }},
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Retry Sync', name: 'retry' },
                    { label: 'View Onboarding', name: 'view' },
                    { label: 'Mark Resolved', name: 'resolve' }
                ]
            }
        }
    ];

    @wire(getAdobeSyncFailures, { 
        groupBy: '$groupBy',
        filters: '$filters'
    })
    wiredFailures({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.failures = data;
            this.filteredFailures = data;
        } else if (error) {
            console.error('Error loading Adobe sync failures:', error);
            this.showError('Failed to load Adobe sync failures');
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        switch (actionName) {
            case 'retry':
                this.handleRetry(row);
                break;
            case 'view':
                this.handleView(row);
                break;
            case 'resolve':
                this.handleResolve(row);
                break;
        }
    }

    handleRetry(row) {
        this.isLoading = true;
        retryAdobeSync({ failureId: row.id })
            .then(() => {
                this.showSuccess('Adobe sync retry initiated');
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to retry sync: ' + (error.body?.message || error.message));
                this.isLoading = false;
            });
    }

    handleView(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.onboardingId,
                actionName: 'view'
            }
        });
    }

    handleResolve(row) {
        this.isLoading = true;
        resolveAdobeSyncFailure({ failureId: row.id })
            .then(() => {
                this.showSuccess('Failure marked as resolved');
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to resolve: ' + (error.body?.message || error.message));
                this.isLoading = false;
            });
    }

    handleGroupByChange(event) {
        this.groupBy = event.detail.value;
        this.refreshData();
    }

    handleDateRangeChange(event) {
        this.filters.dateRange = event.detail.value;
        this.refreshData();
    }

    handleStatusChange(event) {
        this.filters.status = event.detail.value;
        this.refreshData();
    }

    handleTypeChange(event) {
        this.filters.type = event.detail.value;
        this.refreshData();
    }

    handleSelectionChange(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleBulkRetry() {
        if (this.selectedRows.length === 0) {
            this.showWarning('Please select at least one failure to retry');
            return;
        }
        
        this.isLoading = true;
        const failureIds = this.selectedRows.map(row => row.id);
        
        Promise.all(failureIds.map(id => retryAdobeSync({ failureId: id })))
            .then(() => {
                this.showSuccess(`Retry initiated for ${failureIds.length} failure(s)`);
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to retry some failures: ' + (error.body?.message || error.message));
                this.isLoading = false;
            });
    }

    handleBulkResolve() {
        if (this.selectedRows.length === 0) {
            this.showWarning('Please select at least one failure to resolve');
            return;
        }
        
        this.isLoading = true;
        const failureIds = this.selectedRows.map(row => row.id);
        
        Promise.all(failureIds.map(id => resolveAdobeSyncFailure({ failureId: id })))
            .then(() => {
                this.showSuccess(`Resolved ${failureIds.length} failure(s)`);
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to resolve some failures: ' + (error.body?.message || error.message));
                this.isLoading = false;
            });
    }

    handleExport() {
        // TODO: Implement CSV export
        this.showInfo('Export functionality to be implemented');
    }

    refreshData() {
        this.isLoading = true;
        // Wire adapter will automatically refresh
    }

    get groupByOptions() {
        return [
            { label: 'By Type', value: 'type' },
            { label: 'By Status', value: 'status' },
            { label: 'By Onboarding', value: 'onboarding' }
        ];
    }

    get dateRangeOptions() {
        return [
            { label: 'Last 24 Hours', value: 'LAST_24_HOURS' },
            { label: 'Last 7 Days', value: 'LAST_7_DAYS' },
            { label: 'Last 30 Days', value: 'LAST_30_DAYS' },
            { label: 'All Time', value: 'ALL_TIME' }
        ];
    }

    get statusOptions() {
        return [
            { label: 'All Statuses', value: null },
            { label: 'Pending', value: 'Pending' },
            { label: 'Retrying', value: 'Retrying' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Failed', value: 'Failed' }
        ];
    }

    get typeOptions() {
        return [
            { label: 'All Types', value: null },
            { label: 'Form Submission', value: 'Form Submission' },
            { label: 'Signature Sync', value: 'Signature Sync' },
            { label: 'Document Generation', value: 'Document Generation' }
        ];
    }

    get hasNoFailures() {
        return !this.isLoading && this.filteredFailures.length === 0;
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning'
        }));
    }

    showInfo(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Info',
            message: message,
            variant: 'info'
        }));
    }
}

