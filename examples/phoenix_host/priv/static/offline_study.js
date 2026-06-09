// offline_study.js

const DB_NAME = 'crosswake_offline_study';
const DB_VERSION = 1;
const STORE_CARDS = 'flashcards';
const STORE_MUTATIONS = 'mutations';

let db;
let currentCardIndex = 0;
let cards = [];

document.addEventListener('DOMContentLoaded', async () => {
  try {
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
    request.onerror = (event) => reject(event.target.error);
  });
}

function renderCurrentCard() {
  const container = document.getElementById('flashcard-container');
  const btnFlip = document.getElementById('btn-flip');
  const btnPass = document.getElementById('btn-pass');
  const btnFail = document.getElementById('btn-fail');
  
  if (currentCardIndex >= cards.length) {
    container.innerHTML = '<div>You have finished all cards!</div>';
    btnFlip.style.display = 'none';
    btnPass.style.display = 'none';
    btnFail.style.display = 'none';
    return;
  }
  
  const card = cards[currentCardIndex];
  
  container.innerHTML = `
    <div class="card-front">${card.front}</div>
    <div class="card-back" id="card-back">${card.back}</div>
  `;
  
  btnFlip.style.display = 'block';
  btnPass.style.display = 'none';
  btnFail.style.display = 'none';
  updateStatus(`Card ${currentCardIndex + 1} of ${cards.length}`);
}

function setupEventListeners() {
  const btnFlip = document.getElementById('btn-flip');
  const btnPass = document.getElementById('btn-pass');
  const btnFail = document.getElementById('btn-fail');
  
  btnFlip.addEventListener('click', () => {
    document.getElementById('card-back').style.display = 'block';
    btnFlip.style.display = 'none';
    btnPass.style.display = 'block';
    btnFail.style.display = 'block';
  });
  
  btnPass.addEventListener('click', () => handleReview('pass'));
  btnFail.addEventListener('click', () => handleReview('fail'));
}

async function handleReview(result) {
  const card = cards[currentCardIndex];
  
  const mutation = {
    type: 'REVIEW_CARD',
    payload: {
      cardId: card.id,
      result: result,
      timestamp: new Date().toISOString()
    }
  };
  
  try {
    await queueMutation(mutation);
    updateStatus(`Saved ${result} for card ${card.id} to offline queue.`);
    
    currentCardIndex++;
    renderCurrentCard();
  } catch (error) {
    updateStatus('Error saving review: ' + error.message);
  }
}

function updateStatus(message) {
  const statusElement = document.getElementById('status');
  if (statusElement) {
    statusElement.textContent = message;
  }
}
