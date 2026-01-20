import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OnboardingDealerOnboardingModal extends LightningElement {
    @api eligibleAccounts = [];
    @track selectedAccountId = null;

    get eligibleAccountsOptions() {
        return (this.eligibleAccounts || []).map(acc => ({
            label: acc.Name + (acc.Territory ? ' - ' + acc.Territory : ''),
            value: acc.Id
        }));
    }

    handleAccountSelect(event) {
        this.selectedAccountId = event.detail.value;
    }

    handleConfirmStart() {
        if (this.selectedAccountId) {
            this.dispatchEvent(
                new CustomEvent('start', {
                    detail: { accountId: this.selectedAccountId }
                })
            );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Selection Required',
                    message: 'Please select an account to start onboarding.',
                    variant: 'warning'
                })
            );
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}


