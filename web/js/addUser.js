import { database, auth } from "./main.js";

import {
  ref,
  set,
  get,
  query,
  orderByChild,
  equalTo
} from "https://www.gstatic.com/firebasejs/9.22.1/firebase-database.js";

import {
  createUserWithEmailAndPassword
} from "https://www.gstatic.com/firebasejs/9.22.1/firebase-auth.js";


// ─────────────────────────────────────────────
// EmailJS
// ─────────────────────────────────────────────
const emailjs = window.emailjs;

const EMAILJS_SERVICE_ID  = "service_pbp1mcs";
const EMAILJS_TEMPLATE_ID = "template_px9nnfs";
const EMAILJS_PUBLIC_KEY  = "wtYVdTSBfTL3UkriP";

// ─────────────────────────────────────────────
// Elements
// ─────────────────────────────────────────────
const message           = document.getElementById("message");
const tempPasswordBox   = document.getElementById("tempPasswordBox");
const tempPasswordValue = document.getElementById("tempPasswordValue");

// ─────────────────────────────────────────────
// Generate Temporary Password / OTP
// ─────────────────────────────────────────────
function generateTemporaryPassword() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";

  const bytes = new Uint8Array(10);

  crypto.getRandomValues(bytes);

  return Array.from(bytes)
    .map(b => chars[b % chars.length])
    .join("");
}

// ─────────────────────────────────────────────
// Validation
// ─────────────────────────────────────────────
function validate(fieldId, inputId, condition) {

  const field = document.getElementById(fieldId);
  const input = document.getElementById(inputId);

  const ok = condition(input.value);

  input.classList.toggle("valid", ok);
  input.classList.toggle("invalid", !ok);

  field.classList.toggle("show-error", !ok);

  return ok;
}

// Name Validation
document.getElementById("name").addEventListener("blur", () => {

  validate(
    "field-name",
    "name",
    v => v.trim().length > 1
  );

});

// Email Validation
document.getElementById("email").addEventListener("blur", () => {

  validate(
    "field-email",
    "email",
    v => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)
  );

});

// ─────────────────────────────────────────────
// Submit Form
// ─────────────────────────────────────────────
document
  .getElementById("userForm")
  .addEventListener("submit", async (e) => {

    e.preventDefault();

    tempPasswordBox.style.display = "none";
    tempPasswordValue.textContent = "";

    const name  = document.getElementById("name").value.trim();
    const email = document.getElementById("email").value.trim();
    const role  = document.getElementById("role").value;

    // ─────────────────────────────────────────
    // Validation
    // ─────────────────────────────────────────
    const allValid = [

      validate(
        "field-name",
        "name",
        v => v.trim().length > 1
      ),

      validate(
        "field-email",
        "email",
        v => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)
      )

    ].every(Boolean);

    if (!allValid) {

      message.textContent = "Please fix the errors above.";
      message.style.color = "#ef4444";

      return;
    }

    // ─────────────────────────────────────────
    // Check Duplicate Email
    // ─────────────────────────────────────────
    try {

      const existing = await get(
        query(
          ref(database, "users"),
          orderByChild("email"),
          equalTo(email)
        )
      );

      if (existing.exists()) {

        message.textContent =
          " A user with this email already exists.";

        message.style.color = "#ef4444";

        return;
      }

    } catch (err) {

      console.log(err);

    }

    // ─────────────────────────────────────────
    // Start
    // ─────────────────────────────────────────
    message.textContent = " Creating user...";
    message.style.color = "#1b6b57";

    const temporaryPassword =
      generateTemporaryPassword();

    try {

      // ───────────────────────────────────────
      // 1. Create Firebase User
      // ───────────────────────────────────────
      const { user } =
        await createUserWithEmailAndPassword(
          auth,
          email,
          temporaryPassword
        );

      // ───────────────────────────────────────
      // 2. Save User In Database
      // ───────────────────────────────────────
      await set(
        ref(database, "users/" + user.uid),
        {
          name,
          email,
          role,

          mustChangePassword: true,

          createdAt: new Date().toISOString()
        }
      );

      // ───────────────────────────────────────
      // 3. Send Email
      // ───────────────────────────────────────
      await emailjs.send(

        EMAILJS_SERVICE_ID,
        EMAILJS_TEMPLATE_ID,

        {
          to_name:  name,
          to_email: email,

          passcode: temporaryPassword,

          time: "15 minutes"
        },

        EMAILJS_PUBLIC_KEY
      );

// Success
message.textContent =
  " User created successfully. OTP sent to user email.";

message.style.color = "#22c55e";

// Reset form
document.getElementById("userForm").reset();

    } catch (error) {

      console.log(error);

      const errors = {

        "auth/email-already-in-use":
          " Email already in use.",

        "auth/weak-password":
          " Password too weak.",

        "auth/invalid-email":
          " Invalid email address."

      };

      message.textContent =
        errors[error.code] || error.message;

      message.style.color = "#ef4444";
    }

});