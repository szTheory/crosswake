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
  'rejected',
  'scope_mismatch',
  'sigra_denied',
  'transaction_failed',
]);
const STUDY_STATUS_PRESENTATIONS = Object.freeze({
  saved_locally: Object.freeze({ label: 'Saved on this iPhone.', message: 'It will sync when you’re back online.', icon: '●' }),
  syncing: Object.freeze({ label: 'Syncing saved answers…', message: '', icon: '↻' }),
  needs_attention: Object.freeze({ label: 'Some saved answers need review.', message: '', icon: '▲' }),
  sync_paused: Object.freeze({ label: 'Saved answers paused', message: 'Your saved answers remain on this iPhone.', icon: 'Ⅱ' }),
  initialization_failed: Object.freeze({ label: 'Offline study unavailable.', message: 'Reload this page to try again.', icon: '!' }),
});

const AUDIO_COMMAND = 'host.study.audio.play';
const AUDIO_ROUTE_ID = 'offline-study';
const AUDIO_ASSET_KEY = 'pronunciation';
const AUDIO_REPLY_TIMEOUT_MS = 10000;
const BRIDGE_PROTOCOL = 'crosswake.bridge';
const BRIDGE_VERSION = '1.1.0';
const MAX_FREE_FORM_BYTES = 4096;
const REVIEW_STATE_NEEDS_REVIEW = 'needs_review';
const REPLAY_STATE_KEY = 'replay_state';
// "Temporarily unavailable" is temporary: a recorded disablement stops hiding Try again after this long.
const REPLAY_UNAVAILABLE_TTL_MS = 5 * 60 * 1000;
// Closed learner-state vocabulary mirrored into data-island-state for the host observer.
const ISLAND_STATES = Object.freeze([
  'saved_local',
  'waiting',
  'sending',
  'saved_account',
  'needs_review',
  'unavailable',
  'audio_unavailable',
  'fenced',
  'entry_disabled',
]);
const DURABLE_COPY = Object.freeze({
  saved_local: 'Saved on this device',
  waiting: 'Waiting to send',
  sending: 'Sending',
  saved_account: 'Saved to your account',
  needs_review: 'Needs review',
  unavailable: 'Temporarily unavailable. Your answer is still saved on this device.',
  entry_disabled: 'Temporarily unavailable. Your answer is still saved on this device.',
  fenced: 'Paused. Saved answers stay on this device.',
  audio_unavailable: 'Audio unavailable',
});

let db;
let currentIslandState = null;
let reviewableWork = false;
let audioInFlight = null;
let reviewConfirmCounter = 0;
let currentCardIndex = 0;
let cards = [];
let activeScopeRef = null;
let activeEpoch = 0;
let legacyRecoveryRequired = false;
let reviewSubmissionOwned = false;
let currentStudyStatus = null;
let resolveInitialization;
const initialization = new Promise((resolve) => {
  resolveInitialization = resolve;
});

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

  if (!(await initialization)) {
    throw new Error('CW-OFFLINE-INITIALIZATION');
  }

  const lifecycle = await readLifecycle();
  if (lifecycle.state !== 'inactive') {
    throw new Error('CW-OFFLINE-SCOPE-TRANSITION');
  }

  activeEpoch = lifecycle.epoch + 1;
  activeScopeRef = scopeRef;
  await writeLifecycle({ key: 'active', state: 'active', scope_ref: scopeRef, epoch: activeEpoch });
  renderStudyStatus('sync_paused');
  updateProofCompatibilityStatus('Sync is paused');
  // One read serves both counts so activation stays a single outbox read.
  const retained = await getScopeMutations(scopeRef);
  const queuedMutationCount = retained.length;
  reviewableWork = retained.some(r => r.review_state === REVIEW_STATE_NEEDS_REVIEW);
  if (reviewableWork) {
    renderStudyStatus('needs_attention');
    setIslandState('needs_review');
  } else if (queuedMutationCount > 0) {
    setIslandState('waiting');
  } else {
    setIslandState('saved_account', { silent: true });
  }
  if (queuedMutationCount > 0 && navigator.onLine) replayOnOnline();
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
  reviewableWork = false;
  renderStudyStatus('sync_paused');
  setIslandState('fenced');
  updateProofCompatibilityStatus('Sync is paused');
}

function leaseIsCurrent(lease) {
  return activeScopeRef === lease.scopeRef && activeEpoch === lease.epoch;
}

function renderPausedStatus() {
  renderStudyStatus('sync_paused');
  updateProofCompatibilityStatus('Sync is paused');
}

function isRejectedRecord(record) {
  if (!record || typeof record !== 'object') return false;
  if (typeof record.class === 'string') return true;
  return record.outcome === 'rejected' && typeof record.client_mutation_id === 'string';
}

function classifyReplayResponse(data, records) {
  const envelope = data && typeof data === 'object' && !Array.isArray(data) ? data.data : null;
  if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) return { kind: 'blocked' };

  const { accepted_records: acceptedRecords, rejected, halted } = envelope;
  if (!Array.isArray(acceptedRecords) || !Array.isArray(rejected)) return { kind: 'blocked' };
  if (!rejected.every(isRejectedRecord)) {
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
// Read-only observation surface for the host observer: integers only, never entry content.
window.crosswakeIsland = Object.freeze({ outboxCounts });

function configuredSyncEndpoint() {
  const endpoint = document.body.dataset.syncEndpoint;
  return endpoint && endpoint.trim() ? endpoint : '/study/sync';
}

document.addEventListener('DOMContentLoaded', async () => {
  let initialized = false;

  try {
    if (document.body.dataset.page === 'review') {
      await initReviewPage();
      initialized = true;
      return;
    }

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
    setIslandState('fenced', { silent: true });
    updateProofCompatibilityStatus(legacyRecoveryRequired ? 'Saved changes need attention' : 'Sync is paused');
    initialized = true;
  } catch (_error) {
    setStudyControlsDisabled(true);
    disableAnswerControls();
    renderStudyStatus('initialization_failed');
    setIslandState('unavailable', { silent: true });
    updateProofCompatibilityStatus('Offline study unavailable. Reload this page to try again.');
  } finally {
    resolveInitialization(initialized);
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
  const capability = document.body.dataset.recoveryCapability;
  const rawDestination = document.body.dataset.recoveryDestination;
  if (typeof rawDestination !== 'string' || rawDestination.length === 0) return null;

  try {
    const destination = new URL(rawDestination, window.location.origin);
    const plain = destination.origin === window.location.origin &&
      destination.protocol === window.location.protocol &&
      destination.search === '' &&
      destination.hash === '';
    if (!plain) return null;

    // Earlier approved-route path, unchanged.
    if (capability === 'approved_saved_answers' && destination.pathname === '/saved-answers') {
      return destination.href;
    }
    // Host-owned review page: offered only while this scope retains reviewable work.
    if (capability === 'available' && destination.pathname === '/offline/review' && reviewableWork) {
      return destination.href;
    }
    return null;
  } catch (_) {
    return null;
  }
}

function setIslandState(state, options = {}) {
  if (!ISLAND_STATES.includes(state)) return;
  currentIslandState = state;

  const statusElement = document.getElementById('crosswake-study-status');
  if (statusElement) statusElement.dataset.islandState = state;

  // Audio copy lives in its own line; it never replaces the durable save-state copy.
  if (state === 'audio_unavailable') return;

  const line = document.getElementById('study-durable-copy');
  if (!line) return;
  line.textContent = options.silent ? '' : (DURABLE_COPY[state] || '');
  line.hidden = line.textContent.length === 0;
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

function updateProofCompatibilityStatus(message) {
  const compatibilityStatus = document.getElementById('status');
  if (compatibilityStatus) compatibilityStatus.textContent = message;
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

function wireEvent(record) {
  const event = {
    client_mutation_id: record.client_mutation_id,
    card_id: record.card_id,
    rating: record.rating,
  };
  if (typeof record.free_form_answer === 'string') event.free_form_answer = record.free_form_answer;
  return event;
}

async function flushScopedOutbox(invocation) {
  const { lease, controller } = invocation;
  const { scopeRef } = lease;
  try {
    const stored = await getScopeMutations(scopeRef);
    // Work held for review is only sent again when the learner asks (Try again).
    const records = stored.filter(r => r.review_state !== REVIEW_STATE_NEEDS_REVIEW);
    if (!leaseIsCurrent(lease) || records.length === 0) return;

    renderStudyStatus('syncing');
    setIslandState('sending');
    updateProofCompatibilityStatus('Syncing');

    let response;
    try {
      response = await fetch(configuredSyncEndpoint(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scope_ref: scopeRef,
          events: records.map(wireEvent)
        }),
        signal: controller.signal,
      });
    } catch (_networkError) {
      if (!leaseIsCurrent(lease)) return;
      renderStudyStatus('saved_locally');
      setIslandState('waiting');
      updateProofCompatibilityStatus('Saved locally - Queued for replay');
      return;
    }

    if (response.ok) {
      let data;
      try {
        data = await response.json();
      } catch (_parseError) {
        if (!leaseIsCurrent(lease)) return;
        renderPausedStatus();
        setIslandState('unavailable');
        return;
      }
      if (!leaseIsCurrent(lease)) return;
      const result = classifyReplayResponse(data, records);
      if (result.kind === 'blocked') {
        renderPausedStatus();
        setIslandState('unavailable');
        return;
      }

      await deleteAcceptedMutations(scopeRef, records, result.acceptedIds, invocation);
      if (!leaseIsCurrent(lease)) return;

      const held = reviewTargets(result, records);
      if (held.length > 0) {
        await markNeedsReview(scopeRef, held, invocation);
        if (!leaseIsCurrent(lease)) return;
      }

      const remaining = await countScopeMutations(scopeRef);
      const reviewCount = await countNeedsReview(scopeRef);
      if (!leaseIsCurrent(lease)) return;
      reviewableWork = reviewCount > 0;
      const accepted = result.acceptedIds.length;

      if (result.rejected.length > 0) {
        renderStudyStatus('needs_attention');
        if (reviewableWork) {
          setIslandState('needs_review');
        } else {
          setIslandState('unavailable');
          await recordReplayState(scopeRef, 'unavailable');
        }
        updateProofCompatibilityStatus('Saved changes need attention');
      } else if (result.kind === 'halted') {
        renderPausedStatus();
        setIslandState('unavailable');
        await recordReplayState(scopeRef, 'unavailable');
      } else {
        await recordReplayState(scopeRef, 'available');
        if (!leaseIsCurrent(lease)) return;
        if (reviewableWork) {
          renderStudyStatus('needs_attention');
          setIslandState('needs_review');
        } else {
          renderStudyStatus(remaining > 0 ? 'saved_locally' : 'sync_paused');
          setIslandState(remaining > 0 ? 'waiting' : 'saved_account');
        }
        updateProofCompatibilityStatus(`Synced ${accepted} - queued ${remaining}`);
      }
    } else {
      let denialClass = null;
      try {
        denialClass = (await response.json())?.error?.class ?? null;
      } catch (_ignored) {
        denialClass = null;
      }
      if (!leaseIsCurrent(lease)) return;
      renderPausedStatus();
      setIslandState(denialClass === 'feature_disabled' ? 'entry_disabled' : 'unavailable');
      await recordReplayState(scopeRef, 'unavailable');
    }
  } finally {
    if (activeFlush === invocation) activeFlush = null;
  }
}

// Which pending records the server rejected or found in conflict. Authority denials
// and other halts hold nothing back: those records stay queued as before.
function reviewTargets(result, records) {
  const ids = new Set();
  for (const rejected of result.rejected) {
    if (rejected.outcome === 'rejected' && typeof rejected.client_mutation_id === 'string') {
      ids.add(rejected.client_mutation_id);
    } else if (rejected.class === 'scope_conflict') {
      const next = records[result.acceptedIds.length];
      if (next) ids.add(next.client_mutation_id);
    }
  }
  return [...ids];
}

function markNeedsReview(scopeRef, mutationIds, invocation) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    invocation.storageTransaction = tx;
    const store = tx.objectStore(STORE_MUTATIONS);
    mutationIds.forEach((id) => {
      const getRequest = store.get([scopeRef, id]);
      getRequest.onsuccess = () => {
        if (getRequest.result) store.put({ ...getRequest.result, review_state: REVIEW_STATE_NEEDS_REVIEW });
      };
    });
    const release = () => { if (invocation.storageTransaction === tx) invocation.storageTransaction = null; };
    tx.oncomplete = () => { release(); resolve(); };
    tx.onerror = (event) => { release(); reject(event.target.error); };
    tx.onabort = () => { release(); reject(tx.error); };
  });
}

function countNeedsReview(scopeRef) {
  return getScopeMutations(scopeRef).then(rows => rows.filter(r => r.review_state === REVIEW_STATE_NEEDS_REVIEW).length);
}

async function recordReplayState(scopeRef, state) {
  try {
    await writeLifecycleRecord({ key: REPLAY_STATE_KEY, state, scope_ref: scopeRef, at: Date.now() });
  } catch (_ignored) {
    // Best effort: this record only shapes recovery copy; never block replay on it.
  }
}

function writeLifecycleRecord(record) {
  return writeLifecycle(record);
}

function getAllMutations() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readonly');
    const request = tx.objectStore(STORE_MUTATIONS).getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

// Integers only. Never returns entry content, ids, or scope values.
async function outboxCounts() {
  const empty = { selected: 0, free_form: 0, active_scope_total: 0, retained_total: 0 };
  try {
    if (!(await initialization)) return empty;
    const all = await getAllMutations();
    const lease = activeLeaseOrNull();
    const active = lease ? all.filter(r => r.scope_ref === lease.scopeRef) : [];
    return {
      selected: active.filter(r => typeof r.free_form_answer !== 'string').length,
      free_form: active.filter(r => typeof r.free_form_answer === 'string').length,
      active_scope_total: active.length,
      retained_total: all.length,
    };
  } catch (_error) {
    return empty;
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
    const answer = document.getElementById('study-answer');
    if (answer) answer.hidden = true;
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
    if (activeScopeRef) {
      const lease = activeLeaseOrNull();
      renderStudyStatus('saved_locally');
      updateProofCompatibilityStatus('Saved locally - Queued for replay');
      try {
        const queued = lease ? await countScopeMutations(lease.scopeRef) : 0;
        if (lease && leaseIsCurrent(lease) && queued > 0) {
          setIslandState(reviewableWork ? 'needs_review' : 'waiting');
        }
      } catch (_ignored) {
        // The count only shapes the learner line; the queue itself is untouched.
      }
    }
  });

  // Other hosts reuse this script with their own markup; the answer controls are optional.
  document.getElementById('btn-save-answer')?.addEventListener('click', handleFreeFormSave);
  document.getElementById('btn-play-audio')?.addEventListener('click', handleAudioPlay);
  installAudioLandingPad();
  refreshAudioAvailability();

  // Retained work stays inert until the host calls activateScope with fresh authority.
}

function setStudyControlsDisabled(disabled) {
  document.getElementById('btn-flip').disabled = disabled;
  document.getElementById('btn-good').disabled = disabled;
  document.getElementById('btn-hard').disabled = disabled;
}

function disableAnswerControls() {
  const input = document.getElementById('study-free-form');
  const save = document.getElementById('btn-save-answer');
  if (input) input.disabled = true;
  if (save) save.disabled = true;
}

async function handleReview(rating, freeFormAnswer) {
  if (reviewSubmissionOwned) return false;

  const card = cards[currentCardIndex];
  if (!card) return false;

  const isFreeForm = typeof freeFormAnswer === 'string';

  reviewSubmissionOwned = true;
  setStudyControlsDisabled(true);

  const mutation = {
    client_mutation_id: crypto.randomUUID(),
    card_id: parseInt(card.id, 10),
    rating: rating
  };
  if (isFreeForm) mutation.free_form_answer = freeFormAnswer;

  try {
    const lease = requireActiveLease();
    const { scopeRef } = lease;
    await queueMutation(scopeRef, mutation);
    if (!leaseIsCurrent(lease)) return false;
    renderStudyStatus('saved_locally');
    setIslandState('saved_local');
    updateProofCompatibilityStatus('Saved locally - Queued for replay');

    currentCardIndex++;
    renderCurrentCard();
    reviewSubmissionOwned = false;
    setStudyControlsDisabled(false);
    if (navigator.onLine) {
      replayOnOnline();
    }
    return true;
  } catch (error) {
    reviewSubmissionOwned = false;
    setStudyControlsDisabled(false);

    if (error && error.name === 'QuotaExceededError') {
      const container = document.getElementById('flashcard-container');
      const errorMsg = document.createElement('div');
      errorMsg.style.color = 'var(--cw-text-default)';
      errorMsg.style.fontWeight = 'bold';
      errorMsg.style.marginTop = '1rem';
      errorMsg.textContent = 'Device storage limit reached! Cannot save more progress. Please free up space on your device.';
      container.prepend(errorMsg);
      renderStudyStatus('sync_paused');
      updateProofCompatibilityStatus('Free up space on this device, then try saving again.');
    } else {
      renderStudyStatus('sync_paused');
    }
    return false;
  }
}

async function handleFreeFormSave() {
  const input = document.getElementById('study-free-form');
  const message = document.getElementById('study-answer-message');
  if (!input || !message) return;

  const value = input.value;
  if (value.trim().length === 0) {
    message.textContent = 'Type your answer first.';
    return;
  }
  if (new TextEncoder().encode(value).length > MAX_FREE_FORM_BYTES) {
    message.textContent = 'That answer is too long to save.';
    return;
  }

  message.textContent = '';
  // The same outbox write as the rating buttons; the answer is cleared only after the local commit.
  const saved = await handleReview('good', value);
  if (saved) input.value = '';
}

// ---- Audio: one typed host request, only when the shell advertises the command ----

function bridgeTransport() {
  const webkit = window.webkit;
  const handler = webkit && webkit.messageHandlers && webkit.messageHandlers.crosswakeBridge;
  if (handler && typeof handler.postMessage === 'function') return handler;

  const injected = window.crosswakeBridge;
  return injected && typeof injected.postMessage === 'function' ? injected : null;
}

function advertisedCapabilities() {
  const caps = window.crosswakeBridge && window.crosswakeBridge.capabilities;
  return caps && typeof caps === 'object' ? caps : {};
}

function audioAdvertised() {
  return Object.prototype.hasOwnProperty.call(advertisedCapabilities(), AUDIO_COMMAND) && bridgeTransport() !== null;
}

function setAudioLine(text) {
  const line = document.getElementById('study-audio-state');
  if (line) line.textContent = text;
}

function refreshAudioAvailability() {
  const button = document.getElementById('btn-play-audio');
  if (!button) return;
  if (audioAdvertised()) {
    button.setAttribute('aria-disabled', 'false');
    setAudioLine('');
  } else {
    button.setAttribute('aria-disabled', 'true');
    setAudioLine(DURABLE_COPY.audio_unavailable);
  }
}

function installAudioLandingPad() {
  // Augment the injected bridge object; never replace the shell's facts or another owner's pad.
  if (!document.getElementById('btn-play-audio')) return;
  const bridge = window.crosswakeBridge;
  if (bridge && typeof bridge === 'object' && typeof bridge.__reply !== 'function') {
    bridge.__reply = receiveAudioReply;
  }
}

function audioFailed() {
  if (audioInFlight) clearTimeout(audioInFlight.timer);
  audioInFlight = null;
  setAudioLine(DURABLE_COPY.audio_unavailable);
  setIslandState('audio_unavailable');
}

function receiveAudioReply(reply) {
  let parsed = reply;
  if (typeof reply === 'string') {
    try { parsed = JSON.parse(reply); } catch (_ignored) { return false; }
  }
  if (!audioInFlight || !parsed || typeof parsed !== 'object') return false;
  if (parsed.correlation_id !== audioInFlight.correlationId) return false;

  clearTimeout(audioInFlight.timer);
  audioInFlight = null;
  if (parsed.status === 'ok') {
    setAudioLine('Playing pronunciation');
  } else {
    audioFailed();
  }
  return true;
}

function handleAudioPlay() {
  const button = document.getElementById('btn-play-audio');
  if (!button || button.getAttribute('aria-disabled') === 'true') return;
  if (audioInFlight) return;
  if (!audioAdvertised()) {
    refreshAudioAvailability();
    return;
  }

  const correlationId = `cwisland-${crypto.randomUUID()}`;
  const capabilities = {};
  for (const [key, value] of Object.entries(advertisedCapabilities())) {
    if (typeof value === 'string') capabilities[key] = value;
  }
  const request = {
    protocol: BRIDGE_PROTOCOL,
    version: BRIDGE_VERSION,
    command: AUDIO_COMMAND,
    capability: AUDIO_COMMAND,
    route_id: AUDIO_ROUTE_ID,
    active_route_id: AUDIO_ROUTE_ID,
    origin: window.location.origin,
    native_runtime_version: '1.0.0',
    correlation_id: correlationId,
    capabilities,
    installed_packs: {},
    payload: { asset_key: AUDIO_ASSET_KEY, correlation_id: correlationId },
  };

  const timer = setTimeout(() => {
    if (audioInFlight && audioInFlight.correlationId === correlationId) audioFailed();
  }, AUDIO_REPLY_TIMEOUT_MS);
  audioInFlight = { correlationId, timer };
  setAudioLine('Starting pronunciation');

  try {
    bridgeTransport().postMessage(JSON.stringify(request));
  } catch (_transportError) {
    audioFailed();
  }
}


// ---- Recovery: the host-owned review page (D-11) ----
//
// Retained work lives on this device, so the page reads it from the same outbox. It
// lists card label and state only: never answer text, mutation ids, or scope values.
// Discard is the only removal path and always sits behind an explicit confirmation.

async function initReviewPage() {
  await initDB();
  const lifecycle = await readLifecycle();
  if (lifecycle.state === 'active' && isScopeRef(lifecycle.scope_ref) && Number.isSafeInteger(lifecycle.epoch) && lifecycle.epoch >= 1) {
    activeScopeRef = lifecycle.scope_ref;
    activeEpoch = lifecycle.epoch;
  }
  cards = await getAllCards();
  await renderReview();
}

function readReplayState(scopeRef) {
  return new Promise((resolve) => {
    try {
      const tx = db.transaction(STORE_LIFECYCLE, 'readonly');
      const request = tx.objectStore(STORE_LIFECYCLE).get(REPLAY_STATE_KEY);
      request.onsuccess = () => {
        const record = request.result;
        const fresh = record && typeof record.at === 'number' && Date.now() - record.at < REPLAY_UNAVAILABLE_TTL_MS;
        resolve(record && record.scope_ref === scopeRef && record.state === 'unavailable' && fresh ? 'unavailable' : 'available');
      };
      request.onerror = () => resolve('available');
    } catch (_ignored) {
      resolve('available');
    }
  });
}

function cardLabelFor(record) {
  const card = cards.find(candidate => parseInt(candidate.id, 10) === record.card_id);
  return card && typeof card.front === 'string' && card.front.length > 0 ? card.front : 'Saved answer';
}

function deleteOneMutation(scopeRef, localRef) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    tx.objectStore(STORE_MUTATIONS).delete([scopeRef, localRef]);
    tx.oncomplete = () => resolve();
    tx.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

function clearReviewState(scopeRef, localRef) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    const store = tx.objectStore(STORE_MUTATIONS);
    const getRequest = store.get([scopeRef, localRef]);
    getRequest.onsuccess = () => {
      if (!getRequest.result) return;
      const { review_state: _held, ...rest } = getRequest.result;
      store.put(rest);
    };
    tx.oncomplete = () => resolve();
    tx.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

function reviewButton(text, className, ariaLabel) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = className;
  button.textContent = text;
  if (ariaLabel) button.setAttribute('aria-label', ariaLabel);
  return button;
}

function buildReviewItem(record, label, unavailable) {
  const item = document.createElement('li');
  item.className = 'review-item';

  const labelElement = document.createElement('span');
  labelElement.className = 'review-item-label';
  labelElement.textContent = label;

  const stateElement = document.createElement('span');
  stateElement.className = 'review-item-state';
  stateElement.textContent = record.review_state === REVIEW_STATE_NEEDS_REVIEW ? DURABLE_COPY.needs_review : DURABLE_COPY.waiting;

  const actions = document.createElement('div');
  actions.className = 'review-item-actions';

  if (record.review_state === REVIEW_STATE_NEEDS_REVIEW && !unavailable) {
    const retry = reviewButton('Try again', 'btn-primary', `Try again for ${label}`);
    retry.addEventListener('click', () => retryRecord(record));
    actions.append(retry);
  }

  const discard = reviewButton('Discard', 'btn-secondary', `Discard saved answer for ${label}`);
  discard.addEventListener('click', () => showDiscardConfirmation(item, actions, record, discard));
  actions.append(discard);

  item.append(labelElement, stateElement, actions);
  return item;
}

function showDiscardConfirmation(item, actions, record, discardButton) {
  const confirmation = document.createElement('div');
  confirmation.className = 'review-confirm';
  confirmation.setAttribute('role', 'group');
  reviewConfirmCounter += 1;
  const promptId = `review-confirm-${reviewConfirmCounter}`;
  confirmation.setAttribute('aria-labelledby', promptId);

  const prompt = document.createElement('p');
  prompt.id = promptId;
  prompt.textContent = 'Discard this answer? This cannot be undone.';

  const row = document.createElement('div');
  row.className = 'review-item-actions';
  const keep = reviewButton('Keep answer', 'btn-primary');
  const confirmDiscard = reviewButton('Discard answer', 'btn-secondary');
  row.append(keep, confirmDiscard);
  confirmation.append(prompt, row);

  const cancel = () => {
    confirmation.remove();
    actions.hidden = false;
    discardButton.focus();
  };
  keep.addEventListener('click', cancel);
  confirmation.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') cancel();
  });
  confirmDiscard.addEventListener('click', async () => {
    const lease = activeLeaseOrNull();
    if (!lease) return;
    try {
      await deleteOneMutation(lease.scopeRef, record.local_ref);
    } catch (_error) {
      cancel();
      return;
    }
    await renderReview({ message: 'Answer discarded.', focusHeading: true });
  });

  actions.hidden = true;
  item.append(confirmation);
  keep.focus();
}

async function retryRecord(record) {
  const lease = activeLeaseOrNull();
  if (!lease) return;

  try {
    await clearReviewState(lease.scopeRef, record.local_ref);
    reviewableWork = (await countNeedsReview(lease.scopeRef)) > 0;
    await flushOutbox();
  } catch (_error) {
    if (leaseIsCurrent(lease)) renderPausedStatus();
  }
  await renderReview({ focusHeading: true });
}

async function renderReview(options = {}) {
  const list = document.getElementById('review-list');
  const message = document.getElementById('review-message');
  if (!list || !message) return;

  list.replaceChildren();
  message.textContent = options.message || '';

  const lease = activeLeaseOrNull();
  if (!lease) {
    reviewableWork = false;
    renderStudyStatus('sync_paused');
    setIslandState('fenced');
    message.textContent = 'Your saved answers stay on this device. Return to study to continue.';
    return;
  }

  const records = await getScopeMutations(lease.scopeRef);
  const unavailable = (await readReplayState(lease.scopeRef)) === 'unavailable';
  if (!leaseIsCurrent(lease)) return;

  reviewableWork = records.some(record => record.review_state === REVIEW_STATE_NEEDS_REVIEW);
  if (currentStudyStatus !== 'syncing') renderStudyStatus(reviewableWork ? 'needs_attention' : 'sync_paused');

  if (unavailable) {
    setIslandState('unavailable');
  } else if (reviewableWork) {
    setIslandState('needs_review');
  } else if (records.length > 0) {
    setIslandState('waiting');
  } else if (currentIslandState !== 'saved_account') {
    setIslandState('saved_account', { silent: true });
  }

  if (records.length === 0 && !options.message) {
    message.textContent = 'No saved answers are waiting.';
  }

  for (const record of records) {
    list.append(buildReviewItem(record, cardLabelFor(record), unavailable));
  }

  if (options.focusHeading) document.getElementById('review-heading')?.focus();
}
