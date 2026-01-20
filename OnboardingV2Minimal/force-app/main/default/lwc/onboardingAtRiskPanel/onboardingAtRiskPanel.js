import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { extractErrorMessage } from 'c/utils';
import getOnboardingWithBlockingInfo from '@salesforce/apex/OnboardingHomeDashboardController.getOnboardingWithBlockingInfo';
import getBlockedOnboardingCount from '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingCount';
import getBlockedOnboardingIds from '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingIds';

export default class OnboardingAtRiskPanel extends NavigationMixin(LightningElement) {
    @api timeFilter = 'LAST_90_DAYS';
    @api vendorIds = [];
    @api programIds = [];
    
    @track blockedOnboarding = [];
    @track blockedCount = 0;
    @track isLoading = false;
    @track showDetails = false;

    columns = [
        { label: 'Account', fieldName: 'accountName', type: 'text' },
        { label: 'Vendor Program', fieldName: 'vendorProgramName', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { 
            label: 'Blocking Reasons', 
            fieldName: 'blockingReasons', 
            type: 'text',
            wrapText: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View Requirements', name: 'view_requirements' },
                    { label: 'View Record', name: 'view_record' }
                ]
            }
        }
    ];

    // Computed properties for wire parameters
    get timeFilterParam() {
        return this.timeFilter || 'LAST_90_DAYS';
    }

    get vendorFilterParam() {
        if (!this.vendorIds || this.vendorIds.length === 0) {
            return null;
        }
        return this.vendorIds;
    }

    get programFilterParam() {
        if (!this.programIds || this.programIds.length === 0) {
            return null;
        }
        return this.programIds;
    }

    @wire(getBlockedOnboardingCount, {
        timeFilter: '$timeFilterParam',
        vendorIds: '$vendorFilterParam',
        programIds: '$programFilterParam'
    })
    wiredBlockedCount({ error, data }) {
        if (data !== undefined) {
            this.blockedCount = data || 0;
        } else if (error) {
            console.error('Error loading blocked count:', error);
            this.showToast('Error', 'Failed to load blocked onboarding count.', 'error');
        }
    }

    async loadBlockedDetails() {
        if (this.blockedCount === 0) {
            this.blockedOnboarding = [];
            return;
        }

        this.isLoading = true;
        try {
            // Get the list of onboarding IDs that are blocked
            const blockedIds = await getBlockedOnboardingIds({
                timeFilter: this.timeFilterParam,
                vendorIds: this.vendorFilterParam,
                programIds: this.programFilterParam
            });
            
            if (blockedIds && blockedIds.length > 0) {
                const blockingInfo = await getOnboardingWithBlockingInfo({ 
                    onboardingIds: blockedIds 
                });
                
                // Transform to datatable format
                this.blockedOnboarding = (blockingInfo || [])
                    .filter(ob => (ob.IsBlocked || ob.IsAtRisk) && ob.BlockingReasons && ob.BlockingReasons.length > 0)
                    .map(ob => ({
                        Id: ob.Id,
                        accountName: ob.AccountName || '',
                        vendorProgramName: ob.VendorProgramName || '',
                        status: ob.Status || '',
                        blockingReasons: ob.BlockingReasons ? ob.BlockingReasons.join('; ') : '',
                        isAtRisk: ob.IsAtRisk || false
                    }));
            } else {
                this.blockedOnboarding = [];
            }
        } catch (error) {
            this.showToast('Error', extractErrorMessage(error, 'Failed to load blocked onboarding details.'), 'error');
            this.blockedOnboarding = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleToggleDetails() {
        this.showDetails = !this.showDetails;
        if (this.showDetails && this.blockedOnboarding.length === 0) {
            this.loadBlockedDetails();
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view_requirements') {
            this.navigateToRequirements(row.Id);
        } else if (action.name === 'view_record') {
            this.navigateToRecord(row.Id);
        }
    }

    handleViewAll() {
        // Navigate to a list view or filtered view of blocked onboarding
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Onboarding__c',
                actionName: 'list'
            }
        });
    }

    navigateToRequirements(recordId) {
        // Navigate to onboarding record page, ideally with focus on requirements panel
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
        // Dispatch event to parent to indicate we want to show requirements
        this.dispatchEvent(new CustomEvent('viewrequirements', {
            detail: { recordId },
            bubbles: true,
            composed: true
        }));
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
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

    get hasBlockedItems() {
        return this.blockedCount > 0;
    }

    get panelTitle() {
        return `Blocked / At Risk (${this.blockedCount})`;
    }

    get showDetailsLabel() {
        return this.showDetails ? 'Hide Details' : 'Show Details';
    }

    get showDetailsIcon() {
        return this.showDetails ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get blockedCountText() {
        return this.blockedCount === 1 ? 'is' : 'are';
    }

    get blockedCountPlural() {
        return this.blockedCount === 1 ? '' : 's';
    }
}
