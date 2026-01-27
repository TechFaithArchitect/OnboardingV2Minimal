@isTest
public class TestServiceTerritoryMemberFactory {

    public static ServiceTerritoryMember create(Boolean doInsert, ServiceResource serviceResource, ServiceTerritory serviceTerritory, String role) {
        ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember(
            ServiceTerritoryId = serviceTerritory.Id,
            ServiceResourceId = serviceResource.Id,
            TerritoryType = role
        );
        TestDataFactoryUtil.maybeInsert(serviceTerritoryMember, doInsert);
        return serviceTerritoryMember;
    }
}