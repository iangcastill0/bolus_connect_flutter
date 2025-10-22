import 'package:flutter/material.dart';
import '../services/locale_preference_service.dart';

class LocaleSetupPage extends StatefulWidget {
  const LocaleSetupPage({super.key});

  @override
  State<LocaleSetupPage> createState() => _LocaleSetupPageState();
}

class _LocaleSetupPageState extends State<LocaleSetupPage>
    with SingleTickerProviderStateMixin {
  static const LocalePreferenceService _localeService =
      LocalePreferenceService();

  String _selectedLanguage = 'en';
  String _selectedRegion = 'us';
  bool _isAnimating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Map<String, String> _languages = const {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'zh': '中文',
  };

  final Map<String, String> _regions = const {
    'us': 'United States (mg/dL)',
    'uk': 'United Kingdom (mmol/L)',
    'eu': 'Europe (mmol/L)',
    'ca': 'Canada (mmol/L)',
    'au': 'Australia (mmol/L)',
    'mx': 'Mexico (mg/dL)',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _setupPulseAnimation();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadPreferences() async {
    final language = await _localeService.getLanguage();
    final region = await _localeService.getRegion();

    if (mounted) {
      setState(() {
        _selectedLanguage = language;
        _selectedRegion = region;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_isAnimating) return;

    setState(() => _isAnimating = true);

    try {
      await _localeService.setLanguage(_selectedLanguage);
      await _localeService.setRegion(_selectedRegion);
      await _localeService.markSetupCompleted();

      if (!mounted) return;
      // Navigate to welcome page which will then show disclaimer
      Navigator.of(context).pushReplacementNamed('/welcome');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save preferences. Please try again.'),
        ),
      );
      setState(() => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasSelection =
        _selectedLanguage.isNotEmpty && _selectedRegion.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Header
              Column(
                children: [
                  Icon(
                    Icons.public,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's make glucose simple.",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Language Picker
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LanguageDropdown(
                        value: _selectedLanguage,
                        languages: _languages,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLanguage = value);
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Region Picker
                      Text(
                        'Region',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _RegionDropdown(
                        value: _selectedRegion,
                        regions: _regions,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRegion = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Helper text
                      Text(
                        'You can change this later in Settings.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Continue button with pulse animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: hasSelection ? _pulseAnimation.value : 1.0,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: hasSelection && !_isAnimating
                            ? _handleContinue
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isAnimating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.value,
    required this.languages,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> languages;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.primary,
          ),
          dropdownColor: theme.cardColor,
          style: theme.textTheme.bodyLarge,
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(entry.value),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RegionDropdown extends StatelessWidget {
  const _RegionDropdown({
    required this.value,
    required this.regions,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> regions;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.primary,
          ),
          dropdownColor: theme.cardColor,
          style: theme.textTheme.bodyLarge,
          items: regions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
