import fs from "node:fs";
import path from "node:path";

// Phase directories MOVE when `/gsd-complete-milestone` archives a milestone:
// `.planning/workstreams/<ws>/phases/<phase>` becomes
// `.planning/workstreams/<ws>/milestones/<version>-phases/<phase>`. A test that
// hardcodes the live path passes for the whole life of a milestone and then
// breaks, all at once, the moment that milestone ships.
//
// Resolve paths used to READ a file. Do NOT resolve paths used as recorded git
// identity (expected diff path sets, pinned blob SHAs) — those describe where a
// file was when the evidence was recorded, and rewriting them would silently
// invalidate the equality they exist to assert.
export function phaseEvidencePath(root, workstream, phaseRelative) {
  const live = path.join(
    root,
    ".planning/workstreams",
    workstream,
    "phases",
    phaseRelative,
  );
  if (fs.existsSync(live)) return live;

  const milestones = path.join(root, ".planning/workstreams", workstream, "milestones");
  if (fs.existsSync(milestones)) {
    // A phase directory is only ever archived once, so any match is the match;
    // sorting keeps the choice deterministic.
    const archives = fs
      .readdirSync(milestones)
      .filter((entry) => entry.endsWith("-phases"))
      .sort();
    for (const archive of archives.reverse()) {
      const candidate = path.join(milestones, archive, phaseRelative);
      if (fs.existsSync(candidate)) return candidate;
    }
  }

  // Neither exists: return the LIVE path so the caller fails with a missing-file
  // error naming the location a reader would expect, rather than silently
  // finding nothing to check.
  return live;
}
