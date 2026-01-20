/**
 * Controller for Onboarding Home Dashboard LWC component
 * Provides data for the dashboard interface showing user's onboarding records
 */
public with sharing class OnboardingHomeDashboardController {
  /**
   * Get active onboarding records for the current user
   * Uses CreatedBy to show records created by user, respecting Account sharing
   * Since Onboarding__c is Master-Detail to Account, sharing is controlled by Account access
   *
   * @param timeFilter Time range filter (LAST_30_DAYS, LAST_90_DAYS, YEAR_TO_DATE, ALL_TIME) - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   * @param viewFilter View filter (MY_VIEW, MY_TEAM, ORG_WIDE) - optional, defaults to MY_VIEW
   */
  @AuraEnabled(cacheable=true)
  public static List<OnboardingDTO> getMyActiveOnboarding(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds,
    String viewFilter
  ) {
    // Handle null/empty parameters
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }
    if (String.isBlank(viewFilter)) {
      viewFilter = 'MY_VIEW';
    }
    // Resolve which users should be treated as onboarding owners for this view.
    Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(
      viewFilter
    );
    Date startDate = getStartDateForFilter(timeFilter);

    // Use repository to get filtered onboarding records
    List<Onboarding__c> onboardings = OnboardingRepository.getActiveOnboardingWithFilters(
      ownerUserIds,
      startDate,
      vendorIds,
      programIds,
      20
    );

    // Transform to DTOs
    List<OnboardingDTO> onboardingDTOList = new List<OnboardingDTO>();
    for (Onboarding__c onboardingRecord : onboardings) {
      onboardingDTOList.add(new OnboardingDTO(onboardingRecord));
    }

    return onboardingDTOList;
  }

  /**
   * Get summary statistics for onboarding records
   * Uses CreatedById to show records created by user
   *
   * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   * @param viewFilter View filter (MY_VIEW, MY_TEAM, ORG_WIDE) - optional, defaults to MY_VIEW
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Integer> getOnboardingSummary(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds,
    String viewFilter
  ) {
    // Handle null/empty parameters
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }
    if (String.isBlank(viewFilter)) {
      viewFilter = 'MY_VIEW';
    }

    // Resolve owners for summary view
    Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(
      viewFilter
    );
    Date startDate = getStartDateForFilter(timeFilter);

    // Use repository to get filtered summary statistics
    return OnboardingRepository.getOnboardingSummaryWithFilters(
      ownerUserIds,
      startDate,
      vendorIds,
      programIds
    );
  }

  /**
   * Get eligible accounts that can start new onboarding
   *
   * @param timeFilter Time range filter (optional, not currently used for eligible accounts)
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   */
  @AuraEnabled(cacheable=true)
  public static List<AccountDTO> getEligibleAccounts(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    // timeFilter parameter is accepted but not currently used for eligible accounts
    List<AccountDTO> accountDTOList = new List<AccountDTO>();

    // Get accounts using repository
    List<Account> accounts = AccountRepository.getAccountsForOnboarding(50);

    // For each account, check if there are eligible vendors
    List<Id> accountIds = new List<Id>();
    for (Account accountRecord : accounts) {
      accountIds.add(accountRecord.Id);
    }

    if (!accountIds.isEmpty()) {
      try {
        Map<Id, Integer> accountToVendorCount = OnboardingEligibilityService.getEligibleVendorCountsByAccount(
          accountIds,
          vendorIds,
          programIds
        );

        // Build DTOs for accounts with eligible vendors
        for (Account accountRecord : accounts) {
          Integer eligibleCount = accountToVendorCount.get(accountRecord.Id);
          if (eligibleCount != null && eligibleCount > 0) {
            AccountDTO accountDTO = new AccountDTO();
            accountDTO.Id = accountRecord.Id;
            accountDTO.Name = accountRecord.Name;
            accountDTO.Territory = accountRecord.Territory__c;
            accountDTO.Region = accountRecord.Region__c;
            accountDTO.EligibleVendorCount = eligibleCount;
            accountDTO.RecordUrl = '/' + accountRecord.Id;
            accountDTOList.add(accountDTO);
          }
        }
      } catch (Exception ex) {
        // Log error and return empty list if service fails
        System.debug('Error getting eligible accounts: ' + ex.getMessage());
      }
    }

    return accountDTOList;
  }

  /**
   * Get recent onboarding activity
   * Uses CreatedById to show records created by user
   *
   * @param recordLimit Maximum number of records to return - optional, defaults to 10
   * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   */
  @AuraEnabled(cacheable=true)
  public static List<OnboardingDTO> getRecentActivity(
    Integer recordLimit,
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    // Handle null/empty parameters
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }

    Integer limitValue = recordLimit != null &&
      recordLimit > 0
      ? recordLimit
      : 10;
    Date startDate = getStartDateForFilter(timeFilter);
    // Recent activity uses MY_VIEW (current user only)
    Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(
      'MY_VIEW'
    );

    // Use repository to get filtered recent activity
    List<Onboarding__c> onboardings = OnboardingRepository.getRecentOnboardingWithFilters(
      ownerUserIds,
      startDate,
      vendorIds,
      programIds,
      limitValue
    );

    // Transform to DTOs
    List<OnboardingDTO> onboardingDTOList = new List<OnboardingDTO>();
    for (Onboarding__c onboardingRecord : onboardings) {
      onboardingDTOList.add(new OnboardingDTO(onboardingRecord));
    }

    return onboardingDTOList;
  }

  /**
   * Helper method to get start date for time filter
   */
  private static Date getStartDateForFilter(String timeFilter) {
    if (String.isBlank(timeFilter)) {
      return null;
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
   * Get all active onboarding records (not just user's)
   * Useful for admins/managers
   * Sharing is controlled by Account parent (ControlledByParent)
   */
  @AuraEnabled(cacheable=true)
  public static List<OnboardingDTO> getAllActiveOnboarding() {
    List<Onboarding__c> onboardings = OnboardingRepository.getAllActiveOnboarding(
      50
    );

    List<OnboardingDTO> onboardingDTOList = new List<OnboardingDTO>();
    for (Onboarding__c onboardingRecord : onboardings) {
      onboardingDTOList.add(new OnboardingDTO(onboardingRecord));
    }

    return onboardingDTOList;
  }

  /**
   * Get vendor program health metrics
   * Returns metrics for all active vendor programs or filtered by vendor IDs
   *
   * @param timeFilter Time range filter for onboarding counts - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @return List of VendorProgramMetricsDTO
   */
  @AuraEnabled(cacheable=true)
  public static List<VendorProgramMetricsDTO> getVendorProgramMetrics(
    String timeFilter,
    List<Id> vendorIds
  ) {
    // Handle null/empty parameters
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }

    Date startDate = getStartDateForFilter(timeFilter);

    // Build WHERE clause for vendor programs
    String whereClause = 'Active__c = true';
    if (vendorIds != null && !vendorIds.isEmpty()) {
      whereClause += ' AND Vendor__c IN :vendorIds';
    }

    // Query vendor programs
    String query =
      'SELECT Id, Name, Label__c, Vendor__c, Vendor__r.Name, Status__c, Active__c ' +
      'FROM Vendor_Customization__c WHERE ' +
      whereClause +
      ' ORDER BY Name';

    List<Vendor_Customization__c> programs = Database.query(query);

    if (programs.isEmpty()) {
      return new List<VendorProgramMetricsDTO>();
    }

    Set<Id> programIds = new Set<Id>();
    for (Vendor_Customization__c vendorProgram : programs) {
      programIds.add(vendorProgram.Id);
    }

    // Get onboarding counts
    String onboardingWhere = 'Vendor_Customization__c IN :programIds';
    if (startDate != null) {
      onboardingWhere += ' AND CreatedDate >= :startDate';
    }

    // Count by status
    Map<Id, Map<String, Integer>> countsByProgram = new Map<Id, Map<String, Integer>>();
    String countQuery =
      'SELECT Vendor_Customization__c, Onboarding_Status__c, COUNT(Id) cnt ' +
      'FROM Onboarding__c WHERE ' +
      onboardingWhere +
      ' GROUP BY Vendor_Customization__c, Onboarding_Status__c';

    for (AggregateResult aggregateResult : Database.query(countQuery)) {
      Id programId = (Id) aggregateResult.get('Vendor_Customization__c');
      String status = (String) aggregateResult.get('Onboarding_Status__c');
      Integer count = (Integer) aggregateResult.get('cnt');

      if (!countsByProgram.containsKey(programId)) {
        countsByProgram.put(programId, new Map<String, Integer>());
      }
      countsByProgram.get(programId).put(status, count);
    }

    // Get requirement counts (simplified - would need to query Vendor_Program_Requirement__c)
    // For now, we'll set placeholder values

    // Build DTOs
    List<VendorProgramMetricsDTO> vendorProgramMetricsDTOList = new List<VendorProgramMetricsDTO>();
    for (Vendor_Customization__c vendorProgram : programs) {
      VendorProgramMetricsDTO vendorProgramMetricsDTO = new VendorProgramMetricsDTO();
      vendorProgramMetricsDTO.Id = vendorProgram.Id;
      vendorProgramMetricsDTO.Name = vendorProgram.Name;
      vendorProgramMetricsDTO.Label = vendorProgram.Label__c;
      vendorProgramMetricsDTO.VendorId = vendorProgram.Vendor__c;
      vendorProgramMetricsDTO.VendorName = vendorProgram.Vendor__r != null
        ? vendorProgram.Vendor__r.Name
        : null;
      vendorProgramMetricsDTO.Status = vendorProgram.Status__c;
      vendorProgramMetricsDTO.Active = vendorProgram.Active__c;
      vendorProgramMetricsDTO.RecordUrl = '/' + vendorProgram.Id;

      Map<String, Integer> counts = countsByProgram.get(vendorProgram.Id);
      if (counts != null) {
        vendorProgramMetricsDTO.DealersOnboarded = counts.get(
            'Setup Complete'
          ) != null
          ? counts.get('Setup Complete')
          : 0;
        vendorProgramMetricsDTO.InProgressCount = 0;
        for (String statusValue : counts.keySet()) {
          if (
            statusValue != 'Setup Complete' &&
            statusValue != 'Denied' &&
            statusValue != 'Expired'
          ) {
            vendorProgramMetricsDTO.InProgressCount += counts.get(statusValue);
          }
        }
        vendorProgramMetricsDTO.BlockedCount = counts.get('Denied') != null
          ? counts.get('Denied')
          : 0;
      }

      // TODO: Add requirement counts and validation checks
      vendorProgramMetricsDTO.TotalRequirements = 0;
      vendorProgramMetricsDTO.CompleteRequirements = 0;
      vendorProgramMetricsDTO.RulesEngineValid = true;
      vendorProgramMetricsDTO.DependenciesValid = true;
      vendorProgramMetricsDTO.GroupNames = new List<String>();

      vendorProgramMetricsDTOList.add(vendorProgramMetricsDTO);
    }

    return vendorProgramMetricsDTOList;
  }

  /**
   * Get count of blocked/at-risk onboarding records
   *
   * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   * @return Count of blocked/at-risk onboarding records
   */
  @AuraEnabled(cacheable=true)
  public static Integer getBlockedOnboardingCount(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    // Handle null/empty parameters
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }

    Date startDate = getStartDateForFilter(timeFilter);

    // Build WHERE clause for active onboarding
    String whereClause = 'Onboarding_Status__c != \'Complete\' AND Onboarding_Status__c != \'Expired\'';

    if (startDate != null) {
      whereClause += ' AND CreatedDate >= :startDate';
    }

    if (vendorIds != null && !vendorIds.isEmpty()) {
      whereClause += ' AND Vendor_Customization__r.Vendor__c IN :vendorIds';
    }

    if (programIds != null && !programIds.isEmpty()) {
      whereClause += ' AND Vendor_Customization__c IN :programIds';
    }

    // Query onboarding records with requirements
    String query =
      'SELECT Id, Onboarding_Status__c, Vendor_Customization__c ' +
      'FROM Onboarding__c WHERE ' +
      whereClause;

    List<Onboarding__c> onboardings = Database.query(query);

    if (onboardings.isEmpty()) {
      return 0;
    }

    Set<Id> onboardingIds = new Set<Id>();
    for (Onboarding__c onboardingRecord : onboardings) {
      onboardingIds.add(onboardingRecord.Id);
    }

    // Check for blocked onboarding (has requirements with Denied/Incomplete status)
    // This is a simplified check - full implementation would use OnboardingBlockingDetectionService
    Integer blockedCount = 0;

    // Query requirements with problematic statuses
    // Use AggregateResult since we're using GROUP BY
    List<AggregateResult> blockedReqs = [
      SELECT Onboarding__c
      FROM Onboarding_Requirement__c
      WHERE
        Onboarding__c IN :onboardingIds
        AND Status__c IN ('Denied', 'Incomplete')
      GROUP BY Onboarding__c
    ];

    blockedCount = blockedReqs.size();

    // Also count onboarding with Denied status
    for (Onboarding__c onboardingRecord : onboardings) {
      if (onboardingRecord.Onboarding_Status__c == 'Denied') {
        blockedCount++;
      }
    }

    return blockedCount;
  }

  /**
   * Get IDs of blocked onboarding records
   * Used by At-Risk panel to fetch detailed blocking information
   *
   * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   * @return List of Onboarding__c IDs that are blocked
   */
  @AuraEnabled(cacheable=true)
  public static List<Id> getBlockedOnboardingIds(
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    // Handle null/empty parameters
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }

    Date startDate = getStartDateForFilter(timeFilter);

    // Build WHERE clause for active onboarding
    String whereClause = 'Onboarding_Status__c != \'Complete\' AND Onboarding_Status__c != \'Expired\'';

    if (startDate != null) {
      whereClause += ' AND CreatedDate >= :startDate';
    }

    if (vendorIds != null && !vendorIds.isEmpty()) {
      whereClause += ' AND Vendor_Customization__r.Vendor__c IN :vendorIds';
    }

    if (programIds != null && !programIds.isEmpty()) {
      whereClause += ' AND Vendor_Customization__c IN :programIds';
    }

    // Query onboarding records
    String query =
      'SELECT Id, Onboarding_Status__c ' +
      'FROM Onboarding__c WHERE ' +
      whereClause +
      ' LIMIT 200';

    List<Onboarding__c> onboardings = Database.query(query);

    if (onboardings.isEmpty()) {
      return new List<Id>();
    }

    Set<Id> onboardingIds = new Set<Id>();
    for (Onboarding__c onboardingRecord : onboardings) {
      onboardingIds.add(onboardingRecord.Id);
    }

    // Use blocking detection service to identify blocked onboarding
    List<Id> blockedIds = new List<Id>();
    Set<Id> blockedIdSet = OnboardingBlockingDetectionService.getBlockedOnboardingIds(
      new List<Id>(onboardingIds)
    );
    blockedIds.addAll(blockedIdSet);

    // Also include onboarding with Denied status
    for (Onboarding__c onboardingRecord : onboardings) {
      if (
        onboardingRecord.Onboarding_Status__c == 'Denied' &&
        !blockedIdSet.contains(onboardingRecord.Id)
      ) {
        blockedIds.add(onboardingRecord.Id);
      }
    }

    return blockedIds;
  }

  /**
   * Get team/org onboarding queue
   *
   * @param viewFilter View filter (MY_TEAM, ORG_WIDE) - optional, defaults to MY_TEAM
   * @param timeFilter Time range filter - optional, defaults to LAST_90_DAYS
   * @param vendorIds List of vendor IDs to filter by (optional)
   * @param programIds List of vendor program IDs to filter by (optional)
   * @return List of OnboardingDTO
   */
  @AuraEnabled(cacheable=true)
  public static List<OnboardingDTO> getTeamOnboarding(
    String viewFilter,
    String timeFilter,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    // Handle null/empty parameters
    if (String.isBlank(viewFilter)) {
      viewFilter = 'MY_TEAM';
    }
    if (String.isBlank(timeFilter)) {
      timeFilter = 'LAST_90_DAYS';
    }

    Date startDate = getStartDateForFilter(timeFilter);
    Set<Id> ownerUserIds = OnboardingAccessService.getUserIdsForViewFilter(
      viewFilter
    );

    // Use repository to get filtered team onboarding records
    List<Onboarding__c> onboardings = OnboardingRepository.getActiveOnboardingWithFilters(
      ownerUserIds,
      startDate,
      vendorIds,
      programIds,
      50
    );

    // Transform to DTOs
    List<OnboardingDTO> onboardingDTOList = new List<OnboardingDTO>();
    for (Onboarding__c onboardingRecord : onboardings) {
      onboardingDTOList.add(new OnboardingDTO(onboardingRecord));
    }

    return onboardingDTOList;
  }

  /**
   * Get onboarding records with blocking information
   * Adds blocking reasons and at-risk indicators to onboarding DTOs
   *
   * @param onboardingIds List of onboarding IDs to check
   * @return List of OnboardingWithBlockingDTO
   */
  @AuraEnabled(cacheable=true)
  public static List<OnboardingWithBlockingDTO> getOnboardingWithBlockingInfo(
    List<Id> onboardingIds
  ) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return new List<OnboardingWithBlockingDTO>();
    }

    // Query onboarding records
    List<Onboarding__c> onboardings = [
      SELECT
        Id,
        Name,
        Onboarding_Status__c,
        Account__c,
        Account__r.Name,
        Vendor_Customization__c,
        Vendor_Customization__r.Name,
        CreatedDate,
        LastModifiedDate,
        CreatedById,
        CreatedBy.Name
      FROM Onboarding__c
      WHERE Id IN :onboardingIds
    ];

    // Query requirements to check for blocking
    List<Onboarding_Requirement__c> requirements = [
      SELECT Id, Onboarding__c, Status__c, Vendor_Program_Requirement__c
      FROM Onboarding_Requirement__c
      WHERE Onboarding__c IN :onboardingIds
    ];

    // Build map of onboarding to requirements
    Map<Id, List<Onboarding_Requirement__c>> reqsByOnboarding = new Map<Id, List<Onboarding_Requirement__c>>();
    for (Onboarding_Requirement__c onboardingRequirement : requirements) {
      if (!reqsByOnboarding.containsKey(onboardingRequirement.Onboarding__c)) {
        reqsByOnboarding.put(
          onboardingRequirement.Onboarding__c,
          new List<Onboarding_Requirement__c>()
        );
      }
      reqsByOnboarding.get(onboardingRequirement.Onboarding__c)
        .add(onboardingRequirement);
    }

    // Build DTOs with blocking info
    List<OnboardingWithBlockingDTO> onboardingWithBlockingDTOList = new List<OnboardingWithBlockingDTO>();
    for (Onboarding__c onboardingRecord : onboardings) {
      OnboardingWithBlockingDTO onboardingWithBlockingDTO = new OnboardingWithBlockingDTO(
        onboardingRecord
      );

      // Use blocking detection service
      List<String> blockingReasons = OnboardingBlockingDetectionService.getBlockingReasons(
        onboardingRecord.Id
      );
      if (!blockingReasons.isEmpty()) {
        onboardingWithBlockingDTO.IsBlocked = true;
        onboardingWithBlockingDTO.BlockingReasons.addAll(blockingReasons);
      }

      // Check if at risk (7 days threshold)
      Boolean isAtRisk = OnboardingBlockingDetectionService.isAtRisk(
        onboardingRecord.Id,
        7
      );
      if (isAtRisk) {
        onboardingWithBlockingDTO.IsAtRisk = true;
        if (onboardingWithBlockingDTO.BlockingReasons.isEmpty()) {
          onboardingWithBlockingDTO.BlockingReasons.add(
            'No activity for 7+ days'
          );
        }
      }

      // Check if status is Denied
      if (onboardingRecord.Onboarding_Status__c == 'Denied') {
        onboardingWithBlockingDTO.IsBlocked = true;
        onboardingWithBlockingDTO.BlockingReasons.add(
          'Onboarding status is Denied'
        );
      }

      onboardingWithBlockingDTOList.add(onboardingWithBlockingDTO);
    }

    return onboardingWithBlockingDTOList;
  }

  /**
   * Gets all vendors with their associated vendor programs for hierarchical display.
   * Returns data structured for lightning-tree-grid component.
   */
  @AuraEnabled(cacheable=true)
  public static List<VendorHierarchyDTO> getVendorsWithPrograms() {
    List<Vendor__c> vendors = VendorDomainService.getVendorsWithPrograms();
    return buildVendorHierarchy(vendors);
  }

  /**
   * Searches vendors with programs by name.
   */
  @AuraEnabled(cacheable=true)
  public static List<VendorHierarchyDTO> searchVendorsWithPrograms(
    String searchText
  ) {
    List<Vendor__c> vendors = VendorDomainService.searchVendorsWithPrograms(
      searchText
    );
    return buildVendorHierarchy(vendors);
  }

  /**
   * Builds hierarchical DTO structure for tree-grid display.
   */
  private static List<VendorHierarchyDTO> buildVendorHierarchy(
    List<Vendor__c> vendors
  ) {
    List<VendorHierarchyDTO> hierarchy = new List<VendorHierarchyDTO>();

    for (Vendor__c vendor : vendors) {
      VendorHierarchyDTO vendorDTO = new VendorHierarchyDTO();
      vendorDTO.id = vendor.Id;
      vendorDTO.name = vendor.Name;
      vendorDTO.recordType = 'vendor';
      vendorDTO.status = vendor.Active__c ? 'Active' : 'Inactive';
      vendorDTO.programCount = vendor.Vendor_Customizations__r != null
        ? vendor.Vendor_Customizations__r.size()
        : 0;
      vendorDTO.createdDate = vendor.CreatedDate;
      vendorDTO.lastModifiedDate = vendor.LastModifiedDate;
      vendorDTO.children = new List<VendorHierarchyDTO>();

      // Add vendor programs as children
      if (
        vendor.Vendor_Customizations__r != null &&
        !vendor.Vendor_Customizations__r.isEmpty()
      ) {
        for (
          Vendor_Customization__c program : vendor.Vendor_Customizations__r
        ) {
          VendorHierarchyDTO programDTO = new VendorHierarchyDTO();
          programDTO.id = program.Id;
          programDTO.name = program.Name;
          programDTO.label = program.Label__c;
          programDTO.recordType = 'program';
          programDTO.status = program.Status__c != null
            ? program.Status__c
            : 'Draft';
          programDTO.active = program.Active__c;
          programDTO.retailOption = program.Retail_Option__c;
          programDTO.businessVertical = program.Business_Vertical__c;
          programDTO.createdDate = program.CreatedDate;
          programDTO.lastModifiedDate = program.LastModifiedDate;
          programDTO.lastModifiedBy = program.LastModifiedBy != null
            ? program.LastModifiedBy.Name
            : null;
          programDTO.parentId = vendor.Id;
          programDTO.children = null; // Programs are leaf nodes

          vendorDTO.children.add(programDTO);
        }
      }

      hierarchy.add(vendorDTO);
    }

    return hierarchy;
  }

  /**
   * Get list of active vendors for filter dropdown
   * @return List of vendor options with label and value
   */
  @AuraEnabled(cacheable=true)
  public static List<FilterOption> getVendors() {
    List<FilterOption> filterOptionList = new List<FilterOption>();

    List<Vendor__c> vendors = [
      SELECT Id, Name
      FROM Vendor__c
      WHERE Active__c = TRUE
      ORDER BY Name
      LIMIT 1000
    ];

    for (Vendor__c vendorRecord : vendors) {
      FilterOption filterOption = new FilterOption();
      filterOption.label = vendorRecord.Name;
      filterOption.optionValue = vendorRecord.Id;
      filterOptionList.add(filterOption);
    }

    return filterOptionList;
  }

  /**
   * Get list of active vendor programs for filter dropdown
   * @return List of vendor program options with label and value
   */
  @AuraEnabled(cacheable=true)
  public static List<FilterOption> getVendorPrograms() {
    List<FilterOption> filterOptionList = new List<FilterOption>();

    List<Vendor_Customization__c> programs = [
      SELECT Id, Name, Label__c, Vendor__r.Name
      FROM Vendor_Customization__c
      WHERE Active__c = TRUE
      ORDER BY Name
      LIMIT 1000
    ];

    for (Vendor_Customization__c vendorProgram : programs) {
      FilterOption filterOption = new FilterOption();
      String displayName = String.isNotBlank(vendorProgram.Label__c)
        ? vendorProgram.Label__c
        : vendorProgram.Name;
      if (
        vendorProgram.Vendor__r != null &&
        String.isNotBlank(vendorProgram.Vendor__r.Name)
      ) {
        displayName += ' (' + vendorProgram.Vendor__r.Name + ')';
      }
      filterOption.label = displayName;
      filterOption.optionValue = vendorProgram.Id;
      filterOptionList.add(filterOption);
    }

    return filterOptionList;
  }

  /**
   * DTO for filter dropdown options
   */
  public class FilterOption {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String optionValue;
  }

  /**
   * DTO for vendor hierarchy structure (vendor with nested programs)
   */
  public class VendorHierarchyDTO {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String recordType; // 'vendor' or 'program'
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Boolean active;
    @AuraEnabled
    public Integer programCount;
    @AuraEnabled
    public String retailOption;
    @AuraEnabled
    public String businessVertical;
    @AuraEnabled
    public DateTime createdDate;
    @AuraEnabled
    public DateTime lastModifiedDate;
    @AuraEnabled
    public String lastModifiedBy;
    @AuraEnabled
    public String parentId;
    @AuraEnabled
    public List<VendorHierarchyDTO> children; // Note: Apex doesn't allow _ prefix, will map to _children in JS
  }
}
