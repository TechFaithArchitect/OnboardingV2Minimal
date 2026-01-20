import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getResumeContext from '@salesforce/apex/OnboardingApplicationService.getResumeContext';

export default class OnboardingResumePanel extends NavigationMixin(LightningElement) {
    @api recordId; // Renamed from onboardingId - properties starting with "on" are reserved for event handlers
    @track resumeContext = null;
    @track isLoading = false;

    @wire(getResumeContext, { onboardingId: '$recordId' })
    wiredResumeContext({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.resumeContext = data;
        } else if (error) {
            console.error('Error loading resume context:', error);
            this.showError('Failed to load resume information');
        }
    }

    handleResume() {
        if (!this.resumeContext || !this.resumeContext.nextIncompleteRequirement) {
            this.showWarning('No incomplete requirements found');
            return;
        }

        const nextReq = this.resumeContext.nextIncompleteRequirement;
        const fieldId = nextReq.firstIncompleteField?.id;

        // Navigate to the requirement or field
        if (fieldId) {
            // Navigate to specific field
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: fieldId,
                    actionName: 'view'
                }
            });
        } else {
            // Navigate to requirement
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: nextReq.id,
                    actionName: 'view'
                }
            });
        }
    }

    get hasIncompleteRequirements() {
        return this.resumeContext && 
               this.resumeContext.nextIncompleteRequirement != null;
    }

    get completionPercentage() {
        return this.resumeContext?.completionPercentage || 0;
    }

    get lastCompletedRequirementName() {
        return this.resumeContext?.lastCompletedRequirement?.name || 'None';
    }

    get nextIncompleteRequirementName() {
        return this.resumeContext?.nextIncompleteRequirement?.name || 'None';
    }

    get progressBarStyle() {
        return `width: ${this.completionPercentage}%`;
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning'
        }));
    }
}

