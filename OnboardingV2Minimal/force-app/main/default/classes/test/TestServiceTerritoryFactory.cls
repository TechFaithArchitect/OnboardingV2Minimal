@isTest
public class TestServiceTerritoryFactory {

    public static ServiceTerritory createParent(Boolean doInsert, String name, OperatingHours opHrs) {
        ServiceTerritory parentServiceTerritory = new ServiceTerritory(
            Name = name,
            OperatingHoursId = opHrs != null ? opHrs.Id : null,
            IsActive = true
        );
        TestDataFactoryUtil.maybeInsert(parentServiceTerritory, doInsert);
        return parentServiceTerritory;
    }

    public static ServiceTerritory createChild(Boolean doInsert, Account acc, ServiceTerritory parentServiceTerritory) {
        ServiceTerritory childServiceTerritory = new ServiceTerritory(
            Name = acc.Name + ' Territory',
            Account__c = acc.Id,
            ParentTerritoryId = parentServiceTerritory.Id,
            IsActive = true
        );
        TestDataFactoryUtil.maybeInsert(childServiceTerritory, doInsert);
        return childServiceTerritory;
    }
}