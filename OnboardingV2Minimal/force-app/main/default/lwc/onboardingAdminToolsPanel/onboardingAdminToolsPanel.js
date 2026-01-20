import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OnboardingAdminToolsPanel extends NavigationMixin(LightningElement) {
    // Navigation helpers
    navigateToValidationFailuresList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Validation_Failure__c',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }

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

    handleStageDependencies() {
        this.showToast('Info', 'Navigate to Stage Dependencies management', 'info');
    }

    handleVendorProgramWizard() {
        this.showToast('Info', 'Navigate to Vendor Program Wizard configuration', 'info');
    }

    handleComponentLibrary() {
        this.showToast('Info', 'Navigate to Component Library', 'info');
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


