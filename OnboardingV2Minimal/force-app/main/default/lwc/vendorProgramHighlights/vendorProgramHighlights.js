import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import highlightStyles from '@salesforce/resourceUrl/highlightStyles';
import { loadStyle } from 'lightning/platformResourceLoader'; 

import STATUS_FIELD from '@salesforce/schema/Vendor_Customization__c.Status__c';
import VERSION_FIELD from '@salesforce/schema/Vendor_Customization__c.Version__c';
import ACTIVE_FIELD from '@salesforce/schema/Vendor_Customization__c.Active__c';

export default class VendorProgramHighlights extends LightningElement {
    @api recordId;

    record;
    error;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [STATUS_FIELD, VERSION_FIELD, ACTIVE_FIELD]
    })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    connectedCallback() {
        loadStyle(this, highlightStyles);
    }

    get status() {
        return this.record?.fields?.Status__c?.value;
    }

    get version() {
        return 'Version: ' + this.record?.fields?.Version__c?.value;
    }

    get isActive() {
        return this.record?.fields?.Active__c?.value ? 'Active' : 'Inactive';
    }
}
