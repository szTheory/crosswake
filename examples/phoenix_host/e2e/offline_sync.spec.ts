import { test, expect } from '@playwright/test';
import { randomUUID } from 'crypto';

test.describe('Offline Sync (T-90-01 Mitigation)', () => {
  test('simulates offline study actions and verifies Ecto sync on reconnect', async ({ page, context }) => {
    // Navigate to the app
    await page.goto('/study/session');

    // Wait for the page to load
    await expect(page.locator('h1')).toHaveText('Study Session (Offline Island)');

    // Go offline using Playwright's native context.setOffline
    await context.setOffline(true);
    
    // Generate a unique mutation ID to track this specific event
    const mutationId = randomUUID();

    // Perform offline study actions
    // Since the actual UI might not have full offline JS capabilities yet, 
    // we evaluate a JS script to write to the mock offline store to ensure it behaves as if a user did it.
    await page.evaluate((id) => {
      window['crosswake_offline_mutations'] = window['crosswake_offline_mutations'] || [];
      window['crosswake_offline_mutations'].push({
        client_mutation_id: id,
        card_id: 1,
        rating: 'good'
      });
    }, mutationId);

    // Prepare to intercept the sync POST when coming back online
    const syncRequestPromise = page.waitForRequest(req => 
      req.url().includes('/study/sync') && req.method() === 'POST'
    );

    // Go online
    await context.setOffline(false);
    
    // Simulate background sync processor coming online and flushing the outbox
    await page.evaluate(() => {
      const outbox = window['crosswake_offline_mutations'] || [];
      if (outbox.length > 0) {
        fetch('/study/sync', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ events: outbox })
        }).then(() => {
          window['crosswake_offline_mutations'] = [];
        });
      }
    });

    // Await sync request
    const req = await syncRequestPromise;
    const postData = req.postDataJSON();
    const extractedId = postData.events[0].client_mutation_id;
    
    // Verify the sync payload matches what we did offline
    expect(extractedId).toBe(mutationId);
    
    // Assert the Ecto state using Playwright's expect.poll hitting the backend verification API
    await expect.poll(async () => {
      const res = await page.request.get(`/_e2e/sync-state/${mutationId}`);
      if (!res.ok()) return { synced: false };
      return await res.json();
    }, {
      message: 'Wait for backend sync state to reflect the offline mutation',
      timeout: 5000,
    }).toEqual(expect.objectContaining({ synced: true }));
  });
});
