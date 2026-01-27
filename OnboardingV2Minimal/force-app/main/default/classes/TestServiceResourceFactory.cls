@isTest
public class TestServiceResourceFactory {

    public class ServiceResourceWrapper {
        public ServiceResource serviceResource;
        public ServiceResourceWrapper(ServiceResource sr) { this.serviceResource = sr; }
    }

    public static ServiceResourceWrapper create(Boolean doInsert, Account acc, Contact con, User usr) {
        ServiceResource serviceResource = new ServiceResource(
            Name = usr.Name,
            RelatedRecordId = usr.Id,
            Contact__c = con != null ? con.Id : null,
            AccountId = acc != null ? acc.Id : null,  // if custom field exists
            ResourceType = 'T'
        );

        TestDataFactoryUtil.maybeInsert(serviceResource, doInsert);
        return new ServiceResourceWrapper(serviceResource);
    }

    public static ServiceTerritory createParentTerritory(Boolean doInsert, String name, OperatingHours opHrs) {
        ServiceTerritory parentServiceTerritory = new ServiceTerritory(
            Name = name,
            OperatingHoursId = opHrs.Id,
            IsActive = true
        );
        TestDataFactoryUtil.maybeInsert(parentServiceTerritory, doInsert);
        return parentServiceTerritory;
    }

    public static ServiceTerritory createChildTerritory(Boolean doInsert, Account acc, ServiceTerritory parentServiceTerritory) {
        ServiceTerritory childServiceTerritory = new ServiceTerritory(
            Name = 'Child Territory - ' + acc.Name,
            ParentTerritoryId = parentServiceTerritory.Id,
            Account__c = acc.Id,         
            OperatingHoursId = parentServiceTerritory.OperatingHoursId,
            IsActive = true
        );
        TestDataFactoryUtil.maybeInsert(childServiceTerritory, doInsert);
        return childServiceTerritory;
    }

    public static ServiceTerritoryMember createTerritoryMember(Boolean doInsert, ServiceResource serviceResource, ServiceTerritory serviceTerritory, String territoryType) {
        ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember(
            ServiceResourceId = serviceResource.Id,
            ServiceTerritoryId = serviceTerritory.Id,
            TerritoryType = territoryType, 
            EffectiveStartDate = System.today()
        );

        if (territoryType == 'P') {
            serviceTerritoryMember.PostalCode = '35401';
        }

        TestDataFactoryUtil.maybeInsert(serviceTerritoryMember, doInsert);
        return serviceTerritoryMember;
    }
}