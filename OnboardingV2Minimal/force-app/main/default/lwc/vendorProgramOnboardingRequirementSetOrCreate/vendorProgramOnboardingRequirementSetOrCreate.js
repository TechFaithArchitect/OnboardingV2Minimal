import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchOnboardingRequirementSets from '@salesforce/apex/VendorOnboardingWizardController.searchOnboardingRequirementSets';
import linkRequirementSetToVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.linkRequirementSetToVendorProgram';
import createRequirementSetFromExisting from '@salesforce/apex/VendorOnboardingWizardController.createRequirementSetFromExisting';
import getTemplatesForRequirementSet from '@salesforce/apex/VendorOnboardingWizardController.getTemplatesForRequirementSet';
import createOnboardingRequirementTemplate from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingRequirementTemplate';
import createRequirementFromTemplate from '@salesforce/apex/VendorOnboardingWizardController.createRequirementFromTemplate';
import createOnboardingRequirementSet from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingRequirementSet';
import getRequirementSetById from '@salesforce/apex/VendorOnboardingWizardController.getRequirementSetById';

export default class VendorProgramOnboardingRequirementSetOrCreate extends LightningElement {
  @api vendorProgramId;
  @api stageId;
  @api stepNumber;
  @api requirementSetId; // From context when resuming

  // View states: 'search', 'confirm', 'create', 'createRequirements', 'confirmRequirements'
  @track currentView = 'search';
  @track searchText = '';
  @track requirementSets = [];
  @track selectedRequirementSetId = null;
  @track selectedRequirementSet = null;
  @track templates = [];
  @track createdRequirements = [];
  @track nextDisabled = true;
  @track isLoading = false;

  // Inline template creation
  @track showTemplateForm = false;
  @track newTemplate = {
    Requirement_Label__c: '',
    Requirement_Type__c: 'Document',
    Status__c: 'Active',
    Is_Current_Version__c: true,
    Category_Group__c: null
  };
  @track currentRequirementSetId = null; // For inline template creation

  requirementTypeOptions = [
    { label: 'Document', value: 'Document' },
    { label: 'Status', value: 'Status' },
    { label: 'Training', value: 'Training' },
    { label: 'Credential', value: 'Credential' }
  ];

  statusOptions = [
    { label: 'Active', value: 'Active' },
    { label: 'Inactive', value: 'Inactive' },
    { label: 'Draft', value: 'Draft' }
  ];

  connectedCallback() {
    // If requirementSetId is provided (from context when resuming), load it
    if (this.requirementSetId) {
      this.loadExistingRequirementSet();
    }
  }

  async loadExistingRequirementSet() {
    if (!this.requirementSetId) return;
    
    this.isLoading = true;
    try {
      const reqSet = await getRequirementSetById({ requirementSetId: this.requirementSetId });
      if (reqSet) {
        this.selectedRequirementSetId = reqSet.Id;
        this.selectedRequirementSet = reqSet;
        // Add to requirementSets array so it shows in the list
        this.requirementSets = [reqSet];
        // Load templates and show confirm view
        this.templates = await getTemplatesForRequirementSet({ requirementSetId: this.requirementSetId });
        this.currentView = 'confirm';
        this.nextDisabled = false;
      }
    } catch (err) {
      this.showToast('Error', 'Failed to load requirement set.', 'error');
    } finally {
      this.isLoading = false;
    }
  }

  async searchRequirementSets() {
    if (!this.searchText || this.searchText.trim().length === 0) {
      // If we have a selected requirement set from context, keep it in the list
      if (this.selectedRequirementSet) {
        this.requirementSets = [this.selectedRequirementSet];
      } else {
        this.requirementSets = [];
      }
      return;
    }
    try {
      const results = await searchOnboardingRequirementSets({ 
        searchText: this.searchText.trim(),
        vendorProgramId: this.vendorProgramId 
      });
      this.requirementSets = results || [];
      
      // If we have a selected requirement set from context that's not in search results, add it
      if (this.selectedRequirementSet && !this.requirementSets.find(rs => rs.Id === this.selectedRequirementSet.Id)) {
        this.requirementSets.unshift(this.selectedRequirementSet);
      }
    } catch (err) {
      // Keep selected requirement set if available
      if (this.selectedRequirementSet) {
        this.requirementSets = [this.selectedRequirementSet];
      } else {
        this.requirementSets = [];
      }
      this.showToast('Error', 'Failed to search requirement sets.', 'error');
    }
  }

  handleRequirementSetSelect(event) {
    this.selectedRequirementSetId = event.detail.value;
    this.selectedRequirementSet = this.requirementSets.find(rs => rs.Id === this.selectedRequirementSetId);
    this.nextDisabled = false;
  }

  async handleSelectAndContinue() {
    if (!this.selectedRequirementSetId) {
      this.showToast('Selection Required', 'Please select a Requirement Set.', 'warning');
      return;
    }

    // Load templates for the selected set
    this.isLoading = true;
    try {
      this.templates = await getTemplatesForRequirementSet({ requirementSetId: this.selectedRequirementSetId });
      this.currentView = 'confirm';
      this.nextDisabled = false;
    } catch (err) {
      this.showToast('Error', 'Failed to load requirement set details.', 'error');
    } finally {
      this.isLoading = false;
    }
  }

  async handleConfirmSelection() {
    this.isLoading = true;
    try {
      await linkRequirementSetToVendorProgram({
        requirementSetId: this.selectedRequirementSetId,
        vendorProgramId: this.vendorProgramId
      });
      this.showToast('Success', 'Requirement Set linked to Vendor Program successfully!', 'success');
      
      // Proceed to next step
      this.dispatchEvent(new CustomEvent('next', {
        detail: {
          requirementSetId: this.selectedRequirementSetId,
          vendorProgramId: this.vendorProgramId
        }
      }));
    } catch (err) {
      const errorMessage = err.body?.message || err.message || 'Unknown error';
      this.showToast('Error', 'Failed to link requirement set. ' + errorMessage, 'error');
    } finally {
      this.isLoading = false;
    }
  }

  async handleMakeChanges() {
    this.isLoading = true;
    try {
      const newSetId = await createRequirementSetFromExisting({
        existingRequirementSetId: this.selectedRequirementSetId,
        vendorProgramId: this.vendorProgramId
      });
      
      this.showToast('Success', 'New Requirement Set created with changes!', 'success');
      
      // Proceed to next step with new set
      this.dispatchEvent(new CustomEvent('next', {
        detail: {
          requirementSetId: newSetId,
          vendorProgramId: this.vendorProgramId
        }
      }));
    } catch (err) {
      const errorMessage = err.body?.message || err.message || 'Unknown error';
      this.showToast('Error', 'Failed to create requirement set. ' + errorMessage, 'error');
    } finally {
      this.isLoading = false;
    }
  }

  handleSkipToCreateRequirements() {
    // User wants to create requirements directly without a requirement set
    this.currentView = 'createRequirements';
    this.currentRequirementSetId = null; // Will create set when first template is created
    this.templates = [];
    this.createdRequirements = [];
  }

  toggleTemplateForm() {
    this.showTemplateForm = !this.showTemplateForm;
    if (!this.showTemplateForm) {
      this.resetTemplateForm();
    }
  }

  resetTemplateForm() {
    this.newTemplate = {
      Requirement_Label__c: '',
      Requirement_Type__c: 'Document',
      Status__c: 'Active',
      Is_Current_Version__c: true,
      Category_Group__c: null
    };
  }

  handleTemplateFieldChange(event) {
    const field = event.target;
    const name = field.name;
    const value = field.type === 'checkbox' ? field.checked : field.value;
    
    this.newTemplate = {
      ...this.newTemplate,
      [name]: value
    };
  }

  async createTemplate() {
    if (!this.newTemplate.Requirement_Label__c?.trim()) {
      this.showToast('Required Fields Missing', 'Please enter a Requirement Label.', 'warning');
      return;
    }

    this.isLoading = true;

    try {
      // If no requirement set exists yet, create one first
      if (!this.currentRequirementSetId) {
        // Create requirement set - Vendor_Program__c is optional for many-to-many support
        // Junction link will be created automatically by the service
        const newSetId = await createOnboardingRequirementSet({
          requirementSet: {
            Vendor_Program__c: this.vendorProgramId || null, // Optional for many-to-many
            Status__c: 'Draft'
          }
        });
        this.currentRequirementSetId = newSetId;
      }

      // Create the template
      // Onboarding_Requirement_Set__c is optional - junction record will be created by service
      const templateId = await createOnboardingRequirementTemplate({
        template: {
          Onboarding_Requirement_Set__c: this.currentRequirementSetId || null, // Optional for many-to-many
          Requirement_Label__c: this.newTemplate.Requirement_Label__c.trim(),
          Requirement_Type__c: this.newTemplate.Requirement_Type__c || 'Document',
          Status__c: this.newTemplate.Status__c || 'Active',
          Category_Group__c: this.newTemplate.Category_Group__c || null,
          Is_Current_Version__c: this.newTemplate.Is_Current_Version__c !== false
        }
      });

      this.showToast('Success', 'Template created successfully!', 'success');
      
      // Reload templates
      this.templates = await getTemplatesForRequirementSet({ requirementSetId: this.currentRequirementSetId });
      
      // Reset form
      this.resetTemplateForm();
      this.showTemplateForm = false;
    } catch (err) {
      const errorMessage = err.body?.message || err.message || 'Unknown error';
      this.showToast('Error', 'Failed to create template. ' + errorMessage, 'error');
    } finally {
      this.isLoading = false;
    }
  }

  async createRequirementFromTemplate(templateId) {
    this.isLoading = true;
    try {
      const requirementId = await createRequirementFromTemplate({
        templateId: templateId,
        vendorProgramId: this.vendorProgramId
      });

      // Add to created requirements list
      const template = this.templates.find(t => t.Id === templateId);
      this.createdRequirements.push({
        Id: requirementId,
        TemplateId: templateId,
        Label: template.Requirement_Label__c,
        Type: template.Requirement_Type__c
      });

      this.showToast('Success', 'Requirement created successfully!', 'success');
    } catch (err) {
      const errorMessage = err.body?.message || err.message || 'Unknown error';
      this.showToast('Error', 'Failed to create requirement. ' + errorMessage, 'error');
    } finally {
      this.isLoading = false;
    }
  }

  handleConfirmRequirementsCreated() {
    if (this.createdRequirements.length === 0) {
      this.showToast('No Requirements Created', 'Please create at least one requirement before continuing.', 'warning');
      return;
    }

    // Proceed to next step
    this.dispatchEvent(new CustomEvent('next', {
      detail: {
        requirementSetId: this.currentRequirementSetId,
        vendorProgramId: this.vendorProgramId,
        createdRequirements: this.createdRequirements.map(r => r.Id)
      }
    }));
  }

  handleSearchChange(event) {
    this.searchText = event.target.value;
  }

  handleBack() {
    if (this.currentView === 'confirm') {
      // When going back from confirm view, keep the selected requirement set visible
      this.currentView = 'search';
      // Don't clear selectedRequirementSetId or selectedRequirementSet - keep them so user can see what was selected
      // Ensure the requirement set is in the list for display
      if (this.selectedRequirementSet && !this.requirementSets.find(rs => rs.Id === this.selectedRequirementSet.Id)) {
        this.requirementSets = [this.selectedRequirementSet, ...this.requirementSets];
      } else if (this.selectedRequirementSet && this.requirementSets.length === 0) {
        this.requirementSets = [this.selectedRequirementSet];
      }
      // Templates will be cleared but can be reloaded if user continues
      this.templates = [];
    } else if (this.currentView === 'createRequirements') {
      this.currentView = 'search';
      this.currentRequirementSetId = null;
      this.templates = [];
      this.createdRequirements = [];
    } else {
      this.dispatchEvent(new CustomEvent('back'));
    }
  }

  get isSearchView() {
    return this.currentView === 'search';
  }

  get isConfirmView() {
    return this.currentView === 'confirm';
  }

  get isCreateRequirementsView() {
    return this.currentView === 'createRequirements';
  }

  get templateFormButtonLabel() {
    return this.showTemplateForm ? 'Cancel Template Creation' : 'Create New Template';
  }

  get isConfirmButtonDisabled() {
    return !this.hasCreatedRequirements;
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(evt);
  }

  get requirementSetOptions() {
    return this.requirementSets.map(rs => ({
      label: `${rs.Name} (${rs.Status__c || 'N/A'})`,
      value: rs.Id
    }));
  }

  get hasSelectedSet() {
    return !!this.selectedRequirementSetId;
  }

  get hasSelectedRequirementSetFromContext() {
    return this.selectedRequirementSet && this.selectedRequirementSetId && this.isSearchView;
  }

  get hasTemplates() {
    return this.templates && this.templates.length > 0;
  }

  get hasCreatedRequirements() {
    return this.createdRequirements && this.createdRequirements.length > 0;
  }

  get templateColumns() {
    return [
      { label: 'Requirement Label', fieldName: 'Requirement_Label__c' },
      { label: 'Type', fieldName: 'Requirement_Type__c' },
      { label: 'Status', fieldName: 'Status__c' },
      {
        type: 'button',
        typeAttributes: {
          label: 'Create Requirement',
          name: 'create',
          variant: 'brand'
        }
      }
    ];
  }

  get templatesWithCreatedStatus() {
    return this.templates.map(template => {
      const isCreated = this.createdRequirements.some(req => req.TemplateId === template.Id);
      return {
        ...template,
        IsCreated: isCreated
      };
    });
  }

  get createdRequirementsColumns() {
    return [
      { label: 'Requirement Label', fieldName: 'Label' },
      { label: 'Type', fieldName: 'Type' }
    ];
  }

  handleTemplateRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    
    if (action.name === 'create') {
      this.createRequirementFromTemplate(row.Id);
    }
  }

  get cardTitle() {
    const step = this.stepNumber || '?';
    return `Step ${step}: Select Requirement Set or Create Requirements`;
  }
}

