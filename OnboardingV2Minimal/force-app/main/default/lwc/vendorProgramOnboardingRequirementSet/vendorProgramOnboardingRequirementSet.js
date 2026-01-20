import { track, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import OnboardingStepBase from 'c/onboardingStepBase';
import getRequirementSetsWithTemplates from '@salesforce/apex/VendorOnboardingWizardController.getRequirementSetsWithTemplates';
import searchRequirementSetsWithTemplates from '@salesforce/apex/VendorOnboardingWizardController.searchRequirementSetsWithTemplates';
import createOnboardingRequirementSet from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingRequirementSet';

export default class VendorProgramOnboardingRequirementSet extends OnboardingStepBase {
  stepName = 'Select or Create Requirement Set';
  
  @api vendorProgramId;
  @api stageId;

  @track searchText = '';
  @track searchTimeout;
  @track requirementSetHierarchy = [];
  @track selectedRequirementSetId = '';
  @track selectedRequirementSetName = '';
  @track showCreateForm = false;
  @track nextDisabled = true;
  @track newRequirementSetName = '';
  @track newRequirementSetDisplayLabel = ''; // Optional Display Label field
  @track isHierarchyLoading = false;
  @track expandedRows = [];
  @track selectedRows = []; // Array of selected row IDs for tree grid

  // Column definitions for requirement set hierarchy tree grid
  requirementSetHierarchyColumns = [
    { 
      label: 'Display Label (Descriptive Name)', 
      fieldName: 'displayName', 
      type: 'text',
      cellAttributes: {
        class: { fieldName: 'rowClass' }
      },
      wrapText: true
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
      label: 'Templates', 
      fieldName: 'templateCount', 
      type: 'number',
      typeAttributes: {
        minimumFractionDigits: 0
      }
    },
    { 
      label: 'Type', 
      fieldName: 'requirementType', 
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
    }
  ];

  connectedCallback() {
    super.connectedCallback(); // Call base class connectedCallback for event listeners
    this.loadRequirementSetHierarchy();
  }

  get canProceed() {
    return !this.nextDisabled;
  }

  proceedToNext() {
    this.dispatchNextEvent({
      requirementSetId: this.selectedRequirementSetId,
      requirementSetName: this.selectedRequirementSetName,
      vendorProgramId: this.vendorProgramId
    });
  }

  @wire(getRequirementSetsWithTemplates)
  wiredRequirementSetHierarchy(result) {
    this.wiredRequirementSetHierarchyResult = result; // Store result for refreshApex
    const { error: hierarchyWireError, data: hierarchyWireData } = result;
    if (hierarchyWireData) {
      this.processRequirementSetHierarchy(hierarchyWireData);
      this.isHierarchyLoading = false;
    } else if (hierarchyWireError) {
      this.handleError(hierarchyWireError, 'Failed to load requirement sets and templates');
      this.isHierarchyLoading = false;
    }
  }

  processRequirementSetHierarchy(data) {
    this.requirementSetHierarchy = data.map(reqSet => {
      const hasRealChildren = reqSet.children && reqSet.children.length > 0;
      
      // Use Display Label if available, otherwise fall back to Name
      const displayLabel = reqSet.displayLabel || reqSet.name;
      
      const reqSetRow = {
        id: reqSet.id,
        name: reqSet.name,
        displayName: displayLabel, // Use Display Label instead of Name
        status: reqSet.status,
        templateCount: reqSet.templateCount,
        recordType: reqSet.recordType,
        lastModifiedDate: reqSet.lastModifiedDate ? new Date(reqSet.lastModifiedDate) : null,
        rowClass: 'slds-text-heading_small',
        statusClass: this.getStatusClass(reqSet.status),
        // Set _children to empty array so expand arrow appears, but we'll show toast on expand
        _children: hasRealChildren ? reqSet.children.map(template => ({
          id: template.id,
          name: template.name,
          displayName: template.name,
          status: template.status,
          templateCount: null,
          recordType: template.recordType,
          requirementType: template.requirementType || '',
          isCurrentVersion: template.isCurrentVersion,
          lastModifiedDate: template.lastModifiedDate ? new Date(template.lastModifiedDate) : null,
          parentId: template.parentId,
          rowClass: 'slds-text-body_regular',
          statusClass: this.getStatusClass(template.status),
          _children: null
        })) : []
      };
      return reqSetRow;
    });
    
    // If there's already a selected requirement set (from context restoration), update selectedRows
    if (this.selectedRequirementSetId) {
      // Verify the selected ID exists in the hierarchy
      const selectedRow = this.findRowById(this.selectedRequirementSetId, this.requirementSetHierarchy);
      if (selectedRow && selectedRow.recordType === 'requirementSet') {
        this.selectedRows = [this.selectedRequirementSetId];
        // Update selectedRequirementSetName to use Display Label
        this.selectedRequirementSetName = selectedRow.displayName || selectedRow.name || '';
      }
    }
  }

  getStatusClass(status) {
    if (!status) return '';
    const statusLower = status.toLowerCase();
    if (statusLower === 'active') return 'slds-text-color_success';
    if (statusLower === 'draft') return 'slds-text-color_weak';
    if (statusLower === 'inactive') return 'slds-text-color_error';
    return '';
  }

  handleSearchChange(event) {
    const searchValue = event.target.value || '';
    this.searchText = searchValue;

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    if (!searchValue || searchValue.trim().length === 0) {
      // Clear search and reload all requirement sets
      this.searchTimeout = setTimeout(() => {
        this.loadRequirementSetHierarchy();
      }, 300);
      return;
    }

    // Debounce search
    this.isHierarchyLoading = true;
    this.searchTimeout = setTimeout(() => {
      this.searchRequirementSetHierarchy(searchValue.trim());
    }, 500);
  }

  async loadRequirementSetHierarchy() {
    try {
      this.isHierarchyLoading = true;
      const hierarchyData = await getRequirementSetsWithTemplates();
      this.processRequirementSetHierarchy(hierarchyData);
    } catch (loadError) {
      this.handleError(loadError, 'Failed to load requirement sets and templates');
    } finally {
      this.isHierarchyLoading = false;
    }
  }

  async searchRequirementSetHierarchy(searchText) {
    try {
      const hierarchyData = await searchRequirementSetsWithTemplates({ searchText: searchText });
      this.processRequirementSetHierarchy(hierarchyData);
    } catch (searchError) {
      this.handleError(searchError, 'Failed to search requirement sets and templates');
    } finally {
      this.isHierarchyLoading = false;
    }
  }

  handleRequirementSetHierarchySelectionChange(event) {
    // lightning-tree-grid fires onrowselection when checkboxes are clicked
    // event.detail.selectedRows contains the array of selected row objects
    const selectedRowObjects = event.detail.selectedRows || [];
    const newlySelectedRowIds = selectedRowObjects.map(row => row.id);
    
    // Find which Requirement Set rows were selected (not template rows)
    const selectedRequirementSetIds = newlySelectedRowIds.filter(rowId => {
      const row = this.findRowById(rowId, this.requirementSetHierarchy);
      return row && row.recordType === 'requirementSet';
    });
    
    if (selectedRequirementSetIds.length > 0) {
      // Single-select: Only keep the most recently selected Requirement Set
      const latestSelectedId = selectedRequirementSetIds[selectedRequirementSetIds.length - 1];
      const selectedRow = this.findRowById(latestSelectedId, this.requirementSetHierarchy);
      
      // Update selection - only one Requirement Set can be selected
      this.selectedRequirementSetId = latestSelectedId;
      // Use Display Label if available, otherwise fall back to Name
      this.selectedRequirementSetName = selectedRow?.displayName || selectedRow?.name || '';
      
      // Enforce single-select by updating selectedRows to only contain the selected Requirement Set
      if (this.selectedRows.length !== 1 || this.selectedRows[0] !== latestSelectedId) {
        this.selectedRows = [latestSelectedId];
      }
      
      this.newRequirementSetName = '';
      this.showCreateForm = false;
      // Explicitly validate form after selection
      this.validateCreateForm();
    } else if (newlySelectedRowIds.length > 0) {
      // User tried to select a template row - prevent selection and show message
      this.showToast('Info', 'Please select a Requirement Set (parent row) to continue.', 'info');
      // Reset to maintain only the previously selected Requirement Set (if any)
      this.selectedRows = this.selectedRequirementSetId ? [this.selectedRequirementSetId] : [];
      this.validateCreateForm();
    } else {
      // No rows selected - clear selection
      this.selectedRequirementSetId = '';
      this.selectedRequirementSetName = '';
      this.selectedRows = [];
      this.validateCreateForm();
    }
  }

  handleRequirementSetHierarchyToggle(event) {
    // Handle expand/collapse of tree grid rows
    // event.detail structure: { name: rowId, expandedRows: [array of expanded row IDs] }
    const toggleDetails = event.detail;
    
    if (!toggleDetails || !toggleDetails.name) {
      return;
    }
    
    const rowId = toggleDetails.name;
    const updatedExpandedRows = toggleDetails.expandedRows || [];
    
    // Find the row that was toggled
    const toggledRow = this.findRowById(rowId, this.requirementSetHierarchy);
    
    if (!toggledRow || toggledRow.recordType !== 'requirementSet') {
      // Not a requirement set row, update expanded rows normally
      this.expandedRows = updatedExpandedRows;
      return;
    }
    
    // Check if row has children
    const hasChildren = toggledRow._children && Array.isArray(toggledRow._children) && toggledRow._children.length > 0;
    
    // If row has no children and toggle event fires, user clicked expand arrow
    // Show toast notification because tree grid prevents expansion when there are no children
    if (!hasChildren) {
      const requirementSetDisplayLabel = toggledRow.displayName || toggledRow.name || 'Unknown';
      this.showToast('Info', `No Requirement Template records for the Requirement Set "${requirementSetDisplayLabel}".`, 'info');
      // Don't update expandedRows since expansion was prevented by tree grid
      return;
    }
    
    // Normal expansion/collapse handling for rows with children
    this.expandedRows = updatedExpandedRows;
  }

  // Helper method to find a row by ID in the hierarchy (including children)
  findRowById(rowId, hierarchy) {
    if (!hierarchy) return null;
    for (const row of hierarchy) {
      if (row.id === rowId) {
        return row;
      }
      if (row._children && row._children.length > 0) {
        const found = this.findRowById(rowId, row._children);
        if (found) return found;
      }
    }
    return null;
  }


  handleNewRequirementSetChange(e) {
    this.newRequirementSetName = e.target.value;
    this.validateCreateForm();
  }

  handleNewRequirementSetDisplayLabelChange(e) {
    this.newRequirementSetDisplayLabel = e.target.value;
  }

  validateCreateForm() {
    const hasSelectedSet = !!this.selectedRequirementSetId;
    const hasValidCreateForm = !!this.newRequirementSetName?.trim();
    this.nextDisabled = !(hasSelectedSet || hasValidCreateForm);
    this.dispatchValidationState();
  }

  async createRequirementSet() {
    if (!this.vendorProgramId) {
      this.showToast('Error', 'Vendor Program ID is missing. Please refresh the page and try again.', 'error');
      return;
    }

    if (!this.newRequirementSetName?.trim()) {
      this.showToast('Required Fields Missing', 'Please enter a Name for the Requirement Set.', 'warning');
      return;
    }

    try {
      // Create requirement set - Vendor_Program__c is optional for many-to-many support
      // Link to vendor program(s) will be created via junction after creation
      const requirementSetId = await createOnboardingRequirementSet({ 
        requirementSet: { 
          Name: this.newRequirementSetName.trim(),
          // Include Display_Label__c if user provided it
          Display_Label__c: this.newRequirementSetDisplayLabel?.trim() || null,
          // Note: Vendor_Program__c kept for backward compatibility
          // But junction records are the primary way to link requirement sets to vendor programs
          Vendor_Program__c: this.vendorProgramId || null // Optional for many-to-many
        } 
      });
      this.selectedRequirementSetId = requirementSetId;
      this.selectedRows = [requirementSetId]; // Set selected rows for checkbox selection
      const createdName = this.newRequirementSetName.trim(); // Store before clearing
      this.newRequirementSetName = '';
      this.newRequirementSetDisplayLabel = ''; // Clear display label
      this.showCreateForm = false;
      this.nextDisabled = false;
      this.dispatchValidationState();
      
      // Refresh wire adapter to show the newly created requirement set
      if (this.wiredRequirementSetHierarchyResult) {
        await refreshApex(this.wiredRequirementSetHierarchyResult);
      }
      
      // After refresh, update selectedRequirementSetName from the hierarchy to get Display Label
      const createdRow = this.findRowById(requirementSetId, this.requirementSetHierarchy);
      if (createdRow) {
        this.selectedRequirementSetName = createdRow.displayName || createdRow.name || '';
      } else {
        // Fallback to the name that was entered
        this.selectedRequirementSetName = createdName;
      }
      this.showToast('Success', 'Onboarding Requirement Set created successfully!', 'success');
    } catch (err) {
      this.handleError(err, 'Failed to create requirement set');
    }
  }

  toggleCreateForm() {
    this.showCreateForm = !this.showCreateForm;
    if (!this.showCreateForm) {
      this.newRequirementSetName = '';
      this.validateCreateForm();
    }
  }

  proceedToNext() {
    if (!this.selectedRequirementSetId) {
      this.showToast('Selection Required', 'Please select or create a Requirement Set before proceeding.', 'warning');
      return;
    }

    this.dispatchNextEvent({
      requirementSetId: this.selectedRequirementSetId,
      requirementSetName: this.selectedRequirementSetName,
      vendorProgramId: this.vendorProgramId
    });
  }

  get createButtonLabel() {
    return this.showCreateForm ? 'Cancel Create' : 'Create New Requirement Set';
  }

  // Watch for changes to selectedRows and validate
  renderedCallback() {
    // This gets called whenever the component re-renders
    // We can use it to validate if selectedRows has changed
    if (this.selectedRows && this.selectedRows.length > 0) {
      const currentSelectedId = this.selectedRows[0];
      if (currentSelectedId !== this.selectedRequirementSetId) {
        // Selection has changed - update and validate
        const selectedRow = this.findRowById(currentSelectedId, this.requirementSetHierarchy);
        if (selectedRow && selectedRow.recordType === 'requirementSet') {
          this.selectedRequirementSetId = currentSelectedId;
          this.selectedRequirementSetName = selectedRow?.displayName || selectedRow?.name || '';
          this.validateCreateForm();
        }
      }
    } else if (this.selectedRows && this.selectedRows.length === 0 && this.selectedRequirementSetId) {
      // Selection was cleared
      this.selectedRequirementSetId = '';
      this.selectedRequirementSetName = '';
      this.validateCreateForm();
    }
  }
}

