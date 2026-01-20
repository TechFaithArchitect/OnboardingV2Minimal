import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getEligibility from '@salesforce/apex/VendorOnboardingWizardController.getVendorProgramEligibilityForAccount';
import searchPrograms from '@salesforce/apex/VendorOnboardingWizardController.searchVendorProgramsForAccount';
import getContactsWithRoles from '@salesforce/apex/VendorOnboardingWizardController.getAccountContactsWithRoles';
import upsertAcr from '@salesforce/apex/VendorOnboardingWizardController.upsertAccountContactRelation';
import createOpp from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingOpportunity';
import upsertOcr from '@salesforce/apex/VendorOnboardingWizardController.upsertOpportunityContactRole';
import createOnboardingWithReqs from '@salesforce/apex/VendorOnboardingWizardController.createOnboardingWithRequirements';
import createAvo from '@salesforce/apex/VendorOnboardingWizardController.createAccountVendorProgramOnboarding';
// Using static options for ACR Roles (standard Roles field is not exposed via schema here)
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class AccountProgramOnboardingModal extends NavigationMixin(LightningElement) {
    @api recordId; // Account Id
    @api avoOnboardingId; // optional, if you have an existing onboarding record

    @track eligibilityMessage;
    @track eligibilityPassed = false;
    @track accountHasNda = false;
    @track accountHasProgramBase = false;
    @track programOptions = [];
    @track selectedProgramId = '';
    @track searchText = '';
    @track isLoading = false;
    @track contacts = [];
    @track selectedPrimaryContactId = '';
    @track acrRoleOptions = [];

    @track oppName = '';
    @track oppStage = 'Prospecting';
    @track oppCloseDate;
    @track stageOptions = [];
    @track oppRecordTypeId;

    connectedCallback() {
        this.loadEligibility();
        this.loadAcrRolePicklist();
        this.loadContacts();
        this.oppCloseDate = this.computeDefaultCloseDate();
    }

    // Wire Opportunity object info to derive Program Opportunity record type
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    wiredOpportunityInfo({ data, error }) {
        if (data && data.recordTypeInfos) {
            // Look for record type with name or developerName containing 'Program Opportunity'
            const rtInfos = Object.values(data.recordTypeInfos);
            const programRt = rtInfos.find(
                rt =>
                    rt.name === 'Program Opportunity' ||
                    rt.developerName === 'Program_Opportunity' ||
                    rt.label === 'Program Opportunity'
            );
            this.oppRecordTypeId = programRt ? programRt.recordTypeId : data.defaultRecordTypeId;
            this.loadStagePicklist();
        } else if (error) {
            console.error('Opportunity object info error', error);
            this.loadStagePicklist(); // fallback without record type
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$oppRecordTypeId', fieldApiName: STAGE_NAME_FIELD })
    wiredStagePicklist({ data, error }) {
        if (data) {
            this.stageOptions = data.values.map(v => ({ label: v.label, value: v.value }));
            const currentStageValid = this.stageOptions.some(option => option.value === this.oppStage);
            if (!currentStageValid && this.stageOptions.length) {
                this.oppStage = this.stageOptions[0].value;
            }
        } else if (error) {
            console.error('Stage picklist error', error);
            this.stageOptions = [];
        }
    }

    get disableSearch() {
        return this.isLoading || !this.searchText || this.searchText.trim().length < 2;
    }

    get disableNext() {
        const contactsMissingRole = this.contacts.some(c => !c.role);
        return (
            this.isLoading ||
            !this.selectedProgramId ||
            contactsMissingRole ||
            !this.oppName ||
            !this.oppStage ||
            this.contacts.length === 0 ||
            !this.selectedPrimaryContactId
        );
    }

    async loadEligibility() {
        this.isLoading = true;
        try {
            const result = await getEligibility({ accountId: this.recordId });
            this.eligibilityPassed = result?.eligibilityPassed || false;
            this.accountHasNda = result?.hasNda || false;
            this.accountHasProgramBase = result?.hasProgramBase || false;
            this.eligibilityMessage = result?.message;
        } catch (error) {
            this.eligibilityMessage = 'Unable to load eligibility. Please retry.';
            // keep eligibilityPassed as false so only PerfectVision is returned
            console.error('Eligibility error', error);
            this.showToast('Error', 'Unable to load eligibility. Please retry.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadContacts() {
        try {
            const results = await getContactsWithRoles({ accountId: this.recordId });
            const loadedContacts = results?.map(r => ({
                contactId: r.contactId,
                name: r.name,
                email: r.email,
                role: r.role,
                hasAcr: r.hasAcr
            })) || [];
            if (!this.selectedPrimaryContactId && loadedContacts.length) {
                this.selectedPrimaryContactId = loadedContacts[0].contactId;
            }
            this.contacts = loadedContacts.map(c => ({
                ...c,
                isPrimary: c.contactId === this.selectedPrimaryContactId
            }));
        } catch (error) {
            console.error('Contact load error', error);
            this.contacts = [];
            this.showToast('Error', 'Unable to load contacts. Please refresh.', 'error');
        }
    }

    loadAcrRolePicklist() {
        this.acrRoleOptions = [
            { label: 'Principal Owner', value: 'Principal Owner' },
            { label: 'Owner', value: 'Owner' },
            { label: 'Authorized Signer', value: 'Authorized Signer' },
            { label: 'Other', value: 'Other' }
        ];
    }

    handleSearchChange(event) {
        this.searchText = event.target.value;
    }

    async handleSearch() {
        if (this.disableSearch) {
            return;
        }
        this.isLoading = true;
        try {
            const programs = await searchPrograms({
                accountId: this.recordId,
                vendorProgramNameSearchText: this.searchText.trim(),
                eligibilityPassed: this.eligibilityPassed,
                accountHasNda: this.accountHasNda,
                accountHasProgramBase: this.accountHasProgramBase
            });
            this.programOptions = programs.map(p => ({
                label: `${p.Name} (${p.Vendor__r?.Name || 'Vendor'})`,
                value: p.Id
            }));
            if (!this.programOptions.length) {
                this.selectedProgramId = '';
            }
        } catch (error) {
            console.error('Program search error', error);
            this.programOptions = [];
            this.selectedProgramId = '';
            this.showToast('Error', 'Vendor program search failed. Please retry.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleProgramChange(event) {
        this.selectedProgramId = event.detail.value;
    }

    handleContactRoleChange(event) {
        const contactId = event.target.dataset.contactId;
        const value = event.detail.value;
        this.contacts = this.contacts.map(c => c.contactId === contactId ? { ...c, role: value } : c);
    }

    handlePrimaryChange(event) {
        const selectedId = event.target.value;
        this.selectedPrimaryContactId = selectedId;
        this.contacts = this.contacts.map(c => ({
            ...c,
            isPrimary: c.contactId === selectedId
        }));
    }

    handleOppNameChange(event) {
        this.oppName = event.target.value;
    }

    handleOppStageChange(event) {
        this.oppStage = event.target.value;
    }

    handleOppCloseDateChange(event) {
        this.oppCloseDate = event.target.value;
    }

    handleCreateContact() {
        const defaultValues = encodeDefaultFieldValues({
            AccountId: this.recordId
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleNext() {
        if (this.disableNext) {
            return;
        }
        this.isLoading = true;
        try {
            if (!this.contacts.length) {
                this.showToast('Add Contacts', 'Add at least one Contact to the Account and assign a role before proceeding.', 'error');
                return;
            }
            const missingRole = this.contacts.find(c => !c.role);
            if (missingRole) {
                this.showToast('Assign Roles', 'Every contact must have an Account Contact Role before proceeding.', 'error');
                return;
            }

            // Upsert ACRs
            for (const c of this.contacts) {
                await upsertAcr({ accountId: this.recordId, contactId: c.contactId, role: c.role });
            }

            // Create Opportunity
            const oppId = await createOpp({
                accountId: this.recordId,
                name: this.oppName,
                stageName: this.oppStage,
                closeDate: this.oppCloseDate,
                recordTypeId: this.oppRecordTypeId
            });

            // Create OCRs for each contact with role
            for (const c of this.contacts) {
                await upsertOcr({
                    opportunityId: oppId,
                    contactId: c.contactId,
                    role: c.role,
                    isPrimary: c.contactId === this.selectedPrimaryContactId
                });
            }

            // Create Onboarding with seeded requirements
            const onboardingResult = await createOnboardingWithReqs({
                accountId: this.recordId,
                vendorProgramId: this.selectedProgramId,
                opportunityId: oppId
            });

            // Create AVO (always) linking Account, Onboarding, Opportunity
            const avoId = await createAvo({
                accountId: this.recordId,
                onboardingId: onboardingResult.onboardingId,
                opportunityId: oppId,
                status: 'Intake',
                primaryContactId: this.selectedPrimaryContactId
            });

            const detail = {
                selectedProgramId: this.selectedProgramId,
                eligibilityPassed: this.eligibilityPassed,
                opportunityId: oppId,
                accountVendorProgramOnboardingId: avoId,
                onboardingId: onboardingResult.onboardingId,
                primaryContactId: this.selectedPrimaryContactId
            };
            this.dispatchEvent(new CustomEvent('programselected', { detail, bubbles: true, composed: true }));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            console.error('Next handler error', error);
            this.showToast('Error', 'Unable to complete onboarding setup. Please retry.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    computeDefaultCloseDate() {
        const today = new Date();
        const future = new Date();
        future.setDate(today.getDate() + 14);
        return future.toISOString().slice(0, 10);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant: variant || 'info',
                mode: 'dismissable'
            })
        );
    }
}
