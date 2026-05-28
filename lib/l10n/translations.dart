import 'package:flutter/material.dart';
import 'en.dart';
import 'fr.dart';
import 'ar.dart';

class Translations {
  final Locale locale;

  Translations(this.locale);

  static Translations of(BuildContext context) {
    return Translations(Localizations.localeOf(context));
  }

  static const LocalizationsDelegate<Translations> delegate =
      _TranslationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': en,
    'fr': fr,
    'ar': ar,
  };

  String get(String key) {
    final langCode = locale.languageCode;

    // Try to get from current language
    if (_localizedValues.containsKey(langCode)) {
      if (_localizedValues[langCode]!.containsKey(key)) {
        return _localizedValues[langCode]![key]!;
      }
    }

    // Fall back to English
    if (_localizedValues['en']!.containsKey(key)) {
      return _localizedValues['en']![key]!;
    }

    // Return key itself if not found
    return key;
  }

  /// Get text with parameters replacement
  /// Example: tp('welcomeUser', {'name': 'John'})
  /// Will replace {name} with 'John'
  String getWithParams(String key, Map<String, String> params) {
    String text = get(key);
    params.forEach((paramKey, value) {
      text = text.replaceAll('{$paramKey}', value);
    });
    return text;
  }

  /// Check if current locale is RTL (Right-To-Left)
  bool get isRtl => locale.languageCode == 'ar';

  /// Get text direction based on locale
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Get alignment based on locale (useful for padding and positioning)
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
  bool shouldReload(_TranslationsDelegate old) => false;
}

/// Extension to provide convenient access to translations in BuildContext
extension TranslationsExtension on BuildContext {
  /// Get the Translations instance
  Translations get tr => Translations.of(this);

  /// Shorthand for tr.get(key)
  /// Usage: context.t('appName')
  String t(String key) => tr.get(key);

  /// Shorthand for tr.getWithParams(key, params)
  /// Usage: context.tp('welcomeUser', {'name': 'John'})
  String tp(String key, Map<String, String> params) =>
      tr.getWithParams(key, params);

  /// Check if current locale is RTL
  bool get isRtl => tr.isRtl;

  /// Get text direction for current locale
  TextDirection get textDirection => tr.textDirection;
}
