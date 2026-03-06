# Outlook + EAC + ETM Business Requirements Workbook

Use this document to run business discovery workshops for Salesforce with:
- Outlook Calendar integration
- Einstein Activity Capture (EAC)
- Enterprise Territory Management (ETM)
- Shared accounts across multiple sales teams
- Full manager visibility up the role hierarchy

## Purpose

Capture explicit business decisions across three layers:
1. Account access (`ETM`)
2. Activity visibility (`Role Hierarchy + EAC Sharing`)
3. Calendar sync behavior (`Outlook + EAC Sync Settings`)

Important constraint:
- `ETM` controls account access.
- `ETM` does not automatically grant visibility to EAC-captured emails/events.

## Executive Framing

Your future-state design requires aligned decisions in all three layers:

1. Territory model: who can access account records.
2. Visibility model: who can see meetings and emails.
3. Sync model: what syncs between Outlook and Salesforce, and in which direction.

If these are designed separately, users will experience inconsistent visibility and reporting gaps.

## 1. Territory Model Requirements (Account Sharing)

### Territory structure
- What defines a territory: geography, industry, named accounts, revenue bands, or hybrid?
- Can an account belong to multiple territories?
- Are overlay teams represented as separate territories?
- Are there strategic/global account carve-outs?

### Account ownership and edit rights
- For shared accounts, who is the primary owner?
- Who can edit account fields?
- Who can create and edit opportunities?
- Should ETM assignment rules auto-grant view/edit rights?

### Visibility expectations
- Should managers see all accounts in their territory or only direct-report ownership?
- Should territory hierarchy mirror role hierarchy exactly?
- Are there cross-functional teams that must see account data without role-line management?

## 2. Einstein Activity Capture (EAC) Design Questions

EAC activities are not identical to standard `Task` and `Event` behavior. Visibility and reporting expectations must be explicit.

### A. Outlook sync strategy
- Scope: events only, or emails plus events?
- Direction: one-way or two-way sync?
- Should Salesforce-created events write back to Outlook?
- Should Outlook meetings auto-associate to Accounts, Opportunities, or Contacts?
- Should association be automatic, suggested, or manual?

### B. Activity visibility requirements
- Should same-level peers in the same territory see each other’s meetings?
- Should same-level peers see each other’s captured emails?
- Should first-line managers see all subordinate captured activity?
- Should directors and VPs see all subordinate captured activity?
- Should overlay teams see core AE activity?

Key design reminder:
- Role hierarchy drives default EAC visibility.
- Territory membership alone does not guarantee EAC visibility.
- Same-level collaboration typically requires specific EAC sharing configuration and/or use of standard activities.

### C. Notes and collaboration strategy
- Are users standardizing on Enhanced Notes?
- Should notes be collaborative or private by default?
- Must notes and activity summaries be reportable in Salesforce dashboards?
- Are compliance notes required on account timeline for audit?

## 3. Role Hierarchy and Visibility Alignment

Validate that role hierarchy supports intended manager visibility:
- Is role hierarchy aligned with management reporting?
- Which overlay leaders require visibility but are outside direct reporting chains?
- Are there matrix organizations where manager visibility must cross role branches?

Decision required:
- Visibility model = role hierarchy only, territory plus manual sharing, or hybrid model.

## 4. Conflict and Edge Cases

Define expected behavior for each scenario:

### Scenario 1: Two reps in same territory
- Should they see each other’s Outlook meetings?
- If yes, does this include all meeting details or only subject/time?

### Scenario 2: Account in two territories
- Should both reps see all activity on that account?
- Or only activities where they are attendee/owner?

### Scenario 3: Rep leaves company
- What happens to historical captured activity?
- Who inherits visibility and ownership context?

### Scenario 4: Strategic account restrictions
- Which activities must remain restricted even for shared teams?
- Are executive/private meetings excluded from broad visibility?

## 5. Reporting Expectations

Confirm reporting requirements up front:
- Do executives require activity KPIs in Salesforce dashboards?
- Are metrics needed by territory, manager, rep, and account segment?
- Is meeting volume required for pipeline reviews?
- Is email engagement required for performance scorecards?

Important:
- EAC timeline data has different reporting behavior than standard activities.
- If full native reporting is mandatory, include configuration choices that store/report needed activity data in Salesforce.

## 6. Governance Model

Define ownership and operating cadence:
- Who owns Outlook connection policy enforcement?
- Who owns EAC licensing and assignment?
- Who owns territory design and realignment?
- Who approves activity sharing policy changes?
- How often are territory models activated?
- Is sandbox testing required before each ETM activation?

## 7. Technical Architecture Alignment Checklist

Use confirmed business decisions to drive:
- Account OWD and sharing model
- ETM hierarchy and assignment rules
- Role hierarchy alignment and exceptions
- EAC sharing settings
- Outlook deployment and sync configuration
- Decision on storing events in Salesforce for reporting
- Opportunity/Account Teams usage for collaboration

## Common Pitfalls to Avoid

1. Assuming territory access equals activity visibility.
2. Leaving role hierarchy misaligned with management visibility requirements.
3. Expecting complete standard activity reporting from pure EAC capture.
4. Not defining same-level peer visibility rules.
5. Overlooking overlay team access to activity context.

## 12 Critical Business Questions

1. Can accounts belong to multiple territories?
2. Who is primary owner versus shared collaborator?
3. Should peers in the same territory see each other’s meetings?
4. Should managers see all subordinate Outlook events?
5. Should directors and VPs see all subordinate activity?
6. Should overlay teams see core AE activity?
7. Are activity metrics required in executive dashboards?
8. Should emails sync, or events only?
9. Should Salesforce events sync back to Outlook?
10. What happens to visibility during territory realignment?
11. Who governs EAC and sharing configuration?
12. Are there restricted accounts with tighter activity privacy?

## Final Clarification to Resolve Early

Ask this explicitly:

`Is collaboration more important, or activity privacy?`

- Collaboration-first design needs broader sharing and stronger governance controls.
- Privacy-first design needs stricter role-based visibility and reduced peer access.
- Most organizations use a hybrid model by segmenting account types and user groups.

## Workshop Output Template

Use this table to capture decisions:

| Topic | Decision | Owner | Approval Date | Notes |
|---|---|---|---|---|
| Territory overlap policy |  |  |  |  |
| Peer meeting visibility |  |  |  |  |
| Manager activity visibility |  |  |  |  |
| EAC sync scope |  |  |  |  |
| Reporting model |  |  |  |  |
| Restricted account policy |  |  |  |  |
| Governance owner(s) |  |  |  |  |
