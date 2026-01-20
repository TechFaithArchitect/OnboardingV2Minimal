import { track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import OnboardingStepBase from 'c/onboardingStepBase';
import getAllVendorProgramGroups from '@salesforce/apex/VendorOnboardingWizardController.getAllVendorProgramGroups';
import getVendorProgramGroupForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramGroupForVendorProgram';
import createProgramGroup from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramGroup';
import getLogicTypePicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getLogicTypePicklistValues';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';

export default class VendorProgramOnboardingVendorProgramGroup extends OnboardingStepBase {
  stepName = 'Select or Create Vendor Program Group';
  
  @api vendorProgramId; // From flow engine

  @track allGroups = []; // All available groups (for dropdown)
  @track selectedGroupId = ''; // Selected Vendor Program Group
  @track selectedGroupName = ''; // Track name for display
  @track isLoadingGroups = true; // Track loading state for groups
  @track showCreateGroupForm = false; // Show/hide create group form
  @track newGroupName = ''; // Name for new group
  @track newGroupLabel = ''; // Label for new group
  @track newGroupLogicType = ''; // Logic Type for new group
  @track logicTypeOptions = []; // Logic Type picklist options
  @track isCreatingGroup = false; // Track if group is being created
  @track existingRequirements = []; // Requirements from Step 6 for context
  @track isLoadingRequirements = false; // Track loading state for requirements
  @track pendingGroupId = null; // Store group ID to auto-select once groups are loaded

  @wire(getAllVendorProgramGroups)
  wiredAllGroups(result) {
    this.wiredAllGroupsResult = result; // Store result for refreshApex
    this.isLoadingGroups = false;
    const { error, data } = result;
    if (data) {
      this.allGroups = data || [];
      // After groups are loaded, check if we should auto-select an existing group
      // Use setTimeout to ensure DOM is ready
      setTimeout(() => {
        this.autoSelectExistingGroup();
      }, 0);
    } else if (error) {
      this.handleError(error, 'Failed to load Vendor Program Groups');
      this.allGroups = [];
    }
  }

  @wire(getLogicTypePicklistValues)
  wiredLogicTypeOptions({ error, data }) {
    if (data) {
      this.logicTypeOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Logic Type picklist values');
      // Fallback options
      this.logicTypeOptions = [
        { label: 'ALL', value: 'ALL' },
        { label: 'AND', value: 'AND' },
        { label: 'OR', value: 'OR' }
      ];
    }
  }

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    this.loadExistingRequirements();
    this.loadExistingGroup();
  }

  get canProceed() {
    return !this.nextDisabled;
  }

  renderedCallback() {
    // React to vendorProgramId changes
    if (this.vendorProgramId) {
      this.handleVendorProgramIdChange();
    }
  }

  handleVendorProgramIdChange() {
    // Load requirements when vendorProgramId is available
    if (this.vendorProgramId && this.existingRequirements.length === 0) {
      this.loadExistingRequirements();
    }
    // Also check for existing group
    if (this.vendorProgramId && !this.selectedGroupId) {
      this.loadExistingGroup();
    }
  }

  async loadExistingGroup() {
    if (!this.vendorProgramId) {
      return;
    }

    try {
      const existingGroupId = await getVendorProgramGroupForVendorProgram({ 
        vendorProgramId: this.vendorProgramId 
      });
      
      if (existingGroupId) {
        // Auto-select the group if it exists and groups are already loaded
        if (this.allGroups.length > 0) {
          this.autoSelectGroupById(existingGroupId);
        } else {
          // Store it to auto-select once groups are loaded
          this.pendingGroupId = existingGroupId;
        }
      }
    } catch (error) {
      this.handleError(error, 'Failed to load existing Vendor Program Group');
    }
  }

  async autoSelectExistingGroup() {
    // If we have a pending group ID from loadExistingGroup, select it now
    if (this.pendingGroupId) {
      this.autoSelectGroupById(this.pendingGroupId);
      this.pendingGroupId = null;
      return;
    }
    
    // If no pending group but we have vendorProgramId and no selection, load it
    if (this.vendorProgramId && !this.selectedGroupId && this.allGroups.length > 0) {
      await this.loadExistingGroup();
    }
  }

  autoSelectGroupById(groupId) {
    if (!groupId || !this.allGroups || this.allGroups.length === 0) {
      return;
    }

    const group = this.allGroups.find(g => g.Id === groupId);
    if (group) {
      // Use a small delay to ensure combobox is ready
      setTimeout(() => {
        this.selectedGroupId = group.Id;
        this.selectedGroupName = group.Label__c || group.Name;
        this.validateForm();
      }, 100);
    } else if (this.isDebugMode()) {
      console.warn('Vendor Program Group ID not found in loaded groups:', groupId);
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
        label: `${group.Label__c || group.Name} (${group.Logic_Type__c || 'N/A'})`,
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
      // lightning-combobox provides value in event.detail.value
      const selectedId = event.detail?.value;
      
      if (!selectedId) {
        this.selectedGroupId = '';
        this.selectedGroupName = '';
        this.validateForm();
        return;
      }

      // Find the selected group
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

      // Update selection - use simple assignment
      this.selectedGroupId = selectedId;
      this.selectedGroupName = selectedGroup.Label__c || selectedGroup.Name || '';
      
      // Clear create form when selecting existing group
      this.showCreateGroupForm = false;
      this.newGroupName = '';
      this.newGroupLabel = '';
      this.newGroupLogicType = '';
      
      this.validateForm();
    } catch (error) {
      this.handleError(error, 'An error occurred while selecting the group');
    }
  }

  toggleCreateGroupForm() {
    this.showCreateGroupForm = !this.showCreateGroupForm;
    if (!this.showCreateGroupForm) {
      // Clear form when hiding
      this.newGroupName = '';
      this.newGroupLabel = '';
      this.newGroupLogicType = '';
    } else {
      // Clear selection when showing create form
      this.selectedGroupId = '';
      this.selectedGroupName = '';
    }
    this.validateForm();
  }

  handleNewGroupNameChange(event) {
    this.newGroupName = event.target.value;
    // Auto-fill Label if empty
    if (!this.newGroupLabel && this.newGroupName?.trim()) {
      this.newGroupLabel = this.newGroupName.trim();
    }
    this.validateForm();
  }

  handleNewGroupLabelChange(event) {
    this.newGroupLabel = event.target.value;
    this.validateForm();
  }

  handleLogicTypeChange(event) {
    this.newGroupLogicType = event.detail.value;
    this.validateForm();
  }

  validateForm() {
    // Dispatch validation state whenever form state changes
    this.dispatchValidationState();
  }

  async handleCreateGroup() {
    // Validate required fields
    if (!this.newGroupName?.trim()) {
      this.showToast('Required Field Missing', 'Please enter a Group Name.', 'warning');
      return;
    }
    if (!this.newGroupLabel?.trim()) {
      this.showToast('Required Field Missing', 'Please enter a Label.', 'warning');
      return;
    }
    if (!this.newGroupLogicType) {
      this.showToast('Required Field Missing', 'Please select a Logic Type.', 'warning');
      return;
    }

    this.isCreatingGroup = true;
    try {
      const groupId = await createProgramGroup({ 
        vendorProgramGroup: { 
          Name: this.newGroupName.trim(),
          Label__c: this.newGroupLabel.trim(),
          Logic_Type__c: this.newGroupLogicType
        } 
      });
      
      // Refresh groups list (wire will update automatically, but we can manually refresh)
      // For now, just select the newly created group
      this.selectedGroupId = groupId;
      this.selectedGroupName = this.newGroupLabel.trim();
      this.showCreateGroupForm = false;
      this.newGroupName = '';
      this.newGroupLabel = '';
      this.newGroupLogicType = '';
      // nextDisabled is a getter, no need to set it
      
      this.showToast('Success', 'Vendor Program Group created successfully!', 'success');
      
      // Refresh groups list to include the newly created group
      if (this.wiredAllGroupsResult) {
        await refreshApex(this.wiredAllGroupsResult);
      }
    } catch (error) {
      this.handleError(error, 'Failed to create Vendor Program Group');
    } finally {
      this.isCreatingGroup = false;
    }
  }

  get nextDisabled() {
    return !this.selectedGroupId && !(
      this.newGroupName?.trim() &&
      this.newGroupLabel?.trim() &&
      this.newGroupLogicType
    );
  }

  get hasExistingRequirements() {
    return this.existingRequirements && this.existingRequirements.length > 0;
  }

  get hasNoGroups() {
    return !this.isLoadingGroups && this.allGroups.length === 0;
  }

  get isCreateGroupButtonDisabled() {
    return !this.newGroupName?.trim() || !this.newGroupLabel?.trim() || !this.newGroupLogicType || this.isCreatingGroup;
  }

  proceedToNext() {
    if (!this.selectedGroupId) {
      this.showToast('Selection Required', 'Please select or create a Vendor Program Group before proceeding.', 'warning');
      return;
    }
    this.dispatchNextEvent({
      programGroupId: this.selectedGroupId
    });
  }
}
