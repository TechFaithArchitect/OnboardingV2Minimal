import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchRecipientGroups from '@salesforce/apex/VendorOnboardingWizardController.searchRecipientGroups';
import createRecipientGroup from '@salesforce/apex/VendorOnboardingWizardController.createRecipientGroup';
import createVendorProgramRecipientGroupLink from '@salesforce/apex/VendorOnboardingWizardController.createVendorProgramRecipientGroupLink';

export default class VendorProgramOnboardingVendorProgramRecipientGroup extends LightningElement {
    @api vendorProgramId;
    @api stepNumber;

    @track recipientGroups = [];
    @track selectedRecipientGroupId = '';
    @track newRecipientGroupName = '';
    @track isLoading = false;
    @track nextDisabled = true;

    handleSearchChange(event) {
        const searchText = event.target.value;
        if (searchText.length < 2) return;
        this.isLoading = true;

        searchRecipientGroups({ recipientGroupNameSearchText: searchText })
            .then(results => {
                this.recipientGroups = results;
            })
            .catch(error => {
                this.showToast('Error', 'Failed to search recipient groups.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRecipientGroupSelect(event) {
        this.selectedRecipientGroupId = event.detail.value;
        this.newRecipientGroupName = '';
        this.nextDisabled = false;
    }

    handleNewRecipientGroupNameChange(event) {
        this.newRecipientGroupName = event.target.value;
        this.selectedRecipientGroupId = '';
        this.nextDisabled = !this.newRecipientGroupName;
    }

    async handleCreateAndLink() {
        if (!this.newRecipientGroupName || !this.vendorProgramId) return;
        this.isLoading = true;

        try {
            const newGroup = { Name: this.newRecipientGroupName };
            const recipientGroupId = await createRecipientGroup({ recipientGroup: newGroup });

            const linkId = await createVendorProgramRecipientGroupLink({
                vendorProgramId: this.vendorProgramId,
                recipientGroupId
            });

            this.dispatchNext(linkId);
        } catch (err) {
            this.showToast('Error', 'Failed to create and link recipient group.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleLinkExisting() {
        if (!this.selectedRecipientGroupId || !this.vendorProgramId) return;
        this.isLoading = true;

        try {
            const linkId = await createVendorProgramRecipientGroupLink({
                vendorProgramId: this.vendorProgramId,
                recipientGroupId: this.selectedRecipientGroupId
            });

            this.dispatchNext(linkId);
        } catch (err) {
            this.showToast('Error', 'Failed to link existing recipient group.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    dispatchNext(vendorProgramRecipientGroupId) {
        this.dispatchEvent(new CustomEvent('next', {
            detail: { vendorProgramRecipientGroupId }
        }));
    }

    get recipientGroupOptions() {
        return this.recipientGroups.map(group => ({
            label: group.Name,
            value: group.Id
        }));
    }

    get cardTitle() {
        const step = this.stepNumber || '?';
        return `Step ${step}: Assign Recipient Group`;
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
