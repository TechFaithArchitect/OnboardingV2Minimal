# Performance Optimization Guide

This guide covers performance best practices, optimization strategies, and governor limit management for OnboardingV2.

## Overview

OnboardingV2 is designed with performance in mind, using bulkification patterns, efficient queries, and governor limit awareness. This guide documents current optimizations and provides recommendations for further improvements.

## Current Optimizations

### 1. Bulkification Patterns

#### Apex Classes

All service classes and handlers are bulkified:

**OnboardingRulesService**:
- `getRequirementsByVPR()`: Single query with map building (no loop queries)
- `getVendorProgramGroupIds()`: Single query, iterates results (not querying in loop)
- `getRulesForGroups()`: Uses relationship query to fetch child records in one query

**OnboardingStatusEvaluator**:
- Processes all rules in memory after bulk query
- Single update per onboarding record
- Early returns to avoid unnecessary processing

**OnboardingRuleEvaluator**:
- Uses pre-fetched child relationship data
- In-memory evaluation (no additional queries)
- Efficient map-based lookups

#### Triggers

All triggers use handler pattern with bulkification:

**VendorProgramGroupMemberTrigger**:
- Uses aggregate queries to count in bulk
- Processes all records in single transaction
- No queries in loops

**VersioningTriggerHandler**:
- Bulk queries for parent records
- Map-based lookups for efficiency

### 2. Query Optimization

#### Relationship Queries

**Efficient Pattern** (Used in `getRulesForGroups`):
```apex
SELECT Id, Evaluation_Logic__c, Custom_Evaluation_Logic__c,
    (SELECT Id, Rule_Number__c, Requirement__c, Expected_Status__c 
     FROM Onboarding_Status_Rules__r)
FROM Onboarding_Status_Rules_Engine__c
WHERE Vendor_Program_Group__c IN :groupIds
```

**Benefits**:
- Fetches parent and children in single query
- Reduces total SOQL queries
- Improves performance for nested data

#### Selective Queries

All queries use indexed fields in WHERE clauses:
- `WHERE Onboarding__c = :onboardingId` (indexed)
- `WHERE Vendor_Program_Group__c IN :groupIds` (indexed)
- `WHERE Parent_Rule__c = :engineId` (indexed)

#### Query Result Caching

LWC wire adapters use `@AuraEnabled(cacheable=true)`:
- `getStagesForProcess()` - Cached
- `getProcessDetails()` - Cached
- `getProgress()` - Cached
- `getRequirements()` - Cached

**Benefits**:
- Reduces server round trips
- Improves UI responsiveness
- Leverages browser caching

### 3. Governor Limit Management

#### SOQL Queries

**Current Usage**:
- Status evaluation: ~4-5 queries per evaluation
- Flow initialization: 3 queries (stages, progress, details)
- Rules loading: 1-2 queries per load

**Limits**:
- Synchronous: 100 queries
- Asynchronous: 200 queries
- Current usage well within limits

#### DML Operations

**Current Usage**:
- Status update: 1 DML per evaluation
- Progress save: 2 DMLs (progress + completion log)
- Requirement updates: 1 bulk DML

**Limits**:
- Synchronous: 150 DML statements
- Asynchronous: 200 DML statements
- Current usage well within limits

#### CPU Time

**Optimizations**:
- Early returns in evaluation logic
- Map-based lookups (O(1) complexity)
- In-memory processing where possible

## Performance Best Practices

### 1. SOQL Query Optimization

#### Avoid Queries in Loops

**❌ Bad Pattern**:
```apex
for (Onboarding__c ob : onboardings) {
    List<Onboarding_Requirement__c> reqs = [
        SELECT Id FROM Onboarding_Requirement__c 
        WHERE Onboarding__c = :ob.Id
    ];
}
```

**✅ Good Pattern** (Current Implementation):
```apex
Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
for (Onboarding_Requirement__c req : [
    SELECT Id, Status__c, Vendor_Program_Requirement__c
    FROM Onboarding_Requirement__c
    WHERE Onboarding__c IN :onboardingIds
]) {
    reqByVPR.put(req.Vendor_Program_Requirement__c, req);
}
```

#### Use Relationship Queries

**✅ Current Pattern**:
```apex
SELECT Id, Evaluation_Logic__c,
    (SELECT Id, Rule_Number__c, Requirement__c 
     FROM Onboarding_Status_Rules__r)
FROM Onboarding_Status_Rules_Engine__c
```

**Benefits**:
- Fetches related data in single query
- Reduces total query count
- Improves performance

#### Selective WHERE Clauses

Always use indexed fields:
- Primary keys (Id)
- Lookup fields
- External IDs
- Fields with indexes

### 2. DML Optimization

#### Bulk DML Operations

**✅ Current Pattern**:
```apex
List<Onboarding_Requirement__c> updates = new List<Onboarding_Requirement__c>();
// ... build list
update updates; // Single DML for all records
```

#### Partial Success Handling

**✅ Current Pattern** (in EmailTemplateSyncDMLService):
```apex
List<Database.SaveResult> results = Database.insert(batch, false);
// Process failures individually
```

**Benefits**:
- Allows partial success
- Better error handling
- Retry logic for failed records

### 3. Collection Optimization

#### Use Maps for Lookups

**✅ Current Pattern**:
```apex
Map<Id, Onboarding_Requirement__c> reqByVPR = new Map<Id, Onboarding_Requirement__c>();
// O(1) lookup instead of O(n) loop
Onboarding_Requirement__c req = reqByVPR.get(requirementId);
```

#### Efficient List Operations

**✅ Current Pattern**:
```apex
// Use findIndex for stage lookup
const savedIndex = this.stages.findIndex(stage => stage.Id === progress.Current_Stage__c);
```

### 4. Flow Bulkification

#### Record-Triggered Flows

**Current Implementation**:
- `Onboarding_Record_Trigger_Update_Onboarding_Status`: Bulkified
- Processes all records in trigger context
- Uses bulk queries

**Best Practices**:
- Use $Record variables for single record context
- Use Get Records with collection variables for bulk
- Avoid loops with DML inside

## Performance Monitoring

### Key Metrics to Monitor

1. **SOQL Query Count**
   - Target: < 50 queries per transaction
   - Current: ~5-10 queries per status evaluation
   - Status: ✅ Well optimized

2. **DML Statement Count**
   - Target: < 100 DMLs per transaction
   - Current: 1-2 DMLs per operation
   - Status: ✅ Well optimized

3. **CPU Time**
   - Target: < 10,000ms per transaction
   - Monitor: Expression evaluation in custom rules
   - Status: ✅ Generally efficient

4. **Heap Size**
   - Target: < 6MB per transaction
   - Monitor: Large requirement sets
   - Status: ✅ Generally efficient

### Monitoring Tools

1. **Debug Logs**:
   - Enable Apex Debug logs
   - Monitor SOQL and DML counts
   - Check CPU time usage

2. **Developer Console**:
   - Use Query Plan tool
   - Review execution statistics
   - Check for table scans

3. **Salesforce Optimizer**:
   - Run periodic scans
   - Identify performance issues
   - Review recommendations

## Optimization Recommendations

### High Priority

#### 1. Add Indexes (If Needed)

If queries become slow with large data volumes:

```sql
-- Example: Add index on frequently queried fields
CREATE INDEX idx_vendor_program_group ON Onboarding_Status_Rules_Engine__c(Vendor_Program_Group__c);
```

**Note**: Salesforce automatically creates indexes on:
- Primary keys
- Foreign keys (lookup/master-detail)
- External IDs
- Unique fields

#### 2. Optimize Custom Expression Evaluation

**Current**: `OnboardingExpressionEngine.evaluate()` uses recursive parsing

**Potential Optimization**:
- Cache parsed expressions
- Pre-compile common patterns
- Use more efficient parsing algorithm

#### 3. Batch Processing for Large Datasets

If processing many onboardings:

```apex
// Consider batch job for bulk status evaluation
public class OnboardingStatusEvaluationBatch implements Database.Batchable<SObject> {
    // Process in batches of 200
}
```

### Medium Priority

#### 1. Add Query Result Caching

For frequently accessed, rarely changing data:

```apex
@AuraEnabled(cacheable=true)
public static List<Onboarding_Component_Library__c> getComponentLibrary() {
    // Already cached via @AuraEnabled(cacheable=true)
}
```

#### 2. Optimize LWC Data Loading

**Current**: Sequential wire adapters

**Potential Optimization**:
- Use Promise.all() for parallel loading (already implemented in onboardingFlowEngine)
- Reduce number of wire adapters
- Combine related queries

#### 3. Reduce Nested Queries

**Current**: Some nested relationship queries

**Consider**: Flatten queries if relationship depth becomes an issue

### Low Priority

#### 1. Add Pagination

For large requirement lists:

```apex
@AuraEnabled
public static List<RequirementDTO> getRequirements(Id onboardingId, Integer offset, Integer limit) {
    // Add LIMIT and OFFSET
}
```

#### 2. Lazy Loading

Load stage data on demand:

```javascript
// Load next stage when user clicks Next
async loadNextStage() {
    const stage = await getStageDetails({ stageId: nextStageId });
}
```

## Common Performance Issues

### Issue 1: Slow Status Evaluation

**Symptoms**:
- Status updates take several seconds
- Timeout errors

**Causes**:
- Too many rules engines
- Complex custom expressions
- Large requirement sets

**Solutions**:
1. Review and optimize rule configurations
2. Simplify custom expressions
3. Consider batch processing for bulk updates
4. Add indexes if needed

### Issue 2: Slow Flow Loading

**Symptoms**:
- Onboarding flow takes time to load
- Loading spinner visible for long time

**Causes**:
- Many stages in process
- Large component library
- Network latency

**Solutions**:
1. Optimize stage queries (already using cacheable)
2. Reduce number of stages if possible
3. Use lazy loading for stage components
4. Optimize component initialization

### Issue 3: Governor Limit Errors

**Symptoms**:
- "Too many SOQL queries" errors
- "Too many DML statements" errors

**Causes**:
- Queries in loops (should not occur in current code)
- Bulk operations without proper bulkification
- Nested triggers

**Solutions**:
1. Review code for queries in loops
2. Ensure all triggers are bulkified
3. Use batch jobs for large operations
4. Optimize query patterns

## Performance Testing

### Load Testing Scenarios

1. **Single Onboarding Evaluation**:
   - 1 onboarding
   - 10 requirements
   - 5 rules engines
   - Expected: < 1 second

2. **Bulk Onboarding Evaluation**:
   - 100 onboardings
   - 10 requirements each
   - 5 rules engines each
   - Expected: < 30 seconds (consider batch job)

3. **Flow Initialization**:
   - Process with 10 stages
   - Expected: < 2 seconds

### Performance Benchmarks

**Status Evaluation**:
- Small (1-5 requirements): < 500ms
- Medium (6-20 requirements): < 1s
- Large (21+ requirements): < 2s

**Flow Loading**:
- Small process (1-5 stages): < 1s
- Medium process (6-10 stages): < 2s
- Large process (11+ stages): < 3s

## Code Review Checklist

When reviewing code for performance:

- [ ] No SOQL queries in loops
- [ ] All DML operations are bulkified
- [ ] Queries use indexed fields in WHERE clauses
- [ ] Relationship queries used where appropriate
- [ ] Maps used for lookups instead of nested loops
- [ ] Early returns to avoid unnecessary processing
- [ ] Cacheable methods marked with `@AuraEnabled(cacheable=true)`
- [ ] Triggers use handler pattern
- [ ] Batch jobs used for large operations
- [ ] Error handling doesn't impact performance

## Related Documentation

- [Architecture Overview](../architecture/overview.md)
- [Apex Classes](../components/apex-classes.md)
- [Status Evaluation](../processes/status-evaluation.md)
- [Troubleshooting](../user-guides/troubleshooting.md)

