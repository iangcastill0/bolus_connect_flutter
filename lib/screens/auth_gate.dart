import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'welcome_page.dart';
import 'main_tabs_page.dart';
import 'animated_splash_screen.dart';
import 'locale_setup_page.dart';
import '../services/consent_service.dart';
import '../services/guest_session_service.dart';
import '../services/locale_preference_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _disclaimerAccepted;
  bool? _localeSetupCompleted;
  bool _showAnimatedSplash = true;
  bool _splashCompleted = false;
  static const ConsentService _consentService = ConsentService();
  static const LocalePreferenceService _localeService =
      LocalePreferenceService();
  final GuestSessionService _guestService = GuestSessionService.instance;
  GuestProfile? _guestProfile;
  VoidCallback? _guestListener;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 AuthGate: Initializing, will show splash first');
    _guestListener = () {
      if (!mounted) return;
      setState(() => _guestProfile = _guestService.profileListenable.value);
    };
    _guestService.profileListenable.addListener(_guestListener!);
    _loadDisclaimer();
  }

  @override
  void dispose() {
    if (_guestListener != null) {
      _guestService.profileListenable.removeListener(_guestListener!);
    }
    super.dispose();
  }

  Future<void> _loadDisclaimer() async {
    debugPrint('📋 AuthGate: Loading disclaimer preference');
    final accepted = await _consentService.hasAcceptedLatestDisclaimer();
    debugPrint('📋 AuthGate: Disclaimer accepted (latest version) = $accepted');
    final localeSetup = await _localeService.hasCompletedSetup();
    debugPrint('🌍 AuthGate: Locale setup completed = $localeSetup');
    final guest = await _guestService.loadProfile();

    // Store the value but DON'T trigger setState yet
    // This prevents rebuilds from interrupting the splash screen
    _disclaimerAccepted = accepted;
    _localeSetupCompleted = localeSetup;
    _guestProfile = guest;
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
      return AnimatedSplashScreen(onComplete: _onSplashComplete);
    }

    // After splash completes, check if we're still loading data
    if (_disclaimerAccepted == null || _localeSetupCompleted == null) {
      return const _Splash();
    }

    // After splash and data loading, show appropriate screen based on auth state
    if (_guestProfile != null && _disclaimerAccepted == true) {
      return const MainTabsPage();
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

        // Not signed in - check onboarding flow
        // Step 1: Show welcome page if not started
        // Step 2: Show locale setup if welcome page was accepted but locale not set
        // Step 3: Show disclaimer if locale is set but disclaimer not accepted
        // Step 4: Show login page if everything is accepted
        if (_disclaimerAccepted == true) {
          return const LoginPage();
        }

        if (_localeSetupCompleted == true) {
          // Locale setup done, but disclaimer not yet accepted
          return const WelcomePage();
        }

        // Nothing completed yet, start with locale setup
        return const LocaleSetupPage();
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
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text('Loading...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
