import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pain_area_questionnaire_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, size: 64),
              const SizedBox(height: 12),
              Text(user?.email ?? 'Signed in'),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PainAreaQuestionnairePage()),
                  );
                },
                icon: const Icon(Icons.accessibility_new),
                label: const Text('Pain area questionnaire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
