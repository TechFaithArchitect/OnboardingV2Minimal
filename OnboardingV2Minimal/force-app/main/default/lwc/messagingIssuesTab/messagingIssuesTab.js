import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMessagingIssues from '@salesforce/apex/OnboardingAdminDashboardController.getMessagingIssues';
import retryMessaging from '@salesforce/apex/OnboardingAdminDashboardController.retryMessaging';
import dismissMessagingIssue from '@salesforce/apex/OnboardingAdminDashboardController.dismissMessagingIssue';

export default class MessagingIssuesTab extends NavigationMixin(LightningElement) {
    @track issues = [];
    @track filteredIssues = [];
    @track isLoading = false;
    @track selectedRows = [];
    @track groupBy = 'type'; // Options: 'type', 'status', 'onboarding'
    @track filters = {
        type: null,
        status: null,
        dateRange: 'LAST_24_HOURS'
    };

    columns = [
        { label: 'Follow-Up Type', fieldName: 'followUpType', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'status', type: 'text', sortable: true },
        { label: 'Onboarding', fieldName: 'onboardingName', type: 'text' },
        { label: 'Account', fieldName: 'accountName', type: 'text' },
        { label: 'Error Message', fieldName: 'errorMessage', type: 'text', wrapText: true },
        { label: 'Attempt Count', fieldName: 'attemptCount', type: 'number' },
        { label: 'Last Attempt', fieldName: 'lastAttemptDate', type: 'date', typeAttributes: { 
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
                    { label: 'Retry', name: 'retry' },
                    { label: 'View Onboarding', name: 'view' },
                    { label: 'Dismiss', name: 'dismiss' }
                ]
            }
        }
    ];

    @wire(getMessagingIssues, { 
        groupBy: '$groupBy',
        filters: '$filters'
    })
    wiredIssues({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.issues = data;
            this.filteredIssues = data;
        } else if (error) {
            console.error('Error loading messaging issues:', error);
            this.showError('Failed to load messaging issues');
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
            case 'dismiss':
                this.handleDismiss(row);
                break;
        }
    }

    handleRetry(row) {
        this.isLoading = true;
        retryMessaging({ issueId: row.id })
            .then(() => {
                this.showSuccess('Messaging retry initiated');
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to retry messaging: ' + (error.body?.message || error.message));
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

    handleDismiss(row) {
        this.isLoading = true;
        dismissMessagingIssue({ issueId: row.id })
            .then(() => {
                this.showSuccess('Issue dismissed');
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to dismiss issue: ' + (error.body?.message || error.message));
                this.isLoading = false;
            });
    }

    handleGroupByChange(event) {
        this.groupBy = event.detail.value;
        this.refreshData();
    }

    handleFilterChange(event) {
        const filterName = event.detail.name;
        const filterValue = event.detail.value;
        this.filters[filterName] = filterValue;
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
            this.showWarning('Please select at least one issue to retry');
            return;
        }
        
        this.isLoading = true;
        const issueIds = this.selectedRows.map(row => row.id);
        
        // Retry each issue sequentially
        Promise.all(issueIds.map(id => retryMessaging({ issueId: id })))
            .then(() => {
                this.showSuccess(`Retry initiated for ${issueIds.length} issue(s)`);
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to retry some issues: ' + (error.body?.message || error.message));
                this.isLoading = false;
            });
    }

    handleBulkDismiss() {
        if (this.selectedRows.length === 0) {
            this.showWarning('Please select at least one issue to dismiss');
            return;
        }
        
        this.isLoading = true;
        const issueIds = this.selectedRows.map(row => row.id);
        
        Promise.all(issueIds.map(id => dismissMessagingIssue({ issueId: id })))
            .then(() => {
                this.showSuccess(`Dismissed ${issueIds.length} issue(s)`);
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to dismiss some issues: ' + (error.body?.message || error.message));
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
            { label: 'Failed', value: 'Failed' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Pending Retry', value: 'Pending Retry' }
        ];
    }

    get typeOptions() {
        return [
            { label: 'All Types', value: null },
            { label: 'SMS', value: 'SMS' },
            { label: 'Email', value: 'Email' },
            { label: 'In-App', value: 'In-App' }
        ];
    }

    get hasNoIssues() {
        return !this.isLoading && this.filteredIssues.length === 0;
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

