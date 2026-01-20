import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProcessIdForVendorProgram from '@salesforce/apex/OnboardingApplicationService.getProcessIdForVendorProgram';
import getVendorsWithPrograms from '@salesforce/apex/OnboardingHomeDashboardController.getVendorsWithPrograms';
import searchVendorsWithPrograms from '@salesforce/apex/OnboardingHomeDashboardController.searchVendorsWithPrograms';
import getDefaultVendorProgramOnboardingProcessId from '@salesforce/apex/OnboardingApplicationService.getDefaultVendorProgramOnboardingProcessId';
import initializeVendorProgramOnboarding from '@salesforce/apex/VendorOnboardingWizardController.initializeVendorProgramOnboarding';
import searchVendors from '@salesforce/apex/VendorOnboardingWizardController.searchVendors';
import createVendor from '@salesforce/apex/VendorOnboardingWizardController.createVendor';
import createVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgram';

export default class VendorProgramOnboardingWizardModal extends LightningElement {
    @api vendorProgramId;
    @api recordId; // Support recordId as well

    @track processId;
    @track error;
    @track isLoading = false;
    @track showWizard = false;
    @track showSelection = true; // Show tree grid selection screen first
    
    // Vendor/Program Selection Tree Grid
    @track vendorHierarchy = [];
    @track vendorSearchText = '';
    @track vendorSearchTimeout;
    @track isVendorHierarchyLoading = false;
    @track expandedVendorRows = [];
    @track isResumingOnboarding = false;

    // Vendor creation (for "Create New" flow)
    @track showVendorCreation = false;
    @track vendors = [];
    @track selectedVendorId = null;
    @track vendorSearchTextForCreate = '';
    @track newVendorName = '';
    @track isVendorSearching = false;
    @track isCreatingVendor = false;

    // Vendor Program creation
    @track showVendorProgramCreation = false;

    // Wizard footer state (from flow engine)
    @track wizardBackDisabled = false;
    @track wizardNextDisabled = true;

    // Column definitions for vendor hierarchy tree grid
    vendorHierarchyColumns = [
        { 
            label: 'Name / Label', 
            fieldName: 'displayName', 
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'rowClass' }
            }
        },
        { 
            label: 'Status', 
            fieldName: 'status', 
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'statusClass' }
            }
        },
        { 
            label: 'Programs', 
            fieldName: 'programCount', 
            type: 'number',
            typeAttributes: {
                minimumFractionDigits: 0
            }
        },
        { 
            label: 'Retail Option', 
            fieldName: 'retailOption', 
            type: 'text'
        },
        { 
            label: 'Business Vertical', 
            fieldName: 'businessVertical', 
            type: 'text'
        },
        { 
            label: 'Last Modified', 
            fieldName: 'lastModifiedDate', 
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
            label: 'Modified By', 
            fieldName: 'lastModifiedBy', 
            type: 'text'
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    connectedCallback() {
        // If vendorProgramId is provided, skip selection and go straight to wizard
        // Otherwise, show the selection tree grid first
        if (this.effectiveVendorProgramId) {
            // Skip selection and initialize wizard directly
            this.showSelection = false;
            this.initializeWizard();
        } else {
            // Show selection screen first
            this.showSelection = true;
            this.showWizard = false;
            this.isLoading = false;
        }
    }

    // Determine which vendor program ID to use
    get effectiveVendorProgramId() {
        return this.vendorProgramId || this.recordId;
    }

    async initializeWizard() {
        if (!this.effectiveVendorProgramId) {
            this.error = 'Vendor Program ID is required';
            this.isLoading = false;
            this.showSelection = true; // Show selection if no ID provided
            return;
        }

        try {
            this.isLoading = true;
            this.error = null;
            this.showSelection = false; // Hide selection when initializing wizard

            // Get the process ID for this vendor program
            this.processId = await getProcessIdForVendorProgram({ 
                vendorProgramId: this.effectiveVendorProgramId 
            });

            if (!this.processId) {
                this.error = 'No onboarding process found for this Vendor Program. Please initialize the default process from the dashboard.';
            } else {
                this.showWizard = true;
                // Update footer state after wizard is shown
                setTimeout(() => {
                    this.updateWizardFooterState();
                }, 300);
            }
        } catch (initializationError) {
            const errorMessage = initializationError.body?.message || initializationError.message || 'Failed to initialize onboarding wizard';
            this.error = errorMessage;
            this.showToast('Error', errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Vendor Hierarchy Tree Grid Methods
    @wire(getVendorsWithPrograms)
    wiredVendorHierarchy({ error: hierarchyWireError, data: hierarchyWireData }) {
        if (hierarchyWireData) {
            this.processVendorHierarchy(hierarchyWireData);
            this.isVendorHierarchyLoading = false;
        } else if (hierarchyWireError) {
            this.showToast('Error', 'Failed to load vendors and programs.', 'error');
            this.isVendorHierarchyLoading = false;
        }
    }

    processVendorHierarchy(data) {
        this.vendorHierarchy = data.map(vendor => {
            const vendorRow = {
                id: vendor.id,
                name: vendor.name,
                displayName: vendor.name, // For vendors, show name
                status: vendor.status,
                programCount: vendor.programCount,
                recordType: vendor.recordType,
                lastModifiedDate: vendor.lastModifiedDate ? new Date(vendor.lastModifiedDate) : null,
                rowClass: 'slds-text-heading_small',
                statusClass: vendor.status === 'Active' ? 'slds-text-color_success' : 'slds-text-color_weak',
                _children: vendor.children ? vendor.children.map(program => ({
                    id: program.id,
                    name: program.name,
                    label: program.label || '',
                    displayName: program.label || program.name, // For programs, show Label (or fallback to name)
                    status: program.status || 'Draft',
                    programCount: null,
                    recordType: program.recordType,
                    retailOption: program.retailOption || '',
                    businessVertical: program.businessVertical || '',
                    lastModifiedDate: program.lastModifiedDate ? new Date(program.lastModifiedDate) : null,
                    lastModifiedBy: program.lastModifiedBy || '',
                    parentId: program.parentId,
                    rowClass: 'slds-text-body_regular',
                    statusClass: this.getStatusClass(program.status),
                    _children: null
                })) : []
            };
            return vendorRow;
        });
    }

    getStatusClass(status) {
        if (!status) return '';
        const statusLower = status.toLowerCase();
        if (statusLower === 'active') return 'slds-text-color_success';
        if (statusLower === 'draft') return 'slds-text-color_weak';
        if (statusLower === 'inactive') return 'slds-text-color_error';
        return '';
    }

    handleVendorSearchChange(event) {
        const searchValue = event.target.value || '';
        this.vendorSearchText = searchValue;

        if (this.vendorSearchTimeout) {
            clearTimeout(this.vendorSearchTimeout);
        }

        if (!searchValue || searchValue.trim().length === 0) {
            // Clear search and reload all vendors
            this.vendorSearchTimeout = setTimeout(() => {
                this.loadVendorHierarchy();
            }, 300);
            return;
        }

        // Debounce search
        this.isVendorHierarchyLoading = true;
        this.vendorSearchTimeout = setTimeout(() => {
            this.searchVendorHierarchy(searchValue.trim());
        }, 500);
    }

    async loadVendorHierarchy() {
        try {
            this.isVendorHierarchyLoading = true;
            const vendorsWithProgramsData = await getVendorsWithPrograms();
            this.processVendorHierarchy(vendorsWithProgramsData);
        } catch (loadError) {
            this.showToast('Error', 'Failed to load vendors and programs.', 'error');
        } finally {
            this.isVendorHierarchyLoading = false;
        }
    }

    async searchVendorHierarchy(searchText) {
        try {
            const searchResultsData = await searchVendorsWithPrograms({ searchText: searchText });
            this.processVendorHierarchy(searchResultsData);
        } catch (searchError) {
            this.showToast('Error', 'Failed to search vendors and programs.', 'error');
        } finally {
            this.isVendorHierarchyLoading = false;
        }
    }

    handleVendorHierarchyRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'edit') {
            // Resume onboarding process from where it was left off
            // Only proceed if it's a program (not a vendor row)
            if (row.recordType === 'program') {
                this.startOnboardingForProgram(row.id);
            } else {
                // If clicked on vendor row, show message
                this.showToast('Info', 'Please select a specific program to continue.', 'info');
            }
        }
    }

    handleCreateNew() {
        // Show vendor creation/selection screen
        this.showVendorCreation = true;
        this.showSelection = false;
    }

    async startOnboardingForProgram(vendorProgramId) {
        try {
            // Show loading state
            this.isResumingOnboarding = true;

            // Get the default process ID
            const defaultProcessId = await getDefaultVendorProgramOnboardingProcessId();
            
            if (!defaultProcessId) {
                this.showToast('Error', 'No onboarding process found. Please initialize the default process first.', 'error');
                this.isResumingOnboarding = false;
                return;
            }

            // Initialize/resume onboarding for this vendor program
            // This will create progress if new, or resume existing progress
            await initializeVendorProgramOnboarding({ 
                vendorProgramId: vendorProgramId,
                processId: defaultProcessId
            });

            // Set the vendor program ID and initialize the wizard
            this.vendorProgramId = vendorProgramId;
            this.showSelection = false;
            this.isResumingOnboarding = false;
            await this.initializeWizard();
            
        } catch (onboardingError) {
            const errorMessage = onboardingError.body?.message || onboardingError.message || 'Unknown error';
            this.showToast('Error', 'Failed to start onboarding. ' + errorMessage, 'error');
            this.isResumingOnboarding = false;
        }
    }

    // Vendor creation methods
    handleBackToSelection() {
        this.showVendorCreation = false;
        this.showVendorProgramCreation = false;
        this.showSelection = true;
        this.selectedVendorId = null;
        this.vendorSearchTextForCreate = '';
        this.newVendorName = '';
    }

    // Vendor search for creation
    @wire(searchVendors, { vendorNameSearchText: '$vendorSearchTextForCreate' })
    wiredVendors({ error: vendorSearchError, data: vendorSearchData }) {
        if (vendorSearchData) {
            this.vendors = vendorSearchData;
            this.isVendorSearching = false;
        } else if (vendorSearchError) {
            this.vendors = [];
            this.isVendorSearching = false;
        }
    }

    handleVendorSearchChangeForCreate(event) {
        const searchValue = event.target.value || '';
        this.vendorSearchTextForCreate = searchValue;

        if (!searchValue || searchValue.trim().length < 2) {
            this.vendors = [];
            this.selectedVendorId = null;
            return;
        }

        this.isVendorSearching = true;
    }

    handleVendorSelectForCreate(event) {
        this.selectedVendorId = event.detail.value;
    }

    handleNewVendorNameChange(event) {
        this.newVendorName = event.target.value;
    }

    async handleCreateVendor() {
        if (!this.newVendorName || this.newVendorName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a vendor name.', 'warning');
            return;
        }

        this.isCreatingVendor = true;
        try {
            const createdVendorId = await createVendor({ vendor: { Name: this.newVendorName.trim() } });
            this.selectedVendorId = createdVendorId;
            this.vendorSearchTextForCreate = '';
            this.newVendorName = '';
            this.showToast('Success', 'Vendor created successfully.', 'success');
        } catch (createError) {
            this.showToast('Error', 'Failed to create vendor. Please try again.', 'error');
        } finally {
            this.isCreatingVendor = false;
        }
    }

    get vendorOptions() {
        return this.vendors.map(v => ({
            label: v.Name,
            value: v.Id
        }));
    }

    get canProceedWithVendor() {
        return !!this.selectedVendorId;
    }

    get cannotProceedWithVendor() {
        return !this.selectedVendorId;
    }

    async handleProceedWithVendor() {
        if (!this.selectedVendorId) {
            this.showToast('Vendor Required', 'Please select or create a vendor to continue.', 'warning');
            return;
        }

        try {
            // Create a new vendor program
            const createdVendorProgramId = await createVendorProgram({
                vendorProgram: { Name: 'New Vendor Program' },
                vendorId: this.selectedVendorId
            });

            // Start onboarding for the new program
            await this.startOnboardingForProgram(createdVendorProgramId);
        } catch (createProgramError) {
            const errorMessage = createProgramError.body?.message || createProgramError.message || 'Unknown error';
            this.showToast('Error', 'Failed to create vendor program. ' + errorMessage, 'error');
        }
    }

    handleClose() {
        // Fire a close event that can be handled by parent
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleWizardComplete() {
        // Handle wizard completion - close modal and refresh parent
        this.dispatchEvent(new CustomEvent('complete', {
            detail: { vendorProgramId: this.effectiveVendorProgramId }
        }));
        this.handleClose();
    }

    // Wizard footer button handlers
    handleWizardBack() {
        const flowEngine = this.template.querySelector('c-onboarding-flow-engine');
        if (flowEngine) {
            flowEngine.handleFooterBack();
        }
    }

    handleWizardNext() {
        const flowEngine = this.template.querySelector('c-onboarding-flow-engine');
        if (flowEngine) {
            flowEngine.handleFooterNext();
        }
    }

    // Listen for footer state changes from flow engine
    renderedCallback() {
        if (this.showWizard) {
            this.updateWizardFooterState();
        }
    }

    handleFooterStateChanged(event) {
        const { backDisabled, nextDisabled } = event.detail || {};
        this.wizardBackDisabled = backDisabled || false;
        this.wizardNextDisabled = nextDisabled !== undefined ? nextDisabled : true;
    }

    updateWizardFooterState() {
        const flowEngine = this.template.querySelector('c-onboarding-flow-engine');
        if (flowEngine) {
            // Get initial footer state from flow engine
            if (flowEngine.footerBackDisabled !== undefined) {
                this.wizardBackDisabled = flowEngine.footerBackDisabled;
            }
            if (flowEngine.footerNextDisabled !== undefined) {
                this.wizardNextDisabled = flowEngine.footerNextDisabled;
            }
        }
    }

    connectedCallback() {
        // If vendorProgramId is provided, skip selection and go straight to wizard
        // Otherwise, show the selection tree grid first
        if (this.effectiveVendorProgramId) {
            // Skip selection and initialize wizard directly
            this.showSelection = false;
            this.initializeWizard();
        } else {
            // Show selection screen first
            this.showSelection = true;
            this.showWizard = false;
            this.isLoading = false;
        }
        
        // Update footer state after wizard loads (with delay to ensure flow engine is rendered)
        setTimeout(() => {
            this.updateWizardFooterState();
        }, 500);
    }

    handleGoToDashboard() {
        // Navigate to dashboard to initialize process
        window.location.href = '/lightning/n/home';
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
