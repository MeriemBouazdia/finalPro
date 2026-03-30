import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Check if current locale is RTL
  bool get isRtl => _locale.languageCode == 'ar';

  /// Get text direction based on current locale
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  /// Set locale by language code
  void setLocaleByCode(String languageCode) {
    setLocale(Locale(languageCode));
  }
}
