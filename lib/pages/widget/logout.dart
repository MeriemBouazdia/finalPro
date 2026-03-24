import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/login.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

Widget buildLogout(BuildContext context) => SimpleSettingsTile(
      leading: Icon(
        Icons.logout,
        color: Color.fromARGB(255, 74, 116, 241),
      ),
      title: 'Logout',
      subtitle: '',
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      },
    );
