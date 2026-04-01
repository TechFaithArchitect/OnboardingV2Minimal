# OnboardingV2Minimal

Salesforce source and automation for the **OnboardingV2** onboarding platform (Layered flows, CMDT-driven policies, and Apex services).

## Documentation

All human-oriented documentation lives in the app project:

- **[OnboardingV2Minimal/docs/README.md](OnboardingV2Minimal/docs/README.md)** — start here (**“New Here?”** path for sales, ops, admins, developers)
- **[OnboardingV2Minimal/scripts/README.md](OnboardingV2Minimal/scripts/README.md)** — what each repo script is for and when it is safe to run

Metadata and tooling entry points:

- **Salesforce DX project**: `OnboardingV2Minimal/` (contains `force-app/`, `package.json`, `sfdx-project.json`)
- **Primary Lightning app**: `OnboardingV2Minimal/force-app/main/default/applications/Onboarding.app-meta.xml`

## Local development

Use the **Salesforce CLI** (`sf`) and the scripts in [OnboardingV2Minimal/package.json](OnboardingV2Minimal/package.json) (for example `npm run lint`, `npm run doc:metrics`). Exact org strategy (sandbox vs scratch org) is team-specific; see the developer guide linked from the docs map.
