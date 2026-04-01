# FAQ — Sales and Business Users

**If something looks broken, start here.** These checks use **records and screens you already have access to** (no Flow Debugger). If you still cannot resolve the issue, gather the items under [What to send when you escalate](#what-to-send-when-you-escalate) and open a ticket; admins use [FAQ — Admins & Platform](./FAQ_ADMINS.md).

## Which section should I use?

- Missing onboarding after create flow: [I finished the create flow but I do not see the onboarding yet](#i-finished-the-create-flow-but-i-do-not-see-the-onboarding-yet)
- Wrong status: [The onboarding status does not match what I think is done](#the-onboarding-status-does-not-match-what-i-think-is-done)
- Missing email: [I expected an email but nothing arrived](#i-expected-an-email-but-nothing-arrived)
- Cannot pick contact: [I cannot select the right contact in the create flow](#i-cannot-select-the-right-contact-in-the-create-flow)

The platform **baseline setup story** (what admins configure before you see a stable program) is [Baseline setup guide](../BASELINE_SETUP_GUIDE.md). If you wonder what a screen or related list **is**, see [Onboarding UI and custom components](../reference/ONBOARDING_UI_AND_CUSTOM_COMPONENTS.md).

**Related guides:** [Sales User Guide](../sales/SALES_USER_GUIDE.md) · [Business User Guide](../business/BUSINESS_USER_GUIDE.md) · [Support and Troubleshooting](./SUPPORT_AND_TROUBLESHOOTING.md) (technical triage matrix)

---

## I finished the create flow but I do not see the onboarding yet

**Check first**

1. **Wait and refresh.** Onboarding creation can run **asynchronously** when performance settings defer the “tail” work (see [System Overview](../technical/SYSTEM_OVERVIEW.md#1-opportunity-led-onboarding-creation)). Wait a minute, refresh the **Opportunity** and **Account**, and open the **Onboarding** related list again.
2. **Confirm you used the correct entry path.** Onboarding should come from the guided create experience (`EXP_Opportunity_SCR_Create_Record` context), not from ad-hoc record creation, so automation stays consistent ([Sales User Guide](../sales/SALES_USER_GUIDE.md)).
3. **Confirm Opportunity, Contract, and Onboarding links.** On the **Onboarding** record (once visible): `Opportunity__c`, `Contract__c`, and `Account__c` should match what you expect ([Sales field guide](../sales/SALES_USER_GUIDE.md#field-guide-for-sales)).

**If still missing:** Escalate with opportunity id, time of submission, and whether any flow error appeared on screen.

---

## The onboarding status does not match what I think is done

**Check first**

1. **Onboarding status is rule-driven**, not something to set by hand. It comes from requirement evidence and ordered status rules ([Business User Guide](../business/BUSINESS_USER_GUIDE.md#understanding-status-changes)).
2. Open **all** related **Onboarding Requirements** — look for any still **not** in a “done” state you expect.
3. Open **Onboarding Requirement Subjects** for stuck rows (wrong contact, not complete, etc.) ([Business User Guide scenario](../business/BUSINESS_USER_GUIDE.md#scenario-1-requirement-looks-complete-but-onboarding-is-not-setup-complete)).

**If still wrong:** Note expected vs actual status, requirement/subject ids, and escalate.

---

## I expected an email but nothing arrived

**Check first**

1. **Correct email address on the contact** you expect to receive the message (and that the contact is the one the policy treats as primary or recipient for that event).
2. **Training reminders** use scheduled automation; lifecycle emails are usually **event-driven** from onboarding state ([Admin Operations Runbook](../admin/ADMIN_OPERATIONS_RUNBOOK.md#communication-configuration-where-to-set-rules)) — your issue might be timing or the wrong event firing, not your inbox.
3. **Spam / quarantine** for the business domain.

**If still no mail:** This usually needs **admin** verification of communication policies and templates. Escalate with onboarding id, which milestone you passed, and expected email type. Point admins at [FAQ — Admins & Platform](./FAQ_ADMINS.md#email-or-training-message-not-sent).

---

## I cannot select the right contact in the create flow

**Check first**

1. **Account–contact relationship** exists and is active.
2. **Role on the relationship** is one the flow allows for primary selection (for example `Principal Owner`, `Owner`, or `Authorized Signer`) ([Sales User Guide](../sales/SALES_USER_GUIDE.md#scenario-3-primary-contact-cannot-be-selected)).
3. **Exactly one primary opportunity contact** where the process requires it ([Sales User Guide](../sales/SALES_USER_GUIDE.md#field-guide-for-sales)).

**If still blocked:** Escalate with account and contact ids.

---

## The flow stopped with an error about vendor or default program

**Check first**

1. **Vendor program** on the onboarding (or selection in the flow) matches what your admin configured ([Business User Guide — default path](../business/BUSINESS_USER_GUIDE.md#scenario-3-default-vendor-fallback-path)).
2. **Fallback** errors often mean **metadata** for default vendor program is missing or inactive — you cannot fix that in the UI; escalate to admin ([Admin Operations Runbook — default vendor](../admin/ADMIN_OPERATIONS_RUNBOOK.md#default-vendor-program-setup)).

---

## Requirements look missing, duplicated, or assigned to the wrong person

**Check first**

1. **Vendor program** on `Onboarding__c` is the one you intended — it defines which **program requirements** expand ([Business User Guide](../business/BUSINESS_USER_GUIDE.md#field-guide-onboarding-record)).
2. For **wrong person**, open the **Onboarding Requirement** and **Subjects**: check fulfillment-related fields and role snapshot ([Business User Guide scenario](../business/BUSINESS_USER_GUIDE.md#scenario-2-responsibility-looks-wrong-wrong-contact-or-missing-subject)).

**If still wrong:** Escalate with onboarding id, requirement id(s), subject id(s).

---

## Can I check technical errors myself?

If your profile includes access to **`Error_Log__c`**, open recent rows filtered to your onboarding or time window ([Support and Troubleshooting](./SUPPORT_AND_TROUBLESHOOTING.md#where-to-look)). If you do **not** see that object, skip this and escalate — only include an Error Log id if someone shared it with you.

---

## What to send when you escalate

- **Onboarding** id (and **Opportunity** id if applicable)
- **Requirement / subject** ids if the issue is about tasks or status
- **What you clicked** (e.g. “ran onboarding create from opportunity X”)
- **Time** (timezone) of the problem
- **Screenshot or exact wording** of any flow error
- **Error_Log\_\_c** id (if you have it)

This matches the [artifact list](./SUPPORT_AND_TROUBLESHOOTING.md#required-artifacts-for-any-ticket) support uses for faster resolution.
