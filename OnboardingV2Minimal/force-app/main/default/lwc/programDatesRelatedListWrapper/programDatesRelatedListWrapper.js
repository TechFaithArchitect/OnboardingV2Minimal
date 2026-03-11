import { LightningElement, api } from 'lwc';

/**
 * Wrapper component for Program Dates Related List
 * Mimics the standard "Related List - Single" component structure
 * which uses a parent wrapper to provide proper spacing context
 */
export default class ProgramDatesRelatedListWrapper extends LightningElement {
    @api recordId;
}

