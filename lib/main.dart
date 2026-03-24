import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'pages/widget/theme_provider.dart';
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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Greenhouse App',
            theme: themeProvider.themeData,
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
  }
}
