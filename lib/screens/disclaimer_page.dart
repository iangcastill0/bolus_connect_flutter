import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/consent_service.dart';

class DisclaimerPage extends StatefulWidget {
  const DisclaimerPage({super.key});

  @override
  State<DisclaimerPage> createState() => _DisclaimerPageState();
}

class _DisclaimerPageState extends State<DisclaimerPage> {
  static const ConsentService _consentService = ConsentService();
  final PageController _pageController = PageController();
  final List<_DisclaimerCardData> _cards = const [
    _DisclaimerCardData(
      title: 'Not a diagnostic device',
      description:
          'Bolus Connect provides educational guidance only. It does not diagnose, treat, or replace advice from your licensed healthcare team.',
      icon: Icons.health_and_safety_rounded,
    ),
    _DisclaimerCardData(
      title: 'Emergency guidance',
      description:
          'In an emergency, immediately contact your local medical services. Do not rely on this app for urgent instructions or emergency care.',
      icon: Icons.local_phone_rounded,
    ),
    _DisclaimerCardData(
      title: 'Data privacy',
      description:
          'Your data is handled with HIPAA/GDPR-grade safeguards. Review your sharing settings and keep your device secure to protect sensitive information.',
      icon: Icons.verified_user_rounded,
    ),
  ];

  bool _hasViewedAllCards = false;
  bool _hasWaitedMinimumTime = false;
  bool _saving = false;
  int _currentPage = 0;
  Timer? _dwellTimer;

  @override
  void initState() {
    super.initState();
    _startDwellTimer();
  }

  void _startDwellTimer() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _hasWaitedMinimumTime = true);
    });
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool get _canAcknowledge =>
      _hasViewedAllCards && _hasWaitedMinimumTime && !_saving;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      if (index >= _cards.length - 1) {
        _hasViewedAllCards = true;
      }
    });
  }

  Future<void> _handleAccept() async {
    if (!_canAcknowledge) {
      return;
    }

    setState(() => _saving = true);

    try {
      await HapticFeedback.selectionClick();
      await _consentService.recordDisclaimerAcceptance();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your acknowledgement. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Safety & Medical Disclaimer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Swipe through each card to review critical safety information before proceeding.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _cards.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) =>
                      _DisclaimerCard(data: _cards[index]),
                ),
              ),
              const SizedBox(height: 16),
              _PageIndicator(currentIndex: _currentPage, length: _cards.length),
              const SizedBox(height: 16),
              _RequirementHint(
                hasViewedAllCards: _hasViewedAllCards,
                hasWaitedMinimumTime: _hasWaitedMinimumTime,
                isReady: _canAcknowledge,
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canAcknowledge ? _handleAccept : null,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('I Understand'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementHint extends StatelessWidget {
  const _RequirementHint({
    required this.hasViewedAllCards,
    required this.hasWaitedMinimumTime,
    required this.isReady,
  });

  final bool hasViewedAllCards;
  final bool hasWaitedMinimumTime;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isReady) {
      return Text(
        'Thank you for reviewing the safety information.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      );
    }

    final List<String> pending = [];
    if (!hasViewedAllCards) {
      pending.add('view each card');
    }
    if (!hasWaitedMinimumTime) {
      pending.add('take a brief moment (4 seconds) to read');
    }

    return Text(
      'To continue, please ${pending.join(' and ')}.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _DisclaimerCardData {
  const _DisclaimerCardData({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.data});

  final _DisclaimerCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                data.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                data.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentIndex, required this.length});

  final int currentIndex;
  final int length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
