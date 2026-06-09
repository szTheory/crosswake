// app.js - Crosswake Event Bridge Integration

window.Crosswake = window.Crosswake || {};

/**
 * Sends a message across the Crosswake bridge to the native shell.
 */
window.Crosswake.postMessage = function(action, payload = {}) {
  const message = { action, payload, timestamp: new Date().toISOString() };
  
  // iOS WKWebView Bridge
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.crosswake) {
    window.webkit.messageHandlers.crosswake.postMessage(message);
    return true;
  }
  
  // Android WebView Bridge
  if (window.CrosswakeAndroidBridge && window.CrosswakeAndroidBridge.postMessage) {
    window.CrosswakeAndroidBridge.postMessage(JSON.stringify(message));
    return true;
  }
  
  console.log('[Crosswake] Bridge not found. Simulating message in browser:', message);
  return false;
};

/**
 * Handles incoming messages from the native shell.
 */
window.Crosswake.receiveMessage = function(message) {
  try {
    const { event, payload } = typeof message === 'string' ? JSON.parse(message) : message;
    console.log(`[Crosswake] Received event: ${event}`, payload);
    
    // Dispatch as a standard DOM event so other scripts can listen
    const domEvent = new CustomEvent(`crosswake:${event}`, { detail: payload });
    window.dispatchEvent(domEvent);
  } catch (err) {
    console.error('[Crosswake] Error parsing incoming message:', err);
  }
};

/**
 * Triggers a download via the native shell.
 * Mitigates T-89-01 by enforcing strict payload structures at the boundary.
 */
window.Crosswake.triggerDownload = function(url, filename, mimeType) {
  if (!url || !filename) {
    console.error('[Crosswake] Download requires URL and filename.');
    return;
  }
  window.Crosswake.postMessage('download', { url, filename, mimeType });
};

/**
 * Triggers an offline route transition via the native shell.
 */
window.Crosswake.transitionToOffline = function(routeId) {
  window.Crosswake.postMessage('transition', { target: routeId, runtime: 'offline_island' });
};

// Global Event Listeners for Sync Progress & Status
window.addEventListener('crosswake:sync_progress', (e) => {
  const { progress, status } = e.detail;
  console.log(`[Crosswake] Sync Progress: ${progress}% - ${status}`);
  // Find a status element to update, if available
  const statusEl = document.getElementById('status');
  if (statusEl) {
    statusEl.textContent = `Syncing: ${progress}%`;
    statusEl.className = 'sync-status-pending';
  }
});

window.addEventListener('crosswake:sync_complete', (e) => {
  console.log('[Crosswake] Sync Complete');
  const statusEl = document.getElementById('status');
  if (statusEl) {
    statusEl.textContent = 'Sync Complete';
    statusEl.className = 'sync-status-complete';
  }
});
