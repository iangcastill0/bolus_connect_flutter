import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Centralizes social identity flows that back Firebase Authentication.
class IdentityAuthService {
  const IdentityAuthService();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Signs the user in with Google, using PKCE-capable flows on supported
  /// platforms. Returns [UserCredential] on success.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      provider.setCustomParameters(<String, String>{
        'prompt': 'select_account',
      });
      return _auth.signInWithPopup(provider);
    }

    // For Android/iOS, initialize with server client ID from Firebase
    // This is the Web client ID from google-services.json (client_type: 3)
    const serverClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '1000337125532-8c4b58ibs3lm3ev5601141ia03100t37.apps.googleusercontent.com',
    );

    final googleSignIn = GoogleSignIn.instance;

    // Initialize with server client ID for Android
    await googleSignIn.initialize(
      serverClientId: serverClientId,
    );

    final account = await googleSignIn.authenticate(
      scopeHint: const ['email'],
    );
    final authentication = account.authentication;
    if (authentication.idToken == null) {
      throw const IdentitySignInException('Missing idToken from Google');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Signs the user in with Apple using JWT + PKCE via nonce hashing.
  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      final provider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      return _auth.signInWithPopup(provider);
    }

    if (!await SignInWithApple.isAvailable()) {
      throw const IdentitySignInException(
        'Sign in with Apple is not available',
      );
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthCredential(
      providerId: 'apple.com',
      signInMethod: 'oauth',
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );

    return _auth.signInWithCredential(oauthCredential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class IdentitySignInException implements Exception {
  const IdentitySignInException(this.message);
  final String message;

  @override
  String toString() => message;
}

class IdentitySignInAbortedException extends IdentitySignInException {
  const IdentitySignInAbortedException(super.message);
}
