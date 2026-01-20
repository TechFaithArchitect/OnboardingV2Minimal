import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { extractErrorMessage } from 'c/utils';
import getStagesForProcess from '@salesforce/apex/OnboardingApplicationService.getStagesForProcess';
import getProgress from '@salesforce/apex/OnboardingApplicationService.getProgress';
import saveProgress from '@salesforce/apex/OnboardingApplicationService.saveProgress';
import getProcessDetails from '@salesforce/apex/OnboardingApplicationService.getProcessDetails';
import getVendorProgramData from '@salesforce/apex/OnboardingApplicationService.getVendorProgramData';
import getStageCompletions from '@salesforce/apex/OnboardingApplicationService.getStageCompletions';
import autoCompleteStagesAndAdvanceProgress from '@salesforce/apex/OnboardingApplicationService.autoCompleteStagesAndAdvanceProgress';
import isCurrentUserAdmin from '@salesforce/apex/OnboardingApplicationService.isCurrentUserAdmin';
import getOnboardingContext from '@salesforce/apex/VendorOnboardingWizardController.getOnboardingContext';

export default class OnboardingFlowEngine extends LightningElement {
  @api processId;
  _vendorProgramId;
  @api
  get vendorProgramId() {
    return this._vendorProgramId;
  }
  set vendorProgramId(value) {
    this._vendorProgramId = value;
  }

  @track stages = [];
  @track activeStageIndex = 0;
  @track processName = '';
  @track loaded = false;
  @track isAdmin = false;
  @track lastSavedTime = null;
  @track isSaving = false;
  @track canProceed = false; // Track if current step allows proceeding
  @track validationTimeout = null; // For debouncing validation checks
  saveIndicatorTimeout = null;
  
  // Expose footer state for parent components
  @api
  get footerBackDisabled() {
    return this.cannotGoBack;
  }
  
  @api
  get footerNextDisabled() {
    return this.cannotProceed;
  }
  
  @api
  handleFooterBack() {
    this.handleBackClick();
  }
  
  @api
  handleFooterNext() {
    this.handleNextClick();
  }

  // Dispatch footer state changes to parent
  dispatchFooterStateChanged() {
    this.dispatchEvent(new CustomEvent('footerstatechanged', {
      detail: {
        backDisabled: this.cannotGoBack,
        nextDisabled: this.cannotProceed
      },
      bubbles: true,
      composed: true
    }));
  }
  
  // Step data passed between components
  @track requirementSetId = null;
  @track requirementTemplateId = null;
  @track requirementGroupId = null;
  @track statusRulesEngineId = null;
  
  // Auto-save timer
  saveTimeout = null;
  autoSaveDelay = 2000; // 2 seconds delay for auto-save

  // Computed: active stage record
  get activeStage() {
    if (!this.stages || !Array.isArray(this.stages)) {
      return {};
    }
    return this.stages[this.activeStageIndex] || {};
  }

  // Label used for progress indicator (for display)
  get activeStageLabel() {
    return this.activeStage?.Label__c || '';
  }

  // Value used for progress indicator (must match step value)
  get activeStageValue() {
    return this.activeStage?.Id || '';
  }

  // Name of dynamic component to render
  get activeComponentName() {
    return this.activeStage?.Onboarding_Component_Library__r?.Component_API_Name__c || '';
  }

  // Context passed to dynamic component
  get componentContext() {
    return {
      vendorProgramId: this.vendorProgramId,
      stageId: this.activeStage?.Id,
      stepNumber: this.activeStageIndex + 1,
      requirementSetId: this.requirementSetId,
      requirementTemplateId: this.requirementTemplateId,
      requirementGroupId: this.requirementGroupId,
      statusRulesEngineId: this.statusRulesEngineId
    };
  }

  // Step counter for display: "Step 3 of 14"
  get stepCounter() {
    if (!this.stages || this.stages.length === 0) {
      return '';
    }
    return `Step ${this.activeStageIndex + 1} of ${this.stages.length}`;
  }

  // Completion percentage: "21% Complete"
  get completionPercentage() {
    if (!this.stages || this.stages.length === 0) {
      return 0;
    }
    const completed = this.activeStageIndex;
    const total = this.stages.length;
    return Math.round((completed / total) * 100);
  }

  // Formatted completion text
  get completionText() {
    return `${this.completionPercentage}% Complete`;
  }

  // Check if save indicator should be shown
  get showSaveIndicator() {
    return this.lastSavedTime !== null && !this.isSaving;
  }

  // Check if we can go back
  get cannotGoBack() {
    return this.activeStageIndex === 0;
  }

  // Check if we can proceed to next step
  get cannotProceed() {
    return !this.canProceed;
  }

  async connectedCallback() {
    // Check admin status first, then initialize flow
    await this.checkAdminStatus();
    await this.initializeFlow();
    
    // Listen for validation changes from step components
    this.template.addEventListener('validationchanged', this.handleValidationChanged.bind(this));
    
    // Query step component for initial validation state after a brief delay
    this.queueValidationCheck(500);
  }

  async checkAdminStatus() {
    try {
      this.isAdmin = await isCurrentUserAdmin();
    } catch {
      // Default to non-admin on error
      this.isAdmin = false;
    }
  }

  async initializeFlow() {
    this.loaded = false;

    try {
      const [stages, progress, processDetails, vendorProgramData, stageCompletions, contextData] = await Promise.all([
        getStagesForProcess({ processId: this.processId }),
        getProgress({ vendorProgramId: this.vendorProgramId, processId: this.processId }),
        getProcessDetails({ processId: this.processId }),
        getVendorProgramData({ vendorProgramId: this.vendorProgramId }),
        getStageCompletions({ vendorProgramId: this.vendorProgramId, processId: this.processId }),
        getOnboardingContext({ vendorProgramId: this.vendorProgramId })
      ]);

      // Restore context data when resuming
      if (contextData) {
        if (contextData.requirementSetId) {
          this.requirementSetId = contextData.requirementSetId;
        }
        if (contextData.requirementTemplateId) {
          this.requirementTemplateId = contextData.requirementTemplateId;
        }
        if (contextData.requirementGroupId) {
          this.requirementGroupId = contextData.requirementGroupId;
        }
        if (contextData.statusRulesEngineId) {
          this.statusRulesEngineId = contextData.statusRulesEngineId;
        }
      }

      this.stages = stages;
      this.processName = processDetails?.Name || 'Onboarding Flow';

      // Build set of completed stage IDs
      const completedStageIds = new Set(stageCompletions.map(comp => comp.Onboarding_Application_Stage__c));

      // Determine starting stage
      let startingIndex = 0;
      let needsAutoCompletion = false;

      // Check if vendor program has a vendor but early stages aren't marked as complete
      const hasVendor = vendorProgramData?.Vendor__c != null;
      
      if (hasVendor && progress) {
        // Find vendor selection stages
        const vendorStage = this.stages.find(stage => 
          stage.Onboarding_Component_Library__r?.Component_API_Name__c === 'vendorProgramOnboardingVendor'
        );
        const searchStage = this.stages.find(stage => 
          stage.Onboarding_Component_Library__r?.Component_API_Name__c === 'vendorProgramOnboardingVendorProgramSearchOrCreate'
        );

        // Check if these stages should be marked as complete but aren't
        if (vendorStage && !completedStageIds.has(vendorStage.Id)) {
          needsAutoCompletion = true;
        }
        if (searchStage && !completedStageIds.has(searchStage.Id)) {
          needsAutoCompletion = true;
        }

        // If we're currently at a vendor selection stage but vendor already exists, we need to advance
        if (progress.Current_Stage__c) {
          const currentStageIndex = this.stages.findIndex(stage => stage.Id === progress.Current_Stage__c);
          if (currentStageIndex >= 0) {
            const currentStage = this.stages[currentStageIndex];
            const currentComponentName = currentStage?.Onboarding_Component_Library__r?.Component_API_Name__c;
            
            // If we're at vendor selection but vendor exists, auto-complete and advance
            if (currentComponentName === 'vendorProgramOnboardingVendor' || 
                currentComponentName === 'vendorProgramOnboardingVendorProgramSearchOrCreate') {
              needsAutoCompletion = true;
            }
          }
        }
      }

      // Auto-complete stages if needed
      if (needsAutoCompletion) {
        try {
          const newStageId = await autoCompleteStagesAndAdvanceProgress({
            vendorProgramId: this.vendorProgramId,
            processId: this.processId
          });
          
          // Refresh progress after auto-completion
          if (newStageId) {
            const updatedProgress = await getProgress({ 
              vendorProgramId: this.vendorProgramId, 
              processId: this.processId 
            });
            if (updatedProgress?.Current_Stage__c) {
              const savedIndex = this.stages.findIndex(stage => stage.Id === updatedProgress.Current_Stage__c);
              if (savedIndex >= 0) {
                startingIndex = savedIndex;
              }
            }
          }
        } catch {
          // Continue with normal logic if auto-completion fails
        }
      }

      // If we didn't auto-complete, use normal resume logic
      if (!needsAutoCompletion || startingIndex === 0) {
        // First, check if we have saved progress
        if (progress?.Current_Stage__c) {
          const savedIndex = this.stages.findIndex(stage => stage.Id === progress.Current_Stage__c);
          if (savedIndex >= 0) {
            startingIndex = savedIndex;
          }
        } else if (vendorProgramData && hasVendor) {
          // No saved progress, but vendor program exists with vendor
          // Skip vendor selection stages
          const createStageIndex = this.stages.findIndex(stage => 
            stage.Onboarding_Component_Library__r?.Component_API_Name__c === 'vendorProgramOnboardingVendorProgramCreate'
          );
          
          if (createStageIndex >= 0) {
            startingIndex = createStageIndex;
          } else {
            // Find first non-vendor-selection stage
            for (let i = 0; i < this.stages.length; i++) {
              const componentName = this.stages[i].Onboarding_Component_Library__r?.Component_API_Name__c;
              if (componentName !== 'vendorProgramOnboardingVendor' && 
                  componentName !== 'vendorProgramOnboardingVendorProgramSearchOrCreate') {
                startingIndex = i;
                break;
              }
            }
          }
        }
      }

      this.activeStageIndex = startingIndex;

      // If user is not admin and we're starting at or before Step 9, skip to Step 10
      if (!this.isAdmin && this.activeStageIndex >= 0) {
        const currentStage = this.stages[this.activeStageIndex];
        const currentComponentName = currentStage?.Onboarding_Component_Library__r?.Component_API_Name__c;
        
        // If current stage is Recipient Groups (Step 9), skip to Communication Template (Step 10)
        if (currentComponentName === 'vendorProgramOnboardingRecipientGroup') {
          const commTemplateIndex = this.stages.findIndex(stage => 
            stage.Onboarding_Component_Library__r?.Component_API_Name__c === 'vendorProgramOnboardingCommunicationTemplate'
          );
          
          if (commTemplateIndex >= 0) {
            this.activeStageIndex = commTemplateIndex;
            // Auto-complete the skipped Recipient Groups stage
            try {
              await this.autoCompleteStage(currentStage.Id);
            } catch {
              // Silently fail - stage will remain incomplete
            }
          }
        }
      }

    } catch {
      this.showToast('Error', 'Failed to initialize onboarding flow. Please refresh the page.', 'error');
    }

    this.loaded = true;
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant || 'info',
    });
    this.dispatchEvent(evt);
  }

  async handleNext(event) {
    try {
      // Extract step data from event detail to pass to next step
      const eventDetail = event.detail || {};
      
      // Store step-specific data from previous steps
      if (eventDetail.requirementSetId) {
        this.requirementSetId = eventDetail.requirementSetId;
      }
      if (eventDetail.requirementTemplateId) {
        this.requirementTemplateId = eventDetail.requirementTemplateId;
      }
      if (eventDetail.requirementGroupId) {
        this.requirementGroupId = eventDetail.requirementGroupId;
      }
      if (eventDetail.statusRulesEngineId) {
        this.statusRulesEngineId = eventDetail.statusRulesEngineId;
      }
      if (eventDetail.vendorProgramId) {
        this._vendorProgramId = eventDetail.vendorProgramId;
      }

      const nextStageId = this.activeStage?.Next_Stage__c;
      let targetStageId = null;
      let nextIndex = -1;

      if (nextStageId) {
        nextIndex = this.stages.findIndex(stage => stage.Id === nextStageId);
        if (nextIndex >= 0) {
          targetStageId = nextStageId; // Save the NEXT stage ID
        } else {
          // Fallback to next sequential index
          if (this.activeStageIndex < this.stages.length - 1) {
            nextIndex = this.activeStageIndex + 1;
            targetStageId = this.stages[nextIndex]?.Id; // Save the NEXT stage ID
          }
        }
      } else if (this.activeStageIndex < this.stages.length - 1) {
        nextIndex = this.activeStageIndex + 1;
        targetStageId = this.stages[nextIndex]?.Id; // Save the NEXT stage ID
      }

      // Skip Step 9 (Recipient Groups) for non-admin users
      if (nextIndex >= 0 && !this.isAdmin) {
        const nextStage = this.stages[nextIndex];
        const nextComponentName = nextStage?.Onboarding_Component_Library__r?.Component_API_Name__c;
        
        // If next stage is Recipient Groups (Step 9), skip to Communication Template (Step 10)
        if (nextComponentName === 'vendorProgramOnboardingRecipientGroup') {
          // Find Communication Template stage (Step 10)
          const commTemplateIndex = this.stages.findIndex(stage => 
            stage.Onboarding_Component_Library__r?.Component_API_Name__c === 'vendorProgramOnboardingCommunicationTemplate'
          );
          
          if (commTemplateIndex >= 0) {
            nextIndex = commTemplateIndex;
            targetStageId = this.stages[nextIndex]?.Id;
            // Auto-complete the skipped Recipient Groups stage
            await this.autoCompleteStage(nextStage.Id);
          }
        }
      }

      // Mark current stage as complete BEFORE advancing to next stage
      // This ensures the database is in sync with the UI
      if (this.activeStage?.Id && nextIndex >= 0) {
        try {
          // Mark current stage as complete by saving progress with current stage ID
          // This creates/updates the completion record for the current stage
          await this.persistProgressWithStageId(this.activeStage.Id);
        } catch {
          // Log error but continue - we don't want to block progression
          // Error is already handled in persistProgressWithStageId
        }
      }

      // Store previous index before updating (for error recovery)
      const previousIndex = this.activeStageIndex;

      // Update active stage index
      if (nextIndex >= 0) {
        this.activeStageIndex = nextIndex;
        this.canProceed = false; // Reset validation state when changing steps
        this.dispatchFooterStateChanged(); // Notify parent of state change
        
        // Query validation state for new step
        this.queueValidationCheck(300);
      }

      // Save progress with the NEXT stage ID (the one we just moved to)
      // This must complete successfully to keep UI and database in sync
      if (targetStageId) {
        try {
          await this.persistProgressWithStageId(targetStageId);
        } catch {
          // If save fails, revert to previous stage to keep UI and DB in sync
          this.activeStageIndex = previousIndex;
          this.dispatchFooterStateChanged();
          this.showToast('Error', 'Failed to save progress. Please try again.', 'error');
        }
      } else {
        // If no next stage, this might be the last stage - mark as complete
        // Dispatch complete event
        this.dispatchEvent(new CustomEvent('complete', {
          detail: { vendorProgramId: this.vendorProgramId }
        }));
        // Save final progress
        await this.persistProgress();
      }

    } catch (error) {
      this.showToast('Error', extractErrorMessage(error, 'Failed to proceed to next step.'), 'error');
    }
  }

  async persistProgressWithStageId(stageId) {
    try {
      this.isSaving = true;
      await saveProgress({
        processId: this.processId,
        vendorProgramId: this.vendorProgramId,
        stageId: stageId
      });
      this.lastSavedTime = new Date();
      this.queueSaveIndicatorClear();
    } catch (error) {
      // Log error for debugging - progress save failures can cause sync issues
      console.error('Failed to save progress for stage:', stageId, error);
      // Re-throw to allow caller to handle
      throw error;
    } finally {
      this.isSaving = false;
    }
  }
  
  // Auto-save with debouncing
  scheduleAutoSave() {
    // Clear existing timeout
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    
    // Set new timeout for auto-save (2 seconds after last change)
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.saveTimeout = window.setTimeout(() => {
      this.autoSave();
    }, this.autoSaveDelay);
  }
  
  async autoSave() {
    if (!this.processId || !this.vendorProgramId || !this.activeStage?.Id) {
      return;
    }
    
    try {
      this.isSaving = true;
      await saveProgress({
        processId: this.processId,
        vendorProgramId: this.vendorProgramId,
        stageId: this.activeStage.Id
      });
      this.lastSavedTime = new Date();
      this.queueSaveIndicatorClear();
    } catch {
      // Silently fail - auto-save is not critical
    } finally {
      this.isSaving = false;
    }
  }

  async handleBack() {
    try {
      if (this.activeStageIndex > 0) {
        // Find the previous stage by looking for which stage has the current stage as its Next_Stage__c
        // This respects the actual stage relationships rather than just using array index
        const currentStageId = this.activeStage?.Id;
        let previousIndex = -1;
        let previousStageId = null;
        
        if (currentStageId) {
          // Find the stage that has the current stage as its Next_Stage__c
          const previousStage = this.stages.find(stage => stage.Next_Stage__c === currentStageId);
          if (previousStage) {
            previousIndex = this.stages.findIndex(stage => stage.Id === previousStage.Id);
            previousStageId = previousStage.Id;
          }
        }
        
        // Fallback to array index if no relationship found
        if (previousIndex < 0 && this.activeStageIndex > 0) {
          previousIndex = this.activeStageIndex - 1;
          previousStageId = this.stages[previousIndex]?.Id;
        }
        
        // Skip Step 9 (Recipient Groups) for non-admin users when going back
        if (previousIndex >= 0 && !this.isAdmin) {
          const previousStage = this.stages[previousIndex];
          const previousComponentName = previousStage?.Onboarding_Component_Library__r?.Component_API_Name__c;
          
          // If previous stage is Recipient Groups (Step 9), skip to the stage before it
          if (previousComponentName === 'vendorProgramOnboardingRecipientGroup') {
            // Find the stage that has Recipient Groups as its Next_Stage__c
            const stageBeforeRecipientGroups = this.stages.find(stage => 
              stage.Next_Stage__c === previousStage.Id
            );
            
            if (stageBeforeRecipientGroups) {
              previousIndex = this.stages.findIndex(stage => stage.Id === stageBeforeRecipientGroups.Id);
              previousStageId = stageBeforeRecipientGroups.Id;
            } else {
              // Fallback: Find Status Rules Engine stage
              const statusRulesIndex = this.stages.findIndex(stage => 
                stage.Onboarding_Component_Library__r?.Component_API_Name__c === 'vendorProgramOnboardingStatusRulesEngine'
              );
              
              if (statusRulesIndex >= 0) {
                previousIndex = statusRulesIndex;
                previousStageId = this.stages[previousIndex]?.Id;
              } else if (previousIndex > 0) {
                // Final fallback: go back one more stage
                previousIndex = previousIndex - 1;
                previousStageId = this.stages[previousIndex]?.Id;
              }
            }
          }
        }
        
        if (previousIndex >= 0) {
          // Mark current stage before going back (similar to forward navigation)
          if (this.activeStage?.Id) {
            try {
              await this.persistProgressWithStageId(this.activeStage.Id);
            } catch {
              // Error is already handled in persistProgressWithStageId
            }
          }
          
          this.activeStageIndex = previousIndex;
          this.canProceed = false; // Reset validation state when changing steps
          this.dispatchFooterStateChanged(); // Notify parent of state change
          
          // Save progress with the previous stage ID
          if (previousStageId) {
            await this.persistProgressWithStageId(previousStageId);
          } else {
            await this.persistProgress();
          }
          
          // Query validation state for new step
          this.queueValidationCheck(300);
        }
      }
    } catch {
      this.showToast('Error', 'Failed to go back to previous step.', 'error');
    }
  }

  // Footer button handlers
  handleBackClick() {
    // When footer Back is clicked, call the stage renderer's public method
    const stageRenderer = this.template.querySelector('c-onboarding-stage-renderer');
    if (stageRenderer) {
      stageRenderer.triggerFooterBack();
    }
  }

  handleNextClick() {
    // When footer Next is clicked, call the stage renderer's public method
    const stageRenderer = this.template.querySelector('c-onboarding-stage-renderer');
    if (stageRenderer) {
      stageRenderer.triggerFooterNext();
    }
  }

  // Handle validation state changes from step components
  handleValidationChanged(event) {
    event.stopPropagation(); // Prevent bubbling
    const { canProceed, nextDisabled } = event.detail || {};
    this.canProceed = canProceed !== undefined ? canProceed : !nextDisabled;
    this.dispatchFooterStateChanged(); // Notify parent of state change
  }

  // Query step component for validation state
  queryStepValidationState() {
    try {
      const stageRenderer = this.template.querySelector('c-onboarding-stage-renderer');
      if (!stageRenderer) {
        // Step component might not be loaded yet, try again
        this.queueValidationCheck(300);
        return;
      }

      // Try to access the step component's nextDisabled property
      // This is a fallback if the component doesn't dispatch validation events
      const stepComponent = stageRenderer.shadowRoot?.querySelector('[data-step-component]');
      if (stepComponent) {
        if (stepComponent.nextDisabled !== undefined) {
          this.canProceed = !stepComponent.nextDisabled;
        } else if (stepComponent.canProceed !== undefined) {
          this.canProceed = stepComponent.canProceed;
        }
      }
    } catch {
      // Silently fail - validation state query is not critical
    }
  }

  async persistProgress() {
    try {
      this.isSaving = true;
      await saveProgress({
        processId: this.processId,
        vendorProgramId: this.vendorProgramId,
        stageId: this.activeStage?.Id
      });
      this.lastSavedTime = new Date();
      this.queueSaveIndicatorClear();
    } catch {
      // Silently fail - progress save is not critical
    } finally {
      this.isSaving = false;
    }
  }
  
  // Listen for field changes from child components to trigger auto-save
  handleFieldChange() {
    // Schedule auto-save when fields change
    this.scheduleAutoSave();
  }
  
  async autoCompleteStage(stageId) {
    // Auto-complete a stage by creating a completion record
    // This is used when skipping stages (e.g., Step 9 for non-admin users)
    try {
      await saveProgress({
        processId: this.processId,
        vendorProgramId: this.vendorProgramId,
        stageId: stageId
      });
    } catch {
      // Silently fail - auto-completion is not critical
    }
  }

  disconnectedCallback() {
    // Clear any pending auto-save timeout
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
    }
    // Clear validation timeout
    if (this.validationTimeout) {
      clearTimeout(this.validationTimeout);
    }
    if (this.saveIndicatorTimeout) {
      clearTimeout(this.saveIndicatorTimeout);
    }
  }

  queueValidationCheck(delayMs) {
    if (this.validationTimeout) {
      clearTimeout(this.validationTimeout);
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.validationTimeout = window.setTimeout(() => {
      this.validationTimeout = null;
      this.queryStepValidationState();
    }, delayMs);
  }

  queueSaveIndicatorClear() {
    if (this.saveIndicatorTimeout) {
      clearTimeout(this.saveIndicatorTimeout);
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.saveIndicatorTimeout = window.setTimeout(() => {
      this.lastSavedTime = null;
      this.saveIndicatorTimeout = null;
    }, 3000);
  }
}
