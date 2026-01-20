import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { extractErrorMessage } from 'c/utils';

import getVendorsWithPrograms from '@salesforce/apex/OnboardingHomeDashboardController.getVendorsWithPrograms';
import searchVendorsWithPrograms from '@salesforce/apex/OnboardingHomeDashboardController.searchVendorsWithPrograms';
import searchVendors from '@salesforce/apex/VendorOnboardingWizardController.searchVendors';
import createVendor from '@salesforce/apex/VendorOnboardingWizardController.createVendor';
import createVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgram';
import searchVendorPrograms from '@salesforce/apex/VendorOnboardingWizardController.searchVendorPrograms';
import getRecentVendorPrograms from '@salesforce/apex/VendorOnboardingWizardController.getRecentVendorPrograms';
import getDefaultVendorProgramOnboardingProcessId from '@salesforce/apex/OnboardingApplicationService.getDefaultVendorProgramOnboardingProcessId';
import initializeVendorProgramOnboarding from '@salesforce/apex/VendorOnboardingWizardController.initializeVendorProgramOnboarding';

export default class OnboardingVendorProgramWizard extends LightningElement {
    // Wizard step state
    @track vendorProgramModalStep = 'treeGrid'; // 'treeGrid' | 'vendorSelection' | 'vendorProgramSelection'

    // Vendor hierarchy (tree grid)
    @track vendorHierarchy = [];
    vendorSearchTimeout;
    @track isVendorHierarchyLoading = false;
    @track expandedVendorRows = [];
    @track vendorSearchText = '';
    @track isResumingOnboarding = false;

    // Vendor selection
    @track vendors = [];
    @track selectedVendorId = null;
    @track newVendorName = '';
    @track isVendorSearching = false;
    @track isCreatingVendor = false;

    // Vendor program selection
    @track vendorPrograms = [];
    @track recentVendorPrograms = [];
    @track selectedVendorProgramId = null;
    @track vendorProgramSearchText = '';
    @track isVendorProgramSearching = false;

    // Guards to prevent duplicate actions
    @track isProceedingWithVendor = false;
    @track isProceedingWithVendorProgram = false;

    // Base column definitions (without widths - will be calculated dynamically)
    baseVendorHierarchyColumns = [
        {
            label: 'Name / Label',
            fieldName: 'displayName',
            type: 'text',
            minWidth: 150, // Minimum width to prevent too narrow
            flex: 2.5, // Relative flex value for proportional sizing
            cellAttributes: {
                class: { fieldName: 'rowClass' }
            }
        },
        {
            label: 'Status',
            fieldName: 'status',
            type: 'text',
            minWidth: 80,
            flex: 1,
            cellAttributes: {
                class: { fieldName: 'statusClass' }
            }
        },
        {
            label: 'Programs',
            fieldName: 'programCount',
            type: 'number',
            minWidth: 90,
            flex: 0.9,
            typeAttributes: {
                minimumFractionDigits: 0
            }
        },
        {
            label: 'Retail Option',
            fieldName: 'retailOption',
            type: 'text',
            minWidth: 120,
            flex: 1.4
        },
        {
            label: 'Business Vertical',
            fieldName: 'businessVertical',
            type: 'text',
            minWidth: 140,
            flex: 1.6
        },
        {
            label: 'Last Modified',
            fieldName: 'lastModifiedDate',
            type: 'date',
            minWidth: 150,
            flex: 1.5,
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
            type: 'text',
            minWidth: 120,
            flex: 1.4
        },
        {
            type: 'action',
            minWidth: 75,
            flex: 0.75,
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    // Computed columns with calculated widths based on available space
    get vendorHierarchyColumns() {
        if (!this.isTreeGridStep) {
            return this.baseVendorHierarchyColumns;
        }

        // Calculate available width (will be updated in renderedCallback)
        const availableWidth = this.calculatedModalWidth || 1200; // Default fallback
        const padding = 80; // Modal content padding
        const scrollbarWidth = 20; // Account for potential scrollbar
        const usableWidth = availableWidth - padding - scrollbarWidth;

        // Calculate total flex value
        const totalFlex = this.baseVendorHierarchyColumns.reduce((sum, col) => sum + (col.flex || 1), 0);

        // Calculate minimum total width
        const totalMinWidth = this.baseVendorHierarchyColumns.reduce((sum, col) => sum + (col.minWidth || 100), 0);

        // If minimum widths exceed available space, use minimums
        if (totalMinWidth >= usableWidth) {
            return this.baseVendorHierarchyColumns.map(col => ({
                ...col,
                initialWidth: col.minWidth || 100
            }));
        }

        // Distribute available width proportionally based on flex values
        const remainingWidth = usableWidth - totalMinWidth;
        const flexUnit = remainingWidth / totalFlex;

        return this.baseVendorHierarchyColumns.map(col => {
            const flexWidth = (col.flex || 1) * flexUnit;
            const calculatedWidth = Math.max(col.minWidth || 100, col.minWidth + flexWidth);
            
            return {
                ...col,
                initialWidth: Math.round(calculatedWidth)
            };
        });
    }

    // Track calculated modal width for column sizing
    @track calculatedModalWidth = 0;

    // --- Utility helpers ---

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
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

    // --- Wire: vendor hierarchy ---

    @wire(getVendorsWithPrograms)
    wiredVendorHierarchy({ error, data }) {
        if (data) {
            this.processVendorHierarchy(data);
            this.isVendorHierarchyLoading = false;
        } else if (error) {
            this.showToast('Error', 'Failed to load vendors and programs.', 'error');
            this.isVendorHierarchyLoading = false;
        }
    }

    processVendorHierarchy(data) {
        this.vendorHierarchy = data.map(vendor => {
            const vendorRow = {
                id: vendor.id,
                name: vendor.name,
                displayName: vendor.name,
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
                    displayName: program.label || program.name,
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

    // --- Tree grid search ---

    handleVendorSearchChange(event) {
        const searchValue = event.target.value || '';
        this.vendorSearchText = searchValue;

        if (this.isTreeGridStep) {
            if (this.vendorSearchTimeout) {
                clearTimeout(this.vendorSearchTimeout);
            }

            if (!searchValue || searchValue.trim().length === 0) {
                this.vendorSearchTimeout = setTimeout(() => {
                    this.loadVendorHierarchy();
                }, 300);
                return;
            }

            this.isVendorHierarchyLoading = true;
            this.vendorSearchTimeout = setTimeout(() => {
                this.searchVendorHierarchy(searchValue.trim());
            }, 500);
        }
    }

    async loadVendorHierarchy() {
        try {
            this.isVendorHierarchyLoading = true;
            const data = await getVendorsWithPrograms();
            this.processVendorHierarchy(data);
        } catch (error) {
            this.showToast('Error', 'Failed to load vendors and programs.', 'error');
        } finally {
            this.isVendorHierarchyLoading = false;
        }
    }

    async searchVendorHierarchy(searchText) {
        try {
            const data = await searchVendorsWithPrograms({ searchText });
            this.processVendorHierarchy(data);
        } catch (error) {
            this.showToast('Error', 'Failed to search vendors and programs.', 'error');
        } finally {
            this.isVendorHierarchyLoading = false;
        }
    }

    handleVendorHierarchyRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'edit') {
            if (row.recordType === 'program') {
                // Resume onboarding for this program
                this.dispatchEvent(
                    new CustomEvent('launchwizard', {
                        detail: { vendorProgramId: row.id, mode: 'resume' }
                    })
                );
            } else {
                this.showToast('Info', 'Please select a specific program to edit.', 'info');
            }
        }
    }

    // --- Lifecycle hooks ---

    connectedCallback() {
        // Load vendor hierarchy on initial mount
        this.loadVendorHierarchy();
        
        // Listen for window resize to recalculate column widths
        this.handleResize = this.handleResize.bind(this);
        if (typeof window !== 'undefined') {
            window.addEventListener('resize', this.handleResize);
        }
    }

    disconnectedCallback() {
        // Clean up resize listener
        if (typeof window !== 'undefined' && this.handleResize) {
            window.removeEventListener('resize', this.handleResize);
        }
    }

    renderedCallback() {
        // Calculate modal width after render to size columns appropriately
        if (this.isTreeGridStep) {
            // Use setTimeout to ensure modal is fully rendered
            setTimeout(() => {
                this.updateModalWidth();
            }, 100);
        }
    }

    /**
     * Handles window resize to recalculate column widths.
     */
    handleResize() {
        if (this.isTreeGridStep) {
            // Reset calculated width to trigger recalculation
            this.calculatedModalWidth = 0;
            this.updateModalWidth();
        }
    }

    /**
     * Updates the calculated modal width based on actual rendered size.
     * This allows columns to fill the available space.
     */
    updateModalWidth() {
        const modalContainer = this.template.querySelector('.slds-modal__container');
        if (modalContainer) {
            // Use requestAnimationFrame to ensure DOM is fully rendered
            requestAnimationFrame(() => {
                const width = modalContainer.offsetWidth || modalContainer.clientWidth;
                if (width > 0 && Math.abs(width - this.calculatedModalWidth) > 10) {
                    // Only update if change is significant (>10px) to avoid unnecessary recalculations
                    this.calculatedModalWidth = width;
                }
            });
        }
    }

    // --- Step getters ---

    get isTreeGridStep() {
        return this.vendorProgramModalStep === 'treeGrid';
    }

    get isVendorSelectionStep() {
        return this.vendorProgramModalStep === 'vendorSelection';
    }

    get isVendorProgramSelectionStep() {
        return this.vendorProgramModalStep === 'vendorProgramSelection';
    }

    // --- Dynamic modal sizing based on step and column count ---

    /**
     * Calculates the total width needed for all columns in the tree grid.
     * Uses minimum widths to determine modal size, then columns will expand to fill.
     */
    get totalColumnWidth() {
        if (!this.isTreeGridStep || !this.baseVendorHierarchyColumns) {
            return 0;
        }
        
        // Sum all minimum width values from base columns
        const minColumnWidth = this.baseVendorHierarchyColumns.reduce((total, col) => {
            return total + (col.minWidth || 100); // Default to 100px if not specified
        }, 0);
        
        // Add padding for modal content (left/right padding + margins)
        const modalPadding = 80; // ~40px each side
        const contentPadding = 40; // ~20px each side
        const scrollbarWidth = 20; // Account for potential scrollbar
        
        return minColumnWidth + modalPadding + contentPadding + scrollbarWidth;
    }

    /**
     * Gets the viewport width safely (handles SSR).
     */
    getViewportWidth() {
        if (typeof window !== 'undefined' && window.innerWidth) {
            return window.innerWidth;
        }
        // Default to common desktop width if window not available
        return 1920;
    }

    /**
     * Determines the appropriate modal size class based on content width.
     * Dynamically scales from small → medium → large → full based on column count.
     * Follows SLDS patterns for modal sizing.
     */
    get modalContainerClass() {
        const baseClass = 'vendor-program-modal-container';
        
        if (!this.isTreeGridStep) {
            // Other steps use medium size
            return `${baseClass} slds-modal_medium`;
        }
        
        // For tree grid, calculate based on total column width
        const totalWidth = this.totalColumnWidth;
        const viewportWidth = this.getViewportWidth();
        const maxModalWidth = viewportWidth * 0.98; // 98% of viewport for "full"
        
        // Determine modal size based on content width vs viewport
        if (totalWidth <= 600) {
            // Small: ≤600px
            return `${baseClass} modal-size-small`;
        } else if (totalWidth <= 900) {
            // Medium: 601-900px (SLDS medium is ~70%)
            return `${baseClass} slds-modal_medium`;
        } else if (totalWidth <= 1400) {
            // Large: 901-1400px (SLDS large is ~90%)
            return `${baseClass} slds-modal_large`;
        } else if (totalWidth <= maxModalWidth) {
            // Full: 1401px to 98% viewport
            return `${baseClass} modal-size-full`;
        } else {
            // Extra wide: Use full size but allow horizontal scroll on grid only
            return `${baseClass} modal-size-full`;
        }
    }

    /**
     * Gets inline style for modal container to set dynamic min-width.
     * This ensures the modal is wide enough to display all columns without horizontal scroll.
     */
    get modalContainerStyle() {
        if (!this.isTreeGridStep) {
            return '';
        }
        
        const totalWidth = this.totalColumnWidth;
        const viewportWidth = this.getViewportWidth();
        
        // Don't exceed 98% of viewport
        const maxWidth = Math.min(totalWidth, viewportWidth * 0.98);
        
        // Only set min-width if it's meaningful (prevents tiny modals)
        if (maxWidth > 600) {
            return `min-width: ${maxWidth}px;`;
        }
        
        return '';
    }

    // --- Vendor selection ---

    get vendorOptions() {
        return this.vendors.map(v => ({
            label: v.Name,
            value: v.Id
        }));
    }

    get selectedVendorName() {
        if (!this.selectedVendorId) return '';
        const vendor = this.vendors.find(v => v.Id === this.selectedVendorId);
        if (vendor) return vendor.Name;
        if (this.newVendorName) return this.newVendorName;
        return 'Selected Vendor';
    }

    get canProceedWithVendor() {
        return !!this.selectedVendorId;
    }

    get cannotProceedWithVendor() {
        return !this.canProceedWithVendor;
    }

    get disableVendorContinue() {
        return this.cannotProceedWithVendor || this.isProceedingWithVendor;
    }

    handleCreateVendorChange(event) {
        this.newVendorName = event.target.value;
    }

    async handleSearchVendors() {
        const searchText = this.vendorSearchText?.trim();
        if (!searchText || searchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }

        this.isVendorSearching = true;
        try {
            this.vendors = await searchVendors({ vendorNameSearchText: searchText });
            if (this.vendors.length === 0) {
                this.showToast('No Results', 'No vendors found matching your search.', 'info');
            }
        } catch (error) {
            this.showToast('Error', extractErrorMessage(error, 'Failed to search vendors.'), 'error');
        } finally {
            this.isVendorSearching = false;
        }
    }

    handleVendorSelect(event) {
        this.selectedVendorId = event.detail.value;
        this.newVendorName = '';
    }

    async handleCreateVendor() {
        if (!this.newVendorName || this.newVendorName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a vendor name.', 'warning');
            return;
        }

        await this.runWithGuard('isCreatingVendor', async () => {
            try {
                const trimmedName = this.newVendorName.trim();

                const matches = await searchVendors({ vendorNameSearchText: trimmedName });
                if (matches && matches.length > 0) {
                    this.vendors = matches;
                    this.selectedVendorId = null;
                    this.vendorSearchText = '';
                    this.newVendorName = '';
                    this.showToast(
                        'Vendor Already Exists',
                        'We found existing vendors matching this name. Please select an existing vendor to continue or refine your search.',
                        'info'
                    );
                    return;
                }

                const vendorId = await createVendor({ vendor: { Name: trimmedName } });
                this.selectedVendorId = vendorId;
                this.vendors = [];
                this.vendorSearchText = '';
                this.newVendorName = '';
                this.showToast('Success', 'Vendor created successfully.', 'success');

                await this.handleProceedWithVendor();
            } catch (error) {
                this.showToast(
                    'Error',
                    extractErrorMessage(error, 'Failed to create vendor.'),
                    'error'
                );
            }
        });
    }

    // --- Vendor program selection ---

    get vendorProgramOptions() {
        return this.vendorPrograms.map(vp => ({
            label: `${vp.Name} - ${vp.Vendor__r?.Name || 'N/A'} (${vp.Status__c || 'Draft'})`,
            value: vp.Id,
            subtitle: vp.Vendor__r?.Name || ''
        }));
    }

    get recentVendorProgramOptions() {
        return this.recentVendorPrograms.map(vp => ({
            label: `${vp.Name} - ${vp.Vendor__r?.Name || 'N/A'} (${vp.Status__c || 'Draft'})`,
            value: vp.Id,
            subtitle: vp.Vendor__r?.Name || ''
        }));
    }

    get canProceedWithVendorProgram() {
        return !!this.selectedVendorProgramId;
    }

    get cannotProceedWithVendorProgram() {
        return !this.canProceedWithVendorProgram;
    }

    get disableVendorProgramContinue() {
        return this.cannotProceedWithVendorProgram || this.isProceedingWithVendorProgram;
    }

    async loadRecentVendorPrograms() {
        try {
            this.recentVendorPrograms = await getRecentVendorPrograms({ limitCount: 5 });
        } catch (error) {
            // Recent vendor programs are non-critical
        }
    }

    handleVendorProgramSearchChange(event) {
        this.vendorProgramSearchText = event.target.value;
    }

    async handleSearchVendorPrograms() {
        const searchText = this.vendorProgramSearchText?.trim();
        if (!searchText || searchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }

        this.isVendorProgramSearching = true;
        try {
            this.vendorPrograms = await searchVendorPrograms({ vendorProgramNameSearchText: searchText });
            if (this.vendorPrograms.length === 0) {
                this.showToast('No Results', 'No vendor programs found matching your search.', 'info');
            }
        } catch (error) {
            this.showToast('Error', extractErrorMessage(error, 'Failed to search vendor programs.'), 'error');
        } finally {
            this.isVendorProgramSearching = false;
        }
    }

    handleVendorProgramSelect(event) {
        this.selectedVendorProgramId = event.detail.value;
    }

    async handleProceedWithVendorProgram() {
        if (!this.selectedVendorProgramId) {
            this.showToast('Vendor Program Required', 'Please select a vendor program to continue.', 'warning');
            return;
        }

        await this.runWithGuard('isProceedingWithVendorProgram', async () => {
            try {
                const processId = await getDefaultVendorProgramOnboardingProcessId();

                if (!processId) {
                    this.showToast('Process Not Found', 'No Vendor Program Onboarding process found. Please click "Initialize Default Process" first.', 'warning');
                    this.handleClose();
                    return;
                }

                await initializeVendorProgramOnboarding({
                    vendorProgramId: this.selectedVendorProgramId,
                    processId
                });

                this.handleClose();

                await new Promise(resolve => setTimeout(resolve, 200));

                this.dispatchEvent(
                    new CustomEvent('launchwizard', {
                        detail: { vendorProgramId: this.selectedVendorProgramId, mode: 'start' }
                    })
                );
            } catch (error) {
                this.showToast('Error', extractErrorMessage(error, 'Failed to start onboarding flow.'), 'error');
            }
        });
    }

    async handleProceedWithVendor() {
        if (!this.selectedVendorId) {
            this.showToast('Vendor Required', 'Please select or create a vendor to continue.', 'warning');
            return;
        }

        await this.runWithGuard('isProceedingWithVendor', async () => {
            try {
                const vendorProgramId = await createVendorProgram({
                    vendorProgram: { Name: 'New Vendor Program' },
                    vendorId: this.selectedVendorId
                });

                const processId = await getDefaultVendorProgramOnboardingProcessId();

                if (!processId) {
                    this.showToast('Process Not Found', 'No Vendor Program Onboarding process found. Please create one first or sync the component library.', 'warning');
                    this.dispatchEvent(
                        new CustomEvent('launchwizard', {
                            detail: { vendorProgramId, mode: 'view' }
                        })
                    );
                    return;
                }

                await initializeVendorProgramOnboarding({
                    vendorProgramId,
                    processId
                });

                this.handleClose();

                await new Promise(resolve => setTimeout(resolve, 200));

                this.dispatchEvent(
                    new CustomEvent('launchwizard', {
                        detail: { vendorProgramId, mode: 'start' }
                    })
                );
            } catch (error) {
                this.showToast(
                    'Error',
                    extractErrorMessage(error, 'Failed to create vendor program and start onboarding.'),
                    'error'
                );
            }
        });
    }

    // --- Navigation within wizard ---

    handleCreateNewVendorProgram() {
        this.vendorProgramModalStep = 'vendorSelection';
    }

    handleBackToTreeGrid() {
        this.vendorProgramModalStep = 'treeGrid';
        this.selectedVendorProgramId = null;
        this.vendorPrograms = [];
        this.selectedVendorId = null;
        this.vendors = [];
        // Reset calculated width to recalculate on next render
        this.calculatedModalWidth = 0;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
        this.resetState();
    }

    resetState() {
        this.vendorProgramModalStep = 'treeGrid';
        this.vendors = [];
        this.selectedVendorId = null;
        this.newVendorName = '';
        this.vendorPrograms = [];
        this.recentVendorPrograms = [];
        this.selectedVendorProgramId = null;
        this.vendorSearchText = '';
        this.vendorProgramSearchText = '';
        this.isVendorSearching = false;
        this.isCreatingVendor = false;
        this.isVendorProgramSearching = false;
        this.isResumingOnboarding = false;
        this.isProceedingWithVendor = false;
        this.isProceedingWithVendorProgram = false;
    }
}


