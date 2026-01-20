public with sharing class EmailSyncSummaryDTO {
    public Integer insertedCount     { get; set; }
    public Integer updatedCount      { get; set; }
    public Integer newCMDTCount      { get; set; }
    public Decimal durationSeconds   { get; set; }

    public Id asyncOperationId       { get; set; }

    public String asyncOperationIdStr {
        get {
            return asyncOperationId != null ? String.valueOf(asyncOperationId) : manualAsyncOperationIdStr;
        }
        set {
            manualAsyncOperationIdStr = value;
        }
    }
    private String manualAsyncOperationIdStr;

    public Id jobId        { get; set; }
    public String jobName  { get; set; }
    public Boolean manualRun { get; set; }

    // Default constructor
    public EmailSyncSummaryDTO() {
        insertedCount = 0;
        updatedCount = 0;
        newCMDTCount = 0;
    }

    public EmailSyncSummaryDTO(
        Integer insertedCount,
        Integer updatedCount,
        Integer newCMDTCount,
        Decimal durationSeconds,
        Id asyncOperationId,
        Id jobId,
        String jobName,
        Boolean manualRun
    ) {
        this.insertedCount = insertedCount;
        this.updatedCount = updatedCount;
        this.newCMDTCount = newCMDTCount;
        this.durationSeconds = durationSeconds;
        this.asyncOperationId = asyncOperationId;
        this.jobId = jobId;
        this.jobName = jobName;
        this.manualRun = manualRun;
    }

    public static EmailSyncSummaryDTO build(
        Integer inserted,
        Integer updated,
        Integer cmdts,
        Datetime startTime,
        Id asyncId,
        Id jobId,
        String jobName,
        Boolean manualRun
    ) {
        Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / EmailSyncServiceConstants.MILLISECONDS_TO_SECONDS;
        return new EmailSyncSummaryDTO(inserted, updated, cmdts, duration, asyncId, jobId, jobName, manualRun);
    }

    public override String toString() {
        return 'EmailSyncSummaryDTO [' +
            'inserted=' + insertedCount +
            ', updated=' + updatedCount +
            ', cmdts=' + newCMDTCount +
            ', duration=' + durationSeconds +
            ', asyncOp=' + asyncOperationIdStr +
            ']';
    }
}