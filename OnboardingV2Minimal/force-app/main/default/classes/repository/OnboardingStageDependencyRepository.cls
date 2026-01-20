/**
 * Repository for Onboarding Stage Dependency queries and data access.
 * Handles queries for stage dependencies using the Campaign/Campaign Member pattern.
 */
public with sharing class OnboardingStageDependencyRepository {
  /**
   * Gets all dependency rules for a target stage.
   * Returns dependencies where Target_Stage__c matches the given stage ID.
   *
   * @param targetStageId The stage that requires dependencies to be met
   * @return List of dependency rules with their members
   */
  public static List<Onboarding_Application_Stage_Dependency__c> getDependenciesForTargetStage(
    Id targetStageId
  ) {
    if (targetStageId == null) {
      return new List<Onboarding_Application_Stage_Dependency__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Logic_Type__c,
        Required__c,
        Target_Stage__c,
        (
          SELECT Id, Required_Stage__c, Required__c
          FROM Onboarding_App_Stage_Dependency_Members__r
          ORDER BY CreatedDate
        )
      FROM Onboarding_Application_Stage_Dependency__c
      WHERE Target_Stage__c = :targetStageId
      ORDER BY CreatedDate
    ];
  }

  /**
   * Gets all dependency rules for multiple target stages (bulk query).
   *
   * @param targetStageIds Set of stage IDs that require dependencies
   * @return List of dependency rules with their members
   */
  public static List<Onboarding_Application_Stage_Dependency__c> getDependenciesForTargetStages(
    Set<Id> targetStageIds
  ) {
    if (targetStageIds == null || targetStageIds.isEmpty()) {
      return new List<Onboarding_Application_Stage_Dependency__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Logic_Type__c,
        Required__c,
        Target_Stage__c,
        (
          SELECT Id, Required_Stage__c, Required__c
          FROM Onboarding_App_Stage_Dependency_Members__r
          ORDER BY CreatedDate
        )
      FROM Onboarding_Application_Stage_Dependency__c
      WHERE Target_Stage__c IN :targetStageIds
      ORDER BY Target_Stage__c, CreatedDate
    ];
  }

  /**
   * Gets completed stages for a vendor program and process.
   * Returns a set of stage IDs that have been completed.
   *
   * @param vendorProgramId The vendor program ID
   * @param processId The onboarding process ID
   * @return Set of completed stage IDs
   */
  public static Set<Id> getCompletedStageIds(Id vendorProgramId, Id processId) {
    Set<Id> completedIds = new Set<Id>();
    if (vendorProgramId == null || processId == null) {
      return completedIds;
    }
    List<Onboarding_Application_Stage_Completion__c> completions = [
      SELECT Onboarding_Application_Stage__c
      FROM Onboarding_Application_Stage_Completion__c
      WHERE
        Vendor_Program__c = :vendorProgramId
        AND Onboarding_Application_Process__c = :processId
    ];
    for (
      Onboarding_Application_Stage_Completion__c stageCompletion : completions
    ) {
      completedIds.add(stageCompletion.Onboarding_Application_Stage__c);
    }
    return completedIds;
  }

  /**
   * Gets a dependency rule by ID with its members.
   *
   * @param dependencyId The dependency rule ID
   * @return Dependency rule with members, or null if not found
   */
  public static Onboarding_Application_Stage_Dependency__c getDependencyById(
    Id dependencyId
  ) {
    if (dependencyId == null) {
      return null;
    }
    List<Onboarding_Application_Stage_Dependency__c> stageDependencies = [
      SELECT
        Id,
        Name,
        Logic_Type__c,
        Required__c,
        Target_Stage__c,
        (
          SELECT Id, Required_Stage__c, Required__c
          FROM Onboarding_App_Stage_Dependency_Members__r
          ORDER BY CreatedDate
        )
      FROM Onboarding_Application_Stage_Dependency__c
      WHERE Id = :dependencyId
      LIMIT 1
    ];
    return stageDependencies.isEmpty() ? null : stageDependencies[0];
  }
}
