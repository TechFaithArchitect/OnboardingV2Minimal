/**
 * Repository for Onboarding__c data access operations
 * Handles all SOQL queries and DML operations for Onboarding records
 */
public with sharing class OnboardingRepository {
  /**
   * Updates onboarding records
   * @param onboardings List of Onboarding__c records to update
   */
  public static void updateOnboardings(List<Onboarding__c> onboardings) {
    if (onboardings != null && !onboardings.isEmpty()) {
      update onboardings;
    }
  }

  /**
   * Gets active onboarding records created by a specific user
   * Excludes Complete, Denied, and Expired statuses
   * @param userId The user ID who created the records
   * @param limitCount Maximum number of records to return
   * @return List of Onboarding__c records
   */
  public static List<Onboarding__c> getActiveOnboardingByCreatedBy(
    Id userId,
    Integer limitCount
  ) {
    Integer limitValue = limitCount != null && limitCount > 0 ? limitCount : 20;

    return [
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
      WHERE
        CreatedById = :userId
        AND Onboarding_Status__c != 'Complete'
        AND Onboarding_Status__c != 'Denied'
        AND Onboarding_Status__c != 'Expired'
      ORDER BY LastModifiedDate DESC
      LIMIT :limitValue
    ];
  }

  /**
   * Gets all active onboarding records (not filtered by user)
   * Excludes Complete, Denied, and Expired statuses
   * @param limitCount Maximum number of records to return
   * @return List of Onboarding__c records
   */
  public static List<Onboarding__c> getAllActiveOnboarding(Integer limitCount) {
    Integer limitValue = limitCount != null && limitCount > 0 ? limitCount : 50;

    return [
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
      WHERE
        Onboarding_Status__c != 'Complete'
        AND Onboarding_Status__c != 'Denied'
        AND Onboarding_Status__c != 'Expired'
      ORDER BY LastModifiedDate DESC
      LIMIT :limitValue
    ];
  }

  /**
   * Gets recent onboarding activity for a specific user
   * @param userId The user ID who created the records
   * @param limitCount Maximum number of records to return
   * @return List of Onboarding__c records ordered by LastModifiedDate
   */
  public static List<Onboarding__c> getRecentOnboardingByCreatedBy(
    Id userId,
    Integer limitCount
  ) {
    Integer limitValue = limitCount != null && limitCount > 0 ? limitCount : 10;

    return [
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
      WHERE CreatedById = :userId
      ORDER BY LastModifiedDate DESC
      LIMIT :limitValue
    ];
  }

  /**
   * Gets onboarding summary statistics by status for a specific user
   * @param userId The user ID who created the records
   * @return Map of status to count
   */
  public static Map<String, Integer> getOnboardingSummaryByCreatedBy(
    Id userId
  ) {
    Map<String, Integer> summary = new Map<String, Integer>();

    // Initialize with common statuses
    summary.put('Not Started', 0);
    summary.put('In Process', 0);
    summary.put('Pending Initial Review', 0);
    summary.put('Complete', 0);
    summary.put('Denied', 0);
    summary.put('Expired', 0);
    summary.put('Total', 0);

    // Aggregate query to get counts by status
    List<AggregateResult> aggregateResults = [
      SELECT Onboarding_Status__c status, COUNT(Id) cnt
      FROM Onboarding__c
      WHERE CreatedById = :userId
      GROUP BY Onboarding_Status__c
    ];

    Integer total = 0;
    for (AggregateResult aggregateResult : aggregateResults) {
      String status = (String) aggregateResult.get('status');
      Integer count = (Integer) aggregateResult.get('cnt');
      if (status != null) {
        summary.put(status, count);
        total += count;
      }
    }
    summary.put('Total', total);

    return summary;
  }

  /**
   * Fetches onboarding by ID
   * @param onboardingId Onboarding ID
   * @return Onboarding record or null if not found
   */
  public static Onboarding__c fetchOnboardingById(Id onboardingId) {
    if (onboardingId == null) {
      return null;
    }
    List<Onboarding__c> onboardings = [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];
    return onboardings.isEmpty() ? null : onboardings[0];
  }

  /**
   * Fetches onboardings by IDs
   * @param onboardingIds Set of onboarding IDs
   * @return List of onboarding records
   */
  public static List<Onboarding__c> fetchOnboardingsByIds(
    Set<Id> onboardingIds
  ) {
    if (onboardingIds == null || onboardingIds.isEmpty()) {
      return new List<Onboarding__c>();
    }
    return [
      SELECT Id, Onboarding_Status__c
      FROM Onboarding__c
      WHERE Id IN :onboardingIds
    ];
  }

  /**
   * Gets active onboarding records with comprehensive filtering
   * Excludes Complete, Denied, and Expired statuses
   *
   * @param ownerUserIds Set of User IDs to filter by ownership (Account owner or territory onboarding rep)
   *                      If empty, no ownership filter is applied
   * @param startDate Minimum CreatedDate filter (optional, null = no date filter)
   * @param vendorIds List of Vendor IDs to filter by (optional)
   * @param programIds List of Vendor Program IDs to filter by (optional)
   * @param limitCount Maximum number of records to return (defaults to 20)
   * @return List of Onboarding__c records ordered by LastModifiedDate DESC
   */
  public static List<Onboarding__c> getActiveOnboardingWithFilters(
    Set<Id> ownerUserIds,
    Date startDate,
    List<Id> vendorIds,
    List<Id> programIds,
    Integer limitCount
  ) {
    Integer limitValue = (limitCount != null &&
      limitCount > 0)
      ? limitCount
      : 20;

    // Get Account IDs for ownership filtering (avoids nested subquery issues)
    Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(
      ownerUserIds
    );

    // If we have user IDs but no matching accounts, return empty list
    if (!ownerUserIds.isEmpty() && accountIds.isEmpty()) {
      return new List<Onboarding__c>();
    }

    // Build WHERE clause
    List<String> conditions = new List<String>();

    // Status filter - exclude completed/denied/expired
    conditions.add('Onboarding_Status__c != \'Complete\'');
    conditions.add('Onboarding_Status__c != \'Denied\'');
    conditions.add('Onboarding_Status__c != \'Expired\'');

    // Ownership filter - use Account IDs to avoid nested subquery
    if (!accountIds.isEmpty()) {
      conditions.add('Account__c IN :accountIds');
    }
    // If ownerUserIds is empty (ORG_WIDE), no ownership filter is applied

    // Time filter
    if (startDate != null) {
      conditions.add('CreatedDate >= :startDate');
    }

    // Vendor filter
    if (vendorIds != null && !vendorIds.isEmpty()) {
      conditions.add('Vendor_Customization__r.Vendor__c IN :vendorIds');
    }

    // Program filter
    if (programIds != null && !programIds.isEmpty()) {
      conditions.add('Vendor_Customization__c IN :programIds');
    }

    String whereClause = String.join(conditions, ' AND ');

    // Build and execute query
    String query =
      'SELECT Id, Name, Onboarding_Status__c, Account__c, Account__r.Name, ' +
      'Vendor_Customization__c, Vendor_Customization__r.Name, ' +
      'CreatedDate, LastModifiedDate, CreatedById, CreatedBy.Name ' +
      'FROM Onboarding__c WHERE ' +
      whereClause +
      ' ORDER BY LastModifiedDate DESC LIMIT :limitValue';

    return Database.query(query);
  }

  /**
   * Gets onboarding summary statistics by status with comprehensive filtering
   *
   * @param ownerUserIds Set of User IDs to filter by ownership (Account owner or territory onboarding rep)
   *                      If empty, no ownership filter is applied
   * @param startDate Minimum CreatedDate filter (optional, null = no date filter)
   * @param vendorIds List of Vendor IDs to filter by (optional)
   * @param programIds List of Vendor Program IDs to filter by (optional)
   * @return Map of status to count
   */
  public static Map<String, Integer> getOnboardingSummaryWithFilters(
    Set<Id> ownerUserIds,
    Date startDate,
    List<Id> vendorIds,
    List<Id> programIds
  ) {
    Map<String, Integer> summary = new Map<String, Integer>();

    // Initialize with common statuses
    summary.put('Not Started', 0);
    summary.put('In Process', 0);
    summary.put('Pending Initial Review', 0);
    summary.put('Complete', 0);
    summary.put('Denied', 0);
    summary.put('Expired', 0);
    summary.put('Total', 0);

    // Get Account IDs for ownership filtering (avoids nested subquery issues)
    Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(
      ownerUserIds
    );

    // If we have user IDs but no matching accounts, return empty summary
    if (!ownerUserIds.isEmpty() && accountIds.isEmpty()) {
      return summary; // Already initialized with zeros
    }

    // Build WHERE clause
    List<String> conditions = new List<String>();

    // Ownership filter - use Account IDs to avoid nested subquery
    if (!accountIds.isEmpty()) {
      conditions.add('Account__c IN :accountIds');
    }
    // If ownerUserIds is empty (ORG_WIDE), no ownership filter is applied

    // Time filter
    if (startDate != null) {
      conditions.add('CreatedDate >= :startDate');
    }

    // Vendor filter
    if (vendorIds != null && !vendorIds.isEmpty()) {
      conditions.add('Vendor_Customization__r.Vendor__c IN :vendorIds');
    }

    // Program filter
    if (programIds != null && !programIds.isEmpty()) {
      conditions.add('Vendor_Customization__c IN :programIds');
    }

    // Build WHERE clause - if no conditions, query all records
    String whereClause = '';
    if (!conditions.isEmpty()) {
      whereClause = String.join(conditions, ' AND ');
    }

    // Aggregate query to get counts by status
    String query =
      'SELECT Onboarding_Status__c status, COUNT(Id) cnt ' +
      'FROM Onboarding__c';
    if (String.isNotBlank(whereClause)) {
      query += ' WHERE ' + whereClause;
    }
    query += ' GROUP BY Onboarding_Status__c';

    List<AggregateResult> aggregateResults = Database.query(query);

    Integer total = 0;
    for (AggregateResult aggregateResult : aggregateResults) {
      String status = (String) aggregateResult.get('status');
      Integer count = (Integer) aggregateResult.get('cnt');
      if (status != null) {
        summary.put(status, count);
        total += count;
      }
    }
    summary.put('Total', total);

    return summary;
  }

  /**
   * Gets recent onboarding activity with comprehensive filtering
   *
   * @param ownerUserIds Set of User IDs to filter by ownership (Account owner or territory onboarding rep)
   *                      If empty, no ownership filter is applied
   * @param startDate Minimum LastModifiedDate filter (optional, null = no date filter)
   * @param vendorIds List of Vendor IDs to filter by (optional)
   * @param programIds List of Vendor Program IDs to filter by (optional)
   * @param limitCount Maximum number of records to return (defaults to 10)
   * @return List of Onboarding__c records ordered by LastModifiedDate DESC
   */
  public static List<Onboarding__c> getRecentOnboardingWithFilters(
    Set<Id> ownerUserIds,
    Date startDate,
    List<Id> vendorIds,
    List<Id> programIds,
    Integer limitCount
  ) {
    Integer limitValue = (limitCount != null &&
      limitCount > 0)
      ? limitCount
      : 10;

    // Get Account IDs for ownership filtering (avoids nested subquery issues)
    Set<Id> accountIds = OnboardingAccessService.getAccountIdsForOwners(
      ownerUserIds
    );

    // If we have user IDs but no matching accounts, return empty list
    if (!ownerUserIds.isEmpty() && accountIds.isEmpty()) {
      return new List<Onboarding__c>();
    }

    // Build WHERE clause
    List<String> conditions = new List<String>();

    // Ownership filter - use Account IDs to avoid nested subquery
    if (!accountIds.isEmpty()) {
      conditions.add('Account__c IN :accountIds');
    }
    // If ownerUserIds is empty (ORG_WIDE), no ownership filter is applied

    // Time filter (uses LastModifiedDate for recent activity)
    if (startDate != null) {
      conditions.add('LastModifiedDate >= :startDate');
    }

    // Vendor filter
    if (vendorIds != null && !vendorIds.isEmpty()) {
      conditions.add('Vendor_Customization__r.Vendor__c IN :vendorIds');
    }

    // Program filter
    if (programIds != null && !programIds.isEmpty()) {
      conditions.add('Vendor_Customization__c IN :programIds');
    }

    // Build WHERE clause - if no conditions, query all records
    String whereClause = '';
    if (!conditions.isEmpty()) {
      whereClause = String.join(conditions, ' AND ');
    }

    // Build and execute query
    String query =
      'SELECT Id, Name, Onboarding_Status__c, Account__c, Account__r.Name, ' +
      'Vendor_Customization__c, Vendor_Customization__r.Name, ' +
      'CreatedDate, LastModifiedDate, CreatedById, CreatedBy.Name ' +
      'FROM Onboarding__c';
    if (String.isNotBlank(whereClause)) {
      query += ' WHERE ' + whereClause;
    }
    query += ' ORDER BY LastModifiedDate DESC LIMIT :limitValue';

    return Database.query(query);
  }
}
