import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getValidationFailures from '@salesforce/apex/OnboardingAdminDashboardController.getValidationFailures';
import retryValidation from '@salesforce/apex/OnboardingAdminDashboardController.retryValidation';

export default class ValidationFailuresTab extends NavigationMixin(LightningElement) {
    @track failures = [];
    @track filteredFailures = [];
    @track isLoading = false;
    @track selectedRows = [];
    @track groupBy = 'rule'; // Options: 'rule', 'user', 'requirement'
    @track filters = {
        rule: null,
        user: null,
        dateRange: 'LAST_24_HOURS'
    };
    wiredFailuresResult;

    columns = [
        { label: 'Rule Name', fieldName: 'ruleName', type: 'text', sortable: true },
        { label: 'Requirement Field', fieldName: 'requirementFieldName', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text', sortable: true },
        { label: 'Error Message', fieldName: 'errorMessage', type: 'text', wrapText: true },
        { label: 'Created Date', fieldName: 'createdDate', type: 'date', typeAttributes: { 
            year: 'numeric', 
            month: 'short', 
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }},
        { label: 'Retry Count', fieldName: 'retryCount', type: 'number' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Retry Validation', name: 'retry' },
                    { label: 'View Details', name: 'view' },
                    { label: 'Dismiss', name: 'dismiss' }
                ]
            }
        }
    ];

    @wire(getValidationFailures, { 
        groupBy: '$groupBy',
        filters: '$filters'
    })
    wiredFailures({ error, data }) {
        this.wiredFailuresResult = { error, data };
        this.isLoading = false;
        if (data) {
            this.failures = data;
            this.filteredFailures = data;
        } else if (error) {
            console.error('Error loading validation failures:', error);
            this.showError('Failed to load validation failures');
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
        retryValidation({ failureId: row.id })
            .then(() => {
                this.showSuccess('Validation retry initiated');
                // Refresh data
                this.refreshData();
            })
            .catch(error => {
                this.showError('Failed to retry validation: ' + error.body.message);
                this.isLoading = false;
            });
    }

    handleView(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.id,
                actionName: 'view'
            }
        });
    }

    get groupByOptions() {
        return [
            { label: 'By Rule', value: 'rule' },
            { label: 'By User', value: 'user' },
            { label: 'By Requirement', value: 'requirement' }
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

    get hasNoFailures() {
        return !this.isLoading && this.filteredFailures.length === 0;
    }

    handleDateRangeChange(event) {
        this.filters.dateRange = event.detail.value;
        this.refreshData();
    }

    handleDismiss(row) {
        if (!row || !row.id) {
            this.showWarning('Unable to dismiss: missing record id');
            return;
        }

        this.failures = this.failures.filter(item => item.id !== row.id);
        this.filteredFailures = this.filteredFailures.filter(item => item.id !== row.id);
        this.selectedRows = this.selectedRows.filter(item => item.id !== row.id);
        this.showSuccess('Validation failure dismissed from view');
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
        
        Promise.all(failureIds.map(id => retryValidation({ failureId: id })))
            .then(() => {
                this.showSuccess('Bulk retry initiated');
                return this.refreshData();
            })
            .catch(error => {
                const message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
                this.showError('Failed to retry validations: ' + message);
                this.isLoading = false;
            });
    }

    handleExport() {
        if (!this.filteredFailures || this.filteredFailures.length === 0) {
            this.showWarning('No records to export');
            return;
        }

        const csv = this.buildCsv(this.filteredFailures);
        this.downloadCsv(csv, 'validation-failures.csv');
        this.showSuccess('Export started');
    }

    refreshData() {
        this.isLoading = true;
        if (this.wiredFailuresResult) {
            return refreshApex(this.wiredFailuresResult).finally(() => {
                this.isLoading = false;
            });
        }
        this.isLoading = false;
        return Promise.resolve();
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

    buildCsv(rows) {
        const headers = ['Rule Name', 'Requirement Field', 'Status', 'Error Message', 'Created Date', 'Retry Count'];
        const keys = ['ruleName', 'requirementFieldName', 'status', 'errorMessage', 'createdDate', 'retryCount'];

        const csvRows = [];
        csvRows.push(headers.join(','));

        rows.forEach(row => {
            const values = keys.map(key => {
                let val = row[key] === undefined || row[key] === null ? '' : row[key];
                if (val instanceof Date) {
                    val = val.toISOString();
                }
                const stringVal = String(val).replace(/"/g, '""');
                return `"${stringVal}"`;
            });
            csvRows.push(values.join(','));
        });

        return csvRows.join('\n');
    }

    downloadCsv(csvContent, filename) {
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }
}
