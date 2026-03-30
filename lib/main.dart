import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/widget/theme_provider.dart';
import 'pages/widget/locale_provider.dart';
import 'translations.dart';
import 'login.dart';
import 'pages/register.dart';
import 'pages/ghlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const GreenhouseApp());
}

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key});

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
                    Translations.delegate,
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
                  initialRoute: '/login',
                  routes: {
                    '/login': (context) => const Login(),
                    '/main': (context) => const GHListPage(),
                    '/register': (context) => const Register(),
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
