import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'widget/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  String name = "Loading...";
  String email = "";
  String? profileImageUrl;
  bool isLoading = true;
  bool _isUploading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Set email from Firebase Auth
      email = user!.email ?? "";
      _emailController.text = email;
      await fetchUserDataFromFirestore();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserDataFromFirestore() async {
    if (user == null) return;

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          name = userData['name'] as String? ?? "No name";
          email = userData['email'] as String? ?? user?.email ?? "";
          profileImageUrl = userData['profileImage'] as String?;
          isLoading = false;
          _nameController.text = name;
          _emailController.text = email;
        });
      } else {
        // If no document exists, create one with Auth data
        await _createUserDocument();
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _createUserDocument() async {
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user!.uid).set({
        'name': user!.displayName ?? "User",
        'email': user!.email ?? "",
        'profileImage': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        name = user!.displayName ?? "User";
        email = user!.email ?? "";
        _nameController.text = name;
        _emailController.text = email;
      });
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      await _uploadImageToFirebase();
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_image == null || user == null) return;

    setState(() => _isUploading = true);

    try {
      // Delete old image if exists
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(profileImageUrl!).delete();
        } catch (e) {
          // Old image might not exist in storage, continue anyway
        }
      }

      // Upload new image
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user!.uid}.jpg');

      await ref.putFile(
        _image!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .update({'profileImage': downloadUrl});

      setState(() {
        profileImageUrl = downloadUrl;
        _isUploading = false;
        _image = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile image updated!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) return;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': newName,
        'email': newEmail,
      });

      if (newName != user!.displayName) {
        await user!.updateDisplayName(newName);
      }

      setState(() => name = newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Stack(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [const Color(0xFF1B5E20), const Color(0xFF336A29)]
                          : [const Color(0xFF336A29), const Color(0xFFEAEF9D)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              child: _isUploading
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFF336A29),
                                    )
                                  : CircleAvatar(
                                      radius: 56,
                                      backgroundColor: isDarkMode
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.grey[200],
                                      backgroundImage: _getProfileImage(),
                                      child: _image == null &&
                                              (profileImageUrl == null ||
                                                  profileImageUrl!.isEmpty)
                                          ? Icon(
                                              Icons.person,
                                              size: 50,
                                              color: isDarkMode
                                                  ? Colors.white54
                                                  : Colors.grey,
                                            )
                                          : null,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: MediaQuery.of(context).size.width / 2 - 70,
                              child: GestureDetector(
                                onTap: _isUploading ? null : _pickImage,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF336A29),
                                  child: _isUploading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Name',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: TextField(
                            controller: _emailController,
                            textAlign: TextAlign.center,
                            readOnly: true,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : const Color.fromARGB(255, 48, 48, 48),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF336A29),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black12,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildItem(
                                context,
                                Icons.lock,
                                "Password",
                                isDarkMode,
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Change Password"),
                                    ),
                                  );
                                },
                              ),
                              _buildItem(
                                context,
                                Icons.headset_mic,
                                "Help & Support",
                                isDarkMode,
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Help & Support"),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                thickness: 1.5,
                                color: isDarkMode
                                    ? const Color(0xFF3C3C3C)
                                    : Colors.grey[300],
                              ),
                              // Dark Mode Toggle
                              ListTile(
                                leading: Icon(
                                  Icons.dark_mode_outlined,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF642ef3),
                                ),
                                title: Text(
                                  'Dark Mode',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                trailing: Switch(
                                  value: isDarkMode,
                                  onChanged: (value) {
                                    themeProvider.setDarkMode(value);
                                  },
                                  activeColor: const Color(0xFF336A29),
                                ),
                              ),
                              Divider(
                                thickness: 1.5,
                                color: isDarkMode
                                    ? const Color(0xFF3C3C3C)
                                    : Colors.grey[300],
                              ),
                              // Logout button
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  "Log Out",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                onTap: _logout,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_image != null) {
      return FileImage(_image!);
    }
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(profileImageUrl!);
    }
    return null;
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF336A29),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDarkMode ? Colors.white54 : Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
