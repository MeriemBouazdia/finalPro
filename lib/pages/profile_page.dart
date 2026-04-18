import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../translations.dart';
import 'services/profile_service.dart' hide debugPrint;
import 'widget/profile_header.dart';
import 'widget/profile_info.dart';
import 'widget/profile_settings.dart';
import 'widget/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Service for Firebase operations
  final ProfileService _profileService = ProfileService();

  // Local state
  File? _imageFile;
  String _name = "Loading...";
  String _email = "";
  String? _profileImageUrl;
  String? _cacheBuster;
  bool _isLoading = true;
  bool _isUploading = false;

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    _profileService.initialize(user);

    if (user != null) {
      _email = user.email ?? "";
      _emailController.text = _email;
      await _fetchUserData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    try {
      const defaultName = 'User';

      final userProfile = await _profileService
          .fetchUserData(
            defaultName,
            _email,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );

      if (userProfile != null && mounted) {
        setState(() {
          _name = userProfile.name;
          _email = userProfile.email;
          _profileImageUrl = userProfile.profileImageUrl;
          _cacheBuster = userProfile.cacheBuster;
          _nameController.text = _name;
          _emailController.text = _email;
        });
      }
    } catch (e) {
      debugPrint('fetchUserData error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePickImage() async {
    final pickedFile = await _profileService.pickImage();
    if (pickedFile != null && mounted) {
      setState(() => _imageFile = pickedFile);
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    final tr = Translations.of(context);
    setState(() => _isUploading = true);

    final downloadUrl = await _profileService.uploadProfileImage(
      _imageFile!,
      _profileImageUrl,
    );

    setState(() => _isUploading = false);

    if (downloadUrl != null && mounted) {
      setState(() {
        _profileImageUrl = downloadUrl;
        _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.get('profileUpdated')),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.get('errorUploading')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSaveProfile() async {
    final tr = Translations.of(context);
    final success = await _profileService.updateProfileName(
      _nameController.text,
    );

    if (success && mounted) {
      setState(() => _name = _nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.get('profileUpdated')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleLogout() {
    final tr = Translations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.get('logout')),
        content: Text(tr.get('confirmLogout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.get('no')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _profileService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(tr.get('yes')),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword() {
    final tr = Translations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.get('changePassword'))),
    );
  }

  void _handleHelp() {
    final tr = Translations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.get('helpSupport'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final isRtl = tr.isRtl;
    final textDirection = tr.textDirection;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
        body: _isLoading
            ? _buildLoadingIndicator(theme)
            : _buildContent(isDarkMode, isRtl, tr),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildContent(bool isDarkMode, bool isRtl, Translations tr) {
    return Stack(
      children: [
        // Gradient Background
        _buildGradientBackground(isDarkMode, isRtl),
        // Main Content
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                ProfileHeader(
                  imageFile: _imageFile,
                  profileImageUrl: _profileImageUrl,
                  cacheBuster: _cacheBuster,
                  isUploading: _isUploading,
                  isDarkMode: isDarkMode,
                  isRtl: isRtl,
                  onPickImage: _handlePickImage,
                ),
                const SizedBox(height: 10),
                ProfileInfo(
                  nameController: _nameController,
                  emailController: _emailController,
                  isDarkMode: isDarkMode,
                  getTranslation: tr.get,
                  onSave: _handleSaveProfile,
                ),
                const SizedBox(height: 30),
                ProfileSettings(
                  isDarkMode: isDarkMode,
                  isRtl: isRtl,
                  getTranslation: tr.get,
                  onLogout: _handleLogout,
                  onChangePassword: _handleChangePassword,
                  onHelp: _handleHelp,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBackground(bool isDarkMode, bool isRtl) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isRtl ? Alignment.topRight : Alignment.topLeft,
          end: isRtl ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF1B5E20), const Color(0xFF336A29)]
              : [const Color(0xFF336A29), const Color(0xFFEAEF9D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isRtl ? 0 : 60),
          bottomRight: Radius.circular(isRtl ? 60 : 0),
        ),
      ),
    );
  }
}
