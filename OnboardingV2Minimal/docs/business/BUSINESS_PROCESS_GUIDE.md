# Business Process Guide

## Purpose

This guide describes how onboarding operations execute from business perspective across sales, onboarding, compliance, and account services teams.

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
- Requirement subjects are expanded based on fulfillment policy model:
- account-only
- all contacts
- principal owner
- primary contact or account

### 4) Evidence Collection and Status Progression

- Evidence sources (training, contract/agreement, credential artifacts) update requirement subjects.
- Subject statuses roll into parent requirement status/completion.
- Parent requirement state rolls into overall onboarding status based on ordered business rules.

### 5) Communication and Follow-Up

- Communication policies determine template and recipient routing by event/context.
- Faults and unresolved paths are captured for admin follow-up.
- Follow-up queues and error logs support operational remediation.

## Responsibility Model

- Sales: intake initiation, contact role alignment, program path setup
- Onboarding specialists: requirement progression and lifecycle monitoring
- Compliance and finance: specialized requirement review outcomes
- Account services and customer service: status continuity and support handoff

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
