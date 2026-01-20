import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import searchVendorProgramGroups from '@salesforce/apex/VendorOnboardingWizardController.searchVendorProgramGroups';
import createVendorProgramGroup from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramGroup';
import searchVendorProgramRequirementGroups from '@salesforce/apex/VendorOnboardingWizardController.searchVendorProgramRequirementGroups';
import createVendorProgramRequirementGroup from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRequirementGroup';
import searchRecipientGroups from '@salesforce/apex/VendorOnboardingWizardController.searchRecipientGroups';
import createRecipientGroup from '@salesforce/apex/VendorOnboardingWizardController.createRecipientGroup';
import searchStatusRulesEngines from '@salesforce/apex/VendorOnboardingWizardController.searchStatusRulesEngines';
import createOnboardingStatusRulesEngine from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingStatusRulesEngine';
import createVendorProgramRecipientGroupLink from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRecipientGroupLink';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class VendorProgramQuickActions extends NavigationMixin(LightningElement) {
    @api recordId; // Vendor Program (Vendor_Customization__c) ID
    
    @track showCreateGroupModal = false;
    @track showCreateRequirementGroupModal = false;
    @track showCreateRecipientGroupModal = false;
    @track showCreateRulesEngineModal = false;
    @track showLinkGroupsModal = false;
    
    // Vendor Program Group
    @track groupSearchText = '';
    @track groups = [];
    @track selectedGroupId = null;
    @track newGroupName = '';
    @track isLoadingGroups = false;
    
    // Vendor Program Requirement Group
    @track requirementGroupSearchText = '';
    @track requirementGroups = [];
    @track selectedRequirementGroupId = null;
    @track newRequirementGroupName = '';
    @track isLoadingRequirementGroups = false;
    
    // Recipient Group
    @track recipientGroupSearchText = '';
    @track recipientGroups = [];
    @track selectedRecipientGroupId = null;
    @track newRecipientGroupName = '';
    @track isLoadingRecipientGroups = false;
    
    // Status Rules Engine
    @track rulesEngineSearchText = '';
    @track rulesEngines = [];
    @track selectedRulesEngineId = null;
    @track newRulesEngineName = '';
    @track isLoadingRulesEngines = false;
    
    // No need to load vendor program - just create pieces

    // ============================================
    // MODAL HANDLERS
    // ============================================
    
    handleOpenCreateGroupModal() {
        this.showCreateGroupModal = true;
        this.resetGroupModal();
    }

    handleOpenCreateRequirementGroupModal() {
        this.showCreateRequirementGroupModal = true;
        this.resetRequirementGroupModal();
    }

    handleOpenCreateRecipientGroupModal() {
        this.showCreateRecipientGroupModal = true;
        this.resetRecipientGroupModal();
    }

    handleOpenCreateRulesEngineModal() {
        this.showCreateRulesEngineModal = true;
        this.resetRulesEngineModal();
    }

    handleOpenLinkGroupsModal() {
        this.showLinkGroupsModal = true;
    }

    handleCloseModal() {
        this.showCreateGroupModal = false;
        this.showCreateRequirementGroupModal = false;
        this.showCreateRecipientGroupModal = false;
        this.showCreateRulesEngineModal = false;
        this.showLinkGroupsModal = false;
    }

    // ============================================
    // VENDOR PROGRAM GROUP
    // ============================================
    
    resetGroupModal() {
        this.groupSearchText = '';
        this.groups = [];
        this.selectedGroupId = null;
        this.newGroupName = '';
    }

    handleGroupSearchChange(event) {
        this.groupSearchText = event.target.value;
    }

    async handleSearchGroups() {
        if (!this.groupSearchText || this.groupSearchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }
        this.isLoadingGroups = true;
        try {
            this.groups = await searchVendorProgramGroups({ vendorProgramGroupNameSearchText: this.groupSearchText });
        } catch (error) {
            this.showToast('Error', 'Failed to search groups.', 'error');
        } finally {
            this.isLoadingGroups = false;
        }
    }

    handleGroupSelect(event) {
        this.selectedGroupId = event.detail.value;
        this.newGroupName = '';
    }

    handleNewGroupNameChange(event) {
        this.newGroupName = event.target.value;
    }

    async handleCreateGroup() {
        if (!this.newGroupName || this.newGroupName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a group name.', 'warning');
            return;
        }
        try {
            const groupId = await createVendorProgramGroup({ vendorProgramGroup: { Name: this.newGroupName.trim() } });
            this.selectedGroupId = groupId;
            this.showToast('Success', 'Vendor Program Group created successfully. You can assign it to this Vendor Program using the Vendor_Program_Group__c field.', 'success');
            this.handleCloseModal();
            this.refreshRecord();
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to create group. ' + errorMessage, 'error');
        }
    }

    get groupOptions() {
        return this.groups.map(g => ({
            label: g.Name,
            value: g.Id
        }));
    }

    get canProceedWithGroup() {
        return !!this.selectedGroupId;
    }

    // ============================================
    // VENDOR PROGRAM REQUIREMENT GROUP
    // ============================================
    
    resetRequirementGroupModal() {
        this.requirementGroupSearchText = '';
        this.requirementGroups = [];
        this.selectedRequirementGroupId = null;
        this.newRequirementGroupName = '';
    }

    handleRequirementGroupSearchChange(event) {
        this.requirementGroupSearchText = event.target.value;
    }

    async handleSearchRequirementGroups() {
        if (!this.requirementGroupSearchText || this.requirementGroupSearchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }
        this.isLoadingRequirementGroups = true;
        try {
            this.requirementGroups = await searchVendorProgramRequirementGroups({ 
                requirementGroupNameSearchText: this.requirementGroupSearchText 
            });
        } catch (error) {
            this.showToast('Error', 'Failed to search requirement groups.', 'error');
        } finally {
            this.isLoadingRequirementGroups = false;
        }
    }

    handleRequirementGroupSelect(event) {
        this.selectedRequirementGroupId = event.detail.value;
        this.newRequirementGroupName = '';
    }

    handleNewRequirementGroupNameChange(event) {
        this.newRequirementGroupName = event.target.value;
    }

    async handleCreateRequirementGroup() {
        if (!this.newRequirementGroupName || this.newRequirementGroupName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a requirement group name.', 'warning');
            return;
        }
        try {
            const groupId = await createVendorProgramRequirementGroup({ 
                vendorProgramRequirementGroup: { Name: this.newRequirementGroupName.trim() } 
            });
            this.selectedRequirementGroupId = groupId;
            this.showToast('Success', 'Vendor Program Requirement Group created successfully. You can assign it to this Vendor Program using the Vendor_Program_Requirement_Group__c field.', 'success');
            this.handleCloseModal();
            this.refreshRecord();
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to create requirement group. ' + errorMessage, 'error');
        }
    }

    get requirementGroupOptions() {
        return this.requirementGroups.map(g => ({
            label: g.Name,
            value: g.Id
        }));
    }

    get canProceedWithRequirementGroup() {
        return !!this.selectedRequirementGroupId;
    }

    // ============================================
    // RECIPIENT GROUP
    // ============================================
    
    resetRecipientGroupModal() {
        this.recipientGroupSearchText = '';
        this.recipientGroups = [];
        this.selectedRecipientGroupId = null;
        this.newRecipientGroupName = '';
    }

    handleRecipientGroupSearchChange(event) {
        this.recipientGroupSearchText = event.target.value;
    }

    async handleSearchRecipientGroups() {
        if (!this.recipientGroupSearchText || this.recipientGroupSearchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }
        this.isLoadingRecipientGroups = true;
        try {
            this.recipientGroups = await searchRecipientGroups({ 
                recipientGroupNameSearchText: this.recipientGroupSearchText 
            });
        } catch (error) {
            this.showToast('Error', 'Failed to search recipient groups.', 'error');
        } finally {
            this.isLoadingRecipientGroups = false;
        }
    }

    handleRecipientGroupSelect(event) {
        this.selectedRecipientGroupId = event.detail.value;
        this.newRecipientGroupName = '';
    }

    handleNewRecipientGroupNameChange(event) {
        this.newRecipientGroupName = event.target.value;
    }

    async handleCreateRecipientGroup() {
        if (!this.newRecipientGroupName || this.newRecipientGroupName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a recipient group name.', 'warning');
            return;
        }
        try {
            const groupId = await createRecipientGroup({ 
                recipientGroup: { Name: this.newRecipientGroupName.trim() } 
            });
            this.selectedRecipientGroupId = groupId;
            // Optionally link to vendor program if recordId exists
            if (this.recordId && groupId) {
                try {
                    await createVendorProgramRecipientGroupLink({
                        vendorProgramId: this.recordId,
                        recipientGroupId: groupId
                    });
                    this.showToast('Success', 'Recipient Group created and linked to Vendor Program.', 'success');
                } catch (linkError) {
                    // Non-fatal - group was created, just not linked
                    this.showToast('Success', 'Recipient Group created successfully. You can link it manually from the Recipient Groups related list.', 'success');
                }
            } else {
                this.showToast('Success', 'Recipient Group created successfully. You can link it to this Vendor Program from the Recipient Groups related list.', 'success');
            }
            this.handleCloseModal();
            this.refreshRecord();
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to create recipient group. ' + errorMessage, 'error');
        }
    }

    get recipientGroupOptions() {
        return this.recipientGroups.map(g => ({
            label: g.Name,
            value: g.Id
        }));
    }

    get canProceedWithRecipientGroup() {
        return !!this.selectedRecipientGroupId;
    }

    // ============================================
    // STATUS RULES ENGINE
    // ============================================
    
    resetRulesEngineModal() {
        this.rulesEngineSearchText = '';
        this.rulesEngines = [];
        this.selectedRulesEngineId = null;
        this.newRulesEngineName = '';
    }

    handleRulesEngineSearchChange(event) {
        this.rulesEngineSearchText = event.target.value;
    }

    async handleSearchRulesEngines() {
        if (!this.rulesEngineSearchText || this.rulesEngineSearchText.length < 2) {
            this.showToast('Search Required', 'Please enter at least 2 characters to search.', 'warning');
            return;
        }
        this.isLoadingRulesEngines = true;
        try {
            this.rulesEngines = await searchStatusRulesEngines({ 
                nameSearchText: this.rulesEngineSearchText 
            });
        } catch (error) {
            this.showToast('Error', 'Failed to search rules engines.', 'error');
        } finally {
            this.isLoadingRulesEngines = false;
        }
    }

    handleRulesEngineSelect(event) {
        this.selectedRulesEngineId = event.detail.value;
        this.newRulesEngineName = '';
    }

    handleNewRulesEngineNameChange(event) {
        this.newRulesEngineName = event.target.value;
    }

    async handleCreateRulesEngine() {
        if (!this.newRulesEngineName || this.newRulesEngineName.trim().length === 0) {
            this.showToast('Name Required', 'Please enter a rules engine name.', 'warning');
            return;
        }
        try {
            const rulesEngineId = await createOnboardingStatusRulesEngine({ 
                onboardingStatusRulesEngine: { Name: this.newRulesEngineName.trim() } 
            });
            this.selectedRulesEngineId = rulesEngineId;
            this.showToast('Success', 'Status Rules Engine created successfully. You can configure rules and link it to Vendor Program Groups.', 'success');
            this.handleCloseModal();
            this.refreshRecord();
        } catch (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to create rules engine. ' + errorMessage, 'error');
        }
    }

    get rulesEngineOptions() {
        return this.rulesEngines.map(e => ({
            label: e.Name,
            value: e.Id
        }));
    }

    get canProceedWithRulesEngine() {
        return !!this.selectedRulesEngineId;
    }

    // ============================================
    // UTILITY METHODS
    // ============================================
    
    refreshRecord() {
        // Notify that record should be refreshed
        if (this.recordId) {
            getRecordNotifyChange([{ recordId: this.recordId }]);
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}

