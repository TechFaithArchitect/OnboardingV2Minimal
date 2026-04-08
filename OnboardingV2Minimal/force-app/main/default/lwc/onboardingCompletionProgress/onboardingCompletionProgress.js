import { LightningElement, api, track } from 'lwc';
import getCompletionPercent from '@salesforce/apex/OnboardingProgressController.getCompletionPercent';

const RELATED_LIST_CHANGE_EVENT_NAME = 'objectrelatedlistchange';
const ONBOARDING_REQUIREMENT_OBJECT_API_NAME = 'Onboarding_Requirement__c';

export default class OnboardingCompletionProgress extends LightningElement {
    @api recordId;
    @track progress = 0;
    @track lastUpdated = '';
    @track isLoading = false;

    relatedListChangeHandler;
    refreshInFlightPromise;

    connectedCallback() {
        this.relatedListChangeHandler = this.handleRelatedListChange.bind(this);
        if (typeof window !== 'undefined') {
            window.addEventListener(RELATED_LIST_CHANGE_EVENT_NAME, this.relatedListChangeHandler);
        }

        this.fetchProgress();
    }

    disconnectedCallback() {
        if (this.relatedListChangeHandler && typeof window !== 'undefined') {
            window.removeEventListener(RELATED_LIST_CHANGE_EVENT_NAME, this.relatedListChangeHandler);
        }
        this.relatedListChangeHandler = undefined;
    }

    handleRelatedListChange(event) {
        const detail = event?.detail || {};
        if (detail.objectApiName !== ONBOARDING_REQUIREMENT_OBJECT_API_NAME) {
            return;
        }
        if (this.recordId && detail.parentRecordId && detail.parentRecordId !== this.recordId) {
            return;
        }
        this.fetchProgress();
    }

    handleRefresh() {
        this.fetchProgress();
    }

    fetchProgress() {
        if (this.refreshInFlightPromise) {
            return this.refreshInFlightPromise;
        }

        this.isLoading = true;

        this.refreshInFlightPromise = getCompletionPercent({ recordId: this.recordId })
            .then(result => {
                this.progress = result;
                this.lastUpdated = new Date().toLocaleTimeString();
            })
            .catch(error => {
                console.error('Error fetching onboarding progress', error);
                this.progress = 0;
            })
            .finally(() => {
                this.isLoading = false;
                this.refreshInFlightPromise = undefined;
            });

        return this.refreshInFlightPromise;
    }

    get fillStyle() {
        return `width: ${this.progress}%;`;
    }
}
