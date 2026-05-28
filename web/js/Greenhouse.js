import { database } from "./main.js";
import { ref, onValue, remove, update }
  from "https://www.gstatic.com/firebasejs/9.22.1/firebase-database.js";

const tbody      = document.getElementById("tbody1");
const editModal  = document.getElementById("editModal");
const modalStatus = document.getElementById("modalStatus");
const saveBtn    = document.getElementById("modalSaveBtn");
const cancelBtn  = document.getElementById("modalCancelBtn");

// Fields inside the modal
const fName      = document.getElementById("edit-name");
const fEmail     = document.getElementById("edit-email");
const fGhName    = document.getElementById("edit-ghname");
const fGhLoc     = document.getElementById("edit-ghlocation");

// Track which user/greenhouse is being edited
let activeUserId = null;
let activeGhId   = null;

// ─── Open / Close modal ───────────────────────────────────────────────────────

function openModal(userId, ghId, userData, ghData) {
  activeUserId = userId;
  activeGhId   = ghId;

  fName.value    = userData.name     || "";
  fEmail.value   = userData.email    || "";
  fGhName.value  = ghData.name       || "";
  fGhLoc.value   = ghData.location   || "";

  modalStatus.textContent = "";
  modalStatus.style.color = "";
  saveBtn.disabled = false;

  editModal.classList.add("open");
  fName.focus();
}

function closeModal() {
  editModal.classList.remove("open");
  activeUserId = null;
  activeGhId   = null;
}

// Close on overlay click (not on card click)
editModal.addEventListener("click", (e) => {
  if (e.target === editModal) closeModal();
});

cancelBtn.addEventListener("click", closeModal);

// Close on Escape key
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && editModal.classList.contains("open")) closeModal();
});

// ─── Save changes ─────────────────────────────────────────────────────────────

saveBtn.addEventListener("click", async () => {
  if (!activeUserId || !activeGhId) return;

  const newName   = fName.value.trim();
  const newEmail  = fEmail.value.trim();
  const newGhName = fGhName.value.trim();
  const newGhLoc  = fGhLoc.value.trim();

  // Basic validation
  if (!newName || newName.length < 2) {
    modalStatus.textContent = "Name must be at least 2 characters.";
    modalStatus.style.color = "#ef4444";
    return;
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newEmail)) {
    modalStatus.textContent = "Enter a valid email address.";
    modalStatus.style.color = "#ef4444";
    return;
  }

  saveBtn.disabled = true;
  modalStatus.textContent = "⏳ Saving…";
  modalStatus.style.color = "#1b6b57";

  try {
    // Update user fields (name, email) and greenhouse fields in one atomic call
    const updates = {};
    updates[`users/${activeUserId}/name`]                              = newName;
    updates[`users/${activeUserId}/email`]                             = newEmail;
    updates[`users/${activeUserId}/greenhouses/${activeGhId}/name`]     = newGhName || null;
    updates[`users/${activeUserId}/greenhouses/${activeGhId}/location`] = newGhLoc  || null;

    await update(ref(database), updates);

    modalStatus.textContent = "✅ Saved successfully!";
    modalStatus.style.color = "#16a34a";

    setTimeout(closeModal, 900);

  } catch (err) {
    modalStatus.textContent = "Error: " + err.message;
    modalStatus.style.color = "#ef4444";
    saveBtn.disabled = false;
  }
});

// ─── Render table ─────────────────────────────────────────────────────────────

onValue(ref(database, "users"), (snapshot) => {
  tbody.innerHTML = "";

  if (!snapshot.exists()) {
    tbody.innerHTML = `
      <tr>
        <td colspan="5" style="text-align:center;padding:2rem;color:#6b7280">
          No greenhouses found.
        </td>
      </tr>`;
    return;
  }

  snapshot.forEach(userSnap => {
    const user   = userSnap.val();
    const userId = userSnap.key;

    if (!user.greenhouses) return;

    Object.entries(user.greenhouses).forEach(([ghId, gh]) => {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${user.name    || "—"}</td>
        <td>${user.email   || "—"}</td>
        <td>${gh.name      || "—"}</td>
        <td>${gh.location  || "—"}</td>
        <td>
          <button class="btn-update" type="button" data-uid="${userId}" data-ghid="${ghId}">Update</button>
          <button class="btn-danger" type="button" data-uid="${userId}" data-ghid="${ghId}">Delete</button>
        </td>
      `;
      tbody.appendChild(row);
    });
  });

 
  tbody.querySelectorAll(".btn-update").forEach(btn => {
    btn.addEventListener("click", () => {
      const uid  = btn.dataset.uid;
      const ghid = btn.dataset.ghid;

      // Grab current data from the snapshot to pre-fill the modal
      const userSnap = snapshot.child(uid);
      const ghSnap   = userSnap.child(`greenhouses/${ghid}`);

      openModal(uid, ghid, userSnap.val() || {}, ghSnap.val() || {});
    });
  });

  
  tbody.querySelectorAll(".btn-danger").forEach(btn => {
    btn.addEventListener("click", () => {
      if (!confirm("Delete this greenhouse?")) return;
      const path = ref(database, `users/${btn.dataset.uid}/greenhouses/${btn.dataset.ghid}`);
      remove(path).catch(err => alert("Error: " + err.message));
    });
  });
});