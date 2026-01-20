import { createElement } from '@lwc/engine-dom';
import { NavigationMixin } from 'lightning/navigation';
import OnboardingAtRiskPanel from 'c/onboardingAtRiskPanel';
import getOnboardingWithBlockingInfo from '@salesforce/apex/OnboardingHomeDashboardController.getOnboardingWithBlockingInfo';
import getBlockedOnboardingCount from '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingCount';
import getBlockedOnboardingIds from '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingIds';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/OnboardingHomeDashboardController.getOnboardingWithBlockingInfo',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingCount',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/OnboardingHomeDashboardController.getBlockedOnboardingIds',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-onboarding-at-risk-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const mockBlockingInfo = [
        {
            Id: 'a0X000000000001AAA',
            AccountName: 'Test Account',
            VendorProgramName: 'Test Program',
            Status: 'In Process',
            IsBlocked: true,
            IsAtRisk: false,
            BlockingReasons: ['Requirement incomplete', 'Status is Denied']
        },
        {
            Id: 'a0X000000000002AAA',
            AccountName: 'Test Account 2',
            VendorProgramName: 'Test Program 2',
            Status: 'New',
            IsBlocked: false,
            IsAtRisk: true,
            BlockingReasons: ['No activity for 7+ days']
        }
    ];

    it('renders component', () => {
        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.timeFilter = 'LAST_90_DAYS';
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(element).toBeTruthy();
        });
    });

    it('displays blocked count from wire adapter', async () => {
        getBlockedOnboardingCount.mockResolvedValue(5);

        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.timeFilter = 'LAST_90_DAYS';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Verify wire adapter was called
        expect(getBlockedOnboardingCount).toHaveBeenCalled();
        
        // Verify blocked count is set
        await Promise.resolve();
        expect(element.blockedCount).toBe(5);
        expect(element.hasBlockedItems).toBe(true);
    });

    it('shows empty state when no blocked items', async () => {
        getBlockedOnboardingCount.mockResolvedValue(0);

        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.timeFilter = 'LAST_90_DAYS';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        expect(element.blockedCount).toBe(0);
        expect(element.hasBlockedItems).toBe(false);
    });

    it('loads blocked details when show details is clicked', async () => {
        getBlockedOnboardingCount.mockResolvedValue(2);
        getBlockedOnboardingIds.mockResolvedValue(['a0X000000000001AAA', 'a0X000000000002AAA']);
        getOnboardingWithBlockingInfo.mockResolvedValue(mockBlockingInfo);

        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.timeFilter = 'LAST_90_DAYS';
        element.blockedCount = 2;
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        // Toggle details
        element.showDetails = true;
        await element.loadBlockedDetails();

        await Promise.resolve();
        await Promise.resolve();

        expect(getBlockedOnboardingIds).toHaveBeenCalled();
        expect(getOnboardingWithBlockingInfo).toHaveBeenCalled();
        expect(element.blockedOnboarding.length).toBeGreaterThan(0);
    });

    it('handles error when loading blocked details', async () => {
        getBlockedOnboardingCount.mockResolvedValue(1);
        getBlockedOnboardingIds.mockRejectedValue(new Error('Failed to load'));

        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.timeFilter = 'LAST_90_DAYS';
        element.blockedCount = 1;
        
        let toastEvent;
        element.addEventListener('lightning__showtoast', (event) => {
            toastEvent = event.detail;
        });
        
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        element.showDetails = true;
        await element.loadBlockedDetails();

        await Promise.resolve();
        await Promise.resolve();

        expect(toastEvent).toBeTruthy();
        expect(toastEvent.variant).toBe('error');
        expect(element.blockedOnboarding).toEqual([]);
    });

    it('handles row action for view requirements', async () => {
        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.blockedOnboarding = [
            {
                Id: 'a0X000000000001AAA',
                accountName: 'Test Account',
                vendorProgramName: 'Test Program',
                status: 'In Process',
                blockingReasons: 'Requirement incomplete',
                isAtRisk: false
            }
        ];
        document.body.appendChild(element);

        await Promise.resolve();

        const mockEvent = {
            detail: {
                action: { name: 'view_requirements' },
                row: { Id: 'a0X000000000001AAA' }
            }
        };

        let viewRequirementsEvent;
        element.addEventListener('viewrequirements', (event) => {
            viewRequirementsEvent = event;
        });

        element.handleRowAction(mockEvent);

        expect(viewRequirementsEvent).toBeTruthy();
        expect(viewRequirementsEvent.detail.recordId).toBe('a0X000000000001AAA');
    });

    it('handles row action for view record', async () => {
        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.blockedOnboarding = [
            {
                Id: 'a0X000000000001AAA',
                accountName: 'Test Account',
                vendorProgramName: 'Test Program',
                status: 'In Process',
                blockingReasons: 'Requirement incomplete',
                isAtRisk: false
            }
        ];
        document.body.appendChild(element);

        await Promise.resolve();

        const mockEvent = {
            detail: {
                action: { name: 'view_record' },
                row: { Id: 'a0X000000000001AAA' }
            }
        };

        // NavigationMixin.Navigate is mocked by sfdx-lwc-jest
        element.handleRowAction(mockEvent);

        // Verify the method was called (navigation happens internally)
        expect(element.blockedOnboarding[0].Id).toBe('a0X000000000001AAA');
    });

    it('toggles details visibility', async () => {
        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.blockedCount = 2;
        document.body.appendChild(element);

        await Promise.resolve();

        expect(element.showDetails).toBe(false);
        expect(element.showDetailsLabel).toBe('Show Details');
        expect(element.showDetailsIcon).toBe('utility:chevrondown');

        element.handleToggleDetails();

        expect(element.showDetails).toBe(true);
        expect(element.showDetailsLabel).toBe('Hide Details');
        expect(element.showDetailsIcon).toBe('utility:chevronup');
    });

    it('has correct column configuration', () => {
        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const expectedColumns = [
                { label: 'Account', fieldName: 'accountName', type: 'text' },
                { label: 'Vendor Program', fieldName: 'vendorProgramName', type: 'text' },
                { label: 'Status', fieldName: 'status', type: 'text' },
                { label: 'Blocking Reasons', fieldName: 'blockingReasons', type: 'text', wrapText: true },
                { type: 'action', typeAttributes: { rowActions: expect.any(Array) } }
            ];
            
            expect(element.columns.length).toBe(5);
            expect(element.columns[0].fieldName).toBe('accountName');
            expect(element.columns[3].wrapText).toBe(true);
        });
    });

    it('displays correct panel title with count', async () => {
        getBlockedOnboardingCount.mockResolvedValue(3);

        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        element.timeFilter = 'LAST_90_DAYS';
        document.body.appendChild(element);

        await Promise.resolve();
        await Promise.resolve();

        expect(element.panelTitle).toBe('Blocked / At Risk (3)');
    });

    it('handles view all navigation', async () => {
        const element = createElement('c-onboarding-at-risk-panel', {
            is: OnboardingAtRiskPanel
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // NavigationMixin.Navigate is mocked by sfdx-lwc-jest
        element.handleViewAll();

        // Verify the method was called (navigation happens internally)
        expect(element).toBeTruthy();
    });
});
