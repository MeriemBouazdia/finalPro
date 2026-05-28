import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:app/l10n/translations.dart';
import '../../services/monitoring_service.dart';
import 'widget/theme_provider.dart';
import 'device_control.dart';

double _parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double _parseSensorValue(dynamic node, {double fallback = 0.0}) {
  if (node == null || node is! Map) return fallback;
  final map = Map<String, dynamic>.from(node);
  if (map.containsKey('value'))
    return _parseDouble(map['value'], fallback: fallback);
  for (final child in map.values) {
    if (child is Map && child.containsKey('value')) {
      return _parseDouble(child['value'], fallback: fallback);
    }
  }
  return fallback;
}

class _SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double light;

  const _SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.light,
  });

  factory _SensorData.fromMap(Map<String, dynamic> sensors) => _SensorData(
        temperature: _parseSensorValue(sensors['temperature']),
        humidity: _parseSensorValue(sensors['humidity']),
        soilMoisture: _parseSensorValue(sensors['soil']),
        light: _parseSensorValue(sensors['light']),
      );

  static const empty = _SensorData(
    temperature: 0,
    humidity: 0,
    soilMoisture: 0,
    light: 0,
  );
}

class HomePage extends StatefulWidget {
  // ← was StatelessWidget
  final String ghId;
  const HomePage({super.key, required this.ghId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MonitoringService? _monitor;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  Future<void> _startMonitoring() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _monitor = MonitoringService(uid: user.uid, ghId: widget.ghId);
    await _monitor!.start();
  }

  @override
  void dispose() {
    _monitor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text(tr.get('pleaseLoginFirst'))));
    }

    final sensorsRef = FirebaseDatabase.instance
        .ref('users/${user.uid}/greenhouses/${widget.ghId}/sensors');

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

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.cloud_off,
              message: tr.get('connectionError'),
              subtitle: snapshot.error.toString(),
              isDarkMode: isDarkMode,
            );
          }

          final rawValue = snapshot.data?.snapshot.value;
          if (rawValue == null || rawValue is! Map) {
            return _EmptyState(
              icon: Icons.sensors_off,
              message: tr.get('noSensorData'),
              subtitle: 'Greenhouse ID: ${widget.ghId}',
              isDarkMode: isDarkMode,
            );
          }

          final sensors = Map<String, dynamic>.from(rawValue);
          final data = _SensorData.fromMap(sensors);

          return _DashboardBody(
            data: data,
            ghId: widget.ghId,
            isDarkMode: isDarkMode,
            tr: tr,
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final _SensorData data;
  final String ghId;
  final bool isDarkMode;
  final dynamic tr;

  const _DashboardBody({
    required this.data,
    required this.ghId,
    required this.isDarkMode,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                SensorRadialCard(
                  title: tr.get('temp'),
                  value: data.temperature,
                  max: 50,
                  color: Colors.red,
                  isDarkMode: isDarkMode,
                  unit: '°C',
                ),
                SensorRadialCard(
                  title: tr.get('humidity'),
                  value: data.humidity,
                  max: 100,
                  color: Colors.blue,
                  isDarkMode: isDarkMode,
                  unit: '%',
                ),
                SensorRadialCard(
                  title: tr.get('soil'),
                  value: data.soilMoisture,
                  max: 4095,
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                  unit: '',
                  displayValue: data.soilMoisture.toStringAsFixed(0),
                ),
                SensorRadialCard(
                  title: tr.get('light'),
                  value: data.light,
                  max: 4095,
                  color: Colors.orange,
                  isDarkMode: isDarkMode,
                  unit: '',
                  displayValue: data.light.toStringAsFixed(0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DeviceControl(ghId: ghId),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final bool isDarkMode;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.subtitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64, color: isDarkMode ? Colors.grey : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600])),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white38 : Colors.grey[400])),
          ],
        ],
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
  final String? displayValue;

  const SensorRadialCard({
    super.key,
    required this.title,
    required this.value,
    required this.max,
    required this.color,
    required this.isDarkMode,
    required this.unit,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (max == 0) ? 0.0 : (value / max).clamp(0.0, 1.0);
    final label = displayValue ?? '${value.toStringAsFixed(1)}$unit';

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
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              )),
        ],
      ),
    );
  }
}
