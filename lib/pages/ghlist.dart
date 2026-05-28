import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import 'package:app/l10n/translations.dart';
import '../pages/widget/theme_provider.dart';

class _GHColors {
  final bool isDark;
  const _GHColors(this.isDark);

  // Backgrounds mirrors HomePage palette
  Color get scaffold =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get card => isDark ? const Color(0xFF2C2C2C) : Colors.white;
  Color get cardAlt =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F8F1);
  Color get surface =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
  Color get dialog => isDark ? const Color(0xFF2C2C2C) : Colors.white;

  // Borders
  Color get border => isDark
      ? const Color(0xFF3A3A3A)
      : const Color(0xFF336A29).withOpacity(0.18);
  Color get borderSubtle =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDE8DC);

  // Text
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1B2D1A);
  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF336A29);
  Color get textMuted => isDark ? Colors.white54 : Colors.grey.shade500;
  Color get textHint => isDark ? Colors.white30 : Colors.grey.shade400;

  // Brand greens — mirrors HomePage primary
  Color get primary => const Color(0xFF336A29);
  Color get primaryLight => isDark ? Colors.white70 : const Color(0xFF388E3C);
  Color get accent => const Color(0xFF43A047);
  Color get iconBg => isDark
      ? const Color(0xFF336A29).withOpacity(0.30)
      : const Color(0xFF336A29).withOpacity(0.08);
  Color get fab1 => const Color(0xFF336A29);
  Color get fab2 => const Color(0xFF43A047);

  // Shadows
  Color get shadow => isDark
      ? Colors.black.withOpacity(0.45)
      : const Color(0xFF336A29).withOpacity(0.08);
  Color get headerShadow => const Color(0xFF336A29).withOpacity(0.27);

  // Orbs
  Color get orb1 => isDark
      ? const Color(0xFF336A29).withOpacity(0.18)
      : const Color(0xFF336A29).withOpacity(0.10);
  Color get orb2 => isDark
      ? const Color(0xFF1E1E1E).withOpacity(0.60)
      : const Color(0xFF81C784).withOpacity(0.10);

  // Danger
  Color get danger => const Color(0xFFE53935);
  Color get dangerSurface =>
      isDark ? const Color(0xFF3B1111) : const Color(0xFFFFEBEE);

  // Input field
  Color get inputFill =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
  Color get inputBorder =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDE8DC);
  Color get inputFocused => const Color(0xFF336A29);
  Color get inputLabel => isDark ? Colors.white70 : const Color(0xFF336A29);
}

//Animated page route matches project transitions
PageRoute<T> _fadeSlideRoute<T>({required WidgetBuilder builder}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

//Page
class GHListPage extends StatelessWidget {
  const GHListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isRtl = tr.isRtl;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _GHColors(isDark);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: c.scaffold,
        body: Center(
          child: Text(
            tr.get('pleaseLoginFirst'),
            style: TextStyle(color: c.textPrimary),
          ),
        ),
      );
    }

    final DatabaseReference ghRef =
        FirebaseDatabase.instance.ref("users/${user.uid}/greenhouses");

    return Scaffold(
      backgroundColor: c.scaffold,
      body: Stack(
        children: [
          // ── Decorative orbs ──
          Positioned(
            top: -60,
            right: -60,
            child: _OrbDecoration(size: 220, color: c.orb1),
          ),
          Positioned(
            top: 80,
            left: -40,
            child: _OrbDecoration(size: 140, color: c.orb2),
          ),
          Positioned(
            bottom: -80,
            right: -30,
            child: _OrbDecoration(size: 180, color: c.orb2),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(c: c, tr: tr, ghRef: ghRef, isDark: isDark),
                Expanded(
                  child: _GreenhouseList(
                    ghRef: ghRef,
                    tr: tr,
                    isRtl: isRtl,
                    c: c,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _ModernFAB(
        c: c,
        onPressed: () => _showCreateGreenhouseDialog(context, ghRef, tr, c),
      ),
    );
  }
}

//Orb decoration
class _OrbDecoration extends StatelessWidget {
  final double size;
  final Color color;
  const _OrbDecoration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

//Header
class _Header extends StatelessWidget {
  final _GHColors c;
  final Translations tr;
  final DatabaseReference ghRef;
  final bool isDark;
  const _Header({
    required this.c,
    required this.tr,
    required this.ghRef,
    required this.isDark,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFF336A29), const Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: c.headerShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo chip
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 22),
              ),
              const Spacer(),
              // Theme toggle pill
              GestureDetector(
                onTap: () => context.read<ThemeProvider>().toggleDarkMode(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.wb_sunny_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            tr.get('myGreenhouses'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr.get('manageYourGardens'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

//Greenhouse list
class _GreenhouseList extends StatelessWidget {
  final DatabaseReference ghRef;
  final Translations tr;
  final bool isRtl;
  final _GHColors c;

  const _GreenhouseList({
    required this.ghRef,
    required this.tr,
    required this.isRtl,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: ghRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: c.primaryLight,
              strokeWidth: 2.5,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return _EmptyState(
            tr: tr,
            c: c,
            onAdd: () => _showCreateGreenhouseDialog(context, ghRef, tr, c),
          );
        }

        final data =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final ghList = data.entries.toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: ghList.length,
          itemBuilder: (context, index) {
            final ghId = ghList[index].key;
            final ghData = Map<String, dynamic>.from(ghList[index].value);
            final name = ghData["name"]?.toString() ?? tr.get('greenhouse');
            final plant = ghData["plant"]?.toString() ?? "";

            return _AnimatedCard(
              index: index,
              child: Dismissible(
                key: Key(ghId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, name, tr, c),
                onDismissed: (_) async {
                  await ghRef.child(ghId).remove();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '"$name" ${tr.get('deleted')}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                background: _DeleteBackground(),
                child: _GreenhouseCard(
                  name: name,
                  plant: plant,
                  isRtl: isRtl,
                  c: c,
                  onTap: () => Navigator.push(
                    context,
                    _fadeSlideRoute(
                      builder: (_) => MainScreen(ghId: ghId),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Greenhouse card
class _GreenhouseCard extends StatelessWidget {
  final String name;
  final String plant;
  final bool isRtl;
  final _GHColors c;
  final VoidCallback onTap;

  const _GreenhouseCard({
    required this.name,
    required this.plant,
    required this.isRtl,
    required this.c,
    required this.onTap,
  });

  List<Color> get _cardGradient {
    final g = [
      [c.cardAlt, c.card],
      [c.card, c.cardAlt],
      [c.cardAlt, c.surface],
    ];
    return g[name.length % g.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon blob
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (plant.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.grass_rounded,
                              size: 13, color: c.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            plant,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: c.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Confirm delete dialog
Future<bool?> _confirmDelete(
  BuildContext context,
  String name,
  Translations tr,
  _GHColors c,
) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: c.dialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFE53935), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              tr.get('deleteGreenhouse'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '"$name"',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              tr.get('deleteGreenhouseConfirm'),
              style: TextStyle(
                fontSize: 13.5,
                color: c.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: c.borderSubtle, width: 1.5),
                      ),
                    ),
                    child: Text(
                      tr.get('cancel'),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      tr.get('delete'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

//Create greenhouse dialog
void _showCreateGreenhouseDialog(
  BuildContext context,
  DatabaseReference ghRef,
  Translations tr,
  _GHColors c,
) {
  final nameController = TextEditingController();
  final plantController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: c.dialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.add_circle_outline_rounded,
                      color: c.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.get('addNewGreenhouse'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: formKey,
              child: Column(
                children: [
                  _ModernTextField(
                    controller: nameController,
                    label: tr.get('greenhouseName'),
                    hint: tr.get('greenhouseNameHint'),
                    icon: Icons.local_florist_rounded,
                    c: c,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.get('enterName');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _ModernTextField(
                    controller: plantController,
                    label: tr.get('plantType'),
                    hint: tr.get('plantTypeHint'),
                    icon: Icons.grass_rounded,
                    c: c,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: c.borderSubtle, width: 1.5),
                      ),
                    ),
                    child: Text(
                      tr.get('cancel'),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newGhRef = ghRef.push();
                        final newGhId = newGhRef.key;

                        await newGhRef.set({
                          "name": nameController.text.trim(),
                          "plant": plantController.text.trim(),
                          "createdAt": DateTime.now().toIso8601String(),
                        });
                        await newGhRef.child("targets").set({
                          "temperature": {"min": 18, "max": 30},
                          "humidity": {"min": 40, "max": 80},
                          "soil": {"min": 30, "max": 70},
                          "light": {"min": 100, "max": 1000},
                        });
                        await newGhRef.child("actuators").set({
                          "pump": false,
                          "light": false,
                          "fan": false,
                          "vent": false,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            _fadeSlideRoute(
                              builder: (_) => MainScreen(ghId: newGhId!),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      tr.get('create'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Translations tr;
  final _GHColors c;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.tr,
    required this.c,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.cardAlt, c.card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: c.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.eco_rounded, size: 46, color: c.primaryLight),
            ),
            const SizedBox(height: 24),
            Text(
              tr.get('noGreenhousesYet'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first greenhouse.',
              style: TextStyle(fontSize: 14, color: c.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr.get('addGreenhouse')),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final _GHColors c;
  const _ModernFAB({required this.onPressed, required this.c});

  @override
  State<_ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<_ModernFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.90)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.c.fab1, widget.c.fab2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.c.primary.withOpacity(0.40),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final _GHColors c;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.c,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: c.accent, size: 20),
        labelStyle: TextStyle(color: c.inputLabel, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: c.textHint, fontSize: 13),
        filled: true,
        fillColor: c.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.inputFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF9A9A), Color(0xFFE53935)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
