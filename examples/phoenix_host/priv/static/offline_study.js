import { canSatisfyJournalReserve } from './storage_logic.js';

const DB_NAME = 'crosswake_offline_study';
const DB_VERSION = 4;
const STORE_CARDS = 'flashcards';
const STORE_MUTATIONS = 'scoped_mutations';
const STORE_LIFECYCLE = 'scope_lifecycle';
const STORE_LEGACY_MUTATIONS = 'mutations';
const STORE_LEGACY_QUARANTINE = 'legacy_mutations_quarantine';
const SCOPE_REF_PATTERN = /^v[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}$(?![\s\S])/;
const CLIENT_MUTATION_ID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const HALTED_REPLAY_CLASSES = new Set([
  'authority_unavailable',
  'authorization_denied',
  'feature_disabled',
  'invalid_envelope',
  'scope_mismatch',
  'sigra_denied',
  'transaction_failed',
]);
const STUDY_STATUS_PRESENTATIONS = Object.freeze({
  saved_locally: Object.freeze({ label: 'Saved on this iPhone.', message: 'It will sync when you’re back online.', icon: '●' }),
  syncing: Object.freeze({ label: 'Syncing saved answers…', message: '', icon: '↻' }),
  needs_attention: Object.freeze({ label: 'Some saved answers need review.', message: '', icon: '▲' }),
  sync_paused: Object.freeze({ label: 'Saved answers paused', message: 'Your saved answers remain on this iPhone.', icon: 'Ⅱ' }),
});

let db;
let currentCardIndex = 0;
let cards = [];
let activeScopeRef = null;
let activeEpoch = 0;
let legacyRecoveryRequired = false;
let reviewSubmissionOwned = false;
let currentStudyStatus = null;

function isScopeRef(value) {
  return typeof value === 'string' && SCOPE_REF_PATTERN.test(value);
}

function requireActiveLease() {
  if (!isScopeRef(activeScopeRef) || !Number.isSafeInteger(activeEpoch) || activeEpoch < 1) {
    throw new Error('CW-OFFLINE-SCOPE-INACTIVE');
  }

  return { scopeRef: activeScopeRef, epoch: activeEpoch };
}

function activeLeaseOrNull() {
  if (!isScopeRef(activeScopeRef) || !Number.isSafeInteger(activeEpoch) || activeEpoch < 1) {
    return null;
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
  renderStudyStatus('sync_paused');
  if (navigator.onLine) replayOnOnline();
}

async function fenceScope() {
  // Revoke browser authority before the first await. A response already on the
  // wire remains server-authorized independently, but it can no longer touch
  // this browser's storage or learner status.
  const worker = activeFlush;
  activeScopeRef = null;
  activeEpoch = 0;
  worker?.controller.abort();
  worker?.storageTransaction?.abort();

  const lifecycle = await readLifecycle();
  const epoch = lifecycle.epoch + 1;
  await writeLifecycle({ key: 'active', state: 'stopping', scope_ref: null, epoch });
  await worker?.promise.catch(() => undefined);
  await writeLifecycle({ key: 'active', state: 'inactive', scope_ref: null, epoch });
  renderStudyStatus('sync_paused');
}

function leaseIsCurrent(lease) {
  return activeScopeRef === lease.scopeRef && activeEpoch === lease.epoch;
}

function renderPausedStatus() {
  renderStudyStatus('sync_paused');
}

function classifyReplayResponse(data, records) {
  const envelope = data && typeof data === 'object' && !Array.isArray(data) ? data.data : null;
  if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) return { kind: 'blocked' };

  const { accepted_records: acceptedRecords, rejected, halted } = envelope;
  if (!Array.isArray(acceptedRecords) || !Array.isArray(rejected)) return { kind: 'blocked' };
  if (!rejected.every(record => record && typeof record === 'object' && typeof record.class === 'string')) {
    return { kind: 'blocked' };
  }
  if (halted != null && (typeof halted !== 'string' || !HALTED_REPLAY_CLASSES.has(halted))) {
    return { kind: 'blocked' };
  }
  if (halted == null && (acceptedRecords.length !== records.length || rejected.length !== 0)) {
    return { kind: 'blocked' };
  }

  const acceptedIds = [];
  for (let index = 0; index < acceptedRecords.length; index += 1) {
    const accepted = acceptedRecords[index];
    const expected = records[index];
    if (!accepted || typeof accepted !== 'object' || !expected || accepted.client_mutation_id !== expected.client_mutation_id) {
      return { kind: 'blocked' };
    }
    acceptedIds.push(accepted.client_mutation_id);
  }

  return { kind: halted == null ? 'complete' : 'halted', acceptedIds, rejected };
}

window.crosswakeOfflineStudy = Object.freeze({ activateScope, fenceScope, recoverLegacyMutations, refreshStudyStatus });

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
    legacyRecoveryRequired = (await countLegacyQuarantine()) > 0;
    
    // For demo purposes, if no cards exist, we insert some dummy ones
    const existingCards = await getAllCards();
    if (existingCards.length === 0) {
      await seedDummyCards();
    }

    cards = await getAllCards();
    renderCurrentCard();
    setupEventListeners();
    await resetLifecycleOnLaunch();
    renderStudyStatus(legacyRecoveryRequired ? 'needs_attention' : 'sync_paused');
  } catch (error) {
    renderStudyStatus('sync_paused');
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
      const tx = event.target.transaction;
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
      if (!db.objectStoreNames.contains(STORE_LEGACY_QUARANTINE)) {
        db.createObjectStore(STORE_LEGACY_QUARANTINE, { keyPath: 'migration_ref', autoIncrement: true });
      }
      if (db.objectStoreNames.contains(STORE_LEGACY_MUTATIONS)) {
        quarantineLegacyMutations(tx);
      }
    };
  });
}

function quarantineLegacyMutations(tx) {
  const legacyStore = tx.objectStore(STORE_LEGACY_MUTATIONS);
  const quarantineStore = tx.objectStore(STORE_LEGACY_QUARANTINE);
  const cursorRequest = legacyStore.openCursor();

  cursorRequest.onerror = () => tx.abort();
  cursorRequest.onsuccess = () => {
    const cursor = cursorRequest.result;
    if (!cursor) return;

    const quarantineRequest = quarantineStore.add(cursor.value);
    quarantineRequest.onerror = () => tx.abort();
    quarantineRequest.onsuccess = () => {
      const deleteRequest = cursor.delete();
      deleteRequest.onerror = () => tx.abort();
      deleteRequest.onsuccess = () => cursor.continue();
    };
  };
}

function countLegacyQuarantine() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_LEGACY_QUARANTINE, 'readonly');
    const request = tx.objectStore(STORE_LEGACY_QUARANTINE).count();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    tx.onabort = () => reject(tx.error);
  });
}

function recoverLegacyMutations(scopeRef) {
  if (!isScopeRef(scopeRef) || scopeRef !== activeScopeRef) return Promise.resolve('blocked');

  let lease;
  try {
    lease = requireActiveLease();
  } catch (_error) {
    return Promise.resolve('blocked');
  }

  if (lease.scopeRef !== scopeRef) return Promise.resolve('blocked');

  // The example host has no server-verifiable per-record legacy ownership binding.
  // Keep every unowned byte quarantined rather than deriving ownership from a lease.
  return Promise.resolve(legacyRecoveryRequired ? 'recovery_required' : 'recovered');
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

function deleteAcceptedMutations(scopeRef, records, acceptedIds, invocation) {
  const acceptedIdSet = new Set(acceptedIds);
  const toDelete = records.filter(r => acceptedIdSet.has(r.client_mutation_id)).map(r => [scopeRef, r.local_ref]);
  if (toDelete.length === 0) return Promise.resolve();

  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    invocation.storageTransaction = tx;
    const store = tx.objectStore(STORE_MUTATIONS);
    toDelete.forEach(id => store.delete(id));

    tx.oncomplete = () => {
      if (invocation.storageTransaction === tx) invocation.storageTransaction = null;
      resolve();
    };
    tx.onerror = (event) => {
      if (invocation.storageTransaction === tx) invocation.storageTransaction = null;
      reject(event.target.error);
    };
    tx.onabort = () => {
      if (invocation.storageTransaction === tx) invocation.storageTransaction = null;
      reject(tx.error);
    };
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

function validatedRecoveryDestination() {
  const rawDestination = document.body.dataset.recoveryDestination;
  if (typeof rawDestination !== 'string' || rawDestination.length === 0) return null;

  try {
    const destination = new URL(rawDestination, window.location.origin);
    return destination.origin === window.location.origin && destination.protocol === window.location.protocol
      ? destination.href
      : null;
  } catch (_) {
    return null;
  }
}

function renderStudyStatus(state) {
  const presentation = STUDY_STATUS_PRESENTATIONS[state];
  if (!presentation) return;

  const statusElement = document.getElementById('crosswake-study-status');
  const labelElement = document.getElementById('crosswake-study-status-label');
  const messageElement = document.getElementById('crosswake-study-status-message');
  const iconElement = document.getElementById('crosswake-study-status-icon');
  const indicator = document.getElementById('crosswake-study-status-indicator');
  const actionContainer = document.getElementById('crosswake-study-status-action');
  if (!statusElement || !labelElement || !messageElement || !iconElement || !indicator || !actionContainer) return;

  const focusedElement = document.activeElement instanceof HTMLElement ? document.activeElement : null;
  const changed = currentStudyStatus !== state;
  currentStudyStatus = state;
  statusElement.dataset.state = state;
  labelElement.textContent = presentation.label;
  messageElement.textContent = presentation.message;
  messageElement.hidden = presentation.message.length === 0;
  iconElement.textContent = presentation.icon;
  indicator.hidden = state !== 'syncing';
  actionContainer.replaceChildren();

  const destination = state === 'needs_attention' ? validatedRecoveryDestination() : null;
  if (destination) {
    const action = document.createElement('a');
    action.id = 'crosswake-review-saved-answers';
    action.href = destination;
    action.textContent = 'Review saved answers';
    actionContainer.append(action);
  }

  if (focusedElement?.isConnected) focusedElement.focus({ preventScroll: true });

  if (changed) {
    document.dispatchEvent(new CustomEvent('crosswake:study-status-announcement', {
      detail: Object.freeze({ state, announcement: `${presentation.label}${presentation.message ? ` ${presentation.message}` : ''}`, preserveFocus: true }),
    }));
  }
}

function refreshStudyStatus() {
  if (currentStudyStatus) renderStudyStatus(currentStudyStatus);
}

let activeFlush = null;

async function flushOutbox() {
  const lease = activeLeaseOrNull();
  if (!lease) return;
  if (activeFlush) return activeFlush.promise;

  const invocation = {
    lease,
    controller: new AbortController(),
    storageTransaction: null,
    promise: null,
  };
  invocation.promise = flushScopedOutbox(invocation);
  activeFlush = invocation;
  return invocation.promise;
}

function replayOnOnline() {
  const lease = activeLeaseOrNull();
  if (!lease) return;

  void flushOutbox().catch(() => {
    if (leaseIsCurrent(lease)) renderPausedStatus();
  });
}

async function flushScopedOutbox(invocation) {
  const { lease, controller } = invocation;
  const { scopeRef } = lease;
  try {
    const records = await getScopeMutations(scopeRef);
    if (!leaseIsCurrent(lease) || records.length === 0) return;

    renderStudyStatus('syncing');

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
        }),
        signal: controller.signal,
      });
    } catch (_networkError) {
      if (!leaseIsCurrent(lease)) return;
      renderStudyStatus('saved_locally');
      return;
    }

    if (response.ok) {
      let data;
      try {
        data = await response.json();
      } catch (_parseError) {
        if (!leaseIsCurrent(lease)) return;
        renderPausedStatus();
        return;
      }
      if (!leaseIsCurrent(lease)) return;
      const result = classifyReplayResponse(data, records);
      if (result.kind === 'blocked') {
        renderPausedStatus();
        return;
      }

      await deleteAcceptedMutations(scopeRef, records, result.acceptedIds, invocation);
      if (!leaseIsCurrent(lease)) return;

      const remaining = await countScopeMutations(scopeRef);
      if (!leaseIsCurrent(lease)) return;
      const accepted = result.acceptedIds.length;

      if (result.rejected.length > 0) {
        if (!leaseIsCurrent(lease)) return;
        renderStudyStatus('needs_attention');
      } else if (result.kind === 'halted') {
        renderPausedStatus();
      } else {
        if (!leaseIsCurrent(lease)) return;
        renderStudyStatus(remaining > 0 ? 'saved_locally' : 'sync_paused');
      }
    } else {
      if (!leaseIsCurrent(lease)) return;
      renderPausedStatus();
    }
  } finally {
    if (activeFlush === invocation) activeFlush = null;
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
  document.getElementById('card-position').textContent = `Card ${currentCardIndex + 1} of ${cards.length}`;
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

  window.addEventListener('online', replayOnOnline);
  window.addEventListener('offline', async () => {
    if (activeScopeRef) renderStudyStatus('saved_locally');
  });

  // Retained work stays inert until the host calls activateScope with fresh authority.
}

function setReviewControlsDisabled(disabled) {
  document.getElementById('btn-good').disabled = disabled;
  document.getElementById('btn-hard').disabled = disabled;
}

async function handleReview(rating) {
  if (reviewSubmissionOwned) return;

  const card = cards[currentCardIndex];
  if (!card) return;

  reviewSubmissionOwned = true;
  setReviewControlsDisabled(true);

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
    renderStudyStatus('saved_locally');

    currentCardIndex++;
    renderCurrentCard();
    reviewSubmissionOwned = false;
    setReviewControlsDisabled(false);
    if (navigator.onLine) {
      replayOnOnline();
    }
  } catch (error) {
    reviewSubmissionOwned = false;
    setReviewControlsDisabled(false);

    if (error && error.name === 'QuotaExceededError') {
      const container = document.getElementById('flashcard-container');
      const errorMsg = document.createElement('div');
      errorMsg.style.color = 'var(--cw-text-default)';
      errorMsg.style.fontWeight = 'bold';
      errorMsg.style.marginTop = '1rem';
      errorMsg.textContent = 'Device storage limit reached! Cannot save more progress. Please free up space on your device.';
      container.prepend(errorMsg);
      renderStudyStatus('sync_paused');
    } else {
      renderStudyStatus('sync_paused');
    }
  }
}
