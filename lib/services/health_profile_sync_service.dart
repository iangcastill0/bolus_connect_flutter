import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'health_questionnaire_service.dart';

class HealthProfileSyncService {
  HealthProfileSyncService._();

  static const String _endpoint = String.fromEnvironment(
    'HEALTH_PROFILE_ENDPOINT',
    defaultValue: '',
  );

  static Uri? get _endpointUri {
    if (_endpoint.isEmpty) return null;
    return Uri.tryParse(_endpoint);
  }

  /// Attempts to push the latest [answers] for [userId] to the configured backend.
  ///
  /// On success the local cache is marked as synced; in debug builds failures
  /// are logged but otherwise ignored so they can be retried later.
  static Future<void> syncProfile({
    required String userId,
    required Map<String, dynamic> answers,
  }) async {
    final uri = _endpointUri;
    if (uri == null) {
      if (kDebugMode) {
        debugPrint(
          'HealthProfileSyncService: HEALTH_PROFILE_ENDPOINT not set; skipping sync.',
        );
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final payload = <String, dynamic>{
        'userId': userId,
        'profile': answers,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await HealthQuestionnaireService.markSynced(userId);
        if (kDebugMode) {
          debugPrint(
            'HealthProfileSyncService: profile synced successfully (${response.statusCode}).',
          );
        }
      } else {
        throw Exception('Unexpected status code ${response.statusCode}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            'HealthProfileSyncService: failed to sync profile -> $e\n$st');
      }
    }
  }
}
