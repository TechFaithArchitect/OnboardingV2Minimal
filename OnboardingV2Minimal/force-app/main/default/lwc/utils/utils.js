/**
 * Shared error handling utility for LWC components that don't extend OnboardingStepBase
 */

/**
 * Extracts meaningful error messages from various error formats
 * @param {Error} error - The error object
 * @param {String} defaultMessage - Default message if error parsing fails
 * @returns {String} - The extracted error message
 */
export function extractErrorMessage(error, defaultMessage) {
  if (!error) {
    return defaultMessage;
  }
  
  // Parse Salesforce error formats
  if (error.body) {
    if (Array.isArray(error.body) && error.body.length > 0) {
      return error.body[0].message || defaultMessage;
    } else if (error.body.message) {
      return error.body.message;
    } else if (typeof error.body === 'string') {
      return error.body;
    } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
      return error.body.pageErrors[0].message || defaultMessage;
    }
  } else if (error.message) {
    return error.message;
  }
  
  return defaultMessage;
}

/**
 * Shows a toast notification
 * @param {LightningElement} component - The component instance
 * @param {String} title - Toast title
 * @param {String} message - Toast message
 * @param {String} variant - Toast variant (success, error, warning, info)
 */
export function showToast(component, title, message, variant = 'info') {
  const { ShowToastEvent } = require('lightning/platformShowToastEvent');
  const evt = new ShowToastEvent({
    title,
    message,
    variant
  });
  component.dispatchEvent(evt);
}

/**
 * Handles errors and shows toast notification
 * @param {LightningElement} component - The component instance
 * @param {Error} error - The error object
 * @param {String} defaultMessage - Default error message
 * @param {Boolean} debugMode - Whether to log error details (default: false)
 */
export function handleError(component, error, defaultMessage, debugMode = false) {
  const errorMessage = extractErrorMessage(error, defaultMessage);
  showToast(component, 'Error', errorMessage, 'error');
  
  if (debugMode) {
    console.error('Error in', component.constructor.name, ':', error);
  }
}

