# Fix "Deploy This Source to Org" UI Failures

When the Salesforce VS Code extension fails with "No results found", "unsafe character sequences", or `Cannot read properties of null (reading 'startsWith')`, use these fixes.

---

## 1. Open the Correct Folder (Most Important)

The Salesforce extension has a **known limitation** with nested folder structures ([GitHub #5486](https://github.com/forcedotcom/salesforcedx-vscode/issues/5486)). It expects the workspace root to be the SFDX project root (where `sfdx-project.json` lives).

**Fix:** Open the **inner** `OnboardingV2Minimal` folder, not the parent.

- **Wrong:** `File > Open Folder` → `/Users/jasonmu/OnboardingV2Minimal` (parent)
- **Right:** `File > Open Folder` → `/Users/jasonmu/OnboardingV2Minimal/OnboardingV2Minimal` (inner – contains `sfdx-project.json` and `force-app`)

**Or use the workspace file:**

1. `File > Open Workspace from File...`
2. Select `OnboardingV2Minimal.code-workspace` (in the repo root)
3. This opens only the SFDX project folder as the workspace root

---

## 2. Clear Source Tracking Cache

If you still see "unsafe character sequences" (e.g. paths like `../../tmp/onboardv2-training-sync-review/`):

```bash
make fix-deploy
```

Or manually:

```bash
rm -rf .sf/orgs/*/localSourceTracking
sf org disable tracking --target-org OnboardV2
```

---

## 3. Manifest File Language Mode

If deploy/retrieve from a manifest (package.xml) fails, the file may be interpreted as plain XML instead of `ForceSourceManifest`.

**Fix:** In the bottom-right status bar, click the language mode (e.g. "XML") and change it to **ForceSourceManifest**.

Or add to `.vscode/settings.json`:

```json
"files.associations": {
  "manifest/*.xml": "forcesourcemanifest",
  "package.xml": "forcesourcemanifest"
}
```

---

## 4. Use Terminal When UI Fails

The CLI works even when the extension fails. Use:

```bash
# Deploy specific components
make deploy-default-vendor-program

# Or deploy via manifest
sf project deploy start --manifest manifest/deploy-default-vendor-program.xml --target-org OnboardV2

# Or deploy a directory
sf project deploy start --source-dir force-app/main/default/classes --target-org OnboardV2
```

---

## 5. Extension Version

Ensure you're on a recent Salesforce Extension Pack. If issues persist:

1. Uninstall all `salesforcedx` extensions
2. Quit VS Code completely
3. Reinstall [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
4. Reopen the project using the correct folder (step 1)

---

## Summary

| Issue | Fix |
|-------|-----|
| Nested folder / wrong project root | Open inner `OnboardingV2Minimal` or use `OnboardingV2Minimal.code-workspace` |
| Unsafe character sequences | `make fix-deploy` |
| Manifest deploy fails | Set manifest language mode to ForceSourceManifest |
| Extension still broken | Use terminal: `make deploy-default-vendor-program` or `sf project deploy start` |
