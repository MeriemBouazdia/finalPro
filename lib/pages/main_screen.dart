import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/l10n/translations.dart';
import 'home_page.dart';
import '../screens/bot_page.dart';
import 'profile_page.dart';
import 'configuration_page.dart';
import 'widget/theme_provider.dart';
import '../screens/history_screen.dart';
import 'screenchat.dart';

class MainScreen extends StatefulWidget {
  final String ghId;

  const MainScreen({super.key, required this.ghId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(ghId: widget.ghId),
      HistoryPage(firebaseGhId: widget.ghId),
      BotPage(greenhouseId: widget.ghId),
      const ChatScreen(),
      ConfigurationPage(ghId: widget.ghId),
      const ProfilePage(),
    ];
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 4, 154, 24),
        unselectedItemColor: isDarkMode ? Colors.white54 : Colors.grey,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        type: BottomNavigationBarType.fixed,
        // 5 items → 5 pages, perfectly aligned
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: tr.get('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: tr.get('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: tr.get('chat'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: tr.get('messaging'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: tr.get('settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: tr.get('profile'),
          ),
        ],
      ),
    );
  }
}
