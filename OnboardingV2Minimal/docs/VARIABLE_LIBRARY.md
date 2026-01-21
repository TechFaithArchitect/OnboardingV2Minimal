# Variable Library - Onboarding Application

This document defines the variable naming conventions for the Onboarding Application to ensure consistency and clarity across all code.

## Core Principle

**All variables must be specific and descriptive.** A reader should be able to understand exactly what each variable represents without ambiguity or needing to think "Do we mean this? or this?"

## General Rules

1. **Avoid single-letter variables** (except in acceptable contexts listed below)
2. **Avoid generic names** like `result`, `data`, `item`, `temp`, `tmp`, `value`, `obj`, `var`
3. **Use full, descriptive names** that clearly indicate the variable's purpose
4. **Be consistent** - use the same naming pattern for similar concepts

## Exception Variables

**Standard:** Always use `ex` for exception variables

```apex
// ✅ CORRECT
try {
    // code
} catch (Exception ex) {
    System.debug('Error: ' + ex.getMessage());
}

// ❌ INCORRECT
} catch (Exception e) {
```

**Specific Exception Types:**
- `TypeException` → `typeEx`
- `QueryException` → `queryEx`
- `DmlException` → `dmlEx`
- `IllegalArgumentException` → `ex` (or `illegalArgEx` if multiple exceptions in same scope)

## Loop Variables

### Generic String Lists
**Acceptable:** `value` for iterating over generic string collections

```apex
// ✅ ACCEPTABLE - Generic string list iteration
for (String value : fallbackValues) {
    options.add(value);
}

for (String value : completionValueList) {
    completionValueSet.add(value.trim());
}
```

### Specific Object Lists
**Use descriptive names** that match the object type

```apex
// ✅ CORRECT
for (Onboarding_Requirement__c onboardingRequirement : requirements) {
    // ...
}

for (Vendor_Program_Requirement__c vendorProgramRequirement : createdRequirements) {
    // ...
}

for (Communication_Template__c communicationTemplate : templates) {
    // ...
}

for (Recipient_Group_Member__c recipientGroupMember : members) {
    // ...
}

// ❌ INCORRECT
for (Onboarding_Requirement__c req : requirements) {
for (Vendor_Program_Requirement__c r : createdRequirements) {
for (Communication_Template__c t : templates) {
```

### Index Variables
**Use descriptive names** based on context

```apex
// ✅ CORRECT
for (Integer batchStartIndex = 0; batchStartIndex < total; batchStartIndex += BATCH_SIZE) {
    // ...
}

for (Integer recordIndex = batchStartIndex; recordIndex < endIndex; recordIndex++) {
    // ...
}

for (Integer resultIndex = 0; resultIndex < saveResults.size(); resultIndex++) {
    // ...
}

for (Integer charIndex = 0; charIndex < expression.length(); charIndex++) {
    // ...
}

for (Integer vendorProgramIndex = 1; vendorProgramIndex < vendorProgramIds.size(); vendorProgramIndex++) {
    // ...
}

for (Integer componentIndex = 0; componentIndex < EXPECTED_COMPONENTS.size(); componentIndex++) {
    // ...
}

// ❌ INCORRECT
for (Integer i = 0; i < total; i++) {
for (Integer j = 0; j < endIndex; j++) {
for (Integer k = 0; k < results.size(); k++) {
```

## Method Parameters

### Generic Object Parameters
**Acceptable:** Generic names for truly generic utility methods

```apex
// ✅ ACCEPTABLE - Generic utility method
private static void addValue(Metadata.CustomMetadata customMetadata, String fieldName, Object value) {
    // value is a generic Object parameter for metadata
}

public static Boolean isPicklistValueValid(String objectApiName, String fieldApiName, String value) {
    // value is a generic string parameter for validation
}
```

### Specific Object Parameters
**Use descriptive names** that match the object type

```apex
// ✅ CORRECT
public static void updateRecord(Vendor_Customization__c vendorCustomizationRecord) {
    // ...
}

public static Id createStatusRule(Onboarding_Status_Rule__c onboardingStatusRule) {
    // ...
}

public static void applyRecipientGroupMemberDefaults(Recipient_Group_Member__c recipientGroupMember) {
    // ...
}

// ❌ INCORRECT
public static void updateRecord(Vendor_Customization__c record) {
public static Id createStatusRule(Onboarding_Status_Rule__c rule) {
```

## Local Variables

### Result Variables
**Use descriptive names** based on what they contain

```apex
// ✅ CORRECT
SaveResult saveResult = new SaveResult();
ValidationResult validationResult = new ValidationResult();
ValidationTestResult validationTestResult = new ValidationTestResult();
BulkCreateRequirementsResult bulkCreateRequirementsResult = new BulkCreateRequirementsResult();
List<Id> junctionIds = new List<Id>();

// ❌ INCORRECT
SaveResult result = new SaveResult();
ValidationResult result = new ValidationResult();
List<Id> result = new List<Id>();
```

### Collection Variables
**Use descriptive names** that indicate the collection type and contents

```apex
// ✅ CORRECT
List<EmailTemplateDTO> emailTemplateDTOList = EmailTemplateRepository.getAllActiveTemplates();
List<Communication_Template__c> communicationTemplatesToInsert = new List<Communication_Template__c>();
List<Communication_Template__c> communicationTemplatesToUpdate = new List<Communication_Template__c>();
List<Vendor_Customization__c> vendorCustomizationRecords = [SELECT ...];
Map<String, Communication_Template__c> templateMap = new Map<String, Communication_Template__c>();
List<Id> junctionIds = new List<Id>();

// ❌ INCORRECT
List<EmailTemplateDTO> templates = ...;
List<Communication_Template__c> inserts = ...;
List<Communication_Template__c> updates = ...;
List<Vendor_Customization__c> vps = ...;
Map<String, Communication_Template__c> result = ...;
```

### Single Object Variables
**Use descriptive names** that match the object type

```apex
// ✅ CORRECT
Onboarding__c onboardingRecord = [SELECT ...];
Vendor_Customization__c vendorProgram = programs.get(recipientGroupAssignment.Vendor_Program__c);
Requirement_Field_Value__c fieldValueRecord = newRecords[0];
Communication_Template__c communicationTemplate = existing.get(key);
Onboarding_Requirement__c onboardingRequirement = scope[0];

// ❌ INCORRECT
Onboarding__c ob = [SELECT ...];
Vendor_Customization__c prog = programs.get(...);
Requirement_Field_Value__c rec = newRecords[0];
Communication_Template__c template = existing.get(key);
```

## DTO Properties

**Use descriptive property names** that clearly indicate their purpose

```apex
// ✅ CORRECT
public class ValidationFailureDTO {
    @AuraEnabled
    public String validationResult;  // Not just "result"
    
    @AuraEnabled
    public String message;
}

public class FilterOption {
    @AuraEnabled
    public String label;
    
    @AuraEnabled
    public String optionValue;  // Not just "value"
}

// ❌ INCORRECT
public class ValidationFailureDTO {
    public String result;  // Too generic
}

public class FilterOption {
    public String value;  // Too generic
}
```

## Repository Pattern Variables

### Query Results
```apex
// ✅ CORRECT
List<Vendor_Customization__c> vendorCustomizationRecords = [SELECT ...];
List<Onboarding_Requirement__c> onboardingRequirements = [SELECT ...];
Map<String, Communication_Template__c> templateMap = new Map<String, Communication_Template__c>();
List<Database.SaveResult> saveResults = Database.insert(records);

// ❌ INCORRECT
List<Vendor_Customization__c> records = [SELECT ...];
List<Onboarding_Requirement__c> reqs = [SELECT ...];
Map<String, Communication_Template__c> result = new Map<String, Communication_Template__c>();
List<Database.SaveResult> results = Database.insert(records);
```

### Loop Variables in Repositories
```apex
// ✅ CORRECT
for (Communication_Template__c communicationTemplate : [SELECT ...]) {
    templateMap.put(communicationTemplate.DeveloperName, communicationTemplate);
}

for (Vendor_Program_Onboarding_Req_Template__c requirementTemplate : templates) {
    // ...
}

for (Database.SaveResult saveResult : saveResults) {
    // ...
}

// ❌ INCORRECT
for (Communication_Template__c rec : [SELECT ...]) {
for (Vendor_Program_Onboarding_Req_Template__c template : templates) {
for (Database.SaveResult r : results) {
```

## Service Layer Variables

### Request/Response Variables
```apex
// ✅ CORRECT
for (RecipientGroupEmailRequestDTO emailRequest : requests) {
    List<String> emails = RecipientGroupEmailOrchestrator.getEmails(emailRequest.vendorProgramId);
    emailResultDTOList.add(new RecipientGroupEmailResultDTO(emails));
}

for (Request validationRequest : requests) {
    ValidationResult validationResult = validate(validationRequest);
}

// ❌ INCORRECT
for (RecipientGroupEmailRequestDTO req : requests) {
for (Request r : requests) {
```

### Processing Variables
```apex
// ✅ CORRECT
Follow_Up_Rule__mdt followUpRule = getRule(fq.Follow_Up_Rule__c);
List<Integer> schedule = parseSchedule(followUpRule != null ? followUpRule.Escalation_Schedule__c : null);
Map<String, Object> providerConfiguration = buildProviderConfig(smsProvider, followUpRule, communicationTemplate);

// ❌ INCORRECT
Follow_Up_Rule__mdt rule = getRule(...);
Map<String, Object> providerConfig = buildProviderConfig(...);
```

## Handler Variables

### Trigger Handler Variables
```apex
// ✅ CORRECT
for (SObject sObjectRecord : newList) {
    Id parentVersionId = (Id) sObjectRecord.get('Previous_Version__c');
}

for (Requirement_Field_Value__c fieldValueRecord : newRecords) {
    // ...
}

for (Account accountRecord : newList) {
    Account oldAccountRecord = oldMap.get(accountRecord.Id);
}

for (AggregateResult aggregateResult : Database.query(q)) {
    // ...
}

// ❌ INCORRECT
for (SObject record : newList) {
for (Requirement_Field_Value__c rec : newRecords) {
for (Account acc : newList) {
for (AggregateResult ar : Database.query(q)) {
```

## Controller Variables

### AuraEnabled Method Variables
```apex
// ✅ CORRECT
SaveResult saveResult = new SaveResult();
ValidationResult validationResult = new ValidationResult();
ValidationTestResult validationTestResult = new ValidationTestResult();
List<OverrideLogDTO> overrideLogDTOList = new List<OverrideLogDTO>();

for (Onboarding_External_Override_Log__c overrideLogRecord : overrideLogRecords) {
    OverrideLogDTO overrideLogDTO = new OverrideLogDTO();
    // ...
}

// ❌ INCORRECT
SaveResult result = new SaveResult();
List<OverrideLogDTO> logs = new List<OverrideLogDTO>();
for (Onboarding_External_Override_Log__c rec : records) {
    OverrideLogDTO dto = new OverrideLogDTO();
}
```

## Common Patterns

### Email Template Variables
```apex
// ✅ CORRECT
List<EmailTemplateDTO> emailTemplateDTOList = ...;
List<Communication_Template__c> communicationTemplatesToInsert = ...;
List<Communication_Template__c> communicationTemplatesToUpdate = ...;
List<Metadata.CustomMetadata> newCustomMetadataRecords = ...;

for (EmailTemplateDTO emailTemplateDTO : emailTemplateDTOList) {
    // ...
}

// ❌ INCORRECT
List<EmailTemplateDTO> templates = ...;
List<Communication_Template__c> inserts = ...;
List<Communication_Template__c> updates = ...;
List<Metadata.CustomMetadata> newCmdts = ...;
for (EmailTemplateDTO dto : templates) {
```

### Requirement Variables
```apex
// ✅ CORRECT
Onboarding_Requirement__c onboardingRequirement = ...;
Vendor_Program_Requirement__c vendorProgramRequirement = ...;
Vendor_Program_Onboarding_Req_Template__c requirementTemplate = ...;

// ❌ INCORRECT
Onboarding_Requirement__c req = ...;
Vendor_Program_Requirement__c r = ...;
Vendor_Program_Onboarding_Req_Template__c template = ...;
```

### Vendor Program Variables
```apex
// ✅ CORRECT
Vendor_Customization__c vendorProgram = ...;
Vendor_Customization__c vendorCustomizationRecord = ...;
List<Vendor_Customization__c> vendorCustomizationRecords = ...;

for (Vendor_Customization__c vendorProgram : programs) {
    // ...
}

// ❌ INCORRECT
Vendor_Customization__c vp = ...;
Vendor_Customization__c prog = ...;
List<Vendor_Customization__c> vps = ...;
for (Vendor_Customization__c vp : programs) {
```

### Status Rule Variables
```apex
// ✅ CORRECT
Onboarding_Status_Rule__c onboardingStatusRule = ...;
Onboarding_Status_Rules_Engine__c statusRulesEngineRecord = ...;
List<Onboarding_Status_Rule__c> statusRules = ...;
Follow_Up_Rule__mdt followUpRule = ...;

// ❌ INCORRECT
Onboarding_Status_Rule__c rule = ...;
Onboarding_Status_Rules_Engine__c r = ...;
List<Onboarding_Status_Rule__c> rules = ...;
Follow_Up_Rule__mdt rule = ...;
```

## Acceptable Generic Uses

The following are **acceptable** generic variable names:

1. **Loop variables for generic string collections:**
   ```apex
   for (String value : fallbackValues) { }
   for (String value : completionValueList) { }
   ```

2. **Generic Object parameters in utility methods:**
   ```apex
   private static void addValue(Metadata.CustomMetadata metadata, String fieldName, Object value) { }
   ```

3. **Property assignments on metadata objects:**
   ```apex
   customValue.value = value;
   customMetadataValue.value = value;
   ```

## Naming Patterns Summary

| Context | Pattern | Example |
|---------|---------|---------|
| Exception variables | `ex`, `typeEx`, `queryEx`, `dmlEx` | `catch (Exception ex)` |
| Loop - Object list | `{ObjectType}Record` or full object name | `onboardingRequirement`, `vendorProgram` |
| Loop - Index | `{context}Index` | `batchStartIndex`, `recordIndex`, `charIndex` |
| Result variables | `{purpose}Result` | `saveResult`, `validationResult` |
| Collection variables | `{type}List` or `{type}Map` or `{type}Set` | `emailTemplateDTOList`, `templateMap` |
| Method parameters | Full object type name | `vendorCustomizationRecord`, `onboardingStatusRule` |
| DTO properties | Descriptive purpose | `validationResult`, `optionValue` |

## Checklist for New Code

When adding new variables, ask:
- [ ] Is the name specific enough that a reader knows exactly what it represents?
- [ ] Could this name be confused with something else?
- [ ] Does it follow the established patterns in this document?
- [ ] Is it consistent with similar variables in the same file?

## Examples of Good vs Bad

### ✅ GOOD Examples
```apex
List<EmailTemplateDTO> emailTemplateDTOList = ...;
SaveResult saveResult = new SaveResult();
for (Onboarding_Requirement__c onboardingRequirement : requirements) { }
for (Integer batchStartIndex = 0; batchStartIndex < total; batchStartIndex++) { }
Vendor_Customization__c vendorProgram = programs.get(id);
```

### ❌ BAD Examples
```apex
List<EmailTemplateDTO> templates = ...;
SaveResult result = new SaveResult();
for (Onboarding_Requirement__c req : requirements) { }
for (Integer i = 0; i < total; i++) { }
Vendor_Customization__c vp = programs.get(id);
```

---

**Last Updated:** 2024
**Maintained By:** Onboarding Application Team
