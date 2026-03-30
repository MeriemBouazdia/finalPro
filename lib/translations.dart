import 'package:flutter/material.dart';

class Translations {
  final Locale locale;

  Translations(this.locale);

  static Translations of(BuildContext context) {
    return Translations(Localizations.localeOf(context));
  }

  static const LocalizationsDelegate<Translations> delegate =
      _TranslationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appName': 'Greenhouse App',
      'appTitle': 'Greenhouse App',

      // Login
      'welcomeBack': 'Welcome Back',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'dontHaveAccount': "Don't have an account? ",
      'signUp': 'Sign Up',
      'pleaseEnterEmailPassword': 'Please enter email and password',

      // Register
      'createAccount': 'Create Account',
      'registerToManage': 'Register to manage your smart greenhouse',
      'fullName': 'Full Name',
      'enterFullName': 'Enter your full name',
      'enterEmail': 'Enter your email address',
      'confirmPassword': 'Confirm Password',
      'reEnterPassword': 'Re-enter your password',
      'farmer': 'Farmer',
      'visitor': 'Visitor',
      'hasGreenhouse': 'I have a greenhouse',
      'farmLocation': 'Farm Location',
      'enterFarmLocation': 'Enter farm location',
      'register': 'Register',
      'alreadyHaveAccount': 'Already have an account? ',
      'loginLink': 'Login',

      // Validation
      'emailRequired': 'Email is required',
      'validEmail': 'Please enter a valid email',
      'passwordRequired': 'Password is required',
      'passwordMinLength': 'Password must be at least 6 characters',
      'confirmPasswordRequired': 'Please confirm your password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'nameRequired': 'Full name is required',
      'nameMinLength': 'Name must be at least 2 characters',
      'farmLocationRequired': 'Farm location is required',

      // Auth Errors
      'noAccountFound': 'No account found for this email.',
      'incorrectPassword': 'Incorrect password.',
      'invalidEmail': 'Please enter a valid email.',
      'accountDisabled': 'This account has been disabled.',
      'tooManyRequests': 'Too many attempts. Try again later.',
      'noInternet': 'No internet connection.',
      'loginFailed': 'Login failed.',
      'emailAlreadyRegistered': 'This email is already registered',
      'weakPassword': 'Password is too weak (min. 6 characters)',
      'invalidEmailAddress': 'Invalid email address',
      'registrationFailed': 'Registration failed',
      'errorOccurred': 'An error occurred. Please try again.',

      // Success
      'welcomeUser': 'Welcome {name}! Account created successfully.',
      'accountCreated': 'Account created successfully',

      // GH List
      'myGreenhouses': 'My Greenhouses',
      'noGreenhousesYet': 'No greenhouses yet',
      'addGreenhouse': 'Add Greenhouse',
      'addNewGreenhouse': 'Add New Greenhouse',
      'greenhouseName': 'Greenhouse Name',
      'greenhouseNameHint': 'e.g., Greenhouse 1',
      'plantType': 'Plant Type',
      'plantTypeHint': 'e.g., Tomatoes',
      'enterName': 'Please enter a name',
      'cancel': 'Cancel',
      'create': 'Create',
      'greenhouse': 'Greenhouse',

      // Home Page
      'greenhouseDashboard': 'Greenhouse Dashboard',
      'noSensorData': 'No sensor data available',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'soilMoisture': 'Soil Moisture',
      'light': 'Light',
      'temp': 'Temp',
      'soil': 'Soil',

      // Device Control
      'deviceControl': 'Device Control',
      'devices': 'Devices',
      'fan': 'Fan',
      'pump': 'Pump',
      'lightDevice': 'Light',
      'heater': 'Heater',
      'sprinkler': 'Sprinkler',
      'automatic': 'Automatic',
      'manual': 'Manual',
      'on': 'ON',
      'off': 'OFF',

      // Configuration
      'configuration': 'Configuration',
      'temperatureSettings': 'Temperature Settings',
      'humiditySettings': 'Humidity Settings',
      'soilSettings': 'Soil Moisture Settings',
      'lightSettings': 'Light Settings',
      'minTemperature': 'Min Temperature',
      'maxTemperature': 'Max Temperature',
      'minHumidity': 'Min Humidity',
      'maxHumidity': 'Max Humidity',
      'minSoil': 'Min Soil Moisture',
      'maxSoil': 'Max Soil Moisture',
      'minLight': 'Min Light',
      'maxLight': 'Max Light',
      'save': 'Save',
      'saveChanges': 'Save Changes',
      'configurationSaved': 'Configuration saved successfully',
      'errorSaving': 'Error saving: {error}',

      // Profile
      'profile': 'Profile',
      'loading': 'Loading...',
      'noName': 'No name',
      'editProfile': 'Edit Profile',
      'name': 'Name',
      'changePhoto': 'Change Photo',
      'saveProfile': 'Save Profile',
      'profileUpdated': 'Profile updated successfully',
      'uploading': 'Uploading...',
      'errorUploading': 'Error uploading image',

      // Chat
      'chat': 'Chat',
      'chatWithAI': 'Chat with AI Assistant',
      'typeMessage': 'Type a message...',
      'send': 'Send',
      'askAI': 'Ask AI about your greenhouse',
      'aiThinking': 'AI is thinking...',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'french': 'French',
      'arabic': 'العربية',
      'theme': 'Theme',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'logout': 'Log Out',
      'confirmLogout': 'Are you sure you want to log out?',
      'yes': 'Yes',
      'no': 'No',
      'password': 'Password',
      'helpSupport': 'Help & Support',
      'changePassword': 'Change Password',
      'home': 'Home',

      // General
      'error': 'Error',
      'success': 'Success',
      'pleaseLoginFirst': 'Please login first',
      'ok': 'OK',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'confirm': 'Confirm',
      'yesDelete': 'Yes, delete',
      'noKeep': 'No, keep',
    },
    'fr': {
      // App
      'appName': 'Application de serre',
      'appTitle': 'Application de serre',

      // Login
      'welcomeBack': 'Bon retour',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'login': 'Connexion',
      'dontHaveAccount': "Vous n'avez pas de compte? ",
      'signUp': "S'inscrire",
      'pleaseEnterEmailPassword': "Veuillez entrer l'e-mail et le mot de passe",

      // Register
      'createAccount': 'Créer un compte',
      'registerToManage': "Inscrivez-vous pour gérer votre serre intelligente",
      'fullName': 'Nom complet',
      'enterFullName': 'Entrez votre nom complet',
      'enterEmail': "Entrez votre adresse e-mail",
      'confirmPassword': 'Confirmer le mot de passe',
      'reEnterPassword': 'Entrez à nouveau le mot de passe',
      'farmer': 'Agriculteur',
      'visitor': 'Visiteur',
      'hasGreenhouse': "J'ai une serre",
      'farmLocation': 'Emplacement de la ferme',
      'enterFarmLocation': "Entrez l'emplacement de la ferme",
      'register': "S'inscrire",
      'alreadyHaveAccount': 'Vous avez déjà un compte? ',
      'loginLink': 'Connexion',

      // Validation
      'emailRequired': "L'e-mail est requis",
      'validEmail': "Veuillez entrer un e-mail valide",
      'passwordRequired': 'Le mot de passe est requis',
      'passwordMinLength':
          'Le mot de passe doit contenir au moins 6 caractères',
      'confirmPasswordRequired': 'Veuillez confirmer votre mot de passe',
      'passwordsDoNotMatch': 'Les mots de passe ne correspondent pas',
      'nameRequired': 'Le nom complet est requis',
      'nameMinLength': 'Le nom doit contenir au moins 2 caractères',
      'farmLocationRequired': "L'emplacement de la ferme est requis",

      // Auth Errors
      'noAccountFound': 'Aucun compte trouvé pour cet e-mail.',
      'incorrectPassword': 'Mot de passe incorrect.',
      'invalidEmail': "Veuillez entrer un e-mail valide.",
      'accountDisabled': 'Ce compte a été désactivé.',
      'tooManyRequests': "Trop de tentatives. Réessayez plus tard.",
      'noInternet': 'Pas de connexion Internet.',
      'loginFailed': 'Échec de la connexion.',
      'emailAlreadyRegistered': 'Cet e-mail est déjà enregistré',
      'weakPassword': 'Mot de passe trop faible (min. 6 caractères)',
      'invalidEmailAddress': "Adresse e-mail invalide",
      'registrationFailed': "L'inscription a échoué",
      'errorOccurred': 'Une erreur est survenue. Veuillez réessayer.',

      // Success
      'welcomeUser': 'Bienvenue {name}! Compte créé avec succès.',
      'accountCreated': 'Compte créé avec succès',

      // GH List
      'myGreenhouses': 'Mes serres',
      'noGreenhousesYet': 'Pas encore de serres',
      'addGreenhouse': 'Ajouter une serre',
      'addNewGreenhouse': 'Ajouter une nouvelle serre',
      'greenhouseName': 'Nom de la serre',
      'greenhouseNameHint': 'ex., Serre 1',
      'plantType': 'Type de plante',
      'plantTypeHint': 'ex., Tomates',
      'enterName': "Veuillez entrer un nom",
      'cancel': 'Annuler',
      'create': 'Créer',
      'greenhouse': 'Serre',

      // Home Page
      'greenhouseDashboard': 'Tableau de bord de la serre',
      'noSensorData': 'Aucune donnée de capteur disponible',
      'temperature': 'Température',
      'humidity': 'Humidité',
      'soilMoisture': 'Humidité du sol',
      'light': 'Lumière',
      'temp': 'Temp',
      'soil': 'Sol',

      // Device Control
      'deviceControl': 'Contrôle des appareils',
      'devices': 'Appareils',
      'fan': 'Ventilateur',
      'pump': 'Pompe',
      'lightDevice': 'Lumière',
      'heater': 'Chauffage',
      'sprinkler': 'Arroseur',
      'automatic': 'Automatique',
      'manual': 'Manuel',
      'on': 'ON',
      'off': 'OFF',

      // Configuration
      'configuration': 'Configuration',
      'temperatureSettings': 'Paramètres de température',
      'humiditySettings': "Paramètres d'humidité",
      'soilSettings': "Paramètres d'humidité du sol",
      'lightSettings': 'Paramètres de lumière',
      'minTemperature': 'Température min',
      'maxTemperature': 'Température max',
      'minHumidity': 'Humidité min',
      'maxHumidity': 'Humidité max',
      'minSoil': 'Humidité du sol min',
      'maxSoil': 'Humidité du sol max',
      'minLight': 'Lumière min',
      'maxLight': 'Lumière max',
      'save': 'Enregistrer',
      'saveChanges': 'Enregistrer les modifications',
      'configurationSaved': 'Configuration enregistrée avec succès',
      'errorSaving': "Erreur lors de l'enregistrement: {error}",

      // Profile
      'profile': 'Profil',
      'loading': 'Chargement...',
      'noName': 'Pas de nom',
      'editProfile': 'Modifier le profil',
      'name': 'Nom',
      'changePhoto': 'Changer la photo',
      'saveProfile': 'Enregistrer le profil',
      'profileUpdated': 'Profil mis à jour avec succès',
      'uploading': 'Téléchargement...',
      'errorUploading': "Erreur lors du téléchargement de l'image",

      // Chat
      'chat': 'Discussion',
      'chatWithAI': 'Discuter avec lAssistant IA',
      'typeMessage': 'Tapez un message...',
      'send': 'Envoyer',
      'askAI': "Demandez à l'IA au sujet de votre serre",
      'aiThinking': "L'IA réfléchit...",

      // Settings
      'settings': 'Paramètres',
      'language': 'Langue',
      'english': 'Anglais',
      'french': 'Français',
      'arabic': 'العربية',
      'theme': 'Thème',
      'darkMode': 'Mode sombre',
      'lightMode': 'Mode clair',
      'logout': 'Se déconnecter',
      'confirmLogout': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'yes': 'Oui',
      'no': 'Non',
      // ignore: equal_keys_in_map
      'password': 'Mot de passe',
      'helpSupport': 'Aide et support',
      'changePassword': 'Changer le mot de passe',
      'home': 'Accueil',

      // General
      'error': 'Erreur',
      'success': 'Succès',
      'pleaseLoginFirst': "Veuillez d'abord vous connecter",
      'ok': 'OK',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'confirm': 'Confirmer',
      'yesDelete': 'Oui, supprimer',
      'noKeep': 'Non, garder',
    },
    'ar': {
      // App
      'appName': 'تطبيق الدفيئة',
      'appTitle': 'تطبيق الدفيئة',

      // Login
      'welcomeBack': 'مرحباً بعودتك',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'dontHaveAccount': 'ليس لديك حساب؟ ',
      'signUp': 'سجل الآن',
      'pleaseEnterEmailPassword': 'الرجاء إدخال البريد الإلكتروني وكلمة المرور',

      // Register
      'createAccount': 'إنشاء حساب',
      'registerToManage': 'سجل لإدارة دفيئتك الذكية',
      'fullName': 'الاسم الكامل',
      'enterFullName': 'أدخل اسمك الكامل',
      'enterEmail': 'أدخل بريدك الإلكتروني',
      'confirmPassword': 'تأكيد كلمة المرور',
      'reEnterPassword': 'أعد إدخال كلمة المرور',
      'farmer': 'مزارع',
      'visitor': 'زائر',
      'hasGreenhouse': 'لدي دفيئة',
      'farmLocation': 'موقع المزرعة',
      'enterFarmLocation': 'أدخل موقع المزرعة',
      'register': 'سجل الآن',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟ ',
      'loginLink': 'تسجيل الدخول',

      // Validation
      'emailRequired': 'البريد الإلكتروني مطلوب',
      'validEmail': 'الرجاء إدخال بريد إلكتروني صالح',
      'passwordRequired': 'كلمة المرور مطلوبة',
      'passwordMinLength': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'confirmPasswordRequired': 'الرجاء تأكيد كلمة المرور',
      'passwordsDoNotMatch': 'كلمتا المرور غير متطابقتين',
      'nameRequired': 'الاسم الكامل مطلوب',
      'nameMinLength': 'يجب أن يكون الاسم حرفين على الأقل',
      'farmLocationRequired': 'موقع المزرعة مطلوب',

      // Auth Errors
      'noAccountFound': 'لا يوجد حساب لهذا البريد الإلكتروني.',
      'incorrectPassword': 'كلمة المرور غير صحيحة.',
      'invalidEmail': 'الرجاء إدخال بريد إلكتروني صالح.',
      'accountDisabled': 'تم تعطيل هذا الحساب.',
      'tooManyRequests': 'محاولات كثيرة. حاول مرة أخرى لاحقاً.',
      'noInternet': 'لا يوجد اتصال بالإنترنت.',
      'loginFailed': 'فشل تسجيل الدخول.',
      'emailAlreadyRegistered': 'هذا البريد الإلكتروني مسجل بالفعل',
      'weakPassword': 'كلمة المرور ضعيفة (最少 6 أحرف)',
      'invalidEmailAddress': 'عنوان بريد إلكتروني غير صالح',
      'registrationFailed': 'فشل التسجيل',
      'errorOccurred': 'حدث خطأ. الرجاء المحاولة مرة أخرى.',

      // Success
      'welcomeUser': 'مرحباً {name}! تم إنشاء الحساب بنجاح.',
      'accountCreated': 'تم إنشاء الحساب بنجاح',

      // GH List
      'myGreenhouses': 'دفيئاتي',
      'noGreenhousesYet': 'لا توجد دفيئات بعد',
      'addGreenhouse': 'إضافة دفيئة',
      'addNewGreenhouse': 'إضافة دفيئة جديدة',
      'greenhouseName': 'اسم الدفيئة',
      'greenhouseNameHint': 'مثال: الدفيئة 1',
      'plantType': 'نوع النبات',
      'plantTypeHint': 'مثال: طماطم',
      'enterName': 'الرجاء إدخال اسم',
      'cancel': 'إلغاء',
      'create': 'إنشاء',
      'greenhouse': 'دفيئة',

      // Home Page
      'greenhouseDashboard': 'لوحة معلومات الدفيئة',
      'noSensorData': 'لا تتوفر بيانات من المستشعر',
      'temperature': 'الحرارة',
      'humidity': 'الرطوبة',
      'soilMoisture': 'رطوبة التربة',
      'light': 'الإضاءة',
      'temp': 'حرارة',
      'soil': 'تربة',

      // Device Control
      'deviceControl': 'التحكم بالأجهزة',
      'devices': 'الأجهزة',
      'fan': 'مروحة',
      'pump': 'مضخة',
      'lightDevice': 'إضاءة',
      'heater': 'سخان',
      'sprinkler': 'راذاع',
      'automatic': 'تلقائي',
      'manual': 'يدوي',
      'on': 'تشغيل',
      'off': 'إيقاف',

      // Configuration
      'configuration': 'الإعدادات',
      'temperatureSettings': 'إعدادات الحرارة',
      'humiditySettings': 'إعدادات الرطوبة',
      'soilSettings': 'إعدادات رطوبة التربة',
      'lightSettings': 'إعدادات الإضاءة',
      'minTemperature': 'الحرارة الدنيا',
      'maxTemperature': 'الحرارة القصوى',
      'minHumidity': 'الرطوبة الدنيا',
      'maxHumidity': 'الرطوبة القصوى',
      'minSoil': 'رطوبة التربة الدنيا',
      'maxSoil': 'رطوبة التربة القصوى',
      'minLight': 'الإضاءة الدنيا',
      'maxLight': 'الإضاءة القصوى',
      'save': 'حفظ',
      'saveChanges': 'حفظ التغييرات',
      'configurationSaved': 'تم حفظ الإعدادات بنجاح',
      'errorSaving': 'خطأ في الحفظ: {error}',

      // Profile
      'profile': 'الملف الشخصي',
      'loading': 'جاري التحميل...',
      'noName': 'بدون اسم',
      'editProfile': 'تعديل الملف الشخصي',
      'name': 'الاسم',
      'changePhoto': 'تغيير الصورة',
      'saveProfile': 'حفظ الملف الشخصي',
      'profileUpdated': 'تم تحديث الملف الشخصي بنجاح',
      'uploading': 'جاري الرفع...',
      'errorUploading': 'خطأ في رفع الصورة',

      // Chat
      'chat': 'الدردشة',
      'chatWithAI': 'الدردشة مع مساعد الذكاء الاصطناعي',
      'typeMessage': 'اكتب رسالة...',
      'send': 'إرسال',
      'askAI': 'اسأل الذكاء الاصطناعي عن دفيئتك',
      'aiThinking': 'الذكاء الاصطناعي يفكر...',

      // Settings
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'arabic': 'العربية',
      'theme': 'المظهر',
      'darkMode': 'الوضع الداكن',
      'lightMode': 'الوضع الفاتح',
      'logout': 'تسجيل الخروج',
      'confirmLogout': 'هل أنت متأكد من تسجيل الخروج؟',
      'yes': 'نعم',
      'no': 'لا',
      'password': 'كلمة المرور',
      'helpSupport': 'المساعدة والدعم',
      'changePassword': 'تغيير كلمة المرور',
      'home': 'الرئيسية',

      // General
      'error': 'خطأ',
      'success': 'نجاح',
      'pleaseLoginFirst': 'الرجاء تسجيل الدخول أولاً',
      'ok': 'موافق',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'confirm': 'تأكيد',
      'yesDelete': 'نعم، احذف',
      'noKeep': 'لا، احتفظ',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  /// Get text with parameters replacement
  String getWithParams(String key, Map<String, String> params) {
    String text = get(key);
    params.forEach((paramKey, value) {
      text = text.replaceAll('{$paramKey}', value);
    });
    return text;
  }

  /// Check if current locale is RTL
  bool get isRtl => locale.languageCode == 'ar';

  /// Get text direction
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Get alignment based on locale
  Alignment get alignment =>
      isRtl ? Alignment.centerRight : Alignment.centerLeft;
}

class _TranslationsDelegate extends LocalizationsDelegate<Translations> {
  const _TranslationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<Translations> load(Locale locale) async {
    return Translations(locale);
  }

  @override
  bool shouldReload(_TranslationsDelegate old) => true;
}

/// Helper extension to easily access translations
extension TranslationsExtension on BuildContext {
  Translations get tr => Translations.of(this);
}
