import { LightningElement, api, track, wire } from 'lwc';
import getConfig from '@salesforce/apex/RecordCollectionEditorConfigService.getConfig';
import labelPrincipalOwnerConflict from '@salesforce/label/c.Principal_Owner_Conflict';
import labelAuthorizedSignerPermissionDenied from '@salesforce/label/c.RecordCollectionEditor_AuthorizedSignerPermissionDenied';
import labelFixFieldErrors from '@salesforce/label/c.RecordCollectionEditor_FixFieldErrors';

export default class RecordCollectionEditor extends LightningElement {
    @api heading = 'Records';
    @api recordLabel = 'Row';
    @api configKey;
    @api parentId;
    @api existingRecordsJson;
    @api minRows = 1;
    @api maxRows;

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

    _configLoadError;

    @wire(getConfig, { developerName: '$configKey' })
    wiredConfig(configWireResult) {
        const { error: configLoadError, data: configData } = configWireResult;

        if (configData) {
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
                if (this.existingRecordsJson && this.existingRecordsJson.trim()) {
                    this.populateRowsFromExisting();
                } else {
                    this.initializeRows();
                }
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
        this.rows = records.map((rec, idx) => {
            const childData = rec.child || rec;
            const relData = rec.relationship || {};
            const recordId = childData.Id || null;

            const fieldStates = this.fieldConfigs.map((fc) => {
                const dataType = fc.dataType || 'text';
                const isPhoneField = dataType === 'tel' || dataType === 'phone';
                const isCheckbox = dataType === 'checkbox';
                const isPicklist = dataType === 'picklist' || (fc.picklistValues && fc.picklistValues.length > 0);
                const isLookup = dataType === 'lookup';
                const columnSize = fc.columnSize || '1-of-2';
                const columnClass =
                    columnSize === '1-of-4' || columnSize === 'quarter'
                        ? 'slds-col slds-size_1-of-1 slds-small-size_1-of-2 slds-medium-size_1-of-4 slds-p-right_small slds-p-bottom_small'
                        : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
                const val = childData[fc.fieldApiName];
                return {
                    fieldApiName: fc.fieldApiName,
                    label: fc.label,
                    dataType,
                    required: fc.required,
                    readOnly: fc.readOnly === true,
                    isPhoneField,
                    isCheckbox,
                    isPicklist,
                    isLookup,
                    isTextOrDateInput: !isPhoneField && !isCheckbox && !isPicklist && !isLookup,
                    picklistOptions: isPicklist ? this.toPicklistOptions(fc.picklistValues) : [],
                    lookupObjectApiName: fc.lookupObjectApiName,
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
                    readOnly: fc.readOnly === true,
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
                subheading: `${label} ${idx + 1}`,
                fieldStates,
                relationshipFieldStates
            };
        });
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
            const isPhoneField = dataType === 'tel' || dataType === 'phone';
            const isCheckbox = dataType === 'checkbox';
            const isPicklist = dataType === 'picklist' || (fieldConfig.picklistValues && fieldConfig.picklistValues.length > 0);
            const isLookup = dataType === 'lookup';
            const columnSize = fieldConfig.columnSize || '1-of-2';
            const columnClass =
                columnSize === '1-of-4' || columnSize === 'quarter'
                    ? 'slds-col slds-size_1-of-1 slds-small-size_1-of-2 slds-medium-size_1-of-4 slds-p-right_small slds-p-bottom_small'
                    : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
            return {
                fieldApiName: fieldConfig.fieldApiName,
                label: fieldConfig.label,
                dataType,
                required: fieldConfig.required,
                readOnly: fieldConfig.readOnly === true,
                isPhoneField,
                isCheckbox,
                isPicklist,
                isLookup,
                isTextOrDateInput: !isPhoneField && !isCheckbox && !isPicklist && !isLookup,
                picklistOptions: isPicklist ? this.toPicklistOptions(fieldConfig.picklistValues) : [],
                lookupObjectApiName: fieldConfig.lookupObjectApiName,
                columnClass,
                value: null,
                checked: isCheckbox ? false : undefined,
                errorMessage: null,
                formElementClass: 'slds-form-element'
            };
        });

        const relColumnClass = 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-right_small slds-p-bottom_small';
        const newRow = { relationshipFieldStates: [] };
        const relationshipFieldStatesForRow = this.relationshipFieldConfigs.map((fieldConfig) => {
            const isPicklist = fieldConfig.dataType === 'picklist' || (fieldConfig.picklistValues && fieldConfig.picklistValues.length > 0);
            const isCheckbox = fieldConfig.dataType === 'checkbox';
            const isLookup = fieldConfig.dataType === 'lookup';
            return {
                fieldApiName: fieldConfig.fieldApiName,
                label: fieldConfig.label,
                dataType: fieldConfig.dataType || 'text',
                required: fieldConfig.required,
                readOnly: fieldConfig.readOnly === true,
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
        newRow.relationshipFieldStates = relationshipFieldStatesForRow;

        const label = (this.recordLabel || 'Row').trim();
        this.rows = [
            ...this.rows,
            {
                clientId: `row-${rowIndex}-${Date.now()}`,
                recordId,
                subheading: `${label} ${rowIndex + 1}`,
                fieldStates: fieldStatesForRow,
                relationshipFieldStates: relationshipFieldStatesForRow
            }
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
        let newFieldValue;
        if (event.detail && Object.prototype.hasOwnProperty.call(event.detail, 'recordId')) {
            newFieldValue = event.detail.recordId;
        } else if (event.detail && Object.prototype.hasOwnProperty.call(event.detail, 'checked')) {
            newFieldValue = event.detail.checked;
        } else {
            newFieldValue = event.detail?.value;
        }

        if (!clientId || !fieldApiName) {
            return;
        }

        const rowsCopy = this.rows.map((row) => {
            if (row.clientId !== clientId) return row;
            if (isRelationship) {
                const updatedRelStates = (row.relationshipFieldStates || []).map((fs) => {
                    if (fs.fieldApiName !== fieldApiName) return fs;
                    const updated = { ...fs, value: newFieldValue, errorMessage: null, formElementClass: 'slds-form-element' };
                    if (fs.isCheckbox) updated.checked = newFieldValue;
                    return updated;
                });
                return { ...row, relationshipFieldStates: updatedRelStates };
            }
            const updatedFieldStates = row.fieldStates.map((fieldState) => {
                if (fieldState.fieldApiName !== fieldApiName) return fieldState;
                const updated = { ...fieldState, value: newFieldValue, errorMessage: null, formElementClass: 'slds-form-element' };
                if (fieldState.isCheckbox) updated.checked = newFieldValue;
                return updated;
            });
            return { ...row, fieldStates: updatedFieldStates };
        });

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
    }

    get showAddRowButton() {
        if (!this.maxRows) {
            return true;
        }
        return this.rows.length < this.maxRows;
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

    toPicklistOptions(values) {
        return (values || []).map((v) => ({ label: v, value: v }));
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
        const updatedRows = this.rows.map((row, index) => {
            const updatedFieldStates = row.fieldStates.map((fieldState) => {
                const isBlank = fieldState.isCheckbox
                    ? (fieldState.required && (fieldState.checked !== true && fieldState.checked !== 'true'))
                    : (fieldState.value === null || fieldState.value === undefined || fieldState.value === '');
                const fieldErrorMessage = fieldState.required && isBlank
                    ? `${fieldState.label || fieldState.fieldApiName} is required.`
                    : null;
                if (fieldErrorMessage) errors.push(`Row ${index + 1}: ${fieldState.label || fieldState.fieldApiName} is required.`);
                return {
                    ...fieldState,
                    errorMessage: fieldErrorMessage,
                    formElementClass: fieldErrorMessage ? 'slds-form-element slds-has-error' : 'slds-form-element'
                };
            });

            const isDuplicatePrincipalOwnerRow = duplicatePrincipalOwnerRows.includes(row);
            const isRestrictedAuthorizedSignerRow = restrictedAuthorizedSignerRows.includes(row);
            const updatedRelStates = (row.relationshipFieldStates || []).map((fs) => {
                const isBlank = fs.isCheckbox
                    ? (fs.required && (fs.checked !== true && fs.checked !== 'true'))
                    : (fs.value === null || fs.value === undefined || fs.value === '');
                let fieldErrorMessage = fs.required && isBlank
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
}
