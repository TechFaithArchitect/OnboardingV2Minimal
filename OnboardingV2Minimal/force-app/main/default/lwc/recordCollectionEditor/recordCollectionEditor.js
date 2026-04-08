import { LightningElement, api, track, wire } from 'lwc';
import getConfig from '@salesforce/apex/RecordCollectionEditorConfigService.getConfig';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import labelPrincipalOwnerConflict from '@salesforce/label/c.Principal_Owner_Conflict';
import labelAuthorizedSignerPermissionDenied from '@salesforce/label/c.RecordCollectionEditor_AuthorizedSignerPermissionDenied';
import labelFixFieldErrors from '@salesforce/label/c.RecordCollectionEditor_FixFieldErrors';
import labelExactlyOnePrimaryContact from '@salesforce/label/c.RecordCollectionEditor_ExactlyOnePrimaryContact';

export default class RecordCollectionEditor extends LightningElement {
    @api heading = 'Records';
    @api recordLabel = 'Row';
    @api configKey;
    @api parentId;
    @api recordTypeId;

    _apiExistingRecordsJson;

    @api
    get existingRecordsJson() {
        return this._apiExistingRecordsJson;
    }

    set existingRecordsJson(value) {
        const next = value === undefined || value === null ? '' : String(value);
        const prev =
            this._apiExistingRecordsJson === undefined || this._apiExistingRecordsJson === null
                ? ''
                : String(this._apiExistingRecordsJson);
        this._apiExistingRecordsJson = value;
        if (next === prev) {
            return;
        }
        // expCreateRecord (and similar parents) assign existing-records-json from hydrateEditorState on
        // every statechange — same payload the editor just emitted. Re-applying would rebuild rows and
        // drop focus from the active input on each keystroke.
        if (this.isParentEchoOfCurrentOutput(next)) {
            return;
        }
        this.applyExistingRecordsJsonWhenConfigured();
    }

    isParentEchoOfCurrentOutput(incomingNextStr) {
        if (!this.fieldConfigs || !this.fieldConfigs.length) {
            return false;
        }
        const selfRaw = this.recordsToCreate;
        if (selfRaw === undefined || selfRaw === null) {
            return false;
        }
        const a = incomingNextStr.trim();
        const b = String(selfRaw).trim();
        if (!a || !b) {
            return false;
        }
        if (a === b) {
            return true;
        }
        try {
            return JSON.stringify(JSON.parse(a)) === JSON.stringify(JSON.parse(b));
        } catch {
            return false;
        }
    }
    @api minRows = 1;
    @api maxRows;
    @api hideRowContainer = false;
    @api hideRowSubheading = false;

    @api recordsToCreate;
    @api hasValidationError = false;
    @api errorMessage;

    @track rows = [];
    @track fieldConfigs = [];
    @track relationshipFieldConfigs = [];
    @track isLoading = true;
    @track parentFieldApiNameFromConfig;
    @track roleConstraints = null;
    @track canAssignAuthorizedSigner = true;
    @track objectApiName;
    @track objectDefaultRecordTypeId;
    @track picklistFieldValuesByApiName = {};

    _configLoadError;

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data }) {
        this.objectDefaultRecordTypeId = data?.defaultRecordTypeId || null;
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$objectApiName',
        recordTypeId: '$effectiveRecordTypeId'
    })
    wiredPicklistValues({ data }) {
        this.picklistFieldValuesByApiName = data?.picklistFieldValues || {};
        this.refreshDynamicPicklistOptions();
        this.refreshAddressOptions();
    }

    @wire(getConfig, { developerName: '$configKey' })
    wiredConfig(configWireResult) {
        const { error: configLoadError, data: configData } = configWireResult;

        if (configData) {
            this.objectApiName = configData.objectApiName;
            this.fieldConfigs = configData.fields || [];
            this.relationshipFieldConfigs = configData.relationshipFields || [];
            this.parentFieldApiNameFromConfig = configData.parentFieldApiName;
            this.roleConstraints = configData.roleConstraints || null;
            this.canAssignAuthorizedSigner =
                this.roleConstraints &&
                typeof this.roleConstraints.canAssignAuthorizedSigner === 'boolean'
                    ? this.roleConstraints.canAssignAuthorizedSigner
                    : true;
            this.isLoading = false;
            if (!this.rows.length) {
                this.applyExistingRecordsJsonWhenConfigured();
            }
        } else if (configLoadError) {
            this._configLoadError = configLoadError;
            this.isLoading = false;
            this.errorMessage =
                (configLoadError &&
                    configLoadError.body &&
                    configLoadError.body.message) ||
                'Error loading record collection editor configuration.';
        }
    }

    connectedCallback() {
        if (!this.configKey) {
            this.errorMessage = 'Config key is required.';
            this.isLoading = false;
        }
    }

    get effectiveRecordTypeId() {
        if (this.hasValue(this.recordTypeId)) {
            return String(this.recordTypeId).trim();
        }
        return this.objectDefaultRecordTypeId;
    }

    applyExistingRecordsJsonWhenConfigured() {
        if (this.isLoading || !this.fieldConfigs || !this.fieldConfigs.length || !this.configKey) {
            return;
        }
        this.errorMessage = null;
        this.rows = [];
        const json = this.existingRecordsJson;
        const trimmed = json && String(json).trim();
        if (trimmed) {
            let treatAsEmptySeed = false;
            try {
                const parsed = JSON.parse(trimmed);
                if (Array.isArray(parsed) && parsed.length === 0) {
                    treatAsEmptySeed = true;
                }
            } catch {
                // populateRowsFromExisting will surface invalid JSON
            }
            if (treatAsEmptySeed) {
                this.initializeRows();
            } else {
                this.populateRowsFromExisting();
            }
        } else {
            this.initializeRows();
        }
    }

    applyDefaultPrincipalOwnerOnFirstContactRow(relationshipFieldStates, rowIndex) {
        if (this.configKey !== 'CONTACT_ON_ACCOUNT' || rowIndex !== 0) {
            return relationshipFieldStates;
        }
        const rc = this.roleConstraints;
        if (!rc || !rc.roleFieldApiName) {
            return relationshipFieldStates;
        }
        const singles = rc.singlePerAccountRoles || [];
        if (!singles.includes('Principal Owner')) {
            return relationshipFieldStates;
        }
        const roleField = rc.roleFieldApiName;
        return relationshipFieldStates.map((fs) => {
            if (fs.fieldApiName !== roleField) {
                return fs;
            }
            if (fs.value !== undefined && fs.value !== null && fs.value !== '') {
                return fs;
            }
            return { ...fs, value: 'Principal Owner' };
        });
    }

    initializeRows() {
        const count = Math.max(1, this.minRows || 1);
        for (let i = 0; i < count; i++) {
            this.addRowInternal(null);
        }
        this.syncOutputRecords();
    }

    populateRowsFromExisting() {
        let parsed;
        try {
            parsed = JSON.parse(this.existingRecordsJson.trim());
        } catch {
            this.errorMessage = 'Invalid existing records JSON.';
            this.rows = [];
            return;
        }
        const records = Array.isArray(parsed) ? parsed : [parsed];
        const label = (this.recordLabel || 'Row').trim();
        const seededRows = records.map((rec, idx) => {
            const childData = rec.child || rec;
            const relData = rec.relationship || {};
            const recordId = childData.Id || null;

            const fieldStates = this.fieldConfigs.map((fc) => {
                const dataType = fc.dataType || 'text';
                const normalizedType = String(dataType).toLowerCase();
                const isPhoneField = normalizedType === 'tel' || normalizedType === 'phone';
                const isCheckbox = normalizedType === 'checkbox';
                const isPicklist = normalizedType === 'picklist' || (fc.picklistValues && fc.picklistValues.length > 0);
                const isLookup = normalizedType === 'lookup';
                const isAddress = normalizedType === 'address';
                const columnSize = fc.columnSize || '1-of-2';
                const columnClass =
                    columnSize === '1-of-4' || columnSize === 'quarter'
                        ? 'slds-col slds-size_1-of-1 slds-small-size_1-of-2 slds-medium-size_1-of-4 slds-p-right_small slds-p-bottom_small'
                        : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
                const val = isAddress ? null : childData[fc.fieldApiName];
                const addressPrefix = isAddress ? fc.addressPrefix : null;
                const addressValue = isAddress
                    ? this.normalizeAddressValue({
                        street: childData[`${addressPrefix}Street`],
                        city: childData[`${addressPrefix}City`],
                        province:
                            childData[`${addressPrefix}StateCode`] ??
                            childData[`${addressPrefix}State`],
                        postalCode: childData[`${addressPrefix}PostalCode`],
                        country:
                            childData[`${addressPrefix}CountryCode`] ??
                            childData[`${addressPrefix}Country`]
                    })
                    : null;
                const countryOptions = isAddress ? this.getAddressCountryOptions(addressPrefix) : null;
                const normalizedCountry = isAddress
                    ? this.normalizeAddressPicklistSelection(countryOptions, addressValue.country)
                    : null;
                const provinceOptions = isAddress
                    ? this.getAddressProvinceOptions(addressPrefix, normalizedCountry)
                    : null;
                const normalizedProvince = isAddress
                    ? this.normalizeAddressPicklistSelection(provinceOptions, addressValue.province)
                    : null;
                return {
                    fieldApiName: fc.fieldApiName,
                    label: fc.label,
                    dataType,
                    required: fc.required,
                    effectiveRequired: fc.required,
                    readOnly: fc.readOnly === true,
                    controllingFieldApiName: fc.controllingFieldApiName,
                    isDisabled: fc.readOnly === true,
                    isPhoneField,
                    isCheckbox,
                    isPicklist,
                    isLookup,
                    isAddress,
                    isTextOrDateInput: !isPhoneField && !isCheckbox && !isPicklist && !isLookup && !isAddress,
                    picklistOptions: isPicklist ? this.toPicklistOptions(fc.picklistValues) : [],
                    lookupObjectApiName: fc.lookupObjectApiName,
                    addressPrefix,
                    showAddressLookup: fc.showAddressLookup === true,
                    street: isAddress ? addressValue.street : undefined,
                    city: isAddress ? addressValue.city : undefined,
                    province: isAddress ? normalizedProvince : undefined,
                    postalCode: isAddress ? addressValue.postalCode : undefined,
                    country: isAddress ? normalizedCountry : undefined,
                    countryOptions: isAddress ? countryOptions : undefined,
                    provinceOptions: isAddress ? provinceOptions : undefined,
                    columnClass,
                    value: val !== undefined && val !== null ? String(val) : null,
                    checked: isCheckbox ? (val === true || val === 'true') : undefined,
                    errorMessage: null,
                    formElementClass: 'slds-form-element'
                };
            });

            const relColumnClass = 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
            const relationshipFieldStates = this.relationshipFieldConfigs.map((fc) => {
                const val = relData[fc.fieldApiName];
                const isPicklist = fc.dataType === 'picklist' || (fc.picklistValues && fc.picklistValues.length > 0);
                const isCheckbox = fc.dataType === 'checkbox';
                const isLookup = fc.dataType === 'lookup';
                return {
                    fieldApiName: fc.fieldApiName,
                    label: fc.label,
                    dataType: fc.dataType || 'text',
                    required: fc.required,
                    effectiveRequired: fc.required,
                    readOnly: fc.readOnly === true,
                    controllingFieldApiName: fc.controllingFieldApiName,
                    isDisabled: fc.readOnly === true,
                    isPicklist,
                    isCheckbox,
                    isLookup,
                    isTextOrDateInput: !isPicklist && !isCheckbox && !isLookup,
                    picklistOptions: this.getFilteredPicklistOptions(fc),
                    lookupObjectApiName: fc.lookupObjectApiName,
                    columnClass: relColumnClass,
                    value: val !== undefined && val !== null ? String(val) : null,
                    checked: isCheckbox ? (val === true || val === 'true') : undefined,
                    errorMessage: null,
                    formElementClass: 'slds-form-element'
                };
            });

            return {
                clientId: `row-${idx}-${Date.now()}`,
                recordId,
                isFirstRow: idx === 0,
                subheading: `${label} ${idx + 1}`,
                fieldStates,
                relationshipFieldStates
            };
        });
        this.rows = seededRows.map((row) => this.refreshRowPicklistOptionsForRow(row, true));
        this.normalizePrimaryContactSelection();
        this.syncOutputRecords();
        this.refreshAllRolePicklistOptions();
    }

    get hasRows() {
        return this.rows && this.rows.length > 0;
    }

    handleAddRow() {
        if (this.maxRows && this.rows.length >= this.maxRows) {
            return;
        }
        this.addRowInternal(null);
        this.refreshAllRolePicklistOptions();
        this.syncOutputRecords();
    }

    addRowInternal(recordId = null) {
        const rowIndex = this.rows.length;
        const fieldStatesForRow = this.fieldConfigs.map((fieldConfig) => {
            const dataType = fieldConfig.dataType || 'text';
            const normalizedType = String(dataType).toLowerCase();
            const isPhoneField = normalizedType === 'tel' || normalizedType === 'phone';
            const isCheckbox = normalizedType === 'checkbox';
            const isPicklist = normalizedType === 'picklist' || (fieldConfig.picklistValues && fieldConfig.picklistValues.length > 0);
            const isLookup = normalizedType === 'lookup';
            const isAddress = normalizedType === 'address';
            const columnSize = fieldConfig.columnSize || '1-of-2';
            const columnClass =
                columnSize === '1-of-4' || columnSize === 'quarter'
                    ? 'slds-col slds-size_1-of-1 slds-small-size_1-of-2 slds-medium-size_1-of-4 slds-p-right_small slds-p-bottom_small'
                    : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
            const addressPrefix = isAddress ? fieldConfig.addressPrefix : null;
            const countryOptions = isAddress ? this.getAddressCountryOptions(addressPrefix) : null;
            const provinceOptions = isAddress ? this.getAddressProvinceOptions(addressPrefix, null) : null;
            return {
                fieldApiName: fieldConfig.fieldApiName,
                label: fieldConfig.label,
                dataType,
                required: fieldConfig.required,
                effectiveRequired: fieldConfig.required,
                readOnly: fieldConfig.readOnly === true,
                controllingFieldApiName: fieldConfig.controllingFieldApiName,
                isDisabled: fieldConfig.readOnly === true,
                isPhoneField,
                isCheckbox,
                isPicklist,
                isLookup,
                isAddress,
                isTextOrDateInput: !isPhoneField && !isCheckbox && !isPicklist && !isLookup && !isAddress,
                picklistOptions: isPicklist ? this.toPicklistOptions(fieldConfig.picklistValues) : [],
                lookupObjectApiName: fieldConfig.lookupObjectApiName,
                addressPrefix,
                showAddressLookup: isAddress ? fieldConfig.showAddressLookup === true : false,
                street: isAddress ? '' : undefined,
                city: isAddress ? '' : undefined,
                province: isAddress ? '' : undefined,
                postalCode: isAddress ? '' : undefined,
                country: isAddress ? '' : undefined,
                countryOptions: isAddress ? countryOptions : undefined,
                provinceOptions: isAddress ? provinceOptions : undefined,
                columnClass,
                value: null,
                checked: isCheckbox ? false : undefined,
                errorMessage: null,
                formElementClass: 'slds-form-element'
            };
        });

        const relColumnClass = 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
        const newRow = { relationshipFieldStates: [] };
        const relationshipFieldStatesForRowRaw = this.relationshipFieldConfigs.map((fieldConfig) => {
            const isPicklist = fieldConfig.dataType === 'picklist' || (fieldConfig.picklistValues && fieldConfig.picklistValues.length > 0);
            const isCheckbox = fieldConfig.dataType === 'checkbox';
            const isLookup = fieldConfig.dataType === 'lookup';
            return {
                fieldApiName: fieldConfig.fieldApiName,
                label: fieldConfig.label,
                dataType: fieldConfig.dataType || 'text',
                required: fieldConfig.required,
                effectiveRequired: fieldConfig.required,
                readOnly: fieldConfig.readOnly === true,
                controllingFieldApiName: fieldConfig.controllingFieldApiName,
                isDisabled: fieldConfig.readOnly === true,
                isPicklist,
                isCheckbox,
                isLookup,
                isTextOrDateInput: !isPicklist && !isCheckbox && !isLookup,
                picklistOptions: this.getFilteredPicklistOptionsForRow(fieldConfig, newRow, rowIndex),
                lookupObjectApiName: fieldConfig.lookupObjectApiName,
                columnClass: relColumnClass,
                value: null,
                checked: isCheckbox ? false : undefined,
                errorMessage: null,
                formElementClass: 'slds-form-element'
            };
        });
        const relationshipFieldStatesForRow = this.applyDefaultPrincipalOwnerOnFirstContactRow(
            relationshipFieldStatesForRowRaw,
            rowIndex
        );
        newRow.relationshipFieldStates = relationshipFieldStatesForRow;

        const label = (this.recordLabel || 'Row').trim();
        const baseRow = {
            clientId: `row-${rowIndex}-${Date.now()}`,
            recordId,
            isFirstRow: rowIndex === 0,
            subheading: `${label} ${rowIndex + 1}`,
            fieldStates: fieldStatesForRow,
            relationshipFieldStates: relationshipFieldStatesForRow
        };
        const hydratedRow = this.refreshRowPicklistOptionsForRow(baseRow, true);
        this.rows = [
            ...this.rows,
            hydratedRow
        ];
    }

    handleRemoveLastRow() {
        if (this.rows.length <= (this.minRows || 1)) {
            return;
        }
        this.rows = this.rows.slice(0, -1);
        this.refreshAllRolePicklistOptions();
        this.syncOutputRecords();
    }

    handleFieldChange(event) {
        const targetEl = event.target;
        const clientId = targetEl?.dataset?.clientId ?? targetEl?.closest?.('[data-client-id]')?.dataset?.clientId;
        const fieldApiName = targetEl?.dataset?.fieldApiName ?? targetEl?.closest?.('[data-field-api-name]')?.dataset?.fieldApiName;
        const isRelationship = targetEl?.dataset?.relationship === 'true' || targetEl?.closest?.('[data-relationship="true"]')?.dataset?.relationship === 'true';
        const currentRow = this.rows.find((row) => row.clientId === clientId);
        const currentFieldState = isRelationship
            ? currentRow?.relationshipFieldStates?.find((fs) => fs.fieldApiName === fieldApiName)
            : currentRow?.fieldStates?.find((fs) => fs.fieldApiName === fieldApiName);
        const isAddressField = currentFieldState?.isAddress === true;
        let newFieldValue;
        if (isAddressField) {
            newFieldValue = this.normalizeAddressValue(event.detail);
        } else if (event.detail && Object.prototype.hasOwnProperty.call(event.detail, 'recordId')) {
            newFieldValue = event.detail.recordId;
        } else if (event.detail && Object.prototype.hasOwnProperty.call(event.detail, 'checked')) {
            newFieldValue = event.detail.checked;
        } else {
            newFieldValue = event.detail?.value;
        }

        if (!clientId || !fieldApiName) {
            return;
        }

        const dependentFieldApiNames = this.getDependentFieldApiNames(fieldApiName, isRelationship);

        let rowsCopy = this.rows.map((row) => {
            if (row.clientId !== clientId) return row;
            if (isRelationship) {
                const updatedRelStates = (row.relationshipFieldStates || []).map((fs) => {
                    if (fs.fieldApiName === fieldApiName) {
                        const updated = { ...fs, value: newFieldValue, errorMessage: null, formElementClass: 'slds-form-element' };
                        if (fs.isCheckbox) updated.checked = newFieldValue;
                        return updated;
                    }
                    if (dependentFieldApiNames.has(fs.fieldApiName)) {
                        return this.resetFieldStateValue(fs);
                    }
                    return fs;
                });
                return { ...row, relationshipFieldStates: updatedRelStates };
            }
            const updatedFieldStates = row.fieldStates.map((fieldState) => {
                if (fieldState.fieldApiName === fieldApiName) {
                    if (fieldState.isAddress) {
                        const normalizedAddress = this.normalizeAddressValue(newFieldValue);
                        const countryOptions = this.getAddressCountryOptions(fieldState.addressPrefix);
                        const normalizedCountry = this.normalizeAddressPicklistSelection(
                            countryOptions,
                            normalizedAddress.country
                        );
                        const provinceOptions = this.getAddressProvinceOptions(
                            fieldState.addressPrefix,
                            normalizedCountry
                        );
                        const normalizedProvince = this.normalizeAddressPicklistSelection(
                            provinceOptions,
                            normalizedAddress.province
                        );
                        return {
                            ...fieldState,
                            street: normalizedAddress.street,
                            city: normalizedAddress.city,
                            province: normalizedProvince,
                            postalCode: normalizedAddress.postalCode,
                            country: normalizedCountry,
                            countryOptions,
                            provinceOptions,
                            errorMessage: null,
                            formElementClass: 'slds-form-element'
                        };
                    }
                    const updated = { ...fieldState, value: newFieldValue, errorMessage: null, formElementClass: 'slds-form-element' };
                    if (fieldState.isCheckbox) updated.checked = newFieldValue;
                    return updated;
                }
                if (dependentFieldApiNames.has(fieldState.fieldApiName)) {
                    return this.resetFieldStateValue(fieldState);
                }
                return fieldState;
            });
            return { ...row, fieldStates: updatedFieldStates };
        });

        if (this.configKey === 'CONTACT_ON_OPPORTUNITY') {
            this.applyExclusivePrimaryContactRules(rowsCopy, clientId, fieldApiName, newFieldValue, isRelationship);
        }

        rowsCopy = rowsCopy.map((row) => this.refreshRowPicklistOptionsForRow(row, true));
        this.rows = rowsCopy;
        if (isRelationship && this.roleConstraints?.roleFieldApiName === fieldApiName) {
            this.refreshAllRolePicklistOptions();
        }
        this.syncOutputRecords();
    }

    syncOutputRecords() {
        const parentFieldApiName = this.parentFieldApiNameFromConfig;
        const hasRelationshipFields = this.relationshipFieldConfigs.length > 0;

        const outputRecords = this.rows.map((row) => {
            const childRecord = {};
            if (row.recordId) {
                childRecord.Id = row.recordId;
            }
            row.fieldStates.forEach((fieldState) => {
                if (fieldState.isAddress) {
                    const addressPrefix = fieldState.addressPrefix;
                    if (!addressPrefix) {
                        return;
                    }
                    const addressValues = {
                        [`${addressPrefix}Street`]: fieldState.street,
                        [`${addressPrefix}City`]: fieldState.city,
                        [`${addressPrefix}State`]: fieldState.province,
                        [`${addressPrefix}PostalCode`]: fieldState.postalCode,
                        [`${addressPrefix}Country`]: fieldState.country
                    };
                    Object.keys(addressValues).forEach((fieldName) => {
                        const value = addressValues[fieldName];
                        if (value !== undefined && value !== null && (typeof value !== 'string' || value !== '')) {
                            childRecord[fieldName] = value;
                        }
                    });
                    return;
                }
                const val = fieldState.isCheckbox ? (fieldState.checked === true || fieldState.checked === 'true') : fieldState.value;
                if (val !== undefined && val !== null && (typeof val !== 'string' || val !== '')) {
                    childRecord[fieldState.fieldApiName] = val;
                }
            });
            // Always include parent id in payload so relationship creation can
            // resolve parent context even when editing existing child records.
            if (this.parentId && parentFieldApiName) {
                childRecord[parentFieldApiName] = this.parentId;
            }

            if (!hasRelationshipFields) {
                return childRecord;
            }

            const relationshipRecord = {};
            (row.relationshipFieldStates || []).forEach((fs) => {
                const val = fs.isCheckbox ? (fs.checked === true || fs.checked === 'true') : fs.value;
                const hasValue = val !== undefined && val !== null &&
                    (typeof val !== 'string' || val !== '');
                if (hasValue) {
                    relationshipRecord[fs.fieldApiName] = val;
                }
            });
            return { child: childRecord, relationship: relationshipRecord };
        });

        this.recordsToCreate = JSON.stringify(outputRecords);
        this.notifyStateChange();
    }

    get showAddRowButton() {
        if (!this.maxRows) {
            return true;
        }
        return this.rows.length < this.maxRows;
    }

    get showActionRow() {
        return this.showAddRowButton || this.canShowRemoveButton;
    }

    get canShowRemoveButton() {
        return this.rows.length > (this.minRows || 1);
    }

    get addButtonLabel() {
        const label = (this.recordLabel || 'Row').trim();
        return label ? `Add ${label}` : 'Add Row';
    }

    get removeButtonLabel() {
        const label = (this.recordLabel || 'Row').trim();
        return label ? `Remove ${label}` : 'Remove row';
    }

    get hasHeading() {
        return this.hasValue(this.heading);
    }

    get hideRowContainerEnabled() {
        return this.toBoolean(this.hideRowContainer);
    }

    get hideRowSubheadingEnabled() {
        return this.toBoolean(this.hideRowSubheading);
    }

    get rowContainerClass() {
        return this.hideRowContainerEnabled
            ? 'slds-m-bottom_small'
            : 'slds-box slds-m-bottom_small';
    }

    refreshAddressOptions() {
        if (!Array.isArray(this.rows) || this.rows.length === 0) {
            return;
        }

        let changed = false;
        const updatedRows = this.rows.map((row) => {
            const updatedFieldStates = (row.fieldStates || []).map((fieldState) => {
                if (!fieldState.isAddress) {
                    return fieldState;
                }

                const countryOptions = this.getAddressCountryOptions(fieldState.addressPrefix);
                const normalizedCountry = this.normalizeAddressPicklistSelection(
                    countryOptions,
                    fieldState.country
                );
                const provinceOptions = this.getAddressProvinceOptions(
                    fieldState.addressPrefix,
                    normalizedCountry
                );
                const normalizedProvince = this.normalizeAddressPicklistSelection(
                    provinceOptions,
                    fieldState.province
                );

                const nextState = {
                    ...fieldState,
                    country: normalizedCountry,
                    province: normalizedProvince,
                    countryOptions,
                    provinceOptions
                };
                if (
                    nextState.country !== fieldState.country ||
                    nextState.province !== fieldState.province ||
                    nextState.countryOptions !== fieldState.countryOptions ||
                    nextState.provinceOptions !== fieldState.provinceOptions
                ) {
                    changed = true;
                }
                return nextState;
            });
            return { ...row, fieldStates: updatedFieldStates };
        });

        if (!changed) {
            return;
        }

        this.rows = updatedRows;
        this.syncOutputRecords();
    }

    getAddressCountryOptions(addressPrefix) {
        if (!this.hasValue(addressPrefix)) {
            return null;
        }
        const fieldApiName = `${addressPrefix}CountryCode`;
        const fieldPicklist = this.picklistFieldValuesByApiName?.[fieldApiName];
        const values = fieldPicklist?.values || [];
        if (!Array.isArray(values) || values.length === 0) {
            return null;
        }
        return values.map((entry) => ({ label: entry.label, value: entry.value }));
    }

    getAddressProvinceOptions(addressPrefix, selectedCountryCode) {
        if (!this.hasValue(addressPrefix)) {
            return null;
        }
        const fieldApiName = `${addressPrefix}StateCode`;
        const fieldPicklist = this.picklistFieldValuesByApiName?.[fieldApiName];
        const values = fieldPicklist?.values || [];
        if (!Array.isArray(values) || values.length === 0) {
            return null;
        }

        let filteredValues = values;
        const controllerValues = fieldPicklist?.controllerValues || null;
        const controllerIndex =
            controllerValues && this.hasValue(selectedCountryCode)
                ? controllerValues[selectedCountryCode]
                : undefined;
        if (controllerIndex !== undefined) {
            filteredValues = values.filter((entry) => {
                if (!Array.isArray(entry.validFor) || entry.validFor.length === 0) {
                    return true;
                }
                return entry.validFor.includes(controllerIndex);
            });
        }

        return filteredValues.map((entry) => ({ label: entry.label, value: entry.value }));
    }

    refreshDynamicPicklistOptions() {
        if (!Array.isArray(this.rows) || this.rows.length === 0) {
            return;
        }

        let changed = false;
        const updatedRows = this.rows.map((row) => {
            const refreshedRow = this.refreshRowPicklistOptionsForRow(row, true);
            if (refreshedRow !== row) {
                changed = true;
            }
            return refreshedRow;
        });

        if (!changed) {
            return;
        }

        this.rows = updatedRows;
        this.syncOutputRecords();
    }

    refreshRowPicklistOptionsForRow(row, clearInvalidSelection) {
        if (!row || !Array.isArray(row.fieldStates) || row.fieldStates.length === 0) {
            return row;
        }

        let rowChanged = false;
        const updatedFieldStates = row.fieldStates.map((fieldState) => {
            if (!fieldState?.isPicklist || fieldState.isAddress) {
                return fieldState;
            }

            const fieldConfig = this.fieldConfigs.find(
                (configItem) => configItem.fieldApiName === fieldState.fieldApiName
            );
            if (!fieldConfig) {
                return fieldState;
            }

            const nextOptions = this.getPicklistOptionsForFieldConfig(fieldConfig, row.fieldStates);
            let nextValue = fieldState.value;
            const hasCurrentValue = this.hasValue(nextValue);
            const valueStillValid = hasCurrentValue
                ? nextOptions.some((option) => option.value === nextValue)
                : true;
            const isDependentPicklist = this.hasValue(fieldConfig.controllingFieldApiName);
            const noDependentOptionsAvailable = isDependentPicklist && nextOptions.length === 0;
            const dependencyDisabled = this.isFieldDependencyDisabled(fieldConfig, row.fieldStates);
            const nextDisabled = fieldState.readOnly === true || dependencyDisabled || noDependentOptionsAvailable;
            const nextEffectiveRequired = fieldState.required === true && !nextDisabled;

            if (clearInvalidSelection && hasCurrentValue && !valueStillValid) {
                nextValue = null;
            }

            const optionsChanged = !this.arePicklistOptionsEqual(fieldState.picklistOptions, nextOptions);
            const valueChanged = nextValue !== fieldState.value;
            const disabledChanged = nextDisabled !== fieldState.isDisabled;
            const requiredChanged = nextEffectiveRequired !== fieldState.effectiveRequired;
            if (!optionsChanged && !valueChanged && !disabledChanged && !requiredChanged) {
                return fieldState;
            }

            rowChanged = true;
            return {
                ...fieldState,
                picklistOptions: nextOptions,
                isDisabled: nextDisabled,
                effectiveRequired: nextEffectiveRequired,
                value: nextValue,
                errorMessage: (valueChanged || disabledChanged || requiredChanged) ? null : fieldState.errorMessage,
                formElementClass: (valueChanged || disabledChanged || requiredChanged)
                    ? 'slds-form-element'
                    : fieldState.formElementClass
            };
        });

        if (!rowChanged) {
            return row;
        }

        return {
            ...row,
            fieldStates: updatedFieldStates
        };
    }

    getPicklistOptionsForFieldConfig(fieldConfig, rowFieldStates) {
        const fallbackOptions = this.toPicklistOptions(fieldConfig?.picklistValues);
        if (!fieldConfig || !this.hasValue(fieldConfig.fieldApiName)) {
            return fallbackOptions;
        }

        const picklistMetadata = this.picklistFieldValuesByApiName?.[fieldConfig.fieldApiName];
        const metadataValues = Array.isArray(picklistMetadata?.values) ? picklistMetadata.values : [];
        const metadataOptions = metadataValues
            .filter((entry) => entry && entry.active !== false)
            .map((entry) => ({ label: entry.label, value: entry.value }));

        let resolvedOptions = metadataOptions.length > 0 ? metadataOptions : fallbackOptions;

        const controllingFieldApiName = fieldConfig.controllingFieldApiName;
        if (
            this.hasValue(controllingFieldApiName) &&
            metadataValues.length > 0 &&
            picklistMetadata &&
            picklistMetadata.controllerValues
        ) {
            const controllingValue = this.getRowFieldStateValue(
                rowFieldStates,
                controllingFieldApiName
            );
            if (!this.hasValue(controllingValue)) {
                return [];
            }

            const controllerIndex = picklistMetadata.controllerValues[controllingValue];
            if (controllerIndex === undefined || controllerIndex === null) {
                return [];
            }

            resolvedOptions = metadataValues
                .filter((entry) => {
                    if (entry?.active === false) {
                        return false;
                    }
                    if (!Array.isArray(entry.validFor) || entry.validFor.length === 0) {
                        return true;
                    }
                    return entry.validFor.includes(controllerIndex);
                })
                .map((entry) => ({ label: entry.label, value: entry.value }));
        }

        return resolvedOptions;
    }

    isFieldDependencyDisabled(fieldConfig, rowFieldStates) {
        const controllingFieldApiName = fieldConfig?.controllingFieldApiName;
        if (!this.hasValue(controllingFieldApiName)) {
            return false;
        }
        const controllingValue = this.getRowFieldStateValue(rowFieldStates, controllingFieldApiName);
        return !this.hasValue(controllingValue);
    }

    getDependentFieldApiNames(controllingFieldApiName, isRelationship) {
        const dependentSet = new Set();
        if (!this.hasValue(controllingFieldApiName)) {
            return dependentSet;
        }
        const configList = isRelationship ? this.relationshipFieldConfigs : this.fieldConfigs;
        (configList || []).forEach((configItem) => {
            if (configItem?.controllingFieldApiName === controllingFieldApiName) {
                dependentSet.add(configItem.fieldApiName);
            }
        });
        return dependentSet;
    }

    resetFieldStateValue(fieldState) {
        if (!fieldState) {
            return fieldState;
        }
        const baseState = {
            ...fieldState,
            value: null,
            errorMessage: null,
            formElementClass: 'slds-form-element'
        };
        if (fieldState.isCheckbox) {
            baseState.checked = false;
        }
        if (fieldState.isAddress) {
            baseState.street = '';
            baseState.city = '';
            baseState.province = '';
            baseState.postalCode = '';
            baseState.country = '';
        }
        return baseState;
    }

    isFieldRequiredForValidation(fieldState) {
        if (!fieldState) {
            return false;
        }
        if (fieldState.isDisabled === true) {
            return false;
        }
        if (fieldState.effectiveRequired === false) {
            return false;
        }
        return fieldState.required === true;
    }

    getRowFieldStateValue(rowFieldStates, fieldApiName) {
        if (!Array.isArray(rowFieldStates) || !this.hasValue(fieldApiName)) {
            return null;
        }
        const state = rowFieldStates.find((fieldState) => fieldState.fieldApiName === fieldApiName);
        return state ? state.value : null;
    }

    arePicklistOptionsEqual(first, second) {
        const firstOptions = Array.isArray(first) ? first : [];
        const secondOptions = Array.isArray(second) ? second : [];
        if (firstOptions.length !== secondOptions.length) {
            return false;
        }

        for (let index = 0; index < firstOptions.length; index += 1) {
            const firstOption = firstOptions[index];
            const secondOption = secondOptions[index];
            if (!firstOption || !secondOption) {
                return false;
            }
            if (firstOption.value !== secondOption.value || firstOption.label !== secondOption.label) {
                return false;
            }
        }
        return true;
    }

    normalizeAddressPicklistSelection(options, rawValue) {
        const normalizedRaw = this.hasValue(rawValue) ? String(rawValue).trim() : '';
        if (!this.hasValue(normalizedRaw)) {
            return '';
        }
        if (!Array.isArray(options) || options.length === 0) {
            return normalizedRaw;
        }

        const directMatch = options.find((option) => option.value === normalizedRaw);
        if (directMatch) {
            return directMatch.value;
        }

        const labelMatch = options.find(
            (option) => String(option.label).toLowerCase() === normalizedRaw.toLowerCase()
        );
        if (labelMatch) {
            return labelMatch.value;
        }

        return normalizedRaw;
    }

    toPicklistOptions(values) {
        return (values || []).map((v) => ({ label: v, value: v }));
    }

    normalizeAddressValue(rawAddress) {
        const source = rawAddress || {};
        return {
            street: source.street || '',
            city: source.city || '',
            province: source.province || '',
            postalCode: source.postalCode || '',
            country: source.country || ''
        };
    }

    hasCompleteAddressValue(fieldState) {
        if (!fieldState) {
            return false;
        }
        return this.hasValue(fieldState.street) &&
            this.hasValue(fieldState.city) &&
            this.hasValue(fieldState.province) &&
            this.hasValue(fieldState.postalCode) &&
            this.hasValue(fieldState.country);
    }

    hasValue(value) {
        return value !== undefined && value !== null && String(value).trim() !== '';
    }

    toBoolean(value) {
        if (value === true || value === false) {
            return value;
        }
        if (value === null || value === undefined || value === '') {
            return false;
        }
        return String(value).toLowerCase() === 'true';
    }

    /** Multi-select picklist values from ACR/Contact role fields (semicolon-separated). */
    rolePicklistTokenize(val) {
        if (val == null || val === '') return [];
        return String(val)
            .split(';')
            .map((s) => s.trim())
            .filter(Boolean);
    }

    rolePicklistIncludesPrincipalOwner(val) {
        return this.rolePicklistTokenize(val).includes('Principal Owner');
    }

    getRelationshipRoleValue(row) {
        const api = this.roleConstraints?.roleFieldApiName;
        if (!api || !row?.relationshipFieldStates) return null;
        const fs = row.relationshipFieldStates.find((x) => x.fieldApiName === api);
        return fs ? fs.value : null;
    }

    rowIndicatesPrincipalOwner(row) {
        if (this.rolePicklistIncludesPrincipalOwner(this.getRelationshipRoleValue(row))) {
            return true;
        }
        const contactRole = (row.fieldStates || []).find((fs) => fs.fieldApiName === 'Role');
        return this.rolePicklistIncludesPrincipalOwner(contactRole?.value);
    }

    getFilteredPicklistOptions(fieldConfig) {
        return this.getFilteredPicklistOptionsForRow(fieldConfig, null, -1);
    }

    getFilteredPicklistOptionsForRow(fieldConfig, currentRow, currentRowIndex) {
        const raw = (fieldConfig.picklistValues || []).map((v) => ({ label: v, value: v }));
        const rc = this.roleConstraints;
        let options = raw;

        if (rc && rc.requiresPermissionRoles && rc.requiresPermissionRoles.length > 0 && !this.canAssignAuthorizedSigner) {
            options = options.filter((opt) => !rc.requiresPermissionRoles.includes(opt.value));
        }

        if (rc && rc.singlePerAccountRoles && rc.singlePerAccountRoles.length > 0 && rc.roleFieldApiName &&
            fieldConfig.fieldApiName === rc.roleFieldApiName && this.rows && this.rows.length > 0) {
            const roleValsFrom = (val) => {
                if (val == null || val === '') return [];
                return String(val).split(';').map((s) => s.trim()).filter(Boolean);
            };
            const rolesTakenByOtherRows = new Set();
            this.rows.forEach((r, idx) => {
                if (idx === currentRowIndex) return;
                (r.relationshipFieldStates || []).forEach((fs) => {
                    if (fs.fieldApiName === rc.roleFieldApiName) {
                        roleValsFrom(fs.value).forEach((v) => {
                            if (rc.singlePerAccountRoles.includes(v)) rolesTakenByOtherRows.add(v);
                        });
                    }
                });
            });
            if (rolesTakenByOtherRows.size > 0) {
                const thisRowVal = currentRow?.relationshipFieldStates?.find((fs) => fs.fieldApiName === rc.roleFieldApiName)?.value;
                const thisRowRoles = new Set(roleValsFrom(thisRowVal));
                options = options.filter((opt) => {
                    if (!rolesTakenByOtherRows.has(opt.value)) return true;
                    return thisRowRoles.has(opt.value);
                });
            }
        }

        return options;
    }

    /**
     * CONTACT_ON_OPPORTUNITY: at most one Primary; if none checked but Role is Principal Owner, check Primary on that row.
     */
    normalizePrimaryContactSelection() {
        if (this.configKey !== 'CONTACT_ON_OPPORTUNITY' || !this.rows?.length) {
            return;
        }
        const indicesWithPrimary = [];
        this.rows.forEach((row, idx) => {
            const primaryFs = (row.fieldStates || []).find((fs) => fs.fieldApiName === 'IsPrimary');
            if (primaryFs && (primaryFs.checked === true || primaryFs.checked === 'true')) {
                indicesWithPrimary.push(idx);
            }
        });
        let keepIdx = indicesWithPrimary.length > 0 ? indicesWithPrimary[0] : -1;
        let rowsOut = this.rows.map((row, idx) => ({
            ...row,
            fieldStates: (row.fieldStates || []).map((fs) =>
                fs.fieldApiName === 'IsPrimary'
                    ? {
                          ...fs,
                          checked: keepIdx >= 0 ? idx === keepIdx : false,
                          errorMessage: null,
                          formElementClass: 'slds-form-element'
                      }
                    : fs
            )
        }));
        if (keepIdx < 0) {
            const poIdx = rowsOut.findIndex((row) => this.rowIndicatesPrincipalOwner(row));
            if (poIdx >= 0) {
                rowsOut = rowsOut.map((row, idx) => ({
                    ...row,
                    fieldStates: (row.fieldStates || []).map((fs) =>
                        fs.fieldApiName === 'IsPrimary'
                            ? { ...fs, checked: idx === poIdx, errorMessage: null, formElementClass: 'slds-form-element' }
                            : fs
                    )
                }));
            }
        }
        this.rows = rowsOut;
    }

    applyExclusivePrimaryContactRules(rowsCopy, clientId, fieldApiName, newFieldValue, isRelationship) {
        if (!rowsCopy?.length || this.configKey !== 'CONTACT_ON_OPPORTUNITY') {
            return;
        }

        const rc = this.roleConstraints;
        const isAcrRoleField =
            isRelationship === true && rc && rc.roleFieldApiName && fieldApiName === rc.roleFieldApiName;
        const isContactRoleField = !isRelationship && fieldApiName === 'Role';

        if (isRelationship && !isAcrRoleField) {
            return;
        }

        const setPrimaryChecked = (targetClientId, checked) => {
            const idx = rowsCopy.findIndex((r) => r.clientId === targetClientId);
            if (idx < 0) return;
            const row = rowsCopy[idx];
            rowsCopy[idx] = {
                ...row,
                fieldStates: (row.fieldStates || []).map((fs) =>
                    fs.fieldApiName === 'IsPrimary'
                        ? { ...fs, checked, errorMessage: null, formElementClass: 'slds-form-element' }
                        : fs
                )
            };
        };

        if (!isRelationship && fieldApiName === 'IsPrimary' && (newFieldValue === true || newFieldValue === 'true')) {
            rowsCopy.forEach((row) => {
                if (row.clientId !== clientId) {
                    setPrimaryChecked(row.clientId, false);
                }
            });
            return;
        }

        const poSelected =
            (isAcrRoleField || isContactRoleField) && this.rolePicklistIncludesPrincipalOwner(newFieldValue);
        if (poSelected) {
            rowsCopy.forEach((row) => {
                setPrimaryChecked(row.clientId, row.clientId === clientId);
            });
        }
    }

    refreshAllRolePicklistOptions() {
        const rc = this.roleConstraints;
        if (!rc || !rc.roleFieldApiName || !this.relationshipFieldConfigs.length) return;

        const roleFieldConfig = this.relationshipFieldConfigs.find((fc) => fc.fieldApiName === rc.roleFieldApiName);
        if (!roleFieldConfig) return;

        const rowsCopy = this.rows.map((row, rowIndex) => {
            const updatedRelStates = (row.relationshipFieldStates || []).map((fs) => {
                if (fs.fieldApiName !== rc.roleFieldApiName) return fs;
                const newOptions = this.getFilteredPicklistOptionsForRow(roleFieldConfig, row, rowIndex);
                return { ...fs, picklistOptions: newOptions };
            });
            return { ...row, relationshipFieldStates: updatedRelStates };
        });
        this.rows = rowsCopy;
    }

    runClientValidation() {
        if (this.isLoading || this._configLoadError) {
            const message =
                this.errorMessage ||
                'Configuration error: unable to load record editor settings.';
            return { isValid: false, errorMessage: message };
        }

        const errors = [];
        const rc = this.roleConstraints;
        const singlePerAccountRoles = (rc && rc.singlePerAccountRoles) ? rc.singlePerAccountRoles : [];
        const requiresPermissionRoles = (rc && rc.requiresPermissionRoles) ? rc.requiresPermissionRoles : [];
        const roleValsFrom = (val) => {
            if (val == null || val === '') return [];
            return String(val).split(';').map((s) => s.trim()).filter(Boolean);
        };
        const roleFieldApiName = (rc && rc.roleFieldApiName) ? rc.roleFieldApiName : null;
        const phoneValidationByKey = new Map();
        this.template.querySelectorAll('c-react-style-phone-input').forEach((inputCmp) => {
            const clientId = inputCmp?.dataset?.clientId;
            const fieldApiName = inputCmp?.dataset?.fieldApiName;
            if (!clientId || !fieldApiName) {
                return;
            }
            const validationResult = inputCmp.validate ? inputCmp.validate() : { isValid: true };
            phoneValidationByKey.set(
                `${clientId}|${fieldApiName}`,
                validationResult?.isValid !== false
            );
        });

        let duplicatePrincipalOwnerRows = [];
        let restrictedAuthorizedSignerRows = [];
        if (requiresPermissionRoles.length > 0 && !this.canAssignAuthorizedSigner) {
            restrictedAuthorizedSignerRows = this.rows.filter((r) =>
                (r.relationshipFieldStates || []).some((fs) =>
                    roleValsFrom(fs.value).some((v) => requiresPermissionRoles.includes(v))
                )
            );
            if (restrictedAuthorizedSignerRows.length > 0) {
                errors.push(labelAuthorizedSignerPermissionDenied);
            }
        }
        if (singlePerAccountRoles.length > 0) {
            for (const role of singlePerAccountRoles) {
                const rowsWithRole = this.rows.filter((r) =>
                    (r.relationshipFieldStates || []).some((fs) =>
                        roleValsFrom(fs.value).some((v) => v === role)
                    )
                );
                if (rowsWithRole.length > 1) {
                    errors.push(role === 'Principal Owner' ? labelPrincipalOwnerConflict : `Only one contact can have the "${role}" role per account.`);
                    duplicatePrincipalOwnerRows = rowsWithRole;
                }
            }
        }
        let updatedRows = this.rows.map((row, index) => {
            const updatedFieldStates = row.fieldStates.map((fieldState) => {
                const isRequired = this.isFieldRequiredForValidation(fieldState);
                const isBlank = fieldState.isAddress
                    ? (isRequired && !this.hasCompleteAddressValue(fieldState))
                    : fieldState.isCheckbox
                    ? (isRequired && (fieldState.checked !== true && fieldState.checked !== 'true'))
                    : (fieldState.value === null || fieldState.value === undefined || fieldState.value === '');
                let fieldErrorMessage = isRequired && isBlank
                    ? `${fieldState.label || fieldState.fieldApiName} is required.`
                    : null;
                if (!fieldErrorMessage && fieldState.isPhoneField) {
                    const phoneKey = `${row.clientId}|${fieldState.fieldApiName}`;
                    const phoneValid = phoneValidationByKey.has(phoneKey)
                        ? phoneValidationByKey.get(phoneKey)
                        : true;
                    if (!phoneValid) {
                        fieldErrorMessage = `${fieldState.label || fieldState.fieldApiName} is invalid.`;
                    }
                }
                if (fieldErrorMessage) errors.push(`Row ${index + 1}: ${fieldErrorMessage}`);
                return {
                    ...fieldState,
                    errorMessage: fieldErrorMessage,
                    formElementClass: fieldErrorMessage ? 'slds-form-element slds-has-error' : 'slds-form-element'
                };
            });

            const isDuplicatePrincipalOwnerRow = duplicatePrincipalOwnerRows.includes(row);
            const isRestrictedAuthorizedSignerRow = restrictedAuthorizedSignerRows.includes(row);
            const updatedRelStates = (row.relationshipFieldStates || []).map((fs) => {
                const isRequired = this.isFieldRequiredForValidation(fs);
                const isBlank = fs.isCheckbox
                    ? (isRequired && (fs.checked !== true && fs.checked !== 'true'))
                    : (fs.value === null || fs.value === undefined || fs.value === '');
                let fieldErrorMessage = isRequired && isBlank
                    ? `${fs.label || fs.fieldApiName} is required.`
                    : null;
                if (fieldErrorMessage) errors.push(`Row ${index + 1}: ${fs.label || fs.fieldApiName} is required.`);
                if (!fieldErrorMessage && roleFieldApiName && fs.fieldApiName === roleFieldApiName) {
                    if (isDuplicatePrincipalOwnerRow) fieldErrorMessage = labelPrincipalOwnerConflict;
                    else if (isRestrictedAuthorizedSignerRow) fieldErrorMessage = labelAuthorizedSignerPermissionDenied;
                }
                return {
                    ...fs,
                    errorMessage: fieldErrorMessage,
                    formElementClass: fieldErrorMessage ? 'slds-form-element slds-has-error' : 'slds-form-element'
                };
            });

            return { ...row, fieldStates: updatedFieldStates, relationshipFieldStates: updatedRelStates };
        });

        let primaryValidationMessage = null;
        if (this.configKey === 'CONTACT_ON_OPPORTUNITY') {
            let primaryCount = 0;
            updatedRows.forEach((row) => {
                const p = (row.fieldStates || []).find((fs) => fs.fieldApiName === 'IsPrimary');
                if (p && (p.checked === true || p.checked === 'true')) {
                    primaryCount += 1;
                }
            });
            if (primaryCount !== 1) {
                primaryValidationMessage = labelExactlyOnePrimaryContact;
                errors.push(primaryValidationMessage);
            }
        }

        if (primaryValidationMessage) {
            updatedRows = updatedRows.map((row) => ({
                ...row,
                fieldStates: (row.fieldStates || []).map((fs) => {
                    if (fs.fieldApiName !== 'IsPrimary') {
                        return fs;
                    }
                    const mergedMsg = primaryValidationMessage || fs.errorMessage;
                    return {
                        ...fs,
                        errorMessage: mergedMsg,
                        formElementClass: mergedMsg ? 'slds-form-element slds-has-error' : 'slds-form-element'
                    };
                })
            }));
        }

        this.rows = updatedRows;
        this.hasValidationError = errors.length > 0;

        if (errors.length) {
            this.errorMessage = labelFixFieldErrors;
            return { isValid: false, errorMessage: labelFixFieldErrors };
        }

        this.errorMessage = null;
        return { isValid: true };
    }

    @api
    validate() {
        this.syncOutputRecords();
        return this.runClientValidation();
    }

    @api
    getRecordsJson() {
        this.syncOutputRecords();
        return this.recordsToCreate;
    }

    @api
    hasRequiredValues() {
        if (this.isLoading || this._configLoadError || !Array.isArray(this.rows) || this.rows.length === 0) {
            return false;
        }

        return this.rows.every((row) => {
            const fieldsComplete = (row.fieldStates || []).every((fieldState) => {
                if (!this.isFieldRequiredForValidation(fieldState)) {
                    return true;
                }
                if (fieldState.isAddress) {
                    return this.hasCompleteAddressValue(fieldState);
                }
                if (fieldState.isCheckbox) {
                    return fieldState.checked === true || fieldState.checked === 'true';
                }
                return this.hasValue(fieldState.value);
            });
            if (!fieldsComplete) {
                return false;
            }

            return (row.relationshipFieldStates || []).every((fieldState) => {
                if (!this.isFieldRequiredForValidation(fieldState)) {
                    return true;
                }
                if (fieldState.isCheckbox) {
                    return fieldState.checked === true || fieldState.checked === 'true';
                }
                return this.hasValue(fieldState.value);
            });
        });
    }

    notifyStateChange() {
        this.dispatchEvent(new CustomEvent('statechange', {
            detail: {
                hasRequiredValues: this.hasRequiredValues(),
                recordsJson: this.recordsToCreate || '[]'
            },
            bubbles: true,
            composed: true
        }));
    }
}
