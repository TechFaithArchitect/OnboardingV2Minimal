import { LightningElement, api } from 'lwc';

export default class OnboardingRecentActivity extends LightningElement {
    @api activities = [];

    get hasActivities() {
        return this.activities && this.activities.length > 0;
    }

    get processedActivities() {
        if (!this.activities || this.activities.length === 0) {
            return [];
        }

        return this.activities.map(activity => {
            const processed = { ...activity };
            
            // Calculate time ago
            if (processed.LastModifiedDate) {
                const modifiedDate = new Date(processed.LastModifiedDate);
                const now = new Date();
                const diffMs = now - modifiedDate;
                const diffMins = Math.floor(diffMs / (1000 * 60));
                const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
                const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

                if (diffMins < 60) {
                    processed.timeAgo = diffMins + 'm';
                } else if (diffHours < 24) {
                    processed.timeAgo = diffHours + 'h';
                } else {
                    processed.timeAgo = diffDays + 'd';
                }
            } else {
                processed.timeAgo = 'N/A';
            }

            // Determine activity type and color
            if (processed.Status === 'Complete' || processed.Status === 'Setup Complete') {
                processed.activityType = 'completion';
                processed.activityClass = 'slds-text-color_success';
                processed.iconName = 'utility:success';
            } else if (processed.Status === 'Denied' || processed.Status === 'Blocked') {
                processed.activityType = 'blocked';
                processed.activityClass = 'slds-text-color_error';
                processed.iconName = 'utility:error';
            } else {
                processed.activityType = 'neutral';
                processed.activityClass = 'slds-text-color_default';
                processed.iconName = 'utility:info';
            }

            // Build activity summary
            processed.summary = this.buildActivitySummary(processed);

            return processed;
        });
    }

    buildActivitySummary(activity) {
        let summary = '';
        
        if (activity.AccountName && activity.VendorProgramName) {
            summary = `${activity.AccountName} - ${activity.VendorProgramName}`;
        } else if (activity.AccountName) {
            summary = activity.AccountName;
        } else {
            summary = 'Onboarding activity';
        }

        if (activity.Status) {
            summary += ` - Status: ${activity.Status}`;
        }

        return summary;
    }

    handleActivityClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (recordId) {
            this.dispatchEvent(
                new CustomEvent('view', {
                    detail: {
                        recordId: recordId
                    },
                    bubbles: true,
                    composed: true
                })
            );
        }
    }
}

