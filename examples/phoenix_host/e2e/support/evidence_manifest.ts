import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';

export type EvidenceStatus = 'captured' | 'unavailable';

export type EvidenceRoute = {
  route_id: string;
  runtime_owner: string;
  platform_runtime: string;
  command: string;
  proof_class: string;
  support_label: string;
  coordinate_mode: string | null;
  source_job?: string;
  captured_at?: string;
  artifacts: string[];
  retention_label?: string;
  known_limitations: string[];
  status: EvidenceStatus;
  unavailable_reason?: string;
};

export type EvidenceManifest = {
  schema_version: string;
  crosswake_version: string;
  commit_sha: string;
  source_job: string;
  captured_at: string;
  retention_label: string;
  routes: EvidenceRoute[];
};

const schemaVersion = '1.0.0';
const defaultSourceJob = 'route-tour-proof';
const defaultRetentionLabel = 'ci-artifact-14-days';
const packageVersionPath = path.join(process.cwd(), '..', '..', 'mix.exs');

export function writeRouteTourEvidenceManifest(artifactDir: string, command: string) {
  const sourceJob = process.env.GITHUB_JOB || defaultSourceJob;
  const capturedAt = new Date().toISOString();
  const retentionLabel = process.env.CROSSWAKE_EVIDENCE_RETENTION_LABEL || defaultRetentionLabel;
  const routes = routeTourEntries(command);

  assertRequiredArtifacts(artifactDir, routes);
  mkdirSync(artifactDir, { recursive: true });

  const manifest: EvidenceManifest = {
    schema_version: schemaVersion,
    crosswake_version: crosswakeVersion(),
    commit_sha: commitSha(),
    source_job: sourceJob,
    captured_at: capturedAt,
    retention_label: retentionLabel,
    routes: routes.map(route => ({
      ...route,
      source_job: sourceJob,
      captured_at: capturedAt,
      retention_label: retentionLabel,
    })),
  };

  const manifestPath = path.join(artifactDir, 'evidence-manifest.json');
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  return manifestPath;
}

export function routeTourEntries(command: string): EvidenceRoute[] {
  return [
    requiredBrowserRoute('library', 'live_view', command, ['screenshots/library.png']),
    requiredBrowserRoute('bridge-proof', 'bounded_bridge', command, ['screenshots/bridge-proof.png']),
    requiredBrowserRoute('offline-study', 'offline_island', command, ['screenshots/offline-study-replayed.png']),
    requiredBrowserRoute('selective-native-claim-capture', 'native_screen', command, [
      'screenshots/selective-native-claim-capture-unavailable.png',
    ]),
  ];
}

function requiredBrowserRoute(routeId: string, runtimeOwner: string, command: string, artifacts: string[]): EvidenceRoute {
  return {
    route_id: routeId,
    runtime_owner: runtimeOwner,
    platform_runtime: 'browser-chromium',
    command,
    proof_class: 'merge-blocking proof',
    support_label: 'advisory evidence',
    coordinate_mode: null,
    artifacts,
    known_limitations: [
      'Screenshots are collateral captured after semantic Playwright assertions pass.',
      'This browser evidence does not prove native share sheet execution, physical-device support, camera support, media-upload support, provider authority, or merge-blocking native support.',
    ],
    status: 'captured',
  };
}

function assertRequiredArtifacts(artifactDir: string, routes: EvidenceRoute[]) {
  for (const route of routes) {
    if (route.proof_class !== 'merge-blocking proof' || route.status !== 'captured') {
      continue;
    }

    for (const artifact of route.artifacts) {
      const artifactPath = path.join(artifactDir, artifact);

      if (!existsSync(artifactPath)) {
        throw new Error(`route ${route.route_id} missing required artifact ${artifact}`);
      }
    }
  }
}

function crosswakeVersion() {
  if (process.env.CROSSWAKE_VERSION) {
    return process.env.CROSSWAKE_VERSION;
  }

  try {
    const mix = readFileSync(packageVersionPath, 'utf8');
    const match = mix.match(/@version\s+"([^"]+)"/);
    if (match) {
      return match[1];
    }
  } catch {
    // Fall through to local test fixture value below.
  }

  return '0.0.0-local';
}

function commitSha() {
  if (process.env.GITHUB_SHA) {
    return process.env.GITHUB_SHA;
  }

  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  } catch {
    return 'local-unavailable';
  }
}
