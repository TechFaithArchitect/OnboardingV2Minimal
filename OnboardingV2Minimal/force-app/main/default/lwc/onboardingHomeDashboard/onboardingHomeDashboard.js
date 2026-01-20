import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { extractErrorMessage } from 'c/utils';
import hasAdminPermission from '@salesforce/customPermission/OnboardingAppAdmin';
import getMyActiveOnboarding from '@salesforce/apex/OnboardingHomeDashboardController.getMyActiveOnboarding';
import getOnboardingSummary from '@salesforce/apex/OnboardingHomeDashboardController.getOnboardingSummary';
import getEligibleAccounts from '@salesforce/apex/OnboardingHomeDashboardController.getEligibleAccounts';
import getRecentActivity from '@salesforce/apex/OnboardingHomeDashboardController.getRecentActivity';
import getVendorProgramMetrics from '@salesforce/apex/OnboardingHomeDashboardController.getVendorProgramMetrics';
import getBlockedOnboardingCount from '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingCount';
import getTeamOnboarding from '@salesforce/apex/OnboardingHomeDashboardController.getTeamOnboarding';
import syncComponentLibrary from '@salesforce/apex/VendorOnboardingWizardController.syncComponentLibrary';
import initializeDefaultProcess from '@salesforce/apex/VendorOnboardingWizardController.initializeDefaultProcess';

export default class OnboardingHomeDashboard extends NavigationMixin(LightningElement) {
    // Filter state
    @track filters = {
        timeRange: 'LAST_90_DAYS',
        vendors: [],
        programs: [],
        view: 'MY_VIEW'
    };

    // Tab state
    @track activeTab = 'my-onboarding';

    // Data state
    @track activeOnboarding = [];
    @track eligibleAccounts = [];
    @track recentActivity = [];
    @track summary = {};
    @track vendorSummary = {};
    @track vendorPrograms = [];
    @track vendorProgramMetrics = [];
    @track blockedCount = 0;
    @track teamQueue = [];
    
    // Always show blocking indicators in work queues
    showBlockingIndicators = true;
    
    @track isLoading = true;
    @track showStartModal = false;
    
    // Vendor Program Wizard Modal (selection & kickoff)
    @track showVendorProgramModal = false;
    @track isSyncingComponentLibrary = false;

    // Wizard Modal
    @track showWizardModal = false;
    @track wizardVendorProgramId = null;
    @track isInitializingProcess = false;
    
    // Prevent duplicate actions for async admin actions
    @track isProceedingWithVendor = false;
    @track isProceedingWithVendorProgram = false;

    // Column definitions for active onboarding table
    activeOnboardingColumns = [
        { label: 'Account', fieldName: 'AccountName', type: 'text' },
        { label: 'Vendor Program', fieldName: 'VendorProgramName', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Last Modified', fieldName: 'LastModifiedDate', type: 'date',
          typeAttributes: { 
              year: 'numeric',
              month: 'short', 
              day: '2-digit',
              hour: '2-digit',
              minute: '2-digit'
          }
        },
        { label: 'Created By', fieldName: 'CreatedByName', type: 'text' },
        { 
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Resume', name: 'resume' }
                ]
            }
        }
    ];

    // Column definitions for eligible accounts table
    eligibleAccountsColumns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Territory', fieldName: 'Territory', type: 'text' },
        { label: 'Region', fieldName: 'Region', type: 'text' },
        { label: 'Eligible Vendors', fieldName: 'EligibleVendorCount', type: 'number' },
        { 
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Start Onboarding', name: 'start' },
                    { label: 'View Account', name: 'view' }
                ]
            }
        }
    ];

    // Computed properties for wire parameters
    // These need to return undefined (not null) for @wire to work correctly with optional parameters
    get timeFilterParam() {
        return this.filters && this.filters.timeRange ? this.filters.timeRange : 'LAST_90_DAYS';
    }

    get vendorFilterParam() {
        if (!this.filters || !this.filters.vendors || this.filters.vendors.length === 0) {
            return null;
        }
        return this.filters.vendors;
    }

    get programFilterParam() {
        if (!this.filters || !this.filters.programs || this.filters.programs.length === 0) {
            return null;
        }
        return this.filters.programs;
    }

    get viewFilterParam() {
        return this.filters && this.filters.view ? this.filters.view : 'MY_VIEW';
    }

    @wire(getMyActiveOnboarding, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam',
        viewFilter: '$viewFilterParam'
    })
    wiredActiveOnboarding({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.activeOnboarding = (data || []).map(ob => ({
                ...ob,
                LastModifiedDate: ob.LastModifiedDate ? new Date(ob.LastModifiedDate) : null
            }));
            this.isLoading = false;
        } else if (error) {
            // Only show error if there's an actual server error, not just empty results
            this.showToast('Error', 'Failed to load active onboarding records.', 'error');
            this.isLoading = false;
        }
    }

    @wire(getOnboardingSummary, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam',
        viewFilter: '$viewFilterParam'
    })
    wiredSummary({ error, data }) {
        if (data) {
            this.summary = data;
        } else if (error) {
            // Silently fail - summary is not critical
        }
    }

    @wire(getEligibleAccounts, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredEligibleAccounts({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.eligibleAccounts = data || [];
        } else if (error) {
            // Only show error if there's an actual server error, not just empty results
            this.showToast('Error', 'Failed to load eligible accounts.', 'error');
        }
    }

    @wire(getRecentActivity, {
        recordLimit: 10,
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredRecentActivity({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.recentActivity = (data || []).map(ob => ({
                ...ob,
                LastModifiedDate: ob.LastModifiedDate ? new Date(ob.LastModifiedDate) : null
            }));
        } else if (error) {
            // Silently fail - recent activity is not critical
        }
    }

    @wire(getVendorProgramMetrics, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam'
    })
    wiredVendorProgramMetrics({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            const programs = data || [];
            this.vendorPrograms = programs;
            // Build vendor summary
            this.vendorSummary = {
                Active: programs.filter(p => p.Active && p.Status === 'Active').length,
                Draft: programs.filter(p => p.Status === 'Draft').length,
                Total: programs.length
            };
        } else if (error) {
            console.error('Error loading vendor program metrics:', error);
        }
    }

    @wire(getBlockedOnboardingCount, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredBlockedCount({ error, data }) {
        if (data !== undefined) {
            this.blockedCount = data;
        } else if (error) {
            console.error('Error loading blocked count:', error);
        }
    }

    @wire(getTeamOnboarding, {
        viewFilter: '$viewFilterParam',
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredTeamQueue({ error, data }) {
        if (data !== undefined) {
            // data can be an empty array, which is a valid successful response
            this.teamQueue = (data || []).map(ob => ({
                ...ob,
                LastModifiedDate: ob.LastModifiedDate ? new Date(ob.LastModifiedDate) : null
            }));
        } else if (error) {
            console.error('Error loading team queue:', error);
        }
    }

    async runWithGuard(flagPropertyName, asyncCallback) {
        if (this[flagPropertyName]) {
            return;
        }
        try {
            this[flagPropertyName] = true;
            await asyncCallback();
        } finally {
            this[flagPropertyName] = false;
        }
    }

    // Getters for summary cards (kept for backward compatibility if needed)
    get notStartedCount() {
        return this.summary['Not Started'] || 0;
    }

    get inProcessCount() {
        return this.summary['In Process'] || 0;
    }

    get pendingReviewCount() {
        return this.summary['Pending Initial Review'] || 0;
    }

    get completeCount() {
        return this.summary['Complete'] || this.summary['Setup Complete'] || 0;
    }

    get totalCount() {
        return this.summary['Total'] || 0;
    }

    get eligibleAccountsCount() {
        return this.eligibleAccounts.length;
    }

    get onboardingSummary() {
        return this.summary;
    }

    // Filter change handler
    handleFilterChange(event) {
        const { filterType, value } = event.detail;
        
        // Convert single values to arrays for vendor/program filters
        if (filterType === 'vendors' || filterType === 'programs') {
            this.filters[filterType] = value && value.length > 0 ? value : [];
        } else {
            this.filters[filterType] = value;
        }
        
        // Wire methods will automatically refresh when reactive parameters change
    }

    // Tab change handler
    handleTabChange(event) {
        this.activeTab = event.detail.value;
    }

    // KPI tile click handler
    handleKpiTileClick(event) {
        const { metricKey } = event.detail;
        if (metricKey === 'blocked') {
            this.activeTab = 'my-onboarding';
            // Could set a local flag to highlight blocked rows only
        } else if (metricKey === 'activeOnboarding') {
            this.activeTab = 'my-onboarding';
        } else if (metricKey === 'completed') {
            this.activeTab = 'my-onboarding';
        } else if (metricKey === 'activePrograms') {
            this.activeTab = 'programs';
        } else if (metricKey === 'dealersOnboarded') {
            this.activeTab = 'eligible';
        }
    }

    // Component event handlers
    handleViewOnboarding(event) {
        const recordId = event.detail.recordId;
        this.navigateToRecord(recordId);
    }

    handleResumeOnboarding(event) {
        const recordId = event.detail.recordId;
        this.navigateToRecord(recordId);
        // In future, you can pass state to focus on the flow/requirements panel
    }

    handleViewRequirements(event) {
        const recordId = event.detail.recordId;
        // Navigate to onboarding record anchored to requirements panel
        this.navigateToRecord(recordId);
    }

    handleViewProgram(event) {
        const programId = event.detail.programId;
        this.navigateToRecord(programId);
    }

    handleLaunchWizard(event) {
        const programId = event.detail.programId;
        this.wizardVendorProgramId = programId;
        this.showWizardModal = true;
    }

    // Role-based visibility
    get showTeamTab() {
        return this.filters.view === 'MY_TEAM' || this.filters.view === 'ORG_WIDE';
    }

    get showTeamView() {
        // Check if user has permission to see team/org view
        // For now, return true - can be enhanced with permission checks
        return true;
    }

    get hasInsightsComponent() {
        // Insights component is now available
        return true;
    }

    get showAdminSection() {
        return hasAdminPermission === true;
    }

    // Handle row actions for active onboarding table
    handleActiveOnboardingRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view') {
            this.navigateToRecord(row.Id);
        } else if (action.name === 'resume') {
            this.navigateToRecord(row.Id);
        }
    }

    // Handle row actions for eligible accounts table
    handleEligibleAccountsRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'start') {
            this.startOnboardingForAccount(row.Id);
        } else if (action.name === 'view') {
            this.navigateToRecord(row.Id);
        }
    }

    // Navigate to a record
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // Start onboarding for an account
    startOnboardingForAccount(accountId) {
        // Navigate to account record page with quick action
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                actionName: 'view'
            },
            state: {
                actionName: 'Vendor_Onboarding'
            }
        });
    }

    // Handle start dealer onboarding button
    handleStartDealerOnboarding() {
        this.showStartModal = true;
    }

    // Handle start vendor program onboarding button
    handleStartVendorProgramOnboarding() {
        // Open the selection wizard modal; the child component will handle flow kickoff
        this.showVendorProgramModal = true;
    }

    // Close vendor program selection wizard
    handleVendorProgramModalClose() {
        this.showVendorProgramModal = false;
    }

    // Handle events from vendor program selection wizard to launch the main onboarding wizard
    handleVendorProgramWizardLaunch(event) {
        const vendorProgramId = event.detail && event.detail.vendorProgramId;
        if (!vendorProgramId) {
            return;
        }
        this.wizardVendorProgramId = vendorProgramId;
        this.showWizardModal = true;
    }

    // Open wizard in modal (screenflow-like experience)
    openWizardModal(vendorProgramId) {
        this.wizardVendorProgramId = vendorProgramId;
        this.showWizardModal = true;
    }

    // Close wizard modal
    handleCloseWizardModal() {
        this.showWizardModal = false;
        this.wizardVendorProgramId = null;
        // Refresh dashboard to show updated data
        this.handleRefresh();
    }

    // Handle wizard completion
    handleWizardComplete(event) {
        const vendorProgramId = event.detail?.vendorProgramId;
        // Final step of the wizard already shows a success toast and navigates
        // to the Vendor Program record. Here we just close the modal and refresh
        // the dashboard so it reflects any new/updated vendor program data.
        this.handleCloseWizardModal();
    }

    // Navigate to vendor program record page (fallback/alternative)
    navigateToVendorProgram(vendorProgramId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: vendorProgramId,
                actionName: 'view'
            },
            state: {
                c__vendorProgramId: vendorProgramId,
                c__startWizard: 'true'
            }
        });
    }

    // Dealer onboarding modal events
    handleDealerOnboardingStart(event) {
        const accountId = event.detail && event.detail.accountId;
        if (accountId) {
            this.startOnboardingForAccount(accountId);
        }
        this.showStartModal = false;
    }

    handleDealerOnboardingClose() {
        this.showStartModal = false;
    }

    // Show toast message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Refresh data
    handleRefresh() {
        // Force refresh by updating tracked properties
        this.isLoading = true;
        // The @wire will automatically refresh when dependencies change
        // For now, just set loading state
        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }

    // Sync Component Library
    async handleSyncComponentLibrary() {
        await this.runWithGuard('isSyncingComponentLibrary', async () => {
            try {
                const message = await syncComponentLibrary();
                this.showToast('Success', message, 'success');
            } catch (error) {
                this.showToast('Error', extractErrorMessage(error, 'Failed to sync Component Library.'), 'error');
            }
        });
    }

    // Initialize default Vendor Program Onboarding process
    async handleInitializeDefaultProcess() {
        await this.runWithGuard('isInitializingProcess', async () => {
            try {
                const message = await initializeDefaultProcess();
                this.showToast('Success', message, 'success');
                // Refresh the page after a short delay to ensure process is available
                setTimeout(() => {
                    this.handleRefresh();
                }, 1000);
            } catch (error) {
                this.showToast('Error', extractErrorMessage(error, 'Failed to initialize default process.'), 'error');
            }
        });
    }
}
