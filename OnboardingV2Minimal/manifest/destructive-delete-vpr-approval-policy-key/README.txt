Remove Vendor_Program_Requirement__c.Approval_Policy_Key__c from the org after this repo is deployed.

Command (requires --manifest when using --post-destructive-changes):
  sf project deploy start \
    --manifest manifest/destructive-delete-vpr-approval-policy-key/package.xml \
    --post-destructive-changes manifest/destructive-delete-vpr-approval-policy-key/destructiveChangesPost.xml \
    --wait 15

If deploy fails with "referenced elsewhere": older Flow versions in the org still use this field.
In Setup > Flows, open each listed flow, remove any reference to Vendor Program Requirement > Approval Policy Key,
save, and deactivate obsolete versions if needed. Then rerun the command above.
