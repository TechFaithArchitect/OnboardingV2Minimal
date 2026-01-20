import { track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import OnboardingStepBase from 'c/onboardingStepBase';
import getAllVendorProgramRequirementGroups from '@salesforce/apex/VendorOnboardingWizardController.getAllVendorProgramRequirementGroups';
import getVendorProgramRequirementGroupForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramRequirementGroupForVendorProgram';
import createRequirementGroup from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRequirementGroup';
import getStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getStatusPicklistValues';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';

export default class VendorProgramOnboardingVendorProgramRequirementGroup extends OnboardingStepBase {
  stepName = 'Select or Create Requirement Group';
  
  @api vendorProgramId; // From flow engine
  @api requirementGroupId; // From Step 5 - auto-selected Requirement Group

  @track allGroups = []; // All available groups (for dropdown)
  @track selectedGroupId = ''; // Selected Requirement Group
  @track selectedGroupName = ''; // Track name for display
  @track isLoadingGroups = true; // Track loading state for groups
  @track showCreateGroupForm = false; // Show/hide create group form
  @track newGroupName = ''; // Name for new group
  @track newGroupStatus = 'Active'; // Status for new group
  @track statusOptions = []; // Status picklist options
  @track isCreatingGroup = false; // Track if group is being created
  @track existingRequirements = []; // Requirements from Step 6 for context
  @track isLoadingRequirements = false; // Track loading state for requirements
  @track pendingGroupId = null; // Store group ID to auto-select once groups are loaded

  @wire(getAllVendorProgramRequirementGroups)
  wiredAllGroups(result) {
    this.wiredAllGroupsResult = result; // Store result for refreshApex
    this.isLoadingGroups = false;
    const { error, data } = result;
    if (data) {
      this.allGroups = data || [];
      // After groups are loaded, check if we should auto-select an existing group
      setTimeout(() => {
        this.autoSelectExistingGroup();
      }, 0);
    } else if (error) {
      this.handleError(error, 'Failed to load Requirement Groups');
      this.allGroups = [];
    }
  }

  @wire(getStatusPicklistValues)
  wiredStatusOptions({ error, data }) {
    if (data) {
      this.statusOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Status picklist values');
      this.statusOptions = [{ label: 'Active', value: 'Active' }];
    }
  }

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    this.loadExistingRequirements();
    
    // If requirementGroupId is provided from Step 5, use it immediately
    if (this.requirementGroupId) {
      this.pendingGroupId = this.requirementGroupId;
    } else {
      // Otherwise, try to load from the vendor program
      this.loadExistingGroup();
    }
  }

  // Override base class - following DRY pattern
  get canProceed() {
    return !this.nextDisabled;
  }

  renderedCallback() {
    // React to requirementGroupId changes
    if (this.requirementGroupId && !this.selectedGroupId && this.allGroups.length > 0) {
      this.autoSelectGroupById(this.requirementGroupId);
    }
  }

  async loadExistingGroup() {
    if (!this.vendorProgramId) {
      return;
    }

    try {
      const existingGroupId = await getVendorProgramRequirementGroupForVendorProgram({ 
        vendorProgramId: this.vendorProgramId 
      });
      
      if (existingGroupId) {
        if (this.allGroups.length > 0) {
          this.autoSelectGroupById(existingGroupId);
        } else {
          this.pendingGroupId = existingGroupId;
        }
      }
    } catch (error) {
      this.handleError(error, 'Failed to load existing Requirement Group');
    }
  }

  autoSelectExistingGroup() {
    // Priority: requirementGroupId from Step 5 > pendingGroupId > load from vendor program
    if (this.requirementGroupId) {
      this.autoSelectGroupById(this.requirementGroupId);
      return;
    }
    
    if (this.pendingGroupId) {
      this.autoSelectGroupById(this.pendingGroupId);
      this.pendingGroupId = null;
      return;
    }
    
    // If no pending group but we have vendorProgramId and no selection, load it
    if (this.vendorProgramId && !this.selectedGroupId && this.allGroups.length > 0) {
      this.loadExistingGroup();
    }
  }

  autoSelectGroupById(groupId) {
    if (!groupId) {
      return;
    }
    
    if (!this.allGroups || this.allGroups.length === 0) {
      this.pendingGroupId = groupId;
      return;
    }

    const group = this.allGroups.find(g => g.Id === groupId);
    
    if (group) {
      this.selectedGroupId = group.Id;
      this.selectedGroupName = group.Name;
      this.validateForm();
    } else if (this.isDebugMode()) {
      console.warn('Requirement Group ID not found in loaded groups:', groupId);
    }
  }

  async loadExistingRequirements() {
    if (!this.vendorProgramId) {
      return;
    }

    this.isLoadingRequirements = true;
    try {
      const requirements = await getRequirementsForVendorProgram({ 
        vendorProgramId: this.vendorProgramId 
      });
      this.existingRequirements = requirements || [];
    } catch (error) {
      this.handleError(error, 'Failed to load existing requirements');
      this.existingRequirements = [];
    } finally {
      this.isLoadingRequirements = false;
    }
  }

  get groupOptions() {
    if (!this.allGroups || this.allGroups.length === 0) {
      return [];
    }
    try {
      return this.allGroups.map(group => ({
        label: `${group.Name}${group.Status__c ? ' (' + group.Status__c + ')' : ''}`,
        value: group.Id
      }));
    } catch (error) {
      if (this.isDebugMode()) {
        console.error('Error in groupOptions getter:', error);
      }
      return [];
    }
  }

  handleGroupSelect(event) {
    try {
      const selectedId = event.detail?.value;
      
      if (!selectedId) {
        this.selectedGroupId = '';
        this.selectedGroupName = '';
        this.validateForm();
        return;
      }

      const selectedGroup = this.allGroups?.find(g => g.Id === selectedId);
      
      if (!selectedGroup) {
        if (this.isDebugMode()) {
          console.warn('Selected group not found in allGroups. SelectedId:', selectedId);
        }
        this.selectedGroupId = '';
        this.selectedGroupName = '';
        this.validateForm();
        return;
      }

      this.selectedGroupId = selectedId;
      this.selectedGroupName = selectedGroup.Name || '';
      
      // Clear create form when selecting existing group
      this.showCreateGroupForm = false;
      this.newGroupName = '';
      this.newGroupStatus = 'Active';
      
      this.validateForm();
    } catch (error) {
      this.handleError(error, 'An error occurred while selecting the group');
    }
  }

  toggleCreateGroupForm() {
    this.showCreateGroupForm = !this.showCreateGroupForm;
    if (!this.showCreateGroupForm) {
      this.newGroupName = '';
      this.newGroupStatus = 'Active';
    } else {
      // Clear selection when showing create form
      this.selectedGroupId = '';
      this.selectedGroupName = '';
    }
    this.validateForm();
  }

  handleNewGroupChange(event) {
    this.newGroupName = event.target.value;
    this.validateForm();
  }

  handleStatusChange(event) {
    this.newGroupStatus = event.detail.value;
    this.validateForm();
  }

  validateForm() {
    // Dispatch validation state whenever form state changes
    this.dispatchValidationState();
  }


  async handleCreateGroup() {
    if (!this.newGroupName?.trim() || !this.newGroupStatus) {
      this.showToast('Required Fields Missing', 'Please fill in Name and Status.', 'warning');
      return;
    }

    this.isCreatingGroup = true;
    try {
      const groupId = await createRequirementGroup({ 
        vendorProgramRequirementGroup: { 
          Name: this.newGroupName.trim(),
          Status__c: this.newGroupStatus
        } 
      });
      
      this.selectedGroupId = groupId;
      
      // Refresh groups list to include the newly created group
      if (this.wiredAllGroupsResult) {
        await refreshApex(this.wiredAllGroupsResult);
      }
      
      // Find the newly created group in the refreshed list
      const newGroup = this.allGroups.find(g => g.Id === groupId) || { Name: this.newGroupName.trim() };
      this.selectedGroupName = newGroup.Name;
      
      this.showCreateGroupForm = false;
      this.newGroupName = '';
      this.newGroupStatus = 'Active';
      
      this.showToast('Success', 'Requirement Group created successfully!', 'success');
      this.validateForm();
    } catch (error) {
      this.handleError(error, 'Failed to create Requirement Group');
    } finally {
      this.isCreatingGroup = false;
    }
  }

  get nextDisabled() {
    return !this.selectedGroupId && !(this.newGroupName?.trim() && this.newGroupStatus);
  }

  get hasExistingRequirements() {
    return this.existingRequirements && this.existingRequirements.length > 0;
  }

  get hasNoGroups() {
    return !this.isLoadingGroups && this.allGroups.length === 0;
  }

  get isCreateGroupButtonDisabled() {
    return !this.newGroupName?.trim() || !this.newGroupStatus || this.isCreatingGroup;
  }

  get wasAutoSelectedFromStep5() {
    return this.requirementGroupId && this.selectedGroupId === this.requirementGroupId;
  }

  proceedToNext() {
    if (!this.selectedGroupId) {
      this.showToast('Selection Required', 'Please select or create a Requirement Group before proceeding.', 'warning');
      return;
    }
    this.dispatchNextEvent({
      requirementGroupId: this.selectedGroupId
    });
  }
}

