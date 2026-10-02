import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:app/l10n/translations.dart';
import '../pages/widget/theme_provider.dart';

// ─────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────

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
  static const String baseUrl = 'http://192.168.1.7:3000';

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

    if (res.statusCode == 401)
      throw Exception('Unauthorized — please log in again');
    if (res.statusCode == 403)
      throw Exception('Access denied to this greenhouse');
    if (res.statusCode == 404) throw Exception('Greenhouse not found');
    if (res.statusCode != 200)
      throw Exception('Server error: ${res.statusCode}');

    final Map<String, dynamic> body = jsonDecode(res.body);
    final List dataList = body['data'] ?? [];
    return dataList
        .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ─────────────────────────────────────────────
//  DESIGN TOKENS — matches the screenshot exactly
// ─────────────────────────────────────────────

class _T {
  final bool isDark;
  const _T(this.isDark);

  // Scaffold & surfaces
  Color get scaffold =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
  Color get appBar =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFF336A29);
  Color get card => isDark ? const Color(0xFF242424) : Colors.white;
  Color get cardBorder =>
      isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

  // Chart container — white in screenshot
  Color get chartBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get chartBorder =>
      isDark ? const Color(0xFF333333) : const Color(0xFFD0D0D0);

  // Text
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textSecondary => isDark ? Colors.white60 : const Color(0xFF666666);
  Color get textMuted => isDark ? Colors.white38 : const Color(0xFF999999);

  // AppBar elements
  Color get appBarIcon => Colors.white;
  Color get appBarText => Colors.white;

  // Chip — outlined style like screenshot
  Color get chipBorder =>
      isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB);
  Color get chipBg => isDark ? const Color(0xFF2A2A2A) : Colors.white;
  Color get chipText => isDark ? Colors.white70 : const Color(0xFF333333);

  // Selected chip — light green tint
  Color get chipSelectedBorder => const Color(0xFF336A29);
  Color get chipSelectedBg =>
      isDark ? const Color(0xFF1A3020) : const Color(0xFFE8F5E9);
  Color get chipSelectedText =>
      isDark ? const Color(0xFF81C995) : const Color(0xFF336A29);
  Color get chipCheckColor =>
      isDark ? const Color(0xFF81C995) : const Color(0xFF336A29);

  // Grid / divider
  Color get gridLine =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
  Color get divider =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

  // Metric accent colors — same as screenshot
  Color get tempColor => const Color(0xFFE53935);
  Color get humidityColor => const Color(0xFF1E88E5);
  Color get soilColor => const Color(0xFF388E3C);
  Color get lightColor => const Color(0xFFF9A825);

  // Latest card footer
  Color get latestFooter =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8);

  // Shadows
  Color get shadow => isDark ? Colors.black45 : Colors.black.withOpacity(0.06);

  // Primary
  Color get primary => const Color(0xFF336A29);
}

enum ChartMetric { temperature, humidity, soilMoisture, light }

extension _MetricExt on ChartMetric {
  Color accentColor(_T t) {
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

  String chipLabel(Translations tr) {
    switch (this) {
      case ChartMetric.temperature:
        return tr.get('chipTemp');
      case ChartMetric.humidity:
        return tr.get('chipHumidity');
      case ChartMetric.soilMoisture:
        return tr.get('chipSoil');
      case ChartMetric.light:
        return tr.get('chipLight');
    }
  }

  String axisLabel(Translations tr) {
    switch (this) {
      case ChartMetric.temperature:
        return tr.get('axisTemp');
      case ChartMetric.humidity:
        return tr.get('axisHumidity');
      case ChartMetric.soilMoisture:
        return tr.get('axisSoil');
      case ChartMetric.light:
        return tr.get('axisLight');
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

  String tileLabel(Translations tr) {
    switch (this) {
      case ChartMetric.temperature:
        return tr.get('tileTemp');
      case ChartMetric.humidity:
        return tr.get('tileHumidity');
      case ChartMetric.soilMoisture:
        return tr.get('tileSoil');
      case ChartMetric.light:
        return tr.get('tileLight');
    }
  }
}

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
    final tr = Translations.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = _T(isDark);
    final accent = metric.accentColor(t);

    if (data.isEmpty) {
      return Center(
        child: Text(
          tr.get('noDataAvailable'),
          style: TextStyle(color: t.textSecondary),
        ),
      );
    }

    final ordered = data.reversed.toList();
    final spots = ordered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _getValue(e.value));
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: t.chartBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.chartBorder, width: 1),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title — e.g. "Light (lux)" in accent color, bold
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              metric.axisLabel(tr),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: t.gridLine,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: t.gridLine,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: t.textSecondary,
                          ),
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
                  border: Border.all(color: t.chartBorder, width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accent,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.18),
                          accent.withOpacity(0.0),
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

// ─────────────────────────────────────────────
//  HISTORY PAGE
// ─────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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

  Future<void> _refresh() async => setState(_load);

  void _selectMetric(ChartMetric m) {
    if (_selectedMetric == m) return;
    _fadeController.forward(from: 0);
    setState(() => _selectedMetric = m);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = _T(isDark);

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: _buildAppBar(context, t, tr),
      body: RefreshIndicator(
        color: t.primary,
        backgroundColor: t.card,
        onRefresh: _refresh,
        child: FutureBuilder<List<SensorData>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading(t, tr);
            }
            if (snapshot.hasError) {
              return _buildError(t, tr, snapshot.error);
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) return _buildEmpty(t, tr);
            return _buildContent(context, t, tr, data);
          },
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, _T t, Translations tr) {
    return AppBar(
      backgroundColor: t.appBar,
      foregroundColor: t.appBarText,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: t.appBarIcon, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        tr.get('sensorHistory'),
        style: TextStyle(
          color: t.appBarText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          tooltip: tr.get('refresh'),
          icon: Icon(Icons.refresh_rounded, color: t.appBarIcon),
          onPressed: _refresh,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
            height: 1,
            color: Colors.white.withOpacity(isDark(t) ? 0.08 : 0.18)),
      ),
    );
  }

  bool isDark(_T t) => t.isDark;

  // ── Loading ─────────────────────────────────

  Widget _buildLoading(_T t, Translations tr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3, color: t.primary),
          ),
          const SizedBox(height: 16),
          Text(
            tr.get('loadingSensorData'),
            style: TextStyle(color: t.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Error ───────────────────────────────────

  Widget _buildError(_T t, Translations tr, Object? error) {
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
              tr.get('couldNotLoadData'),
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr.get('retry'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ───────────────────────────────────

  Widget _buildEmpty(_T t, Translations tr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            tr.get('noSensorDataYet'),
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            tr.get('pullToRefresh'),
            style: TextStyle(color: t.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Main Content ────────────────────────────

  Widget _buildContent(
    BuildContext context,
    _T t,
    Translations tr,
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
            // Metric chips
            _MetricChipsRow(
              selected: _selectedMetric,
              t: t,
              onSelect: _selectMetric,
            ),

            const SizedBox(height: 20),

            // Chart
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
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

            // "Latest Reading" section label
            Text(
              tr.get('latestReading'),
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            // Latest card
            _LatestCard(data: data.first, t: t),

            const SizedBox(height: 12),

            // Record count
            Row(
              children: [
                Icon(Icons.storage_rounded, size: 14, color: t.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${data.length} ${tr.get('recordsLoaded')}',
                  style: TextStyle(
                    color: t.textMuted,
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
  final _T t;
  final ValueChanged<ChartMetric> onSelect;

  const _MetricChipsRow({
    required this.selected,
    required this.t,
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
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _MetricChip(
              metric: m,
              isSelected: isSelected,
              t: t,
              tr: tr,
              onTap: () => onSelect(m),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final ChartMetric metric;
  final bool isSelected;
  final _T t;
  final Translations tr;
  final VoidCallback onTap;

  const _MetricChip({
    required this.metric,
    required this.isSelected,
    required this.t,
    required this.tr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? t.chipSelectedBg : t.chipBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? t.chipSelectedBorder : t.chipBorder,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark only when selected — matches screenshot
              if (isSelected) ...[
                Icon(Icons.check_rounded, size: 14, color: t.chipCheckColor),
                const SizedBox(width: 4),
              ],
              Text(
                metric.chipLabel(tr),
                style: TextStyle(
                  color: isSelected ? t.chipSelectedText : t.chipText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  final SensorData data;
  final _T t;

  const _LatestCard({required this.data, required this.t});

  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return 'At ${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
        '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
              color: t.shadow, blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricTile(
                  icon: '🌡',
                  value: '${data.temp.toStringAsFixed(1)}°C',
                  label: tr.get('tileTemp'),
                  accent: t.tempColor,
                  t: t,
                ),
                _VDivider(t: t),
                _MetricTile(
                  icon: '💧',
                  value: '${data.humidity.toStringAsFixed(1)}%',
                  label: tr.get('tileHumidity'),
                  accent: t.humidityColor,
                  t: t,
                ),
                _VDivider(t: t),
                _MetricTile(
                  icon: '🌱',
                  value: data.soilMoisture.toStringAsFixed(1),
                  label: tr.get('tileSoil'),
                  accent: t.soilColor,
                  t: t,
                ),
                _VDivider(t: t),
                _MetricTile(
                  icon: '☀️',
                  value: '${data.light.toStringAsFixed(0)} lx',
                  label: tr.get('tileLight'),
                  accent: t.lightColor,
                  t: t,
                ),
              ],
            ),
          ),
          // Timestamp footer — matches "At 2026-04-29 13:55:07"
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: t.latestFooter,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: t.cardBorder, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _formatTime(data.time),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String icon, value, label;
  final Color accent;
  final _T t;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: t.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  final _T t;
  const _VDivider({required this.t});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 52, color: t.cardBorder);
}
