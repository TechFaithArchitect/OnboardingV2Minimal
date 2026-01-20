public with sharing class EmailTemplateSyncFlowAction {
  public class Request {
    @InvocableVariable
    public Boolean runAsManual;
  }

  public class Result {
    @InvocableVariable
    public String message;
  }

  @InvocableMethod(label='Run Full Email Template Sync')
  public static List<Result> run(List<Request> requests) {
    List<Result> syncResultList = new List<Result>();
    Boolean isManual = !requests.isEmpty() && requests[0].runAsManual;

    EmailSyncDomainService.runEmailTemplateSync(isManual);

    Result syncResult = new Result();
    syncResult.message = 'Sync completed manually.';
    syncResultList.add(syncResult);
    return syncResultList;
  }
}
