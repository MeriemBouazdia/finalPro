import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../models/farm_location.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> registerUser({
    required String idToken,
    required String name,
    required String email,
    required bool hasGreenhouse,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/users');

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'hasGreenhouse': hasGreenhouse,
        }),
      );

      if (response.statusCode != 201) {
        final body = _tryDecode(response.body);
        final serverError = body['error'] as String? ?? 'Registration failed';
        throw AppException(serverError);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Network error: $e');
    }
  }

  /// Registers a farmer with full details including farm location.
  ///
  /// [idToken] — Firebase ID token for auth header.
  /// Throws [AppException] if the server returns a non-201 status.
  Future<void> registerFarmer({
    required String idToken,
    required String name,
    required String email,
    required String password,
    required bool hasGreenhouse,
    required FarmLocation farmLocation,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/farmers/register');

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'hasGreenhouse': hasGreenhouse,
          'farmLocation': farmLocation.toJson(),
        }),
      );

      if (response.statusCode != 201) {
        final body = _tryDecode(response.body);
        final serverError = body['error'] as String? ?? 'Registration failed';
        throw AppException(serverError);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Network error: $e');
    }
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
