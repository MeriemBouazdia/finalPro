import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/greenhouse_chat_service.dart';
import '../pages/widget/theme_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class CropItem {
  final String id;
  final String name;

  const CropItem({required this.id, required this.name});

  factory CropItem.fromJson(Map<String, dynamic> j) =>
      CropItem(id: j['id'] as String, name: j['name'] as String);
}

// ─────────────────────────────────────────────
//  API
// ─────────────────────────────────────────────

class AgriApiService {
  static const _timeout = Duration(seconds: 10);
  static const List<String> _hosts = [
    'http://192.168.1.5:5000',
    'http://192.168.1.1:5000',
  ];

  static Future<http.Response?> _tryHosts(
    Future<http.Response> Function(String baseUrl) builder,
  ) async {
    for (final host in _hosts) {
      try {
        final resp = await builder(host).timeout(_timeout);
        if (resp.statusCode < 500) return resp;
      } catch (_) {}
    }
    return null;
  }

  static Future<Map<String, dynamic>?> ask(String question, String lang) async {
    final resp = await _tryHosts(
      (base) => http.post(
        Uri.parse('$base/api/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question, 'language': lang}),
      ),
    );
    if (resp == null || resp.statusCode != 200) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<List<CropItem>> fetchCrops(String lang) async {
    final resp = await _tryHosts(
      (base) => http.get(Uri.parse('$base/api/crops?lang=$lang')),
    );
    if (resp == null || resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body);
    return (data['crops'] as List).map((c) => CropItem.fromJson(c)).toList();
  }

  static Future<Map<String, dynamic>?> fetchCropDetail(
      String cropId, String lang) async {
    final resp = await _tryHosts(
      (base) => http.get(Uri.parse('$base/api/crop/$cropId?lang=$lang')),
    );
    if (resp == null || resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body);
    return data['data'] as Map<String, dynamic>;
  }
}

// ─────────────────────────────────────────────
//  LOCALISED STRINGS
// ─────────────────────────────────────────────

class _Strings {
  static const Map<String, Map<String, String>> _t = {
    'appTitle': {
      'en': 'Crop AI Bot',
      'fr': 'Bot IA Cultures',
      'ar': 'روبوت الحصاد الذكي',
    },
    'hintText': {
      'en': 'Ask about crops...',
      'fr': 'Posez des questions...',
      'ar': 'اسأل عن المحاصيل...',
    },
    'langLabel': {
      'en': 'Language: English',
      'fr': 'Langue: Français',
      'ar': 'اللغة: العربية',
    },
    'viewCrops': {
      'en': 'View Crops',
      'fr': 'Afficher cultures',
      'ar': 'عرض المحاصيل',
    },
    'availCrops': {
      'en': 'Available Crops',
      'fr': 'Cultures disponibles',
      'ar': 'المحاصيل المتاحة',
    },
    'loading': {
      'en': 'Loading...',
      'fr': 'Chargement...',
      'ar': 'جاري التحميل...',
    },
    'serverError': {
      'en': 'Could not reach server. Check your connection.',
      'fr': 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      'ar': 'تعذر الوصول إلى الخادم. تحقق من اتصالك.',
    },
    'welcome': {
      'en':
          'I am your smart agriculture assistant 🌱 Ask me about crops, soil, humidity, irrigation or plant diseases.',
      'fr':
          "Je suis votre assistant agricole intelligent 🌱 Demandez-moi à propos des cultures, du sol, de l'humidité ou des maladies.",
      'ar':
          'أنا مساعدك الزراعي الذكي 🌱 اسألني عن المحاصيل أو التربة أو الرطوبة أو الري أو أمراض النبات.',
    },
    'cropDetail': {
      'en': 'CROP DETAILS',
      'fr': 'DÉTAILS DE LA CULTURE',
      'ar': 'تفاصيل المحصول',
    },
    'close': {'en': 'Close', 'fr': 'Fermer', 'ar': 'إغلاق'},
    'noInfo': {
      'en': 'Could not fetch crop information.',
      'fr': 'Impossible de récupérer les informations.',
      'ar': 'لم أتمكن من الحصول على معلومات المحصول.',
    },
  };

  static String get(String key, String lang) =>
      _t[key]?[lang] ?? _t[key]?['en'] ?? key;
}

class _AppTokens {
  final bool isDark;

  const _AppTokens({required this.isDark});

  // ── Brand greens — mirrors HomePage palette ──
  Color get primary => const Color(0xFF336A29);
  Color get primaryLight =>
      isDark ? const Color(0xFF81C995) : const Color(0xFF4CAF7A);
  Color get primaryContainer =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD8F3DC);

  // ── Surfaces — mirrors HomePage palette ──
  Color get scaffold =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get surface => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get surfaceVariant =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFECF7EF);
  Color get cardShadow =>
      isDark ? Colors.black45 : const Color(0xFF336A29).withOpacity(0.10);

  Color get onSurface => isDark ? Colors.white : Colors.black87;
  Color get onSurfaceMuted => isDark ? Colors.white70 : const Color(0xFF5A7A66);

  // ── Chat bubbles ──
  Color get userBubble => const Color(0xFF336A29);
  Color get botBubble => isDark ? const Color(0xFF2C2C2C) : Colors.white;
  Color get userBubbleText => Colors.white;
  Color get botBubbleText => isDark ? Colors.white : const Color(0xFF1B3A28);

  // ── Input ──
  Color get inputFill =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0FAF3);
  Color get inputBorder =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFB2DFDB);
  Color get inputBorderFocused => const Color(0xFF336A29);

  // ── Misc ──
  Color get divider =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0EAD9);
  Color get bannerBg =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8F5E9);
  Color get chipBg =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD8F3DC);
  Color get chipText => isDark ? Colors.white70 : const Color(0xFF1B5E20);
  Color get appBarBg =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFF336A29);
}

class CropDetailPage extends StatelessWidget {
  final Map<String, dynamic> crop;
  final String lang;

  const CropDetailPage({super.key, required this.crop, required this.lang});

  static const _fieldLabels = {
    'en': {
      'crop': 'Crop',
      'type': 'Type',
      'growing_period': 'Growing Period',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'water_needs': 'Water Needs',
      'soil_type': 'Soil Type',
      'ph_level': 'pH Level',
      'sunlight': 'Sunlight',
      'harvesting': 'Harvesting',
      'benefits': 'Benefits',
      'tips': 'Tips',
    },
    'fr': {
      'crop': 'Culture',
      'type': 'Type',
      'growing_period': 'Période de croissance',
      'temperature': 'Température',
      'humidity': 'Humidité',
      'water_needs': 'Besoins en eau',
      'soil_type': 'Type de sol',
      'ph_level': 'Niveau pH',
      'sunlight': 'Lumière du soleil',
      'harvesting': 'Récolte',
      'benefits': 'Avantages',
      'tips': 'Conseils',
    },
    'ar': {
      'crop': 'المحصول',
      'type': 'النوع',
      'growing_period': 'فترة النمو',
      'temperature': 'درجة الحرارة',
      'humidity': 'الرطوبة',
      'water_needs': 'احتياجات المياه',
      'soil_type': 'نوع التربة',
      'ph_level': 'مستوى pH',
      'sunlight': 'أشعة الشمس',
      'harvesting': 'الحصاد',
      'benefits': 'الفوائد',
      'tips': 'نصائح',
    },
  };

  static const _fieldOrder = [
    'crop',
    'type',
    'growing_period',
    'temperature',
    'humidity',
    'water_needs',
    'soil_type',
    'ph_level',
    'sunlight',
    'harvesting',
    'benefits',
    'tips',
  ];

  static const _fieldIcons = {
    'crop': Icons.eco,
    'type': Icons.category,
    'growing_period': Icons.calendar_today,
    'temperature': Icons.thermostat,
    'humidity': Icons.water_drop,
    'water_needs': Icons.opacity,
    'soil_type': Icons.layers,
    'ph_level': Icons.science,
    'sunlight': Icons.wb_sunny,
    'harvesting': Icons.agriculture,
    'benefits': Icons.favorite,
    'tips': Icons.lightbulb,
  };

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final t = _AppTokens(isDark: themeProvider.isDarkMode);
    final labels = _fieldLabels[lang] ?? _fieldLabels['en']!;
    final isRtl = lang == 'ar';

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: AppBar(
        backgroundColor: t.appBarBg,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _Strings.get('cropDetail', lang),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: _fieldOrder
              .where((key) => crop.containsKey(key))
              .map((key) => _InfoCard(
                    icon: _fieldIcons[key] ?? Icons.info,
                    label: labels[key] ?? key,
                    value: crop[key]?.toString() ?? '',
                    tokens: t,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _AppTokens tokens;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: t.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: t.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.onSurfaceMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: t.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOT PAGE
// ─────────────────────────────────────────────

class BotPage extends StatefulWidget {
  final String greenhouseId;

  const BotPage({super.key, required this.greenhouseId});

  @override
  State<BotPage> createState() => _BotPageState();
}

class _BotPageState extends State<BotPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  List<CropItem> _crops = [];
  bool _isLoading = false;
  bool _isLoadingMessages = true;
  String _lang = 'en';

  final _chatService = GreenhouseChatService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadMessagesFromFirebase();
    if (_messages.isEmpty) _addWelcomeMessage();
    _loadCrops();
    setState(() => _isLoadingMessages = false);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessagesFromFirebase() async {
    try {
      final firebaseMessages =
          await _chatService.getConversations(widget.greenhouseId);
      setState(() {
        _messages.clear();
        for (var msg in firebaseMessages) {
          _messages.add(ChatMessage(
            text: msg.text,
            isUser: msg.sender == 'user',
            timestamp: msg.timestamp,
          ));
        }
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      debugPrint('Error loading messages from Firebase: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMsg = ChatMessage(
      text: _Strings.get('welcome', _lang),
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(welcomeMsg));
    _saveToFirebase(welcomeMsg.text, 'bot');
  }

  void _addMessage(String text, {required bool isUser}) {
    final newMsg = ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(newMsg));
    _saveToFirebase(text, isUser ? 'user' : 'bot');
    Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
  }

  Future<void> _saveToFirebase(String text, String sender) async {
    try {
      await _chatService.saveMessage(widget.greenhouseId, text, sender);
    } catch (e) {
      debugPrint('Error saving message to Firebase: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadCrops() async {
    final crops = await AgriApiService.fetchCrops(_lang);
    if (mounted) setState(() => _crops = crops);
  }

  Future<void> _sendMessage(String text) async {
    final q = text.trim();
    if (q.isEmpty || _isLoading) return;
    _inputController.clear();
    _addMessage(q, isUser: true);
    setState(() => _isLoading = true);

    final result = await AgriApiService.ask(q, _lang);
    setState(() => _isLoading = false);

    _addMessage(
      result != null
          ? result['answer'] as String
          : _Strings.get('serverError', _lang),
      isUser: false,
    );
  }

  Future<void> _showCropDetail(CropItem crop) async {
    final detail = await AgriApiService.fetchCropDetail(crop.id, _lang);
    if (!mounted) return;
    if (detail != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              CropDetailPage(crop: detail, lang: _lang),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
        ),
      );
    } else {
      _addMessage(_Strings.get('noInfo', _lang), isUser: false);
    }
  }

  void _showCropsModal(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final t = _AppTokens(isDark: themeProvider.isDarkMode);

    showModalBottomSheet(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: t.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_florist_rounded,
                    color: t.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                _Strings.get('availCrops', _lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: t.onSurface,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            if (_crops.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: t.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _Strings.get('loading', _lang),
                      style: TextStyle(color: t.onSurfaceMuted),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _crops.map((c) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showCropDetail(c);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.chipBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, size: 14, color: t.primary),
                          const SizedBox(width: 5),
                          Text(
                            c.name,
                            style: TextStyle(
                              color: t.chipText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String lang) {
    setState(() {
      _lang = lang;
      _messages.clear();
    });
    _addWelcomeMessage();
    _loadCrops();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final t = _AppTokens(isDark: themeProvider.isDarkMode);
    final isRtl = _lang == 'ar';

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: _buildAppBar(context, t),
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: _isLoadingMessages
            ? _buildLoading(t)
            : Column(
                children: [
                  _LanguageBanner(lang: _lang, tokens: t),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (_isLoading && i == _messages.length) {
                          return _TypingIndicator(tokens: t);
                        }
                        return _MessageBubble(
                          message: _messages[i],
                          lang: _lang,
                          tokens: t,
                        );
                      },
                    ),
                  ),
                  _InputBar(
                    controller: _inputController,
                    isLoading: _isLoading,
                    lang: _lang,
                    tokens: t,
                    onSend: _sendMessage,
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, _AppTokens t) {
    return AppBar(
      backgroundColor: t.appBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🌾', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Text(
            _Strings.get('appTitle', _lang),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.language_rounded, color: Colors.white),
          color: t.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: _changeLanguage,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'en',
              child:
                  Text('🇬🇧  English', style: TextStyle(color: t.onSurface)),
            ),
            PopupMenuItem(
              value: 'ar',
              child:
                  Text('🇸🇦  العربية', style: TextStyle(color: t.onSurface)),
            ),
            PopupMenuItem(
              value: 'fr',
              child:
                  Text('🇫🇷  Français', style: TextStyle(color: t.onSurface)),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.local_florist_rounded, color: Colors.white),
          tooltip: _Strings.get('viewCrops', _lang),
          onPressed: () => _showCropsModal(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildLoading(_AppTokens t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3, color: t.primary),
          ),
          const SizedBox(height: 14),
          Text(
            _Strings.get('loading', _lang),
            style: TextStyle(color: t.onSurfaceMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LANGUAGE BANNER
// ─────────────────────────────────────────────

class _LanguageBanner extends StatelessWidget {
  final String lang;
  final _AppTokens tokens;

  const _LanguageBanner({required this.lang, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: t.bannerBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: t.primary),
          const SizedBox(width: 6),
          Text(
            _Strings.get('langLabel', lang),
            style: TextStyle(
              fontSize: 12,
              color: t.onSurfaceMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String lang;
  final _AppTokens tokens;

  const _MessageBubble({
    required this.message,
    required this.lang,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final isUser = message.isUser;
    final isRtl = lang == 'ar';
    final align = isUser
        ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
        : (isRtl ? Alignment.centerRight : Alignment.centerLeft);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? t.userBubble : t.botBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isUser ? null : Border.all(color: t.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: t.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? t.userBubbleText : t.botBubbleText,
            fontSize: 14.5,
            height: 1.45,
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TYPING INDICATOR
// ─────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final _AppTokens tokens;

  const _TypingIndicator({required this.tokens});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: t.botBubble,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.divider),
          boxShadow: [
            BoxShadow(
              color: t.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [0, 1, 2]
              .map((i) => _AnimatedDot(
                    animation: _anim,
                    delay: i * 0.15,
                    color: t.primary,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Color color;

  const _AnimatedDot({
    required this.animation,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final phase = ((animation.value - delay) % 1.0).clamp(0.0, 1.0);
        final scale = 0.6 + (phase * 0.4);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            color: color.withOpacity(0.4 + phase * 0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  INPUT BAR
// ─────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String lang;
  final _AppTokens tokens;
  final void Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.lang,
    required this.tokens,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final isRtl = lang == 'ar';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.divider, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: t.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : onSend,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  color: t.onSurface,
                  fontSize: 14.5,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _Strings.get('hintText', lang),
                  hintTextDirection:
                      isRtl ? TextDirection.rtl : TextDirection.ltr,
                  hintStyle: TextStyle(color: t.onSurfaceMuted, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: t.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: t.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        BorderSide(color: t.inputBorderFocused, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  filled: true,
                  fillColor: t.inputFill,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                heroTag: 'send_btn',
                onPressed: isLoading ? null : () => onSend(controller.text),
                backgroundColor:
                    isLoading ? t.onSurfaceMuted.withOpacity(0.5) : t.primary,
                mini: true,
                elevation: isLoading ? 0 : 3,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
