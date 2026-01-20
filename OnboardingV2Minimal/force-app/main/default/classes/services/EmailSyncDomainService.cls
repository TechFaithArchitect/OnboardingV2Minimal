/**
 * Consolidated Email Sync Domain Service
 * Combines EmailTemplateSyncService and OrgWideEmailSyncService
 * Phase 4: Domain Service Consolidation
 *
 * Handles all business logic related to:
 * - Email Template synchronization
 * - Org-Wide Email Address synchronization
 */
public with sharing class EmailSyncDomainService {
  // -------------------------------------
  // Config & Test Flags
  // -------------------------------------
  @TestVisible
  private static Boolean forceFail = false;
  @TestVisible
  private static List<OrgWideEmailDTO> testMockDtos;
  public static void setMockDtos(List<OrgWideEmailDTO> dtos) {
    testMockDtos = dtos;
  }
  private static final Integer BATCH_SIZE = 200;

  // ============================================
  // EMAIL TEMPLATE SYNC OPERATIONS
  // Consolidates EmailTemplateSyncService
  // ============================================

  /**
   * Runs the full email template sync with logging
   * Consolidates EmailTemplateSyncOrchestrator logic
   */
  public static void runEmailTemplateSync(Boolean isManual) {
    Datetime start = Datetime.now();
    System.debug('Email Template Sync started at ' + start.format());

    Sync_Log__c logRec = UtilitiesSyncLogHelper.createLogRecord(
      'Full Email Sync',
      isManual
    );

    try {
      EmailSyncDomainService service = new EmailSyncDomainService();
      EmailSyncSummaryDTO summary = service.syncAllTemplates(logRec.Id);

      UtilitiesSyncLogHelper.updateLogRecord(logRec.Id, summary);
      System.debug('Sync completed successfully: ' + summary.toString());
    } catch (Exception ex) {
      UtilitiesSyncLogHelper.markFailed(logRec.Id, ex);
      System.debug('Sync failed: ' + ex.getMessage());
    }

    System.debug('Email Template Sync finished at ' + Datetime.now().format());
  }

  /**
   * Public entry point for email template sync
   */
  public EmailSyncSummaryDTO syncAllTemplates(Id jobId) {
    if (Test.isRunningTest() && forceFail) {
      throw new EmailSyncException('Forced failure in test');
    }

    Datetime startTime = Datetime.now();
    System.debug('🚀 [EmailSyncDomainService] Starting sync at ' + startTime);

    EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
    summary.jobId = jobId;
    summary.jobName = 'Email Template Sync';
    summary.manualRun = false;

    // Step 1️⃣ - Load source & destination data
    List<EmailTemplateDTO> emailTemplateDTOList = EmailTemplateRepository.getAllActiveTemplates();
    Map<String, Email_Template_Catalog__mdt> existingCMDTs = EmailCatalogCMDTRepository.getAllEmailCatalogs();
    Map<String, Communication_Template__c> existingComms = CommunicationTemplateRepository.getAllTemplates();

    // Step 2️⃣ - Compare and build worksets
    List<Metadata.CustomMetadata> newCmdts = new List<Metadata.CustomMetadata>();
    List<Communication_Template__c> communicationTemplatesToInsert = new List<Communication_Template__c>();
    List<Communication_Template__c> communicationTemplatesToUpdate = new List<Communication_Template__c>();

    for (EmailTemplateDTO emailTemplateDTO : emailTemplateDTOList) {
      if (!existingCMDTs.containsKey(emailTemplateDTO.developerName)) {
        newCmdts.add(
          EmailCatalogCMDTRepository.buildCMDT(emailTemplateDTO, jobId)
        );
        summary.newCMDTCount++;
      }

      if (existingComms.containsKey(emailTemplateDTO.developerName)) {
        Communication_Template__c existing = existingComms.get(
          emailTemplateDTO.developerName
        );
        if (emailTemplateDTO.hasChanges(existing)) {
          Communication_Template__c updated = emailTemplateDTO.toSObject(
            existing
          );
          updated.Sync_Job__c = jobId;
          communicationTemplatesToUpdate.add(updated);
          summary.updatedCount++;
        }
      } else {
        Communication_Template__c newRec = emailTemplateDTO.toSObject();
        newRec.Sync_Job__c = jobId;
        communicationTemplatesToInsert.add(newRec);
        summary.insertedCount++;
      }
    }

    // Step 3️⃣ - Persist changes using retry-safe repository method
    if (!communicationTemplatesToInsert.isEmpty()) {
      CommunicationTemplateRepository.saveWithRetry(
        communicationTemplatesToInsert,
        true
      );
    }
    if (!communicationTemplatesToUpdate.isEmpty()) {
      CommunicationTemplateRepository.saveWithRetry(
        communicationTemplatesToUpdate,
        false
      );
    }

    // Step 4️⃣ - Deploy CMDT metadata
    if (!newCmdts.isEmpty()) {
      summary.asyncOperationId = EmailCatalogCMDTRepository.deployMetadata(
        newCmdts
      );
      System.debug(
        '🧩 [CMDT] Deployment enqueued. Async ID: ' + summary.asyncOperationId
      );
    }

    // Step 5️⃣ - Compute duration
    summary.durationSeconds =
      (Datetime.now().getTime() - startTime.getTime()) /
      EmailSyncServiceConstants.MILLISECONDS_TO_SECONDS;
    System.debug(
      '✅ [EmailSyncDomainService] Completed: ' +
        'Inserted=' +
        summary.insertedCount +
        ', Updated=' +
        summary.updatedCount +
        ', New CMDTs=' +
        summary.newCMDTCount +
        ', Duration=' +
        summary.durationSeconds +
        's'
    );

    return summary;
  }

  // ============================================
  // ORG-WIDE EMAIL SYNC OPERATIONS
  // Consolidates OrgWideEmailSyncService
  // ============================================

  /**
   * Runs the full org-wide email sync with logging
   * Consolidates OrgWideEmailSyncOrchestrator logic
   */
  public static void runOrgWideEmailSync(Boolean isManual) {
    Datetime start = Datetime.now();
    System.debug('Org-Wide Email Sync started at ' + start.format());

    Sync_Log__c logRec = UtilitiesSyncLogHelper.createLogRecord(
      'Org-Wide Email Sync',
      isManual
    );

    try {
      EmailSyncSummaryDTO summary = syncAllOrgWideEmails(logRec.Id);

      UtilitiesSyncLogHelper.updateLogRecord(logRec.Id, summary);
      System.debug('Org-Wide Sync completed: ' + summary.toString());
    } catch (Exception ex) {
      UtilitiesSyncLogHelper.markFailed(logRec.Id, ex);
      System.debug('Sync failed: ' + ex.getMessage());
    }

    System.debug('Org-Wide Email Sync finished at ' + Datetime.now().format());
  }

  /**
   * Syncs all org-wide email addresses
   */
  public static EmailSyncSummaryDTO syncAllOrgWideEmails(Id jobId) {
    Datetime start = Datetime.now();
    EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
    summary.jobId = jobId;
    summary.jobName = 'Org-Wide Email Sync';
    summary.manualRun = false;

    // 🔹 Get Source Data
    List<OrgWideEmailDTO> dtos = new List<OrgWideEmailDTO>();
    if (Test.isRunningTest() && testMockDtos != null) {
      dtos = testMockDtos;
    } else {
      List<OrgWideEmailAddress> orgWideEmails = OrgWideEmailAddressRepository.getAll();
      for (OrgWideEmailAddress owa : orgWideEmails) {
        dtos.add(new OrgWideEmailDTO(owa));
      }
    }

    // 🔹 Sync to OrgWideEmail__c
    List<OrgWideEmail__c> sobjects = new List<OrgWideEmail__c>();
    for (OrgWideEmailDTO orgWideEmailDTO : dtos) {
      sobjects.add(orgWideEmailDTO.toSObject());
    }
    OrgWideEmailRepository.upsertEmails(sobjects);

    // 🔹 Sync to CMDT
    Id asyncId = OrgWideEmailCMDTRepository.upsertCMDTs(dtos);
    summary.asyncOperationId = asyncId;
    summary.newCMDTCount = dtos.size();
    summary.durationSeconds =
      (Datetime.now().getTime() - start.getTime()) /
      EmailSyncServiceConstants.MILLISECONDS_TO_SECONDS;

    return summary;
  }

  // -------------------------------------
  // Local Exception
  // -------------------------------------
  public class EmailSyncException extends Exception {
  }
}
