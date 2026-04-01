# Environment and Integrations Matrix

This table is **operational metadata** for your team: which **Salesforce org** connects to which **external systems** and **notes** for support. It extends [Integrations](./INTEGRATIONS.md).

**End-to-end context:** Step 0 of [Baseline setup guide](../BASELINE_SETUP_GUIDE.md).

## How to use

1. Copy the template row for each environment you maintain.
2. Replace placeholders; keep URLs and secrets **out of git** if this file is public—store references (“see Azure Key Vault …”) instead.
3. Link this doc from internal runbooks and onboarding for new admins.

Simple rule: one row per real org (Dev, UAT, Prod), updated whenever connectors or support ownership changes.

## Org inventory

| Field                       | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| **Org label**               | Human name (e.g. “UAT OnboardV2”)                            |
| **Salesforce org Id**       | `00D...`                                                     |
| **Branch / pipeline stage** | What Git or Gearset stage deploys here                       |
| **Purpose**                 | UAT / training / preprod / prod                              |
| **Adobe Sign**              | Connected app / integration user notes; “N/A” if unused      |
| **LearnUpon**               | Org or namespace; sandbox vs prod API; “N/A” if unused       |
| **Email / Metadata sync**   | Jobs or manual process for `EmailTemplateSync` if you run it |
| **Support contact**         | Team or roster                                               |
| **Last verified**           | Date someone validated connectors                            |

## Template rows (replace with yours)

| Org label    | Org Id            | Stage               | Purpose             | Adobe Sign       | LearnUpon   | Email / template sync | Support       | Last verified |
| ------------ | ----------------- | ------------------- | ------------------- | ---------------- | ----------- | --------------------- | ------------- | ------------- |
| Example UAT  | `00Dxxxxxxxxxxxx` | `develop` → sandbox | Integration testing | Non-prod profile | Sandbox API | Weekly job            | Platform team | YYYY-MM-DD    |
| Example Prod | `00Dyyyyyyyyyyyy` | `main` → prod       | Live                | Prod             | Prod        | Scheduled + deploy    | Platform team | YYYY-MM-DD    |

## Related

- [Integrations](./INTEGRATIONS.md)
- [Deployment Runbook](../admin/DEPLOYMENT_RUNBOOK.md)
- [Metadata Drift Checklist](../admin/METADATA_DRIFT_CHECKLIST.md)
