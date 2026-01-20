import { createElement } from '@lwc/engine-dom';
import OnboardingStatusRulesManager from 'c/onboardingStatusRulesManager';

describe('c-onboarding-status-rules-manager', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders component', () => {
        const element = createElement('c-onboarding-status-rules-manager', {
            is: OnboardingStatusRulesManager
        });
        document.body.appendChild(element);

        expect(element).toBeTruthy();
    });
});