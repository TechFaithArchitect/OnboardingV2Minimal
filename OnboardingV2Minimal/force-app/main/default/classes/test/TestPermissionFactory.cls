@isTest
public class TestPermissionFactory {

    public static PermissionSetAssignment assignPermissionSetToUser(User user, String permissionSetName, Boolean doInsert) {
        Id psId = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1].Id;
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetId = psId
        );
        TestDataFactoryUtil.maybeInsert(psa, doInsert);
        return psa;
    }

    public static PermissionSetAssignment assignPermissionSetGroupToUser(User user, String permissionSetGroupName, Boolean doInsert) {
        Id psgId = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :permissionSetGroupName LIMIT 1].Id;

        if (doInsert) Test.calculatePermissionSetGroup(psgId);

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetGroupId = psgId
        );
        TestDataFactoryUtil.maybeInsert(psa, doInsert);
        return psa;
    }

    public static TestDataFactoryWrapper.PermissionedUserWrapper assignGroupAndReturnWrapper(User user, String groupName, Boolean doInsert) {
        PermissionSetAssignment psa = assignPermissionSetGroupToUser(user, groupName, doInsert);
        return new TestDataFactoryWrapper.PermissionedUserWrapper(user, psa);
    }
}