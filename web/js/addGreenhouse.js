import { database } from "./main.js";
import { ref, get, push, query, orderByChild, equalTo }
  from "https://www.gstatic.com/firebasejs/9.22.1/firebase-database.js";

const form    = document.getElementById("userForm");
const message = document.getElementById("message");


function sanitize(str) {
  return str.replace(/[<>&"]/g, "");
}

function parseThreshold(value) {
  const trimmed = value.trim();
  if (trimmed === "") return null;
  const num = Number(trimmed);
  return isNaN(num) ? null : num;
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  // Guard against double-submit
  const submitBtn = form.querySelector("button[type='submit']");
  if (submitBtn.disabled) return;
  submitBtn.disabled = true;

  const userEmail   = document.getElementById("email").value.trim();
  const name        = sanitize(document.getElementById("name").value.trim());
  const location    = sanitize(document.getElementById("location").value.trim());

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(userEmail) || name.length < 2 || location.length < 2) {
    message.textContent = "Please fix all required fields.";
    message.style.color = "#ef4444";
    submitBtn.disabled = false;
    return;
  }

  message.textContent = "⏳ Saving to Firebase...";
  message.style.color = "#1b6b57";

  try {
    const userQuery = query(ref(database, "users"), orderByChild("email"), equalTo(userEmail));
    const snapshot  = await get(userQuery);

    if (!snapshot.exists()) {
      message.textContent = "User not found.";
      message.style.color = "#ef4444";
      return;
    }

    const userId = Object.keys(snapshot.val())[0];

    await push(ref(database, `users/${userId}/greenhouses`), {
      name,
      location,
      createdAt: new Date().toISOString(),
    });

    message.textContent = " Greenhouse added successfully!";
    message.style.color = "#16a34a";
    form.reset();
    setTimeout(() => { message.textContent = ""; }, 3000);

  } catch (error) {
    // Log internally, show a safe message to the user
    console.error("Firebase write error:", error);
    message.textContent = "Something went wrong. Please try again.";
    message.style.color = "#ef4444";
  } finally {
    submitBtn.disabled = false;
  }
});