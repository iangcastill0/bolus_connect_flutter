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

    final googleSignIn = GoogleSignIn(scopes: const ['email']);
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw const IdentitySignInAbortedException('Google sign-in aborted');
    }
    final authentication = await account.authentication;
    if (authentication.idToken == null) {
      throw const IdentitySignInException('Missing idToken from Google');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
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
