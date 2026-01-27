@isTest
public class TestWorkFactory {

    public static OperatingHours createOperatingHours(String name, Boolean doInsert) {
        OperatingHours operatingHours = new OperatingHours(Name = name);
        TestDataFactoryUtil.maybeInsert(operatingHours, doInsert);
        return operatingHours;
    }

    public static WorkType createWorkType(String name, Boolean doInsert) {
        WorkType workType = new WorkType(
            Name = name,
            EstimatedDuration = 60,
            ShouldAutoCreateSvcAppt = true
        );
        TestDataFactoryUtil.maybeInsert(workType, doInsert);
        return workType;
    }

    public static WorkOrder createWorkOrder(User user, WorkType workType, Boolean doInsert) {
        WorkOrder workOrder = new WorkOrder(
            Status = 'Unscheduled',
            OwnerId = user.Id,
            WorkTypeId = workType.Id,
            Vendor__c = Label.DIRECTV
        );
        TestDataFactoryUtil.maybeInsert(workOrder, doInsert);
        return workOrder;
    }
}