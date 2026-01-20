# Troubleshooting Guide

This guide helps you resolve common issues when using Onboarding V2.

## Common Issues and Solutions

### Onboarding Flow Not Appearing

**Symptoms**:
- Vendor Program record page loads but no onboarding flow component
- Blank space where component should be
- Error message about missing component

**Solutions**:
1. **Check Component Configuration**:
   - Verify `vendorProgramOnboardingFlow` component is added to the page
   - Contact administrator to add component if missing
   - Check Lightning page builder for component visibility

2. **Check Process Assignment**:
   - Verify an onboarding process is assigned to the Vendor Program
   - Check `Onboarding_Application_Progress__c` records
   - Ensure process is active

3. **Check Permissions**:
   - Verify you have read access to Vendor Program
   - Check object-level permissions
   - Verify field-level security settings

4. **Browser Issues**:
   - Clear browser cache
   - Try different browser
   - Disable browser extensions
   - Check browser console for errors

### Cannot Navigate Between Stages

**Symptoms**:
- Next/Back buttons not working
- Stuck on a stage
- Navigation doesn't respond

**Solutions**:
1. **Check Stage Configuration**:
   - Verify stages are configured correctly
   - Check `Onboarding_Application_Stage__c` records
   - Ensure component library entries exist

2. **Check Component Availability**:
   - Verify stage components are deployed
   - Check component API names match
   - Ensure components are not in development mode

3. **Refresh and Retry**:
   - Refresh the page
   - Try navigating again
   - Check browser console for JavaScript errors

4. **Check Progress Saving**:
   - Verify progress is being saved
   - Check for save errors in console
   - Try manually saving progress

### Requirements Panel Not Loading

**Symptoms**:
- Requirements panel shows loading spinner indefinitely
- No requirements displayed
- Error message in panel

**Solutions**:
1. **Check Record Context**:
   - Verify you're on an Onboarding record (not Vendor Program)
   - Ensure recordId is set correctly
   - Check that onboarding record exists

2. **Check Permissions**:
   - Verify read access to Onboarding__c
   - Check read access to Onboarding_Requirement__c
   - Verify field-level security

3. **Check Data**:
   - Verify requirements exist for the onboarding
   - Check requirement relationships
   - Ensure vendor program requirements are linked

4. **Check Apex Methods**:
   - Verify `OnboardingRequirementsPanelController.getRequirements` is accessible
   - Check for Apex errors in debug logs
   - Verify method is not blocked by security

### Status Not Updating Automatically

**Symptoms**:
- Requirement statuses updated but onboarding status unchanged
- Status rules not evaluating
- Manual status updates required

**Solutions**:
1. **Check Status Rules Configuration**:
   - Verify status rules engines exist
   - Check that rules are active
   - Ensure rules are linked to correct groups

2. **Check Rule Evaluation**:
   - Verify requirement statuses match rule conditions
   - Check evaluation logic (ALL, ANY, CUSTOM)
   - Review custom expressions for syntax errors

3. **Check Flow Activation**:
   - Verify `Onboarding_Record_Trigger_Update_Onboarding_Status` flow is active
   - Check flow is not bypassed
   - Ensure flow has proper entry criteria

4. **Check Data Relationships**:
   - Verify vendor program groups are linked
   - Check requirement groups are configured
   - Ensure requirements link to vendor program requirements

5. **Manual Trigger**:
   - Try updating a requirement status again
   - Check if status updates on second attempt
   - Review debug logs for evaluation errors

### Error Messages

#### "Process not found"

**Cause**: No onboarding process assigned to vendor program

**Solution**:
- Assign an onboarding process to the Vendor Program
- Create `Onboarding_Application_Progress__c` record
- Link process to vendor program

#### "Component not found"

**Cause**: Stage component doesn't exist or isn't deployed

**Solution**:
- Verify component is deployed
- Check component API name matches
- Ensure component library entry exists

#### "Permission denied"

**Cause**: Insufficient permissions

**Solution**:
- Contact administrator for access
- Check permission sets
- Verify object and field permissions

#### "Invalid stage configuration"

**Cause**: Stage data is missing or incorrect

**Solution**:
- Check `Onboarding_Application_Stage__c` records
- Verify component library links
- Ensure display order is set

### Performance Issues

**Symptoms**:
- Slow page loading
- Delayed status updates
- Timeout errors

**Solutions**:
1. **Check Data Volume**:
   - Reduce number of requirements if excessive
   - Limit number of stages in process
   - Optimize rule conditions

2. **Check Network**:
   - Verify network connection
   - Check for slow API responses
   - Review browser network tab

3. **Check Governor Limits**:
   - Review Apex debug logs
   - Check for SOQL query limits
   - Verify bulkification in code

4. **Optimize Configuration**:
   - Reduce number of active rules
   - Simplify custom expressions
   - Limit requirement groups

### Data Issues

#### Missing Requirements

**Cause**: Requirements not created during onboarding

**Solution**:
- Verify vendor program requirements exist
- Check requirement group configuration
- Ensure requirements are linked to vendor program

#### Duplicate Requirements

**Cause**: Multiple requirement records for same vendor program requirement

**Solution**:
- Review requirement creation logic
- Check for duplicate prevention rules
- Clean up duplicate records if needed

#### Incorrect Status Values

**Cause**: Status picklist values don't match rule expectations

**Solution**:
- Verify status values in requirements match rule conditions
- Check picklist values are correct
- Update rules to match actual status values

## Getting Additional Help

### Before Contacting Support

1. **Document the Issue**:
   - Note exact error messages
   - Capture screenshots
   - Record steps to reproduce

2. **Check Logs**:
   - Review browser console
   - Check Apex debug logs
   - Review flow debug logs

3. **Try Basic Fixes**:
   - Refresh the page
   - Clear browser cache
   - Try different browser
   - Log out and back in

### Contacting Support

When contacting support, provide:

1. **Issue Description**: Clear description of the problem
2. **Steps to Reproduce**: Exact steps that cause the issue
3. **Error Messages**: Full text of any error messages
4. **Screenshots**: Visual evidence of the issue
5. **Environment**: Browser, Salesforce org, user profile
6. **Logs**: Relevant debug logs or console output

### Resources

- [Getting Started Guide](./getting-started.md)
- [Configuration Guide](../setup/configuration.md)
- [Architecture Documentation](../architecture/overview.md)
- [API Reference](../api/apex-api.md)

## Prevention Tips

1. **Regular Maintenance**:
   - Review and update rules periodically
   - Clean up old test data
   - Monitor performance metrics

2. **User Training**:
   - Ensure users understand the workflow
   - Provide training on requirement management
   - Document common procedures

3. **Configuration Management**:
   - Document rule configurations
   - Version control custom expressions
   - Test changes in sandbox first

4. **Monitoring**:
   - Set up alerts for errors
   - Monitor flow failures
   - Track status evaluation issues

## Related Documentation

- [Getting Started](./getting-started.md)
- [Onboarding Workflow](./onboarding-workflow.md)
- [Managing Requirements](./managing-requirements.md)
- [Configuring Rules](./configuring-rules.md)

