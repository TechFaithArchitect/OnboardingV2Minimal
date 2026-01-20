import { api, track, wire } from 'lwc';
import OnboardingStepBase from 'c/onboardingStepBase';
import searchVendors from '@salesforce/apex/VendorOnboardingWizardController.searchVendors';
import createVendorApex from '@salesforce/apex/VendorOnboardingWizardController.createVendor';

export default class VendorProgramOnboardingStepOne extends OnboardingStepBase {
  stepName = 'Select or Create Vendor';
  
  @track searchText = '';
  @track vendorOptions = [];
  @track selectedVendorId = '';
  @track newVendorName = '';
  @track nextDisabled = true;
  @track isLoading = false;
  @track isCreatingVendor = false;

  // Debounce timer for autocomplete
  searchTimeout;
  @track debouncedSearchText = '';

  // Wire adapter for autocomplete - updates when debouncedSearchText changes
  @wire(searchVendors, { vendorNameSearchText: '$debouncedSearchText' })
  wiredVendors({ error, data }) {
    if (data) {
      this.vendorOptions = data.map(vendor => ({
        label: vendor.Name,
        value: vendor.Id
      }));
      this.isLoading = false;
    } else if (error) {
      this.handleError(error, 'Failed to search vendors');
      this.vendorOptions = [];
      this.isLoading = false;
    } else {
      // Still loading or no data yet
      if (this.debouncedSearchText && this.debouncedSearchText.length >= 2) {
        // We're waiting for results
      } else {
        // No search text, clear options
        this.vendorOptions = [];
        this.isLoading = false;
      }
    }
  }

  handleSearchChange(e) {
    // This handles typing in the input field
    const searchValue = e.target.value || '';
    this.searchText = searchValue;
    
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    // If search text is cleared, clear options
    if (!searchValue || searchValue.trim().length === 0) {
      this.debouncedSearchText = '';
      this.vendorOptions = [];
      this.selectedVendorId = '';
      this.nextDisabled = true;
      this.dispatchValidationState();
      return;
    }

    // Debounce: wait 300ms after user stops typing before searching
    // Require at least 2 characters for autocomplete
    if (searchValue.trim().length >= 2) {
      this.isLoading = true;
      this.searchTimeout = setTimeout(() => {
        this.debouncedSearchText = searchValue.trim();
      }, 300);
    } else {
      this.debouncedSearchText = '';
      this.vendorOptions = [];
      this.selectedVendorId = '';
      this.nextDisabled = true;
      this.dispatchValidationState();
    }
  }

  // Allow Enter key to immediately trigger a search using the current text
  handleSearchKeydown(e) {
    if (e.key === 'Enter' || e.keyCode === 13) {
      const searchValue = e.target.value || '';
      this.searchText = searchValue;
      if (!searchValue || searchValue.trim().length < 2) {
        this.debouncedSearchText = '';
        this.vendorOptions = [];
        this.selectedVendorId = '';
        this.nextDisabled = true;
        this.dispatchValidationState();
        return;
      }
      this.isLoading = true;
      this.debouncedSearchText = searchValue.trim();
    }
  }

  handleNewVendorChange(e) {
    this.newVendorName = e.target.value;
  }

  handleVendorSelect(e) {
    this.selectedVendorId = e.detail.value;
    this.newVendorName = '';
    this.nextDisabled = false;
    this.dispatchValidationState();
    
    // Update search text to show selected vendor name
    const selectedOption = this.vendorOptions.find(opt => opt.value === e.detail.value);
    if (selectedOption) {
      this.searchText = selectedOption.label;
    }
    
    // Clear the search timeout since selection was made
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
  }

  async createVendor() {
    if (!this.newVendorName || this.newVendorName.trim().length === 0) {
      return;
    }

    if (this.isCreatingVendor) {
      return;
    }

    this.isCreatingVendor = true;
    try {
      const trimmedName = this.newVendorName.trim();

      // First, check if a vendor with a similar name already exists
      const matches = await searchVendors({ vendorNameSearchText: trimmedName });
      if (matches && matches.length > 0) {
        // Surface existing vendors instead of creating a duplicate
        this.vendorOptions = matches.map(v => ({
          label: v.Name,
          value: v.Id
        }));
        this.selectedVendorId = '';
        this.searchText = trimmedName;
        this.newVendorName = '';
        this.nextDisabled = true;
        this.dispatchValidationState();

        this.showToast(
          'Vendor Already Exists',
          'We found existing vendors matching this name. Please select an existing vendor above to continue or refine your search.',
          'info'
        );
        return;
      }

      // No match → create vendor and immediately proceed
      const vendorId = await createVendorApex({ vendor: { Name: trimmedName } });

      this.selectedVendorId = vendorId;
      this.searchText = trimmedName;
      this.vendorOptions = [{
        label: trimmedName,
        value: vendorId
      }];
      this.newVendorName = ''; // Clear input
      this.nextDisabled = false;
      this.dispatchValidationState();

      // Immediately advance to next step after successful vendor creation
      this.proceedToNext();
    } catch (err) {
      this.handleError(err, 'Failed to create vendor');
    } finally {
      this.isCreatingVendor = false;
    }
  }

  get canProceed() {
    return !this.nextDisabled;
  }

  proceedToNext() {
    this.dispatchNextEvent({
      vendorId: this.selectedVendorId
    });
  }

  get vendorCountText() {
    const count = this.vendorOptions.length;
    return `${count} vendor${count === 1 ? '' : 's'} found`;
  }

  get hasSearchResults() {
    return this.vendorOptions.length > 0 && this.searchText && this.searchText.trim().length >= 2;
  }

  get hasNoResults() {
    return this.vendorOptions.length === 0 && this.searchText && this.searchText.trim().length >= 2 && !this.isLoading;
  }
}
