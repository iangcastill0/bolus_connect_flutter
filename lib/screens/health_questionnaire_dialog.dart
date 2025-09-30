import 'package:flutter/material.dart';

import '../widgets/keyboard_dismissible.dart';

Future<HealthQuestionnaireResult?> showHealthQuestionnaireDialog(
  BuildContext context, {
  Map<String, dynamic>? initialAnswers,
}) {
  return Navigator.of(context).push<HealthQuestionnaireResult>(
    MaterialPageRoute(
      builder: (_) => _HealthQuestionnaireFlow(
        initialAnswers: initialAnswers,
      ),
      fullscreenDialog: true,
    ),
  );
}

class HealthQuestionnaireResult {
  HealthQuestionnaireResult({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.smokes,
    required this.drinksAlcohol,
    required this.stressLevel,
    required this.completedAt,
    required this.updatedAt,
    this.lastSyncedAt,
    required this.answers,
  });

  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final double heightCm;
  final double weightKg;
  final bool smokes;
  final bool drinksAlcohol;
  final int stressLevel;
  final DateTime completedAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final Map<String, dynamic> answers;
}

class _HealthQuestionnaireFlow extends StatefulWidget {
  const _HealthQuestionnaireFlow({this.initialAnswers});

  final Map<String, dynamic>? initialAnswers;

  @override
  State<_HealthQuestionnaireFlow> createState() =>
      _HealthQuestionnaireFlowState();
}

class _HealthQuestionnaireFlowState extends State<_HealthQuestionnaireFlow> {
  final _pageController = PageController();

  final _basicInfoKey = GlobalKey<FormState>();
  final _metricsKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  bool _smokes = false;
  bool _drinksAlcohol = false;
  int _stressLevel = 5;

  int _step = 0;

  final List<String> _titles = const [
    'About you',
    'Measurements',
    'Lifestyle',
    'Stress check-in',
  ];

  int get _totalSteps => _titles.length;

  @override
  void initState() {
    super.initState();
    _applyInitialAnswers();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_step > 0) {
          _goToStep(_step - 1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Profile'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: (_step + 1) / _totalSteps),
                  const SizedBox(height: 24),
                  Text(
                    _titles[_step],
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildMeasurementsStep(),
                        _buildLifestyleStep(),
                        _buildStressStep(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_step > 0)
                        OutlinedButton(
                          onPressed: () => _goToStep(_step - 1),
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox(width: 0, height: 0),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _handleNext,
                          child: Text(
                              _step == _totalSteps - 1 ? 'Finish' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyInitialAnswers() {
    final data = widget.initialAnswers;
    if (data == null) return;

    final name = data['fullName'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      _nameController.text = name.trim();
    }

    final dobString = (data['dateOfBirth'] ?? data['dob'])?.toString();
    final dob = dobString != null ? DateTime.tryParse(dobString) : null;
    if (dob != null) {
      _dob = dob;
      _dobController.text = _formatDate(dob);
    }

    final gender = data['gender'] as String?;
    if (gender != null && gender.isNotEmpty) {
      _gender = gender;
    }

    final height = _castToDouble(data['heightCm'] ?? data['height']);
    if (height != null) {
      _heightController.text = height.toStringAsFixed(height % 1 == 0 ? 0 : 1);
    }

    final weight = _castToDouble(data['weightKg'] ?? data['weight']);
    if (weight != null) {
      _weightController.text = weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1);
    }

    final smokes = _castToBool(data['smokes']);
    if (smokes != null) {
      _smokes = smokes;
    }

    final drinksAlcohol = _castToBool(data['drinksAlcohol'] ?? data['drinks']);
    if (drinksAlcohol != null) {
      _drinksAlcohol = drinksAlcohol;
    }

    final stressRaw = data['stressLevel'];
    if (stressRaw is num) {
      _stressLevel = stressRaw.clamp(1, 10).round();
    } else if (stressRaw is String) {
      final parsed = int.tryParse(stressRaw);
      if (parsed != null) {
        _stressLevel = parsed.clamp(1, 10);
      }
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Form(
        key: _basicInfoKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name looks too short';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                hintText: 'Select your birth date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDateOfBirth,
              validator: (_) {
                if (_dob == null) {
                  return 'Please choose your birth date';
                }
                final now = DateTime.now();
                if (_dob!.isAfter(now)) {
                  return 'Birth date cannot be in the future';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(
                    value: 'non_binary', child: Text('Non-binary')),
                DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefer not to say')),
              ],
              onChanged: (value) => setState(() => _gender = value),
              validator: (value) =>
                  value == null ? 'Select the option that fits best' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsStep() {
    return SingleChildScrollView(
      child: Form(
        key: _metricsKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _heightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'e.g. 170',
              ),
              validator: (value) {
                final parsed = _parsePositiveNumber(value);
                if (parsed == null) {
                  return 'Enter your height in centimeters';
                }
                if (parsed < 50 || parsed > 250) {
                  return 'Height should be between 50 cm and 250 cm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g. 65',
              ),
              validator: (value) {
                final parsed = _parsePositiveNumber(value);
                if (parsed == null) {
                  return 'Enter your weight in kilograms';
                }
                if (parsed < 20 || parsed > 400) {
                  return 'Weight should be between 20 kg and 400 kg';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifestyleStep() {
    return ListView(
      children: [
        SwitchListTile(
          value: _smokes,
          onChanged: (value) => setState(() => _smokes = value),
          title: const Text('Do you currently smoke?'),
          subtitle: const Text(
              'This includes cigarettes, vaping, or other tobacco products'),
        ),
        const Divider(),
        SwitchListTile(
          value: _drinksAlcohol,
          onChanged: (value) => setState(() => _drinksAlcohol = value),
          title: const Text('Do you consume alcohol?'),
          subtitle: const Text(
              'Even occasional consumption helps tailor recommendations'),
        ),
      ],
    );
  }

  Widget _buildStressStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'On a scale from 1 (very relaxed) to 10 (extremely stressed), how would you rate your current stress level?',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Slider(
          value: _stressLevel.toDouble(),
          divisions: 9,
          min: 1,
          max: 10,
          label: '$_stressLevel',
          onChanged: (value) => setState(() => _stressLevel = value.round()),
        ),
        const SizedBox(height: 8),
        Text(
          'Current selection: $_stressLevel out of 10',
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobController.text = _formatDate(picked);
      });
    }
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;

    if (_step == _totalSteps - 1) {
      _submit();
      return;
    }
    _goToStep(_step + 1);
  }

  void _goToStep(int step) {
    if (step == _step) return;
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _basicInfoKey.currentState?.validate() ?? false;
      case 1:
        return _metricsKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _submit() {
    final fullName = _nameController.text.trim();
    final heightCm = _parsePositiveNumber(_heightController.text)!;
    final weightKg = _parsePositiveNumber(_weightController.text)!;

    final nowIso = DateTime.now().toIso8601String();
    final existingCompletedAt =
        widget.initialAnswers?['completedAt']?.toString();
    final existingSyncedAt = widget.initialAnswers?['lastSyncedAt']?.toString();

    final answers = <String, dynamic>{
      'fullName': fullName,
      'dateOfBirth': _dob!.toIso8601String(),
      'gender': _gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'smokes': _smokes,
      'drinksAlcohol': _drinksAlcohol,
      'stressLevel': _stressLevel,
      'completedAt': existingCompletedAt ?? nowIso,
      'updatedAt': nowIso,
    };

    if (existingSyncedAt != null) {
      answers['lastSyncedAt'] = existingSyncedAt;
    }

    final completedAt =
        DateTime.tryParse(answers['completedAt'] as String? ?? nowIso) ??
            DateTime.now();
    final updatedAt =
        DateTime.tryParse(answers['updatedAt'] as String? ?? nowIso) ??
            DateTime.now();
    final lastSyncedAt =
        existingSyncedAt != null ? DateTime.tryParse(existingSyncedAt) : null;

    final result = HealthQuestionnaireResult(
      fullName: fullName,
      dateOfBirth: _dob!,
      gender: _gender!,
      heightCm: heightCm,
      weightKg: weightKg,
      smokes: _smokes,
      drinksAlcohol: _drinksAlcohol,
      stressLevel: _stressLevel,
      completedAt: completedAt,
      updatedAt: updatedAt,
      lastSyncedAt: lastSyncedAt,
      answers: answers,
    );

    Navigator.of(context).pop(result);
  }

  static double? _parsePositiveNumber(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static double? _castToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _castToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'no' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
