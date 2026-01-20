import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import searchRecipientGroups from '@salesforce/apex/VendorOnboardingWizardController.searchRecipientGroups';
import createRecipientGroup from '@salesforce/apex/VendorOnboardingWizardController.createRecipientGroup';
import createRecipientGroupMember from '@salesforce/apex/VendorOnboardingWizardController.createRecipientGroupMember';
import createVendorProgramRecipientGroupLink from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRecipientGroupLink';
import getRecipientGroupsForVendorProgram from '@salesforce/apex/VendorOnboardingWizardController.getRecipientGroupsForVendorProgram';
import getRecipientGroupMembers from '@salesforce/apex/VendorOnboardingWizardController.getRecipientGroupMembers';
import getAssignableUsers from '@salesforce/apex/VendorOnboardingWizardController.getAssignableUsers';
import getGroupTypePicklistValues from '@salesforce/apex/VendorOnboardingWizardController.getGroupTypePicklistValues';
import isCurrentUserAdmin from '@salesforce/apex/VendorOnboardingWizardController.isCurrentUserAdmin';

export default class VendorProgramOnboardingRecipientGroup extends OnboardingStepBase {
  stepName = 'Recipient Group';
  
  @api vendorProgramId;
  @api stageId;

  @track searchText = '';
  @track recipientGroups = [];
  @track existingGroups = [];
  @track selectedRecipientGroupId = '';
  @track newGroupName = '';
  @track newGroupType = 'User';
  @track groupTypeOptions = [];
  @track nextDisabled = true;
  @track showCreateForm = false;
  @track isLoading = false;
  @track currentView = 'select'; // 'select', 'create', 'addMembers'
  @track createdGroupId = null;
  @track assignableUsers = [];
  @track selectedUserIds = [];
  @track groupMembers = [];
  @track isAdmin = false;

  @wire(getGroupTypePicklistValues)
  wiredGroupTypeOptions({ error, data }) {
    if (data) {
      this.groupTypeOptions = data;
    } else if (error) {
      this.handleError(error, 'Failed to load Group Type options');
      this.groupTypeOptions = [{ label: 'User', value: 'User' }];
    }
  }

  connectedCallback() {
    super.connectedCallback(); // Call base class for event listeners
    this.checkAdminStatus();
    if (this.isAdmin) {
      this.loadExistingGroups();
      this.loadAssignableUsers();
    } else {
      // Non-admin users should skip this step - auto-advance to next
      this.handleSkipForNonAdmin();
    }
  }

  handleFooterNextClick() {
    // Recipient Group step can always proceed (it's optional/auto-skip for non-admin)
    // For admin users, they can always proceed even without selecting a group
    if (this.canProceed) {
      this.proceedToNext();
    }
  }

  get canProceed() {
    // Recipient Group step can always proceed (optional step, can skip)
    return true;
  }

  proceedToNext() {
    this.dispatchNextEvent({});
  }

  async checkAdminStatus() {
    try {
      this.isAdmin = await isCurrentUserAdmin();
    } catch (error) {
      this.handleError(error, 'Failed to check admin status');
      this.isAdmin = false;
    }
  }

  handleSkipForNonAdmin() {
    // Non-admin users skip this step - dispatch next event immediately
    this.dispatchNextEvent({
      vendorProgramId: this.vendorProgramId,
      skipped: true
    });
  }

  async loadExistingGroups() {
    this.isLoading = true;
    try {
      this.existingGroups = await getRecipientGroupsForVendorProgram({ vendorProgramId: this.vendorProgramId });
    } catch (err) {
      this.handleError(err, 'Failed to load existing recipient groups');
    } finally {
      this.isLoading = false;
    }
  }

  async loadAssignableUsers() {
    try {
      this.assignableUsers = await getAssignableUsers();
    } catch (err) {
      this.handleError(err, 'Failed to load assignable users');
    }
  }

  async loadGroupMembers(groupId) {
    try {
      this.groupMembers = await getRecipientGroupMembers({ recipientGroupId: groupId });
    } catch (err) {
      this.handleError(err, 'Failed to load group members');
    }
  }

  handleSearchChange(e) {
    this.searchText = e.target.value;
  }

  handleNewGroupChange(e) {
    this.newGroupName = e.target.value;
    this.validateCreateForm();
  }

  handleGroupTypeChange(e) {
    this.newGroupType = e.detail.value;
    this.validateCreateForm();
  }

  validateCreateForm() {
    const hasSelectedGroup = !!this.selectedRecipientGroupId;
    const hasValidCreateForm = !!(this.newGroupName?.trim() && this.newGroupType);
    this.nextDisabled = !(hasSelectedGroup || hasValidCreateForm);
  }

  async searchGroups() {
    if (!this.searchText || this.searchText.trim().length === 0) {
      this.recipientGroups = [];
      return;
    }
    try {
      this.recipientGroups = await searchRecipientGroups({ recipientGroupNameSearchText: this.searchText.trim() });
    } catch (err) {
      this.handleError(err, 'Failed to search recipient groups');
      this.recipientGroups = [];
    }
  }

  handleGroupSelect(e) {
    this.selectedRecipientGroupId = e.detail.value;
    this.newGroupName = '';
    this.newGroupType = 'User';
    this.showCreateForm = false;
    this.validateCreateForm();
  }

  async createGroup() {
    if (!this.newGroupName?.trim() || !this.newGroupType) {
      this.showToast('Required Fields Missing', 'Please fill in Name and Group Type.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      const groupId = await createRecipientGroup({
        recipientGroup: { 
          Name: this.newGroupName.trim(),
          Group_Type__c: this.newGroupType
        }
      });

      this.createdGroupId = groupId;
      this.selectedRecipientGroupId = groupId;
      this.currentView = 'addMembers';
      this.showCreateForm = false;
      this.showToast('Success', 'Recipient Group created successfully! Now add members.', 'success');
    } catch (err) {
      this.handleError(err, 'Failed to create recipient group');
    } finally {
      this.isLoading = false;
    }
  }

  handleUserSelection(event) {
    this.selectedUserIds = event.detail.value;
  }

  async addMembers() {
    if (!this.selectedRecipientGroupId || !this.selectedUserIds || this.selectedUserIds.length === 0) {
      this.showToast('Selection Required', 'Please select at least one user to add to the group.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      const memberPromises = this.selectedUserIds.map(userId => 
        createRecipientGroupMember({
          recipientGroupMember: {
            Recipient_Group__c: this.selectedRecipientGroupId,
            Recipient_User__c: userId,
            Member_Type__c: 'User',
            Recipient_Type__c: 'To'
          }
        })
      );

      await Promise.all(memberPromises);
      await this.loadGroupMembers(this.selectedRecipientGroupId);
      this.showToast('Success', 'Members added successfully!', 'success');
    } catch (err) {
      this.handleError(err, 'Failed to add members to recipient group');
    } finally {
      this.isLoading = false;
    }
  }

  async linkGroupToVendorProgram() {
    if (!this.selectedRecipientGroupId) {
      this.showToast('Selection Required', 'Please select or create a Recipient Group.', 'warning');
      return;
    }

    this.isLoading = true;
    try {
      await createVendorProgramRecipientGroupLink({
        vendorProgramId: this.vendorProgramId,
        recipientGroupId: this.selectedRecipientGroupId
      });

      this.showToast('Success', 'Recipient Group linked to Vendor Program!', 'success');
      
      // Proceed to next step
      this.dispatchNextEvent({
        vendorProgramId: this.vendorProgramId,
        recipientGroupId: this.selectedRecipientGroupId
      });
    } catch (err) {
      this.handleError(err, 'Failed to link recipient group to vendor program');
    } finally {
      this.isLoading = false;
    }
  }

  handleUseExisting() {
    this.currentView = 'select';
  }

  handleCreateNew() {
    this.currentView = 'create';
    this.showCreateForm = true;
  }

  toggleCreateForm() {
    this.showCreateForm = !this.showCreateForm;
    if (!this.showCreateForm) {
      this.newGroupName = '';
      this.newGroupType = 'User';
      this.validateCreateForm();
    }
  }

  handleFooterBackClick() {
    // Override: custom back logic for view state management
    this.handleBack();
  }

  handleBack() {
    if (this.currentView === 'addMembers') {
      this.currentView = 'create';
    } else if (this.currentView === 'create') {
      this.currentView = 'select';
    } else {
      this.dispatchBackEvent();
    }
  }

  get groupOptions() {
    return this.recipientGroups.map(g => ({
      label: g.Name,
      value: g.Id
    }));
  }

  get userOptions() {
    return this.assignableUsers.map(u => ({
      label: u.Name + (u.Email ? ` (${u.Email})` : ''),
      value: u.Id
    }));
  }

  get createButtonLabel() {
    return this.showCreateForm ? 'Cancel Create' : 'Create New Group';
  }

  get isSelectView() {
    return this.currentView === 'select';
  }

  get isCreateView() {
    return this.currentView === 'create';
  }

  get isAddMembersView() {
    return this.currentView === 'addMembers';
  }

  get hasExistingGroups() {
    return this.existingGroups && this.existingGroups.length > 0;
  }

  get isAddMembersDisabled() {
    return !this.selectedUserIds || this.selectedUserIds.length === 0;
  }

  existingGroupsColumns = [
    { label: 'Recipient Group', fieldName: 'Recipient_Group__r.Name' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' }
  ];

  memberColumns = [
    { label: 'User Name', fieldName: 'Recipient_User__r.Name' },
    { label: 'Email', fieldName: 'Recipient_User__r.Email' },
    { label: 'Member Type', fieldName: 'Member_Type__c' },
    { label: 'Recipient Type', fieldName: 'Recipient_Type__c' }
  ];

}
