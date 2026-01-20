import { LightningElement, api, track } from 'lwc';
import getTerritoryRoleAssignments 
    from '@salesforce/apex/VendorOnboardingWizardController.getTerritoryRoleAssignments';
import getActiveUsers 
    from '@salesforce/apex/VendorOnboardingWizardController.getAssignableUsers';
import getPublicGroups 
    from '@salesforce/apex/VendorOnboardingWizardController.getPublicGroups';
import createRecipientGroupMember 
    from '@salesforce/apex/VendorOnboardingWizardController.createRecipientGroupMember';

export default class VendorProgramOnboardingRecipientGroupMembers extends LightningElement {
    @api recipientGroupId;
    @api vendorProgramRecipientGroupId;
    @api stepNumber;

    @track territoryRoleAssignmentOptions = [];
    @track userOptions = [];
    @track publicGroupOptions = [];

    @track selectedTerritoryRoleAssignmentId = '';
    @track selectedUserId = '';
    @track selectedPublicGroupId = '';

    @track successMessage = '';
    @track errorMessage = '';
    @track isLoading = false;

    async connectedCallback() {
        this.isLoading = true;
        try {
            const [roles, users, publicGroups] = await Promise.all([
                getTerritoryRoleAssignments(),
                getActiveUsers(),
                getPublicGroups()
            ]);

            this.territoryRoleAssignmentOptions = roles.map(r => ({
                label: r.Name,
                value: r.Id
            }));

            this.userOptions = users.map(u => ({
                label: u.Name,
                value: u.Id
            }));

            this.publicGroupOptions = publicGroups.map(g => ({
                label: g.Name,
                value: g.Id
            }));
        } catch (error) {
            this.errorMessage = 'Error loading selection lists.';
        } finally {
            this.isLoading = false;
        }
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handlePublicGroupChange(event) {
        this.selectedPublicGroupId = event.detail.value;
    }

    handleTerritoryRoleAssignmentChange(event) {
        this.selectedTerritoryRoleAssignmentId = event.detail.value;
    }

    async handleAddMember() {
        this.errorMessage = '';
        this.successMessage = '';
        this.isLoading = true;

        try {
            const record = {
                Recipient_Group__c: this.recipientGroupId,
                Vendor_Program_Recipient_Group__c: this.vendorProgramRecipientGroupId,
                User__c: this.selectedUserId || null,
                Group__c: this.selectedPublicGroupId || null,
                Territory_Role_Assignment__c: this.selectedTerritoryRoleAssignmentId || null
            };

            await createRecipientGroupMember({ recipientGroupMember: record });

            this.successMessage = 'Member successfully added.';
            this.clearSelections();
        } catch (error) {
            this.errorMessage = 'Unable to add group member.';
        } finally {
            this.isLoading = false;
        }
    }

    clearSelections() {
        this.selectedUserId = '';
        this.selectedPublicGroupId = '';
        this.selectedTerritoryRoleAssignmentId = '';
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next', {
            detail: {
                recipientGroupId: this.recipientGroupId,
                vendorProgramRecipientGroupId: this.vendorProgramRecipientGroupId
            }
        }));
    }

    get cardTitle() {
        const step = this.stepNumber || '?';
        return `Step ${step}: Add Recipient Group Members`;
    }
}
