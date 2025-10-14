import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/guest_session_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ValueListenableBuilder<GuestProfile?>(
            valueListenable: GuestSessionService.instance.profileListenable,
            builder: (context, guestProfile, _) {
              final user = FirebaseAuth.instance.currentUser;
              final isGuest = user == null && guestProfile != null;
              final theme = Theme.of(context);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGuest ? Icons.explore_outlined : Icons.verified_user,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isGuest
                        ? 'Guest mode active'
                        : (user?.email ?? 'Signed in'),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGuest
                        ? 'Data stays on this device until you upgrade to a connected account.'
                        : 'Your data is securely synced to Bolus Connect.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
