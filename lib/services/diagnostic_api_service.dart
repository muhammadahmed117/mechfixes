import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mechfixes/core/config/diagnostic_api_config.dart';

/// Response from POST /api/diagnose
class DiagnosticResult {
  const DiagnosticResult({
    required this.predictedFault,
    required this.aiAdviceEnglish,
    required this.aiAdviceRomanUrdu,
  });

  final String predictedFault;
  final String aiAdviceEnglish;
  final String aiAdviceRomanUrdu;

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      predictedFault: _stringOrDefault(json['predicted_fault'], 'Unknown fault'),
      aiAdviceEnglish: _stringOrDefault(json['ai_advice_english'], ''),
      aiAdviceRomanUrdu: _stringOrDefault(json['ai_advice_roman_urdu'], ''),
    );
  }

  static String _stringOrDefault(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class DiagnosticApiException implements Exception {
  DiagnosticApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Calls the local FastAPI AI diagnostic backend.
class DiagnosticApiService {
  DiagnosticApiService({http.Client? client, String? diagnoseUrl})
      : _client = client ?? http.Client(),
        _diagnoseUrl = diagnoseUrl ?? DiagnosticApiConfig.diagnoseUrl;

  final http.Client _client;
  final String _diagnoseUrl;

  Future<DiagnosticResult> diagnose(String symptoms) async {
    final trimmed = symptoms.trim();
    if (trimmed.isEmpty) {
      throw DiagnosticApiException('Please describe your car symptoms first.');
    }

    final uri = Uri.parse(_diagnoseUrl);

    try {
      debugPrint('[DiagnosticApi] POST $uri');
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'symptoms': trimmed}),
          )
          .timeout(const Duration(seconds: 120));

      debugPrint('[DiagnosticApi] Response ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw DiagnosticApiException(
            'Invalid response format: expected a JSON object.',
          );
        }
        return DiagnosticResult.fromJson(decoded);
      }

      final detail = _extractErrorDetail(response);
      throw DiagnosticApiException('Server error (${response.statusCode}): $detail');
    } on DiagnosticApiException catch (error, stackTrace) {
      _logError('Request failed', error, stackTrace);
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      final message =
          'Request timed out. The AI server may still be loading models — '
          'wait 30 seconds after starting the server, then try again.';
      _logError(message, error, stackTrace);
      throw DiagnosticApiException(message);
    } on SocketException catch (error, stackTrace) {
      final message =
          'Cannot connect to $_diagnoseUrl. '
          'Ensure start_server.bat is running on your PC.';
      _logError(message, error, stackTrace);
      throw DiagnosticApiException(message);
    } on http.ClientException catch (error, stackTrace) {
      final message =
          'Network error reaching $_diagnoseUrl: ${error.message}';
      _logError(message, error, stackTrace);
      throw DiagnosticApiException(message);
    } on FormatException catch (error, stackTrace) {
      const message = 'Received an invalid JSON response from the diagnostic server.';
      _logError(message, error, stackTrace);
      throw DiagnosticApiException(message);
    } catch (error, stackTrace) {
      final message = 'Unexpected error calling diagnostic API: $error';
      _logError(message, error, stackTrace);
      throw DiagnosticApiException(message);
    }
  }

  String _extractErrorDetail(http.Response response) {
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map<String, dynamic> && errorBody['detail'] != null) {
        final rawDetail = errorBody['detail'];
        if (rawDetail is String) return rawDetail;
        if (rawDetail is List) {
          return rawDetail
              .map((item) {
                if (item is Map && item['msg'] != null) {
                  final loc = item['loc'];
                  final field = loc is List && loc.isNotEmpty
                      ? loc.last.toString()
                      : 'request';
                  return '$field: ${item['msg']}';
                }
                return item.toString();
              })
              .join('\n');
        }
        return rawDetail.toString();
      }
    } catch (_) {}

    return response.body.isNotEmpty ? response.body : 'No details provided';
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    debugPrint('[DiagnosticApi] ERROR: $message');
    debugPrint('[DiagnosticApi] URL: $_diagnoseUrl');
    debugPrint('[DiagnosticApi] Exception: $error');
    developer.log(
      message,
      name: 'DiagnosticApiService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void dispose() => _client.close();
}
