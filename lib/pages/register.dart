import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../translations.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController farmLocationController = TextEditingController();

  bool isLoading = false;
  bool _isFarmer = false;
  bool _hasGreenhouse = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    farmLocationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final tr = Translations.of(context);
    if (value == null || value.isEmpty) {
      return tr.get('emailRequired');
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return tr.get('validEmail');
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final tr = Translations.of(context);
    if (value == null || value.isEmpty) {
      return tr.get('passwordRequired');
    }
    if (value.length < 6) {
      return tr.get('passwordMinLength');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final tr = Translations.of(context);
    if (value == null || value.isEmpty) {
      return tr.get('confirmPasswordRequired');
    }
    if (value != passwordController.text) {
      return tr.get('passwordsDoNotMatch');
    }
    return null;
  }

  String? _validateName(String? value) {
    final tr = Translations.of(context);
    if (value == null || value.isEmpty) {
      return tr.get('nameRequired');
    }
    if (value.length < 2) {
      return tr.get('nameMinLength');
    }
    return null;
  }

  String? _validateFarmLocation(String? value) {
    final tr = Translations.of(context);
    if (_isFarmer && (value == null || value.isEmpty)) {
      return tr.get('farmLocationRequired');
    }
    return null;
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    final tr = Translations.of(context);
    setState(() => isLoading = true);

    try {
      // Create user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user?.updateDisplayName(nameController.text.trim());

      final DatabaseReference ref = FirebaseDatabase.instance.ref();
      await ref.child('users').child(userCredential.user!.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': _isFarmer ? 'farmer' : 'visitor',
        'hasGreenhouse': _isFarmer ? _hasGreenhouse : false,
        'farmLocation': _isFarmer ? farmLocationController.text.trim() : '',
        'greenhouse_access': [],
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(tr
                  .getWithParams('welcomeUser', {'name': nameController.text})),
            ],
          ),
          backgroundColor: primaryGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate to main screen
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final tr = Translations.of(context);
      String errorMsg;
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = tr.get('emailAlreadyRegistered');
          break;
        case 'weak-password':
          errorMsg = tr.get('weakPassword');
          break;
        case 'invalid-email':
          errorMsg = tr.get('invalidEmailAddress');
          break;
        default:
          errorMsg = e.message ?? tr.get('registrationFailed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final tr = Translations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(tr.get('errorOccurred')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isRtl = tr.isRtl;

    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(tr, isRtl),

                  // Form Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: _buildFormCard(tr, isRtl),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Translations tr, bool isRtl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      child: Column(
        children: [
          // Plant/Agri Icon with animated container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [lightGreen, primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            tr.get('createAccount'),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkGreen,
              letterSpacing: -0.5,
            ),
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            tr.get('registerToManage'),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Translations tr, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full Name Field
            _buildModernTextField(
              controller: nameController,
              label: tr.get('fullName'),
              hint: tr.get('enterFullName'),
              icon: Icons.person_outline,
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 18),

            // Email Field
            _buildModernTextField(
              controller: emailController,
              label: tr.get('email'),
              hint: tr.get('enterEmail'),
              icon: Icons.email_outlined,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 18),

            // Password Field
            _buildModernTextField(
              controller: passwordController,
              label: tr.get('password'),
              hint: tr.get('enterFullName'),
              icon: Icons.lock_outline,
              validator: _validatePassword,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade400,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 18),

            // Confirm Password Field
            _buildModernTextField(
              controller: confirmPasswordController,
              label: tr.get('confirmPassword'),
              hint: tr.get('reEnterPassword'),
              icon: Icons.lock_outline,
              validator: _validateConfirmPassword,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey.shade400,
                ),
                onPressed: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // User Type Selector
            _buildUserTypeSelector(tr),

            // Conditional Farmer Fields
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildFarmerFields(tr),
              crossFadeState: _isFarmer
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),

            const SizedBox(height: 28),

            // Register Button
            _buildRegisterButton(tr),
            const SizedBox(height: 20),

            // Login Link
            _buildLoginLink(tr),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color.fromARGB(255, 4, 4, 4),
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryGreen,
            size: 20,
          ),
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
          borderSide: const BorderSide(color: primaryGreen, width: 2),
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

  Widget _buildUserTypeSelector(Translations tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "I am a...",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Farmer Option
            Expanded(
              child: _buildUserTypeCard(
                title: tr.get('farmer'),
                icon: Icons.agriculture,
                isSelected: _isFarmer,
                onTap: () => setState(() => _isFarmer = true),
              ),
            ),
            const SizedBox(width: 12),
            // Visitor Option
            Expanded(
              child: _buildUserTypeCard(
                title: tr.get('visitor'),
                icon: Icons.person_outline,
                isSelected: !_isFarmer,
                onTap: () => setState(() => _isFarmer = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [primaryGreen, lightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryGreen : Colors.grey.shade200,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerFields(Translations tr) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Greenhouse Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softGreen,
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
                  child: const Icon(
                    Icons.home_outlined,
                    color: primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.get('hasGreenhouse'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      Text(
                        _hasGreenhouse
                            ? "Yes, I own a greenhouse"
                            : "No, I don't have one yet",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _hasGreenhouse,
                  onChanged: (value) {
                    setState(() => _hasGreenhouse = value);
                  },
                  activeThumbColor: primaryGreen,
                  activeTrackColor: accentGreen.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Farm Location Field
          _buildModernTextField(
            controller: farmLocationController,
            label: tr.get('farmLocation'),
            hint: tr.get('enterFarmLocation'),
            icon: Icons.location_on_outlined,
            validator: _validateFarmLocation,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(Translations tr) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : register,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.app_registration,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr.get('register'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(Translations tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          tr.get('alreadyHaveAccount'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text(
            tr.get('loginLink'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              decoration: TextDecoration.underline,
              decorationColor: primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
