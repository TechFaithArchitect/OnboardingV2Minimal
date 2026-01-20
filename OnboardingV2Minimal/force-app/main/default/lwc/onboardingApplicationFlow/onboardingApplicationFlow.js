import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { extractErrorMessage } from 'c/utils';
import getStagesForProcess from '@salesforce/apex/OnboardingApplicationService.getStagesForProcess';
import getProcessDetails from '@salesforce/apex/OnboardingApplicationService.getProcessDetails';

export default class OnboardingApplicationFlow extends LightningElement {
    @api processId;
    @api vendorProgramId;

    @track stages = [];
    @track currentStageIndex = 0;
    @track processName = '';
    
    get currentComponentName() {
        const stage = this.stages[this.currentStageIndex];
        // ✅ Use correct field path from the database query
        return stage?.Onboarding_Component_Library__r?.Component_API_Name__c || null;
    }

    get currentStage() {
        return this.stages[this.currentStageIndex] || {};
    }

    get componentContext() {
        return {
            vendorProgramId: this.vendorProgramId,
            stageId: this.currentStage?.Id
        };
    }

    get currentStageLabel() {
        return this.currentStage?.Label__c || this.currentStage?.Name || '';
    }

    get isFirst() {
        return this.currentStageIndex === 0;
    }

    get isLast() {
        return this.currentStageIndex === this.stages.length - 1;
    }

    connectedCallback() {
        this.loadProcess();
    }

    async loadProcess() {
        try {
            const [stagesResult, processResult] = await Promise.all([
                getStagesForProcess({ processId: this.processId }),
                getProcessDetails({ processId: this.processId })
            ]);

            this.stages = stagesResult || [];
            this.processName = processResult?.Name || '';
        } catch (error) {
            this.stages = [];
            this.processName = '';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: extractErrorMessage(error, 'Failed to load onboarding application flow.'),
                    variant: 'error'
                })
            );
        }
    }

    handleNext() {
        if (!this.isLast) {
            this.currentStageIndex++;
        }
    }

    handleBack() {
        if (!this.isFirst) {
            this.currentStageIndex--;
        }
    }
}
