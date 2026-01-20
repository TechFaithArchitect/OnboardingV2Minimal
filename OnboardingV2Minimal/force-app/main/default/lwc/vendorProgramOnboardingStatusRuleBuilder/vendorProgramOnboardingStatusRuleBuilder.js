import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import searchStatusRules from '@salesforce/apex/VendorOnboardingWizardController.searchStatusRules';
import createStatusRule from '@salesforce/apex/VendorOnboardingWizardController.createStatusRule';
import getRequirementsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRequirementsForVendorProgram';
import getStatusRulesEngineById from '@salesforce/apex/VendorOnboardingWizardController.getStatusRulesEngineById';

export default class VendorProgramOnboardingStatusRuleBuilder extends OnboardingStepBase {
  stepName = 'Status Rule Builder';
  
  @api vendorProgramId;
  @api stageId;
  @api statusRulesEngineId; // From Step 11 - Status Rules Engine

  @track searchText = '';
  @track debouncedSearchText = '';
  @track searchResults = [];
  searchTimeout;

  @track requirements = [];
  @track isLoadingRequirements = false;
  @track selectedRuleId = null;
  @track selectedRule = null;
  @track nextDisabled = true;

  // New rule fields
  @track newRuleName = '';
  @track selectedRequirementId = '';
  @track selectedRequirementName = '';

  // Engine details
  @track engineName = '';
  @track isLoadingEngine = false;

  connectedCallback() {
    super.connectedCallback();
    // Load requirements for this vendor program
    this.loadRequirements();
    // Load engine name if we have the ID
    if (this.statusRulesEngineId) {
      this.loadEngineName();
    }
  }

  // Handle changes to statusRulesEngineId (when passed from parent)
  renderedCallback() {
    // Check if statusRulesEngineId changed and we need to reload engine name
    if (this.statusRulesEngineId && !this.engineName && !this.isLoadingEngine) {
      this.loadEngineName();
    }
  }

  // Autocomplete wire - debounced search
  @wire(searchStatusRules, { nameSearchText: '$debouncedSearchText' })
  wiredSearchResults({ error, data }) {
    if (data) {
      this.searchResults = data || [];
      this.isLoading = false;
    } else if (error) {
      this.handleError(error, 'Failed to search status rules');
      this.searchResults = [];
      this.isLoading = false;
    }
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

  async loadEngineName() {
    if (!this.statusRulesEngineId) return;
    
    this.isLoadingEngine = true;
    try {
      const engine = await getStatusRulesEngineById({ engineId: this.statusRulesEngineId });
      if (engine) {
        this.engineName = engine.Name;
      }
    } catch (error) {
      this.handleError(error, 'Failed to load rules engine details');
      this.engineName = '';
    } finally {
      this.isLoadingEngine = false;
    }
  }

  handleSearchChange(event) {
    const searchValue = event.target.value || '';
    this.searchText = searchValue;
    
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    if (!searchValue || searchValue.trim().length === 0) {
      this.debouncedSearchText = '';
      this.searchResults = [];
      return;
    }

    // Debounce: wait 300ms, require at least 2 characters
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

  handleSearchResultSelect(event) {
    const selectedId = event.detail.value;
    const selected = this.searchResults.find(r => r.Id === selectedId);
    if (selected) {
      // Verify the rule belongs to the correct rules engine
      if (this.statusRulesEngineId && selected.Parent_Rule__c !== this.statusRulesEngineId) {
        this.showToast('Invalid Rule', `This rule belongs to a different rules engine. Please select a rule from the current engine.`, 'error');
        return;
      }
      
      this.selectedRuleId = selected.Id;
      this.selectedRule = selected;
      this.nextDisabled = false;
      this.dispatchValidationState();
      
      // Show selected name in search field
      this.searchText = selected.Name;
      
      this.showToast('Success', 'Status Rule selected! Click Next to continue.', 'success');
    }
  }

  handleRequirementChange(event) {
    this.selectedRequirementId = event.detail.value;
    
    // Update display name
    const selected = this.requirementOptions.find(r => r.value === this.selectedRequirementId);
    this.selectedRequirementName = selected ? selected.label : '';
    
    // Reset rule selection if requirement changes
    if (this.selectedRuleId) {
      this.selectedRuleId = null;
      this.selectedRule = null;
      this.nextDisabled = true;
      this.dispatchValidationState();
    }
  }

  handleInputChange(event) {
    const { name, value } = event.target;
    if (name === 'name') {
      this.newRuleName = value;
      // Reset selection if user starts typing new name
      if (this.selectedRuleId) {
        this.selectedRuleId = null;
        this.selectedRule = null;
        this.nextDisabled = true;
        this.dispatchValidationState();
      }
    }
  }

  async handleCreateClick() {
    if (!this.newRuleName?.trim() || !this.statusRulesEngineId || !this.selectedRequirementId) {
      this.showToast('Required Fields Missing', 'Please fill in Rule Name and select a Vendor Program Requirement.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      const rule = {
        Name: this.newRuleName.trim(),
        Parent_Rule__c: this.statusRulesEngineId,
        Requirement__c: this.selectedRequirementId
      };

      const newId = await createStatusRule({ rule });
      
      this.selectedRuleId = newId;
      this.selectedRule = {
        Id: newId,
        Name: this.newRuleName.trim(),
        Parent_Rule__c: this.statusRulesEngineId,
        Requirement__c: this.selectedRequirementId
      };
      this.nextDisabled = false;
      this.dispatchValidationState();

      this.showToast('Success', 'Status Rule created and added to the rules engine! Click Next to continue.', 'success');
      
      // Clear form
      this.newRuleName = '';
      this.selectedRequirementId = '';
      this.selectedRequirementName = '';
    } catch (error) {
      this.handleError(error, 'Failed to create status rule');
    } finally {
      this.isLoading = false;
    }
  }

  // Override base class methods - following DRY pattern
  get canProceed() {
    return !this.nextDisabled;
  }

  proceedToNext() {
    if (!this.selectedRuleId) {
      this.showToast('Action Required', 'Please create or select a Status Rule before proceeding.', 'warning');
      return;
    }
    
    this.dispatchNextEvent({
      statusRuleId: this.selectedRuleId,
      vendorProgramId: this.vendorProgramId,
      statusRulesEngineId: this.statusRulesEngineId
    });
  }

  // Getters
  get requirementOptions() {
    if (!this.requirements || this.requirements.length === 0) {
      return [];
    }
    return this.requirements.map(req => {
      // Use the template label if available (user-friendly), otherwise fall back to Name
      const displayLabel = req.Requirement_Template__r?.Requirement_Label__c || req.Name || 'Unnamed Requirement';
      const statusText = req.Status__c ? `Status: ${req.Status__c}` : '';
      const sequenceText = req.Sequence__c ? `Sequence: ${req.Sequence__c}` : '';
      
      // Combine description parts
      const descriptionParts = [sequenceText, statusText].filter(Boolean);
      const description = descriptionParts.length > 0 ? descriptionParts.join(' • ') : '';
      
      return {
        label: displayLabel,
        value: req.Id,
        description: description
      };
    });
  }

  get searchResultOptions() {
    if (!this.searchResults || this.searchResults.length === 0) {
      return [];
    }
    // Filter by engine if we have one
    const filtered = this.statusRulesEngineId 
      ? this.searchResults.filter(r => r.Parent_Rule__c === this.statusRulesEngineId)
      : this.searchResults;
    
    return filtered.map(rule => ({
      label: rule.Name,
      value: rule.Id,
      description: rule.Vendor_Program_Requirement__r?.Name || rule.Requirement__r?.Name || 'No requirement linked'
    }));
  }

  get hasRequirements() {
    return this.requirements && this.requirements.length > 0;
  }

  get hasSearchResults() {
    return this.searchResults && this.searchResults.length > 0;
  }

  get showSearchResults() {
    return this.searchText && this.searchText.trim().length >= 2 && this.hasSearchResults;
  }


  get selectedRuleDisplay() {
    if (!this.selectedRule) return '';
    return this.selectedRule.Name || 'Selected Rule';
  }

  get isCreateFormValid() {
    return this.newRuleName?.trim() && this.statusRulesEngineId && this.selectedRequirementId;
  }

  get isCreateButtonDisabled() {
    return this.isLoading || !this.isCreateFormValid;
  }

  disconnectedCallback() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
  }
}
