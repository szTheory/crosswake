import { expect, test } from '@playwright/test';
import {
  assertAppGeneratedMutation,
  expectOutboxEmpty,
  expectSyncedReview,
  readQueuedOfflineMutations,
  resetOfflineStudyDatabase,
  type OfflineMutationRecord,
} from '../support/offline_route_proof';
import { proofLaneConfig, runOfflineIslandProof } from './support/proof_lane';

test.describe('Crosswake generated proof lane: Phoenix host adapter', () => {
  test.beforeEach(async ({ page }) => {
    await resetOfflineStudyDatabase(page);
  });

  test('drives one UI mutation through IndexedDB, application reconnect, and exactly-once Phoenix replay', async ({
    page,
    context,
  }) => {
    await runOfflineIslandProof(page, context, {
      navigate: async () => {
        await page.goto('/offline');
        await expect(page.locator('#status')).toContainText('Sync is paused');
        await page.evaluate(() => window.crosswakeOfflineStudy.activateScope('v1.scope_fixture_alpha_01'));
        expect(await page.evaluate(() => !!window.liveSocket)).toBe(false);
      },
      performMutation: async () => {
        await page.click('#btn-flip');
        await page.click('#btn-good');
      },
      readQueuedRecord: async () => {
        const queued = await readQueuedOfflineMutations(page);
        expect(queued).toHaveLength(1);
        assertAppGeneratedMutation(queued[0]);
        return queued[0];
      },
      reconnect: async () => {
        const syncResponse = page.waitForResponse(response =>
          response.url().includes(proofLaneConfig.syncPath) && response.status() === 200,
        );
        await page.evaluate(() => window.dispatchEvent(new Event('online')));
        await syncResponse;
      },
      assertBackendConfirmation: mutationId => expectSyncedReview(page.request, mutationId),
      assertOutboxEmpty: () => expectOutboxEmpty(page),
      assertDuplicateIdempotency: async (mutationId, record) => {
        const mutation = record as OfflineMutationRecord;
        const duplicate = await page.request.post(proofLaneConfig.syncPath, {
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
        await expectSyncedReview(page.request, mutationId, 1);
        await expectOutboxEmpty(page);
      },
    }, proofLaneConfig);
  });
});
