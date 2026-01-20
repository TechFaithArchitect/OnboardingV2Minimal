import { LightningElement, api, wire, track } from 'lwc';
import getStagesWithDependencies from '@salesforce/apex/OnboardingStageDependencyController.getStagesWithDependencies';

export default class OnboardingStageDependencyViewer extends LightningElement {
    @api vendorProgramId;
    @api processId;

    @track stages = [];
    @track isLoading = true;
    @track error;
    @track errorMessage = '';

    // Layout configuration
    get STAGE_WIDTH() { return 200; }
    get STAGE_HEIGHT() { return 100; }
    get STAGE_SPACING() { return 50; }
    get ROW_HEIGHT() { return 150; }

    @wire(getStagesWithDependencies, { 
        processId: '$processId', 
        vendorProgramId: '$vendorProgramId' 
    })
    wiredStages({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.stages = data.map(stage => {
                const position = this.calculatePosition(stage, data);
                return {
                    ...stage,
                    status: this.getStageStatus(stage),
                    statusClass: this.getStatusClass(stage),
                    statusColor: this.getStatusColor(stage),
                    position: position,
                    textX: position.x + this.STAGE_WIDTH / 2,
                    textY: position.y + 30,
                    sequenceY: position.y + 55,
                    badgeX: position.x + 10,
                    badgeY: position.y + 70,
                    badgeWidth: this.STAGE_WIDTH - 20
                };
            });
            this.error = null;
        } else if (error) {
            this.error = error;
            this.errorMessage = error.body || error.message || 'Unknown error';
            this.stages = [];
        }
    }

    get hasStages() {
        return this.stages && this.stages.length > 0;
    }

    get svgWidth() {
        if (this.stages.length === 0) return 800;
        const maxX = Math.max(...this.stages.map(s => s.position.x)) + this.STAGE_WIDTH;
        return Math.max(800, maxX + 100);
    }

    get svgHeight() {
        if (this.stages.length === 0) return 600;
        const maxY = Math.max(...this.stages.map(s => s.position.y)) + this.STAGE_HEIGHT;
        return Math.max(600, maxY + 100);
    }

    get dependencyConnectors() {
        const connectors = [];
        
        for (const stage of this.stages) {
            if (stage.requiredStageIds && stage.requiredStageIds.length > 0) {
                for (const requiredStageId of stage.requiredStageIds) {
                    const requiredStage = this.stages.find(s => s.stageId === requiredStageId);
                    if (requiredStage) {
                        const fromPos = this.getStageCenter(requiredStage);
                        const toPos = this.getStageCenter(stage);
                        
                        connectors.push({
                            id: `${requiredStageId}-${stage.stageId}`,
                            fromX: fromPos.x,
                            fromY: fromPos.y,
                            toX: toPos.x,
                            toY: toPos.y,
                            isBlocked: stage.isBlocked,
                            // SLDS colors: colorTextError (#c23934), colorTextSuccess (#04844b)
                            color: stage.isBlocked ? '#c23934' : '#04844b'
                        });
                    }
                }
            }
        }
        
        return connectors;
    }

    getStageStatus(stage) {
        if (stage.isCompleted) {
            return 'Complete';
        } else if (stage.isBlocked) {
            return 'Blocked';
        } else if (stage.requiredStageIds && stage.requiredStageIds.length > 0) {
            return 'Waiting';
        } else {
            return 'Ready';
        }
    }

    getStatusClass(stage) {
        const status = this.getStageStatus(stage);
        const classMap = {
            'Complete': 'slds-badge slds-badge_success',
            'Blocked': 'slds-badge slds-badge_error',
            'Waiting': 'slds-badge slds-badge_warning',
            'Ready': 'slds-badge slds-badge_inverse'
        };
        return classMap[status] || 'slds-badge';
    }

    // Note: SVG stroke attributes require hex values, but these map to SLDS semantic colors
    // SLDS Color Tokens: --lwc-colorTextSuccess (#04844b), --lwc-colorTextError (#c23934),
    // --lwc-colorTextWarning (#ffb75d), --lwc-colorBrand (#0070d2), --lwc-colorTextWeak (#706e6b)
    getStatusColor(stage) {
        const status = this.getStageStatus(stage);
        const colorMap = {
            'Complete': '#04844b',   // SLDS: colorTextSuccess
            'Blocked': '#c23934',    // SLDS: colorTextError
            'Waiting': '#ffb75d',    // SLDS: colorTextWarning
            'Ready': '#0070d2'       // SLDS: colorBrand
        };
        return colorMap[status] || '#706e6b';  // SLDS: colorTextWeak
    }

    calculatePosition(stage, allStages) {
        // Simple layout: stages in sequence order, left to right
        // In a real implementation, you might want a more sophisticated layout algorithm
        const index = allStages.findIndex(s => s.stageId === stage.stageId);
        const row = Math.floor(index / 3); // 3 stages per row
        const col = index % 3;
        
        return {
            x: 50 + col * (this.STAGE_WIDTH + this.STAGE_SPACING),
            y: 50 + row * this.ROW_HEIGHT
        };
    }

    getStageCenter(stage) {
        return {
            x: stage.position.x + this.STAGE_WIDTH / 2,
            y: stage.position.y + this.STAGE_HEIGHT / 2
        };
    }

    get stageWidth() {
        return this.STAGE_WIDTH;
    }

    get stageHeight() {
        return this.STAGE_HEIGHT;
    }

    handleStageClick(event) {
        const stageId = event.currentTarget.dataset.stageId;
        this.dispatchEvent(
            new CustomEvent('stageclick', {
                detail: { stageId: stageId },
                bubbles: true,
                composed: true
            })
        );
    }
}

