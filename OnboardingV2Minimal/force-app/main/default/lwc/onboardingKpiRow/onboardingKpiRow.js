import { LightningElement, api } from 'lwc';

export default class OnboardingKpiRow extends LightningElement {
    @api summary; // Map<String, Integer> from Apex
    @api vendorSummary; // Map<String, Integer> from Apex
    @api blockedCount; // Integer

    get tiles() {
        // Build a normalized array of KPI tile configs
        return [
            {
                key: 'activeOnboarding',
                label: 'Active Dealer Onboarding',
                value: this.getActiveCount(),
                icon: 'utility:groups',
                trendLabel: null,
                trendClass: ''
            },
            {
                key: 'completed',
                label: 'Completed This Period',
                value: this.getCompletedCount(),
                icon: 'utility:success',
                trendLabel: null,
                trendClass: ''
            },
            {
                key: 'activePrograms',
                label: 'Active Vendor Programs',
                value: this.getActiveProgramsCount(),
                icon: 'utility:work_order_type',
                trendLabel: null,
                trendClass: ''
            },
            {
                key: 'dealersOnboarded',
                label: 'Dealers Onboarded',
                value: this.getDealersOnboardedCount(),
                icon: 'utility:user',
                trendLabel: null,
                trendClass: ''
            },
            {
                key: 'blocked',
                label: 'Blocked / At Risk',
                value: this.blockedCount || 0,
                icon: 'utility:warning',
                trendLabel: null,
                trendClass: 'negative'
            }
        ];
    }

    getActiveCount() {
        if (!this.summary) return 0;
        // Sum all non-terminal statuses
        let active = 0;
        const terminalStatuses = ['Complete', 'Denied', 'Expired'];
        for (const [status, count] of Object.entries(this.summary)) {
            if (!terminalStatuses.includes(status) && status !== 'Total') {
                active += count || 0;
            }
        }
        return active;
    }

    getCompletedCount() {
        if (!this.summary) return 0;
        return this.summary['Complete'] || this.summary['Setup Complete'] || 0;
    }

    getActiveProgramsCount() {
        if (!this.vendorSummary) return 0;
        return this.vendorSummary['Active'] || 0;
    }

    getDealersOnboardedCount() {
        if (!this.summary) return 0;
        return this.summary['Complete'] || this.summary['Setup Complete'] || this.summary['Total'] || 0;
    }

    handleTileClick(event) {
        const key = event.currentTarget.dataset.key;
        this.dispatchEvent(
            new CustomEvent('tileclick', {
                detail: { metricKey: key },
                bubbles: true,
                composed: true
            })
        );
    }
}

