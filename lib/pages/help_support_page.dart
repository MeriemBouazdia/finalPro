import 'package:flutter/material.dart';

void main() => runApp(const _Preview());

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
        ),
        home: const HelpSupportPage(),
      );
}

class _C {
  static const deepGreen = Color(0xFF1B5E20);
  static const midGreen = Color(0xFF2E7D32);
  static const brightGreen = Color(0xFF43A047);
  static const lightGreen = Color(0xFFA5D6A7);
  static const mintBg = Color(0xFFF1F8F1);
  static const cardBg = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A2E1A);
  static const textMid = Color(0xFF4A6741);
  static const textSoft = Color(0xFF7A9B77);
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.mintBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Header()),

          // ── 2. Quick Help Cards ──────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _SectionLabel(
              icon: Icons.bolt_rounded,
              label: 'Quick Help',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          const SliverToBoxAdapter(child: _QuickHelpGrid()),

          // ── 3. FAQ ───────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _SectionLabel(
              icon: Icons.help_outline_rounded,
              label: 'Frequently Asked Questions',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          const SliverToBoxAdapter(child: _FaqSection()),

          // ── 4. Contact Support ───────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _SectionLabel(
              icon: Icons.support_agent_rounded,
              label: 'Contact Support',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          const SliverToBoxAdapter(child: _ContactSection()),

          // ── 5. Tip card ──────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          const SliverToBoxAdapter(child: _TipCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── 1. Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, top + 16, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.deepGreen, _C.brightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative leaf blobs
          Positioned(
            right: -20,
            top: -10,
            child: _LeafBlob(size: 120, opacity: 0.12),
          ),
          Positioned(
            left: -30,
            bottom: -20,
            child: _LeafBlob(size: 90, opacity: 0.08),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + page label
              Row(
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Help & Support',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),

              const Text(
                'Help & Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We're here to help you manage\nyour smart greenhouse",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 24),

              // Search bar (cosmetic)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _C.deepGreen.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search_rounded, color: _C.textSoft, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Search for help…',
                      style: TextStyle(color: _C.textSoft, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Decorative leaf shape
class _LeafBlob extends StatelessWidget {
  final double size;
  final double opacity;
  const _LeafBlob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.6),
            topRight: Radius.circular(size * 0.1),
            bottomLeft: Radius.circular(size * 0.1),
            bottomRight: Radius.circular(size * 0.6),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.lightGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _C.midGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Quick Help Grid ───────────────────────────────────────────────────────

class _QuickHelpGrid extends StatelessWidget {
  const _QuickHelpGrid();

  static const _items = [
    _HelpItem(
      emoji: '🌱',
      icon: Icons.spa_rounded,
      title: 'Getting Started',
      subtitle: 'Setup your greenhouse in minutes',
      route: '/help/getting-started',
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF2E7D32),
    ),
    _HelpItem(
      emoji: '🌡️',
      icon: Icons.thermostat_rounded,
      title: 'Sensors Guide',
      subtitle: 'Understand temperature, humidity & soil',
      route: '/help/sensors',
      gradientStart: Color(0xFF26C6DA),
      gradientEnd: Color(0xFF00838F),
    ),
    _HelpItem(
      emoji: '🚰',
      icon: Icons.water_drop_rounded,
      title: 'Actuator Control',
      subtitle: 'Pump, fan & vent management',
      route: '/help/actuators',
      gradientStart: Color(0xFF42A5F5),
      gradientEnd: Color(0xFF1565C0),
    ),
    _HelpItem(
      emoji: '🔔',
      icon: Icons.notifications_active_rounded,
      title: 'Notifications',
      subtitle: 'Alerts and smart triggers',
      route: '/help/notifications',
      gradientStart: Color(0xFFFFCA28),
      gradientEnd: Color(0xFFE65100),
    ),
    _HelpItem(
      emoji: '🤖',
      icon: Icons.smart_toy_rounded,
      title: 'AI Chatbot Help',
      subtitle: 'Let AI guide your farming decisions',
      route: '/help/chatbot',
      gradientStart: Color(0xFFAB47BC),
      gradientEnd: Color(0xFF4A148C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // First row: 2 cards
          Row(
            children: [
              Expanded(child: _HelpCard(item: _items[0])),
              const SizedBox(width: 12),
              Expanded(child: _HelpCard(item: _items[1])),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: 2 cards
          Row(
            children: [
              Expanded(child: _HelpCard(item: _items[2])),
              const SizedBox(width: 12),
              Expanded(child: _HelpCard(item: _items[3])),
            ],
          ),
          const SizedBox(height: 12),
          // Last card: full width
          _HelpCardWide(item: _items[4]),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String emoji;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color gradientStart;
  final Color gradientEnd;
  const _HelpItem({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class _HelpCard extends StatelessWidget {
  final _HelpItem item;
  const _HelpCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigator.pushNamed(context, item.route);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${item.title}…'),
              backgroundColor: _C.midGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: item.gradientEnd.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.gradientStart, item.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _C.textSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Learn more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.gradientEnd,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 9, color: item.gradientEnd),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCardWide extends StatelessWidget {
  final _HelpItem item;
  const _HelpCardWide({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [item.gradientStart, item.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: item.gradientEnd.withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.82),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3. FAQ Section ───────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const _faqs = [
    _FaqItem(
      question: 'How do sensors work?',
      answer:
          'Your greenhouse sensors measure temperature, humidity, soil moisture, and light in real-time. They send readings to the app every few seconds via Wi-Fi. If a reading crosses the target threshold, the app alerts you instantly.',
    ),
    _FaqItem(
      question: 'How do I set target values?',
      answer:
          'Go to the Configuration page and enter your desired temperature and soil moisture targets. The system will automatically compare live sensor data against these values and trigger alerts or automatic actions when thresholds are exceeded.',
    ),
    _FaqItem(
      question: 'Why am I receiving alerts?',
      answer:
          'Alerts fire when a sensor reading goes above your configured target. For example, if temperature exceeds your target, you\'ll get a "🌡️ High Temperature Alert". Check your targets in the Configuration page if alerts feel too frequent.',
    ),
    _FaqItem(
      question: 'How to control pump/fan manually or automatically?',
      answer:
          'On the Home page, use the Device Control section. Toggle the mode switch to "Manual" to control each device (pump, fan, vent, light) yourself. Switch to "Automatic" and the system controls them based on your sensor targets.',
    ),
    _FaqItem(
      question: 'How does the AI chatbot help farmers?',
      answer:
          'The AI chatbot gives personalized advice based on your greenhouse data. Ask it anything — from crop care tips to interpreting sensor readings. It learns your greenhouse\'s patterns over time to give increasingly relevant suggestions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _C.midGreen.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: List.generate(_faqs.length, (i) {
              final isLast = i == _faqs.length - 1;
              return Column(
                children: [
                  _FaqTile(item: _faqs[i]),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _C.lightGreen.withOpacity(0.3),
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? _C.midGreen
                        : _C.lightGreen.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: _expanded ? Colors.white : _C.midGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _expanded ? _C.midGreen : _C.textDark,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RotationTransition(
                  turns: _rotate,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _expanded ? _C.midGreen : _C.textSoft,
                    size: 22,
                  ),
                ),
              ],
            ),
            FadeTransition(
              opacity: _fade,
              child: SizeTransition(
                sizeFactor: _fade,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 40),
                  child: Text(
                    widget.item.answer,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _C.textMid,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 4. Contact Support ───────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _C.midGreen.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Illustration row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Still need help?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Our support team is\navailable 7 days a week.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _C.textSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.lightGreen, _C.brightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons
            _ContactButton(
              icon: Icons.email_outlined,
              label: 'Contact Support',
              isPrimary: true,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _ContactButton(
              icon: Icons.bug_report_outlined,
              label: 'Report a Problem',
              isPrimary: false,
              onTap: () {},
            ),
            const SizedBox(height: 10),

            // Secondary links row
            Row(
              children: [
                Expanded(
                  child: _SmallContactLink(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallContactLink(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Us',
                    color: _C.brightGreen,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.midGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.midGreen,
                side: const BorderSide(color: _C.midGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
    );
  }
}

class _SmallContactLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallContactLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 5. Tip Card ─────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.lightGreen.withOpacity(0.6), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _C.midGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🌿',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, height: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Farmer\'s Tip',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.brightGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep your soil balanced for healthier crops — consistent moisture prevents root stress and boosts yield 🌾',
                    style: TextStyle(
                      fontSize: 13,
                      color: _C.textMid,
                      height: 1.5,
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
