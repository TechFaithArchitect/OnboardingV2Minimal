# Business Process Guide

## Purpose

This guide explains the onboarding process in plain business terms: who starts it, what records are created, how tasks are assigned, and how completion is determined.

## Quick Example (One Realistic Story)

Use this as a mental model:

1. Sales runs the onboarding create flow from an Opportunity.
2. The system creates Onboarding + Requirement records.
3. The system assigns each requirement to either the account, all contacts, principal owner, or primary contact (based on policy).
4. As evidence comes in (training, contract/agreement, credentials), requirement status updates.
5. When all required work is complete, onboarding moves to `Setup Complete`.

## Related documentation

- [Sales User Guide](./SALES_USER_GUIDE.md) — create flow and validations
- [Business User Guide](./BUSINESS_USER_GUIDE.md) — day-to-day monitoring and field guides
- [Support and Troubleshooting](../support/SUPPORT_AND_TROUBLESHOOTING.md) — triage when outcomes are wrong

## End-to-End Process

### 1) Intake and Opportunity Setup

- Sales initiates onboarding from Account or Opportunity context.
- Guided screen flows capture required opportunity, program path, and related setup fields.
- Opportunity contact assignments are created and primary contact responsibility is established.

### 2) Core Record Creation

- Opportunity, contract, and onboarding records are created and linked.
- Depending on performance configuration, onboarding tail work may run asynchronously.

### 3) Requirement Generation

- Vendor program requirements are expanded to onboarding requirement rows.
- Requirement subjects are expanded based on policy (`ACCOUNT_ONLY`, `ALL_CONTACTS`, `PRINCIPAL_OWNER`, or `PRIMARY_CONTACT_OR_ACCOUNT`).

### 4) Evidence Collection and Status Progression

- Evidence sources (training, contract/agreement, credential artifacts) update requirement subjects.
- Subject statuses roll into parent requirement status/completion.
- Parent requirement state rolls into overall onboarding status based on ordered business rules.

### 5) Communication and Follow-Up

- Communication policies determine template and recipient routing by event/context.
- Faults and unresolved paths are captured for admin follow-up.
- Follow-up queues and error logs support operational remediation.

## Responsibility Model

- Sales: starts intake and sets the correct primary contact.
- Onboarding specialists: track requirements and move work to completion.
- Compliance and finance: handle specialized review outcomes.
- Account services and customer service: maintain continuity and support handoff.

## Lifecycle Outcomes

Primary lifecycle target statuses include:

- In Process
- Pending Sales
- Pending Initial Review
- Paperwork Sent
- Setup Complete
- Denied
- Canceled
- Expired
