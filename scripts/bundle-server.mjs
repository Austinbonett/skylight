#!/usr/bin/env node
/**
 * Bundle the Node server + copy web dist into the Xcode Resources folder.
 *
 * Run from the repo root:
 *   node scripts/bundle-server.mjs
 *
 * Then in Xcode, add Resources/server.cjs and Resources/web/ to the target.
 */

import { execSync } from "node:child_process";
import { copyFileSync, mkdirSync, rmSync, cpSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const resourcesDir = resolve(root, "macos/Skylight/Skylight/Resources");
mkdirSync(resourcesDir, { recursive: true });

// 1. Bundle server
console.log("📦  Bundling server…");
const esbuild = resolve(
  root,
  "node_modules/.pnpm/esbuild@0.28.0/node_modules/esbuild/bin/esbuild"
);
execSync(
  [
    esbuild,
    "server/src/index.ts",
    "--bundle",
    "--platform=node",
    "--target=node20",
    "--format=cjs",
    "--alias:@shared=./shared/src",
    "--loader:.json=json",
    "--external:fsevents",
    `--banner:js="// esbuild bundle\nconst _importMetaHref = 'file://' + __filename.replace(/\\\\\\\\/g, '/');\nconst _importMeta = { url: _importMetaHref };"`,
    `--define:import.meta=_importMeta`,
    `--outfile=${resourcesDir}/server.cjs`,
  ].join(" "),
  { cwd: root, stdio: "inherit" }
);

// 2. Build web if needed
const webDist = resolve(root, "web/dist");
if (!existsSync(webDist)) {
  console.log("🔨  Building web…");
  execSync("pnpm build", { cwd: root, stdio: "inherit" });
}

// 3. Copy web dist
const webTarget = resolve(resourcesDir, "web");
if (existsSync(webTarget)) rmSync(webTarget, { recursive: true });
cpSync(webDist, webTarget, { recursive: true });
console.log("📂  Copied web/dist → Resources/web/");

console.log(`\n✅  Done! Resources are in:\n   ${resourcesDir}`);
console.log(
  "\nNext: In Xcode, drag Resources/server.cjs and Resources/web/ into the Skylight target → Copy Bundle Resources."
);
