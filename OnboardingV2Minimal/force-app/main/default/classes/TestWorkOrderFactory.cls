@isTest
public class TestWorkOrderFactory {

    public static TestDataFactoryWrapper.WorkOrderSetupWrapper createWithTechnician(Boolean doInsert) {
        TestDataFactoryWrapper.TechnicianUserWrapper technicianUserWrapper = TestTechnicianFactory.create(doInsert);
        WorkType workType = TestWorkFactory.createWorkType('Install', doInsert);
        WorkOrder workOrder = TestWorkFactory.createWorkOrder(technicianUserWrapper.user, workType, doInsert);

        return new TestDataFactoryWrapper.WorkOrderSetupWrapper(workOrder, workType, technicianUserWrapper.user);
    }
}