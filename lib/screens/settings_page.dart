import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.email ?? 'Signed in'),
            subtitle: const Text('Account'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Bolus parameters'),
            onTap: () => Navigator.of(context).pushNamed('/settings/bolus-parameters'),
          ),
          const SizedBox(height: 4),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
