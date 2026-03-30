import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'locale_provider.dart';
import 'theme_provider.dart';

/// A reusable settings ListTile widget
class SettingsListTile extends StatelessWidget {
  /// The leading icon
  final IconData icon;

  /// The icon color
  final Color? iconColor;

  /// The title text
  final String title;

  /// The subtitle text (optional)
  final String? subtitle;

  /// The trailing widget
  final Widget? trailing;

  /// Callback when the tile is tapped
  final VoidCallback? onTap;

  const SettingsListTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// A widget that displays profile settings (dark mode, language, help, logout)
class ProfileSettings extends StatelessWidget {
  /// Whether dark mode is enabled
  final bool isDarkMode;

  /// Whether the layout should be RTL
  final bool isRtl;

  /// Translation function for getting localized strings
  final String Function(String key) getTranslation;

  /// Callback when logout is pressed
  final VoidCallback onLogout;

  /// Callback when password change is pressed
  final VoidCallback onChangePassword;

  /// Callback when help is pressed
  final VoidCallback onHelp;

  const ProfileSettings({
    super.key,
    this.isDarkMode = false,
    this.isRtl = false,
    required this.getTranslation,
    required this.onLogout,
    required this.onChangePassword,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        isDarkMode ? const Color(0xFF3C3C3C) : Colors.grey[300];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Password change
          _buildSettingsItem(
            icon: Icons.lock,
            title: getTranslation('password'),
            onTap: onChangePassword,
          ),
          // Help & Support
          _buildSettingsItem(
            icon: Icons.headset_mic,
            title: getTranslation('helpSupport'),
            onTap: onHelp,
          ),
          // Divider
          Divider(
            thickness: 1.5,
            color: dividerColor,
          ),
          // Dark Mode
          _buildDarkModeItem(context),
          // Divider
          Divider(
            thickness: 1.5,
            color: dividerColor,
          ),
          // Language
          _buildLanguageItem(context),
          // Logout
          _buildLogoutItem(),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white70 : const Color(0xFF336A29);

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(
        isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
        size: 16,
        color: isDarkMode ? Colors.white54 : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDarkModeItem(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return ListTile(
      leading: Icon(
        Icons.dark_mode_outlined,
        color: isDarkMode ? Colors.white70 : const Color(0xFF642ef3),
      ),
      title: Text(
        getTranslation('darkMode'),
        style: TextStyle(color: textColor),
      ),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (value) {
          context.read<ThemeProvider>().setDarkMode(value);
        },
        activeThumbColor: const Color(0xFF336A29),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.locale.languageCode;

    String getCurrentLanguage() {
      switch (currentLang) {
        case 'fr':
          return "Français";
        case 'ar':
          return "العربية";
        default:
          return "English";
      }
    }

    return ListTile(
      leading: const Icon(Icons.language, color: Color(0xFF336A29)),
      title: Text(getTranslation('language')),
      subtitle: Text(
        getCurrentLanguage(), // 👈 تبان اللغة المختارة
        style: TextStyle(
          color: isDarkMode ? Colors.white60 : Colors.grey,
        ),
      ),
      trailing: Icon(
        isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
        size: 16,
        color: isDarkMode ? Colors.white54 : Colors.grey,
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // English
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("English"),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    context
                        .read<LocaleProvider>()
                        .setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),

                // French
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Français"),
                  trailing: currentLang == 'fr'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    context
                        .read<LocaleProvider>()
                        .setLocale(const Locale('fr'));
                    Navigator.pop(context);
                  },
                ),

                // Arabic
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text("العربية"),
                  trailing: currentLang == 'ar'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    context
                        .read<LocaleProvider>()
                        .setLocale(const Locale('ar'));
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 10),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutItem() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: Text(
        getTranslation('logout'),
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
        size: 16,
        color: Colors.red.withValues(alpha: 0.7),
      ),
      onTap: onLogout,
    );
  }
}
