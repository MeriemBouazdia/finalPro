import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'notification.dart';

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool? _toBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v.toLowerCase() == 'true';
  return null;
}

class MonitoringService {
  final String uid;
  final String ghId;

  MonitoringService({required this.uid, required this.ghId});

  final List<StreamSubscription<DatabaseEvent>> _subs = [];

  // Last-seen values – used to suppress duplicate notifications
  double? _lastTemp;
  double? _lastSoil;
  bool? _lastPump;
  bool? _lastFan;
  bool? _lastVent;
  bool? _lastLight;
  DatabaseReference get _base =>
      FirebaseDatabase.instance.ref('users/$uid/greenhouses/$ghId');

  DatabaseReference get _sensors => _base.child('sensors');
  DatabaseReference get _targets => _base.child('targets');
  DatabaseReference get _actState => _base.child('actuators/state');

  Future<void> start() async {
    await NotificationService().initialize();
    _listenSensors();
    _listenActuators();
    debugPrint('[MonitoringService] Started for gh=$ghId');
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    debugPrint('[MonitoringService] Disposed for gh=$ghId');
  }

  void _listenSensors() {
    final sub = _sensors.onValue.listen(
      (event) async {
        final raw = event.snapshot.value;
        if (raw == null || raw is! Map) return;

        final sensors = Map<String, dynamic>.from(raw);

        final temp = _extractSensorValue(sensors['temperature']);
        final soil = _extractSensorValue(sensors['soil']);

        // Fetch targets on every sensor change (lightweight single read)
        final targetsSnap = await _targets.get();
        if (!targetsSnap.exists || targetsSnap.value == null) return;

        final targets = Map<String, dynamic>.from(targetsSnap.value as Map);
        final targetTemp =
            _toDouble(targets['temperature'], fallback: double.infinity);
        final targetSoil =
            _toDouble(targets['soil'], fallback: double.infinity);

        await _checkTemperature(temp, targetTemp);
        await _checkSoil(soil, targetSoil);
      },
      onError: (e) => debugPrint('[MonitoringService] sensors error: $e'),
    );
    _subs.add(sub);
  }

  double _extractSensorValue(dynamic node) {
    if (node == null) return 0.0;
    if (node is Map) {
      final m = Map<String, dynamic>.from(node);
      if (m.containsKey('value')) return _toDouble(m['value']);
      // Nested: { sensorId: { value: x } }
      for (final child in m.values) {
        if (child is Map && child.containsKey('value')) {
          return _toDouble(child['value']);
        }
      }
    }
    return _toDouble(node);
  }

  Future<void> _checkTemperature(double temp, double targetTemp) async {
    // Only notify on value change
    if (temp == _lastTemp) return;
    _lastTemp = temp;

    if (temp > targetTemp) {
      await NotificationService().showSensorAlert(
        id: NotificationService.idTempAlert,
        title: '🌡️ High Temperature Alert',
        body:
            'Temperature is ${temp.toStringAsFixed(1)}°C — target is ${targetTemp.toStringAsFixed(1)}°C.',
      );
    } else {
      // Condition cleared — reset cooldown so the next breach fires immediately
      NotificationService().resetCooldown(NotificationService.idTempAlert);
    }
  }

  Future<void> _checkSoil(double soil, double targetSoil) async {
    if (soil == _lastSoil) return;
    _lastSoil = soil;

    if (soil > targetSoil) {
      await NotificationService().showSensorAlert(
        id: NotificationService.idSoilAlert,
        title: 'Soil Moisture Alert',
        body:
            'Soil reading is ${soil.toStringAsFixed(0)} — target is ${targetSoil.toStringAsFixed(0)}.',
      );
    } else {
      NotificationService().resetCooldown(NotificationService.idSoilAlert);
    }
  }

  //  Actuator monitoring

  void _listenActuators() {
    final sub = _actState.onValue.listen(
      (event) async {
        final raw = event.snapshot.value;
        if (raw == null || raw is! Map) return;

        final state = Map<String, dynamic>.from(raw);

        await _checkActuator(
          key: 'pump',
          current: _toBool(state['pump']),
          previous: _lastPump,
          id: NotificationService.idPump,
          onLabel: ' Pump Activated',
          offLabel: ' Pump Deactivated',
        );
        _lastPump = _toBool(state['pump']);

        await _checkActuator(
          key: 'fan',
          current: _toBool(state['fan']),
          previous: _lastFan,
          id: NotificationService.idFan,
          onLabel: ' Fan Turned ON',
          offLabel: ' Fan Turned OFF',
        );
        _lastFan = _toBool(state['fan']);

        await _checkActuator(
          key: 'vent',
          current: _toBool(state['vent']),
          previous: _lastVent,
          id: NotificationService.idVent,
          onLabel: ' Vent Opened',
          offLabel: ' Vent Closed',
        );
        _lastVent = _toBool(state['vent']);

        await _checkActuator(
          key: 'light',
          current: _toBool(state['light']),
          previous: _lastLight,
          id: NotificationService.idLight,
          onLabel: ' Light Turned ON',
          offLabel: ' Light Turned OFF',
        );
        _lastLight = _toBool(state['light']);
      },
      onError: (e) => debugPrint('[MonitoringService] actuators error: $e'),
    );
    _subs.add(sub);
  }

  Future<void> _checkActuator({
    required String key,
    required bool? current,
    required bool? previous,
    required int id,
    required String onLabel,
    required String offLabel,
  }) async {
    if (current == null) return;
    // Skip on first event if we have no previous state (app just opened)
    // — remove the guard below if you want startup notifications too.
    if (previous == null) return;
    // Skip if unchanged
    if (current == previous) return;

    final title = current ? onLabel : offLabel;
    final body = current
        ? 'Device was turned ON by the system or a manual command.'
        : 'Device was turned OFF by the system or a manual command.';

    // Actuator events use a very short cooldown (5 s) because
    // each physical state change is meaningful.
    NotificationService().resetCooldown(id);

    await NotificationService().showActuatorNotification(
      id: id,
      title: title,
      body: body,
    );

    debugPrint('[MonitoringService] Actuator $key → $current  ($title)');
  }
}
