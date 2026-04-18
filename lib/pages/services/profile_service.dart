import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';


/// Model class representing user profile data
class UserProfile {
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? cacheBuster;

  const UserProfile({
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.cacheBuster,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    String? cacheBuster,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      cacheBuster: cacheBuster ?? this.cacheBuster,
    );
  }
}

/// Service class that handles all Firebase-related operations for user profile
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? _currentUser;

  /// Initialize the service with the current authenticated user
  void initialize(User? user) {
    _currentUser = user;
  }

  /// Get the current user
  User? get currentUser => _currentUser;

  /// Fetch user data from Firestore
  Future<UserProfile?> fetchUserData(
      String defaultName, String defaultEmail) async {
    if (_currentUser == null) return null;

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final cacheBuster = userData['profileImageUpdated'] as String?;

        return UserProfile(
          name: userData['name'] as String? ?? defaultName,
          email: userData['email'] as String? ?? defaultEmail,
          profileImageUrl: userData['profileImage'] as String?,
          cacheBuster: cacheBuster,
        );
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument(defaultName, defaultEmail);
        return UserProfile(
          name: defaultName,
          email: defaultEmail,
        );
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  /// Create a new user document in Firestore
  Future<void> _createUserDocument(
      String defaultName, String defaultEmail) async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'name': _currentUser!.displayName ?? defaultName,
        'email': _currentUser!.email ?? defaultEmail,
        'profileImage': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

 Future<File?> pickImage() async {
  try {
    
    var status = await Permission.photos.request();

    if (!status.isGranted) {
      debugPrint("Permission denied");
      return null;
    }

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
  } catch (e) {
    debugPrint('Error picking image: $e');
  }
  return null;
}

  /// Upload profile image to Firebase Storage and update Firestore
  Future<String?> uploadProfileImage(
      File image, String? existingImageUrl) async {
    if (_currentUser == null) return null;

    try {
      // Delete old image if exists
      if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingImageUrl).delete();
        } catch (e) {
          // Old image might not exist in storage
        }
      }

      // Upload new image
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('${_currentUser!.uid}.jpg');

      await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Add cache buster to force refresh
      final cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

      // Update Firestore with new image URL and cache buster
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'profileImage': downloadUrl,
        'profileImageUpdated': cacheBuster,
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Update user profile name in Firestore and Firebase Auth
  Future<bool> updateProfileName(String name) async {
    if (_currentUser == null) return false;

    try {
      await _currentUser!.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'name': name.trim(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

/// Helper function for debug printing
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
