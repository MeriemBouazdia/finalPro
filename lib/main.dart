import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'pages/widget/theme_provider.dart';
import 'pages/widget/locale_provider.dart';
import 'package:app/l10n/translations.dart';
import 'login.dart';
import 'pages/register.dart';
import 'pages/ghlist.dart';
import 'wrapper.dart';
import 'pages/onboarding.dart';
import 'services/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(GreenhouseApp(
    seenOnboarding: seenOnboarding,
    isLoggedIn: isLoggedIn,
  ));
}

class GreenhouseApp extends StatelessWidget {
  final bool seenOnboarding;
  final bool isLoggedIn;

  const GreenhouseApp({
    super.key,
    required this.seenOnboarding,
    required this.isLoggedIn,
  });
  Widget get _startScreen {
    if (isLoggedIn) return const GHListPage();
    if (seenOnboarding) return const Login();
    return const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ChangeNotifierProvider(
            create: (_) => LocaleProvider(),
            child: Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Greenhouse App',
                  theme: themeProvider.themeData,
                  locale: localeProvider.locale,
                  supportedLocales: const [
                    Locale('en'),
                    Locale('fr'),
                    Locale('ar'),
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  builder: (context, child) {
                    return Consumer<LocaleProvider>(
                      builder: (context, localeProvider, _) {
                        final translations = Translations.of(context);
                        return Directionality(
                          textDirection: translations.textDirection,
                          child: child!,
                        );
                      },
                    );
                  },
                  home: _startScreen,
                  routes: {
                    '/login': (context) => const Login(),
                    '/main': (context) => const GHListPage(),
                    '/register': (context) => const RegisterScreen(),
                    '/wrapper': (context) => const Wrapper(),
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
