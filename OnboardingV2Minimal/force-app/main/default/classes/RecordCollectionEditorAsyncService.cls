public with sharing class RecordCollectionEditorAsyncService {
    private class QueuePayload {
        String configKey;
        String recordsJson;

        QueuePayload(String configKey, String recordsJson) {
            this.configKey = configKey;
            this.recordsJson = recordsJson;
        }
    }

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

        List<QueuePayload> payloadsToQueue = new List<QueuePayload>();
        List<Integer> queuedResultIndexes = new List<Integer>();

        for (Integer requestIndex = 0; requestIndex < requests.size(); requestIndex++) {
            QueueRequest requestItem = requests[requestIndex];
            QueueResult resultItem = new QueueResult();
            resultItem.status = 'Ignored';
            resultItem.message = 'Request was null.';

            if (requestItem != null &&
                String.isNotBlank(requestItem.configKey) &&
                String.isNotBlank(requestItem.recordsJson)) {
                payloadsToQueue.add(new QueuePayload(requestItem.configKey, requestItem.recordsJson));
                queuedResultIndexes.add(requestIndex);
                resultItem.status = 'PendingQueue';
                resultItem.message = 'Valid request queued for asynchronous processing.';
            } else {
                resultItem.status = 'InvalidRequest';
                resultItem.message = 'Both configKey and recordsJson are required.';
            }

            results.add(resultItem);
        }

        if (!payloadsToQueue.isEmpty()) {
            String jobId = System.enqueueJob(new CreateRecordsQueueable(payloadsToQueue));
            for (Integer resultIndex : queuedResultIndexes) {
                QueueResult resultItem = results[resultIndex];
                resultItem.status = 'Queued';
                resultItem.jobId = jobId;
                resultItem.message = 'Queued for asynchronous processing.';
            }
        }

        return results;
    }

    public class CreateRecordsQueueable implements Queueable, Finalizer {
        private final List<QueuePayload> payloads;

        public CreateRecordsQueueable(List<QueuePayload> payloads) {
            this.payloads = new List<QueuePayload>();
            if (payloads != null) {
                this.payloads.addAll(payloads);
            }
        }

        public void execute(QueueableContext context) {
            System.attachFinalizer(this);
            for (QueuePayload payload : payloads) {
                if (payload == null) {
                    continue;
                }
                try {
                    RecordCollectionEditorConfigService.CreateFromJsonRequest requestItem =
                        new RecordCollectionEditorConfigService.CreateFromJsonRequest();
                    requestItem.configKey = payload.configKey;
                    requestItem.recordsJson = payload.recordsJson;
                    RecordCollectionEditorConfigService.createRecordsFromJson(
                        new List<RecordCollectionEditorConfigService.CreateFromJsonRequest>{ requestItem }
                    );
                } catch (Exception ex) {
                    LoggingUtil.error(
                        'RecordCollectionEditorAsyncService.CreateRecordsQueueable failed. '
                        + 'ConfigKey=' + String.valueOf(payload.configKey)
                        + ', Exception=' + ex.getTypeName() + ': ' + ex.getMessage()
                    );
                }
            }
        }

        public void execute(FinalizerContext context) {
            if (context == null || context.getResult() != ParentJobResult.UNHANDLED_EXCEPTION) {
                return;
            }
            Exception ex = context.getException();
            LoggingUtil.error(
                'RecordCollectionEditorAsyncService.CreateRecordsQueueable finalizer captured unhandled exception: '
                + (ex == null ? 'Unknown error.' : ex.getTypeName() + ': ' + ex.getMessage())
            );
        }
    }
}
