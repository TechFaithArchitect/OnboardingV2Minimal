# Onboarding Home Dashboard Component

## Overview

The `onboardingHomeDashboard` component provides a comprehensive command center for Dealer and Vendor Program onboarding activities. It offers role-based views, KPI summaries, work queues, analytics, and quick access to start new onboarding processes. Dealer refers to an Account record.

See [User Journey Summary](../user-guides/user-journey-summary.md) for the end-to-end flow.

## Component Details

### Location
`force-app/main/default/lwc/onboardingHomeDashboard/`

### Purpose
Central dashboard for managing and monitoring onboarding activities. Designed as the primary entry point for Program Specialists (Sales), Onboarding Reps, Sales Managers, and Executives.

## Features

### KPI Summary Cards
Displays key metrics at a glance via the `onboardingKpiRow` component:
- **Active Dealer Onboarding**: Count of active onboarding records (excluding Complete, Denied, Expired)
- **Completed This Period**: Count of completed onboarding within the selected time range
- **Active Vendor Programs**: Count of active vendor programs
- **Dealers Onboarded**: Total count of dealers that have completed onboarding
- **Blocked / At Risk**: Count of onboarding records that are blocked or at risk

Each card is clickable and navigates to the relevant tab with appropriate filters applied.

### Global Filters
The `onboardingFilterChips` component provides:
- **Time Range**: Last 30 Days, Last 90 Days, Year to Date, All Time
- **Vendor**: Filter by specific vendors (single-select combobox)
- **Vendor Program**: Filter by specific vendor programs (single-select combobox)
- **View**: My View, My Team, Org Wide (permission-gated)

All filters are applied across all tabs and components.

### Tabbed Work Queues

#### My Active Dealer Onboarding Tab
Shows active onboarding records created by the current user:
- Uses `onboardingWorkQueue` component with row highlighting
- Red border: Blocked records
- Yellow border: At-risk records
- Blue border: Normal records
- Columns: Account, Vendor Program, Status, Age (days), Last Modified, Actions
- Row actions: View, Resume, Requirements

#### Eligible Dealers Tab
Displays accounts that can start new onboarding processes:
- Account name, Territory, Region
- Eligible vendor count
- Row actions: Start Onboarding, View Account

**How Eligibility is Determined:**
- Uses `OnboardingEligibilityService.getEligibleVendorCountsByAccount()` to check each account
- Returns accounts with active vendor programs that haven't been onboarded yet
- Respects prerequisite requirements and existing onboarding records

#### Vendor Programs Tab
Card grid layout showing vendor program health metrics:
- Program name, Vendor, Status badge
- Dealer counts (onboarded, in progress, blocked)
- Requirement progress bar
- Health indicators: Rules Engine status, Dependencies status
- Action buttons: View Program, Launch Wizard

#### Team / Org Queue Tab (Conditional)
Visible only when View filter is set to "My Team" or "Org Wide":
- Shows onboarding records for team members or entire org
- Same columns and functionality as "My Active Onboarding"
- Respects Account sharing rules

#### Insights Tab
Analytics and visualizations:
- Status distribution chart
- Onboarding funnel visualization
- Vendor program metrics overview
- Uses `onboardingInsights` component

### Recent Activity Sidebar
Timeline-style activity feed showing:
- Time ago (e.g., "5m", "2h", "3d")
- Activity summary with account and vendor program
- Actor (user who made the change)
- Color-coded: Green (completions), Orange (blocks), Blue (neutral)
- Clickable links to navigate to records

### Quick Actions
- **Start Onboarding Vendor Program**: Opens `onboardingVendorProgramWizard` modal to select/create a Vendor Program and initialize onboarding
- **Start Dealer Onboarding**: Opens `onboardingDealerOnboardingModal` to select an account and initiate onboarding
- **Sync Component Library**: Populates Component Library with wizard components
- **Initialize Default Process**: Creates default Vendor Program Onboarding process
- **Refresh**: Reloads all dashboard data

### Admin Configuration Shortcuts (Permission-Gated)
Visible only to users with admin permissions:
- **Manage Requirements**: Navigate to requirements management
- **Manage Status Rules**: Navigate to status rules engine
- **Stage Dependencies**: Navigate to stage dependency management
- **Vendor Program Wizard**: Open vendor program onboarding wizard
- **Component Library**: Navigate to component library

These shortcuts, along with validation/messaging tabs, are encapsulated in the `onboardingAdminToolsPanel` child component to keep the main dashboard focused on orchestration.

## Design Decisions

### CreatedBy vs OwnerId

The component uses `CreatedById` instead of `OwnerId` because:

1. **No Owner Field**: `Onboarding__c` is a Master-Detail to Account with `ControlledByParent` sharing. Master-Detail objects don't have Owner fields by default.

2. **Account-Based Sharing**: Access to onboarding records is controlled by the parent Account's sharing rules. All users with access to the Account can see its onboarding records.

3. **Collaborative Workflow**: Multiple users may work on onboarding requirements simultaneously. Using `CreatedById` allows tracking who initiated the onboarding while allowing team collaboration.

4. **Natural Filtering**: "My Active Onboarding" naturally shows records created by the current user, which is typically what users want to see.

### Data Filtering

- **My Active Onboarding**: Shows records where `CreatedById = currentUserId`
- **Summary Statistics**: Aggregates counts for records created by current user
- **All Active Onboarding**: Available via `getAllActiveOnboarding()` method for admins/managers (not exposed in UI by default)

### Performance Considerations

- All Apex methods are `@AuraEnabled(cacheable=true)` for client-side caching
- Result sets are limited to prevent large data loads (20 records for active, 50 for all, 10 for recent)
- Bulk queries where possible (e.g., checking eligible vendors for multiple accounts)
- Uses `@wire` decorators for automatic data loading and refresh

## Setup Instructions

### 1. Deploy Components

Deploy the Apex controller and LWC component:
```bash
sfdx force:source:deploy -p force-app/main/default/classes/controllers/OnboardingHomeDashboardController.cls
sfdx force:source:deploy -p force-app/main/default/lwc/onboardingHomeDashboard
```

### 2. Create Lightning Home Page

1. Navigate to **Setup** → **Lightning App Builder**
2. Click **New** → **Home Page**
3. Name it "Vendor Onboarding Dashboard"
4. Drag the `onboardingHomeDashboard` component onto the page
5. Configure layout as desired
6. Click **Save** → **Activate**

### 3. Assign to App (Optional)

1. Navigate to **Setup** → **App Manager**
2. Edit your app
3. Go to **Navigation Items**
4. Set the home page as default, or add it to the navigation

### 4. Assign to Users (Optional)

1. Navigate to **Setup** → **Lightning Pages**
2. Find your home page
3. Use **Assignment** to assign to specific profiles/users

## Usage

### Viewing Dashboard
Simply navigate to the Home page where the component is added. Data loads automatically.

### Starting New Onboarding
1. Click **Start New Onboarding** button
2. Select an account from the dropdown modal
3. Click **Start Onboarding**
4. System navigates to Account record page
5. Use the Quick Action to select vendor programs and start onboarding

### Viewing/Resuming Onboarding
1. Find the onboarding record in the Active Onboarding table
2. Click the row actions menu (⋯)
3. Select **View** to see details, or **Resume** to continue the process

### Finding Eligible Accounts
1. Review the Eligible Accounts table
2. See which accounts have available vendor programs
3. Click **Start Onboarding** from row actions to begin

## Technical Details

### Apex Controller

**File:** `force-app/main/default/classes/controllers/OnboardingHomeDashboardController.cls`

**Key Methods:**
- `getMyActiveOnboarding(timeFilter, vendorIds, programIds, viewFilter)` - Returns active onboarding with filters
- `getOnboardingSummary(timeFilter, vendorIds, programIds, viewFilter)` - Returns status counts with filters
- `getEligibleAccounts(timeFilter, vendorIds, programIds)` - Returns accounts eligible for onboarding
- `getRecentActivity(recordLimit, timeFilter, vendorIds, programIds)` - Returns recent activity with filters
- `getVendorProgramMetrics(timeFilter, vendorIds)` - Returns vendor program health metrics
- `getBlockedOnboardingCount(timeFilter, vendorIds, programIds)` - Returns count of blocked/at-risk records
- `getTeamOnboarding(viewFilter, timeFilter, vendorIds, programIds)` - Returns team/org queue
- `getOnboardingWithBlockingInfo(onboardingIds)` - Returns onboarding with blocking information
- `getVendors()` - Returns list of vendors for filter dropdown
- `getVendorPrograms()` - Returns list of vendor programs for filter dropdown
- `getAllActiveOnboarding()` - Returns all active records (for admins)

### Services

**OnboardingDashboardFilterService:**
- `getDateRangeFilter(timeFilter)` - Converts time filter to Date range
- `getViewFilterClause(viewFilter, currentUserId)` - Builds WHERE clause for view filter
- `buildFilterClause(...)` - Builds complete WHERE clause with all filters
- `buildLastModifiedFilterClause(...)` - Builds WHERE clause for LastModifiedDate filters

**OnboardingBlockingDetectionService:**
- `getBlockedOnboardingIds(onboardingIds)` - Identifies blocked onboarding records
- `getBlockingReasons(onboardingId)` - Returns list of blocking reasons
- `isAtRisk(onboardingId, daysThreshold)` - Checks if onboarding is at risk
- `getBlockingInfoBulk(onboardingIds)` - Gets blocking info for multiple records

### Data Transfer Objects

**OnboardingDTO:**
- Contains onboarding record data with related Account and Vendor Program info
- Includes CreatedById/CreatedByName (not OwnerId/OwnerName)
- Provides RecordUrl for navigation

**OnboardingWithBlockingDTO:**
- Extends OnboardingDTO
- Adds: IsBlocked, IsAtRisk, BlockingReasons, AgeInDays

**AccountDTO:**
- Contains account data with eligibility information
- Includes eligible vendor count
- Provides RecordUrl for navigation

**VendorProgramMetricsDTO:**
- Contains vendor program health metrics
- Includes: DealersOnboarded, InProgressCount, BlockedCount, Requirement counts
- Health indicators: RulesEngineValid, DependenciesValid

### Component Structure

```
onboardingHomeDashboard/ (main component)
├── onboardingHomeDashboard.html
├── onboardingHomeDashboard.js
├── onboardingHomeDashboard.css
└── onboardingHomeDashboard.js-meta.xml

Child Components:
├── onboardingKpiRow/              # KPI summary cards
├── onboardingFilterChips/         # Global filters
├── onboardingWorkQueue/           # Reusable work queue table
├── onboardingVendorProgramGrid/   # Vendor program card grid
├── onboardingRecentActivity/      # Activity feed sidebar
└── onboardingInsights/            # Analytics and charts
```

## Security

- All Apex methods use `with sharing` to respect Account sharing rules
- Users only see onboarding records for Accounts they have access to
- Summary statistics are scoped to records created by the current user
- Sharing is controlled by the Account parent (ControlledByParent)

## Troubleshooting

### No Data Showing
- Verify user has access to Account records
- Check that onboarding records exist and were created by the user (for "My" views)
- Ensure `OnboardingEligibilityService` is accessible for eligible accounts check

### Eligible Accounts Empty
- Verify accounts exist
- Check that active vendor programs exist
- Ensure `OnboardingEligibilityService` can access required objects

### Performance Issues
- Review result set limits
- Check for large numbers of onboarding records
- Consider adding additional filtering options

## Role-Based Access

### Program Specialists (Sales)
- Default tab: My Active Dealer Onboarding
- Can start dealer onboarding for their accounts
- See "My" metrics in KPI cards
- Team/Org Queue tab hidden

### Onboarding Reps
- Default tab: My Active Dealer Onboarding or Eligible Dealers
- Access to blocked/at-risk indicators
- Can manage requirement completion
- See blocking reasons in work queue

### Sales Managers
- Access to Team/Org Queue tab
- See team-level metrics
- Can filter by "My Team" or "Org Wide"
- View vendor program overview

### Executives
- Default to Vendor Program Overview and Insights tabs
- See org-level KPI counts
- Access to analytics and visualizations
- View pipeline and trends

### Admins
- All above features plus:
- Admin Configuration Shortcuts section
- Access to all configuration UIs
- Can manage requirements, rules, and dependencies

## Filter System

### Time Range Filters
- **LAST_30_DAYS**: Records created/modified in last 30 days
- **LAST_90_DAYS**: Records created/modified in last 90 days (default)
- **YEAR_TO_DATE**: Records from January 1st of current year
- **ALL_TIME**: No time restriction

### View Filters
- **MY_VIEW**: Records created by current user (default)
- **MY_TEAM**: Records created by current user and direct reports
- **ORG_WIDE**: All accessible records (permission-gated)

### Vendor/Program Filters
- Single-select comboboxes
- Filters applied to all queries
- Empty selection means "All"

## Blocking Detection

The dashboard identifies blocked and at-risk onboarding records:

### Blocked Records
- Onboarding status is "Denied"
- Has requirements with "Denied" status
- Visual indicator: Red left border in work queue

### At-Risk Records
- Has incomplete requirements for more than 7 days
- Visual indicator: Yellow left border in work queue
- Shown in "Blocked / At Risk" KPI card

## Mobile Responsiveness

The dashboard is fully responsive:
- KPI cards stack vertically on mobile
- Tabs remain functional with touch-friendly controls
- Tables scroll horizontally on small screens
- Cards adapt to smaller viewports
- Filter chips wrap appropriately

## Future Enhancements

Potential improvements:
- Multi-select vendor/program filters
- Export functionality for data tables
- Advanced stage dependency visualization
- Custom date range picker
- Real-time updates via Platform Events
- Bulk actions on work queues
