#!/usr/bin/env node
/**
 * Prints repository metrics for documentation baseline checks.
 * Run from package root: npm run doc:metrics
 */
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");

function exists(p) {
  try {
    fs.accessSync(p);
    return true;
  } catch {
    return false;
  }
}

function listFiles(dir, predicate) {
  if (!exists(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((name) => predicate(path.join(dir, name), name));
}

function countFlowMeta() {
  const d = path.join(root, "force-app/main/default/flows");
  return listFiles(d, (_, name) => name.endsWith(".flow-meta.xml")).length;
}

/**
 * Prefix counts: DOMAIN_*, BLL_*, EXP_* (first path segment before '_').
 */
function flowPrefixCounts() {
  const d = path.join(root, "force-app/main/default/flows");
  const files = listFiles(d, (_, name) => name.endsWith(".flow-meta.xml"));
  const counts = { DOMAIN: 0, BLL: 0, EXP: 0, other: 0 };
  for (const name of files) {
    const base = name.replace(/\.flow-meta\.xml$/, "");
    const prefix = base.split("_")[0];
    if (prefix === "DOMAIN") counts.DOMAIN++;
    else if (prefix === "BLL") counts.BLL++;
    else if (prefix === "EXP") counts.EXP++;
    else counts.other++;
  }
  return counts;
}

/** Map apiVersion string -> count for flow metadata files */
function flowApiVersionHistogram() {
  const d = path.join(root, "force-app/main/default/flows");
  const files = listFiles(d, (_, name) => name.endsWith(".flow-meta.xml"));
  const hist = {};
  for (const name of files) {
    const p = path.join(d, name);
    const xml = fs.readFileSync(p, "utf8");
    const m = xml.match(/<apiVersion>([0-9.]+)<\/apiVersion>/);
    const v = m ? m[1] : "?";
    hist[v] = (hist[v] || 0) + 1;
  }
  return hist;
}

function countApexClasses() {
  const d = path.join(root, "force-app/main/default/classes");
  return listFiles(d, (_, name) => name.endsWith(".cls")).length;
}

function countTestSuffixClasses() {
  const d = path.join(root, "force-app/main/default/classes");
  return listFiles(
    d,
    (_, name) => name.endsWith(".cls") && /Test\.cls$/.test(name),
  ).length;
}

function countTestFactoryClasses() {
  const d = path.join(root, "force-app/main/default/classes");
  return listFiles(
    d,
    (_, name) => name.endsWith(".cls") && /^Test.*Factory.*\.cls$/.test(name),
  ).length;
}

function countCustomMetadataRows() {
  const d = path.join(root, "force-app/main/default/customMetadata");
  return listFiles(d, (_, name) => name.endsWith(".md-meta.xml")).length;
}

function countObjectTopLevelFolders() {
  const d = path.join(root, "force-app/main/default/objects");
  if (!exists(d)) return 0;
  return fs.readdirSync(d).filter((name) => {
    const p = path.join(d, name);
    return fs.statSync(p).isDirectory();
  }).length;
}

const metrics = {
  flows_flow_meta_xml: countFlowMeta(),
  flow_prefix_DOMAIN_BLL_EXP_other: flowPrefixCounts(),
  flow_api_version_histogram: flowApiVersionHistogram(),
  apex_cls_total: countApexClasses(),
  apex_cls_suffix_Test: countTestSuffixClasses(),
  apex_cls_TestFactory_pattern: countTestFactoryClasses(),
  customMetadata_md_meta_xml: countCustomMetadataRows(),
  objects_top_level_folders: countObjectTopLevelFolders(),
};

console.log("OnboardingV2 doc metrics (from force-app/)");
console.log("---");
for (const [k, v] of Object.entries(metrics)) {
  if (k === "flow_prefix_DOMAIN_BLL_EXP_other" || k === "flow_api_version_histogram") {
    console.log(`${k}: ${JSON.stringify(v)}`);
  } else {
    console.log(`${k}: ${v}`);
  }
}
console.log("---");
console.log(
  "Compare with developer/FLOW_CATALOG.md, developer/APEX_CLASS_INVENTORY.md, and docs/README.md scope baseline.",
);
