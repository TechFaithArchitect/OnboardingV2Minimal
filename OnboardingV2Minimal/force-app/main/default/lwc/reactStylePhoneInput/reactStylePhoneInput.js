import { LightningElement, track, api } from 'lwc';
import libPhone from '@salesforce/resourceUrl/libphonenumber';
import { loadScript } from 'lightning/platformResourceLoader';
import countries from './countries';
import flags from '@salesforce/resourceUrl/flags';

export default class ReactStylePhoneInput extends LightningElement {
    @track selectedCountry = countries[0]; 
    @track phoneNumber = '';
    @track showError = false;
    @api isValid = false;
    @api label = 'Phone Number';
    @api required = false;
    @api disabled = false;
    _defaultPhoneNumber = '';
    @track showDropdown = false;
    @track searchTerm = '';

    libLoaded = false;
    countryList = countries;

    connectedCallback() {
        loadScript(this, libPhone)
            .then(() => {
                this.libLoaded = true;
    
                this.countryList = countries.map(c => ({
                    ...c,
                    flagUrl: `${flags}/${c.flagPath}` // ✅ Use existing key
                }));
    
                this.selectedCountry = this.countryList[0];
                this.applyDefaultPhoneNumber();
            })
            .catch(error => console.error('Lib load failed', error));
    }
    
    @api
    get value() {
        return this.phoneNumber;
    }

    set value(val) {
        this.phoneNumber = val || '';
    }

    @api
    get defaultPhoneNumber() {
        return this._defaultPhoneNumber;
    }

    set defaultPhoneNumber(val) {
        this._defaultPhoneNumber = val || '';
        this.applyDefaultPhoneNumber();
    }

    applyDefaultPhoneNumber() {
        const defaultValue = (this._defaultPhoneNumber || '').trim();
        if (!defaultValue) {
            return;
        }

        // Before libphonenumber is loaded, keep raw value visible.
        if (!this.libLoaded || !window.libphonenumber) {
            this.phoneNumber = defaultValue;
            this.showError = false;
            return;
        }

        const cleanedValue = defaultValue.replace(/[^\d+]/g, '');
        const phoneUtil = window.libphonenumber.PhoneNumberUtil.getInstance();

        try {
            const parsed = cleanedValue.startsWith('+')
                ? phoneUtil.parseAndKeepRawInput(cleanedValue)
                : phoneUtil.parseAndKeepRawInput(cleanedValue, this.selectedCountry?.iso2 || 'US');

            const regionCode = phoneUtil.getRegionCodeForNumber(parsed);
            if (regionCode) {
                const matchingCountry = this.countryList.find(c => c.iso2 === regionCode);
                if (matchingCountry) {
                    this.selectedCountry = matchingCountry;
                }
            }

            this.phoneNumber = phoneUtil.format(parsed, window.libphonenumber.PhoneNumberFormat.NATIONAL);
            this.isValid = phoneUtil.isValidNumber(parsed);
            this.showError = false;
        } catch (error) {
            this.phoneNumber = defaultValue;
            this.isValid = false;
            this.showError = false;
        }
    }

    @api
    validate() {
        let rawNumber = this.phoneNumber.replace(/[^\d+]/g, '');

        if (!rawNumber.startsWith('+')) {
            rawNumber = this.selectedCountry.dialCode + rawNumber;
        }

        console.log('Phone Input:', this.phoneNumber);
        console.log('Cleaned Input:', rawNumber);
        console.log('Selected Country ISO2:', this.selectedCountry.iso2);

        const expectedLength = this.selectedCountry.dialCode === '+1' ? 10 : 7; 

        if (!rawNumber || rawNumber.length < expectedLength) {
            this.showError = false; 
            this.isValid = false;
            return {
                isValid: false,
                errorMessage: '',
            };
        }

        try {
            const phoneUtil = window.libphonenumber.PhoneNumberUtil.getInstance();
            const parsed = phoneUtil.parseAndKeepRawInput(rawNumber, this.selectedCountry.iso2);
            const valid = phoneUtil.isValidNumber(parsed);

            console.log('Parsed:', parsed);
            console.log('Is valid:', valid);

            this.showError = !valid;
            this.isValid = valid;

            return {
                isValid: valid,
                errorMessage: valid ? '' : 'Invalid phone number.',
            };
        } catch (err) {
            console.error('Validation error:', err);
            this.showError = true;
            this.isValid = false;
            return {
                isValid: false,
                errorMessage: 'Invalid phone number.',
            };
        }
        console.log('Returning to Flow:', { isValid: valid });
    }
 

    handleInputChange(event) {
        if (this.disabled) {
            return;
        }
        const inputVal = event.detail.value.replace(/[^\d+]/g, '');
    
        try {
            const phoneUtil = window.libphonenumber.PhoneNumberUtil.getInstance();
            const parsed = phoneUtil.parseAndKeepRawInput(inputVal, this.selectedCountry.iso2);
            this.phoneNumber = phoneUtil.format(parsed, window.libphonenumber.PhoneNumberFormat.NATIONAL);
            this.showError = false;
        } catch {
            this.phoneNumber = inputVal;
            this.showError = true;
        }
    
        this.validate();
        this.dispatchChange();
    }    
    handleCountryChange(event) {
        if (this.disabled) {
            return;
        }
        const selectedCode = event.target.value;
        this.selectedCountry = this.countryList.find(c => c.iso2 === code);
        this.phoneNumber = ''; 
        this.showError = false;
        this.showDropdown = false;
    }
    handleFocus() {
        if (this.disabled) {
            return;
        }
        this.showDropdown = true;
    }
    handleBlur() {
        setTimeout(() => {
            this.showDropdown = false;
        }, 200); 
    }
    handleKeyDown(event) {
        if (this.disabled) {
            return;
        }
        if (event.key === 'Enter') {
            this.toggleDropdown();
        }
    }
    handleClick(event) {
        if (this.disabled) {
            return;
        }
        event.stopPropagation();
        this.toggleDropdown();
    }
    handleDropdownClick(event) {
        event.stopPropagation();
    }
    handleDropdownKeyDown(event) {
        if (this.disabled) {
            return;
        }
        if (event.key === 'Escape') {
            this.showDropdown = false;
        }
    }
    handleDropdownItemClick(event) {
        if (this.disabled) {
            return;
        }
        const code = event.currentTarget.dataset.code;
        this.selectedCountry = this.countryList.find(c => c.iso2 === code);
        try {
            const phoneUtil = window.libphonenumber.PhoneNumberUtil.getInstance();
            const parsed = phoneUtil.parseAndKeepRawInput(this.phoneNumber, code); 
            this.phoneNumber = phoneUtil.format(parsed, window.libphonenumber.PhoneNumberFormat.NATIONAL);
        } catch {
            this.phoneNumber = '';
        }
        this.showDropdown = false;
        this.dispatchChange();
    }
    handleDropdownItemKeyDown(event) {
        if (this.disabled) {
            return;
        }
        if (event.key === 'Enter') {
            const code = event.currentTarget.dataset.code;
            this.selectedCountry = this.countryList.find(c => c.iso2 === code);
            try {
                const phoneUtil = window.libphonenumber.PhoneNumberUtil.getInstance();
                const parsed = phoneUtil.parseAndKeepRawInput(this.phoneNumber, code); 
                this.phoneNumber = phoneUtil.format(parsed, window.libphonenumber.PhoneNumberFormat.NATIONAL);
            } catch {
                this.phoneNumber = '';
            }
            this.showDropdown = false;
            this.dispatchChange();
        }
    }
    handleDropdownItemMouseOut(event) {
        event.preventDefault(); 
    }
    handleDropdownItemMouseOver(event) {
        event.preventDefault(); 
    }    
    toggleDropdown() {
        if (this.disabled) {
            return;
        }
        this.showDropdown = !this.showDropdown;
    }

    selectCountry(event) {
        if (this.disabled) {
            return;
        }
        const code = event.currentTarget.dataset.code;
        this.selectedCountry = this.countryList.find(c => c.iso2 === code);
        this.showDropdown = false;
        this.phoneNumber = '';
        this.dispatchChange();
    }

    handleSearch(event) {
        if (this.disabled) {
            return;
        }
        this.searchTerm = event.target.value.toLowerCase();
        this.countryList = countries.filter(c =>
            c.name.toLowerCase().includes(this.searchTerm) ||
            c.dialCode.includes(this.searchTerm) ||
            c.iso2.toLowerCase().includes(this.searchTerm)
        );
    }

    dispatchChange() {
        this.dispatchEvent(
            new CustomEvent('change', {
                detail: { value: this.phoneNumber },
                bubbles: true,
                composed: true
            })
        );
    }

    get errorClass() {
        return this.showError ? 'slds-has-error' : '';
    }

    get displayLabel() {
        return this.label && this.label.trim() ? this.label : 'Phone Number';
    }
}