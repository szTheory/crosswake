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

  test('displays graceful error on runtime QuotaExceededError', async ({ page }) => {
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
      
      // Override IDBObjectStore.prototype.add to simulate QuotaExceededError
      const originalAdd = IDBObjectStore.prototype.add;
      IDBObjectStore.prototype.add = function(...args) {
        const req = originalAdd.apply(this, args);
        if (this.name === 'mutations') {
          setTimeout(() => {
            if (req.onerror) {
              const err = new DOMException('Quota exceeded.', 'QuotaExceededError');
              const event = new Event('error');
              Object.defineProperty(event, 'target', { value: { error: err } });
              req.onerror(event);
            }
          }, 0);
        }
        return req;
      };
    });

    await page.goto('/offline');
    
    // Flip a card and pass it to trigger a mutation save
    await page.click('#btn-flip');
    await page.click('#btn-pass');
    
    // Check that the inline notification appears
    const notification = page.locator('text=Device storage limit reached! Cannot save more progress.');
    await expect(notification).toBeVisible();
    
    // Verify we didn't crash completely - the status message should also say handled
    const status = page.locator('#status', { hasText: 'QuotaExceededError handled gracefully.' });
    await expect(status).toBeVisible();
  });
});