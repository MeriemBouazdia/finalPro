import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A widget that displays the profile header with avatar and image picker button
class ProfileHeader extends StatelessWidget {
  final File? imageFile;
  final String? profileImageUrl;
  final String? cacheBuster;
  final bool isUploading;
  final bool isDarkMode;
  final bool isRtl;
  final VoidCallback onPickImage;

  const ProfileHeader({
    super.key,
    this.imageFile,
    this.profileImageUrl,
    this.cacheBuster,
    this.isUploading = false,
    this.isDarkMode = false,
    this.isRtl = false,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // PROFILE IMAGE
          GestureDetector(
            onTap: isUploading ? null : onPickImage,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor:
                    isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                child: _buildAvatarContent(context),
              ),
            ),
          ),

          // CAMERA BUTTON
          Positioned(
            bottom: 4,
            right: isRtl ? null : 4,
            left: isRtl ? 4 : null,
            child: GestureDetector(
              onTap: isUploading ? null : onPickImage,
              child: _buildCameraButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    if (isUploading) {
      return const CircularProgressIndicator(
        color: Color(0xFF336A29),
      );
    }

    final image = _getBackgroundImage();

    return CircleAvatar(
      radius: 56,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
      backgroundImage: image,
      child: image == null
          ? Icon(
              Icons.person,
              size: 50,
              color: isDarkMode ? Colors.white54 : Colors.grey,
            )
          : null,
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (imageFile != null) {
      return FileImage(imageFile!);
    }
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      // Add cache buster to force refresh after upload
      final urlWithCacheBuster = cacheBuster != null
          ? '$profileImageUrl?cb=$cacheBuster'
          : profileImageUrl!;
      return CachedNetworkImageProvider(urlWithCacheBuster);
    }
    return null;
  }

  Widget _buildCameraButton() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF336A29),
      child: isUploading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
    );
  }
}
