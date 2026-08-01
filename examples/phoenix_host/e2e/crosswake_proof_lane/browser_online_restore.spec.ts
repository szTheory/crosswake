import { expect, test } from '@playwright/test';
import {
  extractMutationId as extractRepositoryMutationId,
  runOfflineIslandProof as runRepositoryProof,
  type OfflineIslandProofAdapter,
} from '../support/offline_route_proof';
import {
  extractMutationId as extractGeneratedMutationId,
  runOfflineIslandProof as runGeneratedProof,
  type ProofLaneAdapter,
} from './support/proof_lane';

const config = {
  databaseName: 'proof_lane',
  storeName: 'mutations',
  mutationIdPath: 'client_mutation_id',
  syncPath: '/study/sync',
  evidencePath: '/_proof/evidence',
  routePath: '/study/:id',
};

function contextLog(events: boolean[]) {
  return {
    setOffline: async (offline: boolean) => {
      events.push(offline);
    },
  };
}

test('repository helper restores online state before propagating a mutation rejection', async () => {
  const failure = new Error('repository mutation failure');
  const events: boolean[] = [];
  let downstreamReached = false;
  const adapter: OfflineIslandProofAdapter = {
    navigate: async () => undefined,
    performMutation: async () => {
      throw failure;
    },
    readQueuedRecord: async () => ({ client_mutation_id: '00000000-0000-0000-0000-000000000000' }),
    reconnect: async () => { downstreamReached = true; },
    assertBackendConfirmation: async () => { downstreamReached = true; },
    assertOutboxEmpty: async () => { downstreamReached = true; },
    assertDuplicateIdempotency: async () => { downstreamReached = true; },
  };

  await expect(runRepositoryProof({} as never, contextLog(events) as never, adapter, config)).rejects.toBe(failure);
  expect(events).toEqual([true, false]);
  expect(downstreamReached).toBe(false);
});

test('rendered generated helper restores online state before propagating a mutation rejection', async () => {
  const failure = new Error('generated mutation failure');
  const events: boolean[] = [];
  let downstreamReached = false;
  const adapter: ProofLaneAdapter = {
    navigate: async () => undefined,
    performMutation: async () => {
      throw failure;
    },
    readQueuedRecord: async () => ({ client_mutation_id: '00000000-0000-0000-0000-000000000000' }),
    reconnect: async () => { downstreamReached = true; },
    assertBackendConfirmation: async () => { downstreamReached = true; },
    assertOutboxEmpty: async () => { downstreamReached = true; },
    assertDuplicateIdempotency: async () => { downstreamReached = true; },
  };

  await expect(runGeneratedProof({} as never, contextLog(events) as never, adapter, config)).rejects.toBe(failure);
  expect(events).toEqual([true, false]);
  expect(downstreamReached).toBe(false);
});

test('repository and generated helpers accept only lowercase opaque mutation IDs', () => {
  const validMutationId = '01234567-89ab-cdef-0123-456789abcdef';
  const invalidMutationIds = [
    '',
    'opaque-canary',
    '01234567-89AB-cdef-0123-456789abcdef',
    '0123456789ab-cdef-0123-456789abcdef',
    '/scope/opaque-canary',
    'opaque-canary@example.invalid',
  ];

  for (const extractMutationId of [extractRepositoryMutationId, extractGeneratedMutationId]) {
    expect(extractMutationId({ client_mutation_id: validMutationId }, 'client_mutation_id')).toBe(validMutationId);

    for (const invalidMutationId of invalidMutationIds) {
      try {
        extractMutationId({ client_mutation_id: invalidMutationId }, 'client_mutation_id');
        throw new Error('expected opaque mutation-ID validation failure');
      } catch (error) {
        expect(error).toBeInstanceOf(Error);
        expect((error as Error).message).toBe('PL-BROWSER-MUTATION-ID');
        if (invalidMutationId) {
          expect((error as Error).message).not.toContain(invalidMutationId);
        }
      }
    }
  }
});

test('repository helper rejects invalid mutation IDs before proof callbacks', async () => {
  const events: boolean[] = [];
  let downstreamReached = false;
  const adapter: OfflineIslandProofAdapter = {
    navigate: async () => undefined,
    performMutation: async () => undefined,
    readQueuedRecord: async () => ({ client_mutation_id: 'opaque-canary@example.invalid' }),
    reconnect: async () => { downstreamReached = true; },
    assertBackendConfirmation: async () => { downstreamReached = true; },
    assertOutboxEmpty: async () => { downstreamReached = true; },
    assertDuplicateIdempotency: async () => { downstreamReached = true; },
  };

  await expect(runRepositoryProof({} as never, contextLog(events) as never, adapter, config)).rejects.toThrow(
    'PL-BROWSER-MUTATION-ID',
  );
  expect(events).toEqual([true, false]);
  expect(downstreamReached).toBe(false);
});
