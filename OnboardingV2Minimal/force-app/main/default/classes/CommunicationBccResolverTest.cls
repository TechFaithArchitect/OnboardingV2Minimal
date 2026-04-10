@IsTest
private class CommunicationBccResolverTest {

  @IsTest
  static void resolveIncludesActiveUserEmailsAndFlagsInvalidTokens() {
    User userRow = TestDataFactory.createStandardUser(true);

    CommunicationBccResolver.ResolutionResult result = CommunicationBccResolver.resolve(
      String.valueOf(userRow.Id) + '; notAnId ; ' + String.valueOf(userRow.Id),
      null
    );

    System.assertEquals(1, result.bccAddresses.size());
    System.assertEquals(userRow.Email, result.bccAddresses[0]);
    System.assertEquals(1, result.invalidUserIdTokens.size());
    System.assertEquals('notAnId', result.invalidUserIdTokens[0]);
    System.assertEquals(0, result.missingGroupDeveloperNames.size());
    System.assertEquals(0, result.warnings.size());
  }

  @IsTest
  static void resolveExpandsNestedPublicGroupsAndFlagsMissingNames() {
    User primaryUser = TestDataFactory.createStandardUser(true);
    User secondaryUser = TestDataFactory.createStandardUser(true);

    Group childGroup = createPublicGroup('UT_CHLD');
    Group parentGroup = createPublicGroup('UT_PRNT');
    insert new List<Group>{ childGroup, parentGroup };

    insert new List<GroupMember>{
      new GroupMember(GroupId = childGroup.Id, UserOrGroupId = secondaryUser.Id),
      new GroupMember(GroupId = parentGroup.Id, UserOrGroupId = primaryUser.Id),
      new GroupMember(GroupId = parentGroup.Id, UserOrGroupId = childGroup.Id)
    };

    CommunicationBccResolver.ResolutionResult result = CommunicationBccResolver.resolve(
      null,
      parentGroup.DeveloperName + ', MISSING_GROUP'
    );

    Set<String> addresses = new Set<String>(result.bccAddresses);
    System.assert(addresses.contains(primaryUser.Email));
    System.assert(addresses.contains(secondaryUser.Email));
    System.assertEquals(1, result.missingGroupDeveloperNames.size());
    System.assertEquals('MISSING_GROUP', result.missingGroupDeveloperNames[0]);
    System.assertEquals(0, result.invalidUserIdTokens.size());
  }

  @IsTest
  static void buildDiagnosticsFormatsMessages() {
    CommunicationBccResolver.ResolutionResult resolution = new CommunicationBccResolver.ResolutionResult();
    resolution.invalidUserIdTokens.add('badUserToken');
    resolution.missingGroupDeveloperNames.add('MISSING_GROUP');
    resolution.warnings.add('Synthetic warning');

    List<String> diagnostics = CommunicationBccResolver.buildDiagnostics(
      UserInfo.getUserId(),
      resolution
    );

    System.assertEquals(3, diagnostics.size());
    System.assert(diagnostics[0].contains('ignored invalid BCC user Id tokens'));
    System.assert(diagnostics[1].contains('BCC public groups not found'));
    System.assert(diagnostics[2].contains('BCC resolution warning'));
  }

  private static Group createPublicGroup(String prefix) {
    String suffix = String.valueOf(DateTime.now().getTime()).right(8) +
      String.valueOf(Math.abs(Crypto.getRandomInteger())).left(4);
    return new Group(
      Name = prefix + '_' + suffix,
      DeveloperName = prefix + '_' + suffix,
      Type = 'Regular'
    );
  }
}
