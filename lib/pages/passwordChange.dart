import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Change Password',
      debugShowCheckedModeBanner: false,
      theme: _buildGreenhouseTheme(),
      home: const ChangePasswordPage(),
    );
  }

  static ThemeData _buildGreenhouseTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: GreenhouseColors.primaryGreen,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: GreenhouseColors.background,
      fontFamily: 'SF Pro Display',
    );
  }
}

// ============================================================================
// Greenhouse Color System
// ============================================================================

class GreenhouseColors {
  // Core palette
  static const Color background = Color(0xFFF4F8F4);
  static const Color primaryGreen = Color(0xFF2E9E44);
  static const Color darkGreen = Color(0xFF1F7A31);
  static const Color lightGreen = Color(0xFFEAF5EC);
  static const Color borderGreen = Color(0xFFD6E8D9);

  // Text
  static const Color primaryText = Color(0xFF234D20);
  static const Color secondaryText = Color(0xFF6B7B6E);

  // Feedback
  static const Color errorRed = Color(0xFFD94040);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF2E9E44);

  // Decorative blobs
  static const Color blobLight = Color(0xFFC6E5CC);
  static const Color blobMid = Color(0xFFB0D9B8);

  // Card / surface
  static const Color cardSurface = Colors.white;
  static const Color headerFrom = Color(0xFF1F7A31);
  static const Color headerTo = Color(0xFF2E9E44);

  // Field
  static const Color fieldFill = Color(0xFFEAF5EC);
  static const Color fieldBorder = Color(0xFFD6E8D9);
  static const Color fieldFocus = Color(0xFF2E9E44);
  static const Color fieldIcon = Color(0xFF5FAD6E);
}

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
          error: 'No user is currently signed in.',
        );
      }

      if (user.email == null) {
        return const PasswordChangeResponse(
          success: false,
          message: 'Authentication failed',
          error: 'No email address is associated with this account.',
        );
      }

      // Step 1: Re-authenticate
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        return PasswordChangeResponse(
          success: false,
          message: 'Re-authentication failed',
          error: _mapFirebaseError(e),
        );
      }

      // Step 2: Update password
      try {
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        return PasswordChangeResponse(
          success: false,
          message: 'Password update failed',
          error: _mapFirebaseError(e),
        );
      }

      return const PasswordChangeResponse(
        success: true,
        message: 'Password updated successfully',
      );
    } catch (e) {
      return const PasswordChangeResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'Something went wrong. Please try again later.',
      );
    }
  }

  Future<PasswordChangeResponse> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const PasswordChangeResponse(
        success: true,
        message: 'Password reset email sent',
      );
    } on FirebaseAuthException catch (e) {
      return PasswordChangeResponse(
        success: false,
        message: 'Failed to send reset email',
        error: _mapFirebaseError(e),
      );
    } catch (e) {
      return const PasswordChangeResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'Something went wrong. Please try again later.',
      );
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

  bool isWrongPasswordError(String? errorCode) {
    return errorCode == 'wrong-password' || errorCode == 'invalid-credential';
  }
}

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

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final PasswordStrength strength;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.strength,
  });

  Color _strengthColor() => switch (strength) {
        PasswordStrength.weak => const Color(0xFFD94040),
        PasswordStrength.fair => const Color(0xFFE07B27),
        PasswordStrength.good => const Color(0xFF5FAD6E),
        PasswordStrength.strong => GreenhouseColors.primaryGreen,
      };

  String _strengthLabel() => switch (strength) {
        PasswordStrength.weak => 'Weak',
        PasswordStrength.fair => 'Fair',
        PasswordStrength.good => 'Good',
        PasswordStrength.strong => 'Strong',
      };

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final color = _strengthColor();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GreenhouseColors.lightGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GreenhouseColors.borderGreen, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Password Strength',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: GreenhouseColors.secondaryText,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    _strengthLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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
                backgroundColor: GreenhouseColors.borderGreen,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            _RequirementsList(password: password),
          ],
        ),
      ),
    );
  }
}

class _RequirementsList extends StatelessWidget {
  final String password;
  const _RequirementsList({required this.password});

  @override
  Widget build(BuildContext context) {
    final reqs = [
      ('8+ characters', password.length >= 8),
      ('Uppercase A–Z', RegExp(r'[A-Z]').hasMatch(password)),
      ('Lowercase a–z', RegExp(r'[a-z]').hasMatch(password)),
      ('Number 0–9', RegExp(r'[0-9]').hasMatch(password)),
      ('Special !@#\$…', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)),
    ];

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children:
          reqs.map((r) => _RequirementChip(label: r.$1, isMet: r.$2)).toList(),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final bool isMet;
  const _RequirementChip({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isMet
            ? GreenhouseColors.primaryGreen.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMet
              ? GreenhouseColors.primaryGreen.withValues(alpha: 0.35)
              : GreenhouseColors.borderGreen,
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
            color: isMet
                ? GreenhouseColors.primaryGreen
                : GreenhouseColors.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet
                  ? GreenhouseColors.darkGreen
                  : GreenhouseColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

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

  late AnimationController _entranceController;
  late AnimationController _buttonController;
  late AnimationController _headerController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;
  late Animation<double> _headerExpandAnim;

  PasswordStrength _strength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _headerExpandAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _entranceController.forward();
    _headerController.forward();
    _newPwController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() {
    setState(() {
      _strength = PasswordValidator.getStrength(_newPwController.text);
    });
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    _entranceController.dispose();
    _buttonController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
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
        message: 'Password Updated',
        subtitle: 'Your account is now secured with the new password.',
        icon: Icons.check_circle_rounded,
        color: GreenhouseColors.successGreen,
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
        message: 'Update Failed',
        subtitle: response.error ?? response.message,
        icon: Icons.error_outline_rounded,
        color: GreenhouseColors.errorRed,
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final user = _authService.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      _showSnackBar(
        message: 'No Email Found',
        subtitle: 'No email address is linked to this account.',
        icon: Icons.error_outline_rounded,
        color: GreenhouseColors.errorRed,
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _authService.sendPasswordResetEmail(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      _showSnackBar(
        message: 'Reset Email Sent',
        subtitle: 'Check $email for the reset link.',
        icon: Icons.mark_email_read_outlined,
        color: GreenhouseColors.infoBlue,
      );
    } else {
      _showSnackBar(
        message: 'Failed to Send',
        subtitle: response.error ?? response.message,
        icon: Icons.error_outline_rounded,
        color: GreenhouseColors.errorRed,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: GreenhouseColors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: GreenhouseColors.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
    return Scaffold(
      backgroundColor: GreenhouseColors.background,
      body: Stack(
        children: [
          _buildDecorativeBackground(),
          Column(
            children: [
              _buildPremiumHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildFormCard(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildDecorativeBackground() {
    return Stack(
      children: [
        Positioned(
          bottom: 80,
          right: -60,
          child: _GreenhouseBlob(
            size: 220,
            color: GreenhouseColors.blobLight,
            opacity: 0.45,
          ),
        ),
        Positioned(
          bottom: -40,
          left: -70,
          child: _GreenhouseBlob(
            size: 280,
            color: GreenhouseColors.blobMid,
            opacity: 0.30,
          ),
        ),
        Positioned(
          top: 300,
          right: -30,
          child: _GreenhouseBlob(
            size: 140,
            color: GreenhouseColors.borderGreen,
            opacity: 0.55,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    return ScaleTransition(
      scale: _headerExpandAnim,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [GreenhouseColors.headerFrom, GreenhouseColors.headerTo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: Stack(
          children: [
            // Decorative inner blobs on header
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button row
                    Row(
                      children: [
                        _HeaderBackButton(
                          onTap: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Icon + title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon container
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secure your greenhouse account',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        decoration: BoxDecoration(
          color: GreenhouseColors.cardSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: GreenhouseColors.borderGreen,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GreenhouseColors.darkGreen.withValues(alpha: 0.07),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Section header ───────────────────────────────────────
              _FormSectionHeader(
                icon: Icons.security_rounded,
                title: 'Password Settings',
                subtitle: 'Update your credentials below',
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GreenhouseColors.borderGreen.withValues(alpha: 0),
                      GreenhouseColors.borderGreen,
                      GreenhouseColors.borderGreen.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: 'Current Password'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _currentPwController,
                hint: 'Enter your current password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                textInputAction: TextInputAction.next,
                externalError: _currentPwError,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Current password is required';
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
                      color: GreenhouseColors.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GreenhouseColors.borderGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 13,
                          color: GreenhouseColors.darkGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Forgot password?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: GreenhouseColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _SectionLabel(text: 'New Password'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newPwController,
                hint: 'Create a strong password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                textInputAction: TextInputAction.next,
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
              ),
              const SizedBox(height: 24),
              _SectionLabel(text: 'Confirm New Password'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPwController,
                hint: 'Re-enter new password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSubmit(),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Please confirm your new password';
                  if (val != _newPwController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              _buildSubmitButton(),

              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color:
                          GreenhouseColors.secondaryText.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Your data is encrypted and secure',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: GreenhouseColors.secondaryText
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
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
          style: const TextStyle(
            fontSize: 15,
            color: GreenhouseColors.primaryText,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: GreenhouseColors.secondaryText.withValues(alpha: 0.6),
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: externalError != null
                  ? GreenhouseColors.errorRed.withValues(alpha: 0.7)
                  : GreenhouseColors.fieldIcon,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(obscure),
                  color: GreenhouseColors.fieldIcon,
                  size: 20,
                ),
              ),
            ),
            filled: true,
            fillColor: externalError != null
                ? GreenhouseColors.errorRed.withValues(alpha: 0.04)
                : GreenhouseColors.fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: GreenhouseColors.fieldBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: externalError != null
                    ? GreenhouseColors.errorRed.withValues(alpha: 0.5)
                    : GreenhouseColors.fieldBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: GreenhouseColors.fieldFocus, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: GreenhouseColors.errorRed.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: GreenhouseColors.errorRed, width: 2),
            ),
            errorStyle: const TextStyle(
              color: GreenhouseColors.errorRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (externalError != null) ...[
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: GreenhouseColors.errorRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GreenhouseColors.errorRed.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: GreenhouseColors.errorRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    externalError,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GreenhouseColors.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: _buttonScaleAnim,
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [GreenhouseColors.headerTo, GreenhouseColors.headerFrom],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: GreenhouseColors.primaryGreen.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: GreenhouseColors.darkGreen.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || _submitLocked) ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Row(
                      key: ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 9),
                        Text(
                          'Update Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: GreenhouseColors.primaryText.withValues(alpha: 0.20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: GreenhouseColors.borderGreen,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GreenhouseColors.primaryGreen.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: GreenhouseColors.lightGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: GreenhouseColors.borderGreen),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation(GreenhouseColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Updating Password',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: GreenhouseColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please wait a moment…',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: GreenhouseColors.secondaryText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: GreenhouseColors.primaryText,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FormSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: GreenhouseColors.lightGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GreenhouseColors.borderGreen),
          ),
          child: Icon(icon, color: GreenhouseColors.primaryGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GreenhouseColors.primaryText,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: GreenhouseColors.secondaryText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HeaderBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GreenhouseBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GreenhouseBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
