/**
 * Service for resolving "ownership" and visibility for Onboarding__c records.
 *
 * This is intentionally separate from the LWC controller so that:
 * - Ownership rules are defined in one place.
 * - Other entry points (flows, actions, jobs) can reuse the same logic.
 * - Controllers stay thin and delegate business logic to services.
 *
 * ## Ownership Model
 *
 * Onboarding__c is Master-Detail to Account__c, so record-level sharing is
 * controlled by Account. However, for the dashboard we treat multiple users
 * as "owners" of an onboarding:
 *
 * 1. **Account Owner**
 *    - `Account__r.OwnerId` is always considered an owner.
 *
 * 2. **Additional ownership sources**
 *    - For now, ownership is derived only from Account ownership.
 *    - If we reintroduce territory-based ownership in the future, this is
 *      the place to document it.
 *
 * ## View Filters
 *
 * The dashboard supports three view filters that map to sets of user Ids:
 *
 * - `MY_VIEW`  : only the current user
 * - `MY_TEAM`  : current user + all users in their role hierarchy subtree
 * - `ORG_WIDE` : no owner filter; caller sees all records allowed by sharing
 *
 * The public methods in this service expose two concepts:
 *
 * - A **set of user Ids** to be treated as "owners" for a view filter.
 * - A **SOQL WHERE clause fragment** that can be appended to an
 *   `Onboarding__c` query to enforce those ownership rules.
 */
public with sharing class OnboardingAccessService {
  /**
   * Returns the user Ids that should be treated as owners for the given
   * view filter.
   *
   * Ownership rules:
   * - MY_VIEW:   only the current user's Id.
   * - MY_TEAM:   current user + all users in their role hierarchy subtree.
   * - ORG_WIDE:  empty set (no owner filter will be applied).
   *
   * @param viewFilter One of 'MY_VIEW', 'MY_TEAM', 'ORG_WIDE'. Null/blank
   *                   defaults to 'MY_VIEW'.
   * @return Set of User Ids representing owners for this view.
   */
  public static Set<Id> getUserIdsForViewFilter(String viewFilter) {
    String effectiveFilter = String.isBlank(viewFilter)
      ? 'MY_VIEW'
      : viewFilter;
    Id currentUserId = UserInfo.getUserId();

    if (effectiveFilter == 'ORG_WIDE') {
      // Empty set signals that no owner filter should be applied.
      return new Set<Id>();
    }

    if (effectiveFilter == 'MY_TEAM') {
      return getUsersInRoleHierarchy(currentUserId);
    }

    // Default: MY_VIEW
    return new Set<Id>{ currentUserId };
  }

  /**
   * Returns the set of Account IDs that should be considered "owned" by the
   * given user IDs, based on Account ownership and territory assignments.
   *
   * An Account is considered "owned" if the Account's OwnerId is in the userIds set.
   *
   * @param userIds Set of User Ids to treat as owners.
   * @return Set of Account IDs that are owned by the specified users.
   *         Returns empty set if userIds is null/empty.
   */
  public static Set<Id> getAccountIdsForOwners(Set<Id> userIds) {
    Set<Id> accountIds = new Set<Id>();

    if (userIds == null || userIds.isEmpty()) {
      return accountIds;
    }

    // Get Accounts where the owner is in the userIds set.
    for (Account accountRecord : [
      SELECT Id
      FROM Account
      WHERE OwnerId IN :userIds
      LIMIT 10000
    ]) {
      accountIds.add(accountRecord.Id);
    }
    return accountIds;
  }

  /**
   * Builds a SOQL WHERE clause fragment that enforces ownership for
   * Onboarding__c records based on Account ownership and territory
   * onboarding reps.
   *
   * @deprecated This method uses a subquery which causes SOQL errors when
   * combined with other WHERE conditions. Use getAccountIdsForOwners() instead
   * and filter by Account__c IN :accountIds.
   *
   * @param userIds Set of User Ids to treat as owners.
   * @return SOQL WHERE fragment (deprecated - may cause nested subquery errors).
   */
  public static String buildOwnerClauseForOnboarding(Set<Id> userIds) {
    if (userIds == null || userIds.isEmpty()) {
      return '';
    }

    // NOTE: This method is deprecated because it creates nested subqueries
    // that violate SOQL limitations. Use getAccountIdsForOwners() instead.
    //
    // NOTE: This deprecated method only supports Account owner checks.
    // Use getAccountIdsForOwners() for the canonical ownership lookup.
    return '(Account__r.OwnerId IN :userIds)';
  }

  /**
   * Returns all users in the current user's role hierarchy subtree,
   * including the user themself.
   *
   * This is used to power the `MY_TEAM` view:
   * - Starting from the current user's UserRoleId
   * - Traverse child roles recursively
   * - Collect all users whose UserRoleId is in that set of roles
   *
   * @param userId The root user for the hierarchy (usually current user).
   * @return Set of user Ids including the root user and all users in
   *         descendant roles.
   */
  @TestVisible
  private static Set<Id> getUsersInRoleHierarchy(Id userId) {
    Set<Id> roleIds = new Set<Id>();

    // Get the starting role for the user (if any)
    User currentUser = [
      SELECT UserRoleId
      FROM User
      WHERE Id = :userId
      LIMIT 1
    ];

    if (currentUser.UserRoleId != null) {
      Set<Id> toProcess = new Set<Id>{ currentUser.UserRoleId };
      while (!toProcess.isEmpty()) {
        roleIds.addAll(toProcess);

        // Get direct child roles for the current batch.
        List<UserRole> children = [
          SELECT Id
          FROM UserRole
          WHERE ParentRoleId IN :toProcess
        ];

        toProcess = new Set<Id>();
        for (UserRole childRole : children) {
          toProcess.add(childRole.Id);
        }
      }
    }

    // Collect all users in the role hierarchy, including the root user.
    Set<Id> userIds = new Set<Id>{ userId };
    if (!roleIds.isEmpty()) {
      for (User userRecord : [
        SELECT Id
        FROM User
        WHERE UserRoleId IN :roleIds
      ]) {
        userIds.add(userRecord.Id);
      }
    }

    return userIds;
  }

  /**
   * Checks if the current user has System Administrator access.
   *
   * A user is considered an admin if they have:
   * 1. System Administrator profile, OR
   * 2. Customize Application permission (typically admin-level)
   *
   * @return Boolean indicating if current user is an admin
   */
  public static Boolean isCurrentUserAdmin() {
    // Check if user is System Administrator
    Profile userProfile = [
      SELECT Name
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      LIMIT 1
    ];
    if (userProfile.Name == 'System Administrator') {
      return true;
    }

    // Check for Customize Application permission (typically admin-level)
    try {
      PermissionSetAssignment[] assignments = [
        SELECT PermissionSet.PermissionsCustomizeApplication
        FROM PermissionSetAssignment
        WHERE
          AssigneeId = :UserInfo.getUserId()
          AND PermissionSet.PermissionsCustomizeApplication = TRUE
        LIMIT 1
      ];
      return !assignments.isEmpty();
    } catch (Exception ex) {
      // If permission check fails, default to false for security
      return false;
    }
  }
}
