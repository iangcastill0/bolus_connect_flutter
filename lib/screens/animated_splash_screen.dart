import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Animated splash screen shown on cold start
///
/// Features:
/// - Deep blue/graphite gradient background
/// - Lottie animation: droplet falling, rippling, morphing into Time-in-Range ring
/// - Brand wordmark fades in during the last 400ms
/// - Total duration: ~1.2s animation + timing for initialization
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    super.key,
    required this.onComplete,
  });

  /// Callback when splash animation completes
  final VoidCallback onComplete;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wordmarkController;
  late Animation<double> _wordmarkOpacity;

  // Timing constants
  // Animation duration: ~1.2s loop (defined in Lottie JSON)
  static const Duration _wordmarkDelay = Duration(milliseconds: 800);
  static const Duration _wordmarkFadeDuration = Duration(milliseconds: 500);
  static const Duration _totalDuration = Duration(milliseconds: 3000); // 3 seconds for better visibility

  @override
  void initState() {
    super.initState();

    // Debug: Log splash screen start
    debugPrint('🎬 AnimatedSplashScreen: Starting...');

    // Setup wordmark fade-in animation
    _wordmarkController = AnimationController(
      vsync: this,
      duration: _wordmarkFadeDuration,
    );

    _wordmarkOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _wordmarkController,
        curve: Curves.easeIn,
      ),
    );

    // Start wordmark fade-in after delay
    Future.delayed(_wordmarkDelay, () {
      if (mounted) {
        debugPrint('💫 AnimatedSplashScreen: Starting wordmark fade-in');
        _wordmarkController.forward();
      }
    });

    // Complete splash screen after total duration
    Future.delayed(_totalDuration, () {
      if (mounted) {
        debugPrint('✅ AnimatedSplashScreen: Completed, transitioning to app');
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _wordmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e), // Deep blue
              Color(0xFF263238), // Graphite
              Color(0xFF0d47a1), // Medium blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main animation: glucose drop morphing to Time-in-Range ring
            Center(
              child: Opacity(
                opacity: 0.6, // 60% opacity as per spec
                child: Lottie.asset(
                  'assets/animations/glucose_drop_morph.json',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  repeat: true,
                  // Add shimmer highlight effect
                  delegates: LottieDelegates(
                    values: [
                      // Add shimmer effect to specific layers if needed
                    ],
                  ),
                ),
              ),
            ),

            // Brand wordmark with fade-in
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: FadeTransition(
                opacity: _wordmarkOpacity,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App name/logo
                      Text(
                        'Bolus Connect',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline (optional)
                      Text(
                        'Intelligent Insulin Management',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
