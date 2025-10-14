import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight representation of an ephemeral guest profile.
class GuestProfile {
  const GuestProfile({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;
}

/// Handles lifecycle for guest sessions that live entirely on-device.
class GuestSessionService {
  GuestSessionService._();

  static final GuestSessionService instance = GuestSessionService._();

  static const _activeKey = 'guestProfileActive';
  static const _idKey = 'guestProfileId';
  static const _createdAtKey = 'guestProfileCreatedAt';

  final ValueNotifier<GuestProfile?> _profileNotifier =
      ValueNotifier<GuestProfile?>(null);

  ValueListenable<GuestProfile?> get profileListenable => _profileNotifier;

  Future<GuestProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_activeKey) ?? false;
    if (!isActive) {
      _profileNotifier.value = null;
      return null;
    }
    final id = prefs.getString(_idKey);
    final createdAtRaw = prefs.getString(_createdAtKey);
    if (id == null || createdAtRaw == null) {
      await clearGuestProfile();
      return null;
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      await clearGuestProfile();
      return null;
    }
    final profile = GuestProfile(id: id, createdAt: createdAt);
    _profileNotifier.value = profile;
    return profile;
  }

  Future<GuestProfile> startGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = GuestProfile(id: _generateId(), createdAt: DateTime.now());
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_idKey, profile.id);
    await prefs.setString(_createdAtKey, profile.createdAt.toIso8601String());
    _profileNotifier.value = profile;
    return profile;
  }

  Future<void> clearGuestProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
    await prefs.remove(_idKey);
    await prefs.remove(_createdAtKey);
    _profileNotifier.value = null;
  }

  bool get isGuestActive => _profileNotifier.value != null;

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
