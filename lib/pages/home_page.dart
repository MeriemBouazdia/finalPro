import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    final DatabaseReference sensorsRef = FirebaseDatabase.instance
        .ref('users/${user.uid}/greenhouses/$ghId/sensors');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Greenhouse Dashboard"),
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
                    'No sensor data available',
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
                        title: "🌡 Temp",
                        value: temp,
                        max: 50,
                        color: Colors.red,
                        isDarkMode: isDarkMode,
                        unit: "°C",
                      ),
                      SensorRadialCard(
                        title: "💧 Humidity",
                        value: humidity,
                        max: 100,
                        color: Colors.blue,
                        isDarkMode: isDarkMode,
                        unit: "%",
                      ),
                      SensorRadialCard(
                        title: "🌱 Soil",
                        value: soil,
                        max: 100,
                        color: Colors.green,
                        isDarkMode: isDarkMode,
                        unit: "%",
                      ),
                      SensorRadialCard(
                        title: "☀️ Light",
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
    this.unit = "",
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: SfCircularChart(
              series: <CircularSeries>[
                RadialBarSeries<double, String>(
                  dataSource: [value.clamp(0, max)],
                  xValueMapper: (value, _) => '',
                  yValueMapper: (value, _) => value,
                  maximumValue: max,
                  radius: '90%',
                  innerRadius: '60%',
                  cornerStyle: CornerStyle.bothCurve,
                  pointColorMapper: (_, __) => color,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.inside,
                    builder:
                        (data, point, series, pointIndex, dataLabelMapper) {
                      return Text(
                        '${value.toStringAsFixed(1)}$unit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
