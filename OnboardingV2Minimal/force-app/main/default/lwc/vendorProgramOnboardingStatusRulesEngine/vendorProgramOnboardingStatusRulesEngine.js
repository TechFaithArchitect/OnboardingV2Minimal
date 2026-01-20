import { api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import OnboardingStepBase from 'c/onboardingStepBase';
import searchStatusRulesEngines from '@salesforce/apex/VendorOnboardingWizardController.searchStatusRulesEngines';
import createStatusRulesEngine from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingStatusRulesEngine';
import getHistoricalStatusRulesEngines from '@salesforce/apex/VendorOnboardingWizardController.getHistoricalStatusRulesEngines';
import getEvaluationLogicPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getEvaluationLogicPicklistValues';
import getRequiredStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getRequiredStatusPicklistValues';
import getTargetOnboardingStatusPicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getTargetOnboardingStatusPicklistValues';
import getStatusRulesByEngine from '@salesforce/apex/VendorOnboardingWizardController.getStatusRulesByEngine';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';
import upsertStatusRule from '@salesforce/apex/VendorOnboardingWizardController.upsertStatusRule';
import deleteStatusRule from '@salesforce/apex/VendorOnboardingWizardController.deleteStatusRule';

export default class VendorProgramOnboardingStatusRulesEngine extends OnboardingStepBase {
  stepName = 'Status Rules Engine & Rules';
  
  @api vendorProgramId;
  @api stageId;
  @api requirementSetId; // From Step 4

  // Simplified state - no complex view switching
  @track historicalEngines = [];
  @track searchText = '';
  @track debouncedSearchText = '';
  @track searchResults = [];
  @track selectedEngineId = null;
  @track selectedEngine = null;
  @track showCreateForm = false;
  @track isLoading = false;
  @track nextDisabled = true;

  // Debounce timer for autocomplete
  searchTimeout;

  // New record fields for engine
  @track newName = '';
  @track newEvaluationLogic = 'ALL';
  @track newRequiredStatus = 'New';
  @track newTargetOnboardingStatus = 'In Process';

  // Rules management state
  @track rules = [];
  @track requirements = [];
  @track isLoadingRules = false;
  @track isLoadingRequirements = false;
  @track showCreateRuleForm = false;
  @track editingRuleId = null;
  
  // New rule fields
  @track newRuleName = '';
  @track selectedRequirementId = '';
  @track newRuleExpectedStatus = 'New';
  
  // Rule table columns
  columns = [
    { label: 'Rule Name', fieldName: 'ruleDisplayName', editable: false },
    { label: 'Requirement', fieldName: 'requirementName', editable: false },
    { label: 'Expected Status', fieldName: 'Expected_Status__c', editable: true },
    { label: 'Rule Number', fieldName: 'Rule_Number__c', type: 'number', editable: true },
    {
      type: 'action',
      typeAttributes: {
        rowActions: [
          { label: 'Edit', name: 'edit' },
          { label: 'Delete', name: 'delete' }
        ]
      }
    }
  ];

  @track evaluationLogicOptions = [];
  @track requiredStatusOptions = [];
  @track targetOnboardingStatusOptions = [];

  @wire(getEvaluationLogicPicklistValues)
  wiredEvaluationLogicOptions({ error, data }) {
    if (data) {
      this.evaluationLogicOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Evaluation Logic options');
      this.evaluationLogicOptions = [{ label: 'ALL', value: 'ALL' }];
    }
  }

  @wire(getRequiredStatusPicklistValues)
  wiredRequiredStatusOptions({ error, data }) {
    if (data) {
      this.requiredStatusOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Required Status options');
      this.requiredStatusOptions = [{ label: 'New', value: 'New' }];
    }
  }

  @wire(getTargetOnboardingStatusPicklistValues)
  wiredTargetOnboardingStatusOptions({ error, data }) {
    if (data) {
      this.targetOnboardingStatusOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Target Onboarding Status options');
      this.targetOnboardingStatusOptions = [{ label: 'In Process', value: 'In Process' }];
    }
  }

  // Autocomplete wire - debounced search
  @wire(searchStatusRulesEngines, { nameSearchText: '$debouncedSearchText' })
  wiredSearchResults({ error, data }) {
    if (data) {
      this.searchResults = data || [];
      this.isLoading = false;
    } else if (error) {
      this.handleError(error, 'Failed to search status rules engines');
      this.searchResults = [];
      this.isLoading = false;
    }
  }

  // Wire adapter for rules - refresh when engine changes
  wiredRulesResult;
  @wire(getStatusRulesByEngine, { engineId: '$selectedEngineId' })
  wiredRules(result) {
    this.wiredRulesResult = result;
    const { error, data } = result;
    if (data) {
      this.loadRequirementsForRules(data);
    } else if (error) {
      this.handleError(error, 'Failed to load status rules');
      this.rules = [];
      this.isLoadingRules = false;
    }
  }

  connectedCallback() {
    super.connectedCallback();
    this.loadHistoricalEngines();
    this.suggestName();
    this.loadRequirements();
  }

  loadRequirementsForRules(ruleData) {
    // Map rules with requirement names from the relationship fields
    this.rules = ruleData.map(rule => {
      const requirementName = rule.Requirement__r?.Requirement_Template__r?.Requirement_Label__c 
        || rule.Requirement__r?.Name 
        || 'Unknown Requirement';
      
      // Use requirement name as rule display name instead of auto-number
      const ruleDisplayName = requirementName;
      
      return {
        ...rule,
        requirementName: requirementName,
        ruleDisplayName: ruleDisplayName
      };
    });
    this.isLoadingRules = false;
  }

  async loadRequirements() {
    if (!this.vendorProgramId) return;
    
    this.isLoadingRequirements = true;
    try {
      this.requirements = await getRequirementsForVendorProgram({ vendorProgramId: this.vendorProgramId });
    } catch (error) {
      this.handleError(error, 'Failed to load vendor program requirements');
      this.requirements = [];
    } finally {
      this.isLoadingRequirements = false;
    }
  }

  // Override base class methods - following DRY pattern
  get canProceed() {
    return !this.nextDisabled;
  }

  proceedToNext() {
    if (!this.selectedEngineId) {
      this.showToast('Action Required', 'Please select or create a Status Rules Engine before proceeding.', 'warning');
      return;
    }
    
    this.dispatchNextEvent({
      statusRulesEngineId: this.selectedEngineId,
      vendorProgramId: this.vendorProgramId
    });
  }

  async loadHistoricalEngines() {
    if (!this.requirementSetId) {
      return;
    }

    this.isLoading = true;
    try {
      this.historicalEngines = await getHistoricalStatusRulesEngines({ requirementSetId: this.requirementSetId });
      
      // If historical engines found, pre-select first one
      if (this.historicalEngines && this.historicalEngines.length > 0) {
        this.selectedEngineId = this.historicalEngines[0].Id;
        this.selectedEngine = this.historicalEngines[0];
        this.nextDisabled = false;
        this.dispatchValidationState();
      }
    } catch (err) {
      this.handleError(err, 'Failed to load historical status rules engines');
    } finally {
      this.isLoading = false;
    }
  }

  handleSearchChange(event) {
    const searchValue = event.target.value || '';
    this.searchText = searchValue;
    
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    // If search text is cleared, clear results
    if (!searchValue || searchValue.trim().length === 0) {
      this.debouncedSearchText = '';
      this.searchResults = [];
      return;
    }

    // Debounce: wait 300ms after user stops typing before searching
    // Require at least 2 characters for autocomplete
    if (searchValue.trim().length >= 2) {
      this.isLoading = true;
      this.searchTimeout = setTimeout(() => {
        this.debouncedSearchText = searchValue.trim();
      }, 300);
    } else {
      this.debouncedSearchText = '';
      this.searchResults = [];
      this.isLoading = false;
    }
  }

  handleHistoricalEngineSelect(event) {
    const selectedId = event.detail.value;
    this.selectedEngineId = selectedId;
    this.selectedEngine = this.historicalEngines.find(e => e.Id === selectedId);
    this.nextDisabled = false;
    this.loadRulesForEngine(selectedId);
    this.dispatchValidationState();
    
    // Clear search when selecting historical
    this.searchText = '';
    this.debouncedSearchText = '';
    this.searchResults = [];
  }

  async loadRulesForEngine(engineId) {
    if (!engineId) {
      this.rules = [];
      return;
    }
    this.isLoadingRules = true;
    // Rules will load via @wire adapter
  }

  handleSearchResultSelect(event) {
    const selectedId = event.detail.value;
    const selected = this.searchResults.find(e => e.Id === selectedId);
    if (selected) {
      this.selectedEngineId = selected.Id;
      this.selectedEngine = selected;
      this.nextDisabled = false;
      this.loadRulesForEngine(selected.Id);
      this.dispatchValidationState();
      
      // Show selected name in search field
      this.searchText = selected.Name;
    }
  }

  toggleCreateForm() {
    this.showCreateForm = !this.showCreateForm;
    if (!this.showCreateForm) {
      // Clear form when hiding
      this.newName = '';
      this.newEvaluationLogic = 'ALL';
      this.newRequiredStatus = 'New';
      this.newTargetOnboardingStatus = 'In Process';
      this.suggestName();
    } else {
      // Clear selection when showing create form
      this.selectedEngineId = null;
      this.selectedEngine = null;
      this.nextDisabled = true;
      this.dispatchValidationState();
    }
  }

  handleInputChange(event) {
    const field = event.target.name;
    const value = event.target.value;
    if (field === 'name') this.newName = value;
  }

  handleEvaluationLogicChange(event) {
    this.newEvaluationLogic = event.detail.value;
  }

  handleRequiredStatusChange(event) {
    this.newRequiredStatus = event.detail.value;
  }

  handleTargetOnboardingStatusChange(event) {
    this.newTargetOnboardingStatus = event.detail.value;
  }

  async handleCreateClick() {
    if (!this.newName?.trim() || !this.newEvaluationLogic || !this.newRequiredStatus || !this.newTargetOnboardingStatus) {
      this.showToast('Required Fields Missing', 'Please fill in Name, Evaluation Logic, Required Status, and Target Onboarding Status.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      const engine = {
        Name: this.newName.trim(),
        Evaluation_Logic__c: this.newEvaluationLogic,
        Required_Status__c: this.newRequiredStatus,
        Target_Onboarding_Status__c: this.newTargetOnboardingStatus
      };

      const newId = await createStatusRulesEngine({ onboardingStatusRulesEngine: engine });

      // Select the newly created engine
      this.selectedEngineId = newId;
      this.selectedEngine = {
        Id: newId,
        Name: this.newName.trim(),
        Evaluation_Logic__c: this.newEvaluationLogic,
        Required_Status__c: this.newRequiredStatus,
        Target_Onboarding_Status__c: this.newTargetOnboardingStatus
      };
      this.nextDisabled = false;
      this.loadRulesForEngine(newId);
      this.dispatchValidationState();

      this.showToast('Success', 'Status Rules Engine created successfully!', 'success');
      
      // Hide create form
      this.showCreateForm = false;
      this.newName = '';
    } catch (error) {
      this.handleError(error, 'Failed to create status rules engine');
    } finally {
      this.isLoading = false;
    }
  }

  // Rules management methods
  handleRuleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    
    if (actionName === 'edit') {
      this.editRule(row);
    } else if (actionName === 'delete') {
      this.deleteRuleConfirm(row);
    }
  }

  editRule(rule) {
    this.editingRuleId = rule.Id;
    this.newRuleName = rule.Name;
    this.selectedRequirementId = rule.Requirement__c;
    this.newRuleExpectedStatus = rule.Expected_Status__c || 'New';
    this.showCreateRuleForm = true;
  }

  deleteRuleConfirm(rule) {
    if (confirm(`Are you sure you want to delete the rule "${rule.Name}"?`)) {
      this.deleteRule(rule.Id);
    }
  }

  async deleteRule(ruleId) {
    this.isLoadingRules = true;
    try {
      await deleteStatusRule({ ruleId });
      this.showToast('Success', 'Rule deleted successfully', 'success');
      if (this.wiredRulesResult) {
        await refreshApex(this.wiredRulesResult);
      }
    } catch (error) {
      this.handleError(error, 'Failed to delete rule');
    } finally {
      this.isLoadingRules = false;
    }
  }

  toggleCreateRuleForm() {
    this.showCreateRuleForm = !this.showCreateRuleForm;
    if (!this.showCreateRuleForm) {
      this.resetRuleForm();
    }
  }

  resetRuleForm() {
    this.editingRuleId = null;
    this.newRuleName = '';
    this.selectedRequirementId = '';
    this.newRuleExpectedStatus = 'New';
  }

  handleRuleInputChange(event) {
    const { name, value } = event.target;
    if (name === 'ruleName') this.newRuleName = value;
    if (name === 'expectedStatus') this.newRuleExpectedStatus = value;
  }

  handleRequirementSelect(event) {
    this.selectedRequirementId = event.detail.value;
  }

  async handleSaveRule() {
    if (!this.newRuleName?.trim() || !this.selectedRequirementId) {
      this.showToast('Required Fields Missing', 'Please fill in Rule Name and select a Requirement.', 'warning');
      return;
    }

    this.isLoadingRules = true;
    try {
      const rule = {
        Id: this.editingRuleId || undefined,
        Name: this.newRuleName.trim(),
        Parent_Rule__c: this.selectedEngineId,
        Requirement__c: this.selectedRequirementId,
        Expected_Status__c: this.newRuleExpectedStatus
      };

      await upsertStatusRule({ rule });
      
      this.showToast('Success', this.editingRuleId ? 'Rule updated successfully' : 'Rule created successfully', 'success');
      
      // Refresh rules
      if (this.wiredRulesResult) {
        await refreshApex(this.wiredRulesResult);
      }
      
      this.resetRuleForm();
      this.showCreateRuleForm = false;
    } catch (error) {
      this.handleError(error, this.editingRuleId ? 'Failed to update rule' : 'Failed to create rule');
    } finally {
      this.isLoadingRules = false;
    }
  }

  handleRuleSave(event) {
    const draftValues = event.detail.draftValues;
    if (!draftValues || draftValues.length === 0) return;
    
    this.isLoadingRules = true;
    const updatedRules = draftValues.map(draft => {
      const rule = this.rules.find(r => r.Id === draft.Id);
      return { ...rule, ...draft };
    });
    
    Promise.all(updatedRules.map(rule => 
      upsertStatusRule({ rule })
    )).then(() => {
      this.showToast('Success', 'Rules updated successfully', 'success');
      if (this.wiredRulesResult) {
        return refreshApex(this.wiredRulesResult);
      }
    }).catch(error => {
      this.handleError(error, 'Failed to update rules');
    }).finally(() => {
      this.isLoadingRules = false;
    });
  }

  get requirementOptions() {
    if (!this.requirements || this.requirements.length === 0) {
      return [];
    }
    return this.requirements.map(req => {
      const displayLabel = req.Requirement_Template__r?.Requirement_Label__c || req.Name || 'Unnamed Requirement';
      return {
        label: displayLabel,
        value: req.Id
      };
    });
  }

  get hasRules() {
    return this.rules && this.rules.length > 0;
  }

  get createRuleButtonVariant() {
    return this.showCreateRuleForm ? 'neutral' : 'brand';
  }

  get createRuleButtonLabel() {
    if (this.editingRuleId) return 'Cancel Edit';
    if (this.showCreateRuleForm) return 'Cancel Create Rule';
    return 'Create New Rule';
  }

  get saveRuleButtonLabel() {
    return this.editingRuleId ? 'Update Rule' : 'Create Rule';
  }

  get isSaveRuleButtonDisabled() {
    return this.isLoadingRules || !this.newRuleName?.trim() || !this.selectedRequirementId;
  }

  get ruleFormTitle() {
    return this.editingRuleId ? 'Edit Rule' : 'Create New Status Rule';
  }

  // Getters for options
  get historicalEngineOptions() {
    if (!this.historicalEngines || this.historicalEngines.length === 0) {
      return [];
    }
    return this.historicalEngines.map(engine => ({
      label: `${engine.Name} (${engine.Evaluation_Logic__c || 'N/A'})`,
      value: engine.Id,
      description: `Required: ${engine.Required_Status__c || 'N/A'}, Target: ${engine.Target_Onboarding_Status__c || 'N/A'}`
    }));
  }

  get searchResultOptions() {
    if (!this.searchResults || this.searchResults.length === 0) {
      return [];
    }
    return this.searchResults.map(engine => ({
      label: engine.Name,
      value: engine.Id,
      description: `Logic: ${engine.Evaluation_Logic__c || 'N/A'}`
    }));
  }

  get hasHistoricalEngines() {
    return this.historicalEngines && this.historicalEngines.length > 0;
  }

  get hasSearchResults() {
    return this.searchResults && this.searchResults.length > 0;
  }

  get showSearchResults() {
    return this.searchText && this.searchText.trim().length >= 2 && this.hasSearchResults;
  }

  get selectedEngineDisplay() {
    if (!this.selectedEngine) return '';
    const logic = this.selectedEngine.Evaluation_Logic__c || 'N/A';
    return `${this.selectedEngine.Name} (${logic})`;
  }

  get createButtonVariant() {
    return this.showCreateForm ? 'neutral' : 'brand';
  }

  get createButtonLabel() {
    return this.showCreateForm ? 'Cancel Create New Engine' : 'Create New Engine';
  }

  get isCreateEngineButtonDisabled() {
    return this.isLoading || !this.newName?.trim() || !this.newEvaluationLogic || !this.newRequiredStatus || !this.newTargetOnboardingStatus;
  }

  // Helper to suggest name
  suggestName() {
    if (!this.newName && this.vendorProgramId) {
      this.newName = `Status Rules Engine - ${new Date().toLocaleDateString()}`;
    }
  }

  disconnectedCallback() {
    // Clear timeout on cleanup
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
  }
}

