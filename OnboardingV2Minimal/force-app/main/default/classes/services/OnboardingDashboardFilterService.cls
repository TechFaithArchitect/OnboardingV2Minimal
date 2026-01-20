/**
 * Service for building filter clauses for onboarding dashboard queries
 * Centralizes filter logic and date range calculations
 */
public with sharing class OnboardingDashboardFilterService {
  /**
   * Get date range filter for SOQL WHERE clause
   * @param timeFilter Time filter value (LAST_30_DAYS, LAST_90_DAYS, YEAR_TO_DATE, ALL_TIME)
   * @return Date start date or null for ALL_TIME
   */
  public static Date getDateRangeFilter(String timeFilter) {
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }

    Date today = Date.today();

    if (timeFilter == 'LAST_30_DAYS') {
      return today.addDays(-30);
    } else if (timeFilter == 'LAST_90_DAYS') {
      return today.addDays(-90);
    } else if (timeFilter == 'YEAR_TO_DATE') {
      return Date.newInstance(today.year(), 1, 1);
    } else if (timeFilter == 'ALL_TIME') {
      return null;
    }

    // Default to last 90 days
    return today.addDays(-90);
  }

  /**
   * Get WHERE clause for view filter
   * @param viewFilter View filter value (MY_VIEW, MY_TEAM, ORG_WIDE)
   * @param currentUserId Current user ID
   * @return WHERE clause string (e.g., "CreatedById = '005...'")
   */
  public static String getViewFilterClause(
    String viewFilter,
    Id currentUserId
  ) {
    if (String.isBlank(viewFilter)) {
      viewFilter = 'MY_VIEW';
    }

    if (viewFilter == 'MY_VIEW') {
      return 'CreatedById = \'' +
        String.escapeSingleQuotes(String.valueOf(currentUserId)) +
        '\'';
    } else if (viewFilter == 'MY_TEAM') {
      // Get team member IDs
      Set<Id> teamUserIds = OnboardingAccessService.getUserIdsForViewFilter(
        viewFilter
      );
      if (teamUserIds.isEmpty()) {
        return 'CreatedById = \'' +
          String.escapeSingleQuotes(String.valueOf(currentUserId)) +
          '\'';
      }
      return 'CreatedById IN (' + buildIdList(teamUserIds) + ')';
    } else if (viewFilter == 'ORG_WIDE') {
      // No filter - show all records user has access to
      return '';
    }

    // Default to MY_VIEW
    return 'CreatedById = \'' +
      String.escapeSingleQuotes(String.valueOf(currentUserId)) +
      '\'';
  }

  /**
   * Build complete WHERE clause with all filters
   * @param timeFilter Time range filter
   * @param vendorIds List of vendor IDs to filter by
   * @param programIds List of vendor program IDs to filter by
   * @param viewFilter View filter (MY_VIEW, MY_TEAM, ORG_WIDE)
   * @return Complete WHERE clause string
   */
  public static String buildFilterClause(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds,
    String viewFilter
  ) {
    List<String> conditions = new List<String>();

    // View filter
    if (String.isNotBlank(viewFilter) && viewFilter != 'ORG_WIDE') {
      String viewClause = getViewFilterClause(viewFilter, UserInfo.getUserId());
      if (String.isNotBlank(viewClause)) {
        conditions.add(viewClause);
      }
    }

    // Time filter
    Date startDate = getDateRangeFilter(timeFilter);
    if (startDate != null) {
      conditions.add('CreatedDate >= ' + formatDateForSOQL(startDate));
    }

    // Vendor filter
    if (vendorIds != null && !vendorIds.isEmpty()) {
      conditions.add(
        'Vendor__c IN (' + buildIdList(new Set<Id>(vendorIds)) + ')'
      );
    }

    // Program filter
    if (programIds != null && !programIds.isEmpty()) {
      conditions.add(
        'Vendor_Customization__c IN (' +
          buildIdList(new Set<Id>(programIds)) +
          ')'
      );
    }

    // Status filter (exclude completed/denied/expired for active onboarding)
    conditions.add(
      'Onboarding_Status__c NOT IN (\'Complete\', \'Denied\', \'Expired\')'
    );

    return String.join(conditions, ' AND ');
  }

  /**
   * Build ID list string for SOQL IN clause
   */
  private static String buildIdList(Set<Id> ids) {
    if (ids == null || ids.isEmpty()) {
      return '';
    }
    List<String> idStrings = new List<String>();
    for (Id recordId : ids) {
      idStrings.add(
        '\'' + String.escapeSingleQuotes(String.valueOf(recordId)) + '\''
      );
    }
    return String.join(idStrings, ', ');
  }

  /**
   * Format date for SOQL WHERE clause
   */
  private static String formatDateForSOQL(Date dateValue) {
    return String.valueOf(dateValue.year()) +
      '-' +
      String.valueOf(dateValue.month()).leftPad(2, '0') +
      '-' +
      String.valueOf(dateValue.day()).leftPad(2, '0');
  }
}
