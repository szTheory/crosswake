import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';

export type EvidenceStatus = 'captured' | 'unavailable';
export type ProofClass = 'merge-blocking' | 'advisory' | 'not-yet-proven' | 'unsupported';
export type SupportLabel =
  | 'Available today'
  | 'Proof-backed example'
  | 'Demo pressure'
  | 'Advisory evidence'
  | 'Future gap'
  | 'Next-pack candidate';
export type CapabilityPosture =
  | 'shipped'
  | 'proof-backed-example'
  | 'demo-pressure'
  | 'advisory-evidence'
  | 'future-gap'
  | 'next-pack-candidate';
export type PackageOwner = 'core' | 'native shell' | 'first-party companion' | 'example/docs-only' | 'deferred';
export type RuntimeOwner =
  | 'live_view'
  | 'bounded_bridge'
  | 'native_shell'
  | 'native_screen'
  | 'offline_island'
  | 'backend_projection'
  | 'future_native_control';

export type EvidenceRoute = {
  route_id: string;
  runtime_owner: RuntimeOwner;
  platform_runtime: string;
  command: string;
  proof_class: ProofClass;
  support_label: SupportLabel;
  coordinate_mode: string | null;
  source_job?: string;
  captured_at?: string;
  artifacts: string[];
  retention_label?: string;
  known_limitations: string[];
  status: EvidenceStatus;
  unavailable_reason?: string;
  capability_posture: CapabilityPosture;
  package_owner: PackageOwner;
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
    capturedRoute(command, {
      route_id: 'library',
      runtime_owner: 'live_view',
      support_label: 'Available today',
      capability_posture: 'shipped',
      package_owner: 'core',
      artifacts: ['screenshots/library.png'],
    }),
    capturedRoute(command, {
      route_id: 'bridge-proof',
      runtime_owner: 'bounded_bridge',
      support_label: 'Available today',
      capability_posture: 'shipped',
      package_owner: 'core',
      artifacts: ['screenshots/bridge-proof.png'],
    }),
    capturedRoute(command, {
      route_id: 'offline-study',
      runtime_owner: 'offline_island',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/offline-study-replayed.png'],
    }),
    capturedRoute(command, {
      route_id: 'selective-native-claim-capture',
      runtime_owner: 'native_screen',
      support_label: 'Next-pack candidate',
      capability_posture: 'next-pack-candidate',
      package_owner: 'native shell',
      artifacts: ['screenshots/selective-native-claim-capture-unavailable.png'],
    }),
    capturedRoute(command, {
      route_id: 'showcase-hub',
      runtime_owner: 'live_view',
      support_label: 'Available today',
      capability_posture: 'shipped',
      package_owner: 'core',
      artifacts: ['screenshots/showcase-hub.png'],
    }),
    ...adminPilotRoutes(command),
    ...fieldservRoutes(command),
    ...learnLoopRoutes(command),
    capabilityPressure(command, {
      route_id: 'fieldserv-capture-pressure',
      runtime_owner: 'native_screen',
      proof_class: 'not-yet-proven',
      support_label: 'Next-pack candidate',
      capability_posture: 'next-pack-candidate',
      package_owner: 'native shell',
      unavailable_reason:
        'Browser route tour reaches the native capture handoff, but Phase 152 does not ship device camera capture.',
    }),
    capabilityPressure(command, {
      route_id: 'fieldserv-scanner-pressure',
      runtime_owner: 'future_native_control',
      proof_class: 'unsupported',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason: 'Scanner execution is represented as Fieldserv pressure only.',
    }),
    capabilityPressure(command, {
      route_id: 'fieldserv-document-scan-pressure',
      runtime_owner: 'future_native_control',
      proof_class: 'unsupported',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason: 'Document scan execution remains a deferred native-control capability.',
    }),
    capabilityPressure(command, {
      route_id: 'fieldserv-media-upload-pressure',
      runtime_owner: 'future_native_control',
      proof_class: 'unsupported',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason: 'Media upload is modeled as capability pressure, not shipped upload support.',
    }),
    capabilityPressure(command, {
      route_id: 'fieldserv-offline-inspection-pressure',
      runtime_owner: 'offline_island',
      proof_class: 'not-yet-proven',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason:
        'Fieldserv inspection remains cached read-only until a journal, outbox, and reconciliation proof exist.',
    }),
    capabilityPressure(command, {
      route_id: 'learnloop-native-storage-pressure',
      runtime_owner: 'future_native_control',
      proof_class: 'not-yet-proven',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason: 'LearnLoop still uses browser-owned IndexedDB in this proof lane.',
    }),
    capabilityPressure(command, {
      route_id: 'learnloop-sync-productization-pressure',
      runtime_owner: 'offline_island',
      proof_class: 'not-yet-proven',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason:
        'The LearnLoop outbox is app-specific evidence, not a reusable storage or sync product.',
    }),
    capabilityPressure(command, {
      route_id: 'learnloop-commerce-pressure',
      runtime_owner: 'backend_projection',
      proof_class: 'unsupported',
      support_label: 'Future gap',
      capability_posture: 'future-gap',
      package_owner: 'deferred',
      unavailable_reason: 'Commerce remains a mocked backend-projection pressure lane.',
    }),
    capabilityPressure(command, {
      route_id: 'native-controls-alert-confirm',
      runtime_owner: 'future_native_control',
      proof_class: 'not-yet-proven',
      support_label: 'Next-pack candidate',
      capability_posture: 'next-pack-candidate',
      package_owner: 'core',
      unavailable_reason: 'Alert/confirm native controls are next-pack candidates only.',
    }),
    capabilityPressure(command, {
      route_id: 'native-controls-action-menu',
      runtime_owner: 'future_native_control',
      proof_class: 'not-yet-proven',
      support_label: 'Next-pack candidate',
      capability_posture: 'next-pack-candidate',
      package_owner: 'core',
      unavailable_reason: 'Action-menu native controls are next-pack candidates only.',
    }),
    capabilityPressure(command, {
      route_id: 'native-controls-toast-review',
      runtime_owner: 'future_native_control',
      proof_class: 'not-yet-proven',
      support_label: 'Next-pack candidate',
      capability_posture: 'next-pack-candidate',
      package_owner: 'core',
      unavailable_reason: 'Toast review native controls are next-pack candidates only.',
    }),
    advisoryEvidence(command, {
      route_id: 'permissions-status-evidence',
      runtime_owner: 'bounded_bridge',
      package_owner: 'core',
      unavailable_reason:
        'Permissions status evidence is documented capability-map metadata; the browser route tour does not execute OS dialogs.',
    }),
    advisoryEvidence(command, {
      route_id: 'notification-token-evidence',
      runtime_owner: 'bounded_bridge',
      package_owner: 'first-party companion',
      unavailable_reason:
        'Notification token evidence requires native-shell participation outside the browser route tour.',
    }),
  ];
}

function adminPilotRoutes(command: string): EvidenceRoute[] {
  return [
    capturedRoute(command, {
      route_id: 'adminpilot-dashboard',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/adminpilot-dashboard.png'],
    }),
    capturedRoute(command, {
      route_id: 'adminpilot-approvals',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/adminpilot-approvals.png'],
    }),
    capturedRoute(command, {
      route_id: 'adminpilot-approval-approved',
      runtime_owner: 'bounded_bridge',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'core',
      artifacts: ['screenshots/adminpilot-approval-approved.png'],
    }),
    capturedRoute(command, {
      route_id: 'adminpilot-diagnostics',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/adminpilot-diagnostics.png'],
    }),
  ];
}

function fieldservRoutes(command: string): EvidenceRoute[] {
  return [
    capturedRoute(command, {
      route_id: 'fieldserv-jobs',
      runtime_owner: 'live_view',
      support_label: 'Demo pressure',
      capability_posture: 'demo-pressure',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/fieldserv-jobs.png'],
      known_limitations: fieldservLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'fieldserv-job-detail',
      runtime_owner: 'live_view',
      support_label: 'Demo pressure',
      capability_posture: 'demo-pressure',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/fieldserv-job-detail.png'],
      known_limitations: fieldservLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'fieldserv-inspection',
      runtime_owner: 'live_view',
      support_label: 'Demo pressure',
      capability_posture: 'demo-pressure',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/fieldserv-inspection.png'],
      known_limitations: fieldservLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'fieldserv-capture-handoff',
      runtime_owner: 'native_screen',
      support_label: 'Next-pack candidate',
      capability_posture: 'next-pack-candidate',
      package_owner: 'native shell',
      artifacts: ['screenshots/fieldserv-capture-handoff.png'],
      known_limitations: fieldservLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'fieldserv-evidence-review',
      runtime_owner: 'live_view',
      support_label: 'Demo pressure',
      capability_posture: 'demo-pressure',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/fieldserv-evidence-review.png'],
      known_limitations: fieldservLimitations(),
    }),
  ];
}

function learnLoopRoutes(command: string): EvidenceRoute[] {
  return [
    capturedRoute(command, {
      route_id: 'learnloop-dashboard',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/learnloop-dashboard.png'],
      known_limitations: learnLoopLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'learnloop-course',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/learnloop-course.png'],
      known_limitations: learnLoopLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'learnloop-subscription',
      runtime_owner: 'backend_projection',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/learnloop-subscription.png'],
      known_limitations: learnLoopLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'learnloop-pack',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/learnloop-pack.png'],
      known_limitations: learnLoopLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'learnloop-history-diagnostics',
      runtime_owner: 'live_view',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/learnloop-history-diagnostics.png'],
      known_limitations: learnLoopLimitations(),
    }),
    capturedRoute(command, {
      route_id: 'learnloop-route-tour',
      runtime_owner: 'offline_island',
      support_label: 'Proof-backed example',
      capability_posture: 'proof-backed-example',
      package_owner: 'example/docs-only',
      artifacts: ['screenshots/learnloop-route-tour.png'],
      known_limitations: learnLoopLimitations(),
    }),
  ];
}

function capturedRoute(
  command: string,
  route: {
    route_id: string;
    runtime_owner: RuntimeOwner;
    support_label: SupportLabel;
    capability_posture: CapabilityPosture;
    package_owner: PackageOwner;
    artifacts: string[];
    proof_class?: ProofClass;
    known_limitations?: string[];
  },
): EvidenceRoute {
  return {
    route_id: route.route_id,
    runtime_owner: route.runtime_owner,
    platform_runtime: 'browser-chromium',
    command,
    proof_class: route.proof_class ?? 'merge-blocking',
    support_label: route.support_label,
    coordinate_mode: null,
    artifacts: route.artifacts,
    known_limitations: route.known_limitations ?? browserLimitations(),
    status: 'captured',
    capability_posture: route.capability_posture,
    package_owner: route.package_owner,
  };
}

function advisoryEvidence(
  command: string,
  route: {
    route_id: string;
    runtime_owner: RuntimeOwner;
    package_owner: PackageOwner;
    unavailable_reason: string;
  },
): EvidenceRoute {
  return capabilityPressure(command, {
    ...route,
    proof_class: 'advisory',
    support_label: 'Advisory evidence',
    capability_posture: 'advisory-evidence',
  });
}

function capabilityPressure(
  command: string,
  route: {
    route_id: string;
    runtime_owner: RuntimeOwner;
    proof_class: ProofClass;
    support_label: SupportLabel;
    capability_posture: CapabilityPosture;
    package_owner: PackageOwner;
    unavailable_reason: string;
  },
): EvidenceRoute {
  return {
    route_id: route.route_id,
    runtime_owner: route.runtime_owner,
    platform_runtime: 'browser-chromium',
    command,
    proof_class: route.proof_class,
    support_label: route.support_label,
    coordinate_mode: null,
    artifacts: [],
    known_limitations: pressureLimitations(route.route_id),
    status: 'unavailable',
    unavailable_reason: route.unavailable_reason,
    capability_posture: route.capability_posture,
    package_owner: route.package_owner,
  };
}

function browserLimitations(): string[] {
  return [
    'Screenshots are collateral captured after semantic Playwright assertions pass.',
    'This browser evidence does not prove native share sheet execution, physical-device support, camera support, media-upload support, storefront execution, or generic native runtime support.',
  ];
}

function fieldservLimitations(): string[] {
  return [
    'Fieldserv screenshots are collateral captured after route-owner, support-label, backend-verification, and no-overclaiming assertions pass.',
    'This evidence does not prove production scanner, document scan, camera permission, media upload, local-first mutation, or native rebuild support.',
  ];
}

function learnLoopLimitations(): string[] {
  return [
    'LearnLoop screenshots are collateral captured after route-owner, offline-island, outbox, and backend-projection assertions pass.',
    'This evidence does not prove native storage, reusable sync productization, live storefront execution, or device-local entitlement authority.',
  ];
}

function pressureLimitations(routeId: string): string[] {
  return [
    `${routeId} is represented as Phase 152 capability-map pressure, not shipped runtime support.`,
    'This unavailable evidence row does not prove device execution, native-control availability, commerce-provider execution, or reusable offline mutation support.',
  ];
}

function assertRequiredArtifacts(artifactDir: string, routes: EvidenceRoute[]) {
  for (const route of routes) {
    if (route.proof_class !== 'merge-blocking' || route.status !== 'captured') {
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
