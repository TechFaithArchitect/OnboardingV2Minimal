import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OnboardingAdminToolsPanel extends NavigationMixin(LightningElement) {
    // Navigation helpers
    navigateToMessagingIssuesList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Follow_Up_Queue__c',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }

    navigateToFollowUpList(filterName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Follow_Up_Queue__c',
                actionName: 'list'
            },
            state: { filterName }
        });
    }

    handleViewPending() {
        this.navigateToFollowUpList('Pending');
    }

    handleViewPendingRetry() {
        this.navigateToFollowUpList('Pending_Retry');
    }

    handleViewFailed() {
        this.navigateToFollowUpList('Failed');
    }

    handleViewDueToday() {
        this.navigateToFollowUpList('Due_Today');
    }

    navigateToOverrideAuditList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Onboarding_External_Override_Log__c',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }

    // Admin shortcuts that are still stubs (for future navigation)
    handleManageRequirements() {
        this.showToast('Info', 'Navigate to Requirements management page', 'info');
    }

    handleManageStatusRules() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__onboardingStatusRulesEngine'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
