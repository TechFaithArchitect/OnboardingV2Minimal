public with sharing class RecordCollectionEditorAsyncService {
    public class QueueRequest {
        @InvocableVariable(required=true label='Config Key')
        public String configKey;

        @InvocableVariable(required=true label='Records JSON')
        public String recordsJson;
    }

    public class QueueResult {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Job Id')
        public String jobId;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Queue Record Collection DML'
        description='Queues RecordCollectionEditor JSON processing to run asynchronously.'
    )
    public static List<QueueResult> queueRecordCollectionDml(List<QueueRequest> requests) {
        List<QueueResult> results = new List<QueueResult>();
        if (requests == null) {
            return results;
        }

        for (QueueRequest requestItem : requests) {
            QueueResult resultItem = new QueueResult();
            resultItem.status = 'Ignored';
            resultItem.message = 'Request was null.';

            if (requestItem != null &&
                String.isNotBlank(requestItem.configKey) &&
                String.isNotBlank(requestItem.recordsJson)) {
                String jobId = System.enqueueJob(
                    new CreateRecordsQueueable(requestItem.configKey, requestItem.recordsJson)
                );
                resultItem.status = 'Queued';
                resultItem.jobId = jobId;
                resultItem.message = 'Queued for asynchronous processing.';
            } else {
                resultItem.status = 'InvalidRequest';
                resultItem.message = 'Both configKey and recordsJson are required.';
            }

            results.add(resultItem);
        }

        return results;
    }

    public class CreateRecordsQueueable implements Queueable {
        private final String configKey;
        private final String recordsJson;

        public CreateRecordsQueueable(String configKey, String recordsJson) {
            this.configKey = configKey;
            this.recordsJson = recordsJson;
        }

        public void execute(QueueableContext context) {
            try {
                RecordCollectionEditorConfigService.CreateFromJsonRequest requestItem =
                    new RecordCollectionEditorConfigService.CreateFromJsonRequest();
                requestItem.configKey = configKey;
                requestItem.recordsJson = recordsJson;
                RecordCollectionEditorConfigService.createRecordsFromJson(
                    new List<RecordCollectionEditorConfigService.CreateFromJsonRequest>{ requestItem }
                );
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.ERROR,
                    'RecordCollectionEditorAsyncService queue execution failed: ' + ex.getMessage()
                );
            }
        }
    }
}