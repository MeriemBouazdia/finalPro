// lib/services/notification.dart
//
// Drop-in replacement that matches your existing main.dart usage:
//   await NotificationService().initialize();
//
// The class uses a module-level singleton internally so that
// MonitoringService can always call NotificationService() and get
// the same already-initialised instance, regardless of how many
// times the constructor is called.
//
// pubspec.yaml dependency:
//   flutter_local_notifications: ^17.0.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Module-level singleton state ──────────────────────────────────────────

final _NotificationState _state = _NotificationState();

class _NotificationState {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  /// Per-notification-id last-fired timestamp (for cooldown).
  final Map<int, DateTime> lastFired = {};

  bool initialized = false;
}

// ─── Public class ──────────────────────────────────────────────────────────

class NotificationService {
  // Public factory constructor — always returns the same backing state,
  // so `NotificationService()` is safe to call anywhere.
  const NotificationService();

  // ── Notification IDs ─────────────────────────────────────────────────────
  static const int idTempAlert = 1;
  static const int idSoilAlert = 2;
  static const int idPump = 10;
  static const int idFan = 11;
  static const int idVent = 12;
  static const int idLight = 13;

  // ── Channel IDs ──────────────────────────────────────────────────────────
  static const String _channelSensor = 'greenhouse_sensors';
  static const String _channelActuator = 'greenhouse_actuators';

  /// Cooldown in seconds between repeat notifications for the same id.
  static const int _cooldownSeconds = 60;

  // ─────────────────────────────────────────────────────────────────────────
  //  initialize  (called once in main.dart)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_state.initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _state.plugin.initialize(settings);

    // Android 13+ runtime permission
    if (Platform.isAndroid) {
      final impl = _state.plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestNotificationsPermission();
    }

    // iOS permission
    if (Platform.isIOS) {
      final impl = _state.plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await impl?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _state.initialized = true;
    debugPrint('[NotificationService] initialized');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Public helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Sensor threshold alerts (temperature, soil moisture).
  Future<void> showSensorAlert({
    required int id,
    required String title,
    required String body,
  }) =>
      _show(
        id: id,
        title: title,
        body: body,
        channelId: _channelSensor,
        channelName: 'Sensor Alerts',
      );

  /// Actuator ON / OFF state-change notifications.
  Future<void> showActuatorNotification({
    required int id,
    required String title,
    required String body,
  }) =>
      _show(
        id: id,
        title: title,
        body: body,
        channelId: _channelActuator,
        channelName: 'Device Notifications',
      );

  /// Remove the cooldown entry for [id] so the next call fires immediately.
  /// Used by MonitoringService after an alert condition clears or a real
  /// actuator state change occurs.
  void resetCooldown(int id) => _state.lastFired.remove(id);

  // ─────────────────────────────────────────────────────────────────────────
  //  Internal
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    // Lazy init guard (in case MonitoringService fires before main finishes)
    if (!_state.initialized) await initialize();

    // Cooldown check
    final now = DateTime.now();
    final last = _state.lastFired[id];
    if (last != null && now.difference(last).inSeconds < _cooldownSeconds) {
      debugPrint('[NotificationService] Skipping #$id – still in cooldown');
      return;
    }
    _state.lastFired[id] = now;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _state.plugin.show(id, title, body, details);
    debugPrint('[NotificationService] Fired #$id – $title');
  }
}
