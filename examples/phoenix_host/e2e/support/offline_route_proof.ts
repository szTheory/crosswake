import { expect, type APIRequestContext, type Page } from '@playwright/test';

const DEFAULT_OFFLINE_STUDY_DB = 'crosswake_offline_study';

export type OfflineMutationRecord = {
  id?: number;
  client_mutation_id: string;
  card_id: number;
  rating: string;
};

export type OfflineRouteProofOptions = {
  databaseName?: string;
};

export async function resetOfflineStudyDatabase(page: Page, options: OfflineRouteProofOptions = {}) {
  const databaseName = options.databaseName ?? DEFAULT_OFFLINE_STUDY_DB;

  await page.addInitScript((dbName: string) => {
    indexedDB.deleteDatabase(dbName);
  }, databaseName);
}

export async function readQueuedOfflineMutations(
  page: Page,
  options: OfflineRouteProofOptions = {},
): Promise<OfflineMutationRecord[]> {
  const databaseName = options.databaseName ?? DEFAULT_OFFLINE_STUDY_DB;

  return page.evaluate((dbName: string) => {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(dbName, 1);
      req.onsuccess = () => {
        const db = req.result;
        const tx = db.transaction('mutations', 'readonly');
        const store = tx.objectStore('mutations');
        const getAll = store.getAll();
        getAll.onsuccess = () => resolve(getAll.result);
        getAll.onerror = () => reject(getAll.error);
      };
      req.onerror = () => reject(req.error);
    });
  }, databaseName);
}

export async function expectSyncedReview(request: APIRequestContext, clientMutationId: string, expectedCount = 1) {
  await expect.poll(async () => {
    const res = await request.get(`/_e2e/sync-state/${clientMutationId}`);
    return res.ok() ? res.json() : { synced: false, count: -1 };
  }, {
    timeout: 8000,
    message: `offline-study Ecto row should reflect app-flushed mutation ${clientMutationId}`,
  }).toMatchObject({ synced: true, count: expectedCount });
}

export async function expectOutboxEmpty(page: Page, options: OfflineRouteProofOptions = {}) {
  const remaining = await readQueuedOfflineMutations(page, options);
  expect(remaining).toHaveLength(0);
}

export function assertAppGeneratedMutation(record: OfflineMutationRecord) {
  expect(typeof record.client_mutation_id).toBe('string');
  expect(record.client_mutation_id).toMatch(/^[0-9a-f-]{36}$/);
  expect(record.rating).toMatch(/^(good|hard)$/);
}
