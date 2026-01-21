public with sharing class OnboardingAppActivationAction {

    public class Request {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String objectApiName;
    }

    @AuraEnabled
    public static void activate(List<Request> requestList) {
        if (requestList == null || requestList.isEmpty()) {
            return;
        }

        // Validate all requests first
        for (Request activationRequest : requestList) {
            if (activationRequest.recordId == null || String.isBlank(activationRequest.objectApiName)) {
                throw new AuraHandledException('Object API Name and Record Id are required.');
            }
        }

        // Group requests by object type for bulk processing
        Map<String, Set<Id>> bulkRecords = new Map<String, Set<Id>>();
        Set<Id> vendorProgramIds = new Set<Id>();

        for (Request activationRequest : requestList) {
            // Vendor_Customization__c uses specialized service with bulk support
            if (activationRequest.objectApiName == 'Vendor_Customization__c') {
                vendorProgramIds.add(activationRequest.recordId);
            } else {
                // Group by object type for bulk processing
                if (!bulkRecords.containsKey(activationRequest.objectApiName)) {
                    bulkRecords.put(activationRequest.objectApiName, new Set<Id>());
                }
                bulkRecords.get(activationRequest.objectApiName).add(activationRequest.recordId);
            }
        }

        // Process vendor programs in bulk
        if (!vendorProgramIds.isEmpty()) {
            VendorProgramActivationService.activateBulk(vendorProgramIds);
        }

        // Process other object types in bulk
        if (!bulkRecords.isEmpty()) {
            OnboardingAppActivationService.activateRecordsBulk(bulkRecords);
        }
    }
}