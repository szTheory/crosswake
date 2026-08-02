import { canSatisfyJournalReserve } from './storage_logic.js';

const DB_NAME = 'crosswake_offline_study';
const DB_VERSION = 3;
const STORE_CARDS = 'flashcards';
const STORE_MUTATIONS = 'scoped_mutations';
const STORE_LIFECYCLE = 'scope_lifecycle';
const SCOPE_REF_PATTERN = /^v[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}$/;

let db;
let currentCardIndex = 0;
let cards = [];
let activeScopeRef = null;
let activeEpoch = 0;

function isScopeRef(value) {
  return typeof value === 'string' && SCOPE_REF_PATTERN.test(value);
}

function requireActiveLease() {
  if (!isScopeRef(activeScopeRef) || !Number.isSafeInteger(activeEpoch) || activeEpoch < 1) {
    throw new Error('CW-OFFLINE-SCOPE-INACTIVE');
  }

  return { scopeRef: activeScopeRef, epoch: activeEpoch };
}

// The host calls this only after it has independently established backend authority.
// The scope is intentionally never rendered, logged, or copied into status text.
async function activateScope(scopeRef) {
  if (!isScopeRef(scopeRef)) {
    throw new Error('CW-OFFLINE-SCOPE-REF');
  }

  const lifecycle = await readLifecycle();
  if (lifecycle.state !== 'inactive') {
    throw new Error('CW-OFFLINE-SCOPE-TRANSITION');
  }

  activeEpoch = lifecycle.epoch + 1;
  activeScopeRef = scopeRef;
  await writeLifecycle({ key: 'active', state: 'active', scope_ref: scopeRef, epoch: activeEpoch });
  updateStatus('Saved changes will sync when ready.');
}

async function fenceScope() {
  const lifecycle = await readLifecycle();
  const epoch = lifecycle.epoch + 1;
  activeScopeRef = null;
  activeEpoch = 0;
  await writeLifecycle({ key: 'active', state: 'stopping', scope_ref: null, epoch });
  await writeLifecycle({ key: 'active', state: 'inactive', scope_ref: null, epoch });
  updateStatus('Sync is paused. Your saved changes remain on this device. Sign in again or try later.');
}

function leaseIsCurrent(lease) {
  return activeScopeRef === lease.scopeRef && activeEpoch === lease.epoch;
}

window.crosswakeOfflineStudy = Object.freeze({ activateScope, fenceScope });

function configuredSyncEndpoint() {
  const endpoint = document.body.dataset.syncEndpoint;
  return endpoint && endpoint.trim() ? endpoint : '/study/sync';
}

document.addEventListener('DOMContentLoaded', async () => {
  try {
    const reserveForJournalStr = document.body.dataset.reserveForJournal;
    const reserveForJournal = parseInt(reserveForJournalStr, 10);
    
    if (navigator.storage && navigator.storage.estimate) {
      const estimate = await navigator.storage.estimate();
      const quota = estimate.quota || 0;
      const usage = estimate.usage || 0;
      
      if (!isNaN(reserveForJournal) && !canSatisfyJournalReserve(quota, usage, reserveForJournal)) {
        displayHardBlock();
        return; // Prevent initialization
      }
    }

    await initDB();
    
    // For demo purposes, if no cards exist, we insert some dummy ones
    const existingCards = await getAllCards();
    if (existingCards.length === 0) {
      await seedDummyCards();
    }

    cards = await getAllCards();
    renderCurrentCard();
    setupEventListeners();
    await resetLifecycleOnLaunch();
    updateStatus('Sync is paused. Your saved changes remain on this device. Sign in again or try later.');
  } catch (error) {
    updateStatus('Sync is paused. Your saved changes remain on this device. Sign in again or try later.');
  }
});

function displayHardBlock() {
  const body = document.body;
  body.innerHTML = `
    <div style="padding: 2rem; text-align: center; color: var(--cw-text-default); font-weight: bold; border-left: 3px solid var(--cw-status-error); padding-left: 0.5rem; border-radius: 8px; max-width: 600px; margin: 2rem auto;">
      <h1>Storage is critically full.</h1>
      <p>Please free space before starting this session to ensure your progress is saved.</p>
    </div>
  `;
}

function initDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    
    request.onerror = (event) => reject(event.target.error);
    
    request.onsuccess = (event) => {
      db = event.target.result;
      resolve();
    };
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(STORE_CARDS)) {
        db.createObjectStore(STORE_CARDS, { keyPath: 'id' });
      }
      if (!db.objectStoreNames.contains(STORE_MUTATIONS)) {
        const mutations = db.createObjectStore(STORE_MUTATIONS, { keyPath: ['scope_ref', 'local_ref'] });
        mutations.createIndex('by_scope', 'scope_ref', { unique: false });
      }
      if (!db.objectStoreNames.contains(STORE_LIFECYCLE)) {
        db.createObjectStore(STORE_LIFECYCLE, { keyPath: 'key' });
      }
    };
  });
}

function readLifecycle() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_LIFECYCLE, 'readonly');
    const request = tx.objectStore(STORE_LIFECYCLE).get('active');
    request.onsuccess = () => resolve(request.result || { key: 'active', state: 'inactive', scope_ref: null, epoch: 0 });
    request.onerror = () => reject(request.error);
  });
}

function writeLifecycle(lifecycle) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_LIFECYCLE, 'readwrite');
    tx.objectStore(STORE_LIFECYCLE).put(lifecycle);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error);
  });
}

async function resetLifecycleOnLaunch() {
  const prior = await readLifecycle();
  activeScopeRef = null;
  activeEpoch = 0;
  await writeLifecycle({ key: 'active', state: 'inactive', scope_ref: null, epoch: prior.epoch + 1 });
}

function seedDummyCards() {
  const dummyCards = [
    { id: '1', front: 'Elixir', back: 'A dynamic, functional language designed for building scalable and maintainable applications.' },
    { id: '2', front: 'Phoenix', back: 'A web framework built for the Elixir language, known for its performance and real-time capabilities.' },
    { id: '3', front: 'IndexedDB', back: 'A low-level API for client-side storage of significant amounts of structured data.' }
  ];
  
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_CARDS, 'readwrite');
    const store = tx.objectStore(STORE_CARDS);
    
    dummyCards.forEach(card => store.put(card));
    
    tx.oncomplete = () => resolve();
    tx.onerror = (event) => reject(event.target.error);
  });
}

function getAllCards() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_CARDS, 'readonly');
    const store = tx.objectStore(STORE_CARDS);
    const request = store.getAll();
    
    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
  });
}

function queueMutation(scopeRef, mutation) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.add({ ...mutation, scope_ref: scopeRef, local_ref: mutation.client_mutation_id });

    request.onsuccess = () => resolve();
    request.onerror = (event) => {
      reject(event.target.error);
    };
    tx.onabort = () => {
      reject(tx.error);
    };
  });
}

function getScopeMutations(scopeRef) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readonly');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.index('by_scope').getAll(scopeRef);

    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

function deleteAcceptedMutations(scopeRef, records, acceptedIds) {
  const acceptedIdSet = new Set(acceptedIds);
  const toDelete = records.filter(r => acceptedIdSet.has(r.client_mutation_id)).map(r => [scopeRef, r.local_ref]);
  if (toDelete.length === 0) return Promise.resolve();

  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    const store = tx.objectStore(STORE_MUTATIONS);
    toDelete.forEach(id => store.delete(id));

    tx.oncomplete = () => resolve();
    tx.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

function countScopeMutations(scopeRef) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readonly');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.index('by_scope').count(scopeRef);

    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

function updateStatusClear() {
  const statusElement = document.getElementById('status');
  if (statusElement) {
    statusElement.style.borderLeft = '';
    statusElement.style.paddingLeft = '';
    statusElement.style.color = '';
  }
}

function updateStatusError() {
  const statusElement = document.getElementById('status');
  if (statusElement) {
    statusElement.style.borderLeft = '3px solid var(--cw-status-error)';
    statusElement.style.paddingLeft = '0.5rem';
    statusElement.style.color = 'var(--cw-text-default)';
  }
}

async function updateQueuedStatus(prefix = 'Queued for replay') {
  const { scopeRef } = requireActiveLease();
  const queued = await countScopeMutations(scopeRef).catch(() => 0);
  updateStatus(`${prefix} - ${queued} saved locally`);
}

let flushing = false;

async function flushOutbox() {
  if (flushing) return;
  flushing = true;
  try {
    const lease = requireActiveLease();
    const { scopeRef } = lease;
    const records = await getScopeMutations(scopeRef);
    if (records.length === 0) return;

    updateStatusClear();
    updateStatus('Syncing');

    let response;
    try {
      response = await fetch(configuredSyncEndpoint(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scope_ref: scopeRef,
          events: records.map(r => ({
            client_mutation_id: r.client_mutation_id,
            card_id: r.card_id,
            rating: r.rating
          }))
        })
      });
    } catch (_networkError) {
      updateStatusError();
      updateStatus(`Queued for replay - ${records.length} saved locally. Retrying on reconnect.`);
      return;
    }

    if (response.ok) {
      const data = await response.json();
      if (!leaseIsCurrent(lease)) return;
      const acceptedRecords = (data.data && data.data.accepted_records) || [];
      const rejected = (data.data && data.data.rejected) || [];

      const acceptedIds = acceptedRecords.map(r => r.client_mutation_id);
      await deleteAcceptedMutations(scopeRef, records, acceptedIds);

      const remaining = await countScopeMutations(scopeRef);
      const accepted = acceptedIds.length;

      if (rejected.length > 0) {
        updateStatusError();
        updateStatus('Saved changes need attention and remain on this device.');
      } else {
        updateStatusClear();
        updateStatus(`Synced ${accepted} - queued ${remaining}`);
      }
    } else {
      updateStatusError();
      updateStatus('Sync is paused. Your saved changes remain on this device. Sign in again or try later.');
    }
  } finally {
    flushing = false;
  }
}

function renderCurrentCard() {
  const container = document.getElementById('flashcard-container');
  const btnFlip = document.getElementById('btn-flip');
  const btnGood = document.getElementById('btn-good');
  const btnHard = document.getElementById('btn-hard');

  if (currentCardIndex >= cards.length) {
    container.innerHTML = '<div>You have finished all cards!</div>';
    btnFlip.style.display = 'none';
    btnGood.style.display = 'none';
    btnHard.style.display = 'none';
    return;
  }

  const card = cards[currentCardIndex];

  container.innerHTML = `
    <div class="card-front">${card.front}</div>
    <div class="card-back" id="card-back">${card.back}</div>
  `;

  btnFlip.style.display = 'block';
  btnGood.style.display = 'none';
  btnHard.style.display = 'none';
  updateStatus(`Card ${currentCardIndex + 1} of ${cards.length}`);
}

function setupEventListeners() {
  const btnFlip = document.getElementById('btn-flip');
  const btnGood = document.getElementById('btn-good');
  const btnHard = document.getElementById('btn-hard');

  btnFlip.addEventListener('click', () => {
    document.getElementById('card-back').style.display = 'block';
    btnFlip.style.display = 'none';
    btnGood.style.display = 'block';
    btnHard.style.display = 'block';
  });

  btnGood.addEventListener('click', () => handleReview('good'));
  btnHard.addEventListener('click', () => handleReview('hard'));

  window.addEventListener('online', flushOutbox);
  window.addEventListener('offline', async () => {
    updateStatusClear();
    if (activeScopeRef) await updateQueuedStatus('Queued for replay');
  });

  // Retained work stays inert until the host calls activateScope with fresh authority.
}

async function handleReview(rating) {
  const card = cards[currentCardIndex];

  const mutation = {
    client_mutation_id: crypto.randomUUID(),
    card_id: parseInt(card.id, 10),
    rating: rating
  };

  try {
    const lease = requireActiveLease();
    const { scopeRef } = lease;
    await queueMutation(scopeRef, mutation);
    if (!leaseIsCurrent(lease)) return;
    updateStatusClear();
    updateStatus('Saved locally');

    currentCardIndex++;
    renderCurrentCard();
    await updateQueuedStatus('Saved locally - Queued for replay');

    if (navigator.onLine) {
      flushOutbox();
    }
  } catch (error) {
    if (error && error.name === 'QuotaExceededError') {
      const container = document.getElementById('flashcard-container');
      const errorMsg = document.createElement('div');
      errorMsg.style.color = 'var(--cw-text-default)';
      errorMsg.style.fontWeight = 'bold';
      errorMsg.style.marginTop = '1rem';
      errorMsg.textContent = 'Device storage limit reached! Cannot save more progress. Please free up space on your device.';
      container.prepend(errorMsg);
      updateStatusClear();
      updateStatus('QuotaExceededError handled gracefully.');
    } else {
      updateStatusClear();
      updateStatus('Sync is paused. Your saved changes remain on this device. Sign in again or try later.');
    }
  }
}

function updateStatus(message) {
  const statusElement = document.getElementById('status');
  if (statusElement) {
    statusElement.textContent = message;
  }
}
