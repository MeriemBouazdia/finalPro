import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import 'widget/theme_provider.dart';

class ConfigurationPage extends StatefulWidget {
  final String ghId;

  const ConfigurationPage({super.key, required this.ghId});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final tempController = TextEditingController();
  final soilController = TextEditingController();

  late final DatabaseReference _targetsRef;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _targetsRef = FirebaseDatabase.instance
          .ref("users/${user.uid}/greenhouses/${widget.ghId}/targets");
      _loadExistingValues();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      _isLoading = false;
    }
  }

  Future<void> _loadExistingValues() async {
    try {
      final snapshot = await _targetsRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        if (mounted) {
          setState(() {
            tempController.text = data['temperature']?.toString() ?? '';
            soilController.text = data['soil']?.toString() ?? '';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> saveData() async {
    final tr = Translations.of(context);
    setState(() => _isSaving = true);

    try {
      final temperature = double.tryParse(tempController.text);
      final soil = int.tryParse(soilController.text);

      final Map<String, dynamic> data = {};
      if (temperature != null) data['temperature'] = temperature;
      if (soil != null) data['soil'] = soil;

      if (data.isNotEmpty) {
        await _targetsRef.update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.get('configurationSaved')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(tr.getWithParams('errorSaving', {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget buildSection(
    String title,
    String label,
    TextEditingController ctrl,
    bool isDarkMode,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    tempController.dispose();
    soilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr.get('configuration')),
          centerTitle: true,
          backgroundColor:
              isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF336A29),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.get('configuration')),
        centerTitle: true,
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF336A29),
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSection(
              tr.get('temperatureSettings'),
              tr.get('temperature'),
              tempController,
              isDarkMode,
            ),
            buildSection(
              tr.get('soilSettings'),
              tr.get('soil'),
              soilController,
              isDarkMode,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isSaving ? null : saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF336A29),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(tr.get('saveChanges')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
