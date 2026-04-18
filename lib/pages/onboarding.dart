import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../translations.dart';
import 'widget/locale_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _primaryGreen = Color(0xFF2D6A22);
  static const _lightGreen = Color(0xFFEAF4E7);
  static const _accentGreen = Color(0xFF4CAF50);

  final List<OnboardingPage> _pages = [];

  @override
  void initState() {
    super.initState();
    _initializePages();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializePages() {
    _pages.addAll([
      OnboardingPage(
        imagePath: 'assets/logo1.png',
        titleKey: 'onboardingWelcomeTitle',
        descriptionKey: 'onboardingWelcomeDesc',
        accentColor: const Color(0xFF2D6A22),
        bgColor: const Color(0xFFEAF4E7),
      ),
      OnboardingPage(
        imagePath: 'assets/logo2.png',
        titleKey: 'onboardingMonitorTitle',
        descriptionKey: 'onboardingMonitorDesc',
        accentColor: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F0FF),
      ),
      OnboardingPage(
        imagePath: 'assets/logo3.png',
        titleKey: 'onboardingControlTitle',
        descriptionKey: 'onboardingControlDesc',
        accentColor: const Color(0xFF6A1E2D),
        bgColor: const Color(0xFFF4EAE7),
      ),
    ]);
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() => _completeOnboarding();

  void _changeLanguage(String code) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    localeProvider.setLocaleByCode(code);
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = Translations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLang = localeProvider.locale.languageCode;
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              page.bgColor,
              Colors.white,
            ],
            stops: const [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(translations, currentLang),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], translations);
                  },
                ),
              ),
              _buildBottomSection(translations, page),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Translations translations, String currentLang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _skip,
            child: Text(
              translations.get('skip'),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          _buildLanguagePicker(currentLang),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker(String currentLang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langChip('EN', 'en', currentLang),
          _langChip('FR', 'fr', currentLang),
          _langChip('AR', 'ar', currentLang),
        ],
      ),
    );
  }

  Widget _langChip(String label, String code, String currentLang) {
    final isSelected = currentLang == code;
    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, Translations translations) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImageCard(page),
              const SizedBox(height: 52),
              Text(
                translations.get(page.titleKey),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                translations.get(page.descriptionKey),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                  height: 1.6,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(OnboardingPage page) {
    return Container(
      width: 280,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: page.accentColor.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Image.asset(
            page.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: page.accentColor.withOpacity(0.3),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(Translations translations, OnboardingPage page) {
    final isLast = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
      child: Column(
        children: [
          _buildIndicators(page),
          const SizedBox(height: 32),
          _buildNextButton(translations, isLast, page),
        ],
      ),
    );
  }

  Widget _buildIndicators(OnboardingPage page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? page.accentColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton(
      Translations translations, bool isLast, OnboardingPage page) {
    return GestureDetector(
      onTap: _nextPage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              page.accentColor,
              page.accentColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: page.accentColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast
                  ? translations.get('getStarted')
                  : translations.get('next'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String imagePath;
  final String titleKey;
  final String descriptionKey;
  final Color accentColor;
  final Color bgColor;

  OnboardingPage({
    required this.imagePath,
    required this.titleKey,
    required this.descriptionKey,
    required this.accentColor,
    required this.bgColor,
  });
}
