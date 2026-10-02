// lib/services/ai_service.dart
//
// Single point of contact between the Flutter app and the GreenIQ
// FastAPI RAG backend. This class only talks to FastAPI over HTTP.
// It never touches PostgreSQL, pgvector, embeddings, or the Gemini
// API directly — all of that stays on the Python side.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown by [AiService] on any failure. Carries a clean, user-facing
/// message only — never a raw stack trace or exception detail.
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => message;
}

class AiService {
  // ─────────────────────────────────────────────────────────────────
  // >>> REPLACE THIS with your PC's LAN IPv4 address. <<<
  //
  // On Windows: open Command Prompt, run `ipconfig`, and look for the
  // "IPv4 Address" under the Wi-Fi adapter that your PC and phone are
  // both connected to (e.g. 192.168.1.105).
  //
  // Do NOT use 127.0.0.1 or localhost here — on a physical phone those
  // addresses point back to the phone itself, not your PC.
  // ─────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://192.168.1.7:8000';

  static const Duration _timeout = Duration(seconds: 30);

  /// Sends [question] to `POST /chat` and returns the AI-generated
  /// answer as plain text.
  ///
  /// Throws [AiServiceException] with a clean message for:
  /// - empty question
  /// - connection refused / no network route (server not running,
  ///   wrong IP, different Wi-Fi network)
  /// - timeout
  /// - non-200 server responses (4xx / 5xx)
  /// - malformed / non-JSON response body
  /// - missing or empty "answer" field
  Future<String> askQuestion(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw AiServiceException('Please enter a question before sending.');
    }

    final uri = Uri.parse('$baseUrl/chat');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'question': trimmed}),
          )
          .timeout(_timeout);
    } on SocketException {
      throw AiServiceException(
        'Unable to connect to the GreenIQ AI server.\n'
        'Please check that the AI API is running and that your phone '
        'and PC are connected to the same Wi-Fi network.',
      );
    } on TimeoutException {
      throw AiServiceException(
        'The GreenIQ AI server took too long to respond. '
        'Please try again in a moment.',
      );
    } on HttpException {
      throw AiServiceException(
        'A network error occurred while contacting the GreenIQ AI server.',
      );
    } on FormatException {
      throw AiServiceException(
        'Could not reach the GreenIQ AI server at the configured address.',
      );
    } catch (_) {
      throw AiServiceException(
        'Something went wrong while contacting the GreenIQ AI server.',
      );
    }

    if (response.statusCode == 200) {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw AiServiceException(
          'Received an unexpected response from the GreenIQ AI server.',
        );
      }

      if (data is! Map<String, dynamic>) {
        throw AiServiceException(
          'Received an unexpected response from the GreenIQ AI server.',
        );
      }

      final answer = data['answer'];
      if (answer == null || (answer is String && answer.trim().isEmpty)) {
        throw AiServiceException(
          'The GreenIQ AI server did not return an answer. '
          'Please try rephrasing your question.',
        );
      }

      return answer.toString();
    }

    if (response.statusCode >= 500) {
      throw AiServiceException(
        'The GreenIQ AI server encountered an internal error. '
        'Please try again shortly.',
      );
    }

    if (response.statusCode == 404) {
      throw AiServiceException(
        'The GreenIQ AI server endpoint could not be found. '
        'Please check the server configuration.',
      );
    }

    throw AiServiceException(
      'The GreenIQ AI server returned an unexpected error '
      '(code ${response.statusCode}).',
    );
  }
}
