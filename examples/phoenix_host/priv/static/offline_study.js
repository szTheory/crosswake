import { canSatisfyJournalReserve } from './storage_logic.js';

const DB_NAME = 'crosswake_offline_study';
const DB_VERSION = 1;
const STORE_CARDS = 'flashcards';
const STORE_MUTATIONS = 'mutations';

let db;
let currentCardIndex = 0;
let cards = [];

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
  } catch (error) {
    updateStatus('Error initializing: ' + error.message);
    console.error(error);
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
        db.createObjectStore(STORE_MUTATIONS, { keyPath: 'id', autoIncrement: true });
      }
    };
  });
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

function queueMutation(mutation) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readwrite');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.add(mutation);

    request.onsuccess = () => resolve();
    request.onerror = (event) => {
      reject(event.target.error);
    };
    tx.onabort = () => {
      reject(tx.error);
    };
  });
}

function getAllMutations() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readonly');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.getAll();

    request.onsuccess = () => resolve(request.result);
    request.onerror = (event) => reject(event.target.error);
    tx.onabort = () => reject(tx.error);
  });
}

function deleteAcceptedMutations(records, acceptedIds) {
  const acceptedIdSet = new Set(acceptedIds);
  const toDelete = records.filter(r => acceptedIdSet.has(r.client_mutation_id)).map(r => r.id);
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

function countMutations() {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_MUTATIONS, 'readonly');
    const store = tx.objectStore(STORE_MUTATIONS);
    const request = store.count();

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

let flushing = false;

async function flushOutbox() {
  if (flushing) return;
  flushing = true;
  try {
    const records = await getAllMutations();
    if (records.length === 0) return;

    updateStatusClear();
    updateStatus('Syncing…');

    let response;
    try {
      response = await fetch('/study/sync', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          events: records.map(r => ({
            client_mutation_id: r.client_mutation_id,
            card_id: r.card_id,
            rating: r.rating
          }))
        })
      });
    } catch (_networkError) {
      const q = records.length;
      const statusElement = document.getElementById('status');
      if (statusElement) {
        statusElement.style.borderLeft = '3px solid var(--cw-status-error)';
        statusElement.style.paddingLeft = '0.5rem';
        statusElement.style.color = 'var(--cw-text-default)';
      }
      updateStatus(`Sync failed — ${q} still saved locally. Retrying on reconnect.`);
      return;
    }

    if (response.ok) {
      const data = await response.json();
      const acceptedRecords = (data.data && data.data.accepted_records) || [];
      const rejected = (data.data && data.data.rejected) || [];

      rejected.forEach(r => console.warn('Rejected mutation:', r.client_mutation_id, r.errors));

      const acceptedIds = acceptedRecords.map(r => r.client_mutation_id);
      await deleteAcceptedMutations(records, acceptedIds);

      const remaining = await countMutations();
      const accepted = acceptedIds.length;
      updateStatusClear();
      updateStatus(`Synced ${accepted} · queued ${remaining}`);
    } else {
      const q = records.length;
      const statusElement = document.getElementById('status');
      if (statusElement) {
        statusElement.style.borderLeft = '3px solid var(--cw-status-error)';
        statusElement.style.paddingLeft = '0.5rem';
        statusElement.style.color = 'var(--cw-text-default)';
      }
      updateStatus(`Sync failed — ${q} still saved locally. Retrying on reconnect.`);
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
    const queued = await getAllMutations().catch(() => []);
    updateStatusClear();
    updateStatus(`Offline — ${queued.length} saved locally`);
  });

  flushOutbox();
}

async function handleReview(rating) {
  const card = cards[currentCardIndex];

  const mutation = {
    client_mutation_id: crypto.randomUUID(),
    card_id: parseInt(card.id, 10),
    rating: rating
  };

  try {
    await queueMutation(mutation);
    updateStatusClear();
    updateStatus(`Card ${currentCardIndex + 1} of ${cards.length}`);

    currentCardIndex++;
    renderCurrentCard();

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
      updateStatus('Error saving review: ' + (error ? error.message : 'Unknown error'));
    }
  }
}

function updateStatus(message) {
  const statusElement = document.getElementById('status');
  if (statusElement) {
    statusElement.textContent = message;
  }
}
