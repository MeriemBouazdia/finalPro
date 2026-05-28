import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:app/l10n/translations.dart';
import 'widget/theme_provider.dart';

class _ActuatorState {
  final bool pump;
  final bool fan;
  final bool light;
  final bool vent;
  final String mode;

  const _ActuatorState({
    this.pump = false,
    this.fan = false,
    this.light = false,
    this.vent = false,
    this.mode = 'manual',
  });

  factory _ActuatorState.fromStateMap(
    Map<String, dynamic> stateMap,
    String mode,
  ) {
    return _ActuatorState(
      pump: stateMap['pump'] == true,
      fan: stateMap['fan'] == true,
      light: stateMap['light'] == true,
      vent: stateMap['vent'] == true,
      mode: mode,
    );
  }

  _ActuatorState copyWith({
    bool? pump,
    bool? fan,
    bool? light,
    bool? vent,
    String? mode,
  }) {
    return _ActuatorState(
      pump: pump ?? this.pump,
      fan: fan ?? this.fan,
      light: light ?? this.light,
      vent: vent ?? this.vent,
      mode: mode ?? this.mode,
    );
  }

  bool operator ==(Object other) =>
      other is _ActuatorState &&
      other.pump == pump &&
      other.fan == fan &&
      other.light == light &&
      other.vent == vent &&
      other.mode == mode;

  int get hashCode => Object.hash(pump, fan, light, vent, mode);

  static const empty = _ActuatorState();

  @override
  String toString() =>
      'ActuatorState(pump=$pump fan=$fan light=$light vent=$vent mode=$mode)';
}

class DeviceControl extends StatefulWidget {
  final String ghId;
  const DeviceControl({super.key, required this.ghId});

  @override
  State<DeviceControl> createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  late final DatabaseReference _actuatorsRef;
  late final DatabaseReference _stateRef;
  late final DatabaseReference _commandsRef;
  StreamSubscription<DatabaseEvent>? _stateSub;
  StreamSubscription<DatabaseEvent>? _modeSub;

  _ActuatorState _state = _ActuatorState.empty;
  bool _isLoading = true;
  String? _error;

  final Set<String> _pendingWrites = {};
  final Map<String, Timer> _revertTimers = {};
  String _currentMode = 'manual';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _modeSub?.cancel();
    for (final t in _revertTimers.values) t.cancel();
    super.dispose();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'notAuthenticated';
        _isLoading = false;
      });
      return;
    }

    final base = FirebaseDatabase.instance
        .ref('users/${user.uid}/greenhouses/${widget.ghId}/actuators');

    _actuatorsRef = base;
    _stateRef = base.child('state');
    _commandsRef = base.child('commands');

    // ── Listen to state from ESP32
    _stateSub = _stateRef.onValue.listen(
      _onStateChanged,
      onError: _onError,
    );

    _modeSub = base.child('mode').onValue.listen(
          _onModeChanged,
          onError: _onError,
        );
  }

  void _onStateChanged(DatabaseEvent event) {
    final raw = event.snapshot.value;

    if (raw == null) {
      _initializeDefaults();
      return;
    }

    if (raw is! Map) return;

    final parsed = _ActuatorState.fromStateMap(
      Map<String, dynamic>.from(raw),
      _currentMode,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _error = null;

      _state = _ActuatorState(
        pump: _pendingWrites.contains('pump') ? _state.pump : parsed.pump,
        fan: _pendingWrites.contains('fan') ? _state.fan : parsed.fan,
        light: _pendingWrites.contains('light') ? _state.light : parsed.light,
        vent: _pendingWrites.contains('vent') ? _state.vent : parsed.vent,
        mode: _currentMode,
      );
    });
    for (final key in ['pump', 'fan', 'light', 'vent']) {
      final confirmed = _getValueFromParsed(parsed, key);
      final optimistic = _getActuatorValue(key);
      if (confirmed == optimistic && _revertTimers.containsKey(key)) {
        _revertTimers[key]!.cancel();
        _revertTimers.remove(key);
        if (mounted) setState(() => _pendingWrites.remove(key));
        debugPrint('[DeviceControl] ✓ ESP32 confirmed $key=$confirmed');
      }
    }

    debugPrint('[DeviceControl] State from ESP32: $parsed');
  }

  void _onModeChanged(DatabaseEvent event) {
    final modeStr = event.snapshot.value as String? ?? 'manual';
    if (!mounted) return;
    setState(() {
      _currentMode = modeStr;
      _state = _state.copyWith(mode: modeStr);
      _pendingWrites.remove('mode');
    });
    debugPrint('[DeviceControl] Mode → $modeStr');
  }

  void _onError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = error.toString();
      _isLoading = false;
    });
    debugPrint('[DeviceControl] Stream error: $error');
  }

  Future<void> _initializeDefaults() async {
    debugPrint('[DeviceControl] Initializing Firebase defaults');
    try {
      await _actuatorsRef.child('mode').set('manual');
      await _commandsRef.set({
        'pump': false,
        'fan': false,
        'light': false,
        'vent': false,
      });
      await _stateRef.set({
        'pump': false,
        'fan': false,
        'light': false,
        'vent': false,
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to initialize: $e');
    }
  }

  // TOGGLE ACTUATOR — MANUAL MODE ONLY
  Future<void> _toggleActuator(String key, bool newValue) async {
    if (_pendingWrites.contains(key)) return;

    final previousValue = _getActuatorValue(key);
    debugPrint('[DeviceControl] Toggle $key: $previousValue → $newValue');

    // Optimistic update
    setState(() {
      _pendingWrites.add(key);
      _state = _applyKey(_state, key, newValue);
    });

    //Schedule revert if ESP32 doesn't confirm within 5 seconds
    _revertTimers[key]?.cancel();
    _revertTimers[key] = Timer(const Duration(seconds: 5), () {
      if (mounted && _pendingWrites.contains(key)) {
        debugPrint('[DeviceControl] ⚠ Revert $key (no ESP32 confirmation)');
        setState(() {
          _state = _applyKey(_state, key, previousValue);
          _pendingWrites.remove(key);
          _error = 'No response from device for $key';
        });
        _showSnack('Device did not respond. Try again.');
      }
    });

    try {
      await _commandsRef.child(key).set(newValue);
      debugPrint('[DeviceControl] Command written: $key=$newValue');
      // Confirmation comes via _onStateChanged → cancels revert timer
    } catch (e) {
      // Firebase write itself failed — revert immediately
      _revertTimers[key]?.cancel();
      _revertTimers.remove(key);
      if (mounted) {
        setState(() {
          _state = _applyKey(_state, key, previousValue);
          _pendingWrites.remove(key);
          _error = 'Write failed: $e';
        });
        _showSnack('Failed to toggle $key. Check connection.');
      }
      debugPrint('[DeviceControl] Write error: $e');
    }
  }

  Future<void> _toggleMode(bool goAutomatic) async {
    if (_pendingWrites.contains('mode')) return;

    final newMode = goAutomatic ? 'automatic' : 'manual';
    final previousMode = _currentMode;

    setState(() {
      _pendingWrites.add('mode');
      _currentMode = newMode;
      _state = _state.copyWith(mode: newMode);
    });

    try {
      if (!goAutomatic) {
        await _commandsRef.set({
          'pump': _state.pump,
          'fan': _state.fan,
          'light': _state.light,
          'vent': _state.vent,
        });
        debugPrint('[DeviceControl] Seeded commands/ with current state');
      }

      await _actuatorsRef.child('mode').set(newMode);
      debugPrint('[DeviceControl] Mode set to $newMode');
      // _pendingWrites.remove('mode') happens in _onModeChanged
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentMode = previousMode;
          _state = _state.copyWith(mode: previousMode);
          _pendingWrites.remove('mode');
          _error = 'Failed to switch mode';
        });
        _showSnack('Failed to switch mode. Check connection.');
      }
      debugPrint('[DeviceControl] Mode error: $e');
    }
  }

  bool _getActuatorValue(String key) {
    switch (key) {
      case 'pump':
        return _state.pump;
      case 'fan':
        return _state.fan;
      case 'light':
        return _state.light;
      case 'vent':
        return _state.vent;
      default:
        return false;
    }
  }

  bool _getValueFromParsed(_ActuatorState s, String key) {
    switch (key) {
      case 'pump':
        return s.pump;
      case 'fan':
        return s.fan;
      case 'light':
        return s.light;
      case 'vent':
        return s.vent;
      default:
        return false;
    }
  }

  _ActuatorState _applyKey(_ActuatorState s, String key, bool v) {
    switch (key) {
      case 'pump':
        return s.copyWith(pump: v);
      case 'fan':
        return s.copyWith(fan: v);
      case 'light':
        return s.copyWith(light: v);
      case 'vent':
        return s.copyWith(vent: v);
      default:
        return s;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    if (_error == 'notAuthenticated') {
      return _ErrorBanner(
        icon: Icons.lock_outline,
        message: tr.get('pleaseLoginFirst'),
        color: Colors.red,
      );
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isAutomatic = _state.mode == 'automatic';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Error banner
          if (_error != null && _error != 'notAuthenticated')
            _ErrorBanner(
              icon: Icons.warning_amber_rounded,
              message: _error!,
              color: Colors.orange,
            ),

          //Mode toggle
          _ModeToggle(
            isAutomatic: isAutomatic,
            isPending: _pendingWrites.contains('mode'),
            isDarkMode: isDarkMode,
            tr: tr,
            onChanged: _toggleMode,
          ),

          const Divider(height: 1),

          //Actuator tiles
          _ActuatorTile(
            label: tr.get('pump'),
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            value: _state.pump,
            enabled: !isAutomatic && !_pendingWrites.contains('pump'),
            isPending: _pendingWrites.contains('pump'),
            isDarkMode: isDarkMode,
            tr: tr,
            onChanged: (v) => _toggleActuator('pump', v),
          ),
          _ActuatorTile(
            label: tr.get('lightDevice'),
            icon: Icons.lightbulb,
            iconColor: Colors.amber,
            value: _state.light,
            enabled: !isAutomatic && !_pendingWrites.contains('light'),
            isPending: _pendingWrites.contains('light'),
            isDarkMode: isDarkMode,
            tr: tr,
            onChanged: (v) => _toggleActuator('light', v),
          ),
          _ActuatorTile(
            label: tr.get('fan'),
            icon: Icons.air,
            iconColor: Colors.cyan,
            value: _state.fan,
            enabled: !isAutomatic && !_pendingWrites.contains('fan'),
            isPending: _pendingWrites.contains('fan'),
            isDarkMode: isDarkMode,
            tr: tr,
            onChanged: (v) => _toggleActuator('fan', v),
          ),
          _ActuatorTile(
            label: tr.get('vent'),
            icon: Icons.window,
            iconColor: Colors.teal,
            value: _state.vent,
            enabled: !isAutomatic && !_pendingWrites.contains('vent'),
            isPending: _pendingWrites.contains('vent'),
            isDarkMode: isDarkMode,
            tr: tr,
            onChanged: (v) => _toggleActuator('vent', v),
          ),

          //Auto mode hint
          if (isAutomatic)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14,
                      color: isDarkMode ? Colors.white38 : Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr.get('automaticModeHint'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white38 : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isAutomatic;
  final bool isPending;
  final bool isDarkMode;
  final dynamic tr;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.isAutomatic,
    required this.isPending,
    required this.isDarkMode,
    required this.tr,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            isAutomatic ? Icons.auto_mode : Icons.touch_app,
            color: isAutomatic
                ? const Color(0xFF336A29)
                : (isDarkMode ? Colors.white54 : Colors.grey[600]),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.get('controlMode'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  isAutomatic ? tr.get('automaticMode') : tr.get('manualMode'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          isPending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: isAutomatic,
                  activeColor: const Color(0xFF336A29),
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }
}

class _ActuatorTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final bool enabled;
  final bool isPending;
  final bool isDarkMode;
  final dynamic tr;
  final ValueChanged<bool> onChanged;

  const _ActuatorTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.enabled,
    required this.isPending,
    required this.isDarkMode,
    required this.tr,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white54 : Colors.grey[600];

    return ListTile(
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? iconColor.withValues(alpha: 0.15)
              : (isDarkMode
                  ? Colors.white10
                  : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color:
              value ? iconColor : (isDarkMode ? Colors.white38 : Colors.grey),
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled ? labelColor : labelColor.withValues(alpha: 0.4),
        ),
      ),
      subtitle: Text(
        value ? tr.get('on') : tr.get('off'),
        style: TextStyle(
          fontSize: 12,
          color: value ? iconColor : (subtitleColor ?? Colors.grey),
        ),
      ),
      trailing: isPending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: value,
              activeColor: iconColor,
              onChanged: enabled ? onChanged : null,
            ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _ErrorBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
