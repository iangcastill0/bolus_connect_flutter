import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/health_profile_sync_service.dart';
import '../services/health_questionnaire_service.dart';
import 'health_questionnaire_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return HealthQuestionnaireService.loadAnswersForUser(user.uid);
  }

  Future<void> refreshProfile() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  Future<void> _editHealthProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final existing =
        await HealthQuestionnaireService.loadAnswersForUser(user.uid);
    if (!context.mounted) return;

    final result = await showHealthQuestionnaireDialog(
      context,
      initialAnswers: existing,
    );
    if (!context.mounted || result == null) return;

    try {
      final answers = Map<String, dynamic>.from(result.answers);
      await HealthQuestionnaireService.saveAnswersForUser(user.uid, answers);
      await HealthProfileSyncService.syncProfile(
        userId: user.uid,
        answers: answers,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Health profile updated.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update health profile: $e')),
      );
    } finally {
      if (mounted) {
        await refreshProfile();
      }
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
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final subtitle = _profileSubtitle(snapshot.data);
              return ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Health profile'),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editHealthProfile(context),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Bolus parameters'),
            onTap: () =>
                Navigator.of(context).pushNamed('/settings/bolus-parameters'),
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

  String _profileSubtitle(Map<String, dynamic>? data) {
    if (data == null) {
      return 'Complete your health profile to personalize insights.';
    }
    final updatedIso = data['updatedAt']?.toString();
    final syncedIso = data['lastSyncedAt']?.toString();
    final buffer = StringBuffer('Last updated ');
    if (updatedIso != null) {
      final updated = DateTime.tryParse(updatedIso);
      if (updated != null) {
        buffer.write(_formatFriendlyDate(updated));
      } else {
        buffer.write('recently');
      }
    } else {
      buffer.write('recently');
    }
    if (syncedIso != null) {
      final synced = DateTime.tryParse(syncedIso);
      if (synced != null) {
        buffer.write(', synced ${_formatFriendlyDate(synced)}');
      }
    }
    return buffer.toString();
  }

  String _formatFriendlyDate(DateTime dt) {
    final local = dt.toLocal();
    final date = '${local.month}/${local.day}/${local.year}';
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '$date at $time';
  }
}
