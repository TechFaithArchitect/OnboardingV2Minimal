trigger PV_ServiceAppointmentTrigger on ServiceAppointment (before update, after insert, after update, before insert) {
    
    if (trigger.isBefore && trigger.isUpdate) {
        PV_ServiceAppointmentTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (trigger.isAfter && trigger.isInsert) {
        PV_ServiceAppointmentTriggerHandler.updateRelatedWorkOrder(null, Trigger.newMap);
        PV_ServiceAppointmentTriggerHandler.inmediateScheduleAppointment(Trigger.newMap);
        PV_ServiceAppointmentTriggerHandler.handleFirstAvailableSlotStartTime(Trigger.new, null);
    }
    if (trigger.isAfter && trigger.isUpdate) {
        PV_ServiceAppointmentTriggerHandler.updateRelatedWorkOrder(Trigger.oldMap, Trigger.newMap);
        PV_ServiceAppointmentTriggerHandler.handleStatusUpdate(Trigger.oldMap, Trigger.newMap);
        PV_ServiceAppointmentHandler.handleAfterInsertUpdate(Trigger.new);
        PV_ServiceAppointmentTriggerHandler.handleFirstAvailableSlotStartTime(Trigger.new, Trigger.oldMap);
    }
    if (trigger.isBefore && trigger.isInsert){
        PV_ServiceAppointmentTriggerHandler.updateServiceApptFields(Trigger.new);
        PV_ServiceAppointmentTriggerHandler.immediateDealerAssignment(Trigger.new);
        PV_ServiceAppointmentTriggerHandler.assignDealerToAppointments(Trigger.new, null);
    }   
}