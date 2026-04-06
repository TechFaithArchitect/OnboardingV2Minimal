#!/usr/bin/env node
/**
 * Fails the process if any permission set grants high-risk **user** permissions
 * (e.g. Author Apex, Modify All Data). Object-level modifyAllRecords is reported
 * but does not fail by default — tune REPORT_MODIFY_ALL below.
 *
 * Usage (from DX project root): node scripts/automation/audit-permission-set-high-risk.js
 */
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "../..");
const dir = path.join(root, "force-app/main/default/permissionsets");

const FAIL_USER_PERMISSIONS = new Set([
  "AuthorApex",
  "ModifyAllData",
  "ManageUsers",
  "DelegatedAdmin",
  "ManageSharing",
  "ViewAllData",
  "EditBillingInfo",
]);

/** When true, exit 1 if any object has modifyAllRecords true */
const FAIL_ON_MODIFY_ALL_OBJECT = process.env.AUDIT_PERM_FAIL_MODIFY_ALL === "1";

function parseUserPermissionBlocks(xml) {
  const blocks = [];
  const re = /<userPermissions>\s*([\s\S]*?)<\/userPermissions>/g;
  let m;
  while ((m = re.exec(xml))) {
    blocks.push(m[1]);
  }
  return blocks;
}

function blockEnabledName(block) {
  const en = /<enabled>\s*(true|false)\s*<\/enabled>/.exec(block);
  const nm = /<name>\s*([^<]+)\s*<\/name>/.exec(block);
  return {
    enabled: en ? en[1] === "true" : false,
    name: nm ? nm[1].trim() : null,
  };
}

function findModifyAllObjects(xml) {
  const out = [];
  const re =
    /<objectPermissions>\s*([\s\S]*?)<\/objectPermissions>/g;
  let m;
  while ((m = re.exec(xml))) {
    const chunk = m[1];
    if (!/<modifyAllRecords>\s*true\s*<\/modifyAllRecords>/.test(chunk)) continue;
    const om = /<object>\s*([^<]+)\s*<\/object>/.exec(chunk);
    if (om) out.push(om[1].trim());
  }
  return out;
}

function main() {
  if (!fs.existsSync(dir)) {
    console.error("No permissionsets directory:", dir);
    process.exit(1);
  }
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".permissionset-meta.xml"));

  const violations = [];
  const modifyAllReports = [];

  for (const f of files) {
    const xml = fs.readFileSync(path.join(dir, f), "utf8");
    for (const block of parseUserPermissionBlocks(xml)) {
      const { enabled, name } = blockEnabledName(block);
      if (enabled && name && FAIL_USER_PERMISSIONS.has(name)) {
        violations.push({ file: f, userPermission: name });
      }
    }
    const modAll = findModifyAllObjects(xml);
    if (modAll.length) {
      modifyAllReports.push({ file: f, objects: modAll });
    }
  }

  if (violations.length) {
    console.error("High-risk userPermissions(enabled=true):");
    for (const v of violations) {
      console.error(`  ${v.file}: ${v.userPermission}`);
    }
    process.exit(1);
  }

  if (modifyAllReports.length) {
    console.log(
      "Object permissions with modifyAllRecords=true (review for least privilege):",
    );
    for (const r of modifyAllReports) {
      console.log(`  ${r.file}: ${r.objects.join(", ")}`);
    }
    if (FAIL_ON_MODIFY_ALL_OBJECT) {
      console.error("FAIL: set AUDIT_PERM_FAIL_MODIFY_ALL=0 or fix grants.");
      process.exit(1);
    }
  }

  console.log(
    "audit-permission-set-high-risk: OK (no blocked userPermissions enabled).",
  );
}

main();
