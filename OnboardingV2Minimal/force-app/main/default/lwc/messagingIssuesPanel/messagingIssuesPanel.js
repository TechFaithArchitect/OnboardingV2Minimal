import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMessagingIssues from '@salesforce/apex/OnboardingAdminDashboardController.getMessagingIssues';
import retryMessaging from '@salesforce/apex/OnboardingAdminDashboardController.retryMessaging';
import dismissMessagingIssue from '@salesforce/apex/OnboardingAdminDashboardController.dismissMessagingIssue';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { 
        label: 'Name', 
        fieldName: 'name',
        type: 'text'
    },
    { label: 'Type', fieldName: 'type' },
    { 
        label: 'Status', 
        fieldName: 'status',
        cellAttributes: { class: { fieldName: 'statusClass' } }
    },
    { 
        label: 'Onboarding', 
        fieldName: 'onboardingName',
        type: 'text'
    },
    { 
        label: 'Account', 
        fieldName: 'accountName',
        type: 'text'
    },
    { label: 'Reason', fieldName: 'triggerReason' },
    { label: 'Attempts', fieldName: 'attemptCount', type: 'number' },
    { 
        label: 'Last Attempt', 
        fieldName: 'lastAttemptDate', 
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    { 
        label: 'Failures', 
        fieldName: 'consecutiveFailures', 
        type: 'number',
        cellAttributes: { class: { fieldName: 'failureClass' } }
    },
    {
        type: 'button',
        typeAttributes: { 
            label: 'Retry', 
            name: 'retry', 
            variant: 'brand',
            disabled: { fieldName: 'retryDisabled' }
        }
    },
    {
        type: 'button',
        typeAttributes: { 
            label: 'Dismiss', 
            name: 'dismiss', 
            variant: 'neutral',
            disabled: { fieldName: 'dismissDisabled' }
        }
    },
    {
        type: 'button',
        typeAttributes: { 
            label: 'Details', 
            name: 'details', 
            variant: 'base'
        }
    }
];

export default class MessagingIssuesPanel extends NavigationMixin(LightningElement) {
    @track issues = [];
    @track dateRange = 'LAST_7_DAYS';
    @track status = '';
    @track type = '';
    @track isLoading = false;
    @track processingIds = new Set();
    @track currentPage = 1;
    @track pageSize = 25;
    @track selectedIssue = null;
    @track showDetailDrawer = false;

    columns = columns;

    dateRangeOptions = [
        { label: 'Last 24 Hours', value: 'LAST_24_HOURS' },
        { label: 'Last 7 Days', value: 'LAST_7_DAYS' },
        { label: 'Last 30 Days', value: 'LAST_30_DAYS' },
        { label: 'All Time', value: 'ALL_TIME' }
    ];

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'Failed', value: 'Failed' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Pending Retry', value: 'Pending Retry' },
        { label: 'Resolved', value: 'Resolved' }
    ];

    typeOptions = [
        { label: 'All', value: '' },
        { label: 'Email', value: 'Email' },
        { label: 'SMS', value: 'SMS' },
        { label: 'In-App', value: 'In-App' },
        { label: 'Phone', value: 'Phone' }
    ];

    connectedCallback() {
        this.loadData();
    }

    get hasIssues() {
        return this.issues && this.issues.length > 0;
    }

    get paginatedIssues() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.processedIssues.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.processedIssues.length / this.pageSize);
    }

    get showPagination() {
        return this.processedIssues.length > this.pageSize;
    }

    get pageInfo() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.processedIssues.length);
        return `Showing ${start}-${end} of ${this.processedIssues.length}`;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get processedIssues() {
        if (!this.issues || this.issues.length === 0) {
            return [];
        }

        return this.issues.map(issue => {
            const processed = { ...issue };
            
            // Add status class
            if (processed.status === 'Failed') {
                processed.statusClass = 'slds-text-color_error';
            } else if (processed.status === 'Pending Retry') {
                processed.statusClass = 'slds-text-color_warning';
            } else if (processed.status === 'Resolved') {
                processed.statusClass = 'slds-text-color_success';
            } else {
                processed.statusClass = '';
            }

            // Add failure class
            if (processed.consecutiveFailures > 3) {
                processed.failureClass = 'slds-text-color_error';
            } else if (processed.consecutiveFailures > 1) {
                processed.failureClass = 'slds-text-color_warning';
            } else {
                processed.failureClass = '';
            }

            // Store IDs for navigation (URLs will be handled in row actions)
            // Keep original labels for display

            // Disable actions during async operations
            processed.retryDisabled = this.processingIds.has(processed.id);
            processed.dismissDisabled = this.processingIds.has(processed.id);

            return processed;
        });
    }


    async loadData() {
        this.isLoading = true;
        try {
            const filters = {
                dateRange: this.dateRange,
                status: this.status || null,
                type: this.type || null
            };
            this.issues = await getMessagingIssues({ groupBy: null, filters });
            this.currentPage = 1; // Reset to first page on new load
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
            this.issues = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleDateRangeChange(event) {
        this.dateRange = event.detail.value;
        this.loadData();
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
        this.loadData();
    }

    handleTypeChange(event) {
        this.type = event.detail.value;
        this.loadData();
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        if (actionName === 'retry') {
            await this.retry(row.id);
        } else if (actionName === 'dismiss') {
            await this.dismiss(row.id);
        } else if (actionName === 'details') {
            this.showDetails(row);
        }
    }

    handleNameClick(event) {
        const rowId = event.target.closest('tr').dataset.rowKeyValue;
        const issue = this.issues.find(i => i.id === rowId);
        if (issue && issue.id) {
            this.navigateToRecord(issue.id);
        }
    }

    handleOnboardingClick(event) {
        const rowId = event.target.closest('tr').dataset.rowKeyValue;
        const issue = this.issues.find(i => i.id === rowId);
        if (issue && issue.onboardingId) {
            this.navigateToRecord(issue.onboardingId);
        }
    }

    handleAccountClick(event) {
        const rowId = event.target.closest('tr').dataset.rowKeyValue;
        const issue = this.issues.find(i => i.id === rowId);
        if (issue && issue.accountId) {
            this.navigateToRecord(issue.accountId);
        }
    }

    showDetails(issue) {
        this.selectedIssue = issue;
        this.showDetailDrawer = true;
    }

    closeDetailDrawer() {
        this.showDetailDrawer = false;
        this.selectedIssue = null;
    }

    navigateToRecord(recordId) {
        if (!recordId) return;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    async retry(id) {
        if (this.processingIds.has(id)) {
            return; // Already processing
        }

        this.processingIds.add(id);
        try {
            await retryMessaging({ issueId: id });
            this.showToast('Success', 'Retry initiated', 'success');
            await this.loadData();
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        } finally {
            this.processingIds.delete(id);
        }
    }

    async dismiss(id) {
        if (this.processingIds.has(id)) {
            return; // Already processing
        }

        this.processingIds.add(id);
        try {
            await dismissMessagingIssue({ issueId: id });
            this.showToast('Success', 'Issue dismissed', 'success');
            await this.loadData();
        } catch (err) {
            this.showToast('Error', this.formatError(err), 'error');
        } finally {
            this.processingIds.delete(id);
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
