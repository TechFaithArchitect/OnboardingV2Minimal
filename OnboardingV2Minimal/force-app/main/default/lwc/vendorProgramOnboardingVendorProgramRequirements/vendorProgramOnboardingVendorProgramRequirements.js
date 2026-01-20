import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import getRequirementsByGroup from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsByGroup';
import getTemplatesByGroup from '@salesforce/apex/VendorOnboardingWizardController.getTemplatesByGroup';
import bulkCreateRequirementsFromTemplates from '@salesforce/apex/VendorOnboardingWizardController.bulkCreateRequirementsFromTemplates';
import updateRequirementSequences from '@salesforce/apex/VendorOnboardingWizardController.updateRequirementSequences';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';
import deleteVendorProgramRequirement from '@salesforce/apex/VendorOnboardingWizardController.deleteVendorProgramRequirement';
import getVendorProgramRequirementStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramRequirementStatusPicklistValues';
import getAllVendorProgramRequirementGroups from '@salesforce/apex/VendorOnboardingWizardController.getAllVendorProgramRequirementGroups';
import createVendorProgramRequirementGroup from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRequirementGroup';
import getStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getStatusPicklistValues';

const COLUMNS = [
  { label: 'Name', fieldName: 'Name' },
  {
    type: 'button',
    typeAttributes: {
      label: 'Select',
      name: 'select',
      variant: 'brand'
    }
  }
];

export default class VendorProgramOnboardingVendorProgramRequirements extends OnboardingStepBase {
  stepName = 'Vendor Program Requirements';
  
  @api vendorProgramId;
  @api stageId;
  @api requirementTemplateId; // From previous step
  @api requirementGroupId; // From Step 5 - auto-selected Requirement Group

  @track searchText = '';
  @track searchResults = [];
  @track createdRequirementId = null; // Track created requirement for cleanup on back
  @track statusOptions = [];
  @track newRequirement = {
    status: 'Active',
    isRequired: true,
    sequence: null,
    requirementGroupId: null,
    requirementGroupMemberId: null
  };
  @track isLoading = false;
  @track vendorProgramName = '';
  @track requirementTemplateName = '';
  @track allRequirementGroups = []; // All available groups (for dropdown)
  @track selectedGroupId = ''; // Selected Requirement Group
  @track selectedGroupName = ''; // Track name for display
  @track isLoadingGroups = true; // Track loading state for groups
  @track showCreateGroupForm = false; // Show/hide create group form
  @track newGroupName = ''; // Name for new group
  @track newGroupStatus = 'Active'; // Status for new group
  @track groupStatusOptions = []; // Status picklist options for new group
  @track isCreatingGroup = false; // Track if group is being created
  @track templatesFromGroup = []; // Templates linked to the selected Requirement Group
  @track isLoadingGroupData = false; // Track loading state for group-related data
  @track selectedTemplateIds = []; // Templates selected for bulk creation
  @track createdRequirements = []; // Requirements created in this session
  @track showSummary = false; // Show summary after creation
  @track bulkCreateStatus = 'Active'; // Default status for bulk creation
  @track bulkCreateIsRequired = true; // Default Is Required for bulk creation

  columns = COLUMNS;

  @wire(getVendorProgramRequirementStatusPicklistValues)
  wiredStatusOptions({ error, data }) {
    if (data) {
      this.statusOptions = data;
      // Set default status if not already set
      if (!this.newRequirement.status && data.length > 0) {
        this.newRequirement.status = data[0].value;
      }
    } else if (error) {
      this.handleError(error, 'Failed to load Status picklist values');
      this.statusOptions = [
        { label: 'Active', value: 'Active' },
        { label: 'Draft', value: 'Draft' },
        { label: 'Inactive', value: 'Inactive' }
      ];
    }
  }

  get hasSearchResults() {
    return this.searchResults && this.searchResults.length > 0;
  }


  get isCreateFormValid() {
    return !!this.newRequirement.status;
  }

  get isCreateButtonDisabled() {
    return !this.isCreateFormValid || !this.requirementTemplateId || !this.selectedGroupId;
  }

  get canProceed() {
    // Continue requires requirements to be created
    return this.hasCreatedRequirements;
  }

  get canContinue() {
    // Alias for backward compatibility
    return this.canProceed;
  }

  get cannotProceed() {
    return !this.canProceed;
  }

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    // Load vendor program and template names for display
    this.loadContextNames();
    // Load existing requirements for this vendor program immediately
    this.loadExistingRequirements();
    // Load Requirement Groups
    this.loadAllRequirementGroups();
    // Load status options for group creation
    this.loadGroupStatusOptions();
  }

  async handleFooterBackClick() {
    // Override: async logic needed for deletion confirmation
    await this.handleBack();
  }

  renderedCallback() {
    // React to requirementGroupId changes (when coming from Step 5)
    // This runs after the component renders, so we can check if requirementGroupId is set
    if (this.requirementGroupId && !this.selectedGroupId && this.allRequirementGroups.length > 0) {
      this.handleRequirementGroupIdChange();
    }
  }

  async handleRequirementGroupIdChange() {
    // Auto-select group from Step 5 if provided
    if (this.requirementGroupId && this.allRequirementGroups.length > 0) {
      const preSelectedGroup = this.allRequirementGroups.find(g => g.Id === this.requirementGroupId);
      
      if (preSelectedGroup && !this.selectedGroupId) {
        this.selectedGroupId = preSelectedGroup.Id;
        this.selectedGroupName = preSelectedGroup.Name;
        this.newRequirement.requirementGroupId = preSelectedGroup.Id;
        
        // Load requirements and templates for this group
        await this.loadGroupData(preSelectedGroup.Id);
      }
    }
  }

  async loadAllRequirementGroups() {
    this.isLoadingGroups = true;
    try {
      const allGroups = await getAllVendorProgramRequirementGroups();
      this.allRequirementGroups = Array.isArray(allGroups) ? allGroups : [];
      
      // If requirementGroupId was provided, find and select it
      if (this.requirementGroupId && this.allRequirementGroups.length > 0) {
        await this.handleRequirementGroupIdChange();
      }
    } catch (error) {
      this.handleError(error, 'Failed to load requirement groups');
      this.allRequirementGroups = [];
    } finally {
      this.isLoadingGroups = false;
    }
  }

  async loadGroupStatusOptions() {
    try {
      const statusOptionsData = await getStatusPicklistValues();
      this.groupStatusOptions = statusOptionsData || [
        { label: 'Active', value: 'Active' },
        { label: 'Inactive', value: 'Inactive' },
        { label: 'Draft', value: 'Draft' }
      ];
    } catch (error) {
      this.handleError(error, 'Failed to load status picklist values');
      // Use default options
      this.groupStatusOptions = [
        { label: 'Active', value: 'Active' },
        { label: 'Inactive', value: 'Inactive' },
        { label: 'Draft', value: 'Draft' }
      ];
    }
  }

  async loadExistingRequirements() {
    if (!this.vendorProgramId) {
      return;
    }
    try {
      const existingReqs = await getRequirementsForVendorProgram({ vendorProgramId: this.vendorProgramId });
      
      if (!existingReqs) {
        this.createdRequirements = [];
        this.showSummary = false;
        return;
      }
      
      const requirements = Array.isArray(existingReqs) ? existingReqs : [];
      
      // Sort by sequence (already sorted by Apex, but ensure consistency)
      try {
        requirements.sort((a, b) => {
          const seqA = a?.Sequence__c || 9999;
          const seqB = b?.Sequence__c || 9999;
          return seqA - seqB;
        });
      } catch (sortError) {
        if (this.isDebugMode()) {
          console.error('Error sorting requirements:', sortError);
        }
      }
      
      this.createdRequirements = requirements || [];
      
      // Show summary if we have requirements
      if (this.createdRequirements.length > 0) {
        this.showSummary = true;
        // Update validation state when existing requirements are loaded
        this.dispatchValidationState();
      } else {
        this.showSummary = false;
      }
    } catch (error) {
      this.handleError(error, 'Failed to load existing requirements');
      this.createdRequirements = [];
      this.showSummary = false;
    }
  }

  async loadGroupData(requirementGroupId) {
    if (!requirementGroupId) {
      this.templatesFromGroup = [];
      this.searchResults = [];
      return;
    }

    this.isLoadingGroupData = true;
    try {
      // Load both requirements and templates for this group in parallel
      const [requirementsFromGroup, templatesFromGroup] = await Promise.all([
        getRequirementsByGroup({ requirementGroupId: requirementGroupId }),
        getTemplatesByGroup({ requirementGroupId: requirementGroupId })
      ]);

      // Set search results to show existing requirements from this group
      this.searchResults = Array.isArray(requirementsFromGroup) ? requirementsFromGroup : [];
      
      // Store templates for display and selection
      this.templatesFromGroup = Array.isArray(templatesFromGroup) ? templatesFromGroup : [];
      
      // Reload existing requirements for this vendor program to refresh the summary
      await this.loadExistingRequirements();
      
      // Show a toast if templates were loaded
      if (this.templatesFromGroup.length > 0) {
        this.showToast('Info', `Loaded ${this.templatesFromGroup.length} template(s) from '${this.selectedGroupName}'. Select templates below to create requirements.`, 'info');
      }
    } catch (error) {
      this.handleError(error, 'Failed to load templates and requirements for the selected group');
      this.searchResults = [];
      this.templatesFromGroup = [];
    } finally {
      this.isLoadingGroupData = false;
    }
  }

  get hasTemplatesFromGroup() {
    return this.templatesFromGroup && this.templatesFromGroup.length > 0;
  }

  get hasRequirementsFromGroup() {
    return this.searchResults && this.searchResults.length > 0 && this.selectedGroupId;
  }

  get templateOptions() {
    if (!this.templatesFromGroup || this.templatesFromGroup.length === 0) {
      return [];
    }
    return this.templatesFromGroup.map(template => ({
      label: `${template.Requirement_Label__c} (${template.Requirement_Type__c})`,
      value: template.Id,
      template: template
    }));
  }

  get hasSelectedTemplates() {
    return this.selectedTemplateIds && this.selectedTemplateIds.length > 0;
  }

  get canCreateRequirements() {
    return this.hasSelectedTemplates && this.vendorProgramId && this.selectedGroupId;
  }

  get cannotCreateRequirements() {
    return !this.canCreateRequirements;
  }

  get emptyDraftValues() {
    return [];
  }

  get hasCreatedRequirements() {
    return this.createdRequirements && this.createdRequirements.length > 0;
  }

  get canProceed() {
    return this.hasCreatedRequirements;
  }

  handleTemplateSelectionChange(event) {
    this.selectedTemplateIds = event.detail.value || [];
  }

  handleSelectAllTemplates() {
    if (this.templatesFromGroup && this.templatesFromGroup.length > 0) {
      this.selectedTemplateIds = this.templatesFromGroup.map(t => t.Id);
    }
  }

  handleDeselectAllTemplates() {
    this.selectedTemplateIds = [];
  }

  handleBulkStatusChange(event) {
    this.bulkCreateStatus = event.detail.value;
  }

  handleBulkIsRequiredChange(event) {
    this.bulkCreateIsRequired = event.target.checked;
  }

  async handleBulkCreateRequirements() {
    if (!this.canCreateRequirements) {
      this.showToast('Validation Error', 'Please select at least one template to create requirements from.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      const result = await bulkCreateRequirementsFromTemplates({
        vendorProgramId: this.vendorProgramId,
        templateIds: this.selectedTemplateIds,
        defaultStatus: this.bulkCreateStatus,
        defaultIsRequired: this.bulkCreateIsRequired
      });

      if (result.success) {
        const createdCount = result.createdRequirementIds?.length || 0;
        const skippedCount = result.skippedTemplateIds?.length || 0;
        
        let message = `Successfully created ${createdCount} requirement(s).`;
        if (skippedCount > 0) {
          message += ` ${skippedCount} template(s) skipped (requirements already exist).`;
        }
        
        this.showToast('Success', message, 'success');
        
        // Wait a moment for database commit, then reload requirements
        await new Promise(resolve => setTimeout(resolve, 300));
        
        // Reload requirements to show the newly created ones
        await this.loadExistingRequirements();
        
        // Always show summary after creation (even if some were skipped)
        if (createdCount > 0 || this.hasCreatedRequirements) {
          this.showSummary = true;
        }
        
        // Clear selected templates
        this.selectedTemplateIds = [];
        
        // Update validation state after creation
        this.dispatchValidationState();
      } else {
        this.showToast('Error', result.errorMessage || 'Failed to create requirements.', 'error');
      }
    } catch (error) {
      this.handleError(error, 'Failed to create requirements');
    } finally {
      this.isLoading = false;
    }
  }

  handleSequenceChange(event) {
    const updatedRows = event.detail.draftValues;
    if (!updatedRows || updatedRows.length === 0) {
      return;
    }

    // Update local data
    const updatedRequirements = this.createdRequirements.map(req => {
      const updatedRow = updatedRows.find(row => row.Id === req.Id);
      if (updatedRow) {
        return { ...req, Sequence__c: updatedRow.Sequence__c };
      }
      return req;
    });

    // Sort by sequence and renumber
    updatedRequirements.sort((a, b) => {
      const seqA = a.Sequence__c || 9999;
      const seqB = b.Sequence__c || 9999;
      return seqA - seqB;
    });

    // Renumber sequentially
    updatedRequirements.forEach((req, index) => {
      req.Sequence__c = index + 1;
    });

    this.createdRequirements = updatedRequirements;

    // Save to database
    this.saveSequenceChanges(updatedRequirements);
  }

  async saveSequenceChanges(requirements) {
    try {
      const requirementsToUpdate = requirements.map(req => ({
        Id: req.Id,
        Sequence__c: req.Sequence__c
      }));
      
      await updateRequirementSequences({ requirements: requirementsToUpdate });
    } catch (error) {
      this.handleError(error, 'Failed to update sequence order');
    }
  }

  get requirementsColumns() {
    // Let columns auto-size based on content and container width
    // column-widths-mode="auto" will distribute columns to fill full width
    return [
      { 
        label: 'Sequence', 
        fieldName: 'Sequence__c', 
        type: 'number', 
        editable: true, 
        sortable: true,
        cellAttributes: { alignment: 'center' },
        fixedWidth: false,
        wrapText: false
      },
      { 
        label: 'Requirement Number', 
        fieldName: 'Name', 
        type: 'text',
        sortable: true,
        fixedWidth: false,
        wrapText: false
      },
      { 
        label: 'Template', 
        fieldName: 'templateLabel', 
        type: 'text',
        sortable: true,
        wrapText: true,
        fixedWidth: false
      },
      { 
        label: 'Status', 
        fieldName: 'Status__c', 
        type: 'text',
        sortable: true,
        fixedWidth: false,
        wrapText: false
      },
      { 
        label: 'Required', 
        fieldName: 'Is_Required__c', 
        type: 'boolean',
        sortable: true,
        cellAttributes: { alignment: 'center' },
        fixedWidth: false
      },
      {
        type: 'action',
        typeAttributes: {
          rowActions: [
            { label: 'Delete', name: 'delete' }
          ]
        },
        fixedWidth: 75
      }
    ];
  }

  get formattedRequirements() {
    if (!this.createdRequirements || this.createdRequirements.length === 0) {
      return [];
    }
    try {
      return this.createdRequirements.map(req => {
        // Safely access relationship field
        let templateLabel = 'N/A';
        try {
          if (req.Requirement_Template__r && req.Requirement_Template__r.Requirement_Label__c) {
            templateLabel = req.Requirement_Template__r.Requirement_Label__c;
          } else if (req.Requirement_Template__c) {
            // If relationship is null but ID exists, try to find in templates list
            const template = this.templatesFromGroup?.find(t => t.Id === req.Requirement_Template__c);
            if (template) {
              templateLabel = template.Requirement_Label__c || 'N/A';
            }
          }
        } catch (relError) {
          if (this.isDebugMode()) {
            console.warn('Could not access Requirement_Template__r for requirement:', req.Id);
          }
        }
        
        return {
          ...req,
          templateLabel: templateLabel,
          // Ensure all required fields are present
          Sequence__c: req.Sequence__c || null,
          Name: req.Name || '',
          Status__c: req.Status__c || 'Active',
          Is_Required__c: req.Is_Required__c !== undefined ? req.Is_Required__c : true
        };
      });
    } catch (error) {
      if (this.isDebugMode()) {
        console.error('Error formatting requirements:', error);
      }
      // Return requirements without formatting if formatting fails
      return this.createdRequirements;
    }
  }

  handleRequirementRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;

    if (action.name === 'delete') {
      this.handleDeleteRequirement(row.Id);
    }
  }

  async handleDeleteRequirement(requirementId) {
    if (!confirm('Are you sure you want to delete this requirement?')) {
      return;
    }

    this.isLoading = true;
    try {
      await deleteVendorProgramRequirement({ requirementId: requirementId });
      this.showToast('Success', 'Requirement deleted successfully.', 'success');
      
      // Reload requirements
      await this.loadExistingRequirements();
    } catch (error) {
      this.handleError(error, 'Failed to delete requirement');
    } finally {
      this.isLoading = false;
    }
  }

  handleMoveUp(index) {
    if (index === 0) return;
    
    const requirements = [...this.createdRequirements];
    [requirements[index - 1], requirements[index]] = [requirements[index], requirements[index - 1]];
    
    // Renumber sequences
    requirements.forEach((req, idx) => {
      req.Sequence__c = idx + 1;
    });
    
    this.createdRequirements = requirements;
    this.saveSequenceChanges(requirements);
  }

  handleMoveDown(index) {
    if (index === this.createdRequirements.length - 1) return;
    
    const requirements = [...this.createdRequirements];
    [requirements[index], requirements[index + 1]] = [requirements[index + 1], requirements[index]];
    
    // Renumber sequences
    requirements.forEach((req, idx) => {
      req.Sequence__c = idx + 1;
    });
    
    this.createdRequirements = requirements;
    this.saveSequenceChanges(requirements);
  }

  async loadContextNames() {
    // This would ideally fetch the names, but for now we'll use IDs
    // In a real implementation, you might want to fetch these from Apex
    this.vendorProgramName = this.vendorProgramId || 'Current Vendor Program';
    this.requirementTemplateName = this.requirementTemplateId || 'Selected Template';
  }

  handleSearchTextChange(event) {
    this.searchText = event.target.value;
  }


  handleRowAction(event) {
    const selected = event.detail.row;
    this.dispatchEvent(new CustomEvent('next', {
      detail: {
        selectedRequirementId: selected.Id,
        vendorProgramId: this.vendorProgramId
      },
      bubbles: true,
      composed: true
    }));
  }

  handleStatusChange(event) {
    this.newRequirement = {
      ...this.newRequirement,
      status: event.detail.value
    };
  }

  handleIsRequiredChange(event) {
    this.newRequirement = {
      ...this.newRequirement,
      isRequired: event.target.checked
    };
  }

  handleSequenceChange(event) {
    const sequenceValue = event.target.value ? parseInt(event.target.value, 10) : null;
    this.newRequirement = {
      ...this.newRequirement,
      sequence: sequenceValue
    };
  }

  async handleRequirementGroupSelect(event) {
    const newSelectedGroupId = event.detail.value;
    
    // Find the selected group name
    const selectedGroup = this.allRequirementGroups.find(g => g.Id === newSelectedGroupId);
    
    this.selectedGroupId = newSelectedGroupId;
    this.selectedGroupName = selectedGroup ? selectedGroup.Name : '';
    
    this.newRequirement = {
      ...this.newRequirement,
      requirementGroupId: newSelectedGroupId,
      requirementGroupMemberId: null // Clear member when group changes
    };

    // Load requirements and templates for the newly selected group
    await this.loadGroupData(newSelectedGroupId);
    
    // Clear selected templates when group changes
    this.selectedTemplateIds = [];
  }

  handleRequirementGroupChange(event) {
    // Legacy handler - keeping for compatibility but using handleRequirementGroupSelect
    this.handleRequirementGroupSelect(event);
  }

  handleRequirementGroupMemberChange(event) {
    this.newRequirement = {
      ...this.newRequirement,
      requirementGroupMemberId: event.detail.value
    };
  }

  async handleCreate() {
    if (!this.isCreateFormValid) {
      this.showToast('Validation Error', 'Please fill in all required fields.', 'error');
      return;
    }

    if (!this.vendorProgramId || !this.requirementTemplateId) {
      this.showToast('Missing Context', 'Vendor Program and Requirement Template are required. Please go back and complete previous steps.', 'error');
      return;
    }

    if (!this.selectedGroupId) {
      this.showToast('Required Field Missing', 'Please select or create a Requirement Group to continue.', 'error');
      return;
    }

    this.isLoading = true;
    try {
      const requirementToCreate = {
        Vendor_Program__c: this.vendorProgramId,
        Vendor_Program_Onboarding_Req_Template__c: this.requirementTemplateId,
        Status__c: this.newRequirement.status,
        Is_Required__c: this.newRequirement.isRequired,
        Sequence__c: this.newRequirement.sequence,
        Vendor_Program_Requirement_Group__c: this.selectedGroupId,
        Vendor_Program_Requirement_Group_Member__c: this.newRequirement.requirementGroupMemberId || null
      };

      const newRequirementId = await createVendorProgramRequirement({ vendorProgramRequirement: requirementToCreate });
      
      // Track the created requirement ID for cleanup on back
      this.createdRequirementId = newRequirementId;

      this.showToast('Success', 'Requirement created successfully!', 'success');

      // Proceed to next step
      this.dispatchEvent(new CustomEvent('next', {
        detail: {
          selectedRequirementId: newRequirementId,
          vendorProgramId: this.vendorProgramId
        },
        bubbles: true,
        composed: true
      }));
    } catch (error) {
      this.handleError(error, 'Failed to create requirement');
    } finally {
      this.isLoading = false;
    }
  }

  toggleCreateGroupForm() {
    this.showCreateGroupForm = !this.showCreateGroupForm;
    if (!this.showCreateGroupForm) {
      // Reset form when hiding
      this.newGroupName = '';
      this.newGroupStatus = 'Active';
    }
  }

  handleNewGroupNameChange(event) {
    this.newGroupName = event.target.value;
  }

  handleNewGroupStatusChange(event) {
    this.newGroupStatus = event.detail.value;
  }

  get canCreateGroup() {
    return !!this.newGroupName?.trim() && !!this.newGroupStatus;
  }

  get isCreateGroupButtonDisabled() {
    return !this.canCreateGroup || this.isCreatingGroup;
  }

  get isCancelGroupButtonDisabled() {
    return this.isCreatingGroup;
  }

  async handleCreateGroup() {
    if (!this.canCreateGroup) {
      this.showToast('Required Fields Missing', 'Please enter a Group Name.', 'warning');
      return;
    }

    this.isCreatingGroup = true;
    try {
      const newGroupId = await createVendorProgramRequirementGroup({
        vendorProgramRequirementGroup: {
          Name: this.newGroupName.trim(),
          Status__c: this.newGroupStatus
        }
      });

      this.showToast('Success', 'Requirement Group created successfully!', 'success');

      // Reload groups list to include the new one
      await this.loadAllRequirementGroups();

      // Auto-select the newly created group
      this.selectedGroupId = newGroupId;
      const newGroup = this.allRequirementGroups.find(g => g.Id === newGroupId);
      if (newGroup) {
        this.selectedGroupName = newGroup.Name;
        this.newRequirement.requirementGroupId = newGroupId;
      }

      // Hide the form and reset
      this.showCreateGroupForm = false;
      this.newGroupName = '';
      this.newGroupStatus = 'Active';
    } catch (error) {
      this.handleError(error, 'Failed to create requirement group');
    } finally {
      this.isCreatingGroup = false;
    }
  }

  get requirementGroupOptions() {
    if (!this.allRequirementGroups || this.allRequirementGroups.length === 0) {
      return [];
    }
    return this.allRequirementGroups
      .filter(g => g && g.Id && g.Name)
      .map(g => ({
        label: g.Name || 'Unnamed Group',
        value: g.Id
      }));
  }

  get hasSelectedGroup() {
    return !!this.selectedGroupId;
  }

  get hasRequirementGroups() {
    return this.allRequirementGroups && this.allRequirementGroups.length > 0;
  }

  get isGroupFromStep5() {
    return this.requirementGroupId && this.selectedGroupId === this.requirementGroupId;
  }

  proceedToNext() {
    // Proceed to next step with created requirements
    this.dispatchNextEvent({
      vendorProgramId: this.vendorProgramId,
      requirementGroupId: this.selectedGroupId
    });
  }

  async handleBack() {
    // If requirements were created in this session, ask user if they want to delete them
    if (this.hasCreatedRequirements && this.createdRequirements.length > 0) {
      if (!confirm(`You have created ${this.createdRequirements.length} requirement(s) in this step. Do you want to delete them before going back?`)) {
        // User chose not to delete, just go back
        this.dispatchBackEvent();
        return;
      }

      // Delete all created requirements
      this.isLoading = true;
      let deletedCount = 0;
      let failedCount = 0;
      
      for (const req of this.createdRequirements) {
        try {
          await deleteVendorProgramRequirement({ requirementId: req.Id });
          deletedCount++;
        } catch (error) {
          if (this.isDebugMode()) {
            console.error('Error deleting requirement:', error);
          }
          failedCount++;
        }
      }

      if (deletedCount > 0) {
        this.showToast('Info', `${deletedCount} requirement(s) deleted.`, 'info');
      }
      if (failedCount > 0) {
        this.showToast('Warning', `${failedCount} requirement(s) could not be deleted. You may need to delete them manually.`, 'warning');
      }

      // Clear created requirements
      this.createdRequirements = [];
      this.showSummary = false;
      this.isLoading = false;
    }

    // Dispatch back event
    this.dispatchBackEvent();
  }
}
