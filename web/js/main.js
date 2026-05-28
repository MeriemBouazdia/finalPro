import { initializeApp }
  from "https://www.gstatic.com/firebasejs/9.22.1/firebase-app.js";
import { getDatabase }
  from "https://www.gstatic.com/firebasejs/9.22.1/firebase-database.js";
import { getAuth, signOut }
  from "https://www.gstatic.com/firebasejs/9.22.1/firebase-auth.js";

const firebaseConfig = {
  apiKey:            "AIzaSyAn6qEFu9w6bkxp7zMc84B5zHtuz3iRZhY",
  authDomain:        "greenhouseapp-bd86f.firebaseapp.com",
  databaseURL:       "https://greenhouseapp-bd86f-default-rtdb.firebaseio.com",
  projectId:         "greenhouseapp-bd86f",
  storageBucket:     "greenhouseapp-bd86f.firebasestorage.app",
  messagingSenderId: "544572974576",
  appId:             "1:544572974576:web:f1749ac41d653ae2c2e935",
};

const app      = initializeApp(firebaseConfig);
export const database = getDatabase(app);
export const auth     = getAuth(app);
const i18n = {
  en: {
    app_name:                       "GreenIQ",
    dashboard:                      "Dashboard",
    greenhouses:                    "Greenhouses",
    addGreenhouse:                  "Add Greenhouse",
    addUser:                        "Add User",
    logout:                         "Logout",
    nav_overview:                   "Overview",
    nav_admin:                      "Admin",
    "Real-time overview of your greenhouse system":
      "Monitor conditions, control devices, and optimize plant growth with ease.",
    stats_totalUsers:               "Total Users",
    stats_registeredAccounts:       "Registered accounts",
    stats_greenhouses:              "Greenhouses",
    stats_acrossAllUsers:           "Across all users",
    gauge_usersActivity:            "Users Activity",
    gauge_greenhousesActivity:      "Greenhouses",
    gauge_liveFirebaseData:         "Live Firebase data",
    greenhouse_page_subtitle:       "All greenhouses across every user",
    greenhouse_table_title:         "All Greenhouses",
    table_user:                     "User",
    table_email:                    "Email",
    table_greenhouse:               "Greenhouse",
    table_location:                 "Location",
    table_action:                   "Action",
    form_createNewAccount:          "Create a new account.",
    form_fullName:                  "Full name",
    form_email:                     "Email",
    form_password:                  "Password",
    form_confirmPassword:           "Confirm password",
    form_role:                      "Role",
    form_addUserButton:             "Add User",
    form_userOption:                "User",
    form_adminOption:               "Admin",
    footer_connected:               "Connected to Firebase Realtime Database",
    title_dashboard:                "GreenAdmin — Dashboard",
    title_greenhouses:              "GreenAdmin — Greenhouses",
    title_addUser:                  "GreenAdmin — Add User",
    form_farmerOption:              "Farmer",

    // ── GREENHOUSE CONTROL PANEL TRANSLATIONS ──
    gh_title:                       "Greenhouse Control",
    gh_subtitle:                    "Real-time monitoring and control",
    gh_connecting:                  "Connecting to Firebase...",
    gh_connected:                   "Connected",
    gh_disconnected:                "Disconnected",
    Realtimemonitoringandcontrol: "Real-time monitoring and control",

    // ── ALERTS ──
    gh_auto_mode_alert:             "System is controlling automatically. Switch to MANUAL mode to adjust devices.",
    gh_connection_lost:             "Connection lost. Check your internet and Firebase setup.",

    // ── SECTIONS ──
    gh_section_sensors:             "Live Sensor Data",
    gh_section_actuators:           "Device Controls",
    gh_section_targets:             "Setpoints & Targets",
    gh_section_history:             "24-Hour History",

    // ── SENSORS ──
    gh_sensor_temperature:          "Temperature",
    gh_sensor_humidity:             "Humidity",
    gh_sensor_soilMoisture:         "Soil Moisture",
    gh_sensor_light:                "Light",
    gh_sensor_status_normal:        "Normal",
    gh_sensor_status_warning:       "Warning",
    gh_sensor_status_critical:      "Critical",
    gh_sensor_updated:              "Updated:",

    // ── ACTUATORS / CONTROLS ──
    gh_control_mode:                "Control Mode",
    gh_mode_auto:                   "AUTO",
    gh_mode_manual:                 "MANUAL",
    gh_mode_hint:                   "Auto: System controls automatically\nManual: You control devices",

    gh_device_pump:                 "Pump",
    gh_device_pump_desc:            "Water System",
    gh_device_fan:                  "Fan",
    gh_device_fan_desc:             "Circulation Fan",
    gh_device_light:                "Grow Light",
    gh_device_light_desc:           "LED Array",
    gh_device_vent:                 "Vent",
    gh_device_vent_desc:            "Ventilation Vent",

    // ── TARGETS / SETPOINTS ──
    gh_target_temperature:          "Target Temperature",
    gh_target_temperature_unit:     "°C",
    gh_target_soil:                 "Target Soil Moisture",
    gh_target_soil_unit:            "%",
    gh_target_save:                 "Save",
    gh_target_reset:                "Reset",
    gh_target_saved:                "Target saved!",
    gh_target_reset_msg:            "Target reset to default",

    // ── CHART ──
    gh_chart_title:                 "Temperature & Humidity Trend",
    gh_chart_temperature:           "Temperature (°C)",
    gh_chart_humidity:              "Humidity (%)",

    // ── STATUS MESSAGES ──
    gh_status_success:              "Success",
    gh_status_error:                "Error",
    gh_status_loading:              "Loading...",
    gh_status_saving:               "Saving...",
    gh_error_invalid_input:         "Please enter a valid number",
    gh_error_failed_save:           "Failed to save target",
    gh_error_not_found:             "Greenhouse not found",

    // ── NOTIFICATIONS ──
    gh_notification_connected:      "Connected to Firebase",
    gh_notification_disconnected:   "Disconnected from Firebase",
    gh_notification_toggled:        "Device toggled",
    gh_notification_mode_changed:   "Control mode changed",
  },

  fr: {
    // ── EXISTING TRANSLATIONS ──
    app_name:                       "GreenIQ",
    dashboard:                      "Tableau de bord",
    greenhouses:                    "Serres",
    addGreenhouse:                  "Ajouter une Serre",
    addUser:                        "Ajouter un utilisateur",
    logout:                         "Déconnexion",
    nav_overview:                   "Vue d'ensemble",
    nav_admin:                      "Administration",
    "Real-time overview of your greenhouse system":
      "Surveillez les conditions, contrôlez les appareils et optimisez la croissance des plantes en toute simplicité.",
    stats_totalUsers:               "Total des utilisateurs",
    stats_registeredAccounts:       "Comptes enregistrés",
    stats_greenhouses:              "Serres",
    stats_acrossAllUsers:           "Sur tous les utilisateurs",
    gauge_usersActivity:            "Activité des utilisateurs",
    gauge_greenhousesActivity:      "Serres",
    gauge_liveFirebaseData:         "Données Firebase en direct",
    greenhouse_page_subtitle:       "Toutes les serres de chaque utilisateur",
    greenhouse_table_title:         "Toutes les serres",
    table_user:                     "Utilisateur",
    table_email:                    "E-mail",
    table_greenhouse:               "Serre",
    table_location:                 "Emplacement",
    table_action:                   "Action",
    form_createNewAccount:          "Créer un nouveau compte.",
    form_fullName:                  "Nom complet",
    form_email:                     "E-mail",
    form_password:                  "Mot de passe",
    form_confirmPassword:           "Confirmez le mot de passe",
    form_role:                      "Rôle",
    form_addUserButton:             "Ajouter un utilisateur",
    form_userOption:                "Utilisateur",
    form_adminOption:               "Administrateur",
    footer_connected:               "Connecté à Firebase Realtime Database",
    title_dashboard:                "GreenAdmin — Tableau de bord",
    title_greenhouses:              "GreenAdmin — Serres",
    title_addUser:                  "GreenAdmin — Ajouter un utilisateur",
    form_farmerOption:              "Agriculteur",

    // ── GREENHOUSE CONTROL PANEL TRANSLATIONS ──
    gh_title:                       "Contrôle de la Serre",
    gh_subtitle:                    "Surveillance et contrôle en temps réel",
    gh_connecting:                  "Connexion à Firebase...",
    gh_connected:                   "Connecté",
    gh_disconnected:                "Déconnecté",

    // ── ALERTS ──
    gh_auto_mode_alert:             "Le système contrôle automatiquement. Passez en mode MANUEL pour ajuster les appareils.",
    gh_connection_lost:             "Connexion perdue. Vérifiez votre Internet et votre configuration Firebase.",

    // ── SECTIONS ──
    gh_section_sensors:             "Données des Capteurs en Direct",
    gh_section_actuators:           "Contrôle des Appareils",
    gh_section_targets:             "Points de Consigne et Cibles",
    gh_section_history:             "Historique 24 Heures",

    // ── SENSORS ──
    gh_sensor_temperature:          "Température",
    gh_sensor_humidity:             "Humidité",
    gh_sensor_soilMoisture:         "Humidité du Sol",
    gh_sensor_light:                "Lumière",
    gh_sensor_status_normal:        "Normal",
    gh_sensor_status_warning:       "Avertissement",
    gh_sensor_status_critical:      "Critique",
    gh_sensor_updated:              "Mis à jour :",

    // ── ACTUATORS / CONTROLS ──
    gh_control_mode:                "Mode de Contrôle",
    gh_mode_auto:                   "AUTO",
    gh_mode_manual:                 "MANUEL",
    gh_mode_hint:                   "Auto : Le système contrôle automatiquement\nManuel : Vous contrôlez les appareils",

    gh_device_pump:                 "Pompe",
    gh_device_pump_desc:            "Système d'Eau",
    gh_device_fan:                  "Ventilateur",
    gh_device_fan_desc:             "Ventilateur de Circulation",
    gh_device_light:                "Lampe Horticole",
    gh_device_light_desc:           "Barrette LED",
    gh_device_vent:                 "Ventilation",
    gh_device_vent_desc:            "Ouverture de Ventilation",

    // ── TARGETS / SETPOINTS ──
    gh_target_temperature:          "Température Cible",
    gh_target_temperature_unit:     "°C",
    gh_target_soil:                 "Humidité du Sol Cible",
    gh_target_soil_unit:            "%",
    gh_target_save:                 "Enregistrer",
    gh_target_reset:                "Réinitialiser",
    gh_target_saved:                "Cible enregistrée !",
    gh_target_reset_msg:            "Cible réinitialisée par défaut",

    // ── CHART ──
    gh_chart_title:                 "Tendance Température et Humidité",
    gh_chart_temperature:           "Température (°C)",
    gh_chart_humidity:              "Humidité (%)",

    // ── STATUS MESSAGES ──
    gh_status_success:              "Succès",
    gh_status_error:                "Erreur",
    gh_status_loading:              "Chargement...",
    gh_status_saving:               "Enregistrement...",
    gh_error_invalid_input:         "Veuillez entrer un nombre valide",
    gh_error_failed_save:           "Impossible d'enregistrer la cible",
    gh_error_not_found:             "Serre non trouvée",

    // ── NOTIFICATIONS ──
    gh_notification_connected:      "Connecté à Firebase",
    gh_notification_disconnected:   "Déconnecté de Firebase",
    gh_notification_toggled:        "Appareil basculé",
    gh_notification_mode_changed:   "Mode de contrôle modifié",
  },

  ar: {
    // ── EXISTING TRANSLATIONS ──
    app_name:                       "GreenIQ",
    dashboard:                      "لوحة التحكم",
    greenhouses:                    "البيوت المحمية",
    addGreenhouse:                  "إضافة بيت محمي",
    addUser:                        "إضافة مستخدم",
    logout:                         "تسجيل الخروج",
    nav_overview:                   "نظرة عامة",
    nav_admin:                      "إدارة",
    "Real-time overview of your greenhouse system":
      "راقب الظروف، تحكم في الأجهزة، وحسن نمو النباتات بسهولة.",
    stats_totalUsers:               "إجمالي المستخدمين",
    stats_registeredAccounts:       "الحسابات المسجلة",
    stats_greenhouses:              "البيوت المحمية",
    stats_acrossAllUsers:           "عبر جميع المستخدمين",
    gauge_usersActivity:            "نشاط المستخدمين",
    gauge_greenhousesActivity:      "البيوت المحمية",
    gauge_liveFirebaseData:         "بيانات Firebase الحية",
    greenhouse_page_subtitle:       "جميع البيوت المحمية لكل مستخدم",
    greenhouse_table_title:         "جميع البيوت المحمية",
    table_user:                     "المستخدم",
    table_email:                    "البريد الإلكتروني",
    table_greenhouse:               "البيت المحمي",
    table_location:                 "الموقع",
    table_action:                   "الإجراء",
    form_createNewAccount:          "إنشاء حساب جديد.",
    form_fullName:                  "الاسم الكامل",
    form_email:                     "البريد الإلكتروني",
    form_password:                  "كلمة المرور",
    form_confirmPassword:           "تأكيد كلمة المرور",
    form_role:                      "الدور",
    form_addUserButton:             "إضافة مستخدم",
    form_userOption:                "مستخدم",
    form_adminOption:               "مشرف",
    footer_connected:               "متصل بقاعدة بيانات Firebase الفورية",
    title_dashboard:                "GreenAdmin — لوحة التحكم",
    title_greenhouses:              "GreenAdmin — البيوت المحمية",
    title_addUser:                  "GreenAdmin — إضافة مستخدم",
    form_farmerOption:              "مزارع",

    // ── GREENHOUSE CONTROL PANEL TRANSLATIONS ──
    gh_title:                       "التحكم في البيت المحمي",
    gh_subtitle:                    "المراقبة والتحكم في الوقت الفعلي",
    gh_connecting:                  "جاري الاتصال بـ Firebase...",
    gh_connected:                   "متصل",
    gh_disconnected:                "غير متصل",

    // ── ALERTS ──
    gh_auto_mode_alert:             "النظام يتحكم تلقائياً. انتقل إلى وضع يدوي لتعديل الأجهزة.",
    gh_connection_lost:             "انقطع الاتصال. تحقق من الإنترنت وإعدادات Firebase.",

    // ── SECTIONS ──
    gh_section_sensors:             "بيانات المستشعرات الحية",
    gh_section_actuators:           "التحكم في الأجهزة",
    gh_section_targets:             "نقاط الضبط والأهداف",
    gh_section_history:             "السجل 24 ساعة",

    // ── SENSORS ──
    gh_sensor_temperature:          "درجة الحرارة",
    gh_sensor_humidity:             "الرطوبة",
    gh_sensor_soilMoisture:         "رطوبة التربة",
    gh_sensor_light:                "الضوء",
    gh_sensor_status_normal:        "عادي",
    gh_sensor_status_warning:       "تحذير",
    gh_sensor_status_critical:      "حرج",
    gh_sensor_updated:              "تم التحديث:",

    // ── ACTUATORS / CONTROLS ──
    gh_control_mode:                "وضع التحكم",
    gh_mode_auto:                   "تلقائي",
    gh_mode_manual:                 "يدوي",
    gh_mode_hint:                   "التلقائي: يتحكم النظام تلقائياً\nاليدوي: أنت تتحكم في الأجهزة",

    gh_device_pump:                 "مضخة",
    gh_device_pump_desc:            "نظام المياه",
    gh_device_fan:                  "مروحة",
    gh_device_fan_desc:             "مروحة التدوير",
    gh_device_light:                "مصباح النمو",
    gh_device_light_desc:           "مصفوفة LED",
    gh_device_vent:                 "التهوية",
    gh_device_vent_desc:            "فتحة التهوية",

    // ── TARGETS / SETPOINTS ──
    gh_target_temperature:          "درجة الحرارة المستهدفة",
    gh_target_temperature_unit:     "°م",
    gh_target_soil:                 "رطوبة التربة المستهدفة",
    gh_target_soil_unit:            "%",
    gh_target_save:                 "حفظ",
    gh_target_reset:                "إعادة تعيين",
    gh_target_saved:                "تم حفظ الهدف!",
    gh_target_reset_msg:            "تم إعادة تعيين الهدف إلى الافتراضي",

    // ── CHART ──
    gh_chart_title:                 "اتجاه درجة الحرارة والرطوبة",
    gh_chart_temperature:           "درجة الحرارة (°م)",
    gh_chart_humidity:              "الرطوبة (%)",

    // ── STATUS MESSAGES ──
    gh_status_success:              "نجح",
    gh_status_error:                "خطأ",
    gh_status_loading:              "جاري التحميل...",
    gh_status_saving:               "جاري الحفظ...",
    gh_error_invalid_input:         "يرجى إدخال رقم صحيح",
    gh_error_failed_save:           "فشل في حفظ الهدف",
    gh_error_not_found:             "البيت المحمي غير موجود",

    // ── NOTIFICATIONS ──
    gh_notification_connected:      "متصل بـ Firebase",
    gh_notification_disconnected:   "غير متصل بـ Firebase",
    gh_notification_toggled:        "تم تبديل الجهاز",
    gh_notification_mode_changed:   "تم تغيير وضع التحكم",
  },
};

let currentLang = localStorage.getItem("lang") || "en";

export function applyLang(lang) {
  currentLang = lang;
  localStorage.setItem("lang", lang);
  document.documentElement.lang = lang;
  document.documentElement.dir  = lang === "ar" ? "rtl" : "ltr";

  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.dataset.i18n;
    if (i18n[lang]?.[key]) el.textContent = i18n[lang][key];
  });

  document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
    const key = el.dataset.i18nPlaceholder;
    if (i18n[lang]?.[key]) el.placeholder = i18n[lang][key];
  });

  document.querySelectorAll("[data-i18n-title]").forEach(el => {
    const key = el.dataset.i18nTitle;
    if (i18n[lang]?.[key]) el.title = i18n[lang][key];
  });

  document.querySelectorAll("[data-lang]").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.lang === lang);
  });
}

/* ─── Dark mode ─────────────────────────────────────────────────────────── */
export function applyDark(dark) {
  document.documentElement.classList.toggle("dark", dark);
  localStorage.setItem("dark", dark ? "1" : "0");
}

const savedDark =
  localStorage.getItem("dark") === "1" ||
  (localStorage.getItem("dark") === null &&
   window.matchMedia("(prefers-color-scheme: dark)").matches);
applyDark(savedDark);

/* ─── Component loader ───────────────────────────────────────────────────── */
async function loadComponent(id, url) {
  const el = document.getElementById(id);
  if (!el) return;
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    el.innerHTML = await res.text();
  } catch (e) {
    console.warn(`[GreenAdmin] Could not load #${id} from ${url}:`, e.message);
  }
}

/* ─── Sidebar ────────────────────────────────────────────────────────────── */
function initSidebar() {
  const sidebar   = document.getElementById("sidebarEl");
  const overlay   = document.getElementById("sidebarOverlay");
  const toggleBtn = document.querySelector(".sidebar-toggle-btn");

  // Restore collapsed state on desktop
  const collapsed = localStorage.getItem("sidebarCollapsed") === "1";
  if (collapsed && window.innerWidth > 768) {
    sidebar?.classList.add("collapsed");
    document.body.classList.add("sidebar-collapsed");
  }

  toggleBtn?.addEventListener("click", () => {
    if (window.innerWidth <= 768) {
      const open = sidebar?.classList.toggle("mobile-open");
      overlay?.classList.toggle("visible", open);
    } else {
      const isCollapsed = sidebar?.classList.toggle("collapsed");
      document.body.classList.toggle("sidebar-collapsed", isCollapsed);
      localStorage.setItem("sidebarCollapsed", isCollapsed ? "1" : "0");
    }
  });

  overlay?.addEventListener("click", () => {
    sidebar?.classList.remove("mobile-open");
    overlay?.classList.remove("visible");
  });

  // Active nav link
  const currentFile = window.location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(".nav-link[data-page]").forEach(a => {
    a.classList.toggle("active", a.dataset.page === currentFile);
  });
}

/* ─── Dark toggle ────────────────────────────────────────────────────────── */
function initDarkToggle() {
  document.getElementById("darkToggle")?.addEventListener("click", () => {
    applyDark(!document.documentElement.classList.contains("dark"));
  });
}

/* ─── Language toggle ────────────────────────────────────────────────────── */
function initLangToggle() {
  document.querySelectorAll("[data-lang]").forEach(btn => {
    btn.addEventListener("click", () => applyLang(btn.dataset.lang));
  });
}

/* ─── Logout ─────────────────────────────────────────────────────────────── */
function initLogout() {
  document.getElementById("logoutBtn")?.addEventListener("click", async () => {
    try {
      await signOut(auth);
      window.location.href = "login.html";
    } catch (err) {
      console.error("[GreenAdmin] Logout failed:", err.message);
    }
  });
}

/* ─── Main init ──────────────────────────────────────────────────────────── */
export async function initDashboard(base = ".") {
  await Promise.all([
    loadComponent("header",  `${base}/header.html`),
    loadComponent("sidebar", `${base}/sidebar.html`),
    loadComponent("footer",  `${base}/footer.html`),
  ]);

  initSidebar();
  initDarkToggle();
  initLangToggle();
  initLogout();
  applyLang(currentLang);
}
