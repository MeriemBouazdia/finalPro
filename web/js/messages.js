// ══════════════════════════════════════════════════════════════════
//  messages.js — GreenHouse OS Chat
//
//  Data structure:
//    /users/{uid}/          ← user profile (name, email, role …)
//    /users/{uid}/messages/ ← chat thread between admin and this user
//      {pushKey}/
//        text      : string
//        sender    : "admin" | "user"
//        timestamp : serverTimestamp
//        read      : boolean
// ══════════════════════════════════════════════════════════════════

import { database } from "./main.js";

import {
  ref,
  onValue,
  push,
  set,
  serverTimestamp,
  query,
  orderByChild,
} from "https://www.gstatic.com/firebasejs/9.22.1/firebase-database.js";

// ══════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════

const AVATAR_COLORS = [
  { bg: "#d1fae5", text: "#166534" },
  { bg: "#dbeafe", text: "#1d4ed8" },
  { bg: "#fef3c7", text: "#92400e" },
  { bg: "#fce7f3", text: "#9d174d" },
  { bg: "#ede9fe", text: "#5b21b6" },
  { bg: "#ffedd5", text: "#9a3412" },
];

function getAvatarColor(uid) {
  let hash = 0;
  for (const c of String(uid)) hash = (hash * 31 + c.charCodeAt(0)) & 0xffffffff;
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function getInitials(name) {
  return (name || "?")
    .trim()
    .split(/\s+/)
    .map(w => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

function formatTime(ts) {
  if (!ts) return "";
  const d    = new Date(ts);
  const now  = new Date();
  const diff = now - d;
  if (diff < 60_000)     return "Just now";
  if (diff < 3_600_000)  return `${Math.floor(diff / 60_000)}m ago`;
  if (diff < 86_400_000) return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  return d.toLocaleDateString();
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g,  "&amp;")
    .replace(/</g,  "&lt;")
    .replace(/>/g,  "&gt;")
    .replace(/"/g,  "&quot;");
}

// ══════════════════════════════════════
//  STATE
// ══════════════════════════════════════

let currentUid       = null;   // uid of the user currently open in chat
let currentUserName  = null;
let users            = {};     // { uid: { name, email, role, … } }
let msgListeners     = {};     // uid → unsubscribe fn  (prevent duplicate listeners)
let activeMsgUnsub   = null;   // unsubscribe for the currently-open chat listener

// ══════════════════════════════════════
//  USERS LIST  — reads /users/{uid}
// ══════════════════════════════════════

onValue(ref(database, "users"), snap => {
  users = {};
  if (snap.exists()) {
    snap.forEach(child => {
      // Skip entries that have no name/email (pure-data nodes, etc.)
      const val = child.val();
      if (val && (val.name || val.email)) {
        users[child.key] = { uid: child.key, ...val };
      }
    });
  }
  renderUsersList();
});

// ── Render the left-panel list ────────────────────────────────────────────────

function renderUsersList(filter = "") {
  const list  = document.getElementById("farmersList");
  const count = document.getElementById("farmerCount");
  if (!list) return;

  list.innerHTML = "";

  const lc = filter.toLowerCase();
  const filtered = Object.values(users).filter(u => {
    const name  = (u.name  || "").toLowerCase();
    const email = (u.email || "").toLowerCase();
    return !lc || name.includes(lc) || email.includes(lc);
  });

  count.textContent = filtered.length;

  if (!filtered.length) {
    list.innerHTML = `
      <div style="padding:24px;text-align:center;color:var(--text3);font-size:13px;">
        No users found
      </div>`;
    return;
  }

  filtered.forEach(u => {
    const displayName = u.name || u.email || u.uid;
    const col         = getAvatarColor(u.uid);
    const isActive    = currentUid === u.uid;

    const item = document.createElement("div");
    item.className  = "farmer-item" + (isActive ? " active" : "");
    item.dataset.id = u.uid;

    item.innerHTML = `
      <div class="farmer-avatar" style="background:${col.bg};color:${col.text}">
        ${getInitials(displayName)}
      </div>
      <div class="farmer-info">
        <div class="farmer-name">${escapeHtml(displayName)}</div>
        <div class="farmer-last-msg" id="last-${u.uid}">
          ${escapeHtml(u.email || "")}
        </div>
      </div>
      <div class="farmer-meta">
        <span class="farmer-time"  id="time-${u.uid}"></span>
        <span class="unread-badge" id="unread-${u.uid}" style="display:none"></span>
      </div>
    `;

    item.addEventListener("click", () => openChat(u.uid, displayName));
    list.appendChild(item);

    // Subscribe to the last-message preview for this user
    listenLastMsg(u.uid);
  });

  updateTotalUnread();
}

// ── Subscribe to last message for preview + unread count ─────────────────────

function listenLastMsg(uid) {
  if (msgListeners[uid]) return;   // already subscribed

  const msgsRef = ref(database, `users/${uid}/messages`);

  msgListeners[uid] = onValue(msgsRef, snap => {
    if (!snap.exists()) return;

    let last   = null;
    let unread = 0;

    snap.forEach(child => {
      const msg = child.val();
      last = msg;
      // Count messages from the user that the admin hasn't read yet
      if (msg.sender === "user" && !msg.read) unread++;
    });

    const lastEl   = document.getElementById(`last-${uid}`);
    const timeEl   = document.getElementById(`time-${uid}`);
    const unreadEl = document.getElementById(`unread-${uid}`);

    if (last && lastEl) {
      lastEl.textContent = last.text ? escapeHtml(last.text).slice(0, 40) : "📷 Media";
    }
    if (last && timeEl)   timeEl.textContent = formatTime(last.timestamp);
    if (unreadEl) {
      unreadEl.style.display = unread > 0 ? "flex" : "none";
      unreadEl.textContent   = unread > 0 ? String(unread) : "";
    }

    updateTotalUnread();
  });
}

// ── Total unread badge in the sidebar nav ─────────────────────────────────────

function updateTotalUnread() {
  let total = 0;
  document.querySelectorAll("[id^='unread-']").forEach(el => {
    if (el.style.display !== "none") total += parseInt(el.textContent || "0", 10);
  });
  const badge = document.getElementById("totalUnread");
  if (badge) {
    badge.textContent   = total;
    badge.style.display = total > 0 ? "flex" : "none";
  }
}

// ══════════════════════════════════════
//  OPEN CHAT
// ══════════════════════════════════════

function openChat(uid, userName) {
  currentUid      = uid;
  currentUserName = userName;

  // Highlight selected item
  document.querySelectorAll(".farmer-item").forEach(el => {
    el.classList.toggle("active", el.dataset.id === uid);
  });

  const col = getAvatarColor(uid);
  const win = document.getElementById("chatWindow");
  const u   = users[uid] || {};

  win.innerHTML = `
    <div class="chat-header">
      <div class="chat-farmer-avatar" style="background:${col.bg};color:${col.text}">
        ${getInitials(userName)}
      </div>
      <div style="flex:1;min-width:0;">
        <div class="chat-farmer-name">${escapeHtml(userName)}</div>
        <div class="chat-farmer-status">${escapeHtml(u.email || "")}</div>
      </div>
      <div class="chat-header-badge">
        <span class="role-badge">${escapeHtml(u.role || "user")}</span>
      </div>
    </div>

    <div class="messages-area" id="messagesArea"></div>

    <div class="chat-input-area">
      <textarea
        class="chat-input-box"
        id="msgInput"
        placeholder="Type a message to ${escapeHtml(userName)}…"
        rows="1"
      ></textarea>
      <button class="send-btn" id="sendBtn" title="Send message">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="22" y1="2"  x2="11" y2="13"/>
          <polygon points="22 2 15 22 11 13 2 9 22 2"/>
        </svg>
      </button>
    </div>
  `;

  // Auto-resize textarea
  const input = document.getElementById("msgInput");
  input.addEventListener("input", () => {
    input.style.height = "auto";
    input.style.height = Math.min(input.scrollHeight, 120) + "px";
  });

  // Ctrl/Cmd+Enter or just Enter (Shift+Enter = new line)
  input.addEventListener("keydown", e => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });

  document.getElementById("sendBtn").addEventListener("click", sendMessage);

  input.focus();
  loadMessages(uid);
}

// ══════════════════════════════════════
//  LOAD MESSAGES  — /users/{uid}/messages
// ══════════════════════════════════════

function loadMessages(uid) {
  // Detach previous listener
  if (activeMsgUnsub) {
    activeMsgUnsub();
    activeMsgUnsub = null;
  }

  const msgsRef = query(
    ref(database, `users/${uid}/messages`),
    orderByChild("timestamp")
  );

  activeMsgUnsub = onValue(msgsRef, snap => {
    const area = document.getElementById("messagesArea");
    if (!area) return;

    area.innerHTML = "";

    if (!snap.exists()) {
      area.innerHTML = `
        <div style="text-align:center;color:var(--text3);font-size:13px;margin-top:40px;">
          No messages yet. Say hello! 👋
        </div>`;
      return;
    }

    let lastDate = "";

    snap.forEach(child => {
      const msg    = child.val();
      const msgKey = child.key;

      // ── Date divider ──────────────────────────────────────────────────
      const msgDate = msg.timestamp
        ? new Date(msg.timestamp).toLocaleDateString()
        : "";

      if (msgDate && msgDate !== lastDate) {
        lastDate = msgDate;
        const divider = document.createElement("div");
        divider.className   = "date-divider";
        divider.textContent = msgDate === new Date().toLocaleDateString()
          ? "Today"
          : msgDate;
        area.appendChild(divider);
      }

      // ── Message bubble ────────────────────────────────────────────────
      const isAdmin = msg.sender === "admin";
      const col     = getAvatarColor(uid);

      const row = document.createElement("div");
      row.className = `msg-row ${isAdmin ? "admin" : "farmer"}`;
      row.innerHTML = `
        <div class="msg-avatar" style="${
          isAdmin
            ? "background:#166534;color:#fff"
            : `background:${col.bg};color:${col.text}`
        }">
          ${isAdmin ? "AD" : getInitials(currentUserName)}
        </div>
        <div>
          <div class="msg-bubble">${escapeHtml(msg.text || "")}</div>
          <div class="msg-time">
            ${formatTime(msg.timestamp)}${isAdmin ? " ✓✓" : ""}
          </div>
        </div>
      `;
      area.appendChild(row);

      // Mark user→admin messages as read
      if (msg.sender === "user" && !msg.read) {
        set(ref(database, `users/${uid}/messages/${msgKey}/read`), true)
          .catch(() => {});
      }
    });

    // Scroll to bottom
    area.scrollTop = area.scrollHeight;
  });
}

function sendMessage() {
  if (!currentUid) return;

  const input = document.getElementById("msgInput");
  const text  = (input?.value || "").trim();
  if (!text) return;

  push(ref(database, `users/${currentUid}/messages`), {
    text,
    sender:    "admin",
    timestamp: serverTimestamp(),
    read:      true,   // admin wrote it, so it's already "read" on admin side
  }).catch(err => console.error("Send error:", err));

  input.value        = "";
  input.style.height = "auto";
}

document.getElementById("searchInput")
  ?.addEventListener("input", e => renderUsersList(e.target.value));