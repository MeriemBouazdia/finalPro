import 'package:firebase_database/firebase_database.dart';
import '../core/errors/app_exception.dart';
import '../models/farm_location.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class UserRepository {
  UserRepository({
    required AuthService authService,
    required ApiService apiService,
    FirebaseDatabase? database,
  })  : _authService = authService,
        _apiService = apiService,
        _database = database ?? FirebaseDatabase.instance;

  final AuthService _authService;
  final ApiService _apiService;
  final FirebaseDatabase _database;

  Future<void> registerFarmer({
    required String name,
    required String email,
    required String password,
    required bool hasGreenhouse,
    required FarmLocation farmLocation,
  }) async {
    // Step 1 — Firebase Auth
    final user = await _authService.createUser(
      email: email,
      password: password,
    );

    // Step 2 — REST backend
    final idToken = await _authService.getIdToken(user);
    await _apiService.registerUser(
      idToken: idToken,
      name: name,
      email: email,
      hasGreenhouse: hasGreenhouse,
    );

    // Step 3 — Firebase Realtime Database
    try {
      await _database.ref('users/${user.uid}').set({
        'name': name,
        'email': email,
        'role': 'farmer',
        'status': 'pending',
        'hasGreenhouse': hasGreenhouse,
        'farmLocation': farmLocation.toMap(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      throw AppException('Database error: $e');
    }
  }
}
