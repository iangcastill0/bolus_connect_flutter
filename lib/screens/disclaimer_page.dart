import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Disclaimer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Urgent warning banner
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.error, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.error.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Important Safety Warning',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bolus Connect is for educational use only. It does not provide medical advice and is not a substitute for your healthcare provider.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'You are solely responsible for any decisions you make based on the information entered into the app. Always consult your doctor before adjusting insulin doses or making medical decisions.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'By tapping "I Agree", you confirm that you understand and accept these terms.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('disclaimerAccepted', true);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      child: const Text('I Agree'),
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
