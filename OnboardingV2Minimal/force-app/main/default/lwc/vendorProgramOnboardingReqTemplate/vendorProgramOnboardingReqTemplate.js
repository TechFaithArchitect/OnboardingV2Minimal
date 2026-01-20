import { track, api } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import createOnboardingRequirementTemplate from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingRequirementTemplate';
import updateOnboardingRequirementTemplate from '@salesforce/apex/VendorOnboardingWizardController.updateOnboardingRequirementTemplate';
import getAllVendorProgramRequirementGroups from '@salesforce/apex/VendorOnboardingWizardController.getAllVendorProgramRequirementGroups';
import getRequirementTemplatesForSet from '@salesforce/apex/VendorOnboardingWizardController.getRequirementTemplatesForSet';
import updateRequirementTemplateGroupLinks from '@salesforce/apex/VendorOnboardingWizardController.updateRequirementTemplateGroupLinks';
import createVendorProgramRequirementGroup from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRequirementGroup';
import getStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getStatusPicklistValues';
import getAvailableOnboardingStatusFields from '@salesforce/apex/VendorOnboardingWizardController.getAvailableOnboardingStatusFields';
import getAvailableOnboardingStatusFieldsForEdit from '@salesforce/apex/VendorOnboardingWizardController.getAvailableOnboardingStatusFieldsForEdit';
import getPicklistValuesForOnboardingField from '@salesforce/apex/VendorOnboardingWizardController.getPicklistValuesForOnboardingField';
import isCurrentUserAdmin from '@salesforce/apex/VendorOnboardingWizardController.isCurrentUserAdmin';

export default class VendorProgramOnboardingReqTemplate extends OnboardingStepBase {
  stepName = 'Create Requirement Template';
  
  @api vendorProgramId;
  @api stageId;
  @api requirementSetId; // From previous step
  @api requirementGroupId; // From Step 4 - auto-selected Requirement Group

  @track newTemplate = {
    Requirement_Label__c: '',
    Requirement_Type__c: 'Document',
    Status__c: 'Active',
    Category_Group__c: null,
    Is_Current_Version__c: true,
    Onboarding_Status_Field_API_Name__c: '',
    Onboarding_Status_Value_When_Complete__c: '',
    Onboarding_Status_Value_When_Denied__c: '',
    Description__c: '',
    Default_Status_Options__c: null,
    Version__c: null,
    Previous_Version__c: null,
    Active__c: false
  };
  
  @track allRequirementGroups = []; // All available groups (for dropdown)
  @track selectedGroupId = '';
  @track selectedGroupName = ''; // Track name for display
  @track nextDisabled = true;
  @track isLoading = false;
  @track isLoadingGroups = true; // Track loading state for groups
  @track templates = []; // All templates in this Requirement Set
  @track selectedTemplateIds = []; // Templates linked to the selected Requirement Group
  @track previousSelectedTemplateIds = []; // Track previous selection to detect changes
  @track lastCreatedTemplateId = null; // Track the last template created in this session
  @track autoLinkNewTemplates = true; // Auto-link new templates to selected group
  @track showCreateGroupForm = false; // Show/hide create group form
  @track newGroupName = ''; // Name for new group
  @track newGroupStatus = 'Active'; // Status for new group
  @track statusOptions = []; // Status picklist options for new group
  @track isCreatingGroup = false; // Track if group is being created
  @track availableOnboardingFields = []; // Available Onboarding__c status fields
  @track selectedOnboardingFieldApiName = ''; // Selected Onboarding__c field API name
  @track onboardingFieldPicklistValues = []; // Picklist values for selected field
  @track selectedCompletionStatusValues = []; // Selected completion status values (for dual-listbox)
  @track selectedDeniedStatusValues = []; // Selected denied status values (for dual-listbox)
  @track isLoadingOnboardingFields = false;
  @track isLoadingPicklistValues = false;
  @track isAdmin = false; // Track if current user is admin
  @track editingTemplateId = null; // Track which template is being edited (null = creating new)
  @track showEditForm = false; // Show/hide edit form

  requirementTypeOptions = [
    { label: 'Document', value: 'Document' },
    { label: 'Status', value: 'Status' },
    { label: 'Training', value: 'Training' },
    { label: 'Credential', value: 'Credential' }
  ];

  async connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    await this.checkAdminStatus();
    this.validateForm();
    this.loadAllRequirementGroups();
    this.loadStatusOptions();
    if (this.isAdmin) {
      this.loadAvailableOnboardingFields();
    }
    if (this.requirementSetId) {
      this.loadTemplates();
    }
    
    // Auto-select group from Step 4 if provided (will be set when groups load)
    // Note: The actual selection happens in loadAllRequirementGroups() after groups are loaded
    // This is just a placeholder - the real selection happens in loadAllRequirementGroups()
    if (this.requirementGroupId) {
      // Store for later use in loadAllRequirementGroups()
      // Don't set selectedGroupId here as groups haven't loaded yet
    }
    
    // Dispatch initial validation state after a delay to ensure component is ready
    // Note: This will be false initially if no group is selected, which is correct
    setTimeout(() => {
      this.dispatchValidationState();
    }, 100);
  }

  async handleFooterNextClick() {
    // Override: async logic needed to save pending template group links
    if (this.canProceed) {
      await this.handleNext();
    } else {
      // Provide feedback when Next is clicked but validation fails
      if (!this.selectedGroupId) {
        this.showToast('Required Field Missing', 'Please select a Requirement Group to continue.', 'warning');
      }
      // Ensure validation state is dispatched
      this.dispatchValidationState();
    }
  }

  async handleFooterBackClick() {
    // Override: async logic needed to save pending template group links
    await this.handleBack();
  }

  async loadStatusOptions() {
    try {
      const statusOptionsData = await getStatusPicklistValues();
      this.statusOptions = statusOptionsData || [
        { label: 'Active', value: 'Active' },
        { label: 'Inactive', value: 'Inactive' },
        { label: 'Draft', value: 'Draft' }
      ];
    } catch (error) {
      this.handleError(error, 'Failed to load status picklist values');
      // Use default options
      this.statusOptions = [
        { label: 'Active', value: 'Active' },
        { label: 'Inactive', value: 'Inactive' },
        { label: 'Draft', value: 'Draft' }
      ];
    }
  }

  async loadAllRequirementGroups() {
    this.isLoadingGroups = true;
    try {
      const allGroups = await getAllVendorProgramRequirementGroups();
      this.allRequirementGroups = Array.isArray(allGroups) ? allGroups : [];
      
      // If requirementGroupId was provided, find and select it
      if (this.requirementGroupId && this.allRequirementGroups.length > 0) {
        const preSelectedGroup = this.allRequirementGroups.find(g => g.Id === this.requirementGroupId);
        if (preSelectedGroup) {
          this.selectedGroupId = preSelectedGroup.Id;
          this.selectedGroupName = preSelectedGroup.Name;
          this.newTemplate.Category_Group__c = preSelectedGroup.Id;
          // Update selected templates for this group
          if (this.templates.length > 0) {
            this.updateSelectedTemplatesForGroup();
          }
        }
      }
    } catch (error) {
      this.handleError(error, 'Failed to load requirement groups');
      this.allRequirementGroups = [];
    } finally {
      this.isLoadingGroups = false;
      // Always dispatch validation state after groups are loaded
      // Use setTimeout to ensure reactive updates are complete
      setTimeout(() => {
        this.dispatchValidationState();
      }, 0);
    }
  }

  async loadTemplates() {
    if (!this.requirementSetId) {
      return;
    }

    this.isLoading = true;
    try {
      const templateResults = await getRequirementTemplatesForSet({ requirementSetId: this.requirementSetId });
      // Force reactivity by creating a new array
      this.templates = Array.isArray(templateResults) ? [...templateResults] : [];
      
      // If a Requirement Group is selected, update selectedTemplateIds to show linked templates
      if (this.selectedGroupId) {
        this.updateSelectedTemplatesForGroup();
      }
    } catch (error) {
      this.handleError(error, 'Failed to load requirement templates');
      this.templates = [];
    } finally {
      this.isLoading = false;
    }
  }

  updateSelectedTemplatesForGroup() {
    // Find templates that are linked to the selected Requirement Group
    this.selectedTemplateIds = this.templates
      .filter(template => template.Category_Group__c === this.selectedGroupId)
      .map(template => template.Id);
    this.previousSelectedTemplateIds = [...this.selectedTemplateIds];
  }

  handleFieldChange(event) {
    const field = event.target;
    const name = field.name;
    const value = field.type === 'checkbox' ? field.checked : field.value;
    
    this.newTemplate = {
      ...this.newTemplate,
      [name]: value
    };
    
    // DRY Pattern: When Status = 'Active', set Active__c = true
    if (name === 'Status__c' && value === 'Active') {
      this.newTemplate.Active__c = true;
    } else if (name === 'Status__c' && value !== 'Active') {
      // When Status changes away from Active, set Active__c = false
      this.newTemplate.Active__c = false;
    }
    
    this.validateForm();
  }

  async handleGroupSelect(event) {
    const newSelectedGroupId = event.detail.value;
    
    // Save previous selection before changing (if async, await it)
    if (this.selectedGroupId && this.previousSelectedTemplateIds.length > 0) {
      await this.saveTemplateGroupLinks(this.selectedGroupId, this.previousSelectedTemplateIds);
    }
    
    // Find the selected group name
    const selectedGroup = this.allRequirementGroups.find(g => g.Id === newSelectedGroupId);
    this.selectedGroupId = newSelectedGroupId;
    this.selectedGroupName = selectedGroup ? selectedGroup.Name : '';
    
    this.newTemplate = {
      ...this.newTemplate,
      Category_Group__c: this.selectedGroupId
    };
    
    // Dispatch validation state immediately when group is selected
    this.dispatchValidationState();
    
    // Update selected templates to show which ones are linked to this group
    this.updateSelectedTemplatesForGroup();
  }

  handleTemplateSelectionChange(event) {
    const newSelectedIds = event.detail.value || [];
    
    // Only update if the selection actually changed
    if (JSON.stringify(newSelectedIds.sort()) !== JSON.stringify(this.selectedTemplateIds.sort())) {
      this.selectedTemplateIds = newSelectedIds;
      
      // Auto-save when selection changes (if a group is selected)
      if (this.selectedGroupId) {
        this.saveTemplateGroupLinks(this.selectedGroupId, newSelectedIds);
      }
    }
  }

  handleAutoLinkChange(event) {
    this.autoLinkNewTemplates = event.target.checked;
  }

  async saveTemplateGroupLinks(requirementGroupId, selectedTemplateIds) {
    if (!requirementGroupId) {
      return;
    }

    // Determine which templates to link and which to unlink
    const previousIds = this.previousSelectedTemplateIds || [];
    const currentIds = selectedTemplateIds || [];
    
    const templateIdsToLink = currentIds.filter(id => !previousIds.includes(id));
    const templateIdsToUnlink = previousIds.filter(id => !currentIds.includes(id));

    // Only call Apex if there are changes
    if (templateIdsToLink.length === 0 && templateIdsToUnlink.length === 0) {
      return;
    }

    try {
      await updateRequirementTemplateGroupLinks({
        requirementGroupId: requirementGroupId,
        templateIdsToLink: templateIdsToLink,
        templateIdsToUnlink: templateIdsToUnlink
      });

      // Update local template data to reflect the changes
      this.templates = this.templates.map(template => {
        if (templateIdsToLink.includes(template.Id)) {
          return { ...template, Category_Group__c: requirementGroupId };
        } else if (templateIdsToUnlink.includes(template.Id)) {
          return { ...template, Category_Group__c: null };
        }
        return template;
      });

      // Update previous selection tracking
      this.previousSelectedTemplateIds = [...currentIds];
    } catch (error) {
      this.handleError(error, 'Failed to update template group links');
    }
  }

  validateForm() {
    const hasRequirementLabel = !!this.newTemplate.Requirement_Label__c?.trim();
    const hasRequirementSet = !!this.requirementSetId;
    // Note: nextDisabled is for the "Create Template" button, not "Continue"
    // Continue button validation is handled separately via canContinue getter
    this.nextDisabled = !(hasRequirementLabel && hasRequirementSet);
  }

  get canProceed() {
    // Continue requires a Requirement Group to be selected
    // Following DRY pattern - use nextDisabled for create button, canProceed for continue
    // For continue button, we need a group selected (different from create validation)
    return !!this.selectedGroupId;
  }

  get canContinue() {
    // Alias for backward compatibility with template
    return this.canProceed;
  }

  get cannotContinue() {
    // Inverse of canContinue for template binding
    return !this.canContinue;
  }

  async createTemplate() {
    if (!this.requirementSetId) {
      this.showToast('Error', 'Requirement Set ID is missing. Please go back and select a Requirement Set first.', 'error');
      return;
    }

    if (!this.newTemplate.Requirement_Label__c?.trim()) {
      this.showToast('Required Fields Missing', 'Please enter a Requirement Label.', 'warning');
      return;
    }

    // Check for duplicate templates (same Requirement_Label__c in the same Requirement Set)
    const trimmedLabel = this.newTemplate.Requirement_Label__c.trim();
    const duplicateTemplate = this.templates.find(
      t => t.Requirement_Label__c && t.Requirement_Label__c.trim().toLowerCase() === trimmedLabel.toLowerCase()
    );
    
    if (duplicateTemplate) {
      this.showToast('Duplicate Template', `A template with the label "${trimmedLabel}" already exists in this Requirement Set. Please use a different label.`, 'warning');
      return;
    }

    this.isLoading = true;

    try {
      // If auto-link is enabled and a group is selected, use that group
      const categoryGroupId = (this.autoLinkNewTemplates && this.selectedGroupId) 
        ? this.selectedGroupId 
        : (this.newTemplate.Category_Group__c || null);

      // Template creation - Onboarding_Requirement_Set__c is optional for many-to-many support
      // Link to requirement set(s) will be created via junction after template creation
      const templateToCreate = {
        // Note: Onboarding_Requirement_Set__c kept for backward compatibility with MD field
        // But junction records are the primary way to link templates to requirement sets
        Onboarding_Requirement_Set__c: this.requirementSetId || null, // Optional for many-to-many
        Requirement_Label__c: trimmedLabel,
        Requirement_Type__c: this.newTemplate.Requirement_Type__c || 'Document',
        Status__c: this.newTemplate.Status__c || 'Active',
        Category_Group__c: categoryGroupId,
        Is_Current_Version__c: this.newTemplate.Is_Current_Version__c !== false
      };

      // Add all fields
      templateToCreate.Description__c = this.newTemplate.Description__c || null;
      templateToCreate.Default_Status_Options__c = this.newTemplate.Default_Status_Options__c || null;
      // Version and Previous_Version are auto-set by trigger
      // Active__c is auto-set by trigger when Status = 'Active' (DRY pattern)
      templateToCreate.Active__c = this.newTemplate.Active__c !== null ? this.newTemplate.Active__c : false;

      // Only add mapping fields if user is admin
      if (this.isAdmin) {
        templateToCreate.Onboarding_Status_Field_API_Name__c = this.newTemplate.Onboarding_Status_Field_API_Name__c || null;
        templateToCreate.Onboarding_Status_Value_When_Complete__c = this.newTemplate.Onboarding_Status_Value_When_Complete__c || null;
        templateToCreate.Onboarding_Status_Value_When_Denied__c = this.newTemplate.Onboarding_Status_Value_When_Denied__c || null;
      }

      const templateId = await createOnboardingRequirementTemplate({ 
        template: templateToCreate
      });

      // Junction record is created automatically by the service if Onboarding_Requirement_Set__c was provided
      // If we need to link to additional requirement sets later, we can use linkTemplateToRequirementSets

      this.showToast('Success', 'Requirement Template created successfully and added to Available Templates!', 'success');

      // Store the created template ID (for the last one created, in case user wants to continue)
      this.lastCreatedTemplateId = templateId;
      
      // Reload templates to include the newly created one
      // Add a small delay to ensure database commit, then reload
      await new Promise(resolve => setTimeout(resolve, 200));
      await this.loadTemplates();

      // If auto-link is enabled and a group is selected, automatically add the new template to it
      if (this.autoLinkNewTemplates && this.selectedGroupId) {
        // Wait a moment for the template to be in the list, then add it
        const newTemplateInList = this.templates.find(t => t.Id === templateId);
        if (newTemplateInList) {
          this.selectedTemplateIds = [...this.selectedTemplateIds, templateId];
          this.previousSelectedTemplateIds = [...this.selectedTemplateIds];
          await this.saveTemplateGroupLinks(this.selectedGroupId, this.selectedTemplateIds);
        }
      }

      // Clear the form so user can create another template
      this.resetTemplateForm();
    } catch (err) {
      this.handleError(err, 'Failed to create requirement template');
    } finally {
      this.isLoading = false;
    }
  }

  handleCreateTemplate() {
    // Create template and stay on page (don't proceed to next step)
    this.createTemplate();
  }

  async handleNext() {
    // Save any pending template group links before proceeding
    if (this.selectedGroupId && JSON.stringify(this.selectedTemplateIds.sort()) !== JSON.stringify(this.previousSelectedTemplateIds.sort())) {
      await this.saveTemplateGroupLinks(this.selectedGroupId, this.selectedTemplateIds);
    }
    
    // Proceed to next step (user can continue even if they haven't created any templates)
    this.proceedToNext();
  }

  proceedToNext() {
    // Pass the last created template ID if available, otherwise just pass requirementSetId
    // Also pass the selected Requirement Group ID so Step 6 can auto-select it
    this.dispatchNextEvent({
      requirementTemplateId: this.lastCreatedTemplateId || null,
      requirementSetId: this.requirementSetId,
      requirementGroupId: this.selectedGroupId || null,
      vendorProgramId: this.vendorProgramId
    });
  }

  async handleBack() {
    // Save any pending template group links before going back
    if (this.selectedGroupId && JSON.stringify(this.selectedTemplateIds.sort()) !== JSON.stringify(this.previousSelectedTemplateIds.sort())) {
      await this.saveTemplateGroupLinks(this.selectedGroupId, this.selectedTemplateIds);
    }
    this.dispatchBackEvent();
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
        this.newTemplate.Category_Group__c = newGroupId;
        this.dispatchValidationState();
        // Update selected templates for this group
        if (this.templates.length > 0) {
          this.updateSelectedTemplatesForGroup();
        }
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
    const options = this.allRequirementGroups
      .filter(g => g && g.Id && g.Name) // Filter out any invalid entries
      .map(g => ({
        label: g.Name || 'Unnamed Group',
        value: g.Id
      }));
    return options;
  }

  get hasSelectedGroup() {
    return !!this.selectedGroupId;
  }

  get hasRequirementGroups() {
    return this.allRequirementGroups && this.allRequirementGroups.length > 0;
  }

  get templateOptions() {
    return this.templates.map(template => ({
      label: `${template.Requirement_Label__c || 'Unnamed'} (${template.Requirement_Type__c || 'Unknown'})`,
      value: template.Id
    }));
  }

  get hasTemplates() {
    return this.templates && this.templates.length > 0;
  }

  get isDualListboxDisabled() {
    return !this.hasSelectedGroup;
  }

  get isGroupFromStep4() {
    return this.requirementGroupId && this.selectedGroupId === this.requirementGroupId;
  }


  get isCreateGroupButtonDisabled() {
    return !this.canCreateGroup || this.isCreatingGroup;
  }

  get isCancelGroupButtonDisabled() {
    return this.isCreatingGroup;
  }

  async loadAvailableOnboardingFields(excludeTemplateId = null) {
    this.isLoadingOnboardingFields = true;
    try {
      let fields;
      if (excludeTemplateId) {
        // When editing, exclude current template so its mapped field is available
        console.log('Loading fields for edit mode, excluding template:', excludeTemplateId);
        fields = await getAvailableOnboardingStatusFieldsForEdit({ templateId: excludeTemplateId });
      } else {
        console.log('Loading fields for create mode');
        fields = await getAvailableOnboardingStatusFields();
      }
      console.log('Available fields returned:', fields);
      this.availableOnboardingFields = Array.isArray(fields) ? fields : [];
      console.log('Set availableOnboardingFields to:', this.availableOnboardingFields.length, 'fields');
      
      if (this.availableOnboardingFields.length === 0) {
        console.warn('No available fields found. Check if Onboarding__c has any picklist fields with "Status" in the name.');
        this.showToast('Info', 'No status fields available. You may need to create picklist fields on the Onboarding__c object that contain "Status" in the name.', 'info');
      }
    } catch (error) {
      console.error('Error loading available Onboarding status fields:', error);
      this.handleError(error, 'Failed to load available Onboarding status fields');
      this.availableOnboardingFields = [];
    } finally {
      this.isLoadingOnboardingFields = false;
    }
  }

  get onboardingFieldOptions() {
    // Start with empty option so dropdown is always usable
    const options = [{
      label: '-- None --',
      value: ''
    }];
    
    // Add available fields
    const fieldOptions = this.availableOnboardingFields.map(field => ({
      label: `${field.label} (${field.apiName})`,
      value: field.apiName
    }));
    options.push(...fieldOptions);
    
    // If editing and current field is selected but not in available fields
    // ensure it's still in the options so user can see what's currently mapped
    if (this.selectedOnboardingFieldApiName && this.editingTemplateId) {
      const hasCurrentField = options.some(opt => opt.value === this.selectedOnboardingFieldApiName);
      if (!hasCurrentField && this.newTemplate.Onboarding_Status_Field_API_Name__c) {
        // Add current field to options even if not in available list (indicates it's already mapped to this template)
        options.push({
          label: `${this.newTemplate.Onboarding_Status_Field_API_Name__c} (Currently Mapped)`,
          value: this.selectedOnboardingFieldApiName
        });
      }
    }
    
    return options;
  }

  async loadPicklistValuesForField(fieldApiName) {
    if (!fieldApiName) {
      this.onboardingFieldPicklistValues = [];
      return;
    }
    
    this.isLoadingPicklistValues = true;
    try {
      const picklistData = await getPicklistValuesForOnboardingField({ fieldApiName: fieldApiName });
      this.onboardingFieldPicklistValues = Array.isArray(picklistData) ? picklistData : [];
    } catch (error) {
      this.handleError(error, 'Failed to load picklist values for field');
      this.onboardingFieldPicklistValues = [];
    } finally {
      this.isLoadingPicklistValues = false;
    }
  }

  get completionStatusOptions() {
    return this.onboardingFieldPicklistValues.map(entry => ({
      label: entry.label || entry.value,
      value: entry.value
    }));
  }

  handleCompletionStatusChange(event) {
    const selectedValues = event.detail.value || [];
    this.selectedCompletionStatusValues = selectedValues;
    
    // Store as semicolon-separated string
    const semicolonSeparated = selectedValues.join(';');
    this.newTemplate = {
      ...this.newTemplate,
      Onboarding_Status_Value_When_Complete__c: semicolonSeparated
    };
  }

  get showFieldMappingSection() {
    return this.selectedOnboardingFieldApiName && this.onboardingFieldPicklistValues.length > 0;
  }

  get hasFieldMapping() {
    return !!this.selectedOnboardingFieldApiName;
  }

  async checkAdminStatus() {
    try {
      this.isAdmin = await isCurrentUserAdmin();
    } catch (error) {
      // Default to non-admin on error for security
      this.isAdmin = false;
      this.handleError(error, 'Failed to check admin status');
    }
  }

  get showFieldMappingUI() {
    return this.isAdmin;
  }

  get hasAvailableOnboardingFields() {
    return this.availableOnboardingFields && this.availableOnboardingFields.length > 0;
  }

  resetTemplateForm() {
    this.newTemplate = {
      Requirement_Label__c: '',
      Requirement_Type__c: 'Document',
      Status__c: 'Active',
      Category_Group__c: this.selectedGroupId || null,
      Is_Current_Version__c: true,
      Onboarding_Status_Field_API_Name__c: '',
      Onboarding_Status_Value_When_Complete__c: '',
      Onboarding_Status_Value_When_Denied__c: '',
      Description__c: '',
      Default_Status_Options__c: null,
      Version__c: null,
      Previous_Version__c: null,
      Active__c: false
    };
    this.editingTemplateId = null;
    this.showEditForm = false;
    // Reset field mapping (only if admin)
    if (this.isAdmin) {
      this.selectedOnboardingFieldApiName = '';
      this.onboardingFieldPicklistValues = [];
      this.selectedCompletionStatusValues = [];
      this.selectedDeniedStatusValues = [];
    } else {
      // Ensure mapping fields are cleared for non-admin users
      this.newTemplate.Onboarding_Status_Field_API_Name__c = '';
      this.newTemplate.Onboarding_Status_Value_When_Complete__c = '';
      this.newTemplate.Onboarding_Status_Value_When_Denied__c = '';
    }
    this.validateForm();
  }

  async handleOnboardingFieldChange(event) {
    const selectedApiName = event.detail.value;
    this.selectedOnboardingFieldApiName = selectedApiName;
    
    // Update template field
    this.newTemplate = {
      ...this.newTemplate,
      Onboarding_Status_Field_API_Name__c: selectedApiName || ''
    };
    
    // Reset selected values when field changes
    this.selectedCompletionStatusValues = [];
    this.selectedDeniedStatusValues = [];
    this.onboardingFieldPicklistValues = [];
    
    // Load picklist values for the selected field
    if (selectedApiName) {
      await this.loadPicklistValuesForField(selectedApiName);
      
      // Pre-populate if there's existing data (for edit mode)
      if (this.newTemplate.Onboarding_Status_Value_When_Complete__c) {
        const existingValues = this.newTemplate.Onboarding_Status_Value_When_Complete__c.split(';').map(v => v.trim()).filter(v => v);
        this.selectedCompletionStatusValues = existingValues;
      }
      if (this.newTemplate.Onboarding_Status_Value_When_Denied__c) {
        const existingDeniedValues = this.newTemplate.Onboarding_Status_Value_When_Denied__c.split(';').map(v => v.trim()).filter(v => v);
        this.selectedDeniedStatusValues = existingDeniedValues;
      }
    }
  }

  async handleEditTemplate(event) {
    const templateId = event.currentTarget.dataset.id;
    const template = this.templates.find(t => t.Id === templateId);
    
    if (!template) {
      this.showToast('Error', 'Template not found.', 'error');
      return;
    }

    // Populate form with template data
    this.editingTemplateId = templateId;
    this.showEditForm = true;
    this.newTemplate = {
      Id: template.Id,
      Requirement_Label__c: template.Requirement_Label__c || '',
      Requirement_Type__c: template.Requirement_Type__c || 'Document',
      Status__c: template.Status__c || 'Active',
      Category_Group__c: template.Category_Group__c || null,
      Is_Current_Version__c: template.Is_Current_Version__c !== false,
      Onboarding_Status_Field_API_Name__c: template.Onboarding_Status_Field_API_Name__c || '',
      Onboarding_Status_Value_When_Complete__c: template.Onboarding_Status_Value_When_Complete__c || '',
      Onboarding_Status_Value_When_Denied__c: template.Onboarding_Status_Value_When_Denied__c || '',
      Description__c: template.Description__c || '',
      Default_Status_Options__c: template.Default_Status_Options__c || null,
      Version__c: template.Version__c || null,
      Previous_Version__c: template.Previous_Version__c || null,
      Active__c: template.Active__c !== null ? template.Active__c : false
    };

    // Load field mapping data if admin
    if (this.isAdmin) {
      // Always set selectedOnboardingFieldApiName even if empty, so dropdown can be used
      this.selectedOnboardingFieldApiName = this.newTemplate.Onboarding_Status_Field_API_Name__c || '';
      
      // Load available fields, excluding current template so its mapped field is available
      await this.loadAvailableOnboardingFields(this.editingTemplateId);
      
      // If field is already mapped, load picklist values
      if (this.selectedOnboardingFieldApiName) {
        await this.loadPicklistValuesForField(this.selectedOnboardingFieldApiName);
        
        // Set selected values from existing template
        if (this.newTemplate.Onboarding_Status_Value_When_Complete__c) {
          const existingCompleteValues = this.newTemplate.Onboarding_Status_Value_When_Complete__c
            .split(';')
            .map(v => v.trim())
            .filter(v => v);
          this.selectedCompletionStatusValues = existingCompleteValues;
        }
        if (this.newTemplate.Onboarding_Status_Value_When_Denied__c) {
          const existingDeniedValues = this.newTemplate.Onboarding_Status_Value_When_Denied__c
            .split(';')
            .map(v => v.trim())
            .filter(v => v);
          this.selectedDeniedStatusValues = existingDeniedValues;
        }
      } else {
        // Clear picklist values if no field selected
        this.onboardingFieldPicklistValues = [];
        this.selectedCompletionStatusValues = [];
        this.selectedDeniedStatusValues = [];
      }
    }

    this.validateForm();
    // Scroll to top of form
    this.template.querySelector('.slds-p-around_medium')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  handleCancelEdit() {
    this.resetTemplateForm();
  }

  async handleSaveEdit() {
    if (!this.editingTemplateId) {
      return;
    }

    if (!this.newTemplate.Requirement_Label__c?.trim()) {
      this.showToast('Required Fields Missing', 'Please enter a Requirement Label.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      // Get the existing template to preserve required fields
      const existingTemplate = this.templates.find(t => t.Id === this.editingTemplateId);
      if (!existingTemplate) {
        this.showToast('Error', 'Template not found.', 'error');
        this.isLoading = false;
        return;
      }

      const templateToUpdate = {
        Id: this.editingTemplateId,
        Onboarding_Requirement_Set__c: existingTemplate.Onboarding_Requirement_Set__c, // Preserve required field
        Requirement_Label__c: this.newTemplate.Requirement_Label__c.trim(),
        Requirement_Type__c: this.newTemplate.Requirement_Type__c || 'Document',
        Status__c: this.newTemplate.Status__c || 'Active',
        Category_Group__c: this.newTemplate.Category_Group__c || null,
        Is_Current_Version__c: this.newTemplate.Is_Current_Version__c !== false,
        Description__c: this.newTemplate.Description__c || null,
        Default_Status_Options__c: this.newTemplate.Default_Status_Options__c || null,
        Active__c: this.newTemplate.Active__c !== null ? this.newTemplate.Active__c : false
      };

      // Version and Previous_Version are auto-set by trigger
      // Active__c is auto-set by trigger when Status = 'Active' (DRY pattern)

      // Only add mapping fields if user is admin
      if (this.isAdmin) {
        templateToUpdate.Onboarding_Status_Field_API_Name__c = this.selectedOnboardingFieldApiName || this.newTemplate.Onboarding_Status_Field_API_Name__c || null;
        
        // Convert array values to semicolon-separated strings
        if (this.selectedCompletionStatusValues && this.selectedCompletionStatusValues.length > 0) {
          templateToUpdate.Onboarding_Status_Value_When_Complete__c = this.selectedCompletionStatusValues.join(';');
        } else {
          templateToUpdate.Onboarding_Status_Value_When_Complete__c = this.newTemplate.Onboarding_Status_Value_When_Complete__c || null;
        }
        
        if (this.selectedDeniedStatusValues && this.selectedDeniedStatusValues.length > 0) {
          templateToUpdate.Onboarding_Status_Value_When_Denied__c = this.selectedDeniedStatusValues.join(';');
        } else {
          templateToUpdate.Onboarding_Status_Value_When_Denied__c = this.newTemplate.Onboarding_Status_Value_When_Denied__c || null;
        }
      }

      await updateOnboardingRequirementTemplate({ template: templateToUpdate });

      this.showToast('Success', 'Requirement Template updated successfully!', 'success');

      // Reload templates
      await new Promise(resolve => setTimeout(resolve, 200));
      await this.loadTemplates();

      // Reset form
      this.resetTemplateForm();
    } catch (err) {
      this.handleError(err, 'Failed to update requirement template');
    } finally {
      this.isLoading = false;
    }
  }

  handleDeniedStatusChange(event) {
    const selectedValues = event.detail.value || [];
    this.selectedDeniedStatusValues = selectedValues;
    
    // Store as semicolon-separated string
    const semicolonSeparated = selectedValues.join(';');
    this.newTemplate = {
      ...this.newTemplate,
      Onboarding_Status_Value_When_Denied__c: semicolonSeparated
    };
  }

  get isEditing() {
    return !!this.editingTemplateId;
  }

  get formTitle() {
    return this.isEditing ? 'Edit Requirement Template' : 'Create a New Requirement Template';
  }

  get saveButtonLabel() {
    return this.isEditing ? 'Save Changes' : 'Create Template';
  }

  get activeCheckboxDisabled() {
    return this.newTemplate.Status__c === 'Active';
  }
}
