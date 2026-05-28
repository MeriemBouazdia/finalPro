import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:app/l10n/translations.dart';
import '../pages/widget/theme_provider.dart';

class SensorData {
  final double temp;
  final double humidity;
  final double soilMoisture;
  final double light;
  final DateTime time;

  const SensorData({
    required this.temp,
    required this.humidity,
    required this.soilMoisture,
    required this.light,
    required this.time,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final raw = json['timestamp'];
    DateTime time;

    if (raw is int) {
      time = DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    } else if (raw is String) {
      final ms = int.tryParse(raw);
      if (ms != null) {
        time = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      } else {
        time = DateTime.parse(raw).toLocal();
      }
    } else {
      time = DateTime.now();
    }

    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return SensorData(
      temp: toDouble(json['temperature']),
      humidity: toDouble(json['humidity']),
      soilMoisture: toDouble(json['soil_moisture']),
      light: toDouble(json['light']),
      time: time,
    );
  }
}

class SensorApi {
  static const String baseUrl = 'http://192.168.1.5:3000';

  static Future<List<SensorData>> fetchHistory(
    String firebaseGhId, {
    int limit = 100,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final token = await user.getIdToken();
    final uri = Uri.parse('$baseUrl/history/$firebaseGhId?limit=$limit');

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 401) {
      throw Exception('Unauthorized — please log in again');
    }
    if (res.statusCode == 403) {
      throw Exception('Access denied to this greenhouse');
    }
    if (res.statusCode == 404) throw Exception('Greenhouse not found');
    if (res.statusCode != 200) {
      throw Exception('Server error: ${res.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(res.body);
    final List dataList = body['data'] ?? [];

    return dataList
        .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Centralised palette resolved at runtime from the active [ThemeProvider].
class _AppTokens {
  final bool isDark;

  const _AppTokens({required this.isDark});

  // ── Brand greens ──
  Color get primary => const Color(0xFF336A29);
  Color get primaryLight =>
      isDark ? const Color(0xFF81C995) : const Color(0xFF4CAF7A);
  Color get primaryContainer =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD8F3DC);

  // ── Surfaces — mirrors HomePage palette ──
  Color get scaffold =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get surface =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFF336A29);
  Color get surfaceVariant =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFECF7EF);
  Color get cardShadow =>
      isDark ? Colors.black54 : const Color(0xFF336A29).withOpacity(0.12);

  // ── Text ──
  Color get onSurface => isDark ? Colors.white : const Color(0xFF1B3A28);
  Color get onSurfaceMuted => isDark ? Colors.white70 : const Color(0xFF5A7A66);
  // ── Metric accent colours (same for both modes) ──
  Color get tempColor =>
      isDark ? const Color(0xFFFF7043) : const Color(0xFFE53935);
  Color get humidityColor =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1E88E5);
  Color get soilColor =>
      isDark ? const Color(0xFFA5D6A7) : const Color(0xFF388E3C);
  Color get lightColor =>
      isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);

  // ── Misc ──
  Color get divider =>
      isDark ? const Color(0xFF2A4A35) : const Color(0xFFD0EAD9);
  Color get chipSelected =>
      isDark ? const Color(0xFF2E7D4F) : const Color(0xFF4CAF7A);
  Color get chipUnselected =>
      isDark ? const Color(0xFF1E3528) : const Color(0xFFECF7EF);
}

extension _MetricTokens on ChartMetric {
  Color color(_AppTokens t) {
    switch (this) {
      case ChartMetric.temperature:
        return t.tempColor;
      case ChartMetric.humidity:
        return t.humidityColor;
      case ChartMetric.soilMoisture:
        return t.soilColor;
      case ChartMetric.light:
        return t.lightColor;
    }
  }

  String get label {
    switch (this) {
      case ChartMetric.temperature:
        return 'Temperature (°C)';
      case ChartMetric.humidity:
        return 'Humidity (%)';
      case ChartMetric.soilMoisture:
        return 'Soil Moisture';
      case ChartMetric.light:
        return 'Light (lux)';
    }
  }

  String get chipLabel {
    switch (this) {
      case ChartMetric.temperature:
        return '🌡  Temp';
      case ChartMetric.humidity:
        return '💧  Humidity';
      case ChartMetric.soilMoisture:
        return '🌱  Soil';
      case ChartMetric.light:
        return '☀️  Light';
    }
  }

  String get icon {
    switch (this) {
      case ChartMetric.temperature:
        return '🌡';
      case ChartMetric.humidity:
        return '💧';
      case ChartMetric.soilMoisture:
        return '🌱';
      case ChartMetric.light:
        return '☀️';
    }
  }
}

// ─────────────────────────────────────────────
//  ENUM
// ─────────────────────────────────────────────

enum ChartMetric { temperature, humidity, soilMoisture, light }

// ─────────────────────────────────────────────
//  CHART WIDGET
// ─────────────────────────────────────────────

class SensorChart extends StatelessWidget {
  final List<SensorData> data;
  final ChartMetric metric;

  const SensorChart({
    super.key,
    required this.data,
    this.metric = ChartMetric.temperature,
  });

  double _getValue(SensorData d) {
    switch (metric) {
      case ChartMetric.temperature:
        return d.temp;
      case ChartMetric.humidity:
        return d.humidity;
      case ChartMetric.soilMoisture:
        return d.soilMoisture;
      case ChartMetric.light:
        return d.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final t = _AppTokens(isDark: themeProvider.isDarkMode);
    final accentColor = metric.color(t);

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: t.onSurfaceMuted),
        ),
      );
    }

    final ordered = data.reversed.toList();
    final spots = ordered.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), _getValue(entry.value));
    }).toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: t.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                metric.label,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: t.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 10,
                          color: t.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: t.divider),
                    bottom: BorderSide(color: t.divider),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.25),
                          accentColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final String firebaseGhId;

  const HistoryPage({super.key, required this.firebaseGhId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late Future<List<SensorData>> _futureData;
  ChartMetric _selectedMetric = ChartMetric.temperature;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _load();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _load() {
    _futureData = SensorApi.fetchHistory(widget.firebaseGhId).then((data) {
      _fadeController.forward(from: 0);
      return data;
    });
  }

  Future<void> _refresh() async {
    setState(() => _load());
  }

  void _selectMetric(ChartMetric m) {
    if (_selectedMetric == m) return;
    _fadeController.forward(from: 0);
    setState(() => _selectedMetric = m);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final t = _AppTokens(isDark: themeProvider.isDarkMode);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: _buildAppBar(context, t, themeProvider),
      body: RefreshIndicator(
        color: t.primary,
        backgroundColor: t.surface,
        onRefresh: _refresh,
        child: FutureBuilder<List<SensorData>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading(context, t);
            }
            if (snapshot.hasError) {
              return _buildError(context, t, snapshot.error);
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return _buildEmpty(context, t);
            }
            return _buildContent(context, t, data);
          },
        ),
      ),
    );
  }

  //  App Bar

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    _AppTokens t,
    ThemeProvider themeProvider,
  ) {
    final tr = Translations.of(context);
    return AppBar(
      backgroundColor: t.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: t.cardShadow,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon:
            Icon(Icons.arrow_back_ios_new_rounded, color: t.primary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: t.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.eco_rounded,
              color: t.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tr.get('sensorHistory'),
            style: TextStyle(
              color: t.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: Icon(Icons.refresh_rounded, color: t.primary),
          onPressed: _refresh,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: t.divider),
      ),
    );
  }

  Widget _buildLoading(
    BuildContext context,
    _AppTokens t,
  ) {
    final tr = Translations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: t.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr.get('Loading sensor data…'),
            style: TextStyle(color: t.onSurfaceMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    _AppTokens t,
    Object? error,
  ) {
    final tr = Translations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: t.tempColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                color: t.tempColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr.get('Could not load data'),
              style: TextStyle(
                color: t.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.onSurfaceMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                tr.get('retry'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    _AppTokens t,
  ) {
    final tr = Translations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌿', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            tr.get('No sensor data yet'),
            style: TextStyle(
              color: t.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh',
            style: TextStyle(color: t.onSurfaceMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  //Main Content

  Widget _buildContent(
    BuildContext context,
    _AppTokens t,
    List<SensorData> data,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section label ──
            _SectionLabel(label: 'Select Metric', tokens: t),
            const SizedBox(height: 10),

            // ── Metric chips ──
            _MetricChipsRow(
              selected: _selectedMetric,
              tokens: t,
              onSelect: _selectMetric,
            ),

            const SizedBox(height: 24),
            // ── Chart card ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: SensorChart(
                key: ValueKey(_selectedMetric),
                data: data,
                metric: _selectedMetric,
              ),
            ),

            const SizedBox(height: 28),

            // ── Latest reading ──
            _SectionLabel(label: 'Latest Reading', tokens: t),
            const SizedBox(height: 10),
            _LatestCard(data: data.first, tokens: t),

            const SizedBox(height: 12),

            // ── Record count ──
            Row(
              children: [
                Icon(Icons.storage_rounded, size: 14, color: t.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  '${data.length} records loaded',
                  style: TextStyle(
                    color: t.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChipsRow extends StatelessWidget {
  final ChartMetric selected;
  final _AppTokens tokens;
  final ValueChanged<ChartMetric> onSelect;

  const _MetricChipsRow({
    required this.selected,
    required this.tokens,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChartMetric.values.map((m) {
          final isSelected = selected == m;
          final accentColor = m.color(tokens);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.15)
                    : tokens.chipUnselected,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? accentColor : tokens.divider,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: () => onSelect(m),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    m.chipLabel,
                    style: TextStyle(
                      color: isSelected ? accentColor : tokens.onSurfaceMuted,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
//  SECTION LABEL

class _SectionLabel extends StatelessWidget {
  final String label;
  final _AppTokens tokens;

  const _SectionLabel({required this.label, required this.tokens});
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: tokens.onSurfaceMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

//  LATEST CARD
class _LatestCard extends StatelessWidget {
  final SensorData data;
  final _AppTokens tokens;

  const _LatestCard({required this.data, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: t.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Metric tiles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricTile(
                  icon: '🌡',
                  label: 'Temp',
                  value: '${data.temp.toStringAsFixed(1)}°C',
                  accentColor: t.tempColor,
                  tokens: t,
                ),
                _VerticalDivider(tokens: t),
                _MetricTile(
                  icon: '💧',
                  label: 'Humidity',
                  value: '${data.humidity.toStringAsFixed(1)}%',
                  accentColor: t.humidityColor,
                  tokens: t,
                ),
                _VerticalDivider(tokens: t),
                _MetricTile(
                  icon: '🌱',
                  label: 'Soil',
                  value: data.soilMoisture.toStringAsFixed(1),
                  accentColor: t.soilColor,
                  tokens: t,
                ),
                _VerticalDivider(tokens: t),
                _MetricTile(
                  icon: '☀️',
                  label: 'Light',
                  value: '${data.light.toStringAsFixed(0)} lx',
                  accentColor: t.lightColor,
                  tokens: t,
                ),
              ],
            ),
          ),
          // Timestamp footer
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: t.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: t.onSurfaceMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTime(data.time),
                  style: TextStyle(
                    color: t.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
        '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }
}

class _MetricTile extends StatelessWidget {
  final String icon, label, value;
  final Color accentColor;
  final _AppTokens tokens;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.tokens,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: tokens.onSurfaceMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final _AppTokens tokens;
  const _VerticalDivider({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: tokens.divider,
    );
  }
}
