import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_identity_service.dart';
import '../services/consent_service.dart';
import '../services/guest_session_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final IdentityAuthService _identityService = const IdentityAuthService();
  final GuestSessionService _guestService = GuestSessionService.instance;
  static const ConsentService _consentService = ConsentService();

  late final AnimationController _controller;
  late final List<Animation<Offset>> _buttonAnimations;

  String? _initError;
  String? _activeFlow; // apple, google, guest

  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _ensureFirebaseInitialized();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _buttonAnimations = List<Animation<Offset>>.generate(4, (index) {
      final start = 0.1 + (index * 0.08);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.45),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      if (mounted) {
        setState(() => _initError = null);
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(
          () => _initError =
              'Firebase is not configured yet. Run flutterfire configure or add platform config files.',
        );
      }
      return false;
    }
  }

  void _handleTitleTap() async {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _lastTapTime = now;
    _tapCount++;

    if (_tapCount >= 7) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset Onboarding'),
          content: const Text(
            'This will reset the disclaimer and onboarding flow. You will be taken back to the welcome screen.\n\nContinue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (!mounted) return;
        await _consentService.clearDisclaimerAcceptance();
        await _guestService.clearGuestProfile();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding reset! Returning to welcome screen...'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

      _tapCount = 0;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signInWithGoogle() async {
    if (!await _ensureFirebaseInitialized()) return;
    setState(() => _activeFlow = 'google');
    try {
      await _identityService.signInWithGoogle();
      await _guestService.clearGuestProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on IdentitySignInAbortedException {
      // User canceled; no feedback needed.
    } catch (e) {
      _showError('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _activeFlow = null);
    }
  }

  Future<void> _signInWithApple() async {
    if (!await _ensureFirebaseInitialized()) return;
    setState(() => _activeFlow = 'apple');
    try {
      await _identityService.signInWithApple();
      await _guestService.clearGuestProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on IdentitySignInAbortedException {
      // User canceled.
    } catch (e) {
      _showError('Apple sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _activeFlow = null);
    }
  }

  Future<void> _startGuestSession() async {
    setState(() => _activeFlow = 'guest');
    try {
      await _guestService.startGuestSession();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      _showError('Unable to start guest mode: $e');
    } finally {
      if (mounted) setState(() => _activeFlow = null);
    }
  }

  Future<void> _showEmailSheet() async {
    final navigator = Navigator.of(context);
    if (!await _ensureFirebaseInitialized()) return;
    if (!mounted) return;
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _EmailAuthSheet(),
    );
    if (!mounted) return;
    if (success == true) {
      await _guestService.clearGuestProfile();
      if (!mounted) return;
      navigator.pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appleSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          behavior: HitTestBehavior.opaque,
          child: const Text('Sign In'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose how you would like to continue.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_initError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _initError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SlideTransition(
                      position: _buttonAnimations[0],
                      child: _IdentityButton(
                        label: 'Continue with Apple',
                        icon: const Icon(Icons.apple),
                        onPressed: !_isFlowActive && appleSupported
                            ? _signInWithApple
                            : null,
                        loading: _activeFlow == 'apple',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlideTransition(
                      position: _buttonAnimations[1],
                      child: _IdentityButton(
                        label: 'Continue with Google',
                        icon: const Icon(Icons.g_mobiledata),
                        onPressed: !_isFlowActive ? _signInWithGoogle : null,
                        loading: _activeFlow == 'google',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlideTransition(
                      position: _buttonAnimations[2],
                      child: _IdentityButton(
                        label: 'Email',
                        icon: const Icon(Icons.email_outlined),
                        onPressed: !_isFlowActive ? _showEmailSheet : null,
                        loading: false,
                        variant: IdentityButtonVariant.tonal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SlideTransition(
                      position: _buttonAnimations[3],
                      child: Center(
                        child: TextButton(
                          onPressed: !_isFlowActive ? _startGuestSession : null,
                          child: _activeFlow == 'guest'
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("I'm just exploring (Guest mode)"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'All sign-in options use secure JWT + PKCE flows. You can upgrade a guest account at any time.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isFlowActive => _activeFlow != null;
}

enum IdentityButtonVariant { filled, tonal }

class _IdentityButton extends StatelessWidget {
  const _IdentityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.variant = IdentityButtonVariant.filled,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool loading;
  final IdentityButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 12),
          Flexible(child: Text(label)),
        ],
      );
    }

    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
    );

    return switch (variant) {
      IdentityButtonVariant.filled => FilledButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      IdentityButtonVariant.tonal => FilledButton.tonal(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    };
  }
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet();

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'Min 6 characters';
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (!_isLogin && _passwordController.text != _confirmController.text) {
      _showSnack('Passwords do not match');
      return;
    }
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        _showSnack('Firebase init failed: $e');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _showSnack(_friendlyAuthError(e));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'internal-error':
        return 'Internal error from Firebase. Try again shortly.';
      default:
        return e.message ?? e.code;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isLogin ? 'Sign in with Email' : 'Create an account',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: _validatePassword,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: _validatePassword,
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLogin ? 'Continue' : 'Create account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? "Don't have an account? Sign up"
                      : 'Have an account? Log in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
