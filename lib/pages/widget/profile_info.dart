import 'package:flutter/material.dart';

/// A widget that displays the profile information (name and email fields)
class ProfileInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final bool isDarkMode;
  final String Function(String key) getTranslation;
  final VoidCallback onSave;

  const ProfileInfo({
    super.key,
    required this.nameController,
    required this.emailController,
    this.isDarkMode = false,
    required this.getTranslation,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // NAME
          TextField(
            controller: nameController,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: getTranslation('name'),
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.grey,
              ),
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: 120,
            height: 1.2,
            color: isDarkMode ? Colors.white24 : Colors.grey[300],
          ),

          const SizedBox(height: 10),

          // EMAIL
          TextField(
            controller: emailController,
            readOnly: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
            decoration: InputDecoration(
              hintText: getTranslation('email'),
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.grey,
              ),
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 20),

          // SAVE BUTTON
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF336A29),
              padding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 3,
            ),
            child: Text(
              getTranslation('saveChanges'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
