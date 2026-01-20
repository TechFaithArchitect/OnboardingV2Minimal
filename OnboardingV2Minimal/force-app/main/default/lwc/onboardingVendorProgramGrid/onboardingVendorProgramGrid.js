import { LightningElement, api } from 'lwc';

export default class OnboardingVendorProgramGrid extends LightningElement {
    @api programs = [];

    get hasPrograms() {
        return this.programs && this.programs.length > 0;
    }

    get processedPrograms() {
        if (!this.programs || this.programs.length === 0) {
            return [];
        }

        return this.programs.map(program => {
            const processed = { ...program };
            
            // Calculate requirement completion percentage
            if (processed.TotalRequirements > 0) {
                processed.requirementPercentage = Math.round(
                    (processed.CompleteRequirements / processed.TotalRequirements) * 100
                );
            } else {
                processed.requirementPercentage = 0;
            }

            // Determine status badge class
            if (processed.Status === 'Active' && processed.Active) {
                processed.statusClass = 'slds-badge slds-badge_success';
            } else if (processed.Status === 'Draft') {
                processed.statusClass = 'slds-badge slds-badge_lightest';
            } else {
                processed.statusClass = 'slds-badge slds-badge_inverse';
            }

            // Calculate progress bar style
            processed.progressStyle = `width: ${processed.requirementPercentage}%`;

            return processed;
        });
    }

    handleViewProgram(event) {
        const programId = event.currentTarget.dataset.id;
        this.dispatchEvent(
            new CustomEvent('viewprogram', {
                detail: {
                    programId: programId
                },
                bubbles: true,
                composed: true
            })
        );
    }

    handleLaunchWizard(event) {
        const programId = event.currentTarget.dataset.id;
        this.dispatchEvent(
            new CustomEvent('launchwizard', {
                detail: {
                    programId: programId
                },
                bubbles: true,
                composed: true
            })
        );
    }
}

