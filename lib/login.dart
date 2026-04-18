import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../translations.dart';
import 'pages/register.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _errorCtrl;
  late final Animation<double> _errorAnim;

  // ── Singleton GoogleSignIn instance (avoids repeated object creation) ──
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _errorCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _errorAnim =
        CurvedAnimation(parent: _errorCtrl, curve: Curves.easeOutCubic);

    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Clear error as soon as user starts correcting their input
    _email.addListener(_clearError);
    _password.addListener(_clearError);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _errorCtrl.dispose();
    super.dispose();
  }

  // ── Safe translation helper ──────────────────────────────────────────────
  // Guards against Translations.of(context) returning null when the
  // locale provider is not yet ready, preventing a null-deref crash.
  String _t(String key, {String fallback = ''}) {
    try {
      final tr = Translations.of(context);
      if (tr == null) return fallback.isNotEmpty ? fallback : key;
      return tr.get(key);
    } catch (_) {
      return fallback.isNotEmpty ? fallback : key;
    }
  }

  // ── Error banner helpers ─────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _errorMessage = msg);
    _errorCtrl.forward(from: 0);
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorCtrl.reverse().then((_) {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  // ── Email / password sign-in ─────────────────────────────────────────────
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(_t('pleaseEnterEmailPassword',
          fallback: 'Please enter your email and password.'));
      return;
    }

    // Basic client-side email format check — avoids a round-trip for obvious typos
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError(_t('invalidEmail', fallback: 'Please enter a valid email.'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      // Reset loading before navigating so dispose() sees clean state
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_mapFirebaseError(e));
    } catch (e) {
      // Catch unexpected errors (network, platform exceptions, etc.)
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
          _t('loginFailed', fallback: 'Login failed. Please try again.'));
    }
  }

  // ── Google sign-in ───────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Sign out first to force the account-picker every time
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the picker
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ── FIX #1: Null-check both tokens before using them ──────────────
      // accessToken and idToken are both String? — either can be null when:
      //  • SHA-1 / SHA-256 fingerprints are missing in Firebase console
      //  • google-services.json is stale
      //  • Permissions were revoked on the device
      // Passing null to GoogleAuthProvider.credential() triggers the crash.
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null && idToken == null) {
        throw Exception('Google authentication returned null tokens. '
            'Check your Firebase SHA fingerprints and google-services.json.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken, // nullable — Firebase accepts one being null
        idToken: idToken, // nullable — Firebase accepts one being null
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      _showError(_mapFirebaseError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      debugPrint('Google sign-in error: $e');
      _showError(_t('googleSignInFailed',
          fallback: 'Google sign-in failed. Please try again.'));
    }
  }

  // ── Firebase error mapper ────────────────────────────────────────────────
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return _t('noAccountFound',
            fallback: 'No account found with this email.');
      case 'wrong-password':
        return _t('incorrectPassword', fallback: 'Incorrect password.');
      case 'invalid-credential':
        // Firebase v10+ merges user-not-found + wrong-password into this code
        return _t('incorrectPassword', fallback: 'Invalid email or password.');
      case 'invalid-email':
        return _t('invalidEmail', fallback: 'Invalid email address.');
      case 'user-disabled':
        return _t('accountDisabled',
            fallback: 'This account has been disabled.');
      case 'too-many-requests':
        return _t('tooManyRequests',
            fallback: 'Too many attempts. Please try again later.');
      case 'network-request-failed':
        return _t('noInternet', fallback: 'No internet connection.');
      case 'account-exists-with-different-credential':
        return _t('accountExistsDifferentCredential',
            fallback:
                'An account already exists with a different sign-in method.');
      default:
        return e.message ??
            _t('loginFailed', fallback: 'Login failed. Please try again.');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Illustration
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/Login-amico.png',
                        height: 180,
                        fit: BoxFit.contain,
                        // ── FIX: Never crash on a missing asset ──
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 180,
                          child: Center(
                            child: Icon(Icons.lock_open_rounded,
                                size: 80, color: Color(0xFFB0BEC5)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF388E3C).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          _InputField(
                            controller: _email,
                            hint: _t('email', fallback: 'Email'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _InputField(
                            controller: _password,
                            hint: _t('password', fallback: 'Password'),
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signIn(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              splashRadius: 20,
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Inline error banner ──────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _errorMessage == null
                                ? const SizedBox.shrink()
                                : FadeTransition(
                                    opacity: _errorAnim,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0F0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFFFCDD2)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFFC62828),
                                              size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                color: Color(0xFFC62828),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _clearError,
                                            child: const Icon(
                                                Icons.close_rounded,
                                                color: Color(0xFFEF9A9A),
                                                size: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),

                          // Login button
                          _PrimaryButton(
                            label: _t('login', fallback: 'Login'),
                            isLoading: _isLoading,
                            onTap: _signIn,
                          ),

                          const SizedBox(height: 18),

                          // Divider
                          Row(children: [
                            Expanded(child: Divider(color: Colors.grey[200])),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.grey[200])),
                          ]),

                          const SizedBox(height: 18),

                          // Google button
                          _GoogleButton(
                            isLoading: _isGoogleLoading,
                            onTap: _signInWithGoogle,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign-up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _t('dontHaveAccount',
                              fallback: "Don't have an account?"),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Register()),
                          ),
                          child: Text(
                            _t('signUp', fallback: 'Sign up'),
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input Field
// ─────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF388E3C), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7FAF8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF388E3C), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Primary Button
// ─────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF1B5E20).withValues(alpha: 0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Google Button
// ─────────────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: BorderSide(color: Colors.grey[300]!),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Color(0xFF1B5E20), strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
