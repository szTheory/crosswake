// crosswake-proof-lane template_version=1
import { type BrowserContext, type Page } from '@playwright/test';

const OPAQUE_MUTATION_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const MUTATION_ID_ERROR = 'PL-BROWSER-MUTATION-ID';

export type ProofLaneConfig = {
  routePath: string;
  databaseName: string;
  storeName: string;
  mutationIdPath: string;
  syncPath: string;
  evidencePath: string;
};

export type ProofLaneAdapter = {
  navigate(page: Page, config: ProofLaneConfig): Promise<void>;
  performMutation(page: Page): Promise<void>;
  readQueuedRecord(page: Page, config: ProofLaneConfig): Promise<unknown>;
  reconnect(page: Page, config: ProofLaneConfig): Promise<void>;
  assertBackendConfirmation(mutationId: string, config: ProofLaneConfig): Promise<void>;
  assertOutboxEmpty(page: Page, config: ProofLaneConfig): Promise<void>;
  assertDuplicateIdempotency(mutationId: string, record: unknown, config: ProofLaneConfig): Promise<void>;
};

export function extractMutationId(record: unknown, fieldPath: string): string {
  const value = fieldPath.split('.').reduce<unknown>((current, field) =>
    current && typeof current === 'object' ? (current as Record<string, unknown>)[field] : undefined,
  record);
  if (typeof value !== 'string' || !OPAQUE_MUTATION_ID.test(value)) {
    throw new Error(MUTATION_ID_ERROR);
  }

  return value;
}

export async function runOfflineIslandProof(page: Page, context: BrowserContext, adapter: ProofLaneAdapter, config: ProofLaneConfig): Promise<string> {
  await adapter.navigate(page, config);
  await context.setOffline(true);
  let record: unknown;
  let mutationId: string;

  try {
    await adapter.performMutation(page);
    record = await adapter.readQueuedRecord(page, config);
    mutationId = extractMutationId(record, config.mutationIdPath);
  } finally {
    await context.setOffline(false);
  }

  await adapter.reconnect(page, config);
  await adapter.assertBackendConfirmation(mutationId!, config);
  await adapter.assertOutboxEmpty(page, config);
  await adapter.assertDuplicateIdempotency(mutationId!, record!, config);
  return mutationId!;
}

export const proofLaneConfig: ProofLaneConfig = {
  routePath: "/study/:id",
  databaseName: "proof_lane",
  storeName: "mutations",
  mutationIdPath: "client_mutation_id",
  syncPath: "/study/sync",
  evidencePath: "/_proof/evidence",
};
