import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'welcome_page.dart';
import 'main_tabs_page.dart';
import 'animated_splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _disclaimerAccepted;
  bool _showAnimatedSplash = true;
  bool _splashCompleted = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 AuthGate: Initializing, will show splash first');
    _loadDisclaimer();
  }

  Future<void> _loadDisclaimer() async {
    debugPrint('📋 AuthGate: Loading disclaimer preference');
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('disclaimerAccepted') ?? false;
    debugPrint('📋 AuthGate: Disclaimer accepted = $accepted');

    // Store the value but DON'T trigger setState yet
    // This prevents rebuilds from interrupting the splash screen
    _disclaimerAccepted = accepted;
  }

  void _onSplashComplete() {
    debugPrint('🎯 AuthGate: Splash complete, transitioning to auth flow');
    if (mounted) {
      setState(() {
        _splashCompleted = true;
        _showAnimatedSplash = false;
        // Now it's safe to trigger UI updates since splash is done
        // Force rebuild to show the appropriate screen based on loaded data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show animated splash on cold start (takes priority over everything else)
    if (_showAnimatedSplash && !_splashCompleted) {
      return AnimatedSplashScreen(
        onComplete: _onSplashComplete,
      );
    }

    // After splash completes, check if we're still loading data
    if (_disclaimerAccepted == null) {
      return const _Splash();
    }

    // After splash and data loading, show appropriate screen based on auth state
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

