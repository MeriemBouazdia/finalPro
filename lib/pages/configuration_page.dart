import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'widget/theme_provider.dart';

class ConfigurationPage extends StatefulWidget {
  final String ghId;

  const ConfigurationPage({super.key, required this.ghId});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  // Controllers
  final minTempController = TextEditingController();
  final maxTempController = TextEditingController();
  final minHumController = TextEditingController();
  final maxHumController = TextEditingController();
  final minSoilController = TextEditingController();
  final maxSoilController = TextEditingController();
  final minLightController = TextEditingController();
  final maxLightController = TextEditingController();

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
      _targetsRef =
          FirebaseDatabase.instance.ref("greenhouses/${widget.ghId}/targets");
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
            // Temperature
            if (data['temperature'] != null) {
              final temp = Map<String, dynamic>.from(data['temperature']);
              minTempController.text = temp['min']?.toString() ?? '';
              maxTempController.text = temp['max']?.toString() ?? '';
            }
            // Humidity
            if (data['humidity'] != null) {
              final hum = Map<String, dynamic>.from(data['humidity']);
              minHumController.text = hum['min']?.toString() ?? '';
              maxHumController.text = hum['max']?.toString() ?? '';
            }
            // Soil
            if (data['soil'] != null) {
              final soil = Map<String, dynamic>.from(data['soil']);
              minSoilController.text = soil['min']?.toString() ?? '';
              maxSoilController.text = soil['max']?.toString() ?? '';
            }
            // Light
            if (data['light'] != null) {
              final light = Map<String, dynamic>.from(data['light']);
              minLightController.text = light['min']?.toString() ?? '';
              maxLightController.text = light['max']?.toString() ?? '';
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  // Save data as numbers
  Future<void> saveData() async {
    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> data = {};

      // Parse and save as numbers
      final minTemp = _parseDouble(minTempController.text);
      final maxTemp = _parseDouble(maxTempController.text);
      final minHum = _parseDouble(minHumController.text);
      final maxHum = _parseDouble(maxHumController.text);
      final minSoil = _parseDouble(minSoilController.text);
      final maxSoil = _parseDouble(maxSoilController.text);
      final minLight = _parseDouble(minLightController.text);
      final maxLight = _parseDouble(maxLightController.text);

      if (minTemp != null && maxTemp != null) {
        data['temperature'] = {'min': minTemp, 'max': maxTemp};
      }
      if (minHum != null && maxHum != null) {
        data['humidity'] = {'min': minHum, 'max': maxHum};
      }
      if (minSoil != null && maxSoil != null) {
        data['soil'] = {'min': minSoil, 'max': maxSoil};
      }
      if (minLight != null && maxLight != null) {
        data['light'] = {'min': minLight, 'max': maxLight};
      }

      if (data.isNotEmpty) {
        await _targetsRef.update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Configuration saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget buildSection(
    String title,
    String minLabel,
    String maxLabel,
    TextEditingController minCtrl,
    TextEditingController maxCtrl,
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
              controller: minCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: minLabel,
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: maxLabel,
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
    minTempController.dispose();
    maxTempController.dispose();
    minHumController.dispose();
    maxHumController.dispose();
    minSoilController.dispose();
    maxSoilController.dispose();
    minLightController.dispose();
    maxLightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Greenhouse Configuration"),
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
        title: const Text("Greenhouse Configuration"),
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
                "Temperature Settings",
                "Min Temperature (°C)",
                "Max Temperature (°C)",
                minTempController,
                maxTempController,
                isDarkMode),
            buildSection(
                "Humidity Settings",
                "Min Humidity (%)",
                "Max Humidity (%)",
                minHumController,
                maxHumController,
                isDarkMode),
            buildSection(
                "Soil Moisture Settings",
                "Min Soil Moisture (%)",
                "Max Soil Moisture (%)",
                minSoilController,
                maxSoilController,
                isDarkMode),
            buildSection(
                "Light Intensity Settings",
                "Min Light (lux)",
                "Max Light (lux)",
                minLightController,
                maxLightController,
                isDarkMode),
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
                      : const Text("Save"),
                ),
                OutlinedButton(
                  onPressed: () {
                    minTempController.clear();
                    maxTempController.clear();
                    minHumController.clear();
                    maxHumController.clear();
                    minSoilController.clear();
                    maxSoilController.clear();
                    minLightController.clear();
                    maxLightController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white : const Color(0xFF336A29),
                    side: const BorderSide(color: Color(0xFF336A29)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
