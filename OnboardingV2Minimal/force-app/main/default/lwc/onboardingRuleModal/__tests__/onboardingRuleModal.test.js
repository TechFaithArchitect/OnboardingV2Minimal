import { createElement } from '@lwc/engine-dom';
import OnboardingRuleModal from 'c/onboardingRuleModal';

describe('c-onboarding-rule-modal', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders component', () => {
        const element = createElement('c-onboarding-rule-modal', {
            is: OnboardingRuleModal
        });
        document.body.appendChild(element);

        expect(element).toBeTruthy();
    });
});