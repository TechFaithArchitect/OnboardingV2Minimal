import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Base class for all onboarding step components.
 * Provides common functionality for footer navigation, validation state, and toast notifications.
 * 
 * Child components must implement:
 * - getter: canProceed (returns boolean)
 * - method: proceedToNext() (dispatches next event with detail)
 * - property: stepName (string) - optional, for card title
 */
export default class OnboardingStepBase extends LightningElement {
    @api stepNumber;
    stepName = ''; // Override in child components

    connectedCallback() {
        // Set up footer navigation listeners
        this.setupFooterNavigation();
        
        // Dispatch initial validation state
        this.dispatchValidationState();
    }

    /**
     * Sets up footer navigation event listeners.
     * Can be overridden if custom behavior is needed.
     */
    setupFooterNavigation() {
        this.addEventListener('footernavnext', this.handleFooterNextClick.bind(this));
        this.addEventListener('footernavback', this.handleFooterBackClick.bind(this));
    }

    /**
     * Handles footer Next button click.
     * Override in child components if custom logic is needed before proceeding.
     */
    handleFooterNextClick() {
        if (this.canProceed) {
            this.proceedToNext();
        }
    }

    /**
     * Handles footer Back button click.
     * Override in child components if custom logic is needed (e.g., async cleanup).
     */
    handleFooterBackClick() {
        this.dispatchBackEvent();
    }

    /**
     * Dispatches a 'next' event with proper configuration.
     * @param {Object} detail - Event detail object to pass to parent
     */
    dispatchNextEvent(detail = {}) {
        this.dispatchEvent(new CustomEvent('next', {
            detail,
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Dispatches a 'back' event with proper configuration.
     */
    dispatchBackEvent() {
        this.dispatchEvent(new CustomEvent('back', {
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Dispatches validation state to the flow engine.
     * Calls getter 'canProceed' which must be implemented in child components.
     */
    dispatchValidationState() {
        const canProceed = this.canProceed;
        this.dispatchEvent(new CustomEvent('validationchanged', {
            detail: {
                canProceed: canProceed,
                nextDisabled: !canProceed
            },
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Shows a toast notification.
     * @param {String} title - Toast title
     * @param {String} message - Toast message
     * @param {String} variant - Toast variant (success, error, warning, info). Defaults to 'info'
     */
    showToast(title, message, variant = 'info') {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }

    /**
     * Centralized error handling method.
     * Extracts meaningful error messages from various error formats and displays them to the user.
     * @param {Error} error - The error object
     * @param {String} defaultMessage - Default message if error parsing fails
     * @param {Object} context - Optional context object for logging (not displayed to user)
     * @returns {String} - The extracted error message
     */
    handleError(error, defaultMessage, context = {}) {
        let errorMessage = defaultMessage;
        
        // Parse Salesforce error formats
        if (error?.body) {
            if (Array.isArray(error.body) && error.body.length > 0) {
                errorMessage = error.body[0].message || errorMessage;
            } else if (error.body.message) {
                errorMessage = error.body.message;
            } else if (typeof error.body === 'string') {
                errorMessage = error.body;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                errorMessage = error.body.pageErrors[0].message || errorMessage;
            }
        } else if (error?.message) {
            errorMessage = error.message;
        }
        
        // Show error toast to user
        this.showToast('Error', errorMessage, 'error');
        
        // Log error details in development mode only
        if (this.isDebugMode()) {
            console.error('Error in', this.constructor.name, ':', error, context);
        }
        
        return errorMessage;
    }

    /**
     * Checks if debug mode is enabled.
     * Can be overridden to check custom metadata or environment variables.
     * @returns {Boolean} - true if debug mode is enabled
     */
    isDebugMode() {
        // In production, this should check custom metadata or be false
        // For now, return false to disable console logging in production
        return false;
    }

    /**
     * Gets the card title for the step.
     * Format: "Step {stepNumber}: {stepName}"
     * Override 'stepName' property in child components.
     */
    get cardTitle() {
        const step = this.stepNumber || '?';
        if (this.stepName) {
            return `Step ${step}: ${this.stepName}`;
        }
        return `Step ${step}`;
    }

    /**
     * Determines if the step can proceed to the next step.
     * MUST be implemented in child components.
     * @returns {Boolean} - true if step is valid and can proceed
     */
    get canProceed() {
        // Child components must override this
        if (this.isDebugMode()) {
            console.warn(`${this.constructor.name}: canProceed getter not implemented`);
        }
        return false;
    }

    /**
     * Called when proceeding to the next step.
     * MUST be implemented in child components.
     * Should call this.dispatchNextEvent(detail) with appropriate data.
     */
    proceedToNext() {
        // Child components must override this
        if (this.isDebugMode()) {
            console.error(`${this.constructor.name}: proceedToNext method not implemented`);
        }
    }
}
