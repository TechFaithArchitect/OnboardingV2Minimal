import { LightningElement, api } from 'lwc';

export default class OnboardingInsights extends LightningElement {
    @api summary = {};
    @api vendorProgramMetrics = [];

    // Chart dimensions
    DONUT_SIZE = 200;
    DONUT_RADIUS = 80;
    DONUT_STROKE_WIDTH = 20;

    get hasData() {
        return this.summary && Object.keys(this.summary).length > 0;
    }

    get statusDistribution() {
        if (!this.summary) return [];
        
        const distribution = [];
        const statuses = ['Not Started', 'In Process', 'Pending Initial Review', 'Complete', 'Denied', 'Expired'];
        const total = this.totalOnboarding || 1;
        
        for (const status of statuses) {
            const count = this.summary[status] || 0;
            if (count > 0) {
                const percentage = Math.round((count / total) * 100);
                const color = this.getStatusColor(status);
                distribution.push({
                    label: status,
                    value: count,
                    percentage: percentage,
                    progressStyle: `width: ${percentage}%`,
                    color: color,
                    colorStyle: `background-color: ${color}`
                });
            }
        }
        
        return distribution;
    }

    get totalOnboarding() {
        return this.summary['Total'] || 0;
    }

    get funnelData() {
        if (!this.summary) return [];
        
        const total = this.totalOnboarding || 1;
        const stages = [
            { stage: 'Not Started', count: this.summary['Not Started'] || 0 },
            { stage: 'In Process', count: this.summary['In Process'] || 0 },
            { stage: 'Pending Review', count: this.summary['Pending Initial Review'] || 0 },
            { stage: 'Complete', count: this.summary['Complete'] || this.summary['Setup Complete'] || 0 }
        ];
        
        return stages.map(stage => {
            const percentage = Math.round((stage.count / total) * 100);
            return {
                ...stage,
                percentage: percentage,
                progressStyle: `width: ${percentage}%`,
                color: this.getStageColor(stage.stage)
            };
        });
    }

    get vendorProgramStats() {
        if (!this.vendorProgramMetrics || this.vendorProgramMetrics.length === 0) {
            return {
                total: 0,
                active: 0,
                draft: 0,
                totalDealers: 0
            };
        }

        let totalDealers = 0;
        let active = 0;
        let draft = 0;

        for (const program of this.vendorProgramMetrics) {
            totalDealers += program.DealersOnboarded || 0;
            if (program.Status === 'Active' && program.Active) {
                active++;
            } else if (program.Status === 'Draft') {
                draft++;
            }
        }

        return {
            total: this.vendorProgramMetrics.length,
            active: active,
            draft: draft,
            totalDealers: totalDealers
        };
    }

    // Donut chart data for status distribution
    get donutChartData() {
        const distribution = this.statusDistribution;
        if (distribution.length === 0) return { paths: [], total: 0 };

        const total = this.totalOnboarding || 1;
        let currentAngle = -90; // Start at top
        const paths = [];
        const circumference = 2 * Math.PI * this.DONUT_RADIUS;

        distribution.forEach((item, index) => {
            const percentage = item.percentage / 100;
            const angle = percentage * 360;
            const strokeDasharray = `${circumference * percentage} ${circumference}`;
            const strokeDashoffset = -currentAngle * (circumference / 360);

            paths.push({
                ...item,
                d: this.calculateArcPath(currentAngle, angle),
                strokeDasharray: strokeDasharray,
                strokeDashoffset: strokeDashoffset,
                index: index
            });

            currentAngle += angle;
        });

        return { paths, total };
    }

    // Bar chart data for vendor program metrics
    get barChartData() {
        if (!this.vendorProgramMetrics || this.vendorProgramMetrics.length === 0) {
            return [];
        }

        const maxDealers = Math.max(...this.vendorProgramMetrics.map(p => p.DealersOnboarded || 0), 1);
        
        return this.vendorProgramMetrics.slice(0, 10).map(program => {
            const dealers = program.DealersOnboarded || 0;
            const percentage = Math.round((dealers / maxDealers) * 100);
            return {
                name: program.Name || 'Unknown',
                dealers: dealers,
                percentage: percentage,
                status: program.Status,
                active: program.Active,
                barStyle: `width: ${percentage}%`
            };
        });
    }

    // Helper methods
    // Note: SVG fill/stroke attributes require hex values, but these map to SLDS semantic colors
    // SLDS Color Tokens: --lwc-colorTextDefault (#080707), --lwc-colorBrand (#0070d2), 
    // --lwc-colorTextWarning (#ffb75d), --lwc-colorTextSuccess (#04844b), 
    // --lwc-colorTextError (#c23934), --lwc-colorTextWeak (#706e6b)
    getStatusColor(status) {
        const colorMap = {
            'Not Started': '#706e6b',      // SLDS: colorTextWeak
            'In Process': '#0070d2',        // SLDS: colorBrand
            'Pending Initial Review': '#ffb75d',  // SLDS: colorTextWarning
            'Complete': '#04844b',         // SLDS: colorTextSuccess
            'Denied': '#c23934',           // SLDS: colorTextError
            'Expired': '#8b4513'           // Custom: brown (no direct SLDS equivalent)
        };
        return colorMap[status] || '#706e6b';
    }

    getStageColor(stage) {
        const colorMap = {
            'Not Started': '#706e6b',      // SLDS: colorTextWeak
            'In Process': '#0070d2',        // SLDS: colorBrand
            'Pending Review': '#ffb75d',    // SLDS: colorTextWarning
            'Complete': '#04844b'           // SLDS: colorTextSuccess
        };
        return colorMap[stage] || '#706e6b';
    }

    calculateArcPath(startAngle, angle) {
        const radius = this.DONUT_RADIUS;
        const centerX = this.DONUT_SIZE / 2;
        const centerY = this.DONUT_SIZE / 2;
        
        const startAngleRad = (startAngle * Math.PI) / 180;
        const endAngleRad = ((startAngle + angle) * Math.PI) / 180;
        
        const x1 = centerX + radius * Math.cos(startAngleRad);
        const y1 = centerY + radius * Math.sin(startAngleRad);
        const x2 = centerX + radius * Math.cos(endAngleRad);
        const y2 = centerY + radius * Math.sin(endAngleRad);
        
        const largeArcFlag = angle > 180 ? 1 : 0;
        
        return `M ${centerX} ${centerY} L ${x1} ${y1} A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2} Z`;
    }
}

