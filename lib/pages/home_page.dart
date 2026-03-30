import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../../translations.dart';
import 'widget/theme_provider.dart';
import 'device_control.dart';

class HomePage extends StatelessWidget {
  final String ghId;

  const HomePage({super.key, required this.ghId});

  double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isRtl = tr.isRtl;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(tr.get('pleaseLoginFirst')),
        ),
      );
    }

    final DatabaseReference sensorsRef = FirebaseDatabase.instance
        .ref('users/${user.uid}/greenhouses/$ghId/sensors');

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.get('greenhouseDashboard')),
        centerTitle: true,
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF336A29),
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: StreamBuilder<DatabaseEvent>(
        stream: sensorsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : const Color(0xFF336A29),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sensors_off,
                    size: 64,
                    color: isDarkMode ? Colors.grey : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr.get('noSensorData'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ghId: $ghId',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          double temp = _parseDouble(data['temp']?['value']);
          double humidity = _parseDouble(data['humidity']?['value']);
          double soil =
              _parseDouble(data['soil_moisture']?['sensor1']?['value']);
          double light = _parseDouble(data['light']?['value']);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      SensorRadialCard(
                        title: tr.get('temp'),
                        value: temp,
                        max: 50,
                        color: Colors.red,
                        isDarkMode: isDarkMode,
                        unit: "°C",
                      ),
                      SensorRadialCard(
                        title: tr.get('humidity'),
                        value: humidity,
                        max: 100,
                        color: Colors.blue,
                        isDarkMode: isDarkMode,
                        unit: "%",
                      ),
                      SensorRadialCard(
                        title: tr.get('soil'),
                        value: soil,
                        max: 100,
                        color: Colors.green,
                        isDarkMode: isDarkMode,
                        unit: "%",
                      ),
                      SensorRadialCard(
                        title: tr.get('light'),
                        value: light,
                        max: 2000,
                        color: Colors.orange,
                        isDarkMode: isDarkMode,
                        unit: "lux",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                DeviceControl(ghId: ghId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SensorRadialCard extends StatelessWidget {
  final String title;
  final double value;
  final double max;
  final Color color;
  final bool isDarkMode;
  final String unit;

  const SensorRadialCard({
    super.key,
    required this.title,
    required this.value,
    required this.max,
    required this.color,
    required this.isDarkMode,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
