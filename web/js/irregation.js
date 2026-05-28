/**
 * EXAMPLE INTEGRATION CODE FOR GREENHOUSE.JS
 * 
 * This shows how to add a "Control" button to your greenhouse table
 * that opens the Greenhouse Control Panel
 * 
 * Location: js/Greenhouse.js
 * Add this code to your existing table row rendering function
 */

// ============================================================================
// EXAMPLE 1: Simple Control Button in Actions Column
// ============================================================================

function addControlButtonToTable(userId, userName, userEmail, greenhouseId, greenhouseName, location) {
  // ... your existing code that builds the table row ...

  // Create actions cell
  const actionsCell = document.createElement('td');

  // Create Control button
  const controlBtn = document.createElement('button');
  controlBtn.className = 'btn-update'; // Uses your existing btn-update class
  controlBtn.innerHTML = '🎛️ Control';
  controlBtn.title = 'Open greenhouse control panel';
  controlBtn.type = 'button';

  // Handle click - navigate to control panel
  controlBtn.onclick = (e) => {
    e.preventDefault();
    e.stopPropagation();

    // Build URL with parameters
    const params = new URLSearchParams({
      uid: userId,
      ghId: greenhouseId
    });

    window.location.href = `Greenhouse-Control.html?${params.toString()}`;
  };

  // Add button to actions cell
  actionsCell.appendChild(controlBtn);

  // ... add your other action buttons (edit, delete, etc) ...
  // actionsCell.appendChild(editBtn);
  // actionsCell.appendChild(deleteBtn);

  // Return the cell or add to your row
  return actionsCell;
}

// ============================================================================
// EXAMPLE 2: Full Integration with Modal Option
// ============================================================================

function renderGreenhouseRow(userData) {
  const row = document.createElement('tr');

  // Create cells (user name, email, greenhouse, location)
  const userCell = document.createElement('td');
  userCell.textContent = userData.userName;

  const emailCell = document.createElement('td');
  emailCell.textContent = userData.email;

  const ghCell = document.createElement('td');
  ghCell.textContent = userData.greenhouseName;

  const locationCell = document.createElement('td');
  locationCell.textContent = userData.location;

  // ACTION BUTTONS CELL
  const actionsCell = document.createElement('td');
  actionsCell.style.display = 'flex';
  actionsCell.style.gap = '0.375rem';

  // ── CONTROL BUTTON ──
  const controlBtn = document.createElement('button');
  controlBtn.className = 'btn-update';
  controlBtn.textContent = '🎛️';
  controlBtn.title = 'Control Greenhouse';
  controlBtn.type = 'button';
  controlBtn.style.flex = '1';

  controlBtn.onclick = () => {
    openControlPanel(userData.userId, userData.greenhouseId);
  };

  // ── EDIT BUTTON ──
  const editBtn = document.createElement('button');
  editBtn.className = 'btn-update';
  editBtn.textContent = '✏️';
  editBtn.title = 'Edit Greenhouse';
  editBtn.type = 'button';
  editBtn.style.flex = '1';

  editBtn.onclick = () => {
    openEditModal(userData.userId, userData.greenhouseId);
  };

  // ── DELETE BUTTON ──
  const deleteBtn = document.createElement('button');
  deleteBtn.className = 'btn-update';
  deleteBtn.style.color = '#ef4444';
  deleteBtn.style.borderColor = '#ef4444';
  deleteBtn.textContent = '🗑️';
  deleteBtn.title = 'Delete Greenhouse';
  deleteBtn.type = 'button';
  deleteBtn.style.flex = '1';

  deleteBtn.onclick = () => {
    if (confirm(`Delete ${userData.greenhouseName}? This cannot be undone.`)) {
      deleteGreenhouse(userData.userId, userData.greenhouseId);
    }
  };

  // Append buttons to actions cell
  actionsCell.appendChild(controlBtn);
  actionsCell.appendChild(editBtn);
  actionsCell.appendChild(deleteBtn);

  // Build complete row
  row.appendChild(userCell);
  row.appendChild(emailCell);
  row.appendChild(ghCell);
  row.appendChild(locationCell);
  row.appendChild(actionsCell);

  return row;
}

// ============================================================================
// SUPPORTING FUNCTIONS
// ============================================================================

/**
 * Open the Greenhouse Control Panel in new window or same window
 * @param {string} userId - Firebase user ID
 * @param {string} greenhouseId - Greenhouse ID
 */
function openControlPanel(userId, greenhouseId) {
  const params = new URLSearchParams({
    uid: userId,
    ghId: greenhouseId
  });

  // Option 1: Navigate in same window
  window.location.href = `Greenhouse-Control.html?${params.toString()}`;

  // Option 2: Open in new tab (uncomment to use)
  // window.open(`Greenhouse-Control.html?${params.toString()}`, '_blank');

  // Option 3: Log for debugging
  console.log('🎛️ Opening control panel:', { userId, greenhouseId });
}

/**
 * Open edit modal (your existing function)
 */
function openEditModal(userId, greenhouseId) {
  // Your existing modal code here
  const modal = document.getElementById('editModal');
  if (modal) {
    modal.classList.add('open');
  }
}

/**
 * Delete greenhouse (your existing function)
 */
async function deleteGreenhouse(userId, greenhouseId) {
  // Your existing delete code here
  console.log('🗑️ Deleting greenhouse:', { userId, greenhouseId });
}

// ============================================================================
// EXAMPLE 3: In Your Existing Greenhouse Table Rendering
// ============================================================================

/*
If your existing code looks like this:

async function loadGreenhouses() {
  const tbody = document.getElementById('tbody1');
  tbody.innerHTML = '';

  const users = await db.ref('users').once('value');
  users.forEach(userSnap => {
    const userId = userSnap.key;
    const user = userSnap.val();

    if (user.greenhouses) {
      Object.keys(user.greenhouses).forEach(ghId => {
        const gh = user.greenhouses[ghId];
        const row = document.createElement('tr');

        // OLD CODE (without control button):
        row.innerHTML = `
          <td>${user.name}</td>
          <td>${user.email}</td>
          <td>${gh.name}</td>
          <td>${gh.location}</td>
          <td>
            <button onclick="editGH('${userId}', '${ghId}')">Edit</button>
          </td>
        `;

        tbody.appendChild(row);
      });
    }
  });
}

UPDATED CODE (with control button):

async function loadGreenhouses() {
  const tbody = document.getElementById('tbody1');
  tbody.innerHTML = '';

  const users = await db.ref('users').once('value');
  users.forEach(userSnap => {
    const userId = userSnap.key;
    const user = userSnap.val();

    if (user.greenhouses) {
      Object.keys(user.greenhouses).forEach(ghId => {
        const gh = user.greenhouses[ghId];
        const row = document.createElement('tr');

        // NEW CODE (with control button):
        row.innerHTML = `
          <td>${user.name}</td>
          <td>${user.email}</td>
          <td>${gh.name}</td>
          <td>${gh.location}</td>
          <td>
            <button class="btn-update" onclick="openControlPanel('${userId}', '${ghId}')">
              🎛️ Control
            </button>
            <button class="btn-update" onclick="editGH('${userId}', '${ghId}')">
              ✏️ Edit
            </button>
          </td>
        `;

        tbody.appendChild(row);
      });
    }
  });
}
*/

// ============================================================================
// EXAMPLE 4: With Loading Indicator
// ============================================================================

function openControlPanelWithLoader(userId, greenhouseId) {
  // Show loading indicator
  const loader = document.createElement('div');
  loader.textContent = '⏳ Opening...';
  loader.style.position = 'fixed';
  loader.style.bottom = '2rem';
  loader.style.right = '2rem';
  loader.style.padding = '1rem 1.5rem';
  loader.style.background = '#16a34a';
  loader.style.color = 'white';
  loader.style.borderRadius = '8px';
  loader.style.zIndex = '9999';
  document.body.appendChild(loader);

  // Navigate after short delay
  setTimeout(() => {
    const params = new URLSearchParams({ uid: userId, ghId: greenhouseId });
    window.location.href = `Greenhouse-Control.html?${params.toString()}`;
  }, 300);

  // Remove loader if user navigates elsewhere
  setTimeout(() => {
    if (document.body.contains(loader)) {
      loader.remove();
    }
  }, 2000);
}

// ============================================================================
// EXAMPLE 5: With Keyboard Shortcut Support
// ============================================================================

function addKeyboardNavigation(userId, greenhouseId) {
  // Press 'C' while focused on greenhouse row to open control panel
  document.addEventListener('keydown', (e) => {
    if (e.key === 'c' || e.key === 'C') {
      // Check if user is not in an input field
      if (document.activeElement.tagName !== 'INPUT' &&
          document.activeElement.tagName !== 'TEXTAREA') {
        openControlPanel(userId, greenhouseId);
      }
    }
  });
}

// ============================================================================
// EXAMPLE 6: With Hover Tooltip
// ============================================================================

function addControlButtonWithTooltip(userId, greenhouseId) {
  const controlBtn = document.createElement('button');
  controlBtn.className = 'btn-update';
  controlBtn.textContent = '🎛️';
  controlBtn.type = 'button';

  // Add tooltip on hover
  controlBtn.addEventListener('mouseenter', () => {
    const tooltip = document.createElement('div');
    tooltip.textContent = 'Open Control Panel';
    tooltip.style.position = 'absolute';
    tooltip.style.bottom = '100%';
    tooltip.style.left = '50%';
    tooltip.style.transform = 'translateX(-50%)';
    tooltip.style.marginBottom = '0.5rem';
    tooltip.style.padding = '0.5rem 0.75rem';
    tooltip.style.background = '#111';
    tooltip.style.color = '#fff';
    tooltip.style.borderRadius = '4px';
    tooltip.style.fontSize = '12px';
    tooltip.style.whiteSpace = 'nowrap';
    tooltip.style.zIndex = '1000';
    tooltip.style.pointerEvents = 'none';

    controlBtn.parentElement.style.position = 'relative';
    controlBtn.parentElement.appendChild(tooltip);

    controlBtn.addEventListener('mouseleave', () => tooltip.remove(), { once: true });
  });

  controlBtn.onclick = () => {
    openControlPanel(userId, greenhouseId);
  };

  return controlBtn;
}

// ============================================================================
// IMPLEMENTATION IN YOUR TABLE
// ============================================================================

/*
When rendering your table, use it like this:

const actionsCell = document.createElement('td');
actionsCell.appendChild(addControlButtonWithTooltip(userId, greenhouseId));
actionsCell.appendChild(editButton);
actionsCell.appendChild(deleteButton);
row.appendChild(actionsCell);
*/

// ============================================================================
// TESTING IN CONSOLE
// ============================================================================

/*
To test in browser console:

// Test opening control panel
openControlPanel('user123', 'greenhouse1');

// Test with parameters
const params = new URLSearchParams({
  uid: 'user123',
  ghId: 'greenhouse1'
});
console.log('URL:', `Greenhouse-Control.html?${params.toString()}`);
*/

export {
  openControlPanel,
  openControlPanelWithLoader,
  renderGreenhouseRow,
  addControlButtonToTable
};