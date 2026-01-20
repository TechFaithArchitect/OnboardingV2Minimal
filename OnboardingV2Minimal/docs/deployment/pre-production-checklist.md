# Pre-Production Checklist

This checklist ensures all requirements are met before deploying OnboardingV2 to production.

## Test Coverage

### Apex Tests

- [ ] All tests passing (100% pass rate)
- [ ] Test coverage ≥ 75% (Current: 78% ✅)
- [ ] All critical classes have test coverage
- [ ] Test classes cover positive and negative scenarios
- [ ] Test classes test bulk operations
- [ ] Test classes test error handling

**Verification**:
```bash
./scripts/deploy/run-tests.sh [org-alias]
```

### LWC Tests

- [ ] Critical components have Jest tests
- [ ] Test coverage ≥ 80% for LWC components
- [ ] Tests cover user interactions
- [ ] Tests cover event handling
- [ ] Tests mock Apex method calls

**Verification**:
```bash
npm run test:unit:coverage
```

## Code Quality

### Apex Code

- [ ] No SOQL queries in loops
- [ ] All triggers are bulkified
- [ ] All classes use `with sharing` where appropriate
- [ ] Error handling implemented
- [ ] No hardcoded IDs or values
- [ ] Code follows Salesforce best practices

### LWC Components

- [ ] Components are accessible
- [ ] Error handling implemented
- [ ] Loading states displayed
- [ ] No console errors
- [ ] Responsive design
- [ ] Follows Lightning Design System

### Flows

- [ ] All flows are active
- [ ] Flows are bulkified
- [ ] Error handling configured
- [ ] Entry criteria properly set
- [ ] No infinite loops
- [ ] Tested with bulk data

## Documentation

### Technical Documentation

- [ ] Architecture documentation complete
- [ ] API documentation complete
- [ ] Component documentation complete
- [ ] Process documentation complete
- [ ] Data model documented

### User Documentation

- [ ] Getting started guide complete
- [ ] User workflow guides complete
- [ ] Troubleshooting guide complete
- [ ] Configuration guides complete

### Setup Documentation

- [ ] Installation guide complete
- [ ] Configuration guide complete
- [ ] Sample data scripts documented
- [ ] Deployment scripts documented

## Security

### Object Security

- [ ] Sharing models reviewed and documented
- [ ] Field-level security configured
- [ ] Permission sets created and assigned
- [ ] Profiles configured appropriately
- [ ] Security model documented

**Verification**:
- Review `docs/security/security-model.md`
- Verify permission set assignments
- Test with different user profiles

### Apex Security

- [ ] All classes use `with sharing` where appropriate
- [ ] No unnecessary `without sharing` usage
- [ ] FLS enforced in Apex
- [ ] Sharing rules reviewed (if applicable)

## Configuration

### Custom Objects

- [ ] All custom objects deployed
- [ ] Required fields configured
- [ ] Validation rules active
- [ ] Record types configured (if needed)
- [ ] Page layouts configured

### Custom Metadata

- [ ] Global Value Sets configured
- [ ] Custom Labels created
- [ ] Required metadata records created

### Lightning Pages

- [ ] Vendor Program record page configured
- [ ] Onboarding record page configured
- [ ] Components added to pages
- [ ] Page layouts tested

### Flows

- [ ] All flows deployed and active
- [ ] Entry criteria configured
- [ ] Error handling configured
- [ ] Flows tested end-to-end

## Data Setup

### Sample Data (Optional)

- [ ] Sample data scripts tested
- [ ] Sample onboarding process created
- [ ] Sample vendor program created
- [ ] Sample status rules created

### Production Data

- [ ] Production onboarding processes configured
- [ ] Production vendor programs configured
- [ ] Production status rules configured
- [ ] User assignments completed

## Performance

### Query Optimization

- [ ] Queries use indexed fields
- [ ] Relationship queries used where appropriate
- [ ] No queries in loops
- [ ] Query performance acceptable

**Verification**:
- Review `docs/performance/optimization-guide.md`
- Run performance tests
- Monitor debug logs

### Governor Limits

- [ ] SOQL queries < 100 per transaction
- [ ] DML statements < 150 per transaction
- [ ] CPU time within limits
- [ ] Heap size within limits

### Bulkification

- [ ] All triggers bulkified
- [ ] All flows bulkified
- [ ] All Apex methods handle bulk data
- [ ] Batch jobs used for large operations

## Integration

### External Systems

- [ ] API integrations tested
- [ ] Webhook endpoints configured
- [ ] Authentication configured
- [ ] Error handling for integrations

### Internal Systems

- [ ] Salesforce standard objects integrated
- [ ] Custom objects linked correctly
- [ ] Data relationships verified
- [ ] Cross-object formulas working

## User Acceptance Testing

### Test Scenarios

- [ ] Complete onboarding flow tested
- [ ] Requirement management tested
- [ ] Status rules evaluation tested
- [ ] Error scenarios tested
- [ ] Edge cases tested

### User Training

- [ ] End-user documentation provided
- [ ] Training sessions conducted (if applicable)
- [ ] User guides accessible
- [ ] Support contacts identified

## Deployment

### Pre-Deployment

- [ ] Code reviewed and approved
- [ ] Tests passing in sandbox
- [ ] Validation script run successfully
- [ ] Backup of production data (if updating)
- [ ] Deployment plan documented

### Deployment

- [ ] Deployment script tested in sandbox
- [ ] Deployment executed successfully
- [ ] Post-deployment script run
- [ ] Verification completed

### Post-Deployment

- [ ] All components accessible
- [ ] Permission sets assigned
- [ ] Configuration completed
- [ ] Smoke tests passed
- [ ] Users notified

## Monitoring

### Logging

- [ ] Debug logs configured
- [ ] Error logging implemented
- [ ] Performance monitoring enabled
- [ ] Log retention policy set

### Alerts

- [ ] Error alerts configured (if applicable)
- [ ] Performance alerts configured (if applicable)
- [ ] Monitoring dashboard created (if applicable)

## Rollback Plan

### Preparation

- [ ] Rollback procedure documented
- [ ] Previous version available
- [ ] Data backup completed
- [ ] Rollback tested in sandbox

### Execution

- [ ] Rollback triggers identified
- [ ] Rollback steps documented
- [ ] Team trained on rollback procedure

## Sign-Off

### Technical Lead

- [ ] Code review completed
- [ ] Architecture approved
- [ ] Performance acceptable
- [ ] Security reviewed

**Signature**: _________________ **Date**: ___________

### Business Owner

- [ ] Requirements met
- [ ] User acceptance testing passed
- [ ] Documentation complete
- [ ] Training completed

**Signature**: _________________ **Date**: ___________

### Security/Compliance

- [ ] Security review completed
- [ ] Compliance requirements met
- [ ] Data privacy verified
- [ ] Access controls verified

**Signature**: _________________ **Date**: ___________

## Post-Deployment Verification

### Immediate (Within 24 Hours)

- [ ] All critical functions working
- [ ] No error spikes in logs
- [ ] User feedback collected
- [ ] Performance metrics reviewed

### Short-Term (Within 1 Week)

- [ ] Full user acceptance testing completed
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Documentation updated with lessons learned

### Long-Term (Within 1 Month)

- [ ] Usage patterns analyzed
- [ ] Performance optimizations identified
- [ ] User feedback incorporated
- [ ] Continuous improvement plan created

## Related Documentation

- [Installation Guide](../setup/installation.md)
- [Configuration Guide](../setup/configuration.md)
- [Security Model](../security/security-model.md)
- [Performance Guide](../performance/optimization-guide.md)
- [Troubleshooting](../user-guides/troubleshooting.md)

