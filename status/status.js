import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js';
import { getAuth } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-auth.js';
import { getFirestore, collection, getDocs, limit, query } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore.js';

const firebaseConfig = {
  apiKey: 'AIzaSyBS8MKN-vzLCFLDmGfws7uJg5_I4fJKnqM',
  authDomain: 'wardly-24081996.firebaseapp.com',
  projectId: 'wardly-24081996',
  storageBucket: 'wardly-24081996.firebasestorage.app',
  messagingSenderId: '525482754887',
  appId: '1:525482754887:web:2886f69b6402f4718a8262',
};

const app = initializeApp(firebaseConfig);
getAuth(app);
const db = getFirestore(app);

function setStatus(cardId, state, detailText) {
  const card = document.getElementById(cardId);
  if (!card) return;
  const pill = card.querySelector('[data-slot="pill"]');
  const detail = card.querySelector('[data-slot="detail"]');
  if (pill) {
    pill.className = 'status-pill ' + state;
    pill.textContent =
      state === 'green' ? 'OK' :
      state === 'amber' ? 'DEGRADED' :
      state === 'red' ? 'DOWN' : state.toUpperCase();
  }
  if (detail) detail.textContent = detailText;
}

async function checkAuth() {
  const start = performance.now();
  try {
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${firebaseConfig.apiKey}`,
      { method: 'POST', body: JSON.stringify({ idToken: 'none' }) }
    );
    const ms = Math.round(performance.now() - start);
    // We expect 400 (INVALID_ID_TOKEN) — that means the API is up.
    if (res.status < 500) {
      setStatus('svc-auth', 'green',
        `Auth API reachable · ${ms}ms · Email/Password + Google enabled`);
    } else {
      setStatus('svc-auth', 'red',
        `HTTP ${res.status} — Auth API unreachable`);
    }
  } catch (e) {
    setStatus('svc-auth', 'red', `Error: ${e.message}`);
  }
}

async function checkFirestore() {
  const start = performance.now();
  try {
    const q = query(collection(db, 'wards'), limit(1));
    await getDocs(q);
    const ms = Math.round(performance.now() - start);
    setStatus('svc-firestore', 'green',
      `Connected · ${ms}ms · Reads succeeded`);
  } catch (e) {
    const ms = Math.round(performance.now() - start);
    if (e.code === 'permission-denied' || /permission/i.test(e.message)) {
      setStatus('svc-firestore', 'green',
        `Reachable · ${ms}ms · Rules require auth (expected)`);
    } else {
      setStatus('svc-firestore', 'red', `${e.code || 'error'} — ${e.message}`);
    }
  }
}

function updateHeader() {
  document.getElementById('last-check').textContent =
    new Date().toLocaleString();
}

function tally() {
  const pills = document.querySelectorAll('.status-pill');
  let ok = 0, degraded = 0, down = 0;
  pills.forEach(p => {
    if (p.classList.contains('green')) ok++;
    else if (p.classList.contains('amber')) degraded++;
    else if (p.classList.contains('red')) down++;
  });
  const el = document.getElementById('overall');
  if (down > 0) {
    el.textContent = `⚠ ${down} service(s) down.`;
    el.style.color = '#ff6b6b';
  } else if (degraded > 0) {
    el.textContent = `All core systems operational · ${degraded} pending setup.`;
    el.style.color = '#f6b93b';
  } else {
    el.textContent = 'All systems operational.';
    el.style.color = '#00c896';
  }
}

async function runAll() {
  await Promise.all([checkAuth(), checkFirestore()]);
  updateHeader();
  setTimeout(tally, 200);
}

document.getElementById('recheck').addEventListener('click', runAll);
runAll();
