import { LightningElement, api, track } from 'lwc';
import loadContext from '@salesforce/apex/ExpOpportunityCreateRecord.loadContext';
import saveContactsAndPrepareOcr from '@salesforce/apex/ExpOpportunityCreateRecord.saveContactsAndPrepareOcr';
import submitCreateRecord from '@salesforce/apex/ExpOpportunityCreateRecord.submitCreateRecord';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

const ACTION_OFFER_CHUZO_CREATE = 'OFFER_CHUZO_CREATE';
const ACTION_PROMPT_PATH_SELECTION = 'PROMPT_PATH_SELECTION';
const ACTION_REQUIRE_NDA = 'REQUIRE_NDA';
const ACTION_NO_ACTION = 'NO_ACTION';
const ACTION_CREATE_VENDOR_PROGRAM_ONBOARDING = 'CREATE_VENDOR_PROGRAM_ONBOARDING';

const PATH_WITH_CHUZO = 'WITH_CHUZO';
const PATH_WITH_CHUZO_NO_PG = 'WITH_CHUZO_NO_PG';
const PATH_WITHOUT_CHUZO = 'WITHOUT_CHUZO';
const PATH_VENDOR = 'VENDOR_PROGRAM';

const PROGRAM_BASE_BY_PATH = {
    [PATH_WITH_CHUZO]: 'Program Base Application - with Chuzo',
    [PATH_WITH_CHUZO_NO_PG]: 'Program Base Application - with Chuzo (No Personal Guarantee)',
    [PATH_WITHOUT_CHUZO]: 'Program Base Application - without Chuzo',
    [PATH_VENDOR]: 'Not Applicable'
};

const PATH_BY_PROGRAM_BASE = {
    'Program Base Application - with Chuzo': PATH_WITH_CHUZO,
    'Program Base Application - with Chuzo (No Personal Guarantee)': PATH_WITH_CHUZO_NO_PG,
    'Base Application - Infrastructure': PATH_WITH_CHUZO_NO_PG,
    'Program Base Application - without Chuzo': PATH_WITHOUT_CHUZO,
    'Not Applicable': PATH_VENDOR
};

const DOC_READY_YES = 'Yes';
const DOC_READY_NO = 'No';

const STEP_ACCOUNT = 0;
const STEP_OPPORTUNITY = 1;
const STEP_CONTACTS = 2;
const STEP_OCR = 3;
const SALESFORCE_ID_PATTERN = /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/;
const DIAGNOSTIC_LOG_LIMIT = 50;

export default class ExpCreateRecord extends LightningElement {
    @api recordId;
    @api flowAccountId;
    @api availableActions = [];
    @api opportunityCloseDate;
    @api opportunityStageName;
    @api opportunityProgramType;
    @api opportunityProgramBaseSelection;
    @api opportunityDocumentsReady;
    @api opportunityLeadSource;
    @api opportunitySource;
    @api opportunityNextStep;
    @api opportunityNextStepDate;
    @api opportunityOwnerRole;
    @api opportunityRecordTypeId;
    @api opportunityType;
    @api flowFinalNextAction;
    @api flowShowAgreementChoice;
    @api flowShowPersonalGuarantee;
    @api flowShowVendorSelector;
    @api flowShowVerifyAccount;
    @api flowIsUserSpecial;
    @api flowAvailableVendorOptionString;
    @api flowHasAnyOnboardingForAccount;
    @api flowHasChuzoOnboardingForOpportunity;
    @api flowHasNdaOnboardingForOpportunity;
    @api flowHasNonChuzoOnboardingForOpportunity;
    @api flowOpportunityRecordTypeId;
    @api flowRuleErrorMessage;
    @api debugMode;

    @api accountStepHeading = 'Account';
    @api accountStepHelperText;
    @api opportunityStepHeading = 'Opportunity';
    @api opportunityStepHelperText;
    @api contactsStepHeading = 'Add Contact(s)';
    @api contactsStepHelperText;
    @api ocrStepHeading = 'Assign Opportunity Contact Roles';
    @api ocrStepHelperText;
    @api stepHeadingVariant = 'default';
    @api accountStepVariant;
    @api opportunityStepVariant;
    @api contactsStepVariant;
    @api ocrStepVariant;

    @track isLoading = true;
    @track isSaving = false;
    @track errorMessage;
    @track successMessage;

    @track accountExistingJson = '[]';
    @track opportunityExistingJson = '[]';
    @track contactsExistingJson = '[]';
    @track savedContactsJson = '[]';
    @track opportunityContactSeedJson = '[]';
    @track availableVendorOptionString = '[]';

    @track finalNextAction;
    @track showAgreementChoice = false;
    @track showPersonalGuarantee = false;
    @track showVendorSelector = false;
    @track showVerifyAccount = false;
    @track isUserSpecial = false;
    @track pathSelection;

    @track opportunityRuntime = {
        recordTypeId: null,
        programBaseSelection: null
    };

    @track currentStepIndex = STEP_ACCOUNT;
    @track accountStepRecord;
    @track opportunityStepRecord;
    @track opportunityStepVendorSelection = {
        selectedVendorId: null,
        selectedRetailOption: null,
        selectedBusinessVertical: null
    };
    @track runtimeAccountId;
    @track initialAccountId;
    @track isCurrentStepReady = false;
    @track diagnosticsLogEntries = [];
    @track lastContactsJsonResolution;
    @track lastContactsSaveRequest;
    @track lastContactsSaveResponse;
    @track lastSubmitRequest;
    @track lastSubmitResponse;
    @track lastEditorStateEvent;

    connectedCallback() {
        this.initialize();
    }

    renderedCallback() {
        this.evaluateCurrentStepReadiness();
    }

    async initialize() {
        this.clearMessages();
        this.isLoading = true;
        this.logDiagnostics('initialize_start', {
            recordId: this.recordId,
            flowAccountId: this.flowAccountId,
            resolvedAccountId: this.resolvedAccountId
        });

        try {
            const accountId = this.resolvedAccountId;
            if (!accountId) {
                this.errorMessage = 'Account Id is required.';
                this.logDiagnostics('initialize_missing_account_id', {
                    recordId: this.recordId,
                    flowAccountId: this.flowAccountId
                });
                return;
            }
            this.initialAccountId = accountId;
            this.runtimeAccountId = accountId;

            const preloadedContextJson = this.buildPreloadedContextJson();
            const context = await loadContext({
                accountId,
                preloadedContextJson
            });
            if (!context || !context.success) {
                this.errorMessage = (context && context.errorMessage) || 'Unable to load onboarding context.';
                this.logDiagnostics('initialize_load_context_failed', {
                    errorMessage: this.errorMessage
                });
                return;
            }

            const accountRecord = context.accountRecord || {};
            const accountSeed = {
                Id: accountRecord.Id || accountId,
                Name: accountRecord.Name || '',
                Phone: accountRecord.Phone || '',
                BillingStreet: accountRecord.BillingStreet || '',
                BillingCity: accountRecord.BillingCity || '',
                BillingState: accountRecord.BillingStateCode || accountRecord.BillingState || '',
                BillingPostalCode: accountRecord.BillingPostalCode || '',
                BillingCountry: accountRecord.BillingCountryCode || accountRecord.BillingCountry || '',
                ShippingStreet: accountRecord.ShippingStreet || '',
                ShippingCity: accountRecord.ShippingCity || '',
                ShippingState: accountRecord.ShippingStateCode || accountRecord.ShippingState || '',
                ShippingPostalCode: accountRecord.ShippingPostalCode || '',
                ShippingCountry: accountRecord.ShippingCountryCode || accountRecord.ShippingCountry || ''
            };
            this.runtimeAccountId = accountSeed.Id || this.runtimeAccountId;
            this.accountStepRecord = accountSeed;
            this.accountExistingJson = this.serializeSingleRecord(accountSeed);

            this.contactsExistingJson = context.contactRecordsJson || '[]';
            this.savedContactsJson = this.contactsExistingJson;
            this.opportunityContactSeedJson = context.opportunityContactSeedJson || '[]';
            this.availableVendorOptionString = this.pickValue(
                this.flowAvailableVendorOptionString,
                context.availableVendorOptionString || '[]'
            );

            this.finalNextAction = this.pickValue(this.flowFinalNextAction, context.finalNextAction);
            this.showAgreementChoice = this.pickBoolean(
                this.flowShowAgreementChoice,
                context.showAgreementChoice === true
            );
            this.showPersonalGuarantee = this.pickBoolean(
                this.flowShowPersonalGuarantee,
                context.showPersonalGuarantee === true
            );
            this.showVendorSelector = this.pickBoolean(
                this.flowShowVendorSelector,
                context.showVendorSelector === true
            );
            this.showVerifyAccount = this.pickBoolean(
                this.flowShowVerifyAccount,
                context.showVerifyAccount === true
            );
            this.isUserSpecial = this.pickBoolean(this.flowIsUserSpecial, context.isUserSpecial === true);

            this.opportunityRuntime = {
                recordTypeId: this.pickValue(
                    this.opportunityRecordTypeId,
                    this.pickValue(this.flowOpportunityRecordTypeId, context.opportunityRecordTypeId)
                ),
                programBaseSelection: this.pickValue(this.opportunityProgramBaseSelection, null)
            };

            const seededOpportunity = {
                CloseDate: this.pickValue(this.opportunityCloseDate, context.defaultCloseDate),
                StageName: this.pickValue(this.opportunityStageName, context.defaultStageName),
                Program_Type__c: this.pickValue(this.opportunityProgramType, context.defaultProgramType),
                LeadSource: this.pickValue(this.opportunityLeadSource, context.defaultLeadSource),
                Opportunity__c: this.pickValue(this.opportunitySource, context.defaultOpportunitySource),
                NextStep: this.pickValue(this.opportunityNextStep, ''),
                Next_Step_Date__c: this.pickValue(this.opportunityNextStepDate, context.defaultNextStepDate),
                Owner__c: this.pickValue(this.opportunityOwnerRole, context.defaultOwnerRole),
                Type: this.pickValue(this.opportunityType, context.defaultType),
                Documents_Ready__c: this.toDocumentsReadyLabel(this.toBooleanOrNull(this.opportunityDocumentsReady))
            };
            this.opportunityStepRecord = seededOpportunity;
            this.opportunityExistingJson = this.serializeSingleRecord(seededOpportunity);

            this.setInitialPathSelection();

            const resolvedRuleErrorMessage = this.pickValue(this.flowRuleErrorMessage, context.ruleErrorMessage);
            if (resolvedRuleErrorMessage) {
                this.errorMessage = resolvedRuleErrorMessage;
            }
            this.logDiagnostics('initialize_success', {
                runtimeAccountId: this.runtimeAccountId,
                contactsExistingJsonLength: this.stringLength(this.contactsExistingJson),
                opportunityContactSeedJsonLength: this.stringLength(this.opportunityContactSeedJson)
            });
        } catch (error) {
            this.errorMessage = this.reduceError(error, 'Unable to load onboarding context.');
            this.logDiagnostics('initialize_exception', {
                message: this.errorMessage
            });
        } finally {
            this.isLoading = false;
        }
    }

    get isOfferAction() {
        return this.finalNextAction === ACTION_OFFER_CHUZO_CREATE;
    }

    get isPromptAction() {
        return this.finalNextAction === ACTION_PROMPT_PATH_SELECTION || this.finalNextAction === ACTION_REQUIRE_NDA;
    }

    get isVendorOnlyAction() {
        return this.finalNextAction === ACTION_CREATE_VENDOR_PROGRAM_ONBOARDING ||
            this.finalNextAction === ACTION_NO_ACTION;
    }

    get showPathSelector() {
        if (this.isPromptAction) {
            return true;
        }
        return this.isOfferAction && this.showAgreementChoice;
    }

    get pathOptions() {
        if (this.isPromptAction) {
            const options = [
                { label: 'Program Base App with Chuzo', value: PATH_WITH_CHUZO }
            ];
            if (this.isUserSpecial) {
                options.push({
                    label: 'Program Base App with Chuzo (No Personal Guarantee)',
                    value: PATH_WITH_CHUZO_NO_PG
                });
            }
            options.push({
                label: 'Program Base App without Chuzo',
                value: PATH_WITHOUT_CHUZO
            });
            return options;
        }

        if (this.isOfferAction && this.showAgreementChoice) {
            const options = [
                { label: 'Program Base App with Chuzo', value: PATH_WITH_CHUZO }
            ];
            if (this.isUserSpecial) {
                options.push({
                    label: 'Program Base App with Chuzo (No Personal Guarantee)',
                    value: PATH_WITH_CHUZO_NO_PG
                });
            }
            options.push({
                label: 'Vendor Program', value: PATH_VENDOR
            });
            return options;
        }

        return [];
    }

    get shouldShowVendorSelector() {
        if (this.isVendorOnlyAction) {
            return true;
        }
        return this.isOfferAction && this.offerVendorOnboarding;
    }

    get offerVendorOnboarding() {
        return this.pathSelection === PATH_VENDOR ||
            this.showVendorSelector ||
            this.finalNextAction === ACTION_CREATE_VENDOR_PROGRAM_ONBOARDING;
    }

    get resolvedAccountId() {
        const candidates = [
            this.runtimeAccountId,
            this.initialAccountId,
            this.accountStepRecord && this.accountStepRecord.Id,
            this.extractRecordIdFromSerializedRecords(this.accountExistingJson),
            this.extractAccountIdFromEditor('account'),
            this.flowAccountId,
            this.recordId
        ];
        for (let index = 0; index < candidates.length; index += 1) {
            const normalizedId = this.normalizeSalesforceId(candidates[index]);
            if (normalizedId) {
                return normalizedId;
            }
        }
        return null;
    }

    get isAccountStep() {
        return this.currentStepIndex === STEP_ACCOUNT;
    }

    get isOpportunityStep() {
        return this.currentStepIndex === STEP_OPPORTUNITY;
    }

    get isContactsStep() {
        return this.currentStepIndex === STEP_CONTACTS;
    }

    get isOcrStep() {
        return this.currentStepIndex === STEP_OCR;
    }

    get showBackButton() {
        return this.currentStepIndex > STEP_ACCOUNT;
    }

    get isFinalStep() {
        return this.currentStepIndex === STEP_OCR;
    }

    get primaryButtonLabel() {
        if (this.isSaving) {
            return this.isFinalStep ? 'Finishing...' : 'Saving...';
        }
        return this.isFinalStep ? 'Finish' : 'Next';
    }

    get isPrimaryActionDisabled() {
        return this.isSaving || !this.isCurrentStepReady;
    }

    get accountStepClass() {
        return this.isAccountStep ? 'step-panel' : 'step-panel slds-hide';
    }

    get opportunityStepClass() {
        return this.isOpportunityStep ? 'step-panel' : 'step-panel slds-hide';
    }

    get contactsStepClass() {
        return this.isContactsStep ? 'step-panel' : 'step-panel slds-hide';
    }

    get ocrStepClass() {
        return this.isOcrStep ? 'step-panel' : 'step-panel slds-hide';
    }

    get resolvedAccountStepHeading() {
        return this.hasValue(this.accountStepHeading) ? this.accountStepHeading : 'Account';
    }

    get resolvedOpportunityStepHeading() {
        return this.hasValue(this.opportunityStepHeading) ? this.opportunityStepHeading : 'Opportunity';
    }

    get resolvedContactsStepHeading() {
        return this.hasValue(this.contactsStepHeading) ? this.contactsStepHeading : 'Add Contact(s)';
    }

    get resolvedOcrStepHeading() {
        return this.hasValue(this.ocrStepHeading)
            ? this.ocrStepHeading
            : 'Assign Opportunity Contact Roles';
    }

    get resolvedAccountStepVariant() {
        return this.resolveStepVariant(this.accountStepVariant);
    }

    get resolvedOpportunityStepVariant() {
        return this.resolveStepVariant(this.opportunityStepVariant);
    }

    get resolvedContactsStepVariant() {
        return this.resolveStepVariant(this.contactsStepVariant);
    }

    get resolvedOcrStepVariant() {
        return this.resolveStepVariant(this.ocrStepVariant);
    }

    get showDiagnosticsPanel() {
        if (this.debugMode === undefined || this.debugMode === null || this.debugMode === '') {
            return true;
        }
        return this.toBoolean(this.debugMode);
    }

    get diagnosticsSummaryJson() {
        return this.safeStringify(this.buildDiagnosticsSummary(), 2);
    }

    get diagnosticsLogJson() {
        return this.safeStringify(this.diagnosticsLogEntries, 2);
    }

    setInitialPathSelection() {
        if (this.isVendorOnlyAction) {
            this.pathSelection = PATH_VENDOR;
            this.opportunityRuntime = {
                ...this.opportunityRuntime,
                programBaseSelection: PROGRAM_BASE_BY_PATH[PATH_VENDOR]
            };
            return;
        }

        if (this.isOfferAction && !this.showAgreementChoice) {
            this.opportunityRuntime = {
                ...this.opportunityRuntime,
                programBaseSelection: PROGRAM_BASE_BY_PATH[PATH_VENDOR]
            };
            return;
        }

        const mappedPath = this.pathFromProgramBase(this.opportunityRuntime.programBaseSelection);
        if (this.showPathSelector) {
            this.pathSelection = mappedPath || null;
            return;
        }

        if (!this.opportunityRuntime.programBaseSelection) {
            this.opportunityRuntime = {
                ...this.opportunityRuntime,
                programBaseSelection: PROGRAM_BASE_BY_PATH[PATH_WITHOUT_CHUZO]
            };
        }
    }

    handlePathSelectionChange(event) {
        this.pathSelection = event.detail?.value || event.detail;
        const mappedProgramBase = PROGRAM_BASE_BY_PATH[this.pathSelection];
        if (mappedProgramBase) {
            this.opportunityRuntime = {
                ...this.opportunityRuntime,
                programBaseSelection: mappedProgramBase
            };
        }
        this.evaluateCurrentStepReadiness();
    }

    handleBack() {
        if (this.isSaving || this.currentStepIndex === STEP_ACCOUNT) {
            return;
        }
        this.clearMessages();
        this.currentStepIndex -= 1;
        this.evaluateCurrentStepReadiness();
    }

    handleEditorStateChange(event) {
        const editorKey = event?.target?.dataset?.editor;
        const recordsJson = this.normalizeSerializedRecords(event?.detail?.recordsJson);
        const eventSummary = {
            editorKey,
            hasRequiredValues: event?.detail?.hasRequiredValues === true,
            recordsJsonLength: this.stringLength(recordsJson),
            recordsJsonPreview: this.truncateForDiagnostics(recordsJson),
            runtimeAccountId: this.runtimeAccountId,
            resolvedAccountId: this.resolvedAccountId
        };
        this.lastEditorStateEvent = eventSummary;
        this.logDiagnostics('editor_state_change', eventSummary);
        this.hydrateEditorState(event);
        this.evaluateCurrentStepReadiness();
    }

    handleVendorSelectionChange() {
        this.evaluateCurrentStepReadiness();
    }

    async handlePrimaryAction() {
        if (this.isSaving) {
            return;
        }

        this.clearMessages();

        if (this.currentStepIndex === STEP_ACCOUNT) {
            this.advanceFromAccountStep();
            return;
        }

        if (this.currentStepIndex === STEP_OPPORTUNITY) {
            this.advanceFromOpportunityStep();
            return;
        }

        if (this.currentStepIndex === STEP_CONTACTS) {
            await this.advanceFromContactsStep();
            return;
        }

        if (this.currentStepIndex === STEP_OCR) {
            await this.finishFromOcrStep();
        }
    }

    advanceFromAccountStep() {
        const accountEditor = this.template.querySelector('c-record-collection-editor[data-editor="account"]');
        if (!accountEditor) {
            this.errorMessage = 'Account editor is unavailable.';
            return;
        }

        const accountValidation = accountEditor.validate ? accountEditor.validate() : { isValid: true };
        if (!accountValidation.isValid) {
            this.errorMessage = accountValidation.errorMessage || 'Fix validation errors in Account before continuing.';
            return;
        }

        const accountRecord = this.extractSingleEditorRecord('account');
        if (!accountRecord || !accountRecord.Name) {
            this.errorMessage = 'Account Name is required.';
            return;
        }

        const persistedAccountId = this.normalizeSalesforceId(accountRecord.Id) || this.resolvedAccountId;
        if (!persistedAccountId) {
            this.errorMessage = 'Account Id is required.';
            return;
        }

        const normalizedAccountRecord = {
            ...accountRecord,
            Id: persistedAccountId
        };

        this.runtimeAccountId = persistedAccountId;
        this.accountStepRecord = normalizedAccountRecord;
        this.accountExistingJson = this.serializeSingleRecord(normalizedAccountRecord);
        this.currentStepIndex = STEP_OPPORTUNITY;
        this.evaluateCurrentStepReadiness();
    }

    advanceFromOpportunityStep() {
        if (this.showPathSelector && !this.pathSelection) {
            this.errorMessage = 'Program path selection is required.';
            return;
        }

        const opportunityEditor = this.template.querySelector('c-record-collection-editor[data-editor="opportunity"]');
        if (!opportunityEditor) {
            this.errorMessage = 'Opportunity editor is unavailable.';
            return;
        }

        const opportunityValidation = opportunityEditor.validate
            ? opportunityEditor.validate()
            : { isValid: true };
        if (!opportunityValidation.isValid) {
            this.errorMessage = opportunityValidation.errorMessage || 'Fix validation errors in Opportunity before continuing.';
            return;
        }

        if (!this.resolveProgramBaseSelection()) {
            this.errorMessage = 'Program Base App selection is required.';
            return;
        }

        const vendorSelection = this.getVendorSelection();
        if (this.shouldShowVendorSelector && !vendorSelection.selectedVendorId) {
            this.errorMessage = 'Select a Vendor before continuing.';
            return;
        }

        const opportunityRecord = this.extractSingleEditorRecord('opportunity');
        if (!opportunityRecord) {
            this.errorMessage = 'Opportunity input payload is empty.';
            return;
        }

        this.opportunityStepVendorSelection = { ...vendorSelection };
        this.opportunityStepRecord = { ...opportunityRecord };
        this.opportunityExistingJson = this.serializeSingleRecord(opportunityRecord);
        this.currentStepIndex = STEP_CONTACTS;
        this.evaluateCurrentStepReadiness();
    }

    async advanceFromContactsStep() {
        const contactsEditor = this.template.querySelector('c-record-collection-editor[data-editor="contacts"]');
        if (!contactsEditor) {
            this.errorMessage = 'Contacts editor is unavailable.';
            this.logDiagnostics('contacts_step_missing_editor', {});
            return;
        }

        const contactsValidation = contactsEditor.validate ? contactsEditor.validate() : { isValid: true };
        if (!contactsValidation.isValid) {
            this.errorMessage = contactsValidation.errorMessage || 'Fix validation errors in Contacts before continuing.';
            this.logDiagnostics('contacts_step_validation_failed', {
                errorMessage: this.errorMessage
            });
            return;
        }

        const contactsJson = this.resolveContactsJson(contactsEditor);

        let accountId = this.resolvedAccountId;
        if (!accountId) {
            accountId = this.extractAccountIdFromContactsJson(contactsJson);
        }
        if (!accountId) {
            this.errorMessage = 'Account Id is required.';
            this.logDiagnostics('contacts_step_missing_account_id', {
                contactsJsonLength: this.stringLength(contactsJson),
                contactsJsonPreview: this.truncateForDiagnostics(contactsJson),
                resolvedAccountId: this.resolvedAccountId
            });
            return;
        }
        this.runtimeAccountId = accountId;
        this.initialAccountId = this.initialAccountId || accountId;
        const contactsJsonWithAccount = this.ensureAccountIdOnContactsJson(contactsJson, accountId);
        this.lastContactsSaveRequest = {
            accountId,
            resolvedAccountId: this.resolvedAccountId,
            contactsJsonLength: this.stringLength(contactsJsonWithAccount),
            contactsJsonPreview: this.truncateForDiagnostics(contactsJsonWithAccount)
        };
        this.logDiagnostics('contacts_step_save_request', this.lastContactsSaveRequest);

        this.isSaving = true;
        try {
            const saveContactsResult = await saveContactsAndPrepareOcr({
                request: {
                    accountId,
                    contactsJson: contactsJsonWithAccount
                }
            });

            if (!saveContactsResult || !saveContactsResult.success) {
                const detailedErrors = saveContactsResult?.errorMessages?.length
                    ? saveContactsResult.errorMessages.join(' | ')
                    : null;
                this.errorMessage = detailedErrors || saveContactsResult?.errorMessage || 'Unable to save contacts.';
                this.lastContactsSaveResponse = {
                    success: false,
                    errorMessage: this.errorMessage,
                    diagnostics: this.parseDiagnosticsPayload(saveContactsResult?.diagnostics)
                };
                this.logDiagnostics('contacts_step_save_failed', this.lastContactsSaveResponse);
                return;
            }

            this.contactsExistingJson = saveContactsResult.contactRecordsJson || contactsJsonWithAccount;
            this.savedContactsJson = saveContactsResult.contactRecordsJson || contactsJsonWithAccount;
            this.opportunityContactSeedJson = saveContactsResult.opportunityContactSeedJson || '[]';
                this.lastContactsSaveResponse = {
                    success: true,
                    contactCount: saveContactsResult.contactCount,
                    signerContactCount: saveContactsResult.signerContactCount,
                    diagnostics: this.parseDiagnosticsPayload(saveContactsResult.diagnostics)
                };
            this.logDiagnostics('contacts_step_save_success', this.lastContactsSaveResponse);
            this.currentStepIndex = STEP_OCR;
            this.evaluateCurrentStepReadiness();
        } catch (error) {
            this.errorMessage = this.reduceError(error, 'Unable to save contacts.');
            this.lastContactsSaveResponse = {
                success: false,
                errorMessage: this.errorMessage
            };
            this.logDiagnostics('contacts_step_save_exception', this.lastContactsSaveResponse);
        } finally {
            this.isSaving = false;
        }
    }

    async finishFromOcrStep() {
        const ocrEditor = this.template.querySelector('c-record-collection-editor[data-editor="ocr"]');
        if (!ocrEditor) {
            this.errorMessage = 'Opportunity Contact Role editor is unavailable.';
            this.logDiagnostics('ocr_step_missing_editor', {});
            return;
        }

        const ocrValidation = ocrEditor.validate ? ocrEditor.validate() : { isValid: true };
        if (!ocrValidation.isValid) {
            this.errorMessage = ocrValidation.errorMessage || 'Fix validation errors in Opportunity Contact Roles.';
            this.logDiagnostics('ocr_step_validation_failed', {
                errorMessage: this.errorMessage
            });
            return;
        }

        const opportunityContactsJson = ocrEditor.recordsToCreate;
        if (!opportunityContactsJson) {
            this.errorMessage = 'Opportunity Contact Roles payload is empty.';
            this.logDiagnostics('ocr_step_missing_payload', {});
            return;
        }

        const accountRecord = this.accountStepRecord || this.extractSingleEditorRecord('account');
        if (!accountRecord) {
            this.errorMessage = 'Account payload is unavailable.';
            this.logDiagnostics('ocr_step_missing_account_payload', {});
            return;
        }

        const opportunityRecord = this.opportunityStepRecord || this.extractSingleEditorRecord('opportunity');
        if (!opportunityRecord) {
            this.errorMessage = 'Opportunity payload is unavailable.';
            this.logDiagnostics('ocr_step_missing_opportunity_payload', {});
            return;
        }

        const documentsReady = this.parseDocumentsReady(opportunityRecord.Documents_Ready__c);
        if (documentsReady === null) {
            this.errorMessage = 'Select whether documents are ready for onboarding.';
            this.logDiagnostics('ocr_step_missing_documents_ready', {});
            return;
        }

        const currentVendorSelection = this.getVendorSelection();
        const vendorSelection = {
            selectedVendorId: currentVendorSelection.selectedVendorId || this.opportunityStepVendorSelection.selectedVendorId,
            selectedRetailOption:
                currentVendorSelection.selectedRetailOption || this.opportunityStepVendorSelection.selectedRetailOption,
            selectedBusinessVertical:
                currentVendorSelection.selectedBusinessVertical || this.opportunityStepVendorSelection.selectedBusinessVertical
        };

        if (this.shouldShowVendorSelector && !vendorSelection.selectedVendorId) {
            this.errorMessage = 'Select a Vendor before finishing.';
            this.logDiagnostics('ocr_step_missing_vendor', {});
            return;
        }

        let accountId = this.resolvedAccountId;
        if (!accountId) {
            accountId = this.extractAccountIdFromContactsJson(this.savedContactsJson || this.contactsExistingJson);
        }
        if (!accountId) {
            this.errorMessage = 'Account Id is required.';
            this.logDiagnostics('ocr_step_missing_account_id', {});
            return;
        }
        this.runtimeAccountId = accountId;
        this.initialAccountId = this.initialAccountId || accountId;
        const contactsJsonForSubmit = this.resolveContactsJson(
            this.template.querySelector('c-record-collection-editor[data-editor="contacts"]')
        );

        this.isSaving = true;
        try {
            const submitRequest = {
                accountId,
                accountName: accountRecord.Name,
                accountPhone: accountRecord.Phone,
                billingStreet: accountRecord.BillingStreet,
                billingCity: accountRecord.BillingCity,
                billingState: accountRecord.BillingState,
                billingPostalCode: accountRecord.BillingPostalCode,
                billingCountry: accountRecord.BillingCountry,
                shippingStreet: accountRecord.ShippingStreet,
                shippingCity: accountRecord.ShippingCity,
                shippingState: accountRecord.ShippingState,
                shippingPostalCode: accountRecord.ShippingPostalCode,
                shippingCountry: accountRecord.ShippingCountry,
                contactsJson: contactsJsonForSubmit,
                opportunityContactsJson,
                finalNextAction: this.finalNextAction,
                opportunityCloseDate: opportunityRecord.CloseDate,
                opportunityStageName: opportunityRecord.StageName,
                opportunityProgramType: opportunityRecord.Program_Type__c,
                opportunityProgramBaseSelection: this.resolveProgramBaseSelection(),
                opportunityDocumentsReady: documentsReady,
                opportunityLeadSource: opportunityRecord.LeadSource,
                opportunitySource: opportunityRecord.Opportunity__c,
                opportunityNextStep: opportunityRecord.NextStep,
                opportunityNextStepDate: opportunityRecord.Next_Step_Date__c,
                opportunityOwnerRole: opportunityRecord.Owner__c,
                opportunityRecordTypeId: this.opportunityRuntime.recordTypeId,
                opportunityType: opportunityRecord.Type,
                selectedVendorId: vendorSelection.selectedVendorId,
                selectedRetailOption: vendorSelection.selectedRetailOption,
                selectedBusinessVertical: vendorSelection.selectedBusinessVertical
            };
            this.lastSubmitRequest = {
                accountId: submitRequest.accountId,
                contactsJsonLength: this.stringLength(submitRequest.contactsJson),
                contactsJsonPreview: this.truncateForDiagnostics(submitRequest.contactsJson),
                opportunityContactsJsonLength: this.stringLength(submitRequest.opportunityContactsJson)
            };
            this.logDiagnostics('ocr_step_submit_request', this.lastSubmitRequest);

            const submitResult = await submitCreateRecord({ request: submitRequest });
            if (!submitResult || !submitResult.success) {
                const stageError = submitResult?.stageErrors?.length
                    ? submitResult.stageErrors.join(' | ')
                    : null;
                this.errorMessage = stageError || submitResult?.errorMessage || 'Unable to create onboarding request.';
                this.lastSubmitResponse = {
                    success: false,
                    errorMessage: this.errorMessage,
                    diagnostics: this.parseDiagnosticsPayload(submitResult?.diagnostics)
                };
                this.logDiagnostics('ocr_step_submit_failed', this.lastSubmitResponse);
                return;
            }

            this.lastSubmitResponse = {
                success: true,
                message: submitResult.message,
                diagnostics: this.parseDiagnosticsPayload(submitResult.diagnostics)
            };
            this.logDiagnostics('ocr_step_submit_success', this.lastSubmitResponse);
            this.successMessage = submitResult.message || 'Onboarding request has been completed.';
            this.finishFlowIfAvailable();
        } catch (error) {
            this.errorMessage = this.reduceError(error, 'Unable to complete create request.');
            this.lastSubmitResponse = {
                success: false,
                errorMessage: this.errorMessage
            };
            this.logDiagnostics('ocr_step_submit_exception', this.lastSubmitResponse);
        } finally {
            this.isSaving = false;
        }
    }

    resolveContactsJson(contactsEditor) {
        const editorJson = this.getEditorRecordsJson(contactsEditor);
        if (this.hasValue(editorJson)) {
            this.lastContactsJsonResolution = {
                source: 'editor',
                length: this.stringLength(editorJson),
                preview: this.truncateForDiagnostics(editorJson)
            };
            return editorJson;
        }
        if (this.hasValue(this.savedContactsJson)) {
            const fromSaved = String(this.savedContactsJson).trim();
            this.lastContactsJsonResolution = {
                source: 'savedContactsJson',
                length: this.stringLength(fromSaved),
                preview: this.truncateForDiagnostics(fromSaved)
            };
            return fromSaved;
        }
        if (this.hasValue(this.contactsExistingJson)) {
            const fromExisting = String(this.contactsExistingJson).trim();
            this.lastContactsJsonResolution = {
                source: 'contactsExistingJson',
                length: this.stringLength(fromExisting),
                preview: this.truncateForDiagnostics(fromExisting)
            };
            return fromExisting;
        }
        this.lastContactsJsonResolution = {
            source: 'default_empty_array',
            length: 2,
            preview: '[]'
        };
        return '[]';
    }

    getEditorRecordsJson(editor) {
        if (!editor) {
            return null;
        }

        let rawValue;
        try {
            rawValue = typeof editor.getRecordsJson === 'function'
                ? editor.getRecordsJson()
                : editor.recordsToCreate;
        } catch (e) {
            rawValue = editor.recordsToCreate;
        }

        if (rawValue === undefined || rawValue === null) {
            return null;
        }
        if (typeof rawValue === 'string') {
            const trimmed = rawValue.trim();
            return trimmed === '' ? null : trimmed;
        }
        try {
            return JSON.stringify(rawValue);
        } catch (e) {
            const fallback = String(rawValue).trim();
            return fallback === '' ? null : fallback;
        }
    }

    hydrateEditorState(event) {
        const editorKey = event?.target?.dataset?.editor;
        const recordsJson = this.normalizeSerializedRecords(event?.detail?.recordsJson);
        if (!this.hasValue(editorKey) || !this.hasValue(recordsJson)) {
            return;
        }

        if (editorKey === 'account') {
            this.accountExistingJson = recordsJson;
            const accountRecord = this.extractFirstRecordFromSerializedRecords(recordsJson);
            if (accountRecord) {
                this.accountStepRecord = accountRecord;
                const accountId = this.normalizeSalesforceId(accountRecord.Id);
                if (accountId) {
                    this.runtimeAccountId = accountId;
                    this.initialAccountId = this.initialAccountId || accountId;
                }
            }
            return;
        }

        if (editorKey === 'opportunity') {
            this.opportunityExistingJson = recordsJson;
            const opportunityRecord = this.extractFirstRecordFromSerializedRecords(recordsJson);
            if (opportunityRecord) {
                this.opportunityStepRecord = opportunityRecord;
            }
            return;
        }

        if (editorKey === 'contacts') {
            this.contactsExistingJson = recordsJson;
            this.savedContactsJson = recordsJson;
            const contactsAccountId = this.extractAccountIdFromContactsJson(recordsJson);
            if (contactsAccountId) {
                this.runtimeAccountId = contactsAccountId;
                this.initialAccountId = this.initialAccountId || contactsAccountId;
            }
            return;
        }

        if (editorKey === 'ocr') {
            this.opportunityContactSeedJson = recordsJson;
        }
    }

    normalizeSerializedRecords(rawValue) {
        if (rawValue === undefined || rawValue === null) {
            return null;
        }
        if (typeof rawValue === 'string') {
            const trimmed = rawValue.trim();
            return trimmed === '' ? null : trimmed;
        }
        try {
            return JSON.stringify(rawValue);
        } catch (e) {
            const fallback = String(rawValue).trim();
            return fallback === '' ? null : fallback;
        }
    }

    extractFirstRecordFromSerializedRecords(serializedRecords) {
        if (!this.hasValue(serializedRecords)) {
            return null;
        }
        try {
            const parsed = JSON.parse(serializedRecords);
            if (!Array.isArray(parsed) || parsed.length === 0) {
                return null;
            }
            const firstRow = parsed[0];
            if (!firstRow || typeof firstRow !== 'object') {
                return null;
            }
            return firstRow.child || firstRow;
        } catch (e) {
            return null;
        }
    }

    extractAccountIdFromContactsJson(serializedRecords) {
        if (!this.hasValue(serializedRecords)) {
            return null;
        }
        try {
            const parsed = JSON.parse(serializedRecords);
            if (!Array.isArray(parsed) || parsed.length === 0) {
                return null;
            }
            for (let index = 0; index < parsed.length; index += 1) {
                const row = parsed[index];
                if (!row || typeof row !== 'object') {
                    continue;
                }
                const child = row.child && typeof row.child === 'object' ? row.child : row;
                const candidate = this.normalizeSalesforceId(child.AccountId);
                if (candidate) {
                    return candidate;
                }
            }
            return null;
        } catch (e) {
            return null;
        }
    }

    ensureAccountIdOnContactsJson(serializedRecords, accountId) {
        if (!this.hasValue(serializedRecords) || !this.hasValue(accountId)) {
            return serializedRecords;
        }
        try {
            const parsed = JSON.parse(serializedRecords);
            if (!Array.isArray(parsed)) {
                return serializedRecords;
            }
            const normalizedAccountId = this.normalizeSalesforceId(accountId);
            if (!normalizedAccountId) {
                return serializedRecords;
            }

            const patchedRows = parsed.map((row) => {
                if (!row || typeof row !== 'object') {
                    return row;
                }
                if (row.child && typeof row.child === 'object') {
                    return {
                        ...row,
                        child: {
                            ...row.child,
                            AccountId: row.child.AccountId || normalizedAccountId
                        }
                    };
                }
                return {
                    ...row,
                    AccountId: row.AccountId || normalizedAccountId
                };
            });

            return JSON.stringify(patchedRows);
        } catch (e) {
            return serializedRecords;
        }
    }

    resolveProgramBaseSelection() {
        if (this.isVendorOnlyAction) {
            return PROGRAM_BASE_BY_PATH[PATH_VENDOR];
        }
        if (this.isOfferAction && !this.showAgreementChoice) {
            return PROGRAM_BASE_BY_PATH[PATH_VENDOR];
        }
        if (this.pathSelection && PROGRAM_BASE_BY_PATH[this.pathSelection]) {
            return PROGRAM_BASE_BY_PATH[this.pathSelection];
        }
        return this.opportunityRuntime.programBaseSelection;
    }

    getVendorSelection() {
        const vendorSelector = this.template.querySelector('c-vendor-selector[data-id="vendor-selector"]');
        if (!vendorSelector) {
            return {
                selectedVendorId: null,
                selectedRetailOption: null,
                selectedBusinessVertical: null
            };
        }
        return {
            selectedVendorId: vendorSelector.outputVendorId || null,
            selectedRetailOption: vendorSelector.outputRetailOption || null,
            selectedBusinessVertical: vendorSelector.outputBusinessVertical || null
        };
    }

    extractSingleEditorRecord(editorKey) {
        const editor = this.template.querySelector(`c-record-collection-editor[data-editor="${editorKey}"]`);
        if (!editor || !editor.recordsToCreate) {
            return null;
        }
        try {
            const parsed = JSON.parse(editor.recordsToCreate);
            if (!Array.isArray(parsed) || parsed.length === 0) {
                return null;
            }
            const firstRow = parsed[0];
            if (!firstRow) {
                return null;
            }
            return firstRow.child || firstRow;
        } catch (e) {
            return null;
        }
    }

    extractAccountIdFromEditor(editorKey) {
        const editorRecord = this.extractSingleEditorRecord(editorKey);
        if (!editorRecord) {
            return null;
        }
        return editorRecord.Id || null;
    }

    parseDocumentsReady(rawValue) {
        if (rawValue === true || rawValue === false) {
            return rawValue;
        }
        if (rawValue === null || rawValue === undefined || rawValue === '') {
            return null;
        }
        const normalized = String(rawValue).trim().toLowerCase();
        if (normalized === 'yes' || normalized === 'true') {
            return true;
        }
        if (normalized === 'no' || normalized === 'false') {
            return false;
        }
        return null;
    }

    toDocumentsReadyLabel(rawValue) {
        if (rawValue === true) {
            return DOC_READY_YES;
        }
        if (rawValue === false) {
            return DOC_READY_NO;
        }
        return null;
    }

    serializeSingleRecord(recordData) {
        return JSON.stringify([recordData || {}]);
    }

    finishFlowIfAvailable() {
        if (Array.isArray(this.availableActions) && this.availableActions.includes('FINISH')) {
            this.dispatchEvent(new FlowNavigationFinishEvent());
        }
    }

    clearMessages() {
        this.errorMessage = null;
        this.successMessage = null;
    }

    reduceError(error, fallbackMessage) {
        if (!error) {
            return fallbackMessage;
        }

        if (Array.isArray(error.body)) {
            return error.body.map((row) => row.message).join(' | ');
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return fallbackMessage;
    }

    pickValue(candidate, fallbackValue) {
        if (candidate === undefined || candidate === null || candidate === '') {
            return fallbackValue;
        }
        return candidate;
    }

    toBooleanOrNull(candidate) {
        if (candidate === undefined || candidate === null || candidate === '') {
            return null;
        }
        if (typeof candidate === 'boolean') {
            return candidate;
        }
        return String(candidate).toLowerCase() === 'true';
    }

    pickBoolean(candidate, fallbackValue) {
        const parsed = this.toBooleanOrNull(candidate);
        if (parsed === null) {
            return fallbackValue === true;
        }
        return parsed;
    }

    pathFromProgramBase(programBaseSelection) {
        if (!programBaseSelection) {
            return null;
        }
        return PATH_BY_PROGRAM_BASE[programBaseSelection] || null;
    }

    hasValue(value) {
        return value !== undefined && value !== null && String(value).trim() !== '';
    }

    resolveStepVariant(variantValue) {
        return this.hasValue(variantValue) ? variantValue : this.stepHeadingVariant;
    }

    buildDiagnosticsSummary() {
        return {
            step: this.currentStepIndex,
            isLoading: this.isLoading,
            isSaving: this.isSaving,
            isCurrentStepReady: this.isCurrentStepReady,
            ids: {
                recordId: this.recordId,
                flowAccountId: this.flowAccountId,
                runtimeAccountId: this.runtimeAccountId,
                initialAccountId: this.initialAccountId,
                accountStepRecordId: this.accountStepRecord?.Id || null,
                resolvedAccountId: this.resolvedAccountId,
                fromAccountExistingJson: this.extractRecordIdFromSerializedRecords(this.accountExistingJson),
                fromContactsJson: this.extractAccountIdFromContactsJson(
                    this.savedContactsJson || this.contactsExistingJson
                )
            },
            jsonLengths: {
                accountExistingJson: this.stringLength(this.accountExistingJson),
                opportunityExistingJson: this.stringLength(this.opportunityExistingJson),
                contactsExistingJson: this.stringLength(this.contactsExistingJson),
                savedContactsJson: this.stringLength(this.savedContactsJson),
                opportunityContactSeedJson: this.stringLength(this.opportunityContactSeedJson)
            },
            lastContactsJsonResolution: this.lastContactsJsonResolution,
            lastEditorStateEvent: this.lastEditorStateEvent,
            lastContactsSaveRequest: this.lastContactsSaveRequest,
            lastContactsSaveResponse: this.lastContactsSaveResponse,
            lastSubmitRequest: this.lastSubmitRequest,
            lastSubmitResponse: this.lastSubmitResponse
        };
    }

    stringLength(rawValue) {
        if (rawValue === undefined || rawValue === null) {
            return 0;
        }
        return String(rawValue).length;
    }

    truncateForDiagnostics(rawValue) {
        if (!this.hasValue(rawValue)) {
            return rawValue;
        }
        const normalized = String(rawValue);
        const maxLength = 300;
        if (normalized.length <= maxLength) {
            return normalized;
        }
        return `${normalized.substring(0, maxLength)}...`;
    }

    logDiagnostics(eventName, payload) {
        if (!this.showDiagnosticsPanel) {
            return;
        }
        const entry = {
            timestamp: new Date().toISOString(),
            event: eventName,
            payload: payload || {}
        };
        this.diagnosticsLogEntries = [
            entry,
            ...this.diagnosticsLogEntries
        ].slice(0, DIAGNOSTIC_LOG_LIMIT);
    }

    safeStringify(value, spacing = 0) {
        try {
            return JSON.stringify(value, null, spacing);
        } catch (e) {
            return String(value);
        }
    }

    parseDiagnosticsPayload(rawDiagnostics) {
        if (!this.hasValue(rawDiagnostics)) {
            return null;
        }
        if (typeof rawDiagnostics !== 'string') {
            return rawDiagnostics;
        }
        try {
            return JSON.parse(rawDiagnostics);
        } catch (e) {
            return rawDiagnostics;
        }
    }

    toBoolean(value) {
        if (value === true || value === false) {
            return value;
        }
        if (value === undefined || value === null || value === '') {
            return false;
        }
        return String(value).toLowerCase() === 'true';
    }

    evaluateCurrentStepReadiness() {
        if (this.isLoading) {
            this.setCurrentStepReady(false);
            return;
        }

        if (this.currentStepIndex === STEP_ACCOUNT) {
            this.setCurrentStepReady(this.editorHasRequiredValues('account'));
            return;
        }

        if (this.currentStepIndex === STEP_OPPORTUNITY) {
            let ready = this.editorHasRequiredValues('opportunity');
            if (ready && this.showPathSelector) {
                ready = this.hasValue(this.pathSelection);
            }
            if (ready && this.shouldShowVendorSelector) {
                const vendorSelection = this.getVendorSelection();
                ready =
                    this.hasValue(vendorSelection.selectedVendorId) &&
                    this.hasValue(vendorSelection.selectedRetailOption) &&
                    this.hasValue(vendorSelection.selectedBusinessVertical);
            }
            this.setCurrentStepReady(ready);
            return;
        }

        if (this.currentStepIndex === STEP_CONTACTS) {
            this.setCurrentStepReady(this.editorHasRequiredValues('contacts'));
            return;
        }

        if (this.currentStepIndex === STEP_OCR) {
            this.setCurrentStepReady(this.editorHasRequiredValues('ocr'));
            return;
        }

        this.setCurrentStepReady(false);
    }

    editorHasRequiredValues(editorKey) {
        const editor = this.template.querySelector(`c-record-collection-editor[data-editor="${editorKey}"]`);
        if (!editor || typeof editor.hasRequiredValues !== 'function') {
            return false;
        }
        try {
            return editor.hasRequiredValues() === true;
        } catch (e) {
            return false;
        }
    }

    setCurrentStepReady(nextValue) {
        if (this.isCurrentStepReady !== nextValue) {
            this.isCurrentStepReady = nextValue;
        }
    }

    extractRecordIdFromSerializedRecords(serializedRecords) {
        if (!this.hasValue(serializedRecords)) {
            return null;
        }
        try {
            const parsed = JSON.parse(serializedRecords);
            if (!Array.isArray(parsed) || parsed.length === 0) {
                return null;
            }
            const firstRow = parsed[0];
            if (!firstRow) {
                return null;
            }
            if (firstRow.Id) {
                return firstRow.Id;
            }
            if (firstRow.child && firstRow.child.Id) {
                return firstRow.child.Id;
            }
            return null;
        } catch (e) {
            return null;
        }
    }

    normalizeSalesforceId(candidate) {
        if (candidate === undefined || candidate === null) {
            return null;
        }
        const normalized = String(candidate).trim();
        if (!normalized) {
            return null;
        }
        if (!SALESFORCE_ID_PATTERN.test(normalized)) {
            return null;
        }
        return normalized;
    }

    buildPreloadedContextJson() {
        const payload = {};
        this.appendPreloadedEntry(payload, 'finalNextAction', this.flowFinalNextAction);
        this.appendPreloadedEntry(payload, 'showAgreementChoice', this.flowShowAgreementChoice);
        this.appendPreloadedEntry(payload, 'showPersonalGuarantee', this.flowShowPersonalGuarantee);
        this.appendPreloadedEntry(payload, 'showVendorSelector', this.flowShowVendorSelector);
        this.appendPreloadedEntry(payload, 'showVerifyAccount', this.flowShowVerifyAccount);
        this.appendPreloadedEntry(payload, 'isUserSpecial', this.flowIsUserSpecial);
        this.appendPreloadedEntry(
            payload,
            'availableVendorOptionString',
            this.flowAvailableVendorOptionString
        );
        this.appendPreloadedEntry(
            payload,
            'hasAnyOnboardingForAccount',
            this.flowHasAnyOnboardingForAccount
        );
        this.appendPreloadedEntry(
            payload,
            'hasChuzoOnboardingForOpportunity',
            this.flowHasChuzoOnboardingForOpportunity
        );
        this.appendPreloadedEntry(
            payload,
            'hasNdaOnboardingForOpportunity',
            this.flowHasNdaOnboardingForOpportunity
        );
        this.appendPreloadedEntry(
            payload,
            'hasNonChuzoOnboardingForOpportunity',
            this.flowHasNonChuzoOnboardingForOpportunity
        );
        this.appendPreloadedEntry(payload, 'opportunityRecordTypeId', this.flowOpportunityRecordTypeId);
        this.appendPreloadedEntry(payload, 'ruleErrorMessage', this.flowRuleErrorMessage);

        if (Object.keys(payload).length === 0) {
            return null;
        }
        return JSON.stringify(payload);
    }

    appendPreloadedEntry(payload, key, value) {
        if (value === undefined || value === null || value === '') {
            return;
        }
        payload[key] = value;
    }
}
