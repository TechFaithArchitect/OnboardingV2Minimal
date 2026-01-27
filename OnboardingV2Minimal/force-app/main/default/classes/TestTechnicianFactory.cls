@isTest
public class TestTechnicianFactory {

    public static TestDataFactoryWrapper.TechnicianUserWrapper create(Boolean doInsert) {
        Account account = TestAccountFactory.create('Technician Account', doInsert);
        Contact contact = TestContactFactory.create('Tech', 'User', account, doInsert);
        User user = TestUserFactory.createTechnicianUser(doInsert, contact);
        ServiceResource serviceResource = TestServiceResourceFactory.create(doInsert, account, contact, user).serviceResource;

        ServiceTerritory parentTerritory = TestServiceResourceFactory.createParentTerritory(doInsert, 'Parent Territory', null);
        ServiceTerritoryMember territoryMember = TestServiceResourceFactory.createTerritoryMember(doInsert, serviceResource, parentTerritory, 'Primary');

        return new TestDataFactoryWrapper.TechnicianUserWrapper(user, contact, serviceResource, territoryMember);
    }
}