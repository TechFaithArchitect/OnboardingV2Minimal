public with sharing class ScreenFlowQuickActionSObjectType {
    public class Result {
        @InvocableVariable public String sObjectTypeName;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Get SObject Type (Safe)')
    public static List<Result> getTypes(List<Id> recordIds) {
        List<Result> results = new List<Result>();
        if (recordIds == null) {
            return results;
        }

        for (Id recordId : recordIds) {
            results.add(resolveSafely(recordId));
        }
        return results;
    }

    private static Result resolveSafely(Id recordId) {
        Result result = new Result();
        if (recordId == null) {
            result.success = false;
            result.errorMessage = 'Record Id is null.';
            return result;
        }

        try {
            result.sObjectTypeName = recordId.getSObjectType().getDescribe().getName();
            result.success = true;
        } catch (Exception ex) {
            result.success = false;
            result.errorMessage = ex.getMessage();
        }
        return result;
    }
}
