import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/keyboard_dismissible.dart';
import '../services/health_questionnaire_service.dart';

Future<HealthQuestionnaireResult?> showHealthQuestionnaireDialog(
  BuildContext context, {
  Map<String, dynamic>? initialAnswers,
  bool allowCancel = true,
}) {
  return Navigator.of(context).push<HealthQuestionnaireResult>(
    MaterialPageRoute(
      builder: (_) => _HealthQuestionnaireFlow(
        initialAnswers: initialAnswers,
        allowCancel: allowCancel,
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
    required this.countryCode,
    required this.glucoseUnit,
    required this.diabetesType,
    required this.treatment,
    required this.conditions,
    required this.medications,
    this.bmi,
    required this.baselineLifestyle,
    required this.baselineActivity,
    required this.baselineStress,
    required this.baselineSleep,
    required this.baselineNutrition,
    required this.baselinePsych,
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
  final String countryCode;
  final String glucoseUnit;
  final String diabetesType;
  final String treatment;
  final List<String> conditions;
  final List<String> medications;
  final double? bmi;
  final Map<String, dynamic> baselineLifestyle;
  final Map<String, dynamic> baselineActivity;
  final Map<String, dynamic> baselineStress;
  final Map<String, dynamic> baselineSleep;
  final Map<String, dynamic> baselineNutrition;
  final Map<String, dynamic> baselinePsych;
  final DateTime completedAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final Map<String, dynamic> answers;
}

class _LabeledOption {
  const _LabeledOption(this.value, this.label);

  final String value;
  final String label;
}

class _RegionOption {
  const _RegionOption({
    required this.code,
    required this.label,
    required this.glucoseUnit,
  });

  final String code;
  final String label;
  final String glucoseUnit;
}

const List<_LabeledOption> _sexOptions = [
  _LabeledOption('female', 'Female'),
  _LabeledOption('male', 'Male'),
  _LabeledOption('non_binary', 'Non-binary'),
  _LabeledOption('prefer_not_to_say', 'Prefer not to say'),
];

const List<_RegionOption> _regionOptions = [
  _RegionOption(code: 'US', label: 'United States', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'CA', label: 'Canada', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'UK', label: 'United Kingdom', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'AU', label: 'Australia', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'EU', label: 'European Union', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'OTHER', label: 'Other', glucoseUnit: 'mg/dL'),
];

const List<_LabeledOption> _diabetesTypeOptions = [
  _LabeledOption('type1', 'Type 1'),
  _LabeledOption('type2', 'Type 2'),
  _LabeledOption('prediabetes', 'Prediabetes'),
  _LabeledOption('monitoring_only', 'Monitoring only'),
];

const List<_LabeledOption> _treatmentOptions = [
  _LabeledOption('mdi', 'Multiple daily injections (MDI)'),
  _LabeledOption('pump', 'Insulin pump'),
  _LabeledOption('non_insulin_medication', 'Non-insulin medication'),
  _LabeledOption('diet_exercise', 'Diet & exercise'),
  _LabeledOption('none', 'None'),
];

const List<_LabeledOption> _conditionOptions = [
  _LabeledOption('hypertension', 'Hypertension'),
  _LabeledOption('dyslipidemia', 'Dyslipidemia'),
  _LabeledOption('thyroid', 'Thyroid disorder'),
  _LabeledOption('sleep_apnea', 'Sleep apnea'),
  _LabeledOption('pcos', 'PCOS'),
  _LabeledOption('none', 'None'),
];

const List<_LabeledOption> _medicationOptions = [
  _LabeledOption('metformin', 'Metformin'),
  _LabeledOption('glp1', 'GLP-1 receptor agonist'),
  _LabeledOption('sglt2', 'SGLT2 inhibitor'),
  _LabeledOption('basal_insulin', 'Basal insulin'),
  _LabeledOption('bolus_insulin', 'Bolus insulin'),
  _LabeledOption('other', 'Other'),
  _LabeledOption('none', 'None'),
];

const List<_LabeledOption> _workPatternOptions = [
  _LabeledOption('daytime', 'Daytime'),
  _LabeledOption('shift', 'Shift work'),
  _LabeledOption('irregular', 'Irregular'),
  _LabeledOption('student', 'Student'),
  _LabeledOption('retired', 'Retired'),
];

const List<_LabeledOption> _breakfastHabitOptions = [
  _LabeledOption('every_day', 'Every day'),
  _LabeledOption('sometimes', 'Sometimes'),
  _LabeledOption('never', 'Never'),
];

const List<_LabeledOption> _caffeineOptions = [
  _LabeledOption('none', 'None'),
  _LabeledOption('1_2', '1–2 cups'),
  _LabeledOption('3_5', '3–5 cups'),
  _LabeledOption('gt5', 'More than 5 cups'),
];

const List<_LabeledOption> _alcoholOptions = [
  _LabeledOption('never', 'Never'),
  _LabeledOption('occasionally', 'Occasionally'),
  _LabeledOption('several_week', 'Several times a week'),
  _LabeledOption('daily', 'Daily'),
];

const List<_LabeledOption> _smokingOptions = [
  _LabeledOption('yes', 'Yes'),
  _LabeledOption('no', 'No'),
];

const List<_LabeledOption> _energyLevelOptions = [
  _LabeledOption('low', 'Low'),
  _LabeledOption('moderate', 'Moderate'),
  _LabeledOption('high', 'High'),
];

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? _parseTimeOfDay(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

enum _FieldId {
  fullName,
  dob,
  gender,
  height,
  weight,
  country,
  diabetesType,
  treatment,
  conditions,
  medications,
}

enum _Section { basic, measurements, management }

const Duration _kValidationFadeDuration = Duration(milliseconds: 180);

const Map<_FieldId, _Section> _fieldSection = {
  _FieldId.fullName: _Section.basic,
  _FieldId.dob: _Section.basic,
  _FieldId.gender: _Section.basic,
  _FieldId.height: _Section.measurements,
  _FieldId.weight: _Section.measurements,
  _FieldId.country: _Section.measurements,
  _FieldId.diabetesType: _Section.management,
  _FieldId.treatment: _Section.management,
  _FieldId.conditions: _Section.management,
  _FieldId.medications: _Section.management,
};

const Map<_Section, Set<_FieldId>> _sectionFields = {
  _Section.basic: {_FieldId.fullName, _FieldId.dob, _FieldId.gender},
  _Section.measurements: {_FieldId.height, _FieldId.weight, _FieldId.country},
  _Section.management: {
    _FieldId.diabetesType,
    _FieldId.treatment,
    _FieldId.conditions,
    _FieldId.medications,
  },
};

class _HealthQuestionnaireFlow extends StatefulWidget {
  const _HealthQuestionnaireFlow({
    this.initialAnswers,
    this.allowCancel = true,
  });

  final Map<String, dynamic>? initialAnswers;
  final bool allowCancel;

  @override
  State<_HealthQuestionnaireFlow> createState() =>
      _HealthQuestionnaireFlowState();
}

class _HealthQuestionnaireFlowState extends State<_HealthQuestionnaireFlow> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _dobFieldKey = GlobalKey<FormFieldState<String>>();
  final _heightFieldKey = GlobalKey<FormFieldState<String>>();
  final _weightFieldKey = GlobalKey<FormFieldState<String>>();
  final _genderFieldKey = GlobalKey<FormFieldState<String>>();
  final _countryFieldKey = GlobalKey<FormFieldState<String>>();
  final _diabetesTypeFieldKey = GlobalKey<FormFieldState<String>>();
  final _treatmentFieldKey = GlobalKey<FormFieldState<String>>();

  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  String? _countryCode;
  String _glucoseUnit = 'mg/dL';
  String? _diabetesType;
  String? _treatment;
  final Set<String> _conditions = <String>{};
  final Set<String> _medications = <String>{};
  double? _bmi;
  bool _showSelectionErrors = false;
  Map<String, dynamic> _draftAnswers = <String, dynamic>{};
  Map<String, dynamic>? _initialLifestyle;
  Map<String, dynamic>? _initialActivity;
  Map<String, dynamic>? _initialStress;
  Map<String, dynamic>? _initialSleep;
  Map<String, dynamic>? _initialNutrition;
  Map<String, dynamic>? _initialPsych;
  final Map<_FieldId, bool> _fieldValidity = {
    for (final id in _FieldId.values) id: false,
  };
  final Map<_Section, bool> _sectionSaved = {
    for (final section in _Section.values) section: false,
  };
  final Map<_Section, bool> _sectionSaving = {
    for (final section in _Section.values) section: false,
  };

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_updateDerivedMetrics);
    _weightController.addListener(_updateDerivedMetrics);
    _fullNameFocusNode.addListener(
      () => _handleFocusChange(
        _fullNameFocusNode,
        _FieldId.fullName,
        _fullNameFieldKey,
      ),
    );
    _heightFocusNode.addListener(
      () => _handleFocusChange(
        _heightFocusNode,
        _FieldId.height,
        _heightFieldKey,
      ),
    );
    _weightFocusNode.addListener(
      () => _handleFocusChange(
        _weightFocusNode,
        _FieldId.weight,
        _weightFieldKey,
      ),
    );
    _applyInitialAnswers();
  }

  Widget _buildValidatedField({
    required BuildContext context,
    required _FieldId fieldId,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [child, _validationIndicator(context, fieldId)],
    );
  }

  Widget _validationIndicator(BuildContext context, _FieldId fieldId) {
    final theme = Theme.of(context);
    final isValid = _fieldValidity[fieldId] == true;
    return AnimatedSwitcher(
      duration: _kValidationFadeDuration,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isValid
          ? Padding(
              key: ValueKey('${fieldId.name}-valid'),
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Looks good',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox.shrink(key: ValueKey('${fieldId.name}-empty')),
    );
  }

  void _handleFocusChange(
    FocusNode node,
    _FieldId fieldId,
    GlobalKey<FormFieldState<String>> key,
  ) {
    if (node.hasFocus) return;
    _validateFormField(fieldId, key);
  }

  void _invalidateField(_FieldId fieldId) {
    if (_fieldValidity[fieldId] != true) return;
    final section = _fieldSection[fieldId];
    setState(() {
      _fieldValidity[fieldId] = false;
      if (section != null) {
        _sectionSaved[section] = false;
      }
    });
  }

  void _validateFormField(
    _FieldId fieldId,
    GlobalKey<FormFieldState<String>> key,
  ) {
    final isValid = key.currentState?.validate() ?? false;
    _updateFieldValidity(fieldId, isValid);
  }

  void _validateDropdownField(
    _FieldId fieldId,
    GlobalKey<FormFieldState<String>> key,
  ) {
    final isValid = key.currentState?.validate() ?? false;
    _updateFieldValidity(fieldId, isValid);
  }

  void _updateFieldValidity(_FieldId fieldId, bool isValid) {
    final previous = _fieldValidity[fieldId];
    if (previous == isValid) return;
    final section = _fieldSection[fieldId];
    setState(() {
      _fieldValidity[fieldId] = isValid;
      if (!isValid && section != null) {
        _sectionSaved[section] = false;
      }
    });
    if (isValid) {
      _maybeSaveSectionForField(fieldId);
    }
  }

  Future<void> _maybeSaveSectionForField(_FieldId fieldId) async {
    final section = _fieldSection[fieldId];
    if (section == null) return;
    final fields = _sectionFields[section]!;
    final allValid = fields.every((field) => _fieldValidity[field] == true);
    if (!allValid) return;
    if (_sectionSaved[section] == true || _sectionSaving[section] == true) {
      return;
    }
    await _saveSection(section);
  }

  Future<void> _saveSection(_Section section) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _sectionSaving[section] = true;
    });
    try {
      final payload = _buildSectionPayload(section);
      final updated = Map<String, dynamic>.from(_draftAnswers);
      updated.addAll(payload.topLevel);

      final existingProfile = updated['profile'];
      final profileMap = existingProfile is Map<String, dynamic>
          ? Map<String, dynamic>.from(existingProfile)
          : <String, dynamic>{};
      profileMap[_sectionProfileKey(section)] = payload.profile;
      updated['profile'] = profileMap;

      _draftAnswers = updated;

      await HealthQuestionnaireService.saveAnswersForUser(
        user.uid,
        Map<String, dynamic>.from(updated),
      );

      if (section == _Section.measurements) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('glucoseUnit', _glucoseUnit);
      }

      if (!mounted) return;
      setState(() {
        _sectionSaved[section] = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sectionSaving[section] = false;
        });
      }
    }
  }

  ({Map<String, dynamic> topLevel, Map<String, dynamic> profile})
  _buildSectionPayload(_Section section) {
    switch (section) {
      case _Section.basic:
        final topLevel = _withoutNulls(<String, dynamic>{
          'fullName': _nameController.text.trim(),
          'dateOfBirth': _dob?.toIso8601String(),
          'gender': _gender,
        });
        final profile = _withoutNulls(<String, dynamic>{
          'fullName': topLevel['fullName'],
          'dateOfBirth': topLevel['dateOfBirth'],
          'gender': topLevel['gender'],
        });
        return (topLevel: topLevel, profile: profile);
      case _Section.measurements:
        final heightValue = _parsePositiveNumber(_heightController.text);
        final weightValue = _parsePositiveNumber(_weightController.text);
        final heightCm = heightValue == null
            ? null
            : _heightUnit == 'cm'
            ? heightValue
            : heightValue * 2.54;
        final weightKg = weightValue == null
            ? null
            : _weightUnit == 'kg'
            ? weightValue
            : weightValue * 0.45359237;
        final bmi = heightCm != null && weightKg != null
            ? _computeBmi(heightCm, weightKg)
            : null;
        final topLevel = _withoutNulls(<String, dynamic>{
          'heightCm': heightCm,
          'weightKg': weightKg,
          'bmi': bmi,
          'countryCode': _countryCode,
          'glucoseUnit': _glucoseUnit,
        });
        final profile = Map<String, dynamic>.from(topLevel);
        return (topLevel: topLevel, profile: profile);
      case _Section.management:
        final topLevel = _withoutNulls(<String, dynamic>{
          'diabetesType': _diabetesType,
          'treatment': _treatment,
          'conditions': _conditions.toList(),
          'medications': _medications.toList(),
        });
        final profile = Map<String, dynamic>.from(topLevel);
        return (topLevel: topLevel, profile: profile);
    }
  }

  String _sectionProfileKey(_Section section) {
    switch (section) {
      case _Section.basic:
        return 'basic';
      case _Section.measurements:
        return 'measurements';
      case _Section.management:
        return 'management';
    }
  }

  Map<String, dynamic> _withoutNulls(Map<String, dynamic> source) {
    source.removeWhere((key, value) => value == null);
    return source;
  }

  void _refreshInitialValidity() {
    _fieldValidity[_FieldId.fullName] = _nameController.text.trim().length >= 2;
    _fieldValidity[_FieldId.dob] = _dob != null;
    _fieldValidity[_FieldId.gender] = _gender != null && _gender!.isNotEmpty;

    final heightValue = _parsePositiveNumber(_heightController.text);
    final heightCm = heightValue == null
        ? null
        : _heightUnit == 'cm'
        ? heightValue
        : heightValue * 2.54;
    _fieldValidity[_FieldId.height] =
        heightCm != null && heightCm >= 50 && heightCm <= 250;

    final weightValue = _parsePositiveNumber(_weightController.text);
    final weightKg = weightValue == null
        ? null
        : _weightUnit == 'kg'
        ? weightValue
        : weightValue * 0.45359237;
    _fieldValidity[_FieldId.weight] =
        weightKg != null && weightKg >= 30 && weightKg <= 250;

    _fieldValidity[_FieldId.country] =
        _countryCode != null && _countryCode!.isNotEmpty;
    _fieldValidity[_FieldId.diabetesType] =
        _diabetesType != null && _diabetesType!.isNotEmpty;
    _fieldValidity[_FieldId.treatment] =
        _treatment != null && _treatment!.isNotEmpty;
    _fieldValidity[_FieldId.conditions] = _conditions.isNotEmpty;
    _fieldValidity[_FieldId.medications] = _medications.isNotEmpty;
  }

  @override
  void dispose() {
    _heightController.removeListener(_updateDerivedMetrics);
    _weightController.removeListener(_updateDerivedMetrics);
    _fullNameFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = _sectionSaving.values.any((saving) => saving);
    final leading = widget.allowCancel
        ? BackButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
          )
        : null;

    final scaffold = Scaffold(
      appBar: AppBar(title: const Text('Health Profile'), leading: leading),
      body: KeyboardDismissible(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Let's start with your health profile",
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.fullName,
                    child: TextFormField(
                      key: _fullNameFieldKey,
                      focusNode: _fullNameFocusNode,
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      onChanged: (_) => _invalidateField(_FieldId.fullName),
                      onEditingComplete: () => _validateFormField(
                        _FieldId.fullName,
                        _fullNameFieldKey,
                      ),
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
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.dob,
                    child: TextFormField(
                      key: _dobFieldKey,
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
                  ),
                  if (_dob != null) ...[
                    const SizedBox(height: 8),
                    Text('Age: ${_calculateAge(_dob!)} years'),
                  ],
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.gender,
                    child: DropdownButtonFormField<String>(
                      key: _genderFieldKey,
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Sex at birth / gender identity',
                      ),
                      items: _sexOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _gender = value);
                        _genderFieldKey.currentState?.didChange(value);
                        if (value == null) {
                          _updateFieldValidity(_FieldId.gender, false);
                        } else {
                          _validateDropdownField(
                            _FieldId.gender,
                            _genderFieldKey,
                          );
                        }
                      },
                      validator: (value) => value == null
                          ? 'Select the option that fits best'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildValidatedField(
                          context: context,
                          fieldId: _FieldId.height,
                          child: TextFormField(
                            key: _heightFieldKey,
                            focusNode: _heightFocusNode,
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Height',
                              hintText: 'e.g. 170',
                            ),
                            onChanged: (_) => _invalidateField(_FieldId.height),
                            onEditingComplete: () => _validateFormField(
                              _FieldId.height,
                              _heightFieldKey,
                            ),
                            validator: (value) {
                              final parsed = _parsePositiveNumber(value);
                              if (parsed == null) {
                                return 'Enter your height';
                              }
                              final heightCm = _heightUnit == 'cm'
                                  ? parsed
                                  : parsed * 2.54;
                              if (heightCm < 50 || heightCm > 250) {
                                return 'Height should be between 50 and 250 cm';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('heightUnit-$_heightUnit'),
                          initialValue: _heightUnit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: 'cm', child: Text('cm')),
                            DropdownMenuItem(
                              value: 'in',
                              child: Text('inches'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _changeHeightUnit(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildValidatedField(
                          context: context,
                          fieldId: _FieldId.weight,
                          child: TextFormField(
                            key: _weightFieldKey,
                            focusNode: _weightFocusNode,
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Weight',
                              hintText: 'e.g. 70',
                            ),
                            onChanged: (_) => _invalidateField(_FieldId.weight),
                            onEditingComplete: () => _validateFormField(
                              _FieldId.weight,
                              _weightFieldKey,
                            ),
                            validator: (value) {
                              final parsed = _parsePositiveNumber(value);
                              if (parsed == null) {
                                return 'Enter your weight';
                              }
                              final weightKg = _weightUnit == 'kg'
                                  ? parsed
                                  : parsed * 0.45359237;
                              if (weightKg < 30 || weightKg > 250) {
                                return 'Weight should be between 30 and 250 kg';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('weightUnit-$_weightUnit'),
                          initialValue: _weightUnit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(
                              value: 'lb',
                              child: Text('pounds'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _changeWeightUnit(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_bmi != null) ...[
                    const SizedBox(height: 8),
                    Text('BMI: ${_bmi!.toStringAsFixed(1)}'),
                  ],
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.country,
                    child: DropdownButtonFormField<String>(
                      key: _countryFieldKey,
                      initialValue: _countryCode,
                      decoration: const InputDecoration(
                        labelText: 'Country or region',
                      ),
                      items: _regionOptions
                          .map(
                            (region) => DropdownMenuItem<String>(
                              value: region.code,
                              child: Text(region.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => _selectCountry(value),
                      validator: (value) => value == null
                          ? 'Please choose a country or region'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.diabetesType,
                    child: DropdownButtonFormField<String>(
                      key: _diabetesTypeFieldKey,
                      initialValue: _diabetesType,
                      decoration: const InputDecoration(
                        labelText: 'Diabetes type',
                      ),
                      items: _diabetesTypeOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _diabetesType = value);
                        _diabetesTypeFieldKey.currentState?.didChange(value);
                        if (value == null) {
                          _updateFieldValidity(_FieldId.diabetesType, false);
                        } else {
                          _validateDropdownField(
                            _FieldId.diabetesType,
                            _diabetesTypeFieldKey,
                          );
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Select your diabetes type' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.treatment,
                    child: DropdownButtonFormField<String>(
                      key: _treatmentFieldKey,
                      initialValue: _treatment,
                      decoration: const InputDecoration(
                        labelText: 'Current treatment',
                      ),
                      items: _treatmentOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _treatment = value);
                        _treatmentFieldKey.currentState?.didChange(value);
                        if (value == null) {
                          _updateFieldValidity(_FieldId.treatment, false);
                        } else {
                          _validateDropdownField(
                            _FieldId.treatment,
                            _treatmentFieldKey,
                          );
                        }
                      },
                      validator: (value) => value == null
                          ? 'Select your current treatment'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Known conditions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _conditionOptions
                        .map(
                          (option) => FilterChip(
                            label: Text(option.label),
                            selected: _conditions.contains(option.value),
                            onSelected: (selected) =>
                                _toggleCondition(option.value, selected),
                          ),
                        )
                        .toList(),
                  ),
                  if (_showSelectionErrors && _conditions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Select at least one known condition (or choose None).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Current medications',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _medicationOptions
                        .map(
                          (option) => FilterChip(
                            label: Text(option.label),
                            selected: _medications.contains(option.value),
                            onSelected: (selected) =>
                                _toggleMedication(option.value, selected),
                          ),
                        )
                        .toList(),
                  ),
                  if (_showSelectionErrors && _medications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Select at least one medication (or choose None).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: isSaving ? null : _handleContinue,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.allowCancel) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: scaffold,
    );
  }

  void _applyInitialAnswers() {
    final data = widget.initialAnswers;
    _draftAnswers = data != null
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    if (data == null) {
      _refreshInitialValidity();
      return;
    }

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

    final gender = data['gender'] as String? ?? data['sexAtBirth'] as String?;
    if (gender != null && gender.isNotEmpty) {
      _gender = gender;
    }

    final height = _castToDouble(data['heightCm'] ?? data['height']);
    if (height != null) {
      _heightController.text = _formatNumber(height);
      _heightUnit = 'cm';
    }

    final weight = _castToDouble(data['weightKg'] ?? data['weight']);
    if (weight != null) {
      _weightController.text = _formatNumber(weight);
      _weightUnit = 'kg';
    }

    final country = (data['countryCode'] ?? data['country']) as String?;
    if (country != null && country.isNotEmpty) {
      _countryCode = country;
    }

    final storedUnit = data['glucoseUnit'] as String?;
    if (storedUnit != null && storedUnit.isNotEmpty) {
      _glucoseUnit = storedUnit;
    }

    final region = _countryCode != null ? _findRegion(_countryCode!) : null;
    if (region != null) {
      _glucoseUnit = region.glucoseUnit;
    }

    final diabetesType = data['diabetesType'] as String?;
    if (diabetesType != null && diabetesType.isNotEmpty) {
      _diabetesType = diabetesType;
    }

    final treatment =
        data['treatment'] as String? ?? data['currentTreatment'] as String?;
    if (treatment != null && treatment.isNotEmpty) {
      _treatment = treatment;
    }

    final conditionsRaw = data['conditions'];
    if (conditionsRaw is List) {
      _conditions
        ..clear()
        ..addAll(
          conditionsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
    }

    final medicationsRaw = data['medications'];
    if (medicationsRaw is List) {
      _medications
        ..clear()
        ..addAll(
          medicationsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty),
        );
    }

    final bmi = _castToDouble(data['bmi']);
    if (bmi != null) {
      _bmi = bmi;
    }

    final baseline = data['baseline'];
    if (baseline is Map) {
      final lifestyle = baseline['lifestyle'];
      if (lifestyle is Map) {
        _initialLifestyle = lifestyle.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      final activity = baseline['activity'];
      if (activity is Map) {
        final ipaq = activity['ipaq'];
        final mapSource = ipaq is Map ? ipaq : activity;
        _initialActivity = mapSource.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      final stress = baseline['stress'];
      if (stress is Map) {
        _initialStress = stress.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      final sleep = baseline['sleep'];
      if (sleep is Map) {
        _initialSleep = sleep.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      final nutrition = baseline['nutrition'];
      if (nutrition is Map) {
        _initialNutrition = nutrition.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      final psych = baseline['psych'];
      if (psych is Map) {
        _initialPsych = psych.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    // Refresh derived metrics to ensure BMI reflects current inputs.
    _updateDerivedMetrics();
    _refreshInitialValidity();
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
      _validateFormField(_FieldId.dob, _dobFieldKey);
    }
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    final selectionsValid = _conditions.isNotEmpty && _medications.isNotEmpty;

    if (!selectionsValid) {
      setState(() => _showSelectionErrors = true);
    }

    if (!formValid || !selectionsValid) {
      return;
    }
    if (_dob == null) {
      return;
    }
    if (_gender == null || _diabetesType == null || _treatment == null) {
      return;
    }
    if (_countryCode == null) {
      return;
    }
    setState(() => _showSelectionErrors = false);

    final flowResult = await Navigator.of(context).push<_LifestyleFlowResult>(
      MaterialPageRoute(
        builder: (_) => _LifestyleQuestionnairePage(
          initialAnswers: _initialLifestyle,
          initialActivityAnswers: _initialActivity,
          initialStressAnswers: _initialStress,
          initialSleepAnswers: _initialSleep,
          initialNutritionAnswers: _initialNutrition,
          initialPsychAnswers: _initialPsych,
          onLifestyleSaved: _saveLifestyleDraft,
          onActivitySaved: _saveActivityDraft,
          onStressSleepSaved: _saveStressSleepDraft,
          onNutritionSaved: _saveNutritionDraft,
          onPsychSaved: _savePsychDraft,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || flowResult == null) {
      return;
    }

    await _finalizeQuestionnaire(flowResult);
  }

  Future<void> _saveLifestyleDraft(Map<String, dynamic> lifestyle) async {
    final copy = Map<String, dynamic>.from(lifestyle);
    _initialLifestyle = copy;
    await _persistBaselineDraft(lifestyle: copy);
  }

  Future<void> _saveActivityDraft(Map<String, dynamic> activity) async {
    final activityCopy = Map<String, dynamic>.from(activity);
    _initialActivity = activityCopy;
    final container = <String, dynamic>{
      'ipaq': Map<String, dynamic>.from(activityCopy),
    };
    await _persistBaselineDraft(activity: container);
  }

  Future<void> _saveStressSleepDraft(
    Map<String, dynamic> stress,
    Map<String, dynamic> sleep,
  ) async {
    final stressCopy = Map<String, dynamic>.from(stress);
    final sleepCopy = Map<String, dynamic>.from(sleep);
    _initialStress = stressCopy;
    _initialSleep = sleepCopy;
    await _persistBaselineDraft(
      stress: stressCopy,
      sleep: sleepCopy,
    );
  }

  Future<void> _saveNutritionDraft(Map<String, dynamic> nutrition) async {
    final nutritionCopy = Map<String, dynamic>.from(nutrition);
    _initialNutrition = nutritionCopy;
    await _persistBaselineDraft(nutrition: nutritionCopy);
  }

  Future<void> _savePsychDraft(Map<String, dynamic> psych) async {
    final psychCopy = Map<String, dynamic>.from(psych);
    _initialPsych = psychCopy;
    await _persistBaselineDraft(psych: psychCopy);
  }

  Future<void> _persistBaselineDraft({
    Map<String, dynamic>? lifestyle,
    Map<String, dynamic>? activity,
    Map<String, dynamic>? stress,
    Map<String, dynamic>? sleep,
    Map<String, dynamic>? nutrition,
    Map<String, dynamic>? psych,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final updated = Map<String, dynamic>.from(_draftAnswers);
    final baselineRaw = updated['baseline'];
    final baseline = baselineRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(baselineRaw)
        : <String, dynamic>{};

    void writeSection(String key, Map<String, dynamic>? value) {
      if (value != null) {
        baseline[key] = Map<String, dynamic>.from(value);
      }
    }

    writeSection('lifestyle', lifestyle);
    writeSection('activity', activity);
    writeSection('stress', stress);
    writeSection('sleep', sleep);
    writeSection('nutrition', nutrition);
    writeSection('psych', psych);

    updated['baseline'] = baseline;

    if (nutrition != null || psych != null) {
      final metricsRaw = updated['metrics'];
      final metrics = metricsRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(metricsRaw)
          : <String, dynamic>{};
      if (nutrition != null && nutrition['index'] != null) {
        metrics['nutrition'] = {'index': nutrition['index']};
      }
      if (psych != null && psych['index'] != null) {
        metrics['psych'] = {'index': psych['index']};
      }
      updated['metrics'] = metrics;
    }

    updated['updatedAt'] = DateTime.now().toIso8601String();
    _draftAnswers = updated;

    await HealthQuestionnaireService.saveAnswersForUser(
      user.uid,
      Map<String, dynamic>.from(updated),
    );
  }

  Future<void> _finalizeQuestionnaire(_LifestyleFlowResult flow) async {
    FocusScope.of(context).unfocus();

    final lifestyle = flow.lifestyle;
    final activity = flow.activity;
    final stressSleep = flow.stressSleep;

    final heightValue = _parsePositiveNumber(_heightController.text)!;
    final weightValue = _parsePositiveNumber(_weightController.text)!;
    final heightCm = _heightUnit == 'cm' ? heightValue : heightValue * 2.54;
    final weightKg = _weightUnit == 'kg'
        ? weightValue
        : weightValue * 0.45359237;
    final bmi = _computeBmi(heightCm, weightKg);

    final nowIso = DateTime.now().toIso8601String();
    final existingCompletedAt = widget.initialAnswers?['completedAt']
        ?.toString();
    final existingSyncedAt = widget.initialAnswers?['lastSyncedAt']?.toString();

    final answers = <String, dynamic>{
      'fullName': _nameController.text.trim(),
      'dateOfBirth': _dob!.toIso8601String(),
      'gender': _gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': bmi,
      'countryCode': _countryCode,
      'glucoseUnit': _glucoseUnit,
      'diabetesType': _diabetesType,
      'treatment': _treatment,
      'conditions': _conditions.toList(),
      'medications': _medications.toList(),
      'completedAt': existingCompletedAt ?? nowIso,
      'updatedAt': nowIso,
    };

    if (existingSyncedAt != null) {
      answers['lastSyncedAt'] = existingSyncedAt;
    }

    final lifestyleMap = lifestyle.toMap();
    final activityMap = activity.toMap();
    final activityContainer = {'ipaq': activityMap};
    final stressMap = stressSleep.toStressMap();
    final sleepMap = stressSleep.toSleepMap();
    stressMap['loadIndex'] = stressSleep.stressLoad;
    final nutritionMap = stressSleep.toNutritionMap();
    final psychMap = stressSleep.toPsychMap();
    answers['baseline'] = {
      'lifestyle': lifestyleMap,
      'activity': activityContainer,
      'stress': stressMap,
      'sleep': sleepMap,
      'nutrition': nutritionMap,
      'psych': psychMap,
    };

    final metrics = <String, dynamic>{};
    final existingMetrics = widget.initialAnswers?['metrics'];
    if (existingMetrics is Map) {
      existingMetrics.forEach((key, value) {
        metrics[key.toString()] = value;
      });
    }
    metrics['nutrition'] = {'index': nutritionMap['index']};
    metrics['psych'] = {'index': psychMap['index']};
    answers['metrics'] = metrics;

    final flags = <String, dynamic>{};
    final existingFlags = widget.initialAnswers?['flags'];
    if (existingFlags is Map) {
      existingFlags.forEach((key, value) {
        flags[key.toString()] = value;
      });
    }
    final supportNeeded = psychMap['supportNeeded'] == true;
    if (supportNeeded) {
      flags['support_needed'] = true;
    }
    if (flags.isNotEmpty) {
      answers['flags'] = flags;
    }

    final profile = <String, dynamic>{
      'basic': {
        'fullName': answers['fullName'],
        'dateOfBirth': answers['dateOfBirth'],
        'gender': answers['gender'],
      },
      'measurements': {
        'heightCm': answers['heightCm'],
        'weightKg': answers['weightKg'],
        'bmi': answers['bmi'],
        'countryCode': answers['countryCode'],
        'glucoseUnit': answers['glucoseUnit'],
      },
      'management': {
        'diabetesType': answers['diabetesType'],
        'treatment': answers['treatment'],
        'conditions': answers['conditions'],
        'medications': answers['medications'],
      },
      'baseline': {
        'lifestyle': lifestyleMap,
        'activity': activityContainer,
        'stress': stressMap,
        'sleep': sleepMap,
        'nutrition': nutritionMap,
        'psych': psychMap,
      },
    };
    answers['profile'] = profile;

    _draftAnswers = Map<String, dynamic>.from(answers);
    _initialLifestyle = lifestyleMap;
    _initialActivity = activityMap;
    _initialStress = stressMap;
    _initialSleep = sleepMap;
    _initialNutrition = nutritionMap;
    _initialPsych = psychMap;

    final completedAt =
        DateTime.tryParse(answers['completedAt'] as String? ?? nowIso) ??
        DateTime.now();
    final updatedAt =
        DateTime.tryParse(answers['updatedAt'] as String? ?? nowIso) ??
        DateTime.now();
    final lastSyncedAt = existingSyncedAt != null
        ? DateTime.tryParse(existingSyncedAt)
        : null;

    final result = HealthQuestionnaireResult(
      fullName: answers['fullName'] as String,
      dateOfBirth: _dob!,
      gender: _gender!,
      heightCm: heightCm,
      weightKg: weightKg,
      countryCode: _countryCode!,
      glucoseUnit: _glucoseUnit,
      diabetesType: _diabetesType!,
      treatment: _treatment!,
      conditions: List<String>.from(answers['conditions'] as List),
      medications: List<String>.from(answers['medications'] as List),
      bmi: bmi,
      baselineLifestyle: lifestyleMap,
      baselineActivity: activityMap,
      baselineStress: stressMap,
      baselineSleep: sleepMap,
      baselineNutrition: nutritionMap,
      baselinePsych: psychMap,
      completedAt: completedAt,
      updatedAt: updatedAt,
      lastSyncedAt: lastSyncedAt,
      answers: answers,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glucoseUnit', _glucoseUnit);

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _changeHeightUnit(String newUnit) {
    if (newUnit == _heightUnit) return;
    _invalidateField(_FieldId.height);
    final previousUnit = _heightUnit;
    final currentValue = _parsePositiveNumber(_heightController.text);
    setState(() {
      _heightUnit = newUnit;
    });
    if (currentValue != null) {
      double converted = currentValue;
      if (previousUnit == 'cm' && newUnit == 'in') {
        converted = currentValue / 2.54;
      } else if (previousUnit == 'in' && newUnit == 'cm') {
        converted = currentValue * 2.54;
      }
      _heightController.text = _formatNumber(converted);
      _validateFormField(_FieldId.height, _heightFieldKey);
    }
  }

  void _changeWeightUnit(String newUnit) {
    if (newUnit == _weightUnit) return;
    _invalidateField(_FieldId.weight);
    final previousUnit = _weightUnit;
    final currentValue = _parsePositiveNumber(_weightController.text);
    setState(() {
      _weightUnit = newUnit;
    });
    if (currentValue != null) {
      double converted = currentValue;
      if (previousUnit == 'kg' && newUnit == 'lb') {
        converted = currentValue / 0.45359237;
      } else if (previousUnit == 'lb' && newUnit == 'kg') {
        converted = currentValue * 0.45359237;
      }
      _weightController.text = _formatNumber(converted);
      _validateFormField(_FieldId.weight, _weightFieldKey);
    }
  }

  void _selectCountry(String? code) {
    if (code == null) return;
    final region = _findRegion(code);
    setState(() {
      _countryCode = code;
      if (region != null) {
        _glucoseUnit = region.glucoseUnit;
      }
    });
    _countryFieldKey.currentState?.didChange(code);
    _validateDropdownField(_FieldId.country, _countryFieldKey);
  }

  void _toggleCondition(String value, bool selected) {
    setState(() {
      if (value == 'none') {
        if (selected) {
          _conditions
            ..clear()
            ..add(value);
        } else {
          _conditions.remove(value);
        }
      } else {
        _conditions.remove('none');
        if (selected) {
          _conditions.add(value);
        } else {
          _conditions.remove(value);
        }
      }
    });
    _updateFieldValidity(_FieldId.conditions, _conditions.isNotEmpty);
    unawaited(_maybeSaveSectionForField(_FieldId.conditions));
  }

  void _toggleMedication(String value, bool selected) {
    setState(() {
      if (value == 'none') {
        if (selected) {
          _medications
            ..clear()
            ..add(value);
        } else {
          _medications.remove(value);
        }
      } else {
        _medications.remove('none');
        if (selected) {
          _medications.add(value);
        } else {
          _medications.remove(value);
        }
      }
    });
    _updateFieldValidity(_FieldId.medications, _medications.isNotEmpty);
    unawaited(_maybeSaveSectionForField(_FieldId.medications));
  }

  void _updateDerivedMetrics() {
    if (!mounted) return;
    final heightValue = _parsePositiveNumber(_heightController.text);
    final weightValue = _parsePositiveNumber(_weightController.text);

    if (heightValue == null || weightValue == null) {
      if (_bmi != null) {
        setState(() => _bmi = null);
      }
      return;
    }

    final heightCm = _heightUnit == 'cm' ? heightValue : heightValue * 2.54;
    final weightKg = _weightUnit == 'kg'
        ? weightValue
        : weightValue * 0.45359237;
    final bmi = _computeBmi(heightCm, weightKg);
    if ((_bmi == null && bmi != null) ||
        (_bmi != null && bmi == null) ||
        (_bmi != null && bmi != null && (bmi - _bmi!).abs() > 0.001)) {
      setState(() => _bmi = bmi);
    }
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

  static double? _computeBmi(double heightCm, double weightKg) {
    if (heightCm <= 0) return null;
    final heightMeters = heightCm / 100;
    if (heightMeters <= 0) return null;
    final bmi = weightKg / (heightMeters * heightMeters);
    if (bmi.isNaN || bmi.isInfinite) return null;
    return bmi;
  }

  static int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hasHadBirthdayThisYear =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthdayThisYear) {
      age -= 1;
    }
    return age;
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _formatNumber(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  static _RegionOption? _findRegion(String code) {
    for (final region in _regionOptions) {
      if (region.code == code) {
        return region;
      }
    }
    return null;
  }
}

class _LifestyleAnswers {
  const _LifestyleAnswers({
    required this.wakeUpTime,
    required this.bedtime,
    required this.sleepDurationHours,
    required this.sleepQuality,
    required this.workPattern,
    required this.breakfastHabit,
    required this.mealsPerDay,
    required this.dinnerTime,
    required this.caffeineIntake,
    required this.alcoholConsumption,
    required this.smokingStatus,
    required this.energyLevel,
  });

  final TimeOfDay wakeUpTime;
  final TimeOfDay bedtime;
  final double sleepDurationHours;
  final int sleepQuality;
  final String workPattern;
  final String breakfastHabit;
  final int mealsPerDay;
  final TimeOfDay dinnerTime;
  final String caffeineIntake;
  final String alcoholConsumption;
  final String smokingStatus;
  final String energyLevel;

  Map<String, dynamic> toMap() {
    return {
      'wakeUpTime': _formatTimeOfDay(wakeUpTime),
      'bedtime': _formatTimeOfDay(bedtime),
      'sleepDurationHours': sleepDurationHours,
      'sleepQuality': sleepQuality,
      'workPattern': workPattern,
      'breakfastHabit': breakfastHabit,
      'mealsPerDay': mealsPerDay,
      'dinnerTime': _formatTimeOfDay(dinnerTime),
      'caffeineIntake': caffeineIntake,
      'alcoholConsumption': alcoholConsumption,
      'smokingStatus': smokingStatus,
      'energyLevel': energyLevel,
    };
  }
}

class _LifestyleFlowResult {
  const _LifestyleFlowResult({
    required this.lifestyle,
    required this.activity,
    required this.stressSleep,
  });

  final _LifestyleAnswers lifestyle;
  final _ActivityAnswers activity;
  final _StressSleepResult stressSleep;
}

class _ActivityNavigationResult {
  const _ActivityNavigationResult.back({
    required this.activity,
    this.stress,
    this.sleep,
    this.nutrition,
    this.psych,
  });

  final Map<String, dynamic> activity;
  final Map<String, dynamic>? stress;
  final Map<String, dynamic>? sleep;
  final Map<String, dynamic>? nutrition;
  final Map<String, dynamic>? psych;
}

class _ActivityFlowResult {
  const _ActivityFlowResult({
    required this.activity,
    required this.stressSleep,
  });

  final _ActivityAnswers activity;
  final _StressSleepResult stressSleep;
}

class _LifestyleQuestionnairePage extends StatefulWidget {
  const _LifestyleQuestionnairePage({
    this.initialAnswers,
    this.initialActivityAnswers,
    this.initialStressAnswers,
    this.initialSleepAnswers,
    this.initialNutritionAnswers,
    this.initialPsychAnswers,
    this.onLifestyleSaved,
    this.onActivitySaved,
    this.onStressSleepSaved,
    this.onNutritionSaved,
    this.onPsychSaved,
  });

  final Map<String, dynamic>? initialAnswers;
  final Map<String, dynamic>? initialActivityAnswers;
  final Map<String, dynamic>? initialStressAnswers;
  final Map<String, dynamic>? initialSleepAnswers;
  final Map<String, dynamic>? initialNutritionAnswers;
  final Map<String, dynamic>? initialPsychAnswers;
  final Future<void> Function(Map<String, dynamic> lifestyle)? onLifestyleSaved;
  final Future<void> Function(Map<String, dynamic> activity)? onActivitySaved;
  final Future<void> Function(
    Map<String, dynamic> stress,
    Map<String, dynamic> sleep,
  )? onStressSleepSaved;
  final Future<void> Function(Map<String, dynamic> nutrition)? onNutritionSaved;
  final Future<void> Function(Map<String, dynamic> psych)? onPsychSaved;

  @override
  State<_LifestyleQuestionnairePage> createState() =>
      _LifestyleQuestionnairePageState();
}

class _LifestyleQuestionnairePageState
    extends State<_LifestyleQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sleepDurationController =
      TextEditingController();

  TimeOfDay? _wakeUpTime;
  TimeOfDay? _bedtime;
  TimeOfDay? _dinnerTime;
  int _sleepQuality = 3;
  String? _workPattern;
  String? _breakfastHabit;
  int? _mealsPerDay;
  String? _caffeineIntake;
  String? _alcoholConsumption;
  String? _smokingStatus;
  String? _energyLevel;
  Map<String, dynamic>? _initialActivity;
  Map<String, dynamic>? _initialStress;
  Map<String, dynamic>? _initialSleep;
  Map<String, dynamic>? _initialNutrition;
  Map<String, dynamic>? _initialPsych;

  @override
  void initState() {
    super.initState();
    _applyInitialAnswers();
  }

  @override
  void dispose() {
    _sleepDurationController.dispose();
    super.dispose();
  }

  void _applyInitialAnswers() {
    final data = widget.initialAnswers;
    if (data == null) {
      _initialActivity = widget.initialActivityAnswers;
      _initialStress = widget.initialStressAnswers;
      _initialSleep = widget.initialSleepAnswers;
      _initialNutrition = widget.initialNutritionAnswers;
      _initialPsych = widget.initialPsychAnswers;
      return;
    }
    _wakeUpTime = _parseTimeOfDay(data['wakeUpTime']?.toString());
    _bedtime = _parseTimeOfDay(data['bedtime']?.toString());
    _dinnerTime = _parseTimeOfDay(data['dinnerTime']?.toString());
    final sleepDuration = data['sleepDurationHours'];
    final duration = sleepDuration is num
        ? sleepDuration.toDouble()
        : double.tryParse(sleepDuration?.toString() ?? '');
    if (duration != null) {
      _sleepDurationController.text = duration.toStringAsFixed(
        duration % 1 == 0 ? 0 : 1,
      );
    }
    final sleepQuality = data['sleepQuality'];
    if (sleepQuality is num) {
      _sleepQuality = sleepQuality.clamp(1, 5).round();
    }
    final meals = data['mealsPerDay'];
    if (meals is num) {
      _mealsPerDay = meals.clamp(1, 6).round();
    }
    _workPattern = data['workPattern']?.toString();
    _breakfastHabit = data['breakfastHabit']?.toString();
    _caffeineIntake = data['caffeineIntake']?.toString();
    _alcoholConsumption = data['alcoholConsumption']?.toString();
    _smokingStatus = data['smokingStatus']?.toString();
    _energyLevel = data['energyLevel']?.toString();
    _initialActivity = widget.initialActivityAnswers;
    _initialStress = widget.initialStressAnswers;
    _initialSleep = widget.initialSleepAnswers;
    _initialNutrition = widget.initialNutritionAnswers;
    _initialPsych = widget.initialPsychAnswers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
        title: const Text('Health Profile'),
      ),
      body: KeyboardDismissible(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Typical Day', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    "Let's talk about your typical day.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildTimeField(
                    context: context,
                    label: 'Wake-up time',
                    value: _wakeUpTime,
                    onPick: (picked) => setState(() => _wakeUpTime = picked),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeField(
                    context: context,
                    label: 'Bedtime',
                    value: _bedtime,
                    onPick: (picked) => setState(() => _bedtime = picked),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sleepDurationController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Average sleep duration (hours)',
                      hintText: 'e.g. 7.5',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        value?.replaceAll(',', '.') ?? '',
                      );
                      if (parsed == null || parsed <= 0) {
                        return 'Enter hours of sleep';
                      }
                      if (parsed > 24) {
                        return 'Sleep duration must be less than 24 hours';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('sleepQuality-$_sleepQuality'),
                    initialValue: _sleepQuality,
                    decoration: const InputDecoration(
                      labelText: 'Sleep quality (1–5)',
                    ),
                    items: List.generate(5, (index) {
                      final value = index + 1;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }),
                    onChanged: (value) =>
                        setState(() => _sleepQuality = value ?? 3),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('workPattern-${_workPattern ?? 'unset'}'),
                    initialValue: _workPattern,
                    decoration: const InputDecoration(
                      labelText: 'Work pattern',
                    ),
                    items: _workPatternOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _workPattern = value),
                    validator: (value) =>
                        value == null ? 'Select your work pattern' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('breakfast-${_breakfastHabit ?? 'unset'}'),
                    initialValue: _breakfastHabit,
                    decoration: const InputDecoration(
                      labelText: 'Breakfast habit',
                    ),
                    items: _breakfastHabitOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _breakfastHabit = value),
                    validator: (value) =>
                        value == null ? 'Tell us about breakfast' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('meals-${_mealsPerDay ?? 'unset'}'),
                    initialValue: _mealsPerDay,
                    decoration: const InputDecoration(
                      labelText: 'Number of main meals per day',
                    ),
                    items: List.generate(6, (index) {
                      final value = index + 1;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }),
                    onChanged: (value) => setState(() => _mealsPerDay = value),
                    validator: (value) =>
                        value == null ? 'Select meals per day' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeField(
                    context: context,
                    label: 'Typical dinner time',
                    value: _dinnerTime,
                    onPick: (picked) => setState(() => _dinnerTime = picked),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('caffeine-${_caffeineIntake ?? 'unset'}'),
                    initialValue: _caffeineIntake,
                    decoration: const InputDecoration(
                      labelText: 'Caffeine intake per day',
                    ),
                    items: _caffeineOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _caffeineIntake = value),
                    validator: (value) =>
                        value == null ? 'Select caffeine intake' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('alcohol-${_alcoholConsumption ?? 'unset'}'),
                    initialValue: _alcoholConsumption,
                    decoration: const InputDecoration(
                      labelText: 'Alcohol consumption',
                    ),
                    items: _alcoholOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _alcoholConsumption = value),
                    validator: (value) =>
                        value == null ? 'Select alcohol consumption' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('smoking-${_smokingStatus ?? 'unset'}'),
                    initialValue: _smokingStatus,
                    decoration: const InputDecoration(
                      labelText: 'Smoking status',
                    ),
                    items: _smokingOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _smokingStatus = value),
                    validator: (value) =>
                        value == null ? 'Select smoking status' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('energy-${_energyLevel ?? 'unset'}'),
                    initialValue: _energyLevel,
                    decoration: const InputDecoration(
                      labelText: 'Perceived energy level throughout the day',
                    ),
                    items: _energyLevelOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _energyLevel = value),
                    validator: (value) =>
                        value == null ? 'Select energy level' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  FormField<TimeOfDay> _buildTimeField({
    required BuildContext context,
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay> onPick,
  }) {
    return FormField<TimeOfDay>(
      key: ValueKey(
        '$label-${value != null ? _formatTimeOfDay(value) : 'unset'}',
      ),
      initialValue: value,
      validator: (val) => val == null ? 'Select $label' : null,
      builder: (state) {
        final display = state.value != null
            ? MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(state.value!, alwaysUse24HourFormat: false)
            : 'Select';
        final error = state.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              subtitle: Text(display),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      state.value ?? const TimeOfDay(hour: 7, minute: 0),
                );
                if (picked != null) {
                  state.didChange(picked);
                  onPick(picked);
                }
              },
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final sleepDuration = double.parse(
      _sleepDurationController.text.replaceAll(',', '.'),
    );
    final answers = _LifestyleAnswers(
      wakeUpTime: _wakeUpTime!,
      bedtime: _bedtime!,
      sleepDurationHours: sleepDuration,
      sleepQuality: _sleepQuality,
      workPattern: _workPattern!,
      breakfastHabit: _breakfastHabit!,
      mealsPerDay: _mealsPerDay!,
      dinnerTime: _dinnerTime!,
      caffeineIntake: _caffeineIntake!,
      alcoholConsumption: _alcoholConsumption!,
      smokingStatus: _smokingStatus!,
      energyLevel: _energyLevel!,
    );
    final lifestyleMap = answers.toMap();
    if (widget.onLifestyleSaved != null) {
      await widget.onLifestyleSaved!(
        Map<String, dynamic>.from(lifestyleMap),
      );
      if (!mounted) {
        return;
      }
    }
    final activityOutcome = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => _ActivityQuestionnairePage(
          initialAnswers: _initialActivity,
          initialStressAnswers: _initialStress,
          initialSleepAnswers: _initialSleep,
          initialNutritionAnswers: _initialNutrition,
          initialPsychAnswers: _initialPsych,
          onActivitySaved: widget.onActivitySaved,
          onStressSleepSaved: widget.onStressSleepSaved,
          onNutritionSaved: widget.onNutritionSaved,
          onPsychSaved: widget.onPsychSaved,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) {
      return;
    }

    if (activityOutcome is _ActivityNavigationResult) {
      final activityMap =
          Map<String, dynamic>.from(activityOutcome.activity);
      final stressMap = activityOutcome.stress != null
          ? Map<String, dynamic>.from(activityOutcome.stress!)
          : null;
      final sleepMap = activityOutcome.sleep != null
          ? Map<String, dynamic>.from(activityOutcome.sleep!)
          : null;
      final nutritionMap = activityOutcome.nutrition != null
          ? Map<String, dynamic>.from(activityOutcome.nutrition!)
          : null;
      final psychMap = activityOutcome.psych != null
          ? Map<String, dynamic>.from(activityOutcome.psych!)
          : null;

      if (widget.onActivitySaved != null) {
        await widget.onActivitySaved!(Map<String, dynamic>.from(activityMap));
        if (!mounted) {
          return;
        }
      }
      if (stressMap != null && sleepMap != null &&
          widget.onStressSleepSaved != null) {
        await widget.onStressSleepSaved!(
          Map<String, dynamic>.from(stressMap),
          Map<String, dynamic>.from(sleepMap),
        );
        if (!mounted) {
          return;
        }
      }
      if (nutritionMap != null && widget.onNutritionSaved != null) {
        await widget.onNutritionSaved!(
          Map<String, dynamic>.from(nutritionMap),
        );
        if (!mounted) {
          return;
        }
      }
      if (psychMap != null && widget.onPsychSaved != null) {
        await widget.onPsychSaved!(Map<String, dynamic>.from(psychMap));
        if (!mounted) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _initialActivity = activityMap;
        if (stressMap != null) {
          _initialStress = stressMap;
        }
        if (sleepMap != null) {
          _initialSleep = sleepMap;
        }
        if (nutritionMap != null) {
          _initialNutrition = nutritionMap;
        }
        if (psychMap != null) {
          _initialPsych = psychMap;
        }
      });
      return;
    }

    if (activityOutcome is! _ActivityFlowResult) {
      return;
    }

    final activityResult = activityOutcome;

    final activityMap = activityResult.activity.toMap();
    final stressMap = activityResult.stressSleep.toStressMapWithLoad();
    final sleepMap = activityResult.stressSleep.toSleepMap();
    final nutritionMap = activityResult.stressSleep.toNutritionMap();
    final psychMap = activityResult.stressSleep.toPsychMap();

    _initialActivity = activityMap;
    _initialStress = stressMap;
    _initialSleep = sleepMap;
    _initialNutrition = nutritionMap;
    _initialPsych = psychMap;

    if (widget.onActivitySaved != null) {
      await widget.onActivitySaved!(Map<String, dynamic>.from(activityMap));
    }
    if (widget.onStressSleepSaved != null) {
      await widget.onStressSleepSaved!(
        Map<String, dynamic>.from(stressMap),
        Map<String, dynamic>.from(sleepMap),
      );
      if (!mounted) {
        return;
      }
    }
    if (widget.onNutritionSaved != null) {
      await widget.onNutritionSaved!(
        Map<String, dynamic>.from(nutritionMap),
      );
    }
    if (widget.onPsychSaved != null) {
      await widget.onPsychSaved!(Map<String, dynamic>.from(psychMap));
    }

    Navigator.of(context).pop(
      _LifestyleFlowResult(
        lifestyle: answers,
        activity: activityResult.activity,
        stressSleep: activityResult.stressSleep,
      ),
    );
  }
}

class _ActivityAnswers {
  const _ActivityAnswers({
    required this.vigorousDays,
    required this.vigorousMinutes,
    required this.moderateDays,
    required this.moderateMinutes,
    required this.walkingDays,
    required this.walkingMinutes,
    required this.sittingHours,
  });

  final int vigorousDays;
  final double vigorousMinutes;
  final int moderateDays;
  final double moderateMinutes;
  final int walkingDays;
  final double walkingMinutes;
  final double sittingHours;

  double get metMinutesWeek =>
      (vigorousDays * vigorousMinutes * 8.0) +
      (moderateDays * moderateMinutes * 4.0) +
      (walkingDays * walkingMinutes * 3.3);

  double get activityIndex {
    const double maxMet = 6000; // approximate vigorous target
    final index = (metMinutesWeek / maxMet) * 100;
    if (index.isNaN) return 0;
    return index.clamp(0, 100);
  }

  String get activityLevel {
    final index = activityIndex;
    if (index < 33) return 'Low';
    if (index < 67) return 'Moderate';
    return 'High';
  }

  Map<String, dynamic> toMap() {
    return {
      'vigorousDaysPerWeek': vigorousDays,
      'vigorousMinutesPerDay': vigorousMinutes,
      'moderateDaysPerWeek': moderateDays,
      'moderateMinutesPerDay': moderateMinutes,
      'walkingDaysPerWeek': walkingDays,
      'walkingMinutesPerDay': walkingMinutes,
      'sittingHoursPerDay': sittingHours,
      'metMinutesWeek': metMinutesWeek,
      'activityIndex': activityIndex,
      'activityLevel': activityLevel,
    };
  }
}

class _StressAnswers {
  const _StressAnswers({required this.responses});

  final List<int> responses;

  double get normalizedScore {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    return (total / (responses.length * 4)) * 100;
  }

  Map<String, dynamic> toMap() {
    return {'items': responses, 'index': normalizedScore};
  }
}

class _SleepAnswers {
  const _SleepAnswers({required this.responses});

  final List<int> responses;

  double get normalizedScore {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    final maxScore = responses.length * 4;
    if (maxScore == 0) return 0;
    final inverted = 1 - (total / maxScore);
    return inverted * 100;
  }

  Map<String, dynamic> toMap() {
    return {'items': responses, 'index': normalizedScore};
  }
}

class _ActivityQuestionnairePage extends StatefulWidget {
  const _ActivityQuestionnairePage({
    this.initialAnswers,
    this.initialStressAnswers,
    this.initialSleepAnswers,
    this.initialNutritionAnswers,
    this.initialPsychAnswers,
    this.onActivitySaved,
    this.onStressSleepSaved,
    this.onNutritionSaved,
    this.onPsychSaved,
  });

  final Map<String, dynamic>? initialAnswers;
  final Map<String, dynamic>? initialStressAnswers;
  final Map<String, dynamic>? initialSleepAnswers;
  final Map<String, dynamic>? initialNutritionAnswers;
  final Map<String, dynamic>? initialPsychAnswers;
  final Future<void> Function(Map<String, dynamic> activity)? onActivitySaved;
  final Future<void> Function(
    Map<String, dynamic> stress,
    Map<String, dynamic> sleep,
  )? onStressSleepSaved;
  final Future<void> Function(Map<String, dynamic> nutrition)? onNutritionSaved;
  final Future<void> Function(Map<String, dynamic> psych)? onPsychSaved;

  @override
  State<_ActivityQuestionnairePage> createState() =>
      _ActivityQuestionnairePageState();
}

class _ActivityQuestionnairePageState
    extends State<_ActivityQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vigorousMinutesController =
      TextEditingController();
  final TextEditingController _moderateMinutesController =
      TextEditingController();
  final TextEditingController _walkingMinutesController =
      TextEditingController();
  final TextEditingController _sittingHoursController = TextEditingController();

  int? _vigorousDays;
  int? _moderateDays;
  int? _walkingDays;
  Map<String, dynamic>? _initialStress;
  Map<String, dynamic>? _initialSleep;
  Map<String, dynamic>? _initialNutrition;
  Map<String, dynamic>? _initialPsych;

  @override
  void initState() {
    super.initState();
    _applyInitialAnswers();
  }

  @override
  void dispose() {
    _vigorousMinutesController.dispose();
    _moderateMinutesController.dispose();
    _walkingMinutesController.dispose();
    _sittingHoursController.dispose();
    super.dispose();
  }

  void _applyInitialAnswers() {
    final data = widget.initialAnswers;
    if (data == null) {
      _initialStress = widget.initialStressAnswers;
      _initialSleep = widget.initialSleepAnswers;
      _initialNutrition = widget.initialNutritionAnswers;
      _initialPsych = widget.initialPsychAnswers;
      return;
    }
    final vigDays = data['vigorousDaysPerWeek'];
    if (vigDays is num) {
      _vigorousDays = vigDays.clamp(0, 7).round();
    }
    final vigMinutes = data['vigorousMinutesPerDay'];
    if (vigMinutes is num) {
      _vigorousMinutesController.text = vigMinutes.toDouble().toStringAsFixed(
        vigMinutes % 1 == 0 ? 0 : 1,
      );
    }
    final modDays = data['moderateDaysPerWeek'];
    if (modDays is num) {
      _moderateDays = modDays.clamp(0, 7).round();
    }
    final modMinutes = data['moderateMinutesPerDay'];
    if (modMinutes is num) {
      _moderateMinutesController.text = modMinutes.toDouble().toStringAsFixed(
        modMinutes % 1 == 0 ? 0 : 1,
      );
    }
    final walkDays = data['walkingDaysPerWeek'];
    if (walkDays is num) {
      _walkingDays = walkDays.clamp(0, 7).round();
    }
    final walkMinutes = data['walkingMinutesPerDay'];
    if (walkMinutes is num) {
      _walkingMinutesController.text = walkMinutes.toDouble().toStringAsFixed(
        walkMinutes % 1 == 0 ? 0 : 1,
      );
    }
    final sittingHours = data['sittingHoursPerDay'];
    if (sittingHours is num) {
      _sittingHoursController.text = sittingHours.toDouble().toStringAsFixed(
        sittingHours % 1 == 0 ? 0 : 1,
      );
    }
    _initialStress = widget.initialStressAnswers;
    _initialSleep = widget.initialSleepAnswers;
    _initialNutrition = widget.initialNutritionAnswers;
    _initialPsych = widget.initialPsychAnswers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBackToLifestyle();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBackToLifestyle),
          title: const Text('Health Profile'),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Activity & Movement',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's capture your weekly activity.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildDaysDropdown(
                      label: 'Days per week with vigorous activity',
                      value: _vigorousDays,
                      onChanged: (value) =>
                          setState(() => _vigorousDays = value),
                    ),
                    const SizedBox(height: 12),
                    _buildMinutesField(
                      controller: _vigorousMinutesController,
                      label: 'Average minutes per day of vigorous activity',
                      requirePositive: (_vigorousDays ?? 0) > 0,
                    ),
                    const SizedBox(height: 12),
                    _buildDaysDropdown(
                      label: 'Days per week with moderate activity',
                      value: _moderateDays,
                      onChanged: (value) =>
                          setState(() => _moderateDays = value),
                    ),
                    const SizedBox(height: 12),
                    _buildMinutesField(
                      controller: _moderateMinutesController,
                      label: 'Average minutes per day of moderate activity',
                      requirePositive: (_moderateDays ?? 0) > 0,
                    ),
                    const SizedBox(height: 12),
                    _buildDaysDropdown(
                      label: 'Days per week walking ≥10 minutes continuously',
                      value: _walkingDays,
                      onChanged: (value) =>
                          setState(() => _walkingDays = value),
                    ),
                    const SizedBox(height: 12),
                    _buildMinutesField(
                      controller: _walkingMinutesController,
                      label: 'Average minutes per day walking',
                      requirePositive: (_walkingDays ?? 0) > 0,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sittingHoursController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Typical sitting time per day (hours)',
                        hintText: 'e.g. 8',
                      ),
                      validator: (value) {
                        final parsed = _parseNonNegative(value);
                        if (parsed == null) {
                          return 'Enter sitting hours per day';
                        }
                        if (parsed > 24) {
                          return 'Must be 24 hours or less';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _currentActivityMap() {
    final vigorousMinutes =
        _parseNonNegative(_vigorousMinutesController.text) ?? 0;
    final moderateMinutes =
        _parseNonNegative(_moderateMinutesController.text) ?? 0;
    final walkingMinutes =
        _parseNonNegative(_walkingMinutesController.text) ?? 0;
    final sittingHours = _parseNonNegative(_sittingHoursController.text) ?? 0;

    final hasInput =
        (_vigorousDays ?? 0) != 0 ||
        (_moderateDays ?? 0) != 0 ||
        (_walkingDays ?? 0) != 0 ||
        vigorousMinutes != 0 ||
        moderateMinutes != 0 ||
        walkingMinutes != 0 ||
        sittingHours != 0;

    if (!hasInput) {
      final existing = widget.initialAnswers;
      if (existing != null) {
        return Map<String, dynamic>.from(existing);
      }
    }

    final draft = _ActivityAnswers(
      vigorousDays: _vigorousDays ?? 0,
      vigorousMinutes: vigorousMinutes,
      moderateDays: _moderateDays ?? 0,
      moderateMinutes: moderateMinutes,
      walkingDays: _walkingDays ?? 0,
      walkingMinutes: walkingMinutes,
      sittingHours: sittingHours,
    );
    return draft.toMap();
  }

  DropdownButtonFormField<int> _buildDaysDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-${value ?? 'unset'}'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: List.generate(8, (index) {
        return DropdownMenuItem(value: index, child: Text(index.toString()));
      }),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Select $label' : null,
    );
  }

  TextFormField _buildMinutesField({
    required TextEditingController controller,
    required String label,
    required bool requirePositive,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: 'e.g. 30'),
      validator: (value) {
        final parsed = _parseNonNegative(value);
        if (requirePositive) {
          if (parsed == null || parsed <= 0) {
            return 'Enter minutes for this activity';
          }
        } else if (parsed != null && parsed < 0) {
          return 'Minutes cannot be negative';
        }
        return null;
      },
    );
  }

  double? _parseNonNegative(String? value) {
    final cleaned = value?.replaceAll(',', '.').trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final vigorousMinutes =
        _parseNonNegative(_vigorousMinutesController.text) ?? 0;
    final moderateMinutes =
        _parseNonNegative(_moderateMinutesController.text) ?? 0;
    final walkingMinutes =
        _parseNonNegative(_walkingMinutesController.text) ?? 0;
    final sittingHours = _parseNonNegative(_sittingHoursController.text) ?? 0;

    final activityAnswers = _ActivityAnswers(
      vigorousDays: _vigorousDays ?? 0,
      vigorousMinutes: vigorousMinutes,
      moderateDays: _moderateDays ?? 0,
      moderateMinutes: moderateMinutes,
      walkingDays: _walkingDays ?? 0,
      walkingMinutes: walkingMinutes,
      sittingHours: sittingHours,
    );
    final activityMap = activityAnswers.toMap();
    if (widget.onActivitySaved != null) {
      await widget.onActivitySaved!(Map<String, dynamic>.from(activityMap));
      if (!mounted) {
        return;
      }
    }
    final stressOutcome = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => _StressSleepQuestionnairePage(
          initialStressAnswers: _initialStress,
          initialSleepAnswers: _initialSleep,
          initialNutritionAnswers: _initialNutrition,
          initialPsychAnswers: _initialPsych,
          onStressSleepSaved: widget.onStressSleepSaved,
          onNutritionSaved: widget.onNutritionSaved,
          onPsychSaved: widget.onPsychSaved,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) {
      return;
    }

    if (stressOutcome is _StressSleepNavigationResult) {
      final stressMap = Map<String, dynamic>.from(stressOutcome.stress);
      final sleepMap = Map<String, dynamic>.from(stressOutcome.sleep);
      final nutritionMap = stressOutcome.nutrition != null
          ? Map<String, dynamic>.from(stressOutcome.nutrition!)
          : null;
      final psychMap = stressOutcome.psych != null
          ? Map<String, dynamic>.from(stressOutcome.psych!)
          : null;

      if (widget.onStressSleepSaved != null) {
        await widget.onStressSleepSaved!(
          Map<String, dynamic>.from(stressMap),
          Map<String, dynamic>.from(sleepMap),
        );
        if (!mounted) {
          return;
        }
      }
      if (nutritionMap != null && widget.onNutritionSaved != null) {
        await widget.onNutritionSaved!(
          Map<String, dynamic>.from(nutritionMap),
        );
        if (!mounted) {
          return;
        }
      }
      if (psychMap != null && widget.onPsychSaved != null) {
        await widget.onPsychSaved!(Map<String, dynamic>.from(psychMap));
        if (!mounted) {
          return;
        }
      }

      _initialStress = stressMap;
      _initialSleep = sleepMap;
      if (nutritionMap != null) {
        _initialNutrition = nutritionMap;
      }
      if (psychMap != null) {
        _initialPsych = psychMap;
      }
      return;
    }

    if (stressOutcome is! _StressSleepResult) {
      return;
    }

    final stressSleepResult = stressOutcome;

    final stressMap = stressSleepResult.toStressMapWithLoad();
    final sleepMap = stressSleepResult.toSleepMap();
    final nutritionMap = stressSleepResult.toNutritionMap();
    final psychMap = stressSleepResult.toPsychMap();

    _initialStress = stressMap;
    _initialSleep = sleepMap;
    _initialNutrition = nutritionMap;
    _initialPsych = psychMap;

    if (widget.onStressSleepSaved != null) {
      await widget.onStressSleepSaved!(
        Map<String, dynamic>.from(stressMap),
        Map<String, dynamic>.from(sleepMap),
      );
      if (!mounted) {
        return;
      }
    }
    if (widget.onNutritionSaved != null) {
      await widget.onNutritionSaved!(
        Map<String, dynamic>.from(nutritionMap),
      );
      if (!mounted) {
        return;
      }
    }
    if (widget.onPsychSaved != null) {
      await widget.onPsychSaved!(Map<String, dynamic>.from(psychMap));
      if (!mounted) {
        return;
      }
    }

    Navigator.of(context).pop(
      _ActivityFlowResult(
        activity: activityAnswers,
        stressSleep: stressSleepResult,
      ),
    );
  }

  void _handleBackToLifestyle() {
    final stressCopy = _initialStress != null
        ? Map<String, dynamic>.from(_initialStress!)
        : null;
    final sleepCopy = _initialSleep != null
        ? Map<String, dynamic>.from(_initialSleep!)
        : null;
    final nutritionCopy = _initialNutrition != null
        ? Map<String, dynamic>.from(_initialNutrition!)
        : null;
    final psychCopy = _initialPsych != null
        ? Map<String, dynamic>.from(_initialPsych!)
        : null;
    Navigator.of(context).pop(
      _ActivityNavigationResult.back(
        activity: _currentActivityMap(),
        stress: stressCopy,
        sleep: sleepCopy,
        nutrition: nutritionCopy,
        psych: psychCopy,
      ),
    );
  }
}

class _StressSleepResult {
  const _StressSleepResult({
    required this.stress,
    required this.sleep,
    required this.nutrition,
    required this.psych,
  });

  final _StressAnswers stress;
  final _SleepAnswers sleep;
  final _NutritionResult nutrition;
  final _PsychResult psych;

  Map<String, dynamic> toStressMap() => stress.toMap();
  Map<String, dynamic> toStressMapWithLoad() {
    final map = stress.toMap();
    map['loadIndex'] = stressLoad;
    return map;
  }

  Map<String, dynamic> toSleepMap() => sleep.toMap();
  Map<String, dynamic> toNutritionMap() => nutrition.toMap();
  Map<String, dynamic> toPsychMap() => psych.toMap();
  double get stressLoad =>
      (stress.normalizedScore * 0.6) + ((100 - sleep.normalizedScore) * 0.4);
}

class _StressSleepNavigationResult {
  const _StressSleepNavigationResult.back({
    required this.stress,
    required this.sleep,
    this.nutrition,
    this.psych,
  });

  final Map<String, dynamic> stress;
  final Map<String, dynamic> sleep;
  final Map<String, dynamic>? nutrition;
  final Map<String, dynamic>? psych;
}

class _NutritionAnswers {
  const _NutritionAnswers({required this.responses});

  final List<int> responses;

  double get index {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    return (total / (responses.length * 4)) * 100;
  }

  Map<String, dynamic> toMap() {
    return {'items': responses, 'index': index};
  }
}

class _NutritionResult {
  const _NutritionResult({required this.nutrition});

  final _NutritionAnswers nutrition;

  Map<String, dynamic> toMap() => nutrition.toMap();
}

class _NutritionNavigationResult {
  const _NutritionNavigationResult.back({required this.draft});

  final Map<String, dynamic> draft;
}

class _PsychQuestionnairePage extends StatefulWidget {
  const _PsychQuestionnairePage({
    this.initialAnswers,
    this.onPsychSaved,
  });

  final Map<String, dynamic>? initialAnswers;
  final Future<void> Function(Map<String, dynamic> psych)? onPsychSaved;

  @override
  State<_PsychQuestionnairePage> createState() =>
      _PsychQuestionnairePageState();
}

class _PsychQuestionnairePageState extends State<_PsychQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final List<int> _responses = List<int>.filled(5, 2);

  static const _prompts = [
    'Feeling overwhelmed by the demands of diabetes',
    'Feeling discouraged with your diabetes efforts',
    'Feeling that you are failing with your diabetes routine',
    'Feeling angry, scared, or depressed about living with diabetes',
    'Feeling that you are not sticking closely enough to good meal or testing plans',
  ];

  static const _optionLabels = [
    'Not a problem',
    'Slight problem',
    'Moderate problem',
    'Serious problem',
    'Major problem',
  ];

  @override
  void initState() {
    super.initState();
    final raw = widget.initialAnswers;
    if (raw is Map) {
      final map = <String, dynamic>{};
      (raw as Map).forEach((key, value) {
        map[key.toString()] = value;
      });
      final itemsRaw = map['items'];
      if (itemsRaw is List) {
        final items = itemsRaw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList();
        for (var i = 0; i < _responses.length && i < items.length; i++) {
          _responses[i] = items[i].clamp(0, 4);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBackToNutrition();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBackToNutrition),
          title: const Text('Health Profile'),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Emotional wellbeing',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How have you felt about diabetes recently?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_responses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildQuestion(index, theme),
                      );
                    }),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('Finish'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(int index, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_prompts[index], style: theme.textTheme.bodyLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_optionLabels.length, (value) {
            final selected = _responses[index] == value;
            return ChoiceChip(
              label: Text(_optionLabels[value]),
              selected: selected,
              onSelected: (_) => setState(() {
                _responses[index] = value;
              }),
            );
          }),
        ),
      ],
    );
  }

  void _handleBackToNutrition() {
    Navigator.of(context).pop(
      _PsychNavigationResult.backToNutrition(
        responses: List<int>.from(_responses),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final result = _PsychResult(responses: List<int>.from(_responses));
    if (widget.onPsychSaved != null) {
      await widget.onPsychSaved!(
        Map<String, dynamic>.from(result.toMap()),
      );
      if (!mounted) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(result);
  }
}

class _PsychResult {
  const _PsychResult({required this.responses});

  final List<int> responses;

  double get distressIndex {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    return (total / (responses.length * 4)) * 100;
  }

  bool get supportNeeded => distressIndex > 60;

  Map<String, dynamic> toMap() {
    return {
      'items': responses,
      'index': distressIndex,
      'supportNeeded': supportNeeded,
    };
  }
}

class _PsychNavigationResult {
  const _PsychNavigationResult.backToNutrition({required this.responses})
    : goBackToNutrition = true;

  final bool goBackToNutrition;
  final List<int> responses;
}

class _NutritionQuestionnairePage extends StatefulWidget {
  const _NutritionQuestionnairePage({
    this.initialAnswers,
    this.onNutritionSaved,
  });

  final Map<String, dynamic>? initialAnswers;
  final Future<void> Function(Map<String, dynamic> nutrition)? onNutritionSaved;

  @override
  State<_NutritionQuestionnairePage> createState() =>
      _NutritionQuestionnairePageState();
}

class _NutritionQuestionnairePageState
    extends State<_NutritionQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final List<int> _responses = List<int>.filled(7, 2);

  static const _nutritionPrompts = [
    'Daily fruit and vegetable servings',
    'Whole grain servings per day',
    'Frequency of fried or high-fat foods',
    'Sugary drinks per week',
    'Eating dinner within 2 hours of bedtime',
    'Fast food or takeout frequency',
    'Processed snack intake',
  ];

  static const _optionLabels = [
    'Never / rarely',
    '1–2 times',
    '3–4 times',
    '5–6 times',
    'Daily / most days',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialAnswers;
    if (data is Map<String, dynamic> && data['items'] is List) {
      final items = (data['items'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList();
      for (var i = 0; i < _responses.length && i < items.length; i++) {
        _responses[i] = items[i].clamp(0, 4);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleBack()),
          title: const Text('Health Profile'),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nutrition patterns',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tell us about your usual food choices.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_responses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNutritionQuestion(index, theme),
                      );
                    }),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionQuestion(int index, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_nutritionPrompts[index], style: theme.textTheme.bodyLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_optionLabels.length, (value) {
            final selected = _responses[index] == value;
            return ChoiceChip(
              label: Text(_optionLabels[value]),
              selected: selected,
              onSelected: (_) => setState(() {
                _responses[index] = value;
              }),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final result = _NutritionResult(
      nutrition: _NutritionAnswers(responses: List<int>.from(_responses)),
    );
    final map = result.toMap();
    if (widget.onNutritionSaved != null) {
      await widget.onNutritionSaved!(Map<String, dynamic>.from(map));
      if (!mounted) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(result);
  }

  Future<void> _handleBack() async {
    final draft = _NutritionNavigationResult.back(
      draft: _NutritionAnswers(responses: List<int>.from(_responses)).toMap(),
    );
    if (widget.onNutritionSaved != null) {
      await widget.onNutritionSaved!(
        Map<String, dynamic>.from(draft.draft),
      );
      if (!mounted) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(draft);
  }
}

class _StressSleepQuestionnairePage extends StatefulWidget {
  const _StressSleepQuestionnairePage({
    this.initialStressAnswers,
    this.initialSleepAnswers,
    this.initialNutritionAnswers,
    this.initialPsychAnswers,
    this.onStressSleepSaved,
    this.onNutritionSaved,
    this.onPsychSaved,
  });

  final Map<String, dynamic>? initialStressAnswers;
  final Map<String, dynamic>? initialSleepAnswers;
  final Map<String, dynamic>? initialNutritionAnswers;
  final Map<String, dynamic>? initialPsychAnswers;
  final Future<void> Function(
    Map<String, dynamic> stress,
    Map<String, dynamic> sleep,
  )? onStressSleepSaved;
  final Future<void> Function(Map<String, dynamic> nutrition)? onNutritionSaved;
  final Future<void> Function(Map<String, dynamic> psych)? onPsychSaved;

  @override
  State<_StressSleepQuestionnairePage> createState() =>
      _StressSleepQuestionnairePageState();
}

class _StressSleepQuestionnairePageState
    extends State<_StressSleepQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();

  final List<int> _stressResponses = List<int>.filled(4, 0);
  final List<int> _sleepResponses = List<int>.filled(7, 0);
  Map<String, dynamic>? _initialNutrition;
  Map<String, dynamic>? _initialPsych;

  static const _stressPrompts = [
    'Felt unable to control important things?',
    'Felt confident about handling personal problems?',
    'Felt things were going your way?',
    'Felt difficulties were piling up too high?',
  ];

  static const _sleepPrompts = [
    'Difficulty falling asleep',
    'Difficulty staying asleep',
    'Problems waking too early',
    'Sleep satisfaction',
    'Sleep problems interfering with daily life',
    'Noticeability of sleep problems to others',
    'Worry about current sleep difficulties',
  ];

  @override
  void initState() {
    super.initState();
    _applyInitialAnswers();
  }

  void _applyInitialAnswers() {
    final stressRaw = widget.initialStressAnswers;
    if (stressRaw is Map) {
      final stress = Map<String, dynamic>.from(stressRaw as Map);
      final itemsRaw = stress['items'];
      if (itemsRaw is List) {
        final items = itemsRaw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList();
        for (var i = 0; i < _stressResponses.length && i < items.length; i++) {
          _stressResponses[i] = items[i].clamp(0, 4);
        }
      }
    }
    final sleepRaw = widget.initialSleepAnswers;
    if (sleepRaw is Map) {
      final sleep = Map<String, dynamic>.from(sleepRaw as Map);
      final itemsRaw = sleep['items'];
      if (itemsRaw is List) {
        final items = itemsRaw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList();
        for (var i = 0; i < _sleepResponses.length && i < items.length; i++) {
          _sleepResponses[i] = items[i].clamp(0, 4);
        }
      }
    }
    final nutritionRaw = widget.initialNutritionAnswers;
    if (nutritionRaw is Map) {
      final nutrition = <String, dynamic>{};
      (nutritionRaw as Map).forEach((key, value) {
        nutrition[key.toString()] = value;
      });
      _initialNutrition = nutrition;
    }
    final psychRaw = widget.initialPsychAnswers;
    if (psychRaw is Map) {
      final psych = <String, dynamic>{};
      (psychRaw as Map).forEach((key, value) {
        psych[key.toString()] = value;
      });
      _initialPsych = psych;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBackToActivity();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBackToActivity),
          title: const Text('Health Profile'),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Stress & Sleep',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share how stress and sleep feel over the past few weeks.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Perceived Stress (last month)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_stressResponses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildStressQuestion(index),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Sleep quality (past 2 weeks)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_sleepResponses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSleepQuestion(index),
                      );
                    }),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleBackToActivity() {
    final stressAnswers = _StressAnswers(
      responses: List<int>.from(_stressResponses),
    );
    final sleepAnswers = _SleepAnswers(
      responses: List<int>.from(_sleepResponses),
    );
    final stressMap = stressAnswers.toMap()
      ..['loadIndex'] = _computeStressLoad(stressAnswers, sleepAnswers);
    final sleepMap = sleepAnswers.toMap();
    final nutritionCopy = _initialNutrition != null
        ? Map<String, dynamic>.from(_initialNutrition!)
        : null;
    final psychCopy = _initialPsych != null
        ? Map<String, dynamic>.from(_initialPsych!)
        : null;
    Navigator.of(context).pop(
      _StressSleepNavigationResult.back(
        stress: stressMap,
        sleep: sleepMap,
        nutrition: nutritionCopy,
        psych: psychCopy,
      ),
    );
  }

  double _computeStressLoad(
    _StressAnswers stressAnswers,
    _SleepAnswers sleepAnswers,
  ) {
    return (stressAnswers.normalizedScore * 0.6) +
        ((100 - sleepAnswers.normalizedScore) * 0.4);
  }

  Widget _buildStressQuestion(int index) {
    final options = const [
      'Never',
      'Almost never',
      'Sometimes',
      'Fairly often',
      'Very often',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_stressPrompts[index]),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: List.generate(options.length, (value) {
            final selected = _stressResponses[index] == value;
            return ChoiceChip(
              label: Text(options[value]),
              selected: selected,
              onSelected: (_) => setState(() {
                _stressResponses[index] = value;
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSleepQuestion(int index) {
    final options = List<String>.generate(5, (value) => value.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_sleepPrompts[index]),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: List.generate(options.length, (value) {
            final selected = _sleepResponses[index] == value;
            return ChoiceChip(
              label: Text(value.toString()),
              selected: selected,
              onSelected: (_) => setState(() {
                _sleepResponses[index] = value;
              }),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final stress = _StressAnswers(responses: List<int>.from(_stressResponses));
    final sleep = _SleepAnswers(responses: List<int>.from(_sleepResponses));
    final stressMap = stress.toMap()
      ..['loadIndex'] = _computeStressLoad(stress, sleep);
    final sleepMap = sleep.toMap();

    if (widget.onStressSleepSaved != null) {
      await widget.onStressSleepSaved!(
        Map<String, dynamic>.from(stressMap),
        Map<String, dynamic>.from(sleepMap),
      );
    }

    final firstNutritionOutcome = await Navigator.of(context)
        .push<Object?>(
          MaterialPageRoute(
            builder: (_) =>
                _NutritionQuestionnairePage(
              initialAnswers: _initialNutrition,
              onNutritionSaved: widget.onNutritionSaved,
            ),
            fullscreenDialog: true,
          ),
        );

    if (!mounted) {
      return;
    }

    if (firstNutritionOutcome is _NutritionNavigationResult) {
      final draft = Map<String, dynamic>.from(firstNutritionOutcome.draft);
      _initialNutrition = draft;
      return;
    }

    if (firstNutritionOutcome is! _NutritionResult) {
      return;
    }

    final firstNutritionResult = firstNutritionOutcome;
    final firstNutritionMap = firstNutritionResult.toMap();
    _initialNutrition = firstNutritionMap;

    var currentNutritionResult = firstNutritionResult;

    Map<String, dynamic>? psychInitialAnswers = _initialPsych;

    while (mounted) {
      final psychOutcome = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) =>
              _PsychQuestionnairePage(
            initialAnswers: psychInitialAnswers,
            onPsychSaved: widget.onPsychSaved,
          ),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) {
        return;
      }

      if (psychOutcome is _PsychResult) {
        final psychMap = psychOutcome.toMap();
        _initialPsych = psychMap;
        if (widget.onPsychSaved != null) {
          await widget.onPsychSaved!(Map<String, dynamic>.from(psychMap));
        }
        Navigator.of(context).pop(
          _StressSleepResult(
            stress: stress,
            sleep: sleep,
            nutrition: currentNutritionResult,
            psych: psychOutcome,
          ),
        );
        return;
      }

      if (psychOutcome is _PsychNavigationResult &&
          psychOutcome.goBackToNutrition) {
        psychInitialAnswers = {'items': List<int>.from(psychOutcome.responses)};
        _initialPsych = psychInitialAnswers;

        final updatedNutritionOutcome = await Navigator.of(context)
            .push<Object?>(
              MaterialPageRoute(
                builder: (_) => _NutritionQuestionnairePage(
                  initialAnswers: _initialNutrition,
                  onNutritionSaved: widget.onNutritionSaved,
                ),
                fullscreenDialog: true,
              ),
            );

        if (!mounted) {
          return;
        }

        if (updatedNutritionOutcome is _NutritionNavigationResult) {
          final draft =
              Map<String, dynamic>.from(updatedNutritionOutcome.draft);
          _initialNutrition = draft;
          return;
        }

        if (updatedNutritionOutcome is! _NutritionResult) {
          return;
        }

        final updatedNutrition = updatedNutritionOutcome;
        currentNutritionResult = updatedNutrition;
        final updatedNutritionMap = updatedNutrition.toMap();
        _initialNutrition = updatedNutritionMap;
        continue;
      }

      return;
    }
  }
}
