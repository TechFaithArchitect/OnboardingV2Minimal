import { LightningElement, api, wire, track } from 'lwc';
import getECCRecordsForContact from '@salesforce/apex/ContactECCController.getECCRecordsForContact';
import shouldShowECC from '@salesforce/apex/ContactECCController.shouldShowECC';
import updateECCRecord from '@salesforce/apex/ContactECCController.updateECCRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const DEFAULT_FIELD_CONFIGS = [
    { apiName: 'POE_Process_Status__c', label: 'Process Status', readOnly: false },
    { apiName: 'POE_Username__c', label: 'Username', readOnly: false },
    { apiName: 'Activation_Date__c', label: 'Activation Date', readOnly: false },
    { apiName: 'Training_Sent_Date__c', label: 'Training Sent Date', readOnly: true }
];

export default class ContactECC extends LightningElement {
    @api recordId;
    @track eccRecords = [];
    @track dependencies = {};
    @track showECC = false;
    @track isLoading = true;

    wiredECCResult;

    // Determine if ECC section should show
    @wire(shouldShowECC, { contactId: '$recordId' })
    wiredShowECC({ data, error }) {
        this.showECC = !!data;
    }

    // Load ECC records and config data
    @wire(getECCRecordsForContact, { contactId: '$recordId' })
    wiredECC(result) {
        this.wiredECCResult = result;
        const { data, error } = result;

        this.isLoading = true;

        if (data && Array.isArray(data.records)) {
            const rawRecords = data.records || [];
            const configMap = data.fieldConfigurations || {};
            const rawDependencies = data.dependencies || {};

            this.dependencies = rawDependencies;

            // Inject field configs or fallback
            this.eccRecords = rawRecords.map(wrapper => {
                const eccId = wrapper.record?.Id;
                const fieldConfigs = eccId && configMap[eccId]
                    ? configMap[eccId]
                    : DEFAULT_FIELD_CONFIGS;

                if (!eccId || !configMap[eccId]) {
                    console.warn('⚠️ Using DEFAULT_FIELD_CONFIGS for ECC record:', eccId);
                }

                return {
                    ...wrapper,
                    fieldConfigs
                };
            });

        } else {
            this.eccRecords = [];
            this.dependencies = {};
        }

        if (error) {
            console.error('Error loading ECC records:', error);
            this.showToast('Error', 'Failed to load credential records.', 'error');
        }

        this.isLoading = false;
    }

    // Group ECC records by Program for display
    get eccGroupedByProgram() {
        const grouped = {};
        const completedMap = new Map();

        const allowedPrograms = ['Verizon Fios D2D', 'C Spire D2D', 'WOW D2D', 'Verizon Mobile FWA','Verizon Engagement Manager', 'Verizon Digital & Concierge'];

        // Track completion per type
        this.eccRecords.forEach(wrapper => {
            const record = wrapper.record;
            if (!allowedPrograms.includes(record?.POE_Program__c)) {
                return; // Skip non-allowed programs
            }
            const type = record?.External_Contact_Credential_Type__r?.Name;
            const isComplete = record?.POE_Process_Status__c === 'Complete' && record?.POE_Username__c;
            if (type) completedMap.set(type, isComplete);
        });

        this.eccRecords.forEach(wrapper => {
            const record = wrapper.record;
            if (!allowedPrograms.includes(record?.POE_Program__c)) {
                return; // Skip non-allowed programs
            }
            const type = record?.External_Contact_Credential_Type__r?.Name;
            const dependsOn = this.dependencies?.[type] || [];
            const isDisabled = dependsOn.some(dep => !completedMap.get(dep));
            const programName = record?.POE_Program__c || 'Unknown Program';

            if (!grouped[programName]) {
                grouped[programName] = [];
            }

            grouped[programName].push({
                record,
                picklistOptions: wrapper.picklistOptions || [],
                fieldConfigs: wrapper.fieldConfigs || [],
                disabled: isDisabled
            });
        });

        return Object.keys(grouped).map(programName => ({
            programName,
            records: grouped[programName]
        }));
    }

    get isFullyLoaded() {
        return this.showECC && this.eccRecords?.length && !this.isLoading;
    }

    handleFieldChange(event) {
        const updatedRecord = event.detail;

        this.eccRecords = this.eccRecords.map(wrapper => {
            if (wrapper.record?.Id === updatedRecord.Id) {
                return {
                    ...wrapper,
                    record: { ...wrapper.record, ...updatedRecord }
                };
            }
            return wrapper;
        });
    }

    handleSave(event) {
        const recordToSave = event.detail;

        updateECCRecord({ updatedRecord: recordToSave })
            .then(() => {
                this.showToast('Success', 'Record saved successfully', 'success');
                return refreshApex(this.wiredECCResult);
            })
            .catch(error => {
                this.showToast('Error saving record', error.body.message, 'error');
            });
    }

    handleEmailOwner() {
        this.showToast('Feature', 'Email Owner clicked', 'info');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}