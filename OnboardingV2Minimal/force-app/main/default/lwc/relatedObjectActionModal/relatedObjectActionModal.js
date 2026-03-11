/**
 * Generic Reusable Modal Wrapper Component
 * 
 * This component provides a standardized modal structure for creating related records.
 * It handles the modal chrome (header, footer, close button) while delegating form
 * content to child components.
 * 
 * Architecture: Parent-Child Pattern
 * - Parent (this component): Modal structure and coordination
 * - Child (e.g., programDatesScreenAction): Form fields and business logic
 */
import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RelatedObjectActionModal extends LightningElement {
    /** Parent record ID passed from related list or action (e.g., Account Id) */
    @api recordId;
    
    /** Object API name for automatic title generation */
    @api objectApiName;
    
    /** Which child component to render (default: programDatesScreenAction) */
    @api childComponent = 'programDatesScreenAction';
    
    /** Modal title text (default: 'New Record', auto-generated if objectApiName provided) */
    @api modalTitle = 'New Record';
    
    /** Tracks if save operation is in progress */
    isSaving = false;
    
    /** Tracks form validation state from child component */
    isFormValid = true;

    /**
     * Determines if Program Dates child component should be rendered
     * Add similar getters for other child components as needed
     */
    get isProgramDates() {
        return this.childComponent === 'programDatesScreenAction';
    }

    // Add more getters here for other child components
    // get isOtherObject() {
    //     return this.childComponent === 'otherObjectForm';
    // }

    /**
     * Lifecycle hook: Sets default modal title based on objectApiName if not provided
     */
    connectedCallback() {
        if (this.modalTitle === 'New Record' && this.objectApiName) {
            const objectLabel = this.getObjectLabel(this.objectApiName);
            this.modalTitle = `New ${objectLabel}`;
        }
    }

    // Object label mappings for modal titles
    static OBJECT_LABELS = {
        'Program_Dates__c': 'Program Dates',
        'Account': 'Account',
        'Contact': 'Contact'
    };

    getObjectLabel(objectApiName) {
        return RelatedObjectActionModal.OBJECT_LABELS[objectApiName] || 'Record';
    }

    /**
     * Handles Cancel button click - closes the modal
     */
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
    }

    /**
     * Handles Save button click - triggers save in child component
     */
    handleSave() {
        this.isSaving = true;
        const childComponent = this.getChildComponent();
        if (childComponent && typeof childComponent.triggerSave === 'function') {
            childComponent.triggerSave();
        } else {
            console.error('Child component not found or triggerSave method not available');
            this.isSaving = false;
        }
    }

    /**
     * Handles Save & New button click - triggers save and new in child component
     */
    handleSaveAndNew() {
        this.isSaving = true;
        const childComponent = this.getChildComponent();
        if (childComponent && typeof childComponent.triggerSaveAndNew === 'function') {
            childComponent.triggerSaveAndNew();
        } else {
            this.isSaving = false;
        }
    }
    
    /**
     * Gets the active child component dynamically
     * Looks for component with data-child-component attribute first, then falls back to known components
     * @returns {LightningElement|null} The active child component or null if not found
     */
    getChildComponent() {
        // First try to find component with data attribute (preferred method)
        let childComponent = this.template.querySelector('[data-child-component]');
        
        // Fallback to known child components if data attribute not found
        if (!childComponent) {
            if (this.isProgramDates) {
                childComponent = this.template.querySelector('c-program-dates-screen-action');
            }
            // Add more fallbacks for other child components as needed
        }
        
        return childComponent;
    }

    /**
     * Computed property: Determines if save buttons should be disabled
     * Disabled when: saving in progress OR form is invalid
     */
    get saveDisabled() {
        return this.isSaving || !this.isFormValid;
    }

    /**
     * Handles validity change event from child component
     * @param {CustomEvent} event - Event with detail.isValid boolean
     */
    handleValidityChange(event) {
        this.isFormValid = event.detail?.isValid !== false;
    }

    /**
     * Handles success event from child component after record creation
     * @param {CustomEvent} event - Event with detail.recordId and detail.saveAndNew
     */
    handleSuccess(event) {
        this.isSaving = false;
        
        if (!event?.detail?.recordId) {
            return;
        }
        
        // Close modal unless Save & New was used
        if (!event.detail.saveAndNew) {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
        }
        
        // Notify parent (e.g., related list) to refresh
        this.dispatchEvent(
            new CustomEvent('recordcreated', {
                bubbles: true,
                composed: true,
                detail: { 
                    recordId: event.detail.recordId || event.detail.id,
                    objectApiName: this.objectApiName
                }
            })
        );
    }

    /**
     * Handles error event from child component
     */
    handleError() {
        this.isSaving = false;
    }
}
