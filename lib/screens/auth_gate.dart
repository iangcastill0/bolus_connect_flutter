import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'welcome_page.dart';
import 'main_tabs_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _disclaimerAccepted;

  @override
  void initState() {
    super.initState();
    _loadDisclaimer();
  }

  Future<void> _loadDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _disclaimerAccepted = prefs.getBool('disclaimerAccepted') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    // Wait for onboarding flag to load
    if (_disclaimerAccepted == null) {
      return const _Splash();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final user = snapshot.data;
        if (user != null) {
          // Already signed in -> go straight to main tabs
          return const MainTabsPage();
        }

        // Not signed in
        if (_disclaimerAccepted == true) {
          return const LoginPage();
        }
        return const WelcomePage();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text('Loading...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

