// Advisory: verify the absolute raw.githubusercontent.com URLs in the README
// header actually resolve (200) and serve byte-for-byte the committed SVGs.
// Catches path drift, branch renames, and file moves that silently break the
// GitHub-rendered brand header. Network-dependent and main-branch-relative, so
// this runs only as an advisory CI step on push to main.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const REPO = fileURLToPath(new URL('../../', import.meta.url)); // tools/ → ../../ = repo root
const readme = readFileSync(REPO + 'README.md', 'utf8');

const urls = [...readme.matchAll(/https:\/\/raw\.githubusercontent\.com\/\S+?\.svg/g)].map((m) => m[0]);
if (urls.length === 0) {
  console.error('FAIL: no raw.githubusercontent.com SVG URLs found in README header');
  process.exit(1);
}

let failed = 0;
for (const url of urls) {
  // Map the raw URL back to its committed path: .../crosswake/<ref>/<path>
  const rel = url.replace(/^https:\/\/raw\.githubusercontent\.com\/szTheory\/crosswake\/[^/]+\//, '');
  let committed;
  try {
    committed = readFileSync(REPO + rel, 'utf8');
  } catch {
    console.error(`FAIL: README references ${rel} but it does not exist in the repo`);
    failed++;
    continue;
  }
  try {
    const res = await fetch(url);
    if (!res.ok) {
      console.error(`FAIL: ${url} → HTTP ${res.status}`);
      failed++;
      continue;
    }
    const served = await res.text();
    if (served === committed) {
      console.log(`OK:   ${url} (200, bytes match)`);
    } else {
      console.error(`FAIL: ${url} resolves but served bytes differ from committed ${rel}`);
      failed++;
    }
  } catch (err) {
    console.error(`FAIL: ${url} → ${err.message}`);
    failed++;
  }
}

if (failed > 0) {
  console.error(`\n${failed}/${urls.length} README header URL(s) failed verification`);
  process.exit(1);
}
console.log(`\nAll ${urls.length} README header URL(s) verified.`);
