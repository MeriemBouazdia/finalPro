import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/widget/theme_provider.dart';
import 'package:app/l10n/translations.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openWhatsApp(BuildContext context) async {
  const phone = '[0656977376]';
  const message = 'Hello, I need help with the Smart Greenhouse application.';
  final uri =
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.of(context).get('whatsappError')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

Future<void> sendEmail(BuildContext context) async {
  const email = '[bouazdiameriem9@gmail.com]';
  const subject = 'Smart Greenhouse Support';
  const body =
      'Hello Support Team,\n\nI need assistance with the Smart Greenhouse application.\n\nThank you.';
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    query:
        'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.of(context).get('emailError')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
//  COLOR HELPER
// ─────────────────────────────────────────────

class _C {
  final bool isDark;
  const _C(this.isDark);

  Color get deepGreen => const Color(0xFF336A29);
  Color get midGreen => const Color(0xFF336A29);
  Color get brightGreen => const Color(0xFF43A047);
  Color get lightGreen => const Color(0xFFA5D6A7);

  Color get mintBg =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get cardBg => isDark ? const Color(0xFF2C2C2C) : Colors.white;

  Color get textDark => isDark ? Colors.white : const Color(0xFF1A2E1A);
  Color get textMid => isDark ? Colors.white70 : const Color(0xFF4A6741);
  Color get textSoft => isDark ? Colors.white54 : const Color(0xFF7A9B77);

  Color get faqDivider =>
      isDark ? const Color(0xFF3A3A3A) : lightGreen.withOpacity(0.3);
  Color get faqIconBg =>
      isDark ? const Color(0xFF3A3A3A) : lightGreen.withOpacity(0.4);

  Color get cardShadow =>
      isDark ? Colors.black45 : const Color(0xFF336A29).withOpacity(0.08);
  Color get tipGradientStart =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8F5E9);
  Color get tipGradientEnd =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFC8E6C9);
  Color get tipBorder =>
      isDark ? const Color(0xFF3A3A3A) : lightGreen.withOpacity(0.6);
  Color get sectionIconBg =>
      isDark ? const Color(0xFF3A3A3A) : lightGreen.withOpacity(0.5);
  Color get divider =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
}

// ─────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _C(isDark);

    return Scaffold(
      backgroundColor: c.mintBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              tr.get('helpSupport'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFF336A29),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: Colors.white.withOpacity(isDark ? 0.08 : 0.18)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeroBanner(c: c)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _SectionLabel(
                icon: Icons.bolt_rounded, label: tr.get('quickHelp'), c: c),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: _QuickHelpGrid(c: c)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _SectionLabel(
                icon: Icons.help_outline_rounded,
                label: tr.get('faqTitle'),
                c: c),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: _FaqSection(c: c)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: _SectionLabel(
                icon: Icons.support_agent_rounded,
                label: tr.get('contactSupport'),
                c: c),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: _ContactSection(c: c)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(child: _TipCard(c: c)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HERO BANNER
// ─────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final _C c;
  const _HeroBanner({required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFF336A29), const Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF336A29).withOpacity(c.isDark ? 0.15 : 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: _LeafBlob(size: 110, opacity: c.isDark ? 0.06 : 0.12),
          ),
          Positioned(
            left: -20,
            bottom: -10,
            child: _LeafBlob(size: 80, opacity: c.isDark ? 0.04 : 0.08),
          ),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.get('helpSupport'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr.get('heroBannerSubtitle'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
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

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final _C c;
  const _SectionLabel(
      {required this.icon, required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.sectionIconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c.midGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.textDark,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUICK HELP GRID
// ─────────────────────────────────────────────

class _QuickHelpGrid extends StatelessWidget {
  final _C c;
  const _QuickHelpGrid({required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);

    final items = [
      _HelpItem(
        icon: Icons.spa_rounded,
        title: tr.get('qhGettingStarted'),
        subtitle: tr.get('qhGettingStartedSub'),
        gradientStart: const Color(0xFF66BB6A),
        gradientEnd: const Color(0xFF2E7D32),
      ),
      _HelpItem(
        icon: Icons.thermostat_rounded,
        title: tr.get('qhSensorsGuide'),
        subtitle: tr.get('qhSensorsGuideSub'),
        gradientStart: const Color(0xFF26C6DA),
        gradientEnd: const Color(0xFF00838F),
      ),
      _HelpItem(
        icon: Icons.water_drop_rounded,
        title: tr.get('qhActuatorControl'),
        subtitle: tr.get('qhActuatorControlSub'),
        gradientStart: const Color(0xFF42A5F5),
        gradientEnd: const Color(0xFF1565C0),
      ),
      _HelpItem(
        icon: Icons.notifications_active_rounded,
        title: tr.get('qhNotifications'),
        subtitle: tr.get('qhNotificationsSub'),
        gradientStart: const Color(0xFFFFCA28),
        gradientEnd: const Color(0xFFE65100),
      ),
      _HelpItem(
        icon: Icons.smart_toy_rounded,
        title: tr.get('qhAiChatbot'),
        subtitle: tr.get('qhAiChatbotSub'),
        gradientStart: const Color(0xFFAB47BC),
        gradientEnd: const Color(0xFF4A148C),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _HelpCard(item: items[0], c: c)),
              const SizedBox(width: 12),
              Expanded(child: _HelpCard(item: items[1], c: c)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _HelpCard(item: items[2], c: c)),
              const SizedBox(width: 12),
              Expanded(child: _HelpCard(item: items[3], c: c)),
            ],
          ),
          const SizedBox(height: 12),
          _HelpCardWide(item: items[4], c: c),
        ],
      ),
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class _HelpCard extends StatelessWidget {
  final _HelpItem item;
  final _C c;
  const _HelpCard({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tr.get('opening')} ${item.title}…'),
              backgroundColor: c.midGreen,
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
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: c.cardShadow,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: c.textSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    tr.get('learnMore'),
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
  final _C c;
  const _HelpCardWide({required this.item, required this.c});

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

// ─────────────────────────────────────────────
//  FAQ SECTION
// ─────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final _C c;
  const _FaqSection({required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);

    final faqs = [
      _FaqItem(
        question: tr.get('faq1Q'),
        answer: tr.get('faq1A'),
      ),
      _FaqItem(
        question: tr.get('faq2Q'),
        answer: tr.get('faq2A'),
      ),
      _FaqItem(
        question: tr.get('faq3Q'),
        answer: tr.get('faq3A'),
      ),
      _FaqItem(
        question: tr.get('faq4Q'),
        answer: tr.get('faq4A'),
      ),
      _FaqItem(
        question: tr.get('faq5Q'),
        answer: tr.get('faq5A'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: c.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: List.generate(faqs.length, (i) {
              final isLast = i == faqs.length - 1;
              return Column(
                children: [
                  _FaqTile(item: faqs[i], c: c),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: c.faqDivider,
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
  final _C c;
  const _FaqTile({required this.item, required this.c});

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
        vsync: this, duration: const Duration(milliseconds: 280));
    _rotate = Tween<double>(begin: 0, end: 0.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
    final c = widget.c;
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
                    color: _expanded ? c.midGreen : c.faqIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: _expanded ? Colors.white : c.midGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _expanded ? c.midGreen : c.textDark,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RotationTransition(
                  turns: _rotate,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _expanded ? c.midGreen : c.textSoft,
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
                    style: TextStyle(
                      fontSize: 13.5,
                      color: c.textMid,
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

// ─────────────────────────────────────────────
//  CONTACT SECTION
// ─────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  final _C c;
  const _ContactSection({required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: c.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.get('stillNeedHelp'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: c.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr.get('supportAvailability'),
                        style: TextStyle(
                          fontSize: 13,
                          color: c.textSoft,
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
                    gradient: LinearGradient(
                      colors: [c.lightGreen, c.brightGreen],
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
            _ContactButton(
              icon: Icons.email_outlined,
              label: tr.get('contactSupportBtn'),
              isPrimary: true,
              c: c,
              onTap: () => sendEmail(context),
            ),
            const SizedBox(height: 10),
            _ContactButton(
              icon: Icons.bug_report_outlined,
              label: tr.get('reportProblem'),
              isPrimary: false,
              c: c,
              onTap: () => sendEmail(context),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SmallContactLink(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: tr.get('whatsapp'),
                    color: const Color(0xFF25D366),
                    onTap: () => openWhatsApp(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallContactLink(
                    icon: Icons.mail_outline_rounded,
                    label: tr.get('emailUs'),
                    color: c.brightGreen,
                    onTap: () => sendEmail(context),
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
  final _C c;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.c,
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
              label: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.midGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.midGreen,
                side: BorderSide(color: c.midGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
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

// ─────────────────────────────────────────────
//  TIP CARD
// ─────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final _C c;
  const _TipCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.tipGradientStart, c.tipGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.tipBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.midGreen.withOpacity(0.12),
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
                children: [
                  Text(
                    tr.get('farmersTip'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.brightGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr.get('farmersTipBody'),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMid,
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
