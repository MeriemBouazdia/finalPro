import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../translations.dart';

class DeviceControl extends StatefulWidget {
  final String ghId;

  const DeviceControl({
    super.key,
    required this.ghId,
  });

  @override
  State<DeviceControl> createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  late DatabaseReference _actuatorsRef;
  StreamSubscription<DatabaseEvent>? _actuatorsSubscription;

  final Map<String, bool> _deviceStates = {
    'pump': false,
    'light': false,
    'fan': false,
    'vent': false,
  };

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  void _initializeFirebase() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _error = 'User not authenticated. Please login again.';
        _isLoading = false;
      });
      return;
    }

    // Correct user-centric Firebase path: users/$uid/greenhouses/$ghId/actuators
    _actuatorsRef = FirebaseDatabase.instance
        .ref('users/${user.uid}/greenhouses/${widget.ghId}/actuators');

    _listenToActuators();
  }

  void _listenToActuators() {
    _actuatorsSubscription = _actuatorsRef.onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.value == null) {
          // Initialize default values if no data exists
          _initializeDefaultValues();
          return;
        }

        final data = event.snapshot.value as Map;
        setState(() {
          _deviceStates['pump'] = data['pump'] == true;
          _deviceStates['light'] = data['light'] == true;
          _deviceStates['fan'] = data['fan'] == true;
          _deviceStates['vent'] = data['vent'] == true;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        setState(() {
          _error = 'Failed to load device states: $error';
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _initializeDefaultValues() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Create default actuator states if they don't exist
      await _actuatorsRef.set({
        'pump': false,
        'light': false,
        'fan': false,
        'vent': false,
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize devices: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDevice(String device, bool value) async {
    try {
      // Optimistic update for immediate UI feedback
      setState(() {
        _deviceStates[device] = value;
      });

      // Write to Firebase
      await _actuatorsRef.child(device).set(value);
    } catch (e) {
      // Revert on error
      setState(() {
        _deviceStates[device] = !value;
        _error = 'Failed to update $device: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _actuatorsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _error!.contains('not authenticated')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        SwitchListTile(
          title: Text(tr.get('pump')),
          subtitle: Text(
              _deviceStates['pump'] == true ? tr.get('on') : tr.get('off')),
          value: _deviceStates['pump'] ?? false,
          onChanged: (val) => _updateDevice("pump", val),
          secondary: const Icon(Icons.water_drop),
        ),
        SwitchListTile(
          title: Text(tr.get('lightDevice')),
          subtitle: Text(
              _deviceStates['light'] == true ? tr.get('on') : tr.get('off')),
          value: _deviceStates['light'] ?? false,
          onChanged: (val) => _updateDevice("light", val),
          secondary: const Icon(Icons.lightbulb),
        ),
        SwitchListTile(
          title: Text(tr.get('fan')),
          subtitle:
              Text(_deviceStates['fan'] == true ? tr.get('on') : tr.get('off')),
          value: _deviceStates['fan'] ?? false,
          onChanged: (val) => _updateDevice("fan", val),
          secondary: const Icon(Icons.air),
        ),
        SwitchListTile(
          title: Text(tr.get('heater')),
          subtitle: Text(
              _deviceStates['vent'] == true ? tr.get('on') : tr.get('off')),
          value: _deviceStates['vent'] ?? false,
          onChanged: (val) => _updateDevice("vent", val),
          secondary: const Icon(Icons.window),
        ),
      ],
    );
  }
}
