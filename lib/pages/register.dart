import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../core/errors/app_exception.dart';
import '../core/validators/register_validators.dart';
import '../models/farm_location.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    UserRepository? userRepository,
    LocationService? locationService,
  })  : _userRepository = userRepository,
        _locationService = locationService;

  final UserRepository? _userRepository;
  final LocationService? _locationService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // Services / Repositories
  late final UserRepository _userRepository;
  late final LocationService _locationService;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // UI State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasGreenhouse = false;
  FarmLocation? _farmLocation;
  bool _isDetectingLocation = false;
  bool _isRegistering = false;

  // Animations
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  //Lifecycle

  @override
  void initState() {
    super.initState();

    _userRepository = widget._userRepository ??
        UserRepository(
          authService: AuthService(),
          apiService: ApiService(),
        );

    _locationService = widget._locationService ?? LocationService();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Handlers

  Future<void> _handleDetectLocation() async {
    if (_isDetectingLocation) return;
    _setDetectingLocation(true);

    try {
      final location = await _locationService.detectCurrentLocation();
      if (!mounted) return;
      setState(() => _farmLocation = location);
      _showSnackbar('Location detected: ${location.locationName}');
    } on AppException catch (e) {
      if (mounted) _showSnackbar(e.message);
    } finally {
      if (mounted) _setDetectingLocation(false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_farmLocation == null) {
      _showSnackbar('Please detect your farm location');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      await _userRepository.registerFarmer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        hasGreenhouse: _hasGreenhouse,
        farmLocation: _farmLocation!,
      );

      // Write additional user data to Firebase Realtime Database
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseDatabase.instance.ref("users/${user.uid}").set({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "role": "farmer",
          "status": "pending",
          "hasGreenhouse": _hasGreenhouse,
          "farmLocation": {
            "lat": _farmLocation!.latitude,
            "lng": _farmLocation!.longitude,
          },
          "createdAt": DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      setState(() => _isRegistering = false);

      _showSuccessDialog();
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        _showSnackbar(e.message);
      }
    }
  }

  void _setDetectingLocation(bool value) {
    if (mounted) setState(() => _isDetectingLocation = value);
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Account Created'),
        content: const Text(
          'Your account is pending admin approval. '
          "You'll be notified once approved.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pushReplacementNamed(context, '/main'); // go to main
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  const _Header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: _FormCard(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      obscurePassword: _obscurePassword,
                      obscureConfirmPassword: _obscureConfirmPassword,
                      hasGreenhouse: _hasGreenhouse,
                      farmLocation: _farmLocation,
                      isDetectingLocation: _isDetectingLocation,
                      isRegistering: _isRegistering,
                      onToggleObscurePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onToggleObscureConfirm: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      onToggleGreenhouse: (v) =>
                          setState(() => _hasGreenhouse = v),
                      onDetectLocation: _handleDetectLocation,
                      onRegister: _handleRegister,
                      onGoToLogin: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      getPassword: () => _passwordController.text,
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
}

// Header

class _Header extends StatelessWidget {
  const _Header();

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_lightGreen, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.agriculture, size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _primaryGreen,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Register to manage your farm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.hasGreenhouse,
    required this.farmLocation,
    required this.isDetectingLocation,
    required this.isRegistering,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirm,
    required this.onToggleGreenhouse,
    required this.onDetectLocation,
    required this.onRegister,
    required this.onGoToLogin,
    required this.getPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool hasGreenhouse;
  final FarmLocation? farmLocation;
  final bool isDetectingLocation;
  final bool isRegistering;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirm;
  final ValueChanged<bool> onToggleGreenhouse;
  final VoidCallback onDetectLocation;
  final VoidCallback onRegister;
  final VoidCallback onGoToLogin;
  final String Function() getPassword;

  static const Color _primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormField(
              controller: nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              validator: RegisterValidators.name,
            ),
            const SizedBox(height: 16),
            _FormField(
              controller: emailController,
              label: 'Email',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              validator: RegisterValidators.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _FormField(
              controller: passwordController,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              validator: RegisterValidators.password,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: onToggleObscurePassword,
              ),
            ),
            const SizedBox(height: 16),
            _FormField(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              validator: RegisterValidators.confirmPassword(getPassword),
              obscureText: obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: onToggleObscureConfirm,
              ),
            ),
            const SizedBox(height: 22),
            _GreenhouseToggle(
              value: hasGreenhouse,
              onChanged: onToggleGreenhouse,
            ),
            const SizedBox(height: 22),
            _LocationDetector(
              farmLocation: farmLocation,
              isDetecting: isDetectingLocation,
              onTap: onDetectLocation,
            ),
            const SizedBox(height: 28),
            _RegisterButton(
              isLoading: isRegistering,
              onTap: onRegister,
            ),
            const SizedBox(height: 20),
            _LoginLink(onTap: onGoToLogin),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _softGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryGreen, size: 18),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
      ),
    );
  }
}

class _GreenhouseToggle extends StatelessWidget {
  const _GreenhouseToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF4CAF50);
  static const Color _softGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.home_outlined, color: _primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Do you have a greenhouse?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
                  ),
                ),
                Text(
                  value
                      ? 'Yes, I own a greenhouse'
                      : "No, I don't have one yet",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _lightGreen.withValues(alpha: 0.4),
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              return states.contains(WidgetState.selected)
                  ? _primaryGreen
                  : Colors.grey;
            }),
          ),
        ],
      ),
    );
  }
}

class _LocationDetector extends StatelessWidget {
  const _LocationDetector({
    required this.farmLocation,
    required this.isDetecting,
    required this.onTap,
  });

  final FarmLocation? farmLocation;
  final bool isDetecting;
  final VoidCallback onTap;

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _softGreen = Color(0xFFE8F5E9);

  bool get _hasLocation => farmLocation != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Location',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isDetecting ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hasLocation ? _softGreen : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasLocation ? _primaryGreen : Colors.grey.shade200,
                width: _hasLocation ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hasLocation ? _primaryGreen : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isDetecting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: _hasLocation ? Colors.white : Colors.grey,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _hasLocation
                              ? Icons.location_on
                              : Icons.location_on_outlined,
                          color: _hasLocation
                              ? Colors.white
                              : Colors.grey.shade500,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasLocation
                            ? 'Location detected'
                            : 'Tap to detect location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _hasLocation
                              ? _primaryGreen
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (_hasLocation) ...[
                        const SizedBox(height: 2),
                        Text(
                          farmLocation!.locationName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isDetecting)
                  Icon(
                    _hasLocation
                        ? Icons.check_circle
                        : Icons.chevron_right_rounded,
                    color: _hasLocation ? _primaryGreen : Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_primaryGreen, _lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.app_registration,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
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

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  static const Color _primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            ' Login',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
