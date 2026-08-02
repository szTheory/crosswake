import { expect, type APIRequestContext, type Page } from '@playwright/test';
import { type ProofLaneAdapter } from './proof_lane';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
  type OfflineMutationRecord,
} from '../../support/offline_route_proof';

let request: APIRequestContext;
let proofPage: Page;

export const proofLaneHostAdapter = {
  navigate: async (page) => {
    request = page.request;
    proofPage = page;
    await resetOfflineStudyDatabase(page);
    await page.goto('/offline');
    await expect(page.locator('#status')).toContainText('Sync is paused');
    await page.evaluate(() => window.crosswakeOfflineStudy.activateScope('v1.scope_fixture_alpha_01'));
    expect(await page.evaluate(() => !!window.liveSocket)).toBe(false);
  },
  performMutation: async (page) => {
    await page.click('#btn-flip');
    await page.click('#btn-good');
  },
  readQueuedRecord: async (page) => {
    const queued = await readQueuedOfflineMutations(page);
    expect(queued).toHaveLength(1);
    assertAppGeneratedMutation(queued[0]);
    return queued[0];
  },
  reconnect: async (page, config) => {
    const syncResponse = page.waitForResponse(response =>
      response.url().includes(config.syncPath) && response.status() === 200,
    );
    await page.evaluate(() => window.dispatchEvent(new Event('online')));
    await syncResponse;
  },
  assertBackendConfirmation: mutationId => expectSyncedReview(request, mutationId),
  assertOutboxEmpty: page => expectOutboxEmpty(page),
  assertDuplicateIdempotency: async (mutationId, record, config) => {
    const mutation = record as OfflineMutationRecord;
    const duplicate = await request.post(config.syncPath, {
      data: {
        scope_ref: 'v1.scope_fixture_alpha_01',
        events: [{
          client_mutation_id: mutationId,
          card_id: mutation.card_id,
          rating: mutation.rating,
        }],
      },
    });

    expect(duplicate.ok()).toBe(true);
    const body = await duplicate.json();
    expect(body.data.accepted_records).toEqual([{ client_mutation_id: mutationId, outcome: 'accepted' }]);
    await expectSyncedReview(request, mutationId, 1);
    await expectOutboxEmpty(proofPage);
  },
} satisfies ProofLaneAdapter;
