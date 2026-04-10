public with sharing class EmailTemplateSyncService {

  @TestVisible
  private static Boolean forceFail = false;
  private static final Integer BATCH_SIZE = 200;
  private static final Long MILLISECONDS_TO_SECONDS = 1000;
  private static final String DEFAULT_COMMUNICATION_TYPE = 'Custom';

  @TestVisible
  private static List<EmailTemplateDTO> mockDtos;
  @TestVisible
  private static Map<String, Communication_Template__c> mockTemplates;

  public class EmailSyncSummaryDTO {
    public Id jobId;
    public String jobName;
    public Boolean manualRun;
    public Integer insertedCount = 0;
    public Integer updatedCount = 0;
    public Integer newCMDTCount = 0;
    public String asyncOperationId;
    public Long durationSeconds = 0;

    public override String toString() {
      return
        'EmailSyncSummaryDTO(' +
        'jobId=' + String.valueOf(jobId) +
        ', inserted=' + String.valueOf(insertedCount) +
        ', updated=' + String.valueOf(updatedCount) +
        ', newCMDT=' + String.valueOf(newCMDTCount) +
        ', durationSeconds=' + String.valueOf(durationSeconds) +
        ')';
    }
  }

  public class EmailTemplateDTO {
    public String name;
    public String developerName;
    public String subject;
    public String folder;
    public Boolean isActive;
    public String commType;
    public Id templateId;

    public Boolean hasChanges(Communication_Template__c existing) {
      if (existing == null) {
        return true;
      }

      return existing.Name != name ||
        existing.DeveloperName__c != developerName ||
        existing.Email_Subject__c != subject ||
        existing.Folder_Name__c != folder ||
        existing.Active__c != isActive ||
        normalizeTemplateId(existing.Email_Template_Id__c) != normalizeTemplateId(
          templateId == null ? null : String.valueOf(templateId)
        ) ||
        (
          String.isNotBlank(commType) &&
          existing.Communication_Type__c != commType
        );
    }

    public Communication_Template__c toSObject() {
      return toSObject(null);
    }

    public Communication_Template__c toSObject(Communication_Template__c existing) {
      Communication_Template__c output = existing == null
        ? new Communication_Template__c()
        : existing;

      output.Name = name;
      output.DeveloperName__c = developerName;
      output.Email_Subject__c = subject;
      output.Folder_Name__c = folder;
      output.Active__c = isActive == null ? true : isActive;
      output.Email_Template_Id__c = templateId == null ? null : String.valueOf(templateId);

      if (String.isNotBlank(commType)) {
        output.Communication_Type__c = commType;
      } else if (existing == null && String.isBlank(output.Communication_Type__c)) {
        output.Communication_Type__c = DEFAULT_COMMUNICATION_TYPE;
      }

      return output;
    }
  }

  public EmailSyncSummaryDTO syncAllTemplates(Id jobId) {
    if (Test.isRunningTest() && forceFail) {
      throw new EmailSyncException('Forced failure in test');
    }

    Datetime startTime = Datetime.now();
    LoggingUtil.info('EmailTemplateSyncService starting sync at ' + String.valueOf(startTime));

    EmailSyncSummaryDTO summary = new EmailSyncSummaryDTO();
    summary.jobId = jobId;
    summary.jobName = 'Email Template Sync';
    summary.manualRun = false;

    List<EmailTemplateDTO> sourceTemplates = getAllActiveTemplates();
    Map<String, Communication_Template__c> existingComms = getAllTemplates();

    List<Communication_Template__c> toInsert = new List<Communication_Template__c>();
    List<Communication_Template__c> toUpdate = new List<Communication_Template__c>();

    for (EmailTemplateDTO source : sourceTemplates) {
      if (source == null || String.isBlank(source.developerName)) {
        continue;
      }

      if (existingComms.containsKey(source.developerName)) {
        Communication_Template__c existing = existingComms.get(source.developerName);
        if (source.hasChanges(existing)) {
          toUpdate.add(source.toSObject(existing));
          summary.updatedCount++;
        }
      } else {
        toInsert.add(source.toSObject());
        summary.insertedCount++;
      }
    }

    saveWithRetry(toInsert, true);
    saveWithRetry(toUpdate, false);

    summary.durationSeconds =
      (Datetime.now().getTime() - startTime.getTime()) /
      MILLISECONDS_TO_SECONDS;

    LoggingUtil.info(
      'EmailTemplateSyncService completed: ' +
      'Inserted=' + summary.insertedCount +
      ', Updated=' + summary.updatedCount +
      ', New CMDTs=' + summary.newCMDTCount +
      ', Duration=' + summary.durationSeconds + 's'
    );

    return summary;
  }

  private static List<EmailTemplateDTO> getAllActiveTemplates() {
    if (Test.isRunningTest() && mockDtos != null) {
      return cloneDtos(mockDtos);
    }

    List<EmailTemplateDTO> out = new List<EmailTemplateDTO>();
    if (!Schema.sObjectType.EmailTemplate.isAccessible()) {
      return out;
    }

    for (EmailTemplate row : [
      SELECT Id, Name, DeveloperName, Subject, Folder.Name, IsActive
      FROM EmailTemplate
      WHERE IsActive = true
      ORDER BY DeveloperName ASC
    ]) {
      EmailTemplateDTO dto = new EmailTemplateDTO();
      dto.name = row.Name;
      dto.developerName = normalizeDeveloperName(row.DeveloperName, row.Name);
      dto.subject = row.Subject;
      dto.folder = row.Folder == null ? null : row.Folder.Name;
      dto.isActive = row.IsActive;
      dto.commType = DEFAULT_COMMUNICATION_TYPE;
      dto.templateId = row.Id;
      out.add(dto);
    }

    return out;
  }

  private static Map<String, Communication_Template__c> getAllTemplates() {
    if (Test.isRunningTest() && mockTemplates != null) {
      return cloneTemplateMap(mockTemplates);
    }

    Map<String, Communication_Template__c> out = new Map<String, Communication_Template__c>();
    if (!Schema.sObjectType.Communication_Template__c.isAccessible()) {
      return out;
    }

    for (Communication_Template__c row : [
      SELECT
        Id,
        Name,
        DeveloperName__c,
        Email_Subject__c,
        Folder_Name__c,
        Communication_Type__c,
        Active__c,
        Email_Template_Id__c
      FROM Communication_Template__c
      WITH SECURITY_ENFORCED
    ]) {
      String key = normalizeDeveloperName(row.DeveloperName__c, row.Name);
      if (String.isNotBlank(key)) {
        out.put(key, row);
      }
    }

    return out;
  }

  private static void saveWithRetry(List<Communication_Template__c> rows, Boolean isInsert) {
    if (rows == null || rows.isEmpty()) {
      return;
    }

    if (Test.isRunningTest() && mockTemplates != null) {
      for (Communication_Template__c row : rows) {
        String key = normalizeDeveloperName(row.DeveloperName__c, row.Name);
        if (String.isNotBlank(key)) {
          mockTemplates.put(key, row);
        }
      }
      return;
    }

    for (Integer start = 0; start < rows.size(); start += BATCH_SIZE) {
      Integer endExclusive = Math.min(start + BATCH_SIZE, rows.size());
      List<Communication_Template__c> chunk = new List<Communication_Template__c>();
      for (Integer i = start; i < endExclusive; i++) {
        chunk.add(rows[i]);
      }

      Database.SaveResult[] saveResults = isInsert
        ? Database.insert(chunk, false)
        : Database.update(chunk, false);

      for (Integer i = 0; i < saveResults.size(); i++) {
        if (saveResults[i].isSuccess()) {
          continue;
        }
        logDmlErrors(chunk[i], saveResults[i]);
      }
    }
  }

  private static void logDmlErrors(
    Communication_Template__c row,
    Database.SaveResult saveResult
  ) {
    if (saveResult == null || saveResult.getErrors() == null) {
      return;
    }
    for (Database.Error err : saveResult.getErrors()) {
      if (err == null) {
        continue;
      }
      LoggingUtil.error(
        'EmailTemplateSyncService DML error for template ' +
        String.valueOf(row == null ? null : row.DeveloperName__c) +
        ': ' + String.valueOf(err.getStatusCode()) +
        ' - ' + err.getMessage()
      );
    }
  }

  private static String normalizeDeveloperName(String developerName, String fallbackName) {
    String value = String.isBlank(developerName) ? fallbackName : developerName;
    return String.isBlank(value) ? null : value.trim();
  }

  private static String normalizeTemplateId(String idValue) {
    return String.isBlank(idValue) ? null : idValue.trim();
  }

  private static List<EmailTemplateDTO> cloneDtos(List<EmailTemplateDTO> source) {
    List<EmailTemplateDTO> out = new List<EmailTemplateDTO>();
    if (source == null) {
      return out;
    }
    for (EmailTemplateDTO item : source) {
      if (item == null) {
        continue;
      }
      EmailTemplateDTO copy = new EmailTemplateDTO();
      copy.name = item.name;
      copy.developerName = item.developerName;
      copy.subject = item.subject;
      copy.folder = item.folder;
      copy.isActive = item.isActive;
      copy.commType = item.commType;
      copy.templateId = item.templateId;
      out.add(copy);
    }
    return out;
  }

  private static Map<String, Communication_Template__c> cloneTemplateMap(
    Map<String, Communication_Template__c> source
  ) {
    Map<String, Communication_Template__c> out = new Map<String, Communication_Template__c>();
    if (source == null) {
      return out;
    }
    for (String key : source.keySet()) {
      Communication_Template__c value = source.get(key);
      out.put(
        key,
        value == null ? null : value.clone(false, true, false, false)
      );
    }
    return out;
  }

  @TestVisible
  private static void setMockDtosForTest(List<EmailTemplateDTO> dtos) {
    mockDtos = dtos == null ? null : cloneDtos(dtos);
  }

  @TestVisible
  private static void setMockTemplatesForTest(Map<String, Communication_Template__c> templates) {
    mockTemplates = templates == null ? null : cloneTemplateMap(templates);
  }

  @TestVisible
  private static void resetTestState() {
    forceFail = false;
    mockDtos = null;
    mockTemplates = null;
  }

  public class EmailSyncException extends Exception {}
}
