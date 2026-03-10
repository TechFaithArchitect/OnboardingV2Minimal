public with sharing class FlowAdminGuardService {
    public class Request {
        @InvocableVariable(required=true)
        public String message;
    }

    public class FlowAdminGuardException extends Exception {}

    @InvocableMethod(
        label='Fail Fast with Admin Error'
        description='Throws a clear admin-facing flow error when configuration is invalid.'
    )
    public static void failFast(List<Request> requests) {
        String message = 'Flow configuration error. Please review requirement type to record type mappings.';
        if (requests != null && !requests.isEmpty() && !String.isBlank(requests[0].message)) {
            message = requests[0].message;
        }
        throw new FlowAdminGuardException(message);
    }
}
