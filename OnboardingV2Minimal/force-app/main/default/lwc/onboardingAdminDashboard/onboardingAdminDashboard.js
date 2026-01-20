import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSystemHealthMetrics from '@salesforce/apex/OnboardingAdminDashboardController.getSystemHealthMetrics';

export default class OnboardingAdminDashboard extends LightningElement {
    @track metrics = {
        validationFailures24h: 0,
        validationFailuresTrend: 0,
        messageFailures24h: 0,
        messageFailuresTrend: 0,
        webhookFailures24h: 0,
        webhookFailuresTrend: 0,
        platformEventVolume1h: 0,
        activeFollowUpQueues: 0,
        overrideOperations7d: 0
    };

    @track alerts = [];
    @track isLoading = true;

    @wire(getSystemHealthMetrics)
    wiredMetrics({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.metrics = {
                validationFailures24h: data.validationFailures24h || 0,
                validationFailuresTrend: data.validationFailuresTrend || 0,
                messageFailures24h: data.messageFailures24h || 0,
                messageFailuresTrend: data.messageFailuresTrend || 0,
                webhookFailures24h: data.webhookFailures24h || 0,
                webhookFailuresTrend: data.webhookFailuresTrend || 0,
                platformEventVolume1h: data.platformEventVolume1h || 0,
                activeFollowUpQueues: data.activeFollowUpQueues || 0,
                overrideOperations7d: data.overrideOperations7d || 0
            };
            this.evaluateAlerts();
        } else if (error) {
            console.error('Error loading metrics:', error);
            this.showError('Failed to load system health metrics');
        }
    }

    evaluateAlerts() {
        this.alerts = [];
        
        // Platform Event volume alert
        if (this.metrics.platformEventVolume1h > 1500) {
            this.alerts.push({
                type: 'error',
                title: 'High Platform Event Volume',
                message: `${this.metrics.platformEventVolume1h} events in the last hour (threshold: 1,500)`,
                icon: 'utility:warning'
            });
        } else if (this.metrics.platformEventVolume1h > 1000) {
            this.alerts.push({
                type: 'warning',
                title: 'Elevated Platform Event Volume',
                message: `${this.metrics.platformEventVolume1h} events in the last hour`,
                icon: 'utility:info'
            });
        }

        // Validation failures alert
        if (this.metrics.validationFailures24h > 50) {
            this.alerts.push({
                type: 'error',
                title: 'High Validation Failure Rate',
                message: `${this.metrics.validationFailures24h} failures in the last 24 hours`,
                icon: 'utility:error'
            });
        }

        // Message failures alert
        if (this.metrics.messageFailures24h > 20) {
            this.alerts.push({
                type: 'error',
                title: 'High Message Failure Rate',
                message: `${this.metrics.messageFailures24h} message failures in the last 24 hours`,
                icon: 'utility:error'
            });
        }
    }

    get validationFailuresStatus() {
        if (this.metrics.validationFailures24h === 0) return 'success';
        if (this.metrics.validationFailures24h < 10) return 'warning';
        return 'error';
    }

    get messageFailuresStatus() {
        if (this.metrics.messageFailures24h === 0) return 'success';
        if (this.metrics.messageFailures24h < 5) return 'warning';
        return 'error';
    }

    get webhookFailuresStatus() {
        if (this.metrics.webhookFailures24h === 0) return 'success';
        if (this.metrics.webhookFailures24h < 5) return 'warning';
        return 'error';
    }

    get platformEventStatus() {
        if (this.metrics.platformEventVolume1h < 1000) return 'success';
        if (this.metrics.platformEventVolume1h < 1500) return 'warning';
        return 'error';
    }

    get validationFailuresCardStyle() {
        return `border-left: 4px solid ${this.getStatusColor(this.validationFailuresStatus)};`;
    }

    get messageFailuresCardStyle() {
        return `border-left: 4px solid ${this.getStatusColor(this.messageFailuresStatus)};`;
    }

    get webhookFailuresCardStyle() {
        return `border-left: 4px solid ${this.getStatusColor(this.webhookFailuresStatus)};`;
    }

    get platformEventCardStyle() {
        return `border-left: 4px solid ${this.getStatusColor(this.platformEventStatus)};`;
    }

    get validationTrendIcon() {
        return this.metrics.validationFailuresTrend > 0 ? 'utility:arrowup' : 'utility:arrowdown';
    }

    get messageTrendIcon() {
        return this.metrics.messageFailuresTrend > 0 ? 'utility:arrowup' : 'utility:arrowdown';
    }

    get webhookTrendIcon() {
        return this.metrics.webhookFailuresTrend > 0 ? 'utility:arrowup' : 'utility:arrowdown';
    }

    getStatusColor(status) {
        const colors = {
            success: '#04844b',
            warning: '#ffb75d',
            error: '#c23934'
        };
        return colors[status] || colors.success;
    }

    handleMetricClick(event) {
        const metricType = event.currentTarget.dataset.metric;
        // Navigate to appropriate tab
        this.dispatchEvent(new CustomEvent('navigatetab', {
            detail: { tab: this.getTabForMetric(metricType) }
        }));
    }

    getTabForMetric(metricType) {
        const tabMap = {
            'validation': 'validation-failures',
            'message': 'messaging-issues',
            'webhook': 'adobe-failures',
            'override': 'override-audit'
        };
        return tabMap[metricType] || 'dashboard';
    }

    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
}

