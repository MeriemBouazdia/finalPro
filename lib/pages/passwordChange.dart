import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../pages/widget/theme_provider.dart';
import 'package:app/l10n/translations.dart';

class _C {
  final bool isDark;
  const _C(this.isDark);

  Color get primary => const Color(0xFF336A29);
  Color get primaryDark => const Color(0xFF1F5220);
  Color get primaryLight => const Color(0xFF43A047);
  Color get lightGreen =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEAF5EC);
  Color get borderGreen =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD6E8D9);

  Color get scaffold =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get card => isDark ? const Color(0xFF2C2C2C) : Colors.white;
  Color get fieldFill =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEAF5EC);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A2E1A);
  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF6B7B6E);
  Color get textMuted => isDark ? Colors.white54 : const Color(0xFF6B7B6E);
  Color get fieldIcon => isDark ? Colors.white54 : const Color(0xFF5FAD6E);

  Color get appBar =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFF336A29);

  List<Color> get headerGradient => isDark
      ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
      : [const Color(0xFF336A29), const Color(0xFF43A047)];

  List<Color> get buttonGradient =>
      [const Color(0xFF43A047), const Color(0xFF336A29)];

  Color get error => const Color(0xFFD94040);
  Color get errorSurface =>
      isDark ? const Color(0xFF3B1111) : const Color(0xFFFFEBEE);
  Color get success => const Color(0xFF336A29);
  Color get info => const Color(0xFF3B82F6);

  Color get blob1 => isDark
      ? const Color(0xFF336A29).withOpacity(0.15)
      : const Color(0xFFC6E5CC);
  Color get blob2 => isDark
      ? const Color(0xFF2C2C2C).withOpacity(0.60)
      : const Color(0xFFB0D9B8);

  Color get cardShadow =>
      isDark ? Colors.black45 : const Color(0xFF336A29).withOpacity(0.07);
  Color get divider =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD6E8D9);
}

// ─────────────────────────────────────────────
//  FIREBASE AUTH SERVICE
// ─────────────────────────────────────────────

class PasswordChangeResponse {
  final bool success;
  final String message;
  final String? error;
  const PasswordChangeResponse({
    required this.success,
    required this.message,
    this.error,
  });
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  Future<PasswordChangeResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const PasswordChangeResponse(
            success: false,
            message: 'Authentication failed',
            error: 'No user is currently signed in.');
      }
      if (user.email == null) {
        return const PasswordChangeResponse(
            success: false,
            message: 'Authentication failed',
            error: 'No email address is associated with this account.');
      }
      try {
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        return PasswordChangeResponse(
            success: false,
            message: 'Re-authentication failed',
            error: _mapFirebaseError(e));
      }
      try {
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        return PasswordChangeResponse(
            success: false,
            message: 'Password update failed',
            error: _mapFirebaseError(e));
      }
      return const PasswordChangeResponse(
          success: true, message: 'Password updated successfully');
    } catch (_) {
      return const PasswordChangeResponse(
          success: false,
          message: 'An unexpected error occurred',
          error: 'Something went wrong. Please try again later.');
    }
  }

  Future<PasswordChangeResponse> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const PasswordChangeResponse(
          success: true, message: 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return PasswordChangeResponse(
          success: false,
          message: 'Failed to send reset email',
          error: _mapFirebaseError(e));
    } catch (_) {
      return const PasswordChangeResponse(
          success: false,
          message: 'An unexpected error occurred',
          error: 'Something went wrong. Please try again later.');
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' => 'Current password is incorrect.',
      'invalid-credential' => 'Current password is incorrect.',
      'invalid-email' => 'Invalid email address.',
      'user-not-found' => 'No account found for this email.',
      'weak-password' => 'New password is too weak.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'operation-not-allowed' => 'Operation not allowed. Contact support.',
      'requires-recent-login' =>
        'Session expired. Please log out and sign in again.',
      'network-request-failed' =>
        'Network error. Check your internet connection.',
      _ => e.message ?? 'An authentication error occurred.',
    };
  }
}

// ─────────────────────────────────────────────
//  PASSWORD VALIDATION
// ─────────────────────────────────────────────

enum PasswordStrength { weak, fair, good, strong }

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  const ValidationResult({required this.isValid, required this.errors});
}

class PasswordValidator {
  static const int _minLength = 8;
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  static ValidationResult validate(String password) {
    if (password.isEmpty) {
      return const ValidationResult(
          isValid: false, errors: ['Password is required']);
    }
    final errors = <String>[];
    if (password.length < _minLength) errors.add('At least 8 characters');
    if (!_upper.hasMatch(password)) errors.add('One uppercase letter');
    if (!_lower.hasMatch(password)) errors.add('One lowercase letter');
    if (!_digit.hasMatch(password)) errors.add('One number');
    if (!_special.hasMatch(password)) errors.add('One special character');
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  static PasswordStrength getStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    int score = 0;
    if (password.length >= _minLength) score++;
    if (password.length >= 12) score++;
    if (_upper.hasMatch(password)) score++;
    if (_lower.hasMatch(password)) score++;
    if (_digit.hasMatch(password)) score++;
    if (_special.hasMatch(password)) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}

// ─────────────────────────────────────────────
//  PASSWORD STRENGTH INDICATOR
// ─────────────────────────────────────────────

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final PasswordStrength strength;
  final _C c;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.strength,
    required this.c,
  });

  Color _strengthColor() => switch (strength) {
        PasswordStrength.weak => const Color(0xFFD94040),
        PasswordStrength.fair => const Color(0xFFE07B27),
        PasswordStrength.good => const Color(0xFF5FAD6E),
        PasswordStrength.strong => const Color(0xFF336A29),
      };

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    if (password.isEmpty) return const SizedBox.shrink();
    final color = _strengthColor();

    final strengthLabel = switch (strength) {
      PasswordStrength.weak => tr.get('strengthWeak'),
      PasswordStrength.fair => tr.get('strengthFair'),
      PasswordStrength.good => tr.get('strengthGood'),
      PasswordStrength.strong => tr.get('strengthStrong'),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.lightGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderGreen, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tr.get('passwordStrength'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    strengthLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (strength.index + 1) / 4,
                minHeight: 6,
                backgroundColor: c.borderGreen,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            _RequirementsList(password: password, c: c),
          ],
        ),
      ),
    );
  }
}

class _RequirementsList extends StatelessWidget {
  final String password;
  final _C c;
  const _RequirementsList({required this.password, required this.c});

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final reqs = [
      (tr.get('req8Chars'), password.length >= 8),
      (tr.get('reqUppercase'), RegExp(r'[A-Z]').hasMatch(password)),
      (tr.get('reqLowercase'), RegExp(r'[a-z]').hasMatch(password)),
      (tr.get('reqNumber'), RegExp(r'[0-9]').hasMatch(password)),
      (
        tr.get('reqSpecial'),
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)
      ),
    ];
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: reqs
          .map((r) => _RequirementChip(label: r.$1, isMet: r.$2, c: c))
          .toList(),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final bool isMet;
  final _C c;
  const _RequirementChip(
      {required this.label, required this.isMet, required this.c});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isMet ? c.primary.withOpacity(0.10) : c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMet ? c.primary.withOpacity(0.35) : c.borderGreen,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: isMet ? c.primary : c.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? c.primaryDark : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _submitLocked = false;
  String? _currentPwError;
  PasswordStrength _strength = PasswordStrength.weak;

  late AnimationController _entranceController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOutCubic));
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));
    _entranceController.forward();
    _newPwController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() {
    setState(
        () => _strength = PasswordValidator.getStrength(_newPwController.text));
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    _entranceController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final tr = Translations.of(context);
    setState(() => _currentPwError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_submitLocked) return;
    FocusScope.of(context).unfocus();
    await _buttonController.forward();
    await _buttonController.reverse();
    setState(() {
      _isLoading = true;
      _submitLocked = true;
    });
    final response = await _authService.changePassword(
      currentPassword: _currentPwController.text,
      newPassword: _newPwController.text,
    );
    if (!mounted) return;
    if (response.success) {
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      setState(() {
        _isLoading = false;
        _submitLocked = false;
      });
      _showSnackBar(
        message: tr.get('snackPasswordUpdated'),
        subtitle: tr.get('snackPasswordUpdatedSub'),
        icon: Icons.check_circle_rounded,
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) Navigator.of(context).maybePop();
    } else {
      final isWrongPw = response.error?.contains('incorrect') == true ||
          response.error?.contains('expired') == true;
      setState(() {
        _isLoading = false;
        _submitLocked = false;
        if (isWrongPw) _currentPwError = response.error;
      });
      _showSnackBar(
        message: tr.get('snackUpdateFailed'),
        subtitle: response.error ?? response.message,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final tr = Translations.of(context);
    final email = _authService.currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnackBar(
        message: tr.get('snackNoEmail'),
        subtitle: tr.get('snackNoEmailSub'),
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    final response = await _authService.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSnackBar(
      message: response.success
          ? tr.get('snackResetSent')
          : tr.get('snackResetFailed'),
      subtitle: response.success
          ? '${tr.get('snackResetSentSub')} $email${tr.get('snackResetSentSub2')}'
          : (response.error ?? response.message),
      icon: response.success
          ? Icons.mark_email_read_outlined
          : Icons.error_outline_rounded,
      isError: !response.success,
    );
  }

  void _showSnackBar({
    required String message,
    required String subtitle,
    required IconData icon,
    required bool isError,
  }) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final c = _C(isDark);
    final color = isError ? c.error : c.primary;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          padding: EdgeInsets.zero,
          elevation: 0,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 4),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.18), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.20)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message,
                          style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _C(isDark);

    return Scaffold(
      backgroundColor: c.scaffold,
      appBar: AppBar(
        backgroundColor: c.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              tr.get('changePassword'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: Colors.white.withOpacity(isDark ? 0.08 : 0.18)),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 80,
            right: -60,
            child: _Blob(size: 220, color: c.blob1, opacity: 0.45),
          ),
          Positioned(
            bottom: -40,
            left: -70,
            child: _Blob(size: 280, color: c.blob2, opacity: 0.30),
          ),
          Positioned(
            top: 120,
            right: -30,
            child: _Blob(size: 140, color: c.borderGreen, opacity: 0.40),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildFormCard(c, tr),
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(c, tr),
        ],
      ),
    );
  }

  Widget _buildFormCard(_C c, Translations tr) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.borderGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: c.cardShadow, blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.lightGreen,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.borderGreen),
                  ),
                  child:
                      Icon(Icons.security_rounded, color: c.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.get('passwordSettings'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr.get('passwordSettingsSub'),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  c.divider.withOpacity(0),
                  c.divider,
                  c.divider.withOpacity(0),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            _FieldLabel(text: tr.get('currentPassword'), c: c),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _currentPwController,
              hint: tr.get('currentPasswordHint'),
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
              textInputAction: TextInputAction.next,
              externalError: _currentPwError,
              c: c,
              validator: (val) {
                if (val == null || val.isEmpty)
                  return tr.get('validCurrentRequired');
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _isLoading ? null : _handleForgotPassword,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.borderGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline_rounded,
                          size: 13, color: c.primaryDark),
                      const SizedBox(width: 5),
                      Text(
                        tr.get('forgotPassword'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.primaryDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _FieldLabel(text: tr.get('newPassword'), c: c),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _newPwController,
              hint: tr.get('newPasswordHint'),
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              textInputAction: TextInputAction.next,
              c: c,
              validator: (val) {
                final result = PasswordValidator.validate(val ?? '');
                if (!result.isValid) return result.errors.join(' · ');
                return null;
              },
            ),
            const SizedBox(height: 12),
            PasswordStrengthIndicator(
              password: _newPwController.text,
              strength: _strength,
              c: c,
            ),

            const SizedBox(height: 24),
            _FieldLabel(text: tr.get('confirmNewPassword'), c: c),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmPwController,
              hint: tr.get('confirmNewPasswordHint'),
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(),
              c: c,
              validator: (val) {
                if (val == null || val.isEmpty)
                  return tr.get('validConfirmRequired');
                if (val != _newPwController.text)
                  return tr.get('validPasswordsMismatch');
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Submit button
            ScaleTransition(
              scale: _buttonScaleAnim,
              child: SizedBox(
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: c.buttonGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: c.primary.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || _submitLocked) ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      padding: EdgeInsets.zero,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_reset_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 9),
                                Text(
                                  tr.get('updatePasswordBtn'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    size: 13, color: c.textMuted.withOpacity(0.6)),
                const SizedBox(width: 5),
                Text(
                  tr.get('encryptedNotice'),
                  style: TextStyle(
                      fontSize: 11.5,
                      color: c.textMuted.withOpacity(0.7),
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required _C c,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    String? externalError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: (_) {
            if (externalError != null) setState(() => _currentPwError = null);
          },
          style: TextStyle(
              fontSize: 15, color: c.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: c.textSecondary.withOpacity(0.6),
                fontSize: 14.5,
                fontWeight: FontWeight.w400),
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: externalError != null
                    ? c.error.withOpacity(0.7)
                    : c.fieldIcon,
                size: 20),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(obscure),
                  color: c.fieldIcon,
                  size: 20,
                ),
              ),
            ),
            filled: true,
            fillColor:
                externalError != null ? c.error.withOpacity(0.04) : c.fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.borderGreen, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: externalError != null
                        ? c.error.withOpacity(0.5)
                        : c.borderGreen,
                    width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.primary, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: c.error.withOpacity(0.6), width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.error, width: 2)),
            errorStyle: TextStyle(
                color: c.error, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        if (externalError != null) ...[
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: c.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.error.withOpacity(0.20)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: c.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(externalError,
                      style: TextStyle(
                          fontSize: 12,
                          color: c.error,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingOverlay(_C c, Translations tr) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.borderGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: c.primary.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.lightGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.borderGreen),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(c.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr.get('loadingUpdatingPassword'),
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  tr.get('loadingPleaseWait'),
                  style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final _C c;
  const _FieldLabel({required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: 0.1));
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Blob({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withOpacity(opacity),
          color.withOpacity(0),
        ]),
      ),
    );
  }
}
