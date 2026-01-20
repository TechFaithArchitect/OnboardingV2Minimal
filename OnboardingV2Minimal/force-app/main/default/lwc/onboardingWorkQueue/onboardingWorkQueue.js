import { LightningElement, api, track } from 'lwc';

export default class OnboardingWorkQueue extends LightningElement {
    @api records = [];
    @api showBlockingIndicators = false;
    @api columns;
    
    @track filteredRecords = [];
    @track statusFilter = '';
    @track blockedFilter = '';
    @track ageFilter = '';
    @track sortBy = 'LastModifiedDate';
    @track sortDirection = 'desc';
    @track currentPage = 1;
    @track pageSize = 25;
    @track isLoading = false;

    defaultColumns = [
        { label: 'Account', fieldName: 'AccountName', type: 'text', sortable: true },
        { label: 'Vendor Program', fieldName: 'VendorProgramName', type: 'text', sortable: true },
        { 
            label: 'Status', 
            fieldName: 'Status', 
            type: 'text',
            sortable: true,
            cellAttributes: { class: { fieldName: 'statusClass' } }
        },
        { 
            label: 'Age (Days)', 
            fieldName: 'AgeInDays', 
            type: 'number',
            sortable: true,
            cellAttributes: { class: { fieldName: 'ageClass' } }
        },
        { 
            label: 'Last Modified', 
            fieldName: 'LastModifiedDate', 
            type: 'date',
            sortable: true,
            typeAttributes: { 
                year: 'numeric',
                month: 'short', 
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            }
        },
        { 
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Resume', name: 'resume' },
                    { label: 'Requirements', name: 'viewrequirements' }
                ]
            }
        }
    ];

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Blocked', value: 'Blocked' },
        { label: 'At Risk', value: 'At Risk' },
        { label: 'Completed', value: 'Completed' }
    ];

    blockedOptions = [
        { label: 'All', value: '' },
        { label: 'Blocked Only', value: 'blocked' },
        { label: 'Not Blocked', value: 'not-blocked' }
    ];

    ageOptions = [
        { label: 'All', value: '' },
        { label: 'Last 7 Days', value: '0-7' },
        { label: '8-14 Days', value: '8-14' },
        { label: '15-30 Days', value: '15-30' },
        { label: 'Over 30 Days', value: '30+' }
    ];

    connectedCallback() {
        this.applyFilters();
    }

    get tableColumns() {
        return this.columns || this.defaultColumns;
    }

    get processedRecords() {
        return this.filteredRecords;
    }

    get paginatedRecords() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.filteredRecords.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.filteredRecords.length / this.pageSize);
    }

    get hasRecords() {
        return this.records && this.records.length > 0;
    }

    get hasFilteredRecords() {
        return this.filteredRecords && this.filteredRecords.length > 0;
    }

    get showPagination() {
        return this.filteredRecords.length > this.pageSize;
    }

    get pageInfo() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.filteredRecords.length);
        return `Showing ${start}-${end} of ${this.filteredRecords.length}`;
    }

    get legendItems() {
        if (!this.showBlockingIndicators) return [];
        return [
            { label: 'Blocked', class: 'blocked-badge', color: 'error' },
            { label: 'At Risk', class: 'at-risk-badge', color: 'warning' },
            { label: 'Normal', class: 'normal-badge', color: 'success' }
        ];
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    handleStatusFilterChange(event) {
        this.statusFilter = event.detail.value;
        this.currentPage = 1;
        this.applyFilters();
    }

    handleBlockedFilterChange(event) {
        this.blockedFilter = event.detail.value;
        this.currentPage = 1;
        this.applyFilters();
    }

    handleAgeFilterChange(event) {
        this.ageFilter = event.detail.value;
        this.currentPage = 1;
        this.applyFilters();
    }

    handleSort(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.applyFilters();
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

    applyFilters() {
        if (!this.records || this.records.length === 0) {
            this.filteredRecords = [];
            return;
        }

        let filtered = this.records.map(onboardingRecord => {
            const processed = { ...onboardingRecord };
            
            // Calculate age if not present
            if (!processed.AgeInDays && processed.CreatedDate) {
                const createdDate = new Date(processed.CreatedDate);
                const today = new Date();
                processed.AgeInDays = Math.floor((today - createdDate) / (1000 * 60 * 60 * 24));
            }

            // Add status class
            if (processed.Status === 'Blocked') {
                processed.statusClass = 'slds-text-color_error';
            } else if (processed.Status === 'At Risk') {
                processed.statusClass = 'slds-text-color_warning';
            } else {
                processed.statusClass = '';
            }

            // Add age class
            if (processed.AgeInDays > 14) {
                processed.ageClass = 'slds-text-color_error';
            } else if (processed.AgeInDays > 7) {
                processed.ageClass = 'slds-text-color_warning';
            } else {
                processed.ageClass = '';
            }

            // Add row class for blocking indicators
            if (this.showBlockingIndicators) {
                if (processed.IsBlocked) {
                    processed.rowClass = 'blocked-row';
                } else if (processed.IsAtRisk) {
                    processed.rowClass = 'at-risk-row';
                } else {
                    processed.rowClass = 'normal-row';
                }
            } else {
                processed.rowClass = 'normal-row';
            }

            return processed;
        });

        // Apply status filter
        if (this.statusFilter) {
            filtered = filtered.filter(onboardingRecord => onboardingRecord.Status === this.statusFilter);
        }

        // Apply blocked filter
        if (this.blockedFilter === 'blocked') {
            filtered = filtered.filter(onboardingRecord => onboardingRecord.IsBlocked === true);
        } else if (this.blockedFilter === 'not-blocked') {
            filtered = filtered.filter(onboardingRecord => !onboardingRecord.IsBlocked);
        }

        // Apply age filter
        if (this.ageFilter) {
            if (this.ageFilter === '0-7') {
                filtered = filtered.filter(onboardingRecord => onboardingRecord.AgeInDays >= 0 && onboardingRecord.AgeInDays <= 7);
            } else if (this.ageFilter === '8-14') {
                filtered = filtered.filter(onboardingRecord => onboardingRecord.AgeInDays >= 8 && onboardingRecord.AgeInDays <= 14);
            } else if (this.ageFilter === '15-30') {
                filtered = filtered.filter(onboardingRecord => onboardingRecord.AgeInDays >= 15 && onboardingRecord.AgeInDays <= 30);
            } else if (this.ageFilter === '30+') {
                filtered = filtered.filter(onboardingRecord => onboardingRecord.AgeInDays > 30);
            }
        }

        // Apply sorting
        filtered.sort((a, b) => {
            let aValue = a[this.sortBy];
            let bValue = b[this.sortBy];
            
            if (aValue == null) aValue = '';
            if (bValue == null) bValue = '';
            
            if (this.sortDirection === 'asc') {
                return aValue > bValue ? 1 : -1;
            } else {
                return aValue < bValue ? 1 : -1;
            }
        });

        this.filteredRecords = filtered;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        const eventName = action.name === 'view' ? 'view' : 
                         action.name === 'resume' ? 'resume' : 
                         'viewrequirements';
        
        this.dispatchEvent(
            new CustomEvent(eventName, {
                detail: {
                    recordId: row.Id,
                    record: row
                },
                bubbles: true,
                composed: true
            })
        );
    }
}

