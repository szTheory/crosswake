import { test, expect } from '@playwright/test';

test.describe('Offline Storage Quota Enforcement', () => {
  test('shows hard block when journal reserve is unfulfilled', async ({ page }) => {
    // Mock navigator.storage.estimate to return low bytes (remaining = 1MB, reserve = 5MB)
    await page.addInitScript(() => {
      Object.defineProperty(navigator, 'storage', {
        value: {
          estimate: async () => ({
            quota: 10000000,
            usage: 9000000 // 1MB remaining
          })
        },
        configurable: true
      });
    });

    await page.goto('/offline');
    
    // Check for the boundary card
    const header = page.locator('h1', { hasText: 'Storage is critically full.' });
    await expect(header).toBeVisible();
    
    // Ensure the interactive session elements are absent
    const container = page.locator('#flashcard-container');
    await expect(container).not.toBeVisible();
  });

  test('allows entry when reserve is satisfied', async ({ page }) => {
    // Mock navigator.storage.estimate with sufficient bytes
    await page.addInitScript(() => {
      Object.defineProperty(navigator, 'storage', {
        value: {
          estimate: async () => ({
            quota: 100000000,
            usage: 10000000 // 90MB remaining
          })
        },
        configurable: true
      });
    });

    await page.goto('/offline');
    
    // Check that the regular UI is visible
    const header = page.locator('h1', { hasText: 'Offline Study Island' });
    await expect(header).toBeVisible();
    
    // And NO hard block card
    const blockHeader = page.locator('h1', { hasText: 'Storage is critically full.' });
    await expect(blockHeader).not.toBeVisible();
  });

  test('displays graceful error on runtime QuotaExceededError', async ({ page, context }) => {
    // Satisfy upfront block
    await page.addInitScript(() => {
      Object.defineProperty(navigator, 'storage', {
        value: {
          estimate: async () => ({
            quota: 100000000,
            usage: 10000000
          })
        },
        configurable: true
      });
      
      // Refuse the scoped outbox transaction as IndexedDB does when quota is exhausted.
      const originalTransaction = IDBDatabase.prototype.transaction;
      IDBDatabase.prototype.transaction = function(...args) {
        if (args[0] === 'scoped_mutations' && args[1] === 'readwrite') {
          throw new DOMException('Quota exceeded.', 'QuotaExceededError');
        }
        return originalTransaction.apply(this, args);
      };
    });

    await page.goto('/offline');
    await context.setOffline(true);
    await page.evaluate(() => window.crosswakeOfflineStudy.activateScope('v1.scope_fixture_alpha_01'));
    
    // Flip a card and pass it to trigger a mutation save
    await page.click('#btn-flip');
    await page.click('#btn-good');

    // Check that the inline notification appears
    const notification = page.locator('text=Device storage limit reached! Cannot save more progress. Please free up space on your device.');
    await expect(notification).toBeVisible();
    
    // Verify we didn't crash completely - the status message should also say handled
    await expect(page.locator('#status')).toHaveText('QuotaExceededError handled gracefully.');
  });
});
