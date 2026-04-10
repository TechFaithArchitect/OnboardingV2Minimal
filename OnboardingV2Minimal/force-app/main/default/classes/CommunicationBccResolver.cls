public with sharing class CommunicationBccResolver {
  private static final String TOKEN_SPLIT_REGEX = '[,;\\s]+';
  private static final String PUBLIC_GROUP_TYPE = 'Regular';

  public class ResolutionResult {
    public List<String> bccAddresses = new List<String>();
    public List<String> invalidUserIdTokens = new List<String>();
    public List<String> missingGroupDeveloperNames = new List<String>();
    public List<String> warnings = new List<String>();
  }

  public static ResolutionResult resolve(
    String bccUserIdsRaw,
    String bccPublicGroupDeveloperNamesRaw
  ) {
    ResolutionResult result = new ResolutionResult();

    Set<String> userTokens = tokenize(bccUserIdsRaw);
    Set<String> groupDeveloperNameTokens = tokenize(bccPublicGroupDeveloperNamesRaw);

    Set<Id> recipientUserIds = parseUserIds(
      userTokens,
      result.invalidUserIdTokens
    );

    Map<String, Id> groupIdByDeveloperName = resolveGroupIdsByDeveloperName(
      groupDeveloperNameTokens,
      result.warnings
    );
    for (String developerName : groupDeveloperNameTokens) {
      if (!groupIdByDeveloperName.containsKey(developerName)) {
        result.missingGroupDeveloperNames.add(developerName);
      }
    }

    recipientUserIds.addAll(
      resolveUserIdsFromGroups(
        new Set<Id>(groupIdByDeveloperName.values()),
        result.warnings
      )
    );

    result.bccAddresses = resolveUserEmails(recipientUserIds, result.warnings);

    result.invalidUserIdTokens.sort();
    result.missingGroupDeveloperNames.sort();
    result.warnings.sort();
    return result;
  }

  public static List<String> buildDiagnostics(Id templateId, ResolutionResult resolution) {
    List<String> diagnostics = new List<String>();
    if (resolution == null) {
      return diagnostics;
    }

    String templateLabel = templateId == null ? 'unknown template' : String.valueOf(templateId);
    if (!resolution.invalidUserIdTokens.isEmpty()) {
      diagnostics.add(
        'Template ' + templateLabel + ': ignored invalid BCC user Id tokens: ' +
          String.join(resolution.invalidUserIdTokens, ', ')
      );
    }
    if (!resolution.missingGroupDeveloperNames.isEmpty()) {
      diagnostics.add(
        'Template ' + templateLabel + ': BCC public groups not found: ' +
          String.join(resolution.missingGroupDeveloperNames, ', ')
      );
    }
    for (String warning : resolution.warnings) {
      diagnostics.add('Template ' + templateLabel + ': BCC resolution warning: ' + warning);
    }
    return diagnostics;
  }

  private static Set<String> tokenize(String rawValue) {
    Set<String> tokens = new Set<String>();
    if (String.isBlank(rawValue)) {
      return tokens;
    }

    for (String token : rawValue.split(TOKEN_SPLIT_REGEX)) {
      if (String.isBlank(token)) {
        continue;
      }
      tokens.add(token.trim());
    }
    return tokens;
  }

  private static Set<Id> parseUserIds(
    Set<String> userTokens,
    List<String> invalidTokensOut
  ) {
    Set<Id> userIds = new Set<Id>();
    if (userTokens.isEmpty()) {
      return userIds;
    }

    for (String token : userTokens) {
      Id parsedId = tryParseId(token);
      if (parsedId == null || parsedId.getSObjectType() != User.SObjectType) {
        invalidTokensOut.add(token);
        continue;
      }
      userIds.add(parsedId);
    }

    return userIds;
  }

  private static Map<String, Id> resolveGroupIdsByDeveloperName(
    Set<String> developerNames,
    List<String> warningsOut
  ) {
    Map<String, Id> groupIdByName = new Map<String, Id>();
    if (developerNames.isEmpty()) {
      return groupIdByName;
    }

    try {
      for (Group groupRow : [
        SELECT Id, DeveloperName
        FROM Group
        WHERE Type = :PUBLIC_GROUP_TYPE
          AND DeveloperName IN :developerNames
      ]) {
        if (String.isNotBlank(groupRow.DeveloperName)) {
          groupIdByName.put(groupRow.DeveloperName, groupRow.Id);
        }
      }
    } catch (Exception ex) {
      warningsOut.add('Unable to resolve BCC public groups: ' + ex.getMessage());
    }

    return groupIdByName;
  }

  private static Set<Id> resolveUserIdsFromGroups(
    Set<Id> seedGroupIds,
    List<String> warningsOut
  ) {
    Set<Id> recipientUserIds = new Set<Id>();
    if (seedGroupIds.isEmpty()) {
      return recipientUserIds;
    }

    Set<Id> visitedGroupIds = new Set<Id>();
    Set<Id> pendingGroupIds = new Set<Id>(seedGroupIds);

    while (!pendingGroupIds.isEmpty()) {
      visitedGroupIds.addAll(pendingGroupIds);
      Set<Id> nextGroupIds = new Set<Id>();

      List<GroupMember> members = new List<GroupMember>();
      try {
        members = [
          SELECT GroupId, UserOrGroupId
          FROM GroupMember
          WHERE GroupId IN :pendingGroupIds
        ];
      } catch (Exception ex) {
        warningsOut.add('Unable to resolve BCC public group members: ' + ex.getMessage());
        return recipientUserIds;
      }

      for (GroupMember memberRow : members) {
        if (memberRow.UserOrGroupId == null) {
          continue;
        }

        if (memberRow.UserOrGroupId.getSObjectType() == User.SObjectType) {
          recipientUserIds.add(memberRow.UserOrGroupId);
          continue;
        }

        if (
          memberRow.UserOrGroupId.getSObjectType() == Group.SObjectType &&
          !visitedGroupIds.contains(memberRow.UserOrGroupId)
        ) {
          nextGroupIds.add(memberRow.UserOrGroupId);
        }
      }

      pendingGroupIds = nextGroupIds;
    }

    return recipientUserIds;
  }

  private static List<String> resolveUserEmails(
    Set<Id> userIds,
    List<String> warningsOut
  ) {
    List<String> emails = new List<String>();
    if (userIds.isEmpty()) {
      return emails;
    }

    try {
      Set<String> seenNormalizedEmails = new Set<String>();
      for (User userRow : [
        SELECT Email
        FROM User
        WHERE Id IN :userIds
          AND IsActive = true
          AND Email != null
        WITH SECURITY_ENFORCED
      ]) {
        String emailAddress = userRow.Email == null
          ? null
          : userRow.Email.trim();
        if (String.isBlank(emailAddress)) {
          continue;
        }
        String normalizedEmail = emailAddress.toLowerCase();
        if (seenNormalizedEmails.contains(normalizedEmail)) {
          continue;
        }
        seenNormalizedEmails.add(normalizedEmail);
        emails.add(emailAddress);
      }
    } catch (Exception ex) {
      warningsOut.add('Unable to resolve BCC user emails: ' + ex.getMessage());
    }

    emails.sort();
    return emails;
  }

  private static Id tryParseId(String value) {
    if (String.isBlank(value)) {
      return null;
    }
    try {
      return (Id) value.trim();
    } catch (Exception ignored) {
      return null;
    }
  }
}
