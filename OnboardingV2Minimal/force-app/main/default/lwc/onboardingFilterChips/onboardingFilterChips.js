import { LightningElement, api, wire, track } from 'lwc';
import getVendors from '@salesforce/apex/OnboardingHomeDashboardController.getVendors';
import getVendorPrograms from '@salesforce/apex/OnboardingHomeDashboardController.getVendorPrograms';

export default class OnboardingFilterChips extends LightningElement {
    @api timeFilter = 'LAST_90_DAYS';
    @api vendorFilter = [];
    @api programFilter = [];
    @api viewFilter = 'MY_VIEW';
    @api showTeamView = false;

    @track vendorOptions = [];
    @track programOptions = [];

    timeFilterOptions = [
        { label: 'Last 30 Days', value: 'LAST_30_DAYS' },
        { label: 'Last 90 Days', value: 'LAST_90_DAYS' },
        { label: 'Year to Date', value: 'YEAR_TO_DATE' },
        { label: 'All Time', value: 'ALL_TIME' }
    ];

    viewFilterOptions = [
        { label: 'My View', value: 'MY_VIEW' },
        { label: 'My Team', value: 'MY_TEAM' },
        { label: 'Org Wide', value: 'ORG_WIDE' }
    ];

    @wire(getVendors)
    wiredVendors({ error, data }) {
        if (data) {
            // Add "All" option at the beginning
            this.vendorOptions = [
                { label: 'All Vendors', value: '' },
                ...data.map(v => ({
                    label: v.label || v.Name,
                    value: v.value || v.Id
                }))
            ];
        } else if (error) {
            console.error('Error loading vendors:', error);
            this.vendorOptions = [{ label: 'All Vendors', value: '' }];
        }
    }

    @wire(getVendorPrograms)
    wiredVendorPrograms({ error, data }) {
        if (data) {
            // Add "All" option at the beginning
            this.programOptions = [
                { label: 'All Programs', value: '' },
                ...data.map(p => ({
                    label: p.label || p.Name,
                    value: p.value || p.Id
                }))
            ];
        } else if (error) {
            console.error('Error loading vendor programs:', error);
            this.programOptions = [{ label: 'All Programs', value: '' }];
        }
    }

    handleTimeFilterChange(event) {
        this.timeFilter = event.detail.value;
        this.dispatchFilterChange('timeRange', this.timeFilter);
    }

    handleVendorFilterChange(event) {
        const value = event.detail.value;
        // Store as array for consistency with API, empty string means "All"
        this.vendorFilter = (value && value !== '') ? [value] : [];
        this.dispatchFilterChange('vendors', this.vendorFilter);
    }

    handleProgramFilterChange(event) {
        const value = event.detail.value;
        // Store as array for consistency with API, empty string means "All"
        this.programFilter = (value && value !== '') ? [value] : [];
        this.dispatchFilterChange('programs', this.programFilter);
    }

    handleViewFilterChange(event) {
        this.viewFilter = event.detail.value;
        this.dispatchFilterChange('view', this.viewFilter);
    }

    dispatchFilterChange(filterType, value) {
        this.dispatchEvent(
            new CustomEvent('filterchange', {
                detail: {
                    filterType: filterType,
                    value: value
                },
                bubbles: true,
                composed: true
            })
        );
    }

    get filteredViewOptions() {
        if (this.showTeamView) {
            return this.viewFilterOptions;
        }
        // Only show MY_VIEW if team view is not available
        return [{ label: 'My View', value: 'MY_VIEW' }];
    }

    get selectedVendorValue() {
        return this.vendorFilter && this.vendorFilter.length > 0 ? this.vendorFilter[0] : '';
    }

    get selectedProgramValue() {
        return this.programFilter && this.programFilter.length > 0 ? this.programFilter[0] : '';
    }
}

