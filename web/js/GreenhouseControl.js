import { database } from './main.js';
import {
  ref,
  onValue,
  get,
  set,
  off
} from 'https://www.gstatic.com/firebasejs/9.22.1/firebase-database.js';


function readSensorValue(node) {
  if (node === null || node === undefined) return null;
  if (typeof node === 'object' && 'value' in node) return Number(node.value);
  return Number(node);
}

/**
 * Extracts the timestamp string from a sensor node's updatedAt,
 * or falls back to the sensors-level updatedAt, or current time.
 */
function readSensorTime(node, fallbackUpdatedAt) {
  if (node && typeof node === 'object' && node.time != null) {
    return `t=${node.time}s`;
  }
  if (fallbackUpdatedAt) return fallbackUpdatedAt;
  return new Date().toLocaleTimeString();
}


const state = {
  uid:   null,
  ghId:  null,
  mode:  'auto',

  sensors: {
    temperature:  null,
    humidity:     null,
    soil:         null,
    soil_moisture: null,
    light:        null,
  },

  sensorTimes: {
    temperature:  '—',
    humidity:     '—',
    soil:         '—',
    soil_moisture:'—',
    light:        '—',
  },

  updatedAt: null,

  actuators: { pump: false, fan: false, light: false, vent: false },
  targets:   { temperature: 22, soil: 60 },
  connected: false,
};

const _listeners = [];

// Each sensor now stores a Font Awesome icon class string instead of an emoji
const sensorConfig = [
  {
    key: 'temperature',
    label: 'Temperature',
    icon: 'fa-solid fa-temperature-half',
    unit: '°C',
    decimals: 1,
    min: 15, max: 30,
    criticalLow: 10, criticalHigh: 35,
  },
  {
    key: 'humidity',
    label: 'Humidity',
    icon: 'fa-solid fa-droplet',
    unit: '%',
    decimals: 1,
    min: 40, max: 80,
    criticalLow: 20, criticalHigh: 95,
  },
  {
    key: 'soil',
    label: 'Soil (raw)',
    icon: 'fa-solid fa-seedling',
    unit: '',
    decimals: 0,
    min: 100, max: 800,
    criticalLow: 0, criticalHigh: 1023,
  },
  {
    key: 'light',
    label: 'Light',
    icon: 'fa-solid fa-sun',
    unit: 'lux',
    decimals: 0,
    min: 200, max: 1000,
    criticalLow: 0, criticalHigh: 2000,
  },
];

document.addEventListener('DOMContentLoaded', () => {
  const params = new URLSearchParams(window.location.search);
  const uid  = params.get('uid');
  const ghId = params.get('ghId');

  if (uid && ghId) {
    loadAndOpenFromParams(uid, ghId);
  } else {
    fetchAllGreenhouses();
  }

  document.getElementById('back-btn')?.addEventListener('click', showSelector);
  document.getElementById('gh-search')?.addEventListener('input', filterCards);
});

function showSelector() {
  teardownListeners();
  document.getElementById('selector-screen').style.display = 'flex';
  document.getElementById('control-screen').style.display  = 'none';
  history.replaceState(null, '', window.location.pathname);
}

function showControl() {
  document.getElementById('selector-screen').style.display = 'none';
  document.getElementById('control-screen').style.display  = 'block';
}

let _allCards = [];

async function fetchAllGreenhouses() {
  const grid = document.getElementById('picker-grid');

  try {
    const snapshot = await get(ref(database, 'users'));

    if (!snapshot.exists()) {
      grid.innerHTML = `
        <div class="gh-picker-empty">
          <div class="gh-picker-empty-icon">
            <i class="fa-solid fa-leaf"></i>
          </div>
          <div>No greenhouses found.</div>
        </div>`;
      return;
    }

    _allCards = [];

    snapshot.forEach(userSnap => {
      const user   = userSnap.val();
      const userId = userSnap.key;
      if (!user.greenhouses) return;

      Object.entries(user.greenhouses).forEach(([ghId, gh]) => {
        _allCards.push({
          userId,
          ghId,
          ghName:   gh.name     || 'Unnamed',
          location: gh.location || '—',
          userName: user.name   || '—',
          email:    user.email  || '',
        });
      });
    });

    renderCards(_allCards);

  } catch (err) {
    console.error('Error fetching greenhouses:', err);
    grid.innerHTML = `
      <div class="gh-picker-empty">
        <div class="gh-picker-empty-icon gh-picker-empty-icon--warning">
          <i class="fa-solid fa-triangle-exclamation"></i>
        </div>
        <div>Failed to load greenhouses. Check Firebase permissions.</div>
      </div>`;
  }
}

function renderCards(cards) {
  const grid = document.getElementById('picker-grid');
  grid.innerHTML = '';

  if (cards.length === 0) {
    grid.innerHTML = `
      <div class="gh-picker-empty">
        <div class="gh-picker-empty-icon">
          <i class="fa-solid fa-magnifying-glass"></i>
        </div>
        <div>No greenhouses match your search.</div>
      </div>`;
    return;
  }

  cards.forEach(card => {
    const el = document.createElement('div');
    el.className = 'gh-picker-card';
    el.innerHTML = `
      <div class="gh-picker-arrow">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
             stroke-linecap="round" stroke-linejoin="round">
          <polyline points="9 18 15 12 9 6"/>
        </svg>
      </div>
      <div class="gh-picker-icon">
        <i class="fa-solid fa-leaf"></i>
      </div>
      <div class="gh-picker-name">${escapeHtml(card.ghName)}</div>
      <div class="gh-picker-meta">
        <i class="fa-solid fa-location-dot"></i>
        ${escapeHtml(card.location)}
      </div>
      <div class="gh-picker-owner">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round" width="11" height="11">
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
          <circle cx="12" cy="7" r="4"/>
        </svg>
        ${escapeHtml(card.userName)}
      </div>
    `;
    el.addEventListener('click', () => {
      showControlPanel(card.userId, card.ghId, card.ghName, card.userName);
    });
    grid.appendChild(el);
  });
}

function filterCards() {
  const q = document.getElementById('gh-search').value.trim().toLowerCase();
  renderCards(
    q ? _allCards.filter(c =>
      c.ghName.toLowerCase().includes(q)   ||
      c.location.toLowerCase().includes(q) ||
      c.userName.toLowerCase().includes(q) ||
      c.email.toLowerCase().includes(q)
    ) : _allCards
  );
}

async function loadAndOpenFromParams(uid, ghId) {
  try {
    const snap = await get(ref(database, `users/${uid}`));
    const user = snap.val() || {};
    const gh   = user.greenhouses?.[ghId] || {};
    showControlPanel(uid, ghId, gh.name || 'Greenhouse', user.name || '—');
  } catch (err) {
    console.error('Deep-link load error:', err);
    showControlPanel(uid, ghId, 'Greenhouse', '—');
  }
}

function showControlPanel(uid, ghId, ghName, userName) {
  state.uid  = uid;
  state.ghId = ghId;

  sensorConfig.forEach(c => {
    state.sensors[c.key]     = null;
    state.sensorTimes[c.key] = '—';
  });
  state.updatedAt = null;

  history.replaceState(null, '', `?uid=${uid}&ghId=${ghId}`);

  const el = id => document.getElementById(id);
  if (el('gh-title'))         el('gh-title').textContent    = ghName;
  if (el('gh-subtitle'))      el('gh-subtitle').textContent = `Owner: ${userName} — Real-time monitoring & control`;
  if (el('breadcrumb-name'))  el('breadcrumb-name').textContent = ghName;

  resetControlUI();
  showControl();

  teardownListeners();
  setupRealtimeListeners();
  loadTargets();
  setupEventListeners();
  initChart();
  loadHistory();
}

function resetControlUI() {
  renderSensorCards();

  document.querySelectorAll('.gh-toggle-switch').forEach(t => {
    t.classList.remove('active');
    t.disabled = false;
  });
  document.querySelectorAll('.gh-mode-option').forEach(b => {
    b.classList.toggle('active', b.dataset.mode === 'auto');
  });
  state.mode = 'auto';

  const hide = id => { const e = document.getElementById(id); if (e) e.style.display = 'none'; };
  hide('connection-alert');
  hide('auto-mode-alert');

  const clear = id => { const e = document.getElementById(id); if (e) e.value = ''; };
  clear('target-temp');
  clear('target-soil');
}

function teardownListeners() {
  _listeners.forEach(({ dbRef, handler }) => off(dbRef, 'value', handler));
  _listeners.length = 0;

  if (chart) { chart.destroy(); chart = null; }
}

function setupRealtimeListeners() {
  const base = `users/${state.uid}/greenhouses/${state.ghId}`;

  const sensorsRef = ref(database, `${base}/sensors`);
  const sensorsHandler = onValue(sensorsRef, snap => {
    if (!snap.exists()) return;

    const raw = snap.val();

    state.updatedAt = raw.updatedAt || null;

    sensorConfig.forEach(cfg => {
      const node = raw[cfg.key];
      state.sensors[cfg.key]     = readSensorValue(node);
      state.sensorTimes[cfg.key] = readSensorTime(node, raw.updatedAt);
    });

    renderSensorCards();
    updateChart();
  }, err => console.error('Sensor listener error:', err));
  _listeners.push({ dbRef: sensorsRef, handler: sensorsHandler });

  const actuatorsRef = ref(database, `${base}/actuators`);
  const actuatorsHandler = onValue(actuatorsRef, snap => {
    if (!snap.exists()) return;
    const data = snap.val();

    const mode = data.mode || 'auto';
    state.mode = mode;
    syncModeUI(mode);

    const deviceState = data.state    || {};
    const deviceCmds  = data.commands || {};

    ['pump', 'fan', 'light', 'vent'].forEach(device => {
      const rawVal = (device in deviceState) ? deviceState[device] : deviceCmds[device];
      const isOn   = Boolean(rawVal);

      const toggle = document.getElementById(`${device}-toggle`);
      if (toggle) toggle.classList.toggle('active', isOn);
      state.actuators[device] = isOn;
    });

  }, err => console.error('Actuators listener error:', err));
  _listeners.push({ dbRef: actuatorsRef, handler: actuatorsHandler });

  const connRef = ref(database, '.info/connected');
  const connHandler = onValue(connRef, snap => {
    state.connected = Boolean(snap.val());
    updateConnectionBadge();
  });
  _listeners.push({ dbRef: connRef, handler: connHandler });
}

function syncModeUI(mode) {
  document.querySelectorAll('.gh-mode-option').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.mode === mode);
  });
  const isAuto = mode === 'auto';
  document.querySelectorAll('.gh-toggle-switch').forEach(t => { t.disabled = isAuto; });
  const alert = document.getElementById('auto-mode-alert');
  if (alert) alert.style.display = isAuto ? 'flex' : 'none';
}


function setupEventListeners() {
  document.querySelectorAll('.gh-mode-option').forEach(btn => {
    const clone = btn.cloneNode(true);
    btn.parentNode.replaceChild(clone, btn);
    clone.addEventListener('click', () => switchMode(clone.dataset.mode));
  });

  document.querySelectorAll('.gh-toggle-switch').forEach(toggle => {
    const clone = toggle.cloneNode(true);
    toggle.parentNode.replaceChild(clone, toggle);
    clone.addEventListener('click', () => toggleDevice(clone));
  });
}

function switchMode(mode) {
  state.mode = mode;
  syncModeUI(mode);

  set(
    ref(database, `users/${state.uid}/greenhouses/${state.ghId}/actuators/mode`),
    mode
  ).catch(err => console.error('Error setting mode:', err));
}

function toggleDevice(toggle) {
  if (state.mode === 'auto') return;

  const device   = toggle.dataset.device;
  const newState = !toggle.classList.contains('active');
  toggle.classList.toggle('active', newState);
  state.actuators[device] = newState;

  set(
    ref(database, `users/${state.uid}/greenhouses/${state.ghId}/actuators/commands/${device}`),
    newState
  ).catch(err => console.error(`Error toggling ${device}:`, err));
}

function loadTargets() {
  const targetsRef = ref(database, `users/${state.uid}/greenhouses/${state.ghId}/targets`);
  const handler = onValue(targetsRef, snap => {
    if (snap.exists()) {
      const d = snap.val();
      if (d.temperature?.value != null) state.targets.temperature = d.temperature.value;
      if (d.soil?.value        != null) state.targets.soil        = d.soil.value;
    }
    const ti = document.getElementById('target-temp');
    const si = document.getElementById('target-soil');
    if (ti) ti.value = state.targets.temperature;
    if (si) si.value = state.targets.soil;
  }, err => console.error('Targets listener error:', err));
  _listeners.push({ dbRef: targetsRef, handler });
}

window.saveTarget = function(type) {
  const input = document.getElementById(type === 'temperature' ? 'target-temp' : 'target-soil');
  if (!input) return;
  const value = parseFloat(input.value);
  if (isNaN(value)) { showNotification('Please enter a valid number', 'warning'); return; }

  const path = type === 'temperature' ? 'targets/temperature/value' : 'targets/soil/value';
  set(ref(database, `users/${state.uid}/greenhouses/${state.ghId}/${path}`), value)
    .then(() => showNotification(`Target ${type} saved!`, 'success'))
    .catch(() => showNotification('Failed to save target', 'warning'));
};

window.resetTarget = function(type) {
  const input = document.getElementById(type === 'temperature' ? 'target-temp' : 'target-soil');
  if (input) input.value = type === 'temperature' ? 22 : 60;
  window.saveTarget(type);
};

function renderSensorCards() {
  const container = document.getElementById('sensors-container');
  if (!container) return;
  container.innerHTML = '';

  const headerTime = state.updatedAt
    ? new Date(state.updatedAt).toLocaleString()
    : null;

  sensorConfig.forEach(cfg => {
    const rawValue = state.sensors[cfg.key];
    const hasData  = rawValue !== null && !isNaN(rawValue);
    const display  = hasData ? Number(rawValue).toFixed(cfg.decimals) : '—';
    const status   = hasData ? getValueStatus(rawValue, cfg) : 'unknown';
    const dotClass = status === 'success' ? '' : status === 'unknown' ? 'warning' : status;

    const timeLabel = state.sensorTimes[cfg.key] !== '—'
      ? state.sensorTimes[cfg.key]
      : (headerTime || '—');

    const card = document.createElement('div');
    card.className = 'gh-sensor-card';
    card.id = `sensor-${cfg.key}`;
    card.innerHTML = `
      <div class="gh-sensor-header">
        <span class="gh-sensor-label">${cfg.label}</span>
        <span class="gh-sensor-icon">
          <i class="${cfg.icon}"></i>
        </span>
      </div>
      <div class="gh-sensor-value">
        ${display}<span class="gh-sensor-unit">${cfg.unit}</span>
      </div>
      <div class="gh-sensor-status">
        <span class="gh-sensor-status-dot ${dotClass}"></span>
        <span>${status === 'success' ? 'Normal'
               : status === 'warning' ? 'Warning'
               : status === 'danger'  ? 'Critical'
               : 'No data'}</span>
      </div>
      <div class="gh-sensor-timestamp">Updated: ${timeLabel}</div>
    `;
    container.appendChild(card);
  });
}

function getValueStatus(value, cfg) {
  if (value <= cfg.criticalLow || value >= cfg.criticalHigh) return 'danger';
  if (value < cfg.min          || value > cfg.max)           return 'warning';
  return 'success';
}

let chart = null;

let _lastHistoryKey = null;
let _historyLoaded  = false;

function buildChartConfig() {
  return {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Temperature (°C)',
          data: [],
          borderColor: '#16a34a',
          backgroundColor: 'rgba(22,163,74,0.05)',
          borderWidth: 2, fill: true, tension: 0.3,
          pointRadius: 3, pointBackgroundColor: '#16a34a',
          pointBorderColor: 'white', pointBorderWidth: 1.5,
        },
        {
          label: 'Humidity (%)',
          data: [],
          borderColor: '#3b82f6',
          backgroundColor: 'rgba(59,130,246,0.05)',
          borderWidth: 2, fill: true, tension: 0.3,
          pointRadius: 3, pointBackgroundColor: '#3b82f6',
          pointBorderColor: 'white', pointBorderWidth: 1.5,
        },
        {
          label: 'Soil Moisture (%)',
          data: [],
          borderColor: '#f59e0b',
          backgroundColor: 'rgba(245,158,11,0.05)',
          borderWidth: 2, fill: true, tension: 0.3,
          pointRadius: 3, pointBackgroundColor: '#f59e0b',
          pointBorderColor: 'white', pointBorderWidth: 1.5,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 300 },
      plugins: {
        legend: {
          display: true, position: 'top',
          labels: {
            usePointStyle: true, padding: 15,
            font: { size: 12, weight: '500' },
            color: 'var(--text3,#9ca3af)',
          },
        },
        tooltip: {
          callbacks: {
            label: ctx => {
              const v = ctx.parsed.y;
              return `${ctx.dataset.label}: ${v !== null && v !== undefined ? v : '—'}`;
            },
          },
        },
      },
      scales: {
        y: {
          beginAtZero: false,
          grid: { color: 'var(--border,#e5e7eb)', drawBorder: false },
          ticks: { color: 'var(--text3,#9ca3af)', font: { size: 11 } },
        },
        x: {
          grid: { display: false, drawBorder: false },
          ticks: {
            color: 'var(--text3,#9ca3af)',
            font: { size: 10 },
            maxRotation: 45,
            autoSkip: true,
            maxTicksLimit: 12,
          },
        },
      },
    },
  };
}

function initChart() {
  if (chart) { chart.destroy(); chart = null; }
  _lastHistoryKey = null;
  _historyLoaded  = false;

  const canvas = document.getElementById('history-chart');
  if (!canvas) return;

  chart = new Chart(canvas.getContext('2d'), buildChartConfig());
}

function pushChartPoint(label, temp, hum, soilMoisture) {
  if (!chart) return;

  chart.data.labels.push(label);
  chart.data.datasets[0].data.push(temp         ?? null);
  chart.data.datasets[1].data.push(hum          ?? null);
  chart.data.datasets[2].data.push(soilMoisture ?? null);

  if (chart.data.labels.length > 48) {
    chart.data.labels.shift();
    chart.data.datasets.forEach(d => d.data.shift());
  }

  chart.update('none');
}

function updateChart() {
  if (!_historyLoaded) return;

  const label = state.updatedAt
    ? new Date(state.updatedAt).toLocaleTimeString()
    : new Date().toLocaleTimeString();

  pushChartPoint(
    label,
    state.sensors.temperature,
    state.sensors.humidity,
    state.sensors.soil_moisture,
  );
}


async function loadHistory() {
  if (!state.uid || !state.ghId || !chart) return;

  // Show a Font Awesome spinner instead of an emoji while loading
  const titleEl = document.querySelector('.gh-chart-title');
  const origTitle = titleEl?.textContent || '';
  if (titleEl) {
    titleEl.innerHTML = `${escapeHtml(origTitle)}&nbsp;&nbsp;<i class="fa-solid fa-spinner fa-spin" aria-label="Loading history"></i>`;
  }

  try {
    const histSnap = await get(
      ref(database, `users/${state.uid}/greenhouses/${state.ghId}/history`)
    );

    if (!histSnap.exists()) {
      if (titleEl) titleEl.textContent = origTitle;
      return;
    }

    const raw = histSnap.val();

    const entries = Object.entries(raw).sort(([a], [b]) => {
      return a < b ? -1 : a > b ? 1 : 0;
    });

    const recent = entries.slice(-48);

    chart.data.labels = [];
    chart.data.datasets.forEach(d => { d.data = []; });

    recent.forEach(([fbKey, entry]) => {
      let label = '—';
      if (entry.timestamp) {
        const d = new Date(
          typeof entry.timestamp === 'number'
            ? entry.timestamp
            : entry.timestamp
        );
        label = isNaN(d) ? String(entry.timestamp) : d.toLocaleTimeString();
      } else if (entry.sensors?.updatedAt) {
        const d = new Date(entry.sensors.updatedAt);
        label = isNaN(d) ? entry.sensors.updatedAt : d.toLocaleTimeString();
      } else {
        label = pushKeyToTime(fbKey);
      }

      const s    = entry.sensors || {};
      const temp = readSensorValue(s.temperature);
      const hum  = readSensorValue(s.humidity);
      const soil = readSensorValue(s.soil_moisture) ?? readSensorValue(s.soil);

      chart.data.labels.push(label);
      chart.data.datasets[0].data.push(temp ?? null);
      chart.data.datasets[1].data.push(hum  ?? null);
      chart.data.datasets[2].data.push(soil ?? null);

      _lastHistoryKey = fbKey;
    });

    chart.update();

  } catch (err) {
    console.error('History load error:', err);
  } finally {
    if (titleEl) titleEl.textContent = origTitle;
    _historyLoaded = true;
  }
}

function pushKeyToTime(key) {
  try {
    const PUSH_CHARS = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    let ts = 0;
    for (let i = 0; i < 8; i++) {
      ts = ts * 64 + PUSH_CHARS.indexOf(key[i]);
    }
    const d = new Date(ts);
    return isNaN(d) ? key.slice(0, 8) : d.toLocaleTimeString();
  } catch {
    return key.slice(0, 8);
  }
}

function updateConnectionBadge() {
  const badge = document.getElementById('connection-alert');
  if (!badge) return;
  if (state.connected) {
    badge.style.display = 'none';
  } else {
    badge.classList.add('alert-warning');
    badge.classList.remove('alert-info');
    const txt = document.getElementById('connection-text');
    if (txt) txt.textContent = 'Disconnected from Firebase';
    badge.style.display = 'flex';
  }
}


function showNotification(message, type = 'success') {
  const n = document.createElement('div');
  n.className = 'gh-notification';
  n.textContent = message;
  if (type === 'warning') n.style.backgroundColor = '#ef4444';
  if (type === 'info')    n.style.backgroundColor = '#3b82f6';
  document.body.appendChild(n);
  setTimeout(() => n.remove(), 3000);
}


function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, c =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])
  );
}

export { state, switchMode, toggleDevice };