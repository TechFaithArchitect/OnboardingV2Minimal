import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

const ACTION_OFFER_CHUZO_CREATE = 'OFFER_CHUZO_CREATE';
const ACTION_PROMPT_PATH_SELECTION = 'PROMPT_PATH_SELECTION';

const VALUE_WITH_CHUZO = 'ProgramBaseAppwithChuzo';
const VALUE_WITH_CHUZO_NO_PG = 'ProgramBaseAppwithChuzoNoPG';
const VALUE_WITHOUT_CHUZO = 'ProgramBaseAppwithoutChuzo';
const VALUE_VENDOR_PROGRAM = 'VendorProgram';

export default class OnboardingPathSelector extends LightningElement {
    @api questionLabel = 'Which Agreement Would You Like To Send?';
    @api fieldLabel = 'Select One';
    @api showVendorOpportunityPath = false;
    @api showChuzoNoPersonalGuarantee = false;
    @api showChuzoPath = false;
    @api showWithoutChuzoPath = false;

    _finalNextAction;
    _isUserSpecial = false;
    _required = false;
    _selection;

    @api
    get required() {
        return this._required;
    }

    set required(value) {
        this._required = value === true || value === 'true';
    }

    @api
    get finalNextAction() {
        return this._finalNextAction;
    }

    set finalNextAction(value) {
        this._finalNextAction = value;
        this.normalizeSelection();
    }

    @api
    get isUserSpecial() {
        return this._isUserSpecial;
    }

    set isUserSpecial(value) {
        this._isUserSpecial = value === true || value === 'true';
        this.normalizeSelection();
    }

    @api
    get selection() {
        return this._selection;
    }

    set selection(value) {
        this._selection = value;
        this.syncOutputs();
    }

    get isVisible() {
        return this.finalNextAction === ACTION_OFFER_CHUZO_CREATE ||
            this.finalNextAction === ACTION_PROMPT_PATH_SELECTION;
    }

    get options() {
        if (this.finalNextAction === ACTION_PROMPT_PATH_SELECTION) {
            return this.buildPromptOptions();
        }

        if (this.finalNextAction === ACTION_OFFER_CHUZO_CREATE) {
            return this.buildOfferOptions();
        }

        return [];
    }

    get hasOptions() {
        return this.options.length > 0;
    }

    connectedCallback() {
        this.normalizeSelection();
        this.syncOutputs();
    }

    handleSelectionChange(event) {
        this._selection = event.detail.value;
        this.syncOutputs();
    }

    @api
    validate() {
        if (!this.required || !this.isVisible || !this.hasOptions) {
            return { isValid: true };
        }

        if (this.selection) {
            return { isValid: true };
        }

        return {
            isValid: false,
            errorMessage: 'Select one option to continue.'
        };
    }

    buildPromptOptions() {
        const options = [
            { label: 'Program Base App with Chuzo', value: VALUE_WITH_CHUZO }
        ];

        if (this.isUserSpecial) {
            options.push({
                label: 'Program Base App with Chuzo (No Personal Guarantee)',
                value: VALUE_WITH_CHUZO_NO_PG
            });
        }

        options.push({
            label: 'Program Base App without Chuzo',
            value: VALUE_WITHOUT_CHUZO
        });

        return options;
    }

    buildOfferOptions() {
        const options = [
            { label: 'Program Base App with Chuzo', value: VALUE_WITH_CHUZO }
        ];

        if (this.isUserSpecial) {
            options.push({
                label: 'Program Base App with Chuzo (No Personal Guarantee)',
                value: VALUE_WITH_CHUZO_NO_PG
            });
        }

        options.push({ label: 'Vendor Program', value: VALUE_VENDOR_PROGRAM });
        return options;
    }

    normalizeSelection() {
        if (!this.hasOptions) {
            if (this._selection) {
                this._selection = null;
                this.dispatchFlowChange('selection', null);
            }
            this.syncOutputs();
            return;
        }

        const validValues = new Set(this.options.map((option) => option.value));
        if (this._selection && !validValues.has(this._selection)) {
            this._selection = null;
            this.dispatchFlowChange('selection', null);
        }

        this.syncOutputs();
    }

    syncOutputs() {
        this.showVendorOpportunityPath = this.selection === VALUE_VENDOR_PROGRAM;
        this.showChuzoNoPersonalGuarantee = this.selection === VALUE_WITH_CHUZO_NO_PG;
        this.showChuzoPath = this.selection === VALUE_WITH_CHUZO || this.selection === VALUE_WITH_CHUZO_NO_PG;
        this.showWithoutChuzoPath = this.selection === VALUE_WITHOUT_CHUZO;

        this.dispatchFlowChange('selection', this.selection || null);
        this.dispatchFlowChange('showVendorOpportunityPath', this.showVendorOpportunityPath);
        this.dispatchFlowChange('showChuzoNoPersonalGuarantee', this.showChuzoNoPersonalGuarantee);
        this.dispatchFlowChange('showChuzoPath', this.showChuzoPath);
        this.dispatchFlowChange('showWithoutChuzoPath', this.showWithoutChuzoPath);
    }

    dispatchFlowChange(attributeName, value) {
        this.dispatchEvent(new FlowAttributeChangeEvent(attributeName, value));
    }
}