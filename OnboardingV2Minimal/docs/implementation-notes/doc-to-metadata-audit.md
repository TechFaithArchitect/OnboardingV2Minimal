# Doc-to-Metadata Audit

**Run:** 2026-01-21 15:02:33 UTC

## Scope
- Flow inventory list in `docs/components/flows.md` vs `force-app/main/default/flows`
- Trigger docs in `docs/components/triggers.md` vs `force-app/main/default/triggers`
- LWC docs in `docs/components/lwc-components.md` vs `force-app/main/default/lwc`

## Method
- Compare documented items to repo filenames or directory names.
- LWC coverage is based on `Location:` entries in the LWC doc.
- Flow coverage is based on the "Flow Inventory (Repo)" section.

## Results
- Flows: 0 missing in docs, 0 missing in repo
- Triggers: 0 missing in docs, 0 missing in repo
- LWC: 0 missing in docs, 0 missing in repo

## Notes
- Added LWC doc entries for `vendorProgramOnboardingVendor` and `vendorProgramOnboardingVendorProgramRecipientGroup` to align docs with repo.
