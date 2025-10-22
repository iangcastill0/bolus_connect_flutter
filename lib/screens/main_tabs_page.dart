import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'logs_page.dart';
import 'bolus_page.dart';
import 'settings_page.dart';
import '../services/health_profile_sync_service.dart';
import '../services/health_questionnaire_service.dart';
import 'health_questionnaire_dialog.dart';
import 'profile_summary_page.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _index = 0;
  final ValueNotifier<int> _bolusRefreshTick = ValueNotifier<int>(0);
  final ValueNotifier<int> _logsRefreshTick = ValueNotifier<int>(0);
  final ValueNotifier<int> _homeRefreshTick = ValueNotifier<int>(0);
  final GlobalKey<SettingsPageState> _settingsPageKey =
      GlobalKey<SettingsPageState>();
  bool _openedBolusAfterProfile = false;
  bool _promptHandledThisSession = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(refreshTick: _homeRefreshTick),
      LogsPage(refreshTick: _logsRefreshTick),
      BolusPage(
          refreshTick: _bolusRefreshTick, logRefreshTick: _logsRefreshTick),
      SettingsPage(key: _settingsPageKey),
    ];
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybePromptQuestionnaire());
  }

  @override
  void dispose() {
    _bolusRefreshTick.dispose();
    _logsRefreshTick.dispose();
    _homeRefreshTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 0) {
            _homeRefreshTick.value++;
          } else if (i == 2) {
            _bolusRefreshTick.value++;
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Insights'),
          NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: 'Bolus'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }

  Future<void> _saveBaselineMetrics(
      String userId, ProfileMetrics metrics) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'baseline_metrics_$userId';
    final data = metrics.toMap();
    await prefs.setString(key, data.toString());
  }

  Future<void> _maybePromptQuestionnaire() async {
    if (!mounted) return;
    if (_promptHandledThisSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final alreadyCompleted =
        await HealthQuestionnaireService.isCompletedForUser(user.uid);
    if (!mounted) return;

    // Only prompt if the user hasn't completed the questionnaire yet
    if (alreadyCompleted) return;

    // Load any previously saved draft answers
    final initialAnswers = await HealthQuestionnaireService.loadAnswersForUser(user.uid);
    if (!mounted) return;

    final result = await showHealthQuestionnaireDialog(
      context,
      allowCancel: false,
      initialAnswers: initialAnswers,
    );

    if (kDebugMode) {
      print('Questionnaire result: ${result != null ? "received" : "null"}');
    }

    if (!mounted) return;
    if (result == null) return;

    await HealthQuestionnaireService.saveAnswersForUser(
        user.uid, Map<String, dynamic>.from(result.answers));
    await HealthProfileSyncService.syncProfile(
      userId: user.uid,
      answers: result.answers,
    );
    _settingsPageKey.currentState?.refreshProfile();
    if (!mounted) return;

    _promptHandledThisSession = true;

    // Calculate and save baseline metrics
    try {
      if (kDebugMode) {
        print('Calculating profile metrics...');
        print('Baseline data present: ${result.answers.containsKey("baseline")}');
      }

      final metrics = ProfileMetrics.fromAnswers(result.answers);

      if (kDebugMode) {
        print('Metrics calculated successfully:');
        print('  Activity: ${metrics.activityLabel} (${metrics.activityIndex})');
        print('  Stress: ${metrics.stressLabel} (${metrics.stressLoad})');
        print('  Sleep: ${metrics.sleepLabel} (${metrics.sleepQuality})');
        print('  Nutrition: ${metrics.nutritionLabel} (${metrics.nutritionQuality})');
        print('  Emotional: ${metrics.emotionalWellbeingLabel} (${metrics.emotionalWellbeing})');
      }

      await _saveBaselineMetrics(user.uid, metrics);

      // Show profile summary screen
      if (mounted) {
        if (kDebugMode) {
          print('Pushing ProfileSummaryPage...');
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileSummaryPage(metrics: metrics),
          ),
        );
        if (kDebugMode) {
          print('ProfileSummaryPage dismissed');
        }
      }
    } catch (e, stackTrace) {
      // If metrics calculation fails, log and continue
      if (kDebugMode) {
        print('Error calculating profile metrics: $e');
        print('Stack trace: $stackTrace');
      }
    }
    if (!mounted) return;

    // Then prompt for bolus parameters
    if (!_openedBolusAfterProfile) {
      _openedBolusAfterProfile = true;
      await Navigator.of(context).pushNamed('/settings/bolus-parameters');
      if (!mounted) return;
    }
  }
}
