@isTest
public class TestTerritoryFactory {

    public static TestDataFactoryWrapper.TerritorySetupWrapper createSetup(Boolean doInsert) {
        Account account = TestAccountFactory.create('Territory Account', doInsert);
        Contact contact = TestContactFactory.create('Terry', 'Territory', account, doInsert);
        User user = TestUserFactory.createStandardUser(doInsert);

        OperatingHours operatingHours = TestWorkFactory.createOperatingHours('Territory Hours', doInsert);

        ServiceTerritory parentServiceTerritory = TestServiceTerritoryFactory.createParent(doInsert, 'Parent Territory', operatingHours);
        ServiceTerritory childServiceTerritory = TestServiceTerritoryFactory.createChild(doInsert, account, parentServiceTerritory);

        ServiceResource serviceResource = TestServiceResourceFactory.create(doInsert, account, contact, user).serviceResource;
        ServiceTerritoryMember serviceTerritoryMember = TestServiceTerritoryMemberFactory.create(doInsert, serviceResource, childServiceTerritory, 'Primary');

        return new TestDataFactoryWrapper.TerritorySetupWrapper(parentServiceTerritory, childServiceTerritory, serviceTerritoryMember);
    }
}