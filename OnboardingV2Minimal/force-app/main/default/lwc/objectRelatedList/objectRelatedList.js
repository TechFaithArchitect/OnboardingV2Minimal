/**
 * Object Related List Component
 * 
 * A reusable component for displaying related records in a datatable format.
 * Accepts configuration via public properties for maximum flexibility.
 * 
 * Usage:
 * 1. Pass childObjectApiName to determine the related child object
 * 2. Pass columns array for datatable columns
 * 3. Pass parentFieldApiName to specify the lookup field
 * 4. Pass fieldApiNames array for fields to query
 * 5. Optionally pass relationshipFieldApiNames for related object fields
 * 6. Optionally pass childComponent name for the modal form
 * 7. Optionally pass rowTransform function name (handled in parent wrapper)
 */
import { LightningElement, api, wire } from 'lwc';
import getRelatedRecords from '@salesforce/apex/ObjectRelatedListController.getRelatedRecords';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

export default class ObjectRelatedList extends NavigationMixin(LightningElement) {
    static DEFAULT_NEW_ACTION_BEHAVIOR = 'auto';
    static NEW_ACTION_BEHAVIORS = ['auto', 'standard', 'modal', 'hidden'];
    static REFRESH_DEBOUNCE_MS = 200;

    /** Parent record ID (e.g., Account Id) */
    @api recordId;
    
    /** Parent record object API name (auto-provided by Lightning record pages). */
    @api objectApiName;

    /** Related child object API name to query (e.g., 'Program_Dates__c'). */
    @api childObjectApiName;
    
    /** Parent field API name that links to the parent record (e.g., 'Account__c') */
    @api parentFieldApiName;

    /** Optional field on current record whose Id value should be used as parentRecordId (example: Account__c) */
    @api parentRecordIdSourceFieldApiName;
    
    /** Array of field API names to query and display */
    @api fieldApiNames = [];

    /** Comma-separated field API names (App Builder friendly alternative to fieldApiNames array) */
    @api fieldApiNamesCsv;

    /** Array of relationship field API names (e.g., ['Vendor_Program__r.Label__c']) */
    @api relationshipFieldApiNames = [];

    /** Comma-separated relationship field API names (App Builder friendly alternative) */
    @api relationshipFieldApiNamesCsv;

    /** Array of column definitions for lightning-datatable */
    @api columns = [];

    /** JSON array of lightning-datatable columns (App Builder friendly alternative) */
    @api columnsJson;

    /** Comma-separated list of fields to auto-generate columns from */
    @api columnFieldApiNamesCsv;

    /** Optional field that should render as a clickable record link in auto-generated columns */
    @api linkFieldApiName;

    /** Field API name to use for ordering (e.g., 'Program_Date__c') */
    @api orderByField;
    
    /** Order direction: 'ASC' or 'DESC' (default: 'DESC') */
    @api orderDirection = 'DESC';
    
    /** Child component name for the modal form (e.g., 'programDatesScreenAction') */
    @api childComponent;

    /** Controls New button behavior: auto | standard | modal | hidden */
    @api newActionBehavior = ObjectRelatedList.DEFAULT_NEW_ACTION_BEHAVIOR;

    /** Comma-separated default field values for standard New action (Field__c=value) */
    @api defaultFieldValuesCsv;

    /** Modal title override (defaults to object label + 'New') */
    @api modalTitle;
    
    /** Object label override (defaults to object info label) */
    @api objectLabel;
    
    /** Custom text for the header title (defaults to object label + count) */
    @api headerTitleOverride;
    
    /** Custom text for item count label */
    @api itemCountLabelOverride;
    
    /** Relationship API name for navigation (e.g., 'Program_Dates__r') */
    @api relationshipApiName;
    
    /** Optional limit for number of records to query (defaults to 2000) */
    @api recordLimit;

    /** Controls whether auto-generated columns should be editable */
    @api enableInlineEdit;

    /** Comma-separated field API names that should always be read-only */
    @api readOnlyFieldApiNamesCsv;

    /** Comma-separated field API names rendered as read-only text (never checkbox/picklist editors) */
    @api readOnlyTreatAsTextFieldApiNamesCsv;

    /** Optional CSV filters to exclude rows in format FieldApiName=value */
    @api excludeRowsWhereCsv;

    /** Shows picklist fetch telemetry in header for runtime troubleshooting. */
    @api enablePicklistTelemetry;

    rows = [];
    draftValues = [];
    error;
    showNewModal = false;
    wiredResult;
    objectInfo;
    parentSourceRecord;
    picklistOptionsByFieldByRecordType = {};
    picklistRequestKeys = new Set();
    picklistRecordTypeQueue = [];
    picklistRecordTypeIdToLoad;
    picklistWireErrorDetected = false;
    lastLoadedAt;
    refreshHandlerId;
    recordTypeRefreshRequested = false;
    picklistTelemetry = {
        requestCount: 0,
        successCount: 0,
        fallbackEmptyCount: 0,
        fallbackErrorCount: 0,
        lastFieldApiName: '',
        lastRecordTypeId: '',
        lastOutcome: 'none',
        lastOptionCount: 0,
        lastError: ''
    };
    refreshInFlightPromise;
    refreshDebounceHandle;
    suppressNextPageRefresh = false;

    connectedCallback() {
        try {
            this.refreshHandlerId = registerRefreshHandler(this, this.handlePageRefresh.bind(this));
        } catch (e) {
            this.refreshHandlerId = undefined;
        }
    }

    disconnectedCallback() {
        if (this.refreshHandlerId) {
            unregisterRefreshHandler(this.refreshHandlerId);
            this.refreshHandlerId = undefined;
        }
        if (this.refreshDebounceHandle) {
            clearTimeout(this.refreshDebounceHandle);
            this.refreshDebounceHandle = undefined;
        }
    }

    handlePageRefresh() {
        if (this.suppressNextPageRefresh) {
            this.suppressNextPageRefresh = false;
            return Promise.resolve(true);
        }
        return this.refreshList()
            .then(() => true)
            .catch(() => false);
    }

    scheduleDebouncedRefresh() {
        if (this.refreshDebounceHandle) {
            clearTimeout(this.refreshDebounceHandle);
        }
        this.refreshDebounceHandle = setTimeout(() => {
            this.refreshDebounceHandle = undefined;
            this.refreshList().catch(() => {});
        }, ObjectRelatedList.REFRESH_DEBOUNCE_MS);
    }

    dispatchPageRefresh() {
        this.suppressNextPageRefresh = true;
        this.dispatchEvent(new RefreshEvent());
        setTimeout(() => {
            this.suppressNextPageRefresh = false;
        }, 0);
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$parentRecordSourceFields' })
    wiredParentSourceRecord({ data, error }) {
        if (data) {
            this.parentSourceRecord = data;
        } else if (error) {
            this.parentSourceRecord = undefined;
        }
    }

    /**
     * Builds query configuration for Apex controller.
     * Returns undefined if required properties are missing (prevents unnecessary wire calls).
     */
    get queryConfig() {
        const parentRecordId = this.effectiveParentRecordId;
        if (!this.targetObjectApiName || !this.parentFieldApiName || !parentRecordId || !this.resolvedFieldApiNames.length) {
            return undefined;
        }

        const fieldApiNames = [...this.resolvedFieldApiNames];
        const relationshipFieldApiNames = [...this.resolvedRelationshipFieldApiNames];

        this.rowExclusionRules.forEach((rule) => {
            if (!rule.fieldApiName) {
                return;
            }
            if (rule.fieldApiName.includes('.')) {
                if (!relationshipFieldApiNames.includes(rule.fieldApiName)) {
                    relationshipFieldApiNames.push(rule.fieldApiName);
                }
            } else if (!fieldApiNames.includes(rule.fieldApiName)) {
                fieldApiNames.push(rule.fieldApiName);
            }
        });

        if (this.objectHasRecordTypeId && !fieldApiNames.includes('RecordTypeId')) {
            fieldApiNames.push('RecordTypeId');
        }

        return {
            objectApiName: this.targetObjectApiName,
            parentFieldApiName: this.parentFieldApiName,
            parentRecordId,
            fieldApiNames,
            relationshipFieldApiNames,
            orderByField: this.orderByField,
            orderDirection: this.orderDirection || 'DESC',
            recordLimit: this.recordLimit
        };
    }

    get objectHasRecordTypeId() {
        return Object.prototype.hasOwnProperty.call(this.objectInfo?.fields || {}, 'RecordTypeId');
    }

    get rowExclusionRules() {
        return this.parseFieldValuePairsCsv(this.excludeRowsWhereCsv);
    }

    get parentRecordSourceFields() {
        const fieldPath = this.parentRecordIdSourceFieldPath;
        return fieldPath ? [fieldPath] : undefined;
    }

    get parentRecordIdSourceFieldPath() {
        const fieldApiName = (this.parentRecordIdSourceFieldApiName || '').trim();
        if (!fieldApiName || !this.objectApiName) {
            return undefined;
        }
        if (fieldApiName.includes('.')) {
            return fieldApiName;
        }
        return `${this.objectApiName}.${fieldApiName}`;
    }

    get effectiveParentRecordId() {
        if (!(this.parentRecordIdSourceFieldApiName || '').trim()) {
            return this.recordId;
        }
        return this.parentRecordIdFromSourceField;
    }

    get parentRecordIdFromSourceField() {
        const sourceFieldApiName = (this.parentRecordIdSourceFieldApiName || '').trim();
        if (!sourceFieldApiName || !this.parentSourceRecord?.fields) {
            return undefined;
        }
        const fieldToken = sourceFieldApiName.includes('.')
            ? sourceFieldApiName.split('.').pop()
            : sourceFieldApiName;
        return this.parentSourceRecord.fields?.[fieldToken]?.value;
    }

    get resolvedFieldApiNames() {
        const explicitFieldApiNames = this.normalizeStringList(this.fieldApiNames);
        if (explicitFieldApiNames.length) {
            return explicitFieldApiNames;
        }
        const configuredFieldApiNames = this.normalizeStringList(this.fieldApiNamesCsv);
        if (configuredFieldApiNames.length) {
            return configuredFieldApiNames;
        }
        return this.normalizeStringList(this.columnFieldApiNamesCsv);
    }

    get resolvedRelationshipFieldApiNames() {
        const explicitRelationshipFields = this.normalizeStringList(this.relationshipFieldApiNames);
        if (explicitRelationshipFields.length) {
            return explicitRelationshipFields;
        }
        return this.normalizeStringList(this.relationshipFieldApiNamesCsv);
    }

    get resolvedColumns() {
        if (Array.isArray(this.columns) && this.columns.length) {
            return this.columns;
        }

        const parsedColumns = this.parseColumnsJson();
        if (parsedColumns.length) {
            return parsedColumns;
        }

        return this.buildAutoColumns();
    }

    get resolvedColumnFieldApiNames() {
        const configuredColumns = this.normalizeStringList(this.columnFieldApiNamesCsv);
        if (configuredColumns.length) {
            return configuredColumns;
        }
        return this.resolvedFieldApiNames;
    }

    get effectiveNewActionBehavior() {
        const normalized = (this.newActionBehavior || ObjectRelatedList.DEFAULT_NEW_ACTION_BEHAVIOR)
            .toString()
            .trim()
            .toLowerCase();
        return ObjectRelatedList.NEW_ACTION_BEHAVIORS.includes(normalized)
            ? normalized
            : ObjectRelatedList.DEFAULT_NEW_ACTION_BEHAVIOR;
    }

    get showNewButton() {
        return this.effectiveNewActionBehavior !== 'hidden';
    }

    get useModalForNewAction() {
        if (this.effectiveNewActionBehavior === 'modal') {
            return true;
        }
        if (this.effectiveNewActionBehavior === 'standard' || this.effectiveNewActionBehavior === 'hidden') {
            return false;
        }
        return !!this.childComponent;
    }

    get canNavigateToRelationship() {
        return !!this.relationshipApiName && !!this.recordId;
    }

    get targetObjectApiName() {
        const configuredChild = (this.childObjectApiName || '').trim();
        if (configuredChild) {
            return configuredChild;
        }
        return undefined;
    }

    get shouldEnableInlineEdit() {
        return this.enableInlineEdit !== false;
    }

    get defaultRecordTypeId() {
        return this.objectInfo?.defaultRecordTypeId;
    }

    get readOnlyFieldApiNames() {
        return new Set(this.normalizeStringList(this.readOnlyFieldApiNamesCsv));
    }

    get readOnlyTreatAsTextFieldApiNames() {
        return new Set(this.normalizeStringList(this.readOnlyTreatAsTextFieldApiNamesCsv));
    }

    get editablePicklistFieldApiNames() {
        return this.resolvedColumnFieldApiNames.filter((fieldApiName) => {
            if (!fieldApiName || fieldApiName.includes('.')) {
                return false;
            }
            if (this.readOnlyTreatAsTextFieldApiNames.has(fieldApiName)) {
                return false;
            }
            const fieldInfo = this.getFieldInfo(fieldApiName);
            return fieldInfo?.dataType === 'Picklist' || fieldInfo?.dataType === 'MultiselectPicklist';
        });
    }

    get hasError() {
        return !!this.error || !!this.columnsJsonErrorMessage;
    }

    get displayError() {
        return [this.columnsJsonErrorMessage, this.error].filter((message) => !!message).join(' | ');
    }

    get showPicklistTelemetry() {
        return this.enablePicklistTelemetry !== false && this.editablePicklistFieldApiNames.length > 0;
    }

    get picklistTelemetryLabel() {
        const telemetry = this.picklistTelemetry;
        const lastField = telemetry.lastFieldApiName || '-';
        const lastRecordType = telemetry.lastRecordTypeId || '-';
        const errorSuffix = telemetry.lastError ? ` | err: ${telemetry.lastError}` : '';
        const wireErrorDetected = this.picklistWireErrorDetected ? 1 : 0;
        return `Picklist telemetry req:${telemetry.requestCount} ok:${telemetry.successCount} emptyFallback:${telemetry.fallbackEmptyCount} errorFallback:${telemetry.fallbackErrorCount} wireError:${wireErrorDetected} last:${telemetry.lastOutcome} ${lastField}@${lastRecordType} opts:${telemetry.lastOptionCount}${errorSuffix}`;
    }

    get columnsJsonErrorMessage() {
        if (typeof this.columnsJson !== 'string' || !this.columnsJson.trim()) {
            return undefined;
        }
        try {
            const parsedColumns = JSON.parse(this.columnsJson);
            return Array.isArray(parsedColumns)
                ? undefined
                : 'Column JSON must be an array. Falling back to auto-generated columns.';
        } catch (e) {
            return 'Column JSON is invalid. Falling back to auto-generated columns.';
        }
    }

    @wire(getObjectInfo, { objectApiName: '$childObjectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            const previousApiName = this.objectInfo?.apiName;
            if (previousApiName && previousApiName !== data.apiName) {
                this.picklistOptionsByFieldByRecordType = {};
                this.picklistRequestKeys.clear();
                this.picklistRecordTypeQueue = [];
                this.picklistRecordTypeIdToLoad = undefined;
                this.picklistWireErrorDetected = false;
                this.recordTypeRefreshRequested = false;
                this.resetPicklistTelemetry();
            }
            this.objectInfo = data;
            if (this.rows.length) {
                this.rows = this.decorateRowsWithPicklistOptions(this.rows);
                this.ensurePicklistOptionsLoadedForRows(this.rows);
                if (
                    this.objectHasRecordTypeId &&
                    !this.rowsIncludeRecordTypeId(this.rows) &&
                    !this.recordTypeRefreshRequested
                ) {
                    this.recordTypeRefreshRequested = true;
                    this.refreshList().catch(() => {});
                }
            }
        } else if (error) {
            // Safe to ignore; will fall back to default icon
            this.objectInfo = undefined;
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$childObjectApiName',
        recordTypeId: '$picklistRecordTypeIdToLoad'
    })
    wiredPicklistValuesByRecordType({ data, error }) {
        const recordTypeId = this.picklistRecordTypeIdToLoad;
        if (!recordTypeId) {
            return;
        }

        const requestKey = this.getPicklistRecordTypeRequestKey(recordTypeId);
        const picklistFields = this.editablePicklistFieldApiNames;
        if (!picklistFields.length) {
            this.completePicklistRecordTypeLoad(requestKey);
            return;
        }

        if (!data && !error) {
            return;
        }

        try {
            if (data) {
                picklistFields.forEach((fieldApiName) => {
                    if (!this.picklistOptionsByFieldByRecordType[fieldApiName]) {
                        this.picklistOptionsByFieldByRecordType[fieldApiName] = {};
                    }
                    const rawValues = data?.picklistFieldValues?.[fieldApiName]?.values || [];
                    const scopedOptions = this.normalizePicklistOptions(
                        rawValues.map((entry) => ({
                            label: entry.label || entry.value,
                            value: entry.value
                        }))
                    );
                    const finalOptions = this.hasNonEmptyOptions(scopedOptions)
                        ? scopedOptions
                        : this.getFieldPicklistFallbackOptions(fieldApiName);
                    this.picklistOptionsByFieldByRecordType[fieldApiName][recordTypeId] = finalOptions;
                    this.recordPicklistTelemetryOutcome({
                        fieldApiName,
                        recordTypeId,
                        outcome: this.hasNonEmptyOptions(scopedOptions) ? 'success' : 'fallback-empty',
                        optionCount: finalOptions.length
                    });
                });
            } else {
                const errorMessage = this.reduceErrors(error).join(', ');
                this.picklistWireErrorDetected = true;
                picklistFields.forEach((fieldApiName) => {
                    if (!this.picklistOptionsByFieldByRecordType[fieldApiName]) {
                        this.picklistOptionsByFieldByRecordType[fieldApiName] = {};
                    }
                    const fallbackOptions = this.getFieldPicklistFallbackOptions(fieldApiName);
                    this.picklistOptionsByFieldByRecordType[fieldApiName][recordTypeId] = fallbackOptions;
                    this.recordPicklistTelemetryOutcome({
                        fieldApiName,
                        recordTypeId,
                        outcome: 'fallback-error',
                        optionCount: fallbackOptions.length,
                        errorMessage
                    });
                });
            }
        } catch (unexpectedError) {
            const errorMessage = this.reduceErrors(unexpectedError).join(', ');
            this.picklistWireErrorDetected = true;
            picklistFields.forEach((fieldApiName) => {
                if (!this.picklistOptionsByFieldByRecordType[fieldApiName]) {
                    this.picklistOptionsByFieldByRecordType[fieldApiName] = {};
                }
                if (!this.hasNonEmptyOptions(this.picklistOptionsByFieldByRecordType[fieldApiName][recordTypeId])) {
                    this.picklistOptionsByFieldByRecordType[fieldApiName][recordTypeId] =
                        this.getFieldPicklistFallbackOptions(fieldApiName);
                }
                this.recordPicklistTelemetryOutcome({
                    fieldApiName,
                    recordTypeId,
                    outcome: 'fallback-error',
                    optionCount: this.picklistOptionsByFieldByRecordType[fieldApiName][recordTypeId]?.length || 0,
                    errorMessage
                });
            });
        } finally {
            this.rows = this.decorateRowsWithPicklistOptions(this.rows);
            this.completePicklistRecordTypeLoad(requestKey);
        }
    }

    @wire(getRelatedRecords, { config: '$queryConfig' })
    wiredRelatedRecords(value) {
        this.wiredResult = value;
        const { data, error } = value;
        if (data) {
            const transformedRows = this.applyRowExclusions(this.transformRows(data));
            if (this.rowsIncludeRecordTypeId(transformedRows)) {
                this.recordTypeRefreshRequested = false;
            }
            this.rows = this.decorateRowsWithPicklistOptions(transformedRows);
            this.ensurePicklistOptionsLoadedForRows(transformedRows);
            this.lastLoadedAt = new Date();
            this.error = undefined;
            this.draftValues = [];
        } else if (error) {
            this.rows = [];
            this.error = this.reduceErrors(error).join(', ');
        }
    }

    /**
     * Transforms raw query results into display rows.
     * Adds recordLink field for navigation.
     * @param {Array} data - Raw query results
     * @returns {Array} Transformed rows with recordLink
     */
    transformRows(data) {
        if (!Array.isArray(data)) {
            return [];
        }

        const relationshipPaths = new Set(
            [
                ...this.resolvedRelationshipFieldApiNames,
                ...this.resolvedFieldApiNames.filter((apiName) => apiName.includes('.')),
                ...this.resolvedColumnFieldApiNames.filter((apiName) => apiName.includes('.'))
            ].filter((path) => !!path)
        );

        return data.map((row) => {
            const transformedRow = {
                ...row,
                recordLink: `/${row.Id || ''}`
            };

            relationshipPaths.forEach((path) => {
                transformedRow[path] = this.getNestedValue(row, path);
            });

            return transformedRow;
        });
    }

    get hasRows() {
        return this.rows && this.rows.length > 0;
    }

    get recordCount() {
        return Array.isArray(this.rows) ? this.rows.length : 0;
    }

    get recordCountLabel() {
        return `(${this.recordCount})`;
    }

    get countLabel() {
        const count = this.recordCount;
        return `${count} record${count === 1 ? '' : 's'}`;
    }

    get headerTitle() {
        if (this.headerTitleOverride) {
            return this.headerTitleOverride.replace('{count}', this.recordCount);
        }
        const label = this.objectLabel || this.objectInfo?.label || this.targetObjectApiName || 'Records';
        return `${label} (${this.recordCount})`;
    }

    get itemCountLabel() {
        const count = this.recordCount;
        const parts = [`${count} item${count === 1 ? '' : 's'}`];
        if (this.orderByFieldLabel) {
            parts.push(`Sorted by ${this.orderByFieldLabel}`);
        }
        if (this.lastUpdatedRelativeLabel) {
            parts.push(`Updated ${this.lastUpdatedRelativeLabel}`);
        }
        const defaultLabel = parts.join(' • ');

        if (!this.itemCountLabelOverride) {
            return defaultLabel;
        }
        return this.interpolateItemCountLabel(this.itemCountLabelOverride, defaultLabel);
    }

    get orderByFieldLabel() {
        if (!this.orderByField) {
            return undefined;
        }
        const fieldInfo = this.getFieldInfo(this.orderByField);
        return fieldInfo?.label || this.formatFieldLabel(this.orderByField);
    }

    get lastUpdatedRelativeLabel() {
        const timestamps = this.rows
            .map((row) => row.LastModifiedDate)
            .filter((value) => !!value)
            .map((value) => new Date(value))
            .filter((value) => !Number.isNaN(value.getTime()));

        const referenceTime = timestamps.length
            ? new Date(Math.max(...timestamps.map((value) => value.getTime())))
            : this.lastLoadedAt;

        if (!referenceTime || Number.isNaN(referenceTime.getTime())) {
            return undefined;
        }
        return this.formatRelativeTime(referenceTime);
    }

    get displayModalTitle() {
        if (this.modalTitle) {
            return this.modalTitle;
        }
        const label = this.objectLabel || this.objectInfo?.label || 'Record';
        return `New ${label}`;
    }

    /**
     * Extracts icon name from object info theme.
     * Supports both standard and custom icon paths.
     */
    getObjectIconName(themeInfo) {
        if (!themeInfo?.iconUrl) {
            return 'standard:record';
        }
        
        const iconUrl = themeInfo.iconUrl;
        const standardMatch = iconUrl.match(/\/standard\/([^_/]+)/);
        if (standardMatch) {
            return `standard:${standardMatch[1]}`;
        }
        
        const customMatch = iconUrl.match(/\/custom\/([^_/]+)/);
        if (customMatch) {
            return `custom:${customMatch[1]}`;
        }
        
        return 'standard:record';
    }

    get objectIconName() {
        return this.getObjectIconName(this.objectInfo?.themeInfo);
    }

    get iconAlt() {
        return this.objectLabel || this.objectInfo?.label || this.targetObjectApiName || 'Records';
    }

    handleHeaderClick(event) {
        event.preventDefault();
        if (this.canNavigateToRelationship) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: this.recordId,
                    relationshipApiName: this.relationshipApiName,
                    objectApiName: this.objectApiName,
                    actionName: 'view'
                }
            });
        }
    }

    handleViewAll(event) {
        event.preventDefault();
        this.handleHeaderClick(event);
    }

    getPicklistOptionsFieldName(fieldApiName) {
        return `__picklistOptions_${fieldApiName.replace(/[^a-zA-Z0-9_]/g, '_')}`;
    }

    getPicklistOptionsForRowField(fieldApiName, recordTypeId, currentValue) {
        const fieldOptionsByRecordType = this.picklistOptionsByFieldByRecordType[fieldApiName] || {};
        const cachedOptions = recordTypeId ? (fieldOptionsByRecordType[recordTypeId] || []) : [];
        const options = this.hasNonEmptyOptions(cachedOptions) ? cachedOptions : [];
        const normalizedValue = currentValue === null || currentValue === undefined ? '' : String(currentValue);

        if (!normalizedValue) {
            return options;
        }

        const hasCurrentValue = options.some((option) => option.value === normalizedValue);
        if (hasCurrentValue) {
            return options;
        }

        return [{ label: normalizedValue, value: normalizedValue }, ...options];
    }

    getFieldPicklistFallbackOptions(fieldApiName) {
        const fieldInfo = this.getFieldInfo(fieldApiName);
        const picklistValues = Array.isArray(fieldInfo?.picklistValues) ? fieldInfo.picklistValues : [];
        return this.normalizePicklistOptions(
            picklistValues
            .filter((entry) => entry?.active !== false && entry?.value)
            .map((entry) => ({
                label: entry.label || entry.value,
                value: entry.value
            }))
        );
    }

    normalizePicklistOptions(options) {
        if (!Array.isArray(options) || !options.length) {
            return [];
        }
        const normalized = [];
        const seenValues = new Set();
        options.forEach((entry) => {
            const rawValue = entry?.value;
            if (rawValue === null || rawValue === undefined || rawValue === '') {
                return;
            }
            const value = String(rawValue);
            if (seenValues.has(value)) {
                return;
            }
            seenValues.add(value);
            const label = entry?.label ? String(entry.label) : value;
            normalized.push({ label, value });
        });
        return normalized;
    }

    hasNonEmptyOptions(options) {
        return Array.isArray(options) && options.length > 0;
    }

    getPicklistRecordTypeRequestKey(recordTypeId) {
        return `${this.targetObjectApiName || '-'}|${recordTypeId || '-'}`;
    }

    hasAllFieldOptionsForRecordType(recordTypeId, fieldApiNames) {
        if (!recordTypeId || !Array.isArray(fieldApiNames) || !fieldApiNames.length) {
            return true;
        }
        return fieldApiNames.every((fieldApiName) => {
            const options = this.picklistOptionsByFieldByRecordType?.[fieldApiName]?.[recordTypeId];
            return this.hasNonEmptyOptions(options);
        });
    }

    enqueuePicklistRecordTypeLoad(recordTypeId, fieldApiNames) {
        if (!recordTypeId || this.hasAllFieldOptionsForRecordType(recordTypeId, fieldApiNames)) {
            return;
        }
        const requestKey = this.getPicklistRecordTypeRequestKey(recordTypeId);
        if (this.picklistRequestKeys.has(requestKey)) {
            return;
        }
        if (this.picklistRecordTypeIdToLoad === recordTypeId) {
            return;
        }
        if (this.picklistRecordTypeQueue.includes(recordTypeId)) {
            return;
        }

        this.picklistRecordTypeQueue = [...this.picklistRecordTypeQueue, recordTypeId];
        this.processPicklistRecordTypeQueue();
    }

    processPicklistRecordTypeQueue() {
        if (this.picklistRecordTypeIdToLoad || !this.picklistRecordTypeQueue.length) {
            return;
        }

        const nextRecordTypeId = this.picklistRecordTypeQueue[0];
        this.picklistRecordTypeQueue = this.picklistRecordTypeQueue.slice(1);
        this.picklistRecordTypeIdToLoad = nextRecordTypeId;

        const requestKey = this.getPicklistRecordTypeRequestKey(nextRecordTypeId);
        this.picklistRequestKeys.add(requestKey);
        this.editablePicklistFieldApiNames.forEach((fieldApiName) => {
            this.recordPicklistTelemetryStart(fieldApiName, nextRecordTypeId);
        });
    }

    completePicklistRecordTypeLoad(requestKey) {
        if (requestKey) {
            this.picklistRequestKeys.delete(requestKey);
        }
        this.picklistRecordTypeIdToLoad = undefined;
        this.processPicklistRecordTypeQueue();
    }

    rowsIncludeRecordTypeId(rows) {
        if (!Array.isArray(rows) || !rows.length) {
            return false;
        }
        return rows.some((row) => !!row?.RecordTypeId);
    }

    resetPicklistTelemetry() {
        this.picklistTelemetry = {
            requestCount: 0,
            successCount: 0,
            fallbackEmptyCount: 0,
            fallbackErrorCount: 0,
            lastFieldApiName: '',
            lastRecordTypeId: '',
            lastOutcome: 'none',
            lastOptionCount: 0,
            lastError: ''
        };
    }

    recordPicklistTelemetryStart(fieldApiName, recordTypeId) {
        this.picklistTelemetry = {
            ...this.picklistTelemetry,
            requestCount: (this.picklistTelemetry.requestCount || 0) + 1,
            lastFieldApiName: fieldApiName || '',
            lastRecordTypeId: recordTypeId || '',
            lastOutcome: 'request',
            lastOptionCount: 0,
            lastError: ''
        };

        // eslint-disable-next-line no-console
        console.info(
            `[objectRelatedList][picklist] request field=${fieldApiName || '-'} recordTypeId=${recordTypeId || '-'}`
        );
    }

    recordPicklistTelemetryOutcome({ fieldApiName, recordTypeId, outcome, optionCount, errorMessage }) {
        const nextTelemetry = {
            ...this.picklistTelemetry,
            lastFieldApiName: fieldApiName || '',
            lastRecordTypeId: recordTypeId || '',
            lastOutcome: outcome || 'unknown',
            lastOptionCount: Number.isFinite(optionCount) ? optionCount : 0,
            lastError: errorMessage || ''
        };

        if (outcome === 'success') {
            nextTelemetry.successCount = (nextTelemetry.successCount || 0) + 1;
        } else if (outcome === 'fallback-empty') {
            nextTelemetry.fallbackEmptyCount = (nextTelemetry.fallbackEmptyCount || 0) + 1;
        } else if (outcome === 'fallback-error') {
            nextTelemetry.fallbackErrorCount = (nextTelemetry.fallbackErrorCount || 0) + 1;
        }

        this.picklistTelemetry = nextTelemetry;

        const logMessage =
            `[objectRelatedList][picklist] ${outcome || 'unknown'} ` +
            `field=${fieldApiName || '-'} recordTypeId=${recordTypeId || '-'} options=${nextTelemetry.lastOptionCount}` +
            (errorMessage ? ` error=${errorMessage}` : '');
        if (outcome === 'fallback-error') {
            // eslint-disable-next-line no-console
            console.warn(logMessage);
        } else {
            // eslint-disable-next-line no-console
            console.info(logMessage);
        }
    }

    decorateRowsWithPicklistOptions(rows) {
        if (!Array.isArray(rows) || !rows.length) {
            return Array.isArray(rows) ? rows : [];
        }

        const picklistFields = this.editablePicklistFieldApiNames;
        if (!picklistFields.length) {
            return rows;
        }

        return rows.map((row) => {
            const decoratedRow = { ...row };
            const recordTypeId = row.RecordTypeId || this.defaultRecordTypeId;
            picklistFields.forEach((fieldApiName) => {
                decoratedRow[this.getPicklistOptionsFieldName(fieldApiName)] = this.getPicklistOptionsForRowField(
                    fieldApiName,
                    recordTypeId,
                    row[fieldApiName]
                );
            });
            return decoratedRow;
        });
    }

    ensurePicklistOptionsLoadedForRows(rows) {
        if (!Array.isArray(rows) || !rows.length || !this.targetObjectApiName) {
            return;
        }

        const picklistFields = this.editablePicklistFieldApiNames;
        if (!picklistFields.length) {
            return;
        }

        const recordTypeIds = new Set();
        let rowMissingRecordType = false;
        rows.forEach((row) => {
            if (row.RecordTypeId) {
                recordTypeIds.add(row.RecordTypeId);
            } else {
                rowMissingRecordType = true;
            }
        });
        if (this.defaultRecordTypeId && (rowMissingRecordType || !recordTypeIds.size)) {
            recordTypeIds.add(this.defaultRecordTypeId);
        }

        picklistFields.forEach((fieldApiName) => {
            if (!this.picklistOptionsByFieldByRecordType[fieldApiName]) {
                this.picklistOptionsByFieldByRecordType[fieldApiName] = {};
            }
        });

        recordTypeIds.forEach((recordTypeId) => {
            this.enqueuePicklistRecordTypeLoad(recordTypeId, picklistFields);
        });

        this.processPicklistRecordTypeQueue();
    }

    handleRefresh() {
        this.scheduleDebouncedRefresh();
    }

    /**
     * Handles inline editing save from datatable.
     * Updates multiple records in batch.
     * @param {CustomEvent} event - Event with draftValues array
     */
    handleInlineSave(event) {
        const drafts = event.detail?.draftValues;
        if (!Array.isArray(drafts) || drafts.length === 0) {
            return;
        }

        const recordInputs = drafts.map((draft) => ({ fields: { ...draft } }));

        Promise.all(recordInputs.map((recordInput) => updateRecord(recordInput)))
            .then(() => {
                this.showToast('Success', 'Records updated', 'success');
                this.draftValues = [];
                return this.refreshList();
            })
            .then(() => {
                this.dispatchPageRefresh();
            })
            .catch((error) => {
                this.showToast('Error updating records', this.reduceErrors(error).join(', '), 'error');
            });
    }

    handleNew() {
        if (this.useModalForNewAction && this.childComponent) {
            this.showNewModal = true;
            return;
        }

        if (this.useModalForNewAction && !this.childComponent) {
            this.showToast(
                'Configuration warning',
                'No child component configured. Opening the standard New page instead.',
                'warning'
            );
        }

        this.navigateToNewRecord();
    }

    handleModalClose() {
        this.showNewModal = false;
    }

    handleRecordCreated() {
        this.showNewModal = false;
        const label = this.objectLabel || this.objectInfo?.label || 'Record';
        this.showToast('Success', `${label} record created.`, 'success');
        this.refreshList().then(() => {
            this.dispatchPageRefresh();
        });
    }

    // Constants for row actions
    static ROW_ACTIONS = {
        VIEW: 'view',
        EDIT: 'edit',
        DELETE: 'delete'
    };

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case ObjectRelatedList.ROW_ACTIONS.VIEW:
                this.navigateToRecord(row.Id, 'view');
                break;
            case ObjectRelatedList.ROW_ACTIONS.EDIT:
                this.navigateToRecord(row.Id, 'edit');
                break;
            case ObjectRelatedList.ROW_ACTIONS.DELETE:
                this.deleteRow(row.Id);
                break;
            default:
                break;
        }
    }

    navigateToRecord(recordId, actionName) {
        if (!recordId || !this.targetObjectApiName) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: this.targetObjectApiName,
                actionName
            }
        });
    }

    deleteRow(recordId) {
        if (!recordId) {
            return;
        }
        deleteRecord(recordId)
            .then(() => {
                const label = this.objectLabel || this.objectInfo?.label || 'Record';
                this.showToast('Deleted', `${label} record deleted.`, 'success');
                return this.refreshList();
            })
            .then(() => {
                this.dispatchPageRefresh();
            })
            .catch((error) => {
                this.showToast('Error deleting record', this.reduceErrors(error).join(', '), 'error');
            });
    }

    refreshList() {
        if (!this.wiredResult) {
            return Promise.resolve();
        }
        if (this.refreshInFlightPromise) {
            return this.refreshInFlightPromise;
        }
        this.refreshInFlightPromise = Promise.resolve(refreshApex(this.wiredResult)).finally(() => {
            this.refreshInFlightPromise = undefined;
        });
        return this.refreshInFlightPromise;
    }

    navigateToNewRecord() {
        if (!this.targetObjectApiName) {
            return;
        }

        const defaultFieldValues = this.buildDefaultFieldValues();
        const pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.targetObjectApiName,
                actionName: 'new'
            }
        };

        if (Object.keys(defaultFieldValues).length) {
            pageReference.state = {
                defaultFieldValues: encodeDefaultFieldValues(defaultFieldValues)
            };
        }

        this[NavigationMixin.Navigate](pageReference);
    }

    buildDefaultFieldValues() {
        const defaults = this.parseDefaultFieldValuesCsv(this.defaultFieldValuesCsv);
        if (this.parentFieldApiName && this.effectiveParentRecordId) {
            defaults[this.parentFieldApiName] = this.effectiveParentRecordId;
        }
        return defaults;
    }

    parseDefaultFieldValuesCsv(csvValue) {
        const defaults = {};
        if (typeof csvValue !== 'string' || !csvValue.trim()) {
            return defaults;
        }

        csvValue
            .split(',')
            .map((pair) => pair.trim())
            .filter((pair) => !!pair)
            .forEach((pair) => {
                const separatorIndex = pair.indexOf('=');
                if (separatorIndex <= 0) {
                    return;
                }
                const fieldName = pair.substring(0, separatorIndex).trim();
                const fieldValue = pair.substring(separatorIndex + 1).trim();
                if (fieldName) {
                    defaults[fieldName] = fieldValue;
                }
            });

        return defaults;
    }

    parseFieldValuePairsCsv(csvValue) {
        const pairs = [];
        if (typeof csvValue !== 'string' || !csvValue.trim()) {
            return pairs;
        }

        csvValue
            .split(',')
            .map((entry) => entry.trim())
            .filter((entry) => !!entry)
            .forEach((entry) => {
                const separatorIndex = entry.indexOf('=');
                if (separatorIndex <= 0) {
                    return;
                }
                const fieldApiName = entry.substring(0, separatorIndex).trim();
                const fieldValue = entry.substring(separatorIndex + 1).trim();
                if (!fieldApiName) {
                    return;
                }
                pairs.push({
                    fieldApiName,
                    fieldValue
                });
            });

        return pairs;
    }

    applyRowExclusions(rows) {
        if (!Array.isArray(rows) || !rows.length || !this.rowExclusionRules.length) {
            return rows;
        }

        return rows.filter((row) => !this.matchesAnyExclusionRule(row));
    }

    matchesAnyExclusionRule(row) {
        return this.rowExclusionRules.some((rule) => this.rowMatchesExclusionRule(row, rule));
    }

    rowMatchesExclusionRule(row, rule) {
        if (!row || !rule?.fieldApiName) {
            return false;
        }

        const rawValue = rule.fieldApiName.includes('.')
            ? this.getNestedValue(row, rule.fieldApiName)
            : row[rule.fieldApiName];

        return this.normalizeComparableValue(rawValue) === this.normalizeComparableValue(rule.fieldValue);
    }

    normalizeComparableValue(value) {
        if (value === null || value === undefined) {
            return '';
        }
        return String(value).trim().toLowerCase();
    }

    normalizeStringList(rawValue) {
        if (Array.isArray(rawValue)) {
            return rawValue
                .filter((entry) => typeof entry === 'string')
                .map((entry) => entry.trim())
                .filter((entry) => !!entry);
        }

        if (typeof rawValue === 'string') {
            return rawValue
                .split(',')
                .map((entry) => entry.trim())
                .filter((entry) => !!entry);
        }

        return [];
    }

    parseColumnsJson() {
        if (typeof this.columnsJson !== 'string' || !this.columnsJson.trim()) {
            return [];
        }

        try {
            const parsedColumns = JSON.parse(this.columnsJson);
            return Array.isArray(parsedColumns) ? parsedColumns : [];
        } catch (e) {
            return [];
        }
    }

    buildAutoColumns() {
        return this.resolvedColumnFieldApiNames.map((fieldApiName) => {
            const isLinkField = this.linkFieldApiName && fieldApiName === this.linkFieldApiName;
            const fieldInfo = this.getFieldInfo(fieldApiName);
            const label = fieldInfo?.label || this.formatFieldLabel(fieldApiName);
            const isExplicitReadOnly = this.readOnlyFieldApiNames.has(fieldApiName);
            const treatAsText = this.readOnlyTreatAsTextFieldApiNames.has(fieldApiName);

            if (isLinkField) {
                return {
                    label,
                    fieldName: 'recordLink',
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: fieldApiName },
                        target: '_self'
                    },
                    wrapText: true
                };
            }

            const type = this.getDatatableType(fieldInfo?.dataType);
            const isPicklistField = fieldInfo?.dataType === 'Picklist' || fieldInfo?.dataType === 'MultiselectPicklist';
            if (isPicklistField && !treatAsText) {
                const isEditablePicklist = this.shouldEnableInlineEdit && fieldInfo?.updateable && !isExplicitReadOnly;
                return {
                    label,
                    fieldName: fieldApiName,
                    type: 'picklistInline',
                    editable: isEditablePicklist,
                    typeAttributes: {
                        options: { fieldName: this.getPicklistOptionsFieldName(fieldApiName) },
                        placeholder: `Select ${label}`
                    }
                };
            }

            const column = {
                label,
                fieldName: fieldApiName,
                type: treatAsText ? 'text' : type
            };
            if (
                this.shouldEnableInlineEdit &&
                !fieldApiName.includes('.') &&
                fieldInfo?.updateable &&
                !isExplicitReadOnly &&
                !treatAsText
            ) {
                column.editable = true;
            }

            return column;
        });
    }

    getFieldInfo(fieldApiName) {
        if (!fieldApiName || fieldApiName.includes('.')) {
            return undefined;
        }
        return this.objectInfo?.fields?.[fieldApiName];
    }

    getDatatableType(dataType) {
        switch (dataType) {
            case 'Boolean':
                return 'boolean';
            case 'Currency':
                return 'currency';
            case 'Date':
            case 'DateTime':
                return 'date';
            case 'Double':
            case 'Integer':
            case 'Long':
                return 'number';
            case 'Percent':
                return 'percent';
            case 'Email':
                return 'email';
            case 'Phone':
                return 'phone';
            case 'Url':
                return 'url';
            default:
                return 'text';
        }
    }

    formatFieldLabel(fieldApiName) {
        const token = (fieldApiName || '').split('.').pop() || fieldApiName || 'Field';
        const cleanToken = token.replace(/__(c|r)$/i, '');
        return cleanToken
            .split('_')
            .filter((word) => !!word)
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    getNestedValue(record, path) {
        if (!record || !path) {
            return undefined;
        }

        return path.split('.').reduce((value, segment) => {
            if (value === null || value === undefined) {
                return undefined;
            }
            return value[segment];
        }, record);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceErrors(errors) {
        if (!errors) {
            return ['Unknown error'];
        }
        if (Array.isArray(errors)) {
            return errors.flatMap((error) => this.reduceErrors(error));
        }
        if (errors.body && Array.isArray(errors.body.pageErrors) && errors.body.pageErrors.length) {
            return errors.body.pageErrors.map((error) => error.message);
        }
        if (errors.body && errors.body.message) {
            return [errors.body.message];
        }
        if (typeof errors.message === 'string') {
            return [errors.message];
        }
        return ['Unknown error'];
    }

    interpolateItemCountLabel(template, defaultLabel) {
        if (typeof template !== 'string' || !template.trim()) {
            return defaultLabel;
        }

        const count = this.recordCount;
        const countLabel = `${count} item${count === 1 ? '' : 's'}`;
        const sortLabel = this.orderByFieldLabel ? `Sorted by ${this.orderByFieldLabel}` : '';
        const updatedLabel = this.lastUpdatedRelativeLabel ? `Updated ${this.lastUpdatedRelativeLabel}` : '';

        let resolved = template;
        resolved = resolved.replace(/\{count\}/gi, String(count));
        resolved = resolved.replace(/\{itemcount\}/gi, countLabel);
        resolved = resolved.replace(/\{items\}/gi, countLabel);
        resolved = resolved.replace(/\{sort\}/gi, sortLabel);
        resolved = resolved.replace(/\{sorted by\}/gi, sortLabel);
        resolved = resolved.replace(/\{last updated\}/gi, updatedLabel);
        resolved = resolved.replace(/\{lastupdated\}/gi, updatedLabel);
        resolved = resolved.replace(/\{updated\}/gi, updatedLabel);

        if (/\{[^}]+\}/.test(resolved)) {
            return defaultLabel;
        }

        const normalized = resolved.replace(/\s+•\s+•/g, ' • ').trim();
        return normalized || defaultLabel;
    }

    formatRelativeTime(dateValue) {
        const deltaSeconds = Math.max(0, Math.floor((Date.now() - dateValue.getTime()) / 1000));
        if (deltaSeconds < 45) {
            return 'a few seconds ago';
        }
        if (deltaSeconds < 90) {
            return 'a minute ago';
        }
        const deltaMinutes = Math.floor(deltaSeconds / 60);
        if (deltaMinutes < 60) {
            return `${deltaMinutes} minutes ago`;
        }
        const deltaHours = Math.floor(deltaMinutes / 60);
        if (deltaHours < 24) {
            return `${deltaHours} hour${deltaHours === 1 ? '' : 's'} ago`;
        }
        const deltaDays = Math.floor(deltaHours / 24);
        return `${deltaDays} day${deltaDays === 1 ? '' : 's'} ago`;
    }
}
