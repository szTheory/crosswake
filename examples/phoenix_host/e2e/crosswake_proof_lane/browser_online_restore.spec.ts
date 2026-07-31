import { expect, test } from '@playwright/test';
import {
  runOfflineIslandProof as runRepositoryProof,
  type OfflineIslandProofAdapter,
} from '../support/offline_route_proof';
import {
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
