import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/health_questionnaire_service.dart';
import '../widgets/keyboard_dismissible.dart';

Future<HealthQuestionnaireResult?> showHealthQuestionnaireDialog(
  BuildContext context, {
  Map<String, dynamic>? initialAnswers,
  bool allowCancel = true,
}) {
  return Navigator.of(context).push<HealthQuestionnaireResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _BaselineIntakeFlow(
        initialAnswers: initialAnswers,
        allowCancel: allowCancel,
      ),
    ),
  );
}

class HealthQuestionnaireResult {
  HealthQuestionnaireResult({
    required this.answers,
    required this.baselineVersion,
    required this.completedAt,
    this.lockedAt,
  });

  final Map<String, dynamic> answers;
  final String baselineVersion;
  final DateTime completedAt;
  final DateTime? lockedAt;

  Map<String, dynamic> get baseline =>
      Map<String, dynamic>.from(answers['baseline'] as Map? ?? {});
}

class _ConditionOption {
  const _ConditionOption({required this.label, required this.code});
  final String label;
  final String code;
}

class _SelectedCondition {
  _SelectedCondition({
    required this.label,
    required this.code,
    this.isCurrent = true,
    this.diagnosedYear,
  });

  final String label;
  final String code;
  bool isCurrent;
  String? diagnosedYear;
}

class _MedicationOption {
  const _MedicationOption({required this.label, required this.code});
  final String label;
  final String code;
}

class _ActivityCategory {
  const _ActivityCategory({
    required this.key,
    required this.label,
    required this.description,
  });
  final String key;
  final String label;
  final String description;
}

class _ActivityCategoryInput {
  _ActivityCategoryInput({required this.key});

  final String key;
  int? daysPerWeek;
  int? minutesPerSession;
  String? intensity;
}

class _BaselineIntakeFlow extends StatefulWidget {
  const _BaselineIntakeFlow({
    required this.initialAnswers,
    required this.allowCancel,
  });

  final Map<String, dynamic>? initialAnswers;
  final bool allowCancel;

  @override
  State<_BaselineIntakeFlow> createState() => _BaselineIntakeFlowState();
}

class _BaselineIntakeFlowState extends State<_BaselineIntakeFlow> {
  // Page definitions
  static const _totalPages = 9;

  static const List<String> _dietPatterns = [
    'Balanced',
    'Mediterranean',
    'Low carb',
    'Plant-forward/vegetarian',
    'High protein',
    'Other',
  ];

  static const List<String> _dietRestrictionOptions = [
    'Gluten free',
    'Dairy free',
    'Nut allergy',
    'Low sodium',
    'Halal/Kosher',
    'None',
  ];

  static const List<String> _countryOptions = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo (DRC)',
    'Congo (Republic)',
    'Costa Rica',
    'Cote d\'Ivoire',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar (Burma)',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
    'Other',
  ];

  static const List<String> _activityLimitationsOptions = [
    'Joint pain',
    'Cardio limitations',
    'Recent surgery',
    'Balance issues',
    'Time constraints',
    'None',
  ];

  static const List<String> _cardioRiskOptions = [];

  // Condition catalog definitions (label + clinical code)
  static const Map<String, List<_ConditionOption>> _conditionCatalog = {
    'Cardiometabolic Disorders': [
      _ConditionOption(label: 'Hypertension (essential)', code: 'I10'),
      _ConditionOption(label: 'Hypertensive heart disease', code: 'I11'),
      _ConditionOption(label: 'Hypertensive chronic kidney disease', code: 'I12'),
      _ConditionOption(label: 'Combined heart + kidney disease (hypertensive)', code: 'I13'),
      _ConditionOption(label: 'Dyslipidemia (unspecified / mixed)', code: 'E78.5'),
      _ConditionOption(label: 'Hypercholesterolemia (high LDL)', code: 'E78.0'),
      _ConditionOption(label: 'Hypertriglyceridemia', code: 'E78.1'),
      _ConditionOption(label: 'Low HDL (hypoalphalipoproteinemia)', code: 'E78.6'),
      _ConditionOption(label: 'Type 1 Diabetes Mellitus', code: 'E10'),
      _ConditionOption(label: 'Type 2 Diabetes Mellitus', code: 'E11'),
      _ConditionOption(label: 'Prediabetes / Impaired fasting glucose', code: 'R73.01/R73.03'),
      _ConditionOption(label: 'Insulin resistance', code: 'E88.81'),
      _ConditionOption(label: 'Obesity (general)', code: 'E66.9'),
      _ConditionOption(label: 'Severe obesity (BMI ≥35–40)', code: 'E66.01/E66.02'),
      _ConditionOption(label: 'Metabolic syndrome', code: 'E88.81'),
      _ConditionOption(label: 'Non-alcoholic fatty liver disease (NAFLD / MASLD)', code: 'K76.0'),
      _ConditionOption(label: 'Non-alcoholic steatohepatitis (NASH / MASH)', code: 'K75.81'),
    ],
    'Endocrine & Hormonal Disorders': [
      _ConditionOption(label: 'Hypothyroidism (acquired)', code: 'E03.9'),
      _ConditionOption(label: 'Hashimoto’s thyroiditis', code: 'E06.3'),
      _ConditionOption(label: 'Hyperthyroidism', code: 'E05.90'),
      _ConditionOption(label: 'Polycystic Ovary Syndrome (PCOS)', code: 'E28.2'),
      _ConditionOption(label: 'Vitamin D deficiency', code: 'E55.9'),
      _ConditionOption(label: 'Testosterone deficiency (male hypogonadism)', code: 'E29.1'),
    ],
    'Respiratory & Sleep Disorders': [
      _ConditionOption(label: 'Obstructive Sleep Apnea (OSA)', code: 'G47.33'),
      _ConditionOption(label: 'Insomnia (chronic)', code: 'F51.04'),
      _ConditionOption(label: 'Sleep-related breathing disorders (other)', code: 'G47.30'),
    ],
    'Cardiovascular Diseases': [
      _ConditionOption(label: 'Coronary artery disease (CAD)', code: 'I25.10'),
      _ConditionOption(label: 'History of myocardial infarction', code: 'I25.2'),
      _ConditionOption(label: 'Angina pectoris', code: 'I20.9'),
      _ConditionOption(label: 'Heart failure (unspecified or reduced EF)', code: 'I50.9/I50.2'),
      _ConditionOption(label: 'Peripheral arterial disease (PAD)', code: 'I73.9'),
    ],
    'Renal Disorders': [
      _ConditionOption(label: 'Chronic kidney disease (CKD), stage 1–5', code: 'N18.1-N18.5'),
      _ConditionOption(label: 'End-stage renal disease', code: 'N18.6'),
      _ConditionOption(label: 'Diabetic nephropathy', code: 'E11.21'),
    ],
    'Gastrointestinal / Metabolic': [
      _ConditionOption(label: 'GERD (gastroesophageal reflux)', code: 'K21.9'),
      _ConditionOption(label: 'Irritable bowel syndrome', code: 'K58.9'),
    ],
    'Inflammatory & Autoimmune': [
      _ConditionOption(label: 'Rheumatoid arthritis', code: 'M06.9'),
      _ConditionOption(label: 'Psoriatic arthritis', code: 'L40.50'),
      _ConditionOption(label: 'Psoriasis (skin)', code: 'L40.0'),
    ],
    'Mental Health': [
      _ConditionOption(label: 'Depression (major depressive disorder)', code: 'F33.9'),
      _ConditionOption(label: 'Generalized anxiety disorder', code: 'F41.1'),
    ],
    'Other Common Related Conditions': [
      _ConditionOption(label: 'Gout / Hyperuricemia', code: 'M10.9'),
      _ConditionOption(label: 'Migraine', code: 'G43.909'),
      _ConditionOption(label: 'Anemia (unspecified)', code: 'D64.9'),
      _ConditionOption(label: 'None of the above', code: 'NONE'),
    ],
  };

  // Medication catalog (sample, searchable)
  static const List<_MedicationOption> _medicationCatalog = [
    _MedicationOption(label: 'Metformin', code: '860975'),
    _MedicationOption(label: 'Lisinopril', code: '29046'),
    _MedicationOption(label: 'Atorvastatin', code: '617314'),
    _MedicationOption(label: 'Levothyroxine', code: '966286'),
    _MedicationOption(label: 'Insulin glargine', code: '847207'),
    _MedicationOption(label: 'Insulin aspart', code: '847207-ASP'),
    _MedicationOption(label: 'Semaglutide', code: '1991301'),
    _MedicationOption(label: 'Losartan', code: '617320'),
    _MedicationOption(label: 'Sertraline', code: '36567'),
    _MedicationOption(label: 'Albuterol inhaler', code: '435'),
  ];

  static const Map<String, List<String>> _conditionMedicationShortcuts = {
    'I10': ['Lisinopril', 'Losartan'],
    'E11': ['Metformin', 'Semaglutide', 'Insulin glargine'],
    'E10': ['Insulin glargine', 'Insulin aspart'],
    'E78.5': ['Atorvastatin'],
    'E03.9': ['Levothyroxine'],
    'J45.909': ['Albuterol inhaler'],
    'I25.10': ['Atorvastatin', 'Lisinopril'],
  };

  // Controllers and state
  int _pageIndex = 0;
  bool _saving = false;
  String? _baselineVersion;
  Map<String, dynamic>? _initialAnswers;

  final _demographicsFormKey = GlobalKey<FormState>();
  final _nutritionFormKey = GlobalKey<FormState>();
  final _activityFormKey = GlobalKey<FormState>();
  final _mentalFormKey = GlobalKey<FormState>();
  final _riskFormKey = GlobalKey<FormState>();

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _otherDietController = TextEditingController();
  final TextEditingController _sleepHoursController = TextEditingController();
  final TextEditingController _smokingDetailsController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _conditionSearchController =
      TextEditingController();
  final TextEditingController _medicationSearchController =
      TextEditingController();

  DateTime? _dateOfBirth;
  String? _sex;
  String? _country;
  bool _useMetric = true; // true = cm/kg, false = in/lb
  double _heightValue = 170;
  double _weightValue = 70;

  final List<_SelectedCondition> _selectedConditions = [];
  bool _takesPrescriptions = false;
  bool _takesSupplements = false;
  final List<Map<String, String>> _medications = [];
  final List<Map<String, String>> _supplements = [];
  final Map<String, _ActivityCategoryInput> _categoryInputs = {
    'walking': _ActivityCategoryInput(key: 'walking'),
    'cardio': _ActivityCategoryInput(key: 'cardio'),
    'strength': _ActivityCategoryInput(key: 'strength'),
    'sports': _ActivityCategoryInput(key: 'sports'),
    'mobility': _ActivityCategoryInput(key: 'mobility'),
  };
  String? _stepRange;
  String? _jobActivity;
  Set<String> _equipmentAccess = <String>{};
  String? _trainingHistory;
  static const List<String> _equipmentOptions = [
    'Gym access',
    'Dumbbells / kettlebells',
    'Resistance bands',
    'Cardio machine',
    'None',
  ];

  // Typical day / routine
  TimeOfDay? _wakeUpTime;
  TimeOfDay? _bedTime;
  TimeOfDay? _dinnerTime;
  String? _typicalSleepQuality;
  String? _workShift;
  String? _breakfastHabit;
  int? _mealsPerDay;

  double? _sleepHours;
  String? _sleepQuality;
  Set<String> _sleepDisturbances = <String>{};
  Set<String> _sleepDisorders = <String>{};

  String? _dietPattern;
  Set<String> _dietRestrictionSelections = <String>{};
  String? _alcoholUse;
  String? _caffeineUse;

  int? _activityFrequency;
  String? _activityIntensity;
  Set<String> _activityLimitations = <String>{};

  String? _stressLevel;
  String? _mood;
  bool _focusIssues = false;
  bool _burnout = false;

  String? _smokingStatus;
  String? _substanceUse;
  Set<String> _cardioRisks = <String>{};

  bool _consentGiven = false;

  final List<_ActivityCategory> _activityCategories = const [
    _ActivityCategory(
      key: 'walking',
      label: 'Walking / general movement',
      description: 'Everyday steps, brisk walks, errands.',
    ),
    _ActivityCategory(
      key: 'cardio',
      label: 'Cardio exercise',
      description: 'Running, cycling, rowing, HIIT, classes.',
    ),
    _ActivityCategory(
      key: 'strength',
      label: 'Strength training',
      description: 'Weights, machines, bodyweight sessions.',
    ),
    _ActivityCategory(
      key: 'sports',
      label: 'Sports',
      description: 'Team or individual sports (tennis, basketball, etc.).',
    ),
    _ActivityCategory(
      key: 'mobility',
      label: 'Mobility / stretching',
      description: 'Yoga, stretching, mobility drills.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _hydrateFromInitial(widget.initialAnswers);
  }

  List<_ConditionOption> _filteredConditionOptions(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) {
      return _conditionCatalog.values.expand((c) => c).toList();
    }
    return _conditionCatalog.values
        .expand((c) => c)
        .where((c) => c.label.toLowerCase().contains(lower))
        .toList();
  }

  bool _hasConditionSelected(String code) =>
      _selectedConditions.any((c) => c.code == code);

  Widget _conditionResultTile(_ConditionOption option) {
    final selected = _hasConditionSelected(option.code);
    return CheckboxListTile(
      title: Text(option.label),
      subtitle: Text(option.code),
      value: selected,
      onChanged: (_) => _toggleCondition(option),
    );
  }

  void _toggleCondition(_ConditionOption option) {
    setState(() {
      if (_hasConditionSelected(option.code)) {
        _selectedConditions.removeWhere((c) => c.code == option.code);
        return;
      }
      if (option.code == 'NONE') {
        _selectedConditions
          ..clear()
          ..add(_SelectedCondition(label: option.label, code: option.code));
      } else {
        _selectedConditions.removeWhere((c) => c.code == 'NONE');
        _selectedConditions.add(
          _SelectedCondition(label: option.label, code: option.code),
        );
      }
    });
  }

  Widget _conditionDetailEditor(_SelectedCondition condition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    condition.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  condition.code,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _selectedConditions.remove(condition);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: condition.isCurrent ? 'current' : 'past',
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'current',
                        child: Text('Current'),
                      ),
                      DropdownMenuItem(
                        value: 'past',
                        child: Text('Past'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        condition.isCurrent = value == 'current';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('${condition.code}-year-${condition.diagnosedYear ?? ''}'),
                    initialValue: condition.diagnosedYear,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosed year',
                      hintText: 'Optional',
                    ),
                    onChanged: (value) {
                      condition.diagnosedYear = value.trim();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_MedicationOption> _buildMedicationSuggestions() {
    final selectedCodes = _selectedConditions.map((c) => c.code).toSet();
    final suggestedLabels = <String>{};
    for (final code in selectedCodes) {
      final meds = _conditionMedicationShortcuts[code];
      if (meds != null) suggestedLabels.addAll(meds);
    }
    final existingNames = _medications.map((m) => m['name']).toSet();
    return _medicationCatalog
        .where(
          (m) => suggestedLabels.contains(m.label) && !existingNames.contains(m.label),
        )
        .toList();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _otherDietController.dispose();
    _sleepHoursController.dispose();
    _smokingDetailsController.dispose();
    _conditionSearchController.dispose();
    _medicationSearchController.dispose();
    super.dispose();
  }

  void _hydrateFromInitial(Map<String, dynamic>? initial) {
    _initialAnswers = initial;
    if (initial == null) return;

    final baseline = initial['baseline'] as Map<String, dynamic>?;
    _baselineVersion = initial['baselineVersion']?.toString();
    // Locking disabled: always editable
    final progress = initial['progress'];
    if (progress is Map) {
      final savedPage = progress['pageIndex'] as int?;
      if (savedPage != null && savedPage >= 0 && savedPage < _totalPages) {
        _pageIndex = savedPage;
      }
    }

    final demographics = baseline?['demographics'];
    if (demographics is Map) {
      final dobString = demographics['dateOfBirth']?.toString();
      if (dobString != null) {
        _dateOfBirth = DateTime.tryParse(dobString);
        if (_dateOfBirth != null) {
          _dobController.text = _formatDate(_dateOfBirth!);
        }
      }
      final ageValue = demographics['age'];
      if (ageValue is num) {
        _ageController.text = ageValue.toString();
      }
      final height = demographics['heightCm'];
      final weight = demographics['weightKg'];
      _fullNameController.text = demographics['fullName']?.toString() ?? '';
      _sex = demographics['sex']?.toString();
      _country = demographics['country']?.toString();
      _useMetric = !_usesImperialUnits(_country);
      if (height is num) {
        _heightValue = _clampHeight(height.toDouble(), true);
      }
      if (weight is num) {
        _weightValue = _clampWeight(weight.toDouble(), true);
      }
      if (!_useMetric) {
        _heightValue = _clampHeight(_heightValue / 2.54, false);
        _weightValue = _clampWeight(_weightValue / 0.45359237, false);
      }
    }

    final medical = baseline?['medical'];
    if (medical is Map) {
          final conditions = medical['conditions'];
          if (conditions is List) {
            for (final entry in conditions) {
              if (entry is Map) {
                _selectedConditions.add(
                  _SelectedCondition(
                    label: entry['label']?.toString() ?? '',
                    code: entry['code']?.toString() ?? '',
                    isCurrent: entry['isCurrent'] == true,
                    diagnosedYear: entry['diagnosedYear']?.toString(),
                  ),
                );
              }
            }
          } else {
            final legacy = medical['chronicDiagnoses'];
            if (legacy is List) {
              for (final item in legacy) {
                final label = item.toString();
                _selectedConditions.add(
                  _SelectedCondition(label: label, code: label),
                );
              }
            }
          }
    }

    final meds = baseline?['medications'];
    if (meds is Map) {
      _takesPrescriptions =
          meds['hasPrescriptions'] == true || _medications.isNotEmpty;
      _takesSupplements = meds['hasSupplements'] == true;
      final prescriptions = meds['prescriptions'];
      if (prescriptions is List) {
        _medications.addAll(
          prescriptions
              .whereType<Map>()
              .map((e) => e.map((key, value) =>
                  MapEntry(key.toString(), value?.toString() ?? '')))
              .toList(),
        );
        if (_medications.isNotEmpty) {
          _takesPrescriptions = true;
        }
      }
      final supplements = meds['supplements'];
      if (supplements is List) {
        _supplements.addAll(
          supplements
              .whereType<Map>()
              .map((e) => e.map((key, value) =>
                  MapEntry(key.toString(), value?.toString() ?? '')))
              .toList(),
        );
        if (_supplements.isNotEmpty) {
          _takesSupplements = true;
        }
      }
    }

    final routine = baseline?['routine'];
    if (routine is Map) {
      _wakeUpTime = _parseTime(routine['wakeUp']);
      _bedTime = _parseTime(routine['bedTime']);
      _dinnerTime = _parseTime(routine['dinnerTime']);
      _typicalSleepQuality = routine['sleepQuality']?.toString();
      _workShift = routine['workShift']?.toString();
      _breakfastHabit = routine['breakfastHabit']?.toString();
      final meals = routine['mealsPerDay'];
      if (meals is num) _mealsPerDay = meals.toInt();
    }

    final sleep = baseline?['sleep'];
    if (sleep is Map) {
      final hours = sleep['avgHours'];
      _sleepHours = hours is num ? hours.toDouble() : null;
      if (_sleepHours != null) {
        _sleepHoursController.text =
            _sleepHours!.toStringAsFixed(_sleepHours! % 1 == 0 ? 0 : 1);
      }
      _sleepQuality = sleep['quality']?.toString();
      final disturbances = sleep['disturbances'];
      if (disturbances is List) {
        _sleepDisturbances = disturbances.map((e) => e.toString()).toSet();
      }
      final disorders = sleep['sleepDisorders'];
      if (disorders is List) {
        _sleepDisorders = disorders.map((e) => e.toString()).toSet();
      }
    }

    final nutrition = baseline?['nutrition'];
    if (nutrition is Map) {
      _dietPattern = nutrition['dietPattern']?.toString();
      final restrictions = nutrition['restrictions'];
      if (restrictions is List) {
        _dietRestrictionSelections =
            restrictions.map((e) => e.toString()).toSet();
      }
      _alcoholUse = nutrition['alcohol']?.toString();
      _caffeineUse = nutrition['caffeinePerDay']?.toString();
      _otherDietController.text =
          nutrition['dietNote']?.toString().trim() ?? '';
    }

    final activity = baseline?['activity'];
    if (activity is Map) {
      _activityFrequency = activity['frequencyPerWeek'] is int
          ? activity['frequencyPerWeek'] as int
          : int.tryParse(activity['frequencyPerWeek']?.toString() ?? '');
      _activityIntensity = activity['intensity']?.toString();
      final limitations = activity['limitations'];
      if (limitations is List) {
        _activityLimitations = limitations.map((e) => e.toString()).toSet();
      }
      final categories = activity['categories'];
      if (categories is Map) {
        categories.forEach((key, value) {
          final map = value as Map?;
          if (map == null) return;
          final input = _categoryInputs[key];
          if (input != null) {
            input.daysPerWeek = _toInt(map['daysPerWeek']);
            input.minutesPerSession = _toInt(map['minutesPerSession']);
            input.intensity = map['intensity']?.toString();
          }
        });
      }
      _stepRange = activity['stepRange']?.toString();
      _jobActivity = activity['jobActivity']?.toString();
      final equipment = activity['equipment'];
      if (equipment is List) {
        _equipmentAccess = equipment.map((e) => e.toString()).toSet();
      }
      _trainingHistory = activity['trainingHistory']?.toString();
    }

    final mental = baseline?['mental'];
    if (mental is Map) {
      _stressLevel = mental['stress']?.toString();
      _mood = mental['mood']?.toString();
      _focusIssues = mental['focusIssues'] == true;
      _burnout = mental['burnoutIndicators'] == true;
    }

    final risks = baseline?['risks'];
    if (risks is Map) {
      _smokingStatus = risks['smokingStatus']?.toString();
      _substanceUse = risks['substanceUse']?.toString();
      final cardio = risks['cardiometabolicRisks'];
      if (cardio is List) {
        _cardioRisks = cardio.map((e) => e.toString()).toSet();
      }
      _smokingDetailsController.text = risks['riskNotes']?.toString() ?? '';
    }

    final finalReview = baseline?['finalReview'];
    if (finalReview is Map) {
      _consentGiven = finalReview['consentAccepted'] == true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pageIndex + 1) / _totalPages;
    final theme = Theme.of(context);

    return PopScope(
      canPop: widget.allowCancel && !_saving,
      onPopInvoked: widget.allowCancel
          ? null
          : (didPop) {
              if (didPop) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Complete the baseline intake to continue setup.'),
                ),
              );
            },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baseline intake'),
          leading: widget.allowCancel ? const BackButton() : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildPage(theme),
            ),
          ),
        ),
        bottomNavigationBar: _buildNavigation(theme, progress),
      ),
    );
  }

  Widget _buildNavigation(ThemeData theme, double progress) {
    final isLast = _pageIndex == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (_pageIndex > 0)
            OutlinedButton(
              onPressed: _saving ? null : _previousPage,
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    await (isLast ? _completeFlow() : _nextPage());
                  },
            child: Text(isLast ? 'Save' : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(ThemeData theme) {
    switch (_pageIndex) {
      case 0:
        return _demographicsPage(theme);
      case 1:
        return _medicalPage(theme);
      case 2:
        return _medicationsPage(theme);
      case 3:
        return _typicalDayPage(theme);
      case 4:
        return _nutritionPage(theme);
      case 5:
        return _activityPage(theme);
      case 6:
        return _mentalPage(theme);
      case 7:
        return _riskPage(theme);
      default:
        return _reviewPage(theme);
    }
  }

  Widget _sectionShell({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      key: ValueKey(title),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = _formatDate(picked);
      });
    }
  }

  bool _usesImperialUnits(String? country) {
    if (country == null) return false;
    switch (country) {
      case 'United States':
      case 'United Kingdom':
      case 'Liberia':
      case 'Myanmar (Burma)':
        return true;
      default:
        return false;
    }
  }

  Widget _demographicsPage(ThemeData theme) {
    final heightRange = _heightRange(_useMetric);
    final weightRange = _weightRange(_useMetric);
    final heightValue = _clampHeight(_heightValue, _useMetric);
    final weightValue = _clampWeight(_weightValue, _useMetric);
    return _sectionShell(
      title: 'Demographics & identity',
      subtitle:
          'Baseline-critical details to anchor all future comparisons. Required before moving on.',
      children: [
        Form(
          key: _demographicsFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                onTap: () => HapticFeedback.lightImpact(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name looks too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  hintText: 'Select your birth date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pickDateOfBirth();
                },
                validator: (_) {
                  if (_dateOfBirth == null) {
                    return 'Please choose your birth date';
                  }
                  final now = DateTime.now();
                  if (_dateOfBirth!.isAfter(now)) {
                    return 'Birth date cannot be in the future';
                  }
                  final age = _calculateAge(_dateOfBirth!);
                  if (age < 5 || age > 120) {
                    return 'Age must be between 5 and 120';
                  }
                  return null;
                },
              ),
              if (_dateOfBirth != null) ...[
                const SizedBox(height: 6),
                Text('Age: ${_calculateAge(_dateOfBirth!)} years'),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                ],
                onChanged: (value) => setState(() => _sex = value),
                validator: (value) =>
                    value == null ? 'Select the option that fits best' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: const InputDecoration(labelText: 'Country/region'),
                items: _countryOptions
                    .map(
                      (country) =>
                          DropdownMenuItem(value: country, child: Text(country)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _country = value;
                    final wantsImperial = _usesImperialUnits(value);
                    if (wantsImperial && _useMetric) {
                      _useMetric = false;
                      _heightValue =
                          _clampHeight(_heightValue / 2.54, _useMetric);
                      _weightValue =
                          _clampWeight(_weightValue / 0.45359237, _useMetric);
                    } else if (!wantsImperial && !_useMetric) {
                      _useMetric = true;
                      _heightValue =
                          _clampHeight(_heightValue * 2.54, _useMetric);
                      _weightValue =
                          _clampWeight(_weightValue * 0.45359237, _useMetric);
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Select where you live' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Units',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Metric'),
                    selected: _useMetric,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _useMetric = true;
                        _heightValue =
                            _clampHeight(_heightValue * 2.54, _useMetric);
                        _weightValue =
                            _clampWeight(_weightValue * 0.45359237, _useMetric);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Standard'),
                    selected: !_useMetric,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _useMetric = false;
                        _heightValue =
                            _clampHeight(_heightValue / 2.54, _useMetric);
                        _weightValue =
                            _clampWeight(_weightValue / 0.45359237, _useMetric);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Height',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(_formatHeightLabel()),
                        ],
                      ),
                      Slider(
                        value: heightValue.toDouble(),
                        min: heightRange.min,
                        max: heightRange.max,
                        divisions: _useMetric ? 130 : 100,
                        label: _formatHeightLabel(),
                        onChanged: (value) {
                          setState(() => _heightValue = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weight',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(_formatWeightLabel()),
                        ],
                      ),
                      Slider(
                        value: weightValue.toDouble(),
                        min: weightRange.min,
                        max: weightRange.max,
                        divisions: _useMetric ? 220 : 240,
                        label: _formatWeightLabel(),
                        onChanged: (value) {
                          setState(() => _weightValue = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typicalDayPage(ThemeData theme) {
    return _sectionShell(
      title: 'Typical day',
      subtitle: 'Daily rhythm to contextualize sleep, meals, and energy.',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _timePickerTile(
              label: 'Wake-up time',
              value: _timeLabel(_wakeUpTime),
              onTap: () async {
                final picked = await _pickTime(_wakeUpTime);
                if (picked != null) {
                  setState(() => _wakeUpTime = picked);
                }
              },
            ),
            _timePickerTile(
              label: 'Bedtime',
              value: _timeLabel(_bedTime),
              onTap: () async {
                final picked = await _pickTime(_bedTime);
                if (picked != null) {
                  setState(() => _bedTime = picked);
                }
              },
            ),
            _timePickerTile(
              label: 'Dinner time',
              value: _timeLabel(_dinnerTime),
              onTap: () async {
                final picked = await _pickTime(_dinnerTime);
                if (picked != null) {
                  setState(() => _dinnerTime = picked);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _typicalSleepQuality,
          decoration: const InputDecoration(labelText: 'Sleep quality'),
          items: const [
            DropdownMenuItem(value: 'restorative', child: Text('Restorative')),
            DropdownMenuItem(value: 'ok', child: Text('Okay')),
            DropdownMenuItem(value: 'poor', child: Text('Poor')),
          ],
          onChanged: (value) => setState(() => _typicalSleepQuality = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _workShift,
          decoration: const InputDecoration(labelText: 'Work shift'),
          items: const [
            DropdownMenuItem(value: 'day', child: Text('Day shift')),
            DropdownMenuItem(value: 'night', child: Text('Night shift')),
            DropdownMenuItem(value: 'rotating', child: Text('Rotating/variable')),
            DropdownMenuItem(value: 'none', child: Text('Not working')),
          ],
          onChanged: (value) => setState(() => _workShift = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _breakfastHabit,
          decoration: const InputDecoration(labelText: 'Breakfast habit'),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Every day')),
            DropdownMenuItem(value: 'sometimes', child: Text('Sometimes')),
            DropdownMenuItem(value: 'never', child: Text('Never')),
          ],
          onChanged: (value) => setState(() => _breakfastHabit = value),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meals per day',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              value: (_mealsPerDay ?? 3).toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              label: '${_mealsPerDay ?? 3}',
              onChanged: (value) {
                setState(() => _mealsPerDay = value.round());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _medicalPage(ThemeData theme) {
    final query = _conditionSearchController.text.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;
    final options = _filteredConditionOptions(query);

    return _sectionShell(
      title: 'Medical conditions',
      subtitle:
          'Search or browse, then add follow-up details. This becomes the baseline condition profile.',
      children: [
        TextField(
          controller: _conditionSearchController,
          decoration: InputDecoration(
            labelText: 'Search conditions',
            hintText: 'e.g., hypertension, diabetes, asthma',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: hasQuery
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _conditionSearchController.clear());
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (hasQuery)
          ...options.map(_conditionResultTile)
        else
          ..._conditionCatalog.entries.map(
            (entry) => Card(
              child: ExpansionTile(
                title: Text(entry.key),
                children: entry.value.map(_conditionResultTile).toList(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_selectedConditions.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected conditions',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedConditions.map(_conditionDetailEditor),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_medicalValidationError != null)
          Text(
            _medicalValidationError!,
            style:
                theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
      ],
    );
  }

  Widget _medicationsPage(ThemeData theme) {
    final query = _medicationSearchController.text.trim().toLowerCase();
    final matches = _medicationCatalog
        .where(
          (m) => query.isEmpty || m.label.toLowerCase().contains(query),
        )
        .toList();
    final suggestions = _buildMedicationSuggestions();

    return _sectionShell(
      title: 'Medications',
      subtitle:
          'Search and add medications. We suggest common options based on your selected conditions, but you decide what to include.',
      children: [
        TextField(
          controller: _medicationSearchController,
          decoration: InputDecoration(
            labelText: 'Search medications',
            hintText: 'e.g., metformin, lisinopril',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _medicationSearchController.clear());
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (query.isEmpty && suggestions.isNotEmpty) ...[
          Text(
            'Suggested for your conditions',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (med) => ActionChip(
                    label: Text(med.label),
                    onPressed: () => _addMedicationWithDetails(med),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (matches.isNotEmpty) ...[
          Text(
            'Search results',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...matches.take(8).map(
                (m) => ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(m.label),
                  subtitle: Text('Code: ${m.code}'),
                  trailing: TextButton(
                    onPressed: () => _addMedicationWithDetails(m),
                    child: const Text('Add'),
                  ),
                ),
              ),
        ] else
          Text(
            'No matches. Try another spelling.',
            style: theme.textTheme.bodySmall,
          ),
        const Divider(height: 24),
        if (_medications.isNotEmpty)
          ..._medications.map(
            (med) => Card(
              child: ListTile(
                title: Text(med['name'] ?? ''),
                subtitle: Text(
                  [
                    if (med['dose']?.isNotEmpty == true) med['dose'],
                    if (med['frequency']?.isNotEmpty == true) med['frequency'],
                    if (med['adherence']?.isNotEmpty == true) med['adherence'],
                  ].whereType<String>().join(' • '),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _medications.remove(med));
                  },
                ),
              ),
            ),
          )
        else
          Text(
            'No medications added yet.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        const Divider(height: 24),
        SwitchListTile(
          value: _takesSupplements,
          title: const Text('Taking supplements or OTC'),
          onChanged: (value) {
            setState(() {
              _takesSupplements = value;
              if (!value) _supplements.clear();
            });
          },
        ),
        if (_takesSupplements) ...[
          ..._supplements.map(
            (supplement) => Card(
              child: ListTile(
                title: Text(supplement['name'] ?? ''),
                subtitle: Text(
                  [
                    if (supplement['dose']?.isNotEmpty == true)
                      supplement['dose'],
                    if (supplement['frequency']?.isNotEmpty == true)
                      supplement['frequency'],
                    if (supplement['adherence']?.isNotEmpty == true)
                      supplement['adherence'],
                  ].whereType<String>().join(' • '),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _supplements.remove(supplement));
                  },
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showSupplementDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add supplement'),
          ),
        ],
      ],
    );
  }

  Widget _nutritionPage(ThemeData theme) {
    return _sectionShell(
      title: 'Nutrition & hydration',
      subtitle:
          'Daily patterns, restrictions, and intake signals used for baseline normalization.',
      children: [
        Form(
          key: _nutritionFormKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
              value: _dietPattern,
              decoration:
                  const InputDecoration(labelText: 'Primary diet pattern'),
              items: _dietPatterns
                  .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern,
                        child: Text(pattern),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _dietPattern = value),
                validator: (value) =>
                    value == null ? 'Select a diet pattern' : null,
              ),
              if (_dietPattern == 'Other') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherDietController,
                  decoration: const InputDecoration(
                    labelText: 'Diet notes',
                    hintText: 'Describe your approach',
                  ),
                  validator: (value) {
                    if (_dietPattern == 'Other' &&
                        (value == null || value.isEmpty)) {
                      return 'Please describe your diet';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
              runSpacing: 8,
              children: _dietRestrictionOptions
                  .map(_dietRestrictionChip)
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _caffeineUse,
                decoration:
                    const InputDecoration(labelText: 'Caffeine per day'),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: '1-2', child: Text('1-2 cups')),
                  DropdownMenuItem(value: '3-5', child: Text('3-5 cups')),
                  DropdownMenuItem(value: 'gt5', child: Text('More than 5')),
                ],
                onChanged: (value) => setState(() => _caffeineUse = value),
                validator: (value) =>
                    value == null ? 'Select caffeine intake' : null,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityPage(ThemeData theme) {
    return _sectionShell(
      title: 'Weekly activity baseline',
      subtitle:
          'Capture a typical week: volume, intensity, constraints, and history to set your starting plan.',
      children: [
        Form(
          key: _activityFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Do you currently exercise?'),
                value: (_activityFrequency ?? 0) > 0 || _activityIntensity != null,
                onChanged: (value) {
                  setState(() {
                    if (!value) {
                      _resetActivityInputs();
                    } else {
                      _activityFrequency ??= 1;
                      _activityIntensity ??= 'light';
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              if ((_activityFrequency ?? 0) > 0 || _activityIntensity != null) ...[
                TextFormField(
                  initialValue:
                      _activityFrequency != null ? '$_activityFrequency' : null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Intentional activity days per week',
                  ),
                  onChanged: (value) =>
                      _activityFrequency = int.tryParse(value.trim()),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 0 || parsed > 21) {
                      return 'Enter 0–21 days';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Breakdown by category',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._activityCategories.map(_activityCategoryCard),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _activityIntensity,
                  decoration:
                      const InputDecoration(labelText: 'Overall intensity feel'),
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('Easy / light')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'vigorous', child: Text('Hard')),
                  ],
                  onChanged: (value) => setState(() => _activityIntensity = value),
                  validator: (value) =>
                      value == null ? 'Select intensity' : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Context',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _stepRange,
                  decoration: const InputDecoration(
                    labelText: 'Typical weekly steps (range)',
                    hintText: 'e.g., 35k-50k (optional)',
                  ),
                  onChanged: (v) => _stepRange = v.trim().isEmpty ? null : v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _jobActivity,
                  decoration:
                      const InputDecoration(labelText: 'Job activity level'),
                  items: const [
                    DropdownMenuItem(
                        value: 'sedentary', child: Text('Mostly sitting')),
                    DropdownMenuItem(
                        value: 'mixed', child: Text('Mixed sitting/standing')),
                    DropdownMenuItem(
                        value: 'on_feet', child: Text('On feet most of day')),
                  ],
                  onChanged: (value) => setState(() => _jobActivity = value),
                ),
                const SizedBox(height: 12),
                Text(
                  'Equipment access',
                  style: theme.textTheme.bodyMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _equipmentOptions
                      .map(
                        (opt) => FilterChip(
                          label: Text(opt),
                          selected: _equipmentAccess.contains(opt),
                          onSelected: (sel) {
                            setState(() {
                              sel
                                  ? _equipmentAccess.add(opt)
                                  : _equipmentAccess.remove(opt);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Limitations',
                  style: theme.textTheme.bodyMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activityLimitationsOptions
                      .map(_activityLimitationChip)
                      .toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _trainingHistory,
                  decoration:
                      const InputDecoration(labelText: 'Training history'),
                  items: const [
                    DropdownMenuItem(
                        value: 'new', child: Text('New to exercise')),
                    DropdownMenuItem(
                        value: 'returning',
                        child: Text('Returning after a break')),
                    DropdownMenuItem(
                        value: 'consistent',
                        child: Text('Consistently active for months/years')),
                  ],
                  onChanged: (value) => setState(() => _trainingHistory = value),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _mentalPage(ThemeData theme) {
    return _sectionShell(
      title: 'Mental & cognitive health',
      subtitle: 'Stress, mood, and cognitive load signals.',
      children: [
        Form(
          key: _mentalFormKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _stressLevel,
                decoration: const InputDecoration(labelText: 'Stress level'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) => setState(() => _stressLevel = value),
                validator: (value) =>
                    value == null ? 'Select stress level' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _mood,
                decoration: const InputDecoration(labelText: 'Mood stability'),
                items: const [
                  DropdownMenuItem(value: 'stable', child: Text('Stable')),
                  DropdownMenuItem(value: 'variable', child: Text('Variable')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (value) => setState(() => _mood = value),
                validator: (value) =>
                    value == null ? 'Select mood status' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _focusIssues,
                title: const Text('Difficulty focusing'),
                onChanged: (value) => setState(() => _focusIssues = value),
              ),
              SwitchListTile(
                value: _burnout,
                title: const Text('Burnout indicators present'),
                onChanged: (value) => setState(() => _burnout = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _riskPage(ThemeData theme) {
    return _sectionShell(
      title: 'Risk factors',
      subtitle:
          'Behaviors and inherited risks recorded with this baseline for future safety checks.',
      children: [
        Form(
          key: _riskFormKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _smokingStatus,
                decoration: const InputDecoration(labelText: 'Smoking'),
                items: const [
                  DropdownMenuItem(value: 'never', child: Text('Never')),
                  DropdownMenuItem(value: 'former', child: Text('Former')),
                  DropdownMenuItem(value: 'current', child: Text('Current')),
                ],
                onChanged: (value) => setState(() => _smokingStatus = value),
                validator: (value) =>
                    value == null ? 'Select smoking status' : null,
              ),
              if (_smokingStatus == 'current') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _smokingDetailsController,
                  decoration: const InputDecoration(
                    labelText: 'Daily usage or notes',
                  ),
                  validator: (value) {
                    if (_smokingStatus == 'current' &&
                        (value == null || value.isEmpty)) {
                      return 'Add brief detail for risk calculations';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _substanceUse,
                decoration:
                    const InputDecoration(labelText: 'Substance use'),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(
                      value: 'occasional', child: Text('Occasional')),
                  DropdownMenuItem(value: 'regular', child: Text('Regular')),
                ],
                onChanged: (value) => setState(() => _substanceUse = value),
                validator: (value) =>
                    value == null ? 'Select substance use' : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cardioRiskOptions.map(_cardioRiskChip).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewPage(ThemeData theme) {
    final baseline = _buildBaselinePreview();
    return _sectionShell(
      title: 'Final review & confirmation',
      subtitle:
          'Confirm accuracy. Submitting saves this as your baseline snapshot; you can refresh it later by re-running intake.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: baseline
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $entry'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        CheckboxListTile(
          value: _consentGiven,
          onChanged: (value) => setState(() => _consentGiven = value ?? false),
          title: const Text(
            'I confirm the above is accurate to use as my baseline snapshot.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (!_consentGiven)
          _errorText(theme, 'Consent is required to finish the baseline.'),
      ],
    );
  }

  Widget _errorText(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style:
              theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  Future<void> _nextPage() async {
    if (!_validateCurrentPage()) return;
    await _persistDraft();
    if (!mounted) return;
    setState(() {
      _pageIndex = (_pageIndex + 1).clamp(0, _totalPages - 1);
    });
  }

  void _previousPage() {
    setState(() {
      _pageIndex = (_pageIndex - 1).clamp(0, _totalPages - 1);
    });
  }

  bool _validateCurrentPage() {
    switch (_pageIndex) {
      case 0:
        final valid = _demographicsFormKey.currentState?.validate() ?? false;
        final heightCm = _useMetric ? _heightValue : _heightValue * 2.54;
        final weightKg = _useMetric ? _weightValue : _weightValue * 0.45359237;
        final heightRange = _heightRange(true);
        final weightRange = _weightRange(true);
        final heightValid =
            heightCm >= heightRange.min && heightCm <= heightRange.max;
        final weightValid =
            weightKg >= weightRange.min && weightKg <= weightRange.max;
        if (!heightValid || !weightValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Set realistic height and weight before continuing.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return valid && heightValid && weightValid;
      case 1:
        const valid = true;
        final hasCondition = _selectedConditions.isNotEmpty;
        if (!hasCondition) {
          setState(() {
            _medicalValidationError =
                'Select at least one condition to continue.';
          });
          return false;
        }
        _medicalValidationError = null;
        return valid;
      case 2:
        // Medications are optional; if supplements are toggled on with no entries, turn the toggle off to avoid blocking progress.
        if (_takesSupplements && _supplements.isEmpty) {
          setState(() => _takesSupplements = false);
        }
        return true;
      case 3:
        return true; // Typical day optional
      case 4:
        return _nutritionFormKey.currentState?.validate() ?? false;
      case 5:
        return _activityFormKey.currentState?.validate() ?? false;
      case 6:
        return _mentalFormKey.currentState?.validate() ?? false;
      case 7:
        return _riskFormKey.currentState?.validate() ?? false;
      case 8:
      default:
        return _consentGiven;
    }
  }

  String? _medicalValidationError;

  Future<void> _persistDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final answers = _buildAnswers(status: 'in_progress');
    await HealthQuestionnaireService.saveAnswersForUser(user.uid, answers);
  }

  Future<void> _completeFlow() async {
    if (!_validateCurrentPage()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      final version = _baselineVersion ?? 'baseline-${now.toIso8601String()}';
      final answers = _buildAnswers(
        status: 'editable',
        completedAt: now,
        lockedAt: null,
        baselineVersion: version,
      );
      await HealthQuestionnaireService.saveAnswersForUser(user.uid, answers);
      if (!mounted) return;
      Navigator.of(context).pop(
        HealthQuestionnaireResult(
          answers: answers,
          baselineVersion: version,
          completedAt: now.toLocal(),
          lockedAt: null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Map<String, dynamic> _buildAnswers({
    required String status,
    DateTime? completedAt,
    DateTime? lockedAt,
    String? baselineVersion,
  }) {
    final now = DateTime.now().toUtc();
    final ageText = _ageController.text.trim();
    final age = _dateOfBirth != null
        ? _calculateAge(_dateOfBirth!)
        : int.tryParse(ageText);
    final height = _useMetric ? _heightValue : _heightValue * 2.54;
    final weight = _useMetric ? _weightValue : _weightValue * 0.45359237;
    final bmi =
        height > 0 ? weight / ((height / 100) * (height / 100)) : null;
    final stressScore = _stressScore(_stressLevel, _burnout);
    final sleepScore = _sleepScore(_sleepHours, _sleepQuality);
    final nutritionScore = _nutritionScore(
      _dietPattern,
      _dietRestrictionSelections,
      _alcoholUse,
    );
    final emotionalScore = _emotionalScore(_mood, _focusIssues, _burnout);
    final activityProfile = _buildActivityProfile();

    final resolvedVersion =
        baselineVersion ?? _baselineVersion ?? 'baseline-${now.toIso8601String()}';
    _baselineVersion ??= resolvedVersion;
    final versionHistory =
        List<Map<String, dynamic>>.from(_initialAnswers?['versionHistory'] ?? []);
    // Keep version history but do not lock the baseline
    versionHistory.add({
      'version': resolvedVersion,
      'lockedAt': null,
    });

    return {
      'status': status,
      'editable': true,
      'lockState': 'unlocked',
      'updatedAt': now.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lockedAt': lockedAt?.toIso8601String(),
      'immutable': false,
      'baselineVersion': resolvedVersion,
      'lastSyncedAt': _initialAnswers?['lastSyncedAt'],
      'progress': {'pageIndex': _pageIndex},
      'versionHistory': versionHistory,
      'baseline': {
        'demographics': {
          'fullName': _fullNameController.text.trim().isEmpty
              ? null
              : _fullNameController.text.trim(),
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'age': age,
          'sex': _sex,
          'heightCm': height,
          'weightKg': weight,
          'bmi': bmi,
          'country': _country,
        },
        'general': {}, // reserved for future general health signals
        'medical': {
          'conditions': _selectedConditions
              .map((c) => {
                    'label': c.label,
                    'code': c.code,
                    'isCurrent': c.isCurrent,
                    'diagnosedYear': c.diagnosedYear?.trim().isEmpty == true
                        ? null
                        : c.diagnosedYear,
                  })
              .toList(),
        },
        'medications': {
          'hasPrescriptions': _medications.isNotEmpty || _takesPrescriptions,
          'hasSupplements': _takesSupplements,
          'prescriptions': _medications,
          'supplements': _supplements,
        },
        'sleep': {
          'avgHours': _sleepHours,
          'quality': _sleepQuality,
          'disturbances': _sleepDisturbances.toList(),
          'sleepDisorders': _sleepDisorders.toList(),
          'canonical': {'sleep_score': sleepScore},
        },
        'nutrition': {
          'dietPattern': _dietPattern,
          'dietNote': _otherDietController.text.trim().isEmpty
              ? null
              : _otherDietController.text.trim(),
          'restrictions': _dietRestrictionSelections.toList(),
          'alcohol': _alcoholUse,
          'caffeinePerDay': _caffeineUse,
          'canonical': {'nutrition_score': nutritionScore},
        },
        'routine': {
          'wakeUp': _wakeUpTime != null ? _format24h(_wakeUpTime!) : null,
          'bedTime': _bedTime != null ? _format24h(_bedTime!) : null,
          'dinnerTime': _dinnerTime != null ? _format24h(_dinnerTime!) : null,
          'sleepQuality': _typicalSleepQuality,
          'workShift': _workShift,
          'breakfastHabit': _breakfastHabit,
          'mealsPerDay': _mealsPerDay,
        },
        'activity': activityProfile,
        'mental': {
          'stress': _stressLevel,
          'mood': _mood,
          'focusIssues': _focusIssues,
          'burnoutIndicators': _burnout,
          'canonical': {
            'stress_score': stressScore,
            'emotional_score': emotionalScore,
          },
        },
        'risks': {
          'smokingStatus': _smokingStatus,
          'substanceUse': _substanceUse,
          'cardiometabolicRisks': [],
          'riskNotes': _smokingDetailsController.text.trim(),
        },
        'finalReview': {
          'consentAccepted': _consentGiven,
          'version': resolvedVersion,
          'lockedAt': lockedAt?.toIso8601String(),
          'editable': true,
        },
      },
    };
  }

  List<String> _buildBaselinePreview() {
    final bmi = _computeBmi();
    final age = _dateOfBirth != null ? _calculateAge(_dateOfBirth!) : null;
    return [
      if (_fullNameController.text.trim().isNotEmpty)
        'Name ${_fullNameController.text.trim()}',
      if (_dateOfBirth != null && _sex != null)
        'DOB ${_formatDate(_dateOfBirth!)}, Age $age, $_sex',
      if (_dateOfBirth == null &&
          _ageController.text.isNotEmpty &&
          _sex != null)
        'Age ${_ageController.text}, $_sex',
      if (_dateOfBirth == null &&
          _ageController.text.isNotEmpty &&
          _sex == null)
        'Age ${_ageController.text}',
      if (_country != null) 'Country: $_country',
      'Height: ${_formatHeightLabel()}',
      'Weight: ${_formatWeightLabel()}',
      if (bmi != null) 'BMI ${bmi.toStringAsFixed(1)}',
      if (_selectedConditions.isNotEmpty)
        'Conditions: ${_selectedConditions.length} recorded',
      if (_takesPrescriptions)
        'Medications: ${_medications.length} listed',
      if (_wakeUpTime != null)
        'Wake-up: ${_timeLabel(_wakeUpTime)}',
      if (_bedTime != null)
        'Bedtime: ${_timeLabel(_bedTime)}',
      if (_dinnerTime != null)
        'Dinner: ${_timeLabel(_dinnerTime)}',
      if (_typicalSleepQuality != null)
        'Sleep quality: $_typicalSleepQuality',
      if (_workShift != null) 'Work shift: $_workShift',
      if (_breakfastHabit != null) 'Breakfast: $_breakfastHabit',
      if (_mealsPerDay != null) 'Meals/day: $_mealsPerDay',
      if (_sleepHours != null) 'Sleep: ${_sleepHours?.toStringAsFixed(1)}h',
      if (_dietPattern != null) 'Diet: $_dietPattern',
      if (_activityFrequency != null && _activityIntensity != null)
        'Activity: $_activityFrequency/wk at $_activityIntensity intensity',
      if (_stressLevel != null) 'Stress: $_stressLevel',
      if (_smokingStatus != null) 'Smoking: $_smokingStatus',
    ];
  }

  double? _computeBmi() {
    final height = _useMetric ? _heightValue : _heightValue * 2.54;
    final weight = _useMetric ? _weightValue : _weightValue * 0.45359237;
    if (height == 0) return null;
    return weight / ((height / 100) * (height / 100));
  }

  String _formatHeightLabel() {
    if (_useMetric) {
      return '${_heightValue.toStringAsFixed(0)} cm';
    }
    final inches = _heightValue;
    final feet = (inches / 12).floor();
    final remainingInches = (inches - feet * 12).round();
    return "$feet'$remainingInches\"";
  }

  String _formatWeightLabel() {
    if (_useMetric) {
      return '${_weightValue.toStringAsFixed(1)} kg';
    }
    return '${_weightValue.toStringAsFixed(0)} lb';
  }

  ({double min, double max}) _heightRange(bool metric) =>
      (min: metric ? 120.0 : 48.0, max: metric ? 250.0 : 98.0);

  ({double min, double max}) _weightRange(bool metric) =>
      (min: metric ? 30.0 : 66.0, max: metric ? 250.0 : 550.0);

  double _clampHeight(double value, bool metric) {
    final range = _heightRange(metric);
    return value.clamp(range.min, range.max).toDouble();
  }

  double _clampWeight(double value, bool metric) {
    final range = _weightRange(metric);
    return value.clamp(range.min, range.max).toDouble();
  }

  String _format24h(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _resetActivityInputs() {
    _activityFrequency = 0;
    _activityIntensity = null;
    for (final entry in _categoryInputs.values) {
      entry
        ..daysPerWeek = null
        ..minutesPerSession = null
        ..intensity = null;
    }
    _stepRange = null;
    _jobActivity = null;
    _equipmentAccess.clear();
    _activityLimitations.clear();
    _trainingHistory = null;
  }

  int _estimateMetMinutes(int frequency, String? intensity) {
    final intensityFactor = switch (intensity) {
      'light' => 2.5,
      'moderate' => 4.5,
      'vigorous' => 8.0,
      _ => 2.5,
    };
    final minutesPerSession = 30;
    return (frequency * minutesPerSession * intensityFactor).round();
  }

  int _stressScore(String? stressLevel, bool burnout) {
    int base = switch (stressLevel) {
      'low' => 25,
      'moderate' => 55,
      'high' => 80,
      _ => 50,
    };
    if (burnout) base += 10;
    return base.clamp(0, 100);
  }

  int _sleepScore(double? hours, String? quality) {
    if (hours == null || quality == null) return 50;
    int base;
    if (hours >= 7.5) {
      base = 80;
    } else if (hours >= 6) {
      base = 60;
    } else {
      base = 35;
    }
    if (quality == 'restorative') base += 10;
    if (quality == 'poor') base -= 15;
    return base.clamp(0, 100);
  }

  int _nutritionScore(
    String? dietPattern,
    Set<String> restrictions,
    String? alcohol,
  ) {
    int base = switch (dietPattern) {
      'Mediterranean' => 80,
      'Balanced' => 70,
      'Plant-forward/vegetarian' => 70,
      'High protein' => 65,
      'Low carb' => 65,
      'Other' => 60,
      _ => 55,
    };
    if (alcohol == 'heavy') base -= 15;
    if (alcohol == 'moderate') base -= 5;
    if (restrictions.contains('None')) base += 0;
    return base.clamp(0, 100);
  }

  Map<String, dynamic> _buildActivityProfile() {
    final categories = <String, dynamic>{};
    _categoryInputs.forEach((key, input) {
      if (input.daysPerWeek == null &&
          input.minutesPerSession == null &&
          input.intensity == null) {
        return;
      }
      categories[key] = {
        'daysPerWeek': input.daysPerWeek,
        'minutesPerSession': input.minutesPerSession,
        'intensity': input.intensity,
      };
    });

    // Rough starting plan: sum minutes across categories
    int totalMinutes = 0;
    for (final input in _categoryInputs.values) {
      final days = input.daysPerWeek ?? 0;
      final minutes = input.minutesPerSession ?? 0;
      totalMinutes += days * minutes;
    }
    String startingLevel;
    if (totalMinutes >= 180) {
      startingLevel = 'high';
    } else if (totalMinutes >= 90) {
      startingLevel = 'moderate';
    } else if (totalMinutes > 0) {
      startingLevel = 'light';
    } else {
      startingLevel = 'none';
    }

    int progressionRate;
    switch (startingLevel) {
      case 'high':
        progressionRate = 5;
        break;
      case 'moderate':
        progressionRate = 10;
        break;
      case 'light':
        progressionRate = 15;
        break;
      default:
        progressionRate = 20;
    }

    return {
      'frequencyPerWeek': _activityFrequency,
      'intensity': _activityIntensity,
      'categories': categories,
      'stepRange': _stepRange,
      'jobActivity': _jobActivity,
      'equipment': _equipmentAccess.toList(),
      'limitations': _activityLimitations.toList(),
      'trainingHistory': _trainingHistory,
      'canonical': {
        'starting_minutes_per_week': totalMinutes,
        'starting_level': startingLevel,
        'progression_rate_percent': progressionRate,
        'estimated_met_minutes':
            _estimateMetMinutes(_activityFrequency ?? 0, _activityIntensity),
      },
    };
  }

  int _emotionalScore(String? mood, bool focusIssues, bool burnout) {
    int base = switch (mood) {
      'stable' => 75,
      'variable' => 55,
      'low' => 40,
      _ => 50,
    };
    if (focusIssues) base -= 5;
    if (burnout) base -= 10;
    return base.clamp(0, 100);
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) async {
    final now = TimeOfDay.now();
    return showTimePicker(
      context: context,
      initialTime: initial ?? now,
    );
  }

  Widget _dietRestrictionChip(String label) {
    final selected = _dietRestrictionSelections.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (label == 'None') {
            _dietRestrictionSelections = value ? {label} : <String>{};
          } else {
            _dietRestrictionSelections.remove('None');
            value
                ? _dietRestrictionSelections.add(label)
                : _dietRestrictionSelections.remove(label);
          }
        });
      },
    );
  }

  Widget _activityLimitationChip(String label) {
    final selected = _activityLimitations.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (label == 'None') {
            _activityLimitations = value ? {label} : <String>{};
          } else {
            _activityLimitations.remove('None');
            value
                ? _activityLimitations.add(label)
                : _activityLimitations.remove(label);
          }
        });
      },
    );
  }

  Widget _cardioRiskChip(String label) {
    final selected = _cardioRisks.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          value
              ? _cardioRisks.add(label)
              : _cardioRisks.remove(label);
        });
      },
    );
  }

  Widget _timePickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 6),
                Text(value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCategoryCard(_ActivityCategory category) {
    final input = _categoryInputs[category.key] ??
        _ActivityCategoryInput(key: category.key);
    _categoryInputs[category.key] = input;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.label,
              style:
                  Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue:
                        input.daysPerWeek != null ? '${input.daysPerWeek}' : null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days per week',
                    ),
                    onChanged: (v) =>
                        input.daysPerWeek = int.tryParse(v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: input.minutesPerSession != null
                        ? '${input.minutesPerSession}'
                        : null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes per session',
                    ),
                    onChanged: (v) =>
                        input.minutesPerSession = int.tryParse(v.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: input.intensity,
              decoration: const InputDecoration(labelText: 'How hard?'),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Easy')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(value: 'vigorous', child: Text('Hard')),
              ],
              onChanged: (v) => setState(() => input.intensity = v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMedicationWithDetails(_MedicationOption option) async {
    final doseController = TextEditingController();
    String adherence = 'Consistent';
    String frequency = 'Daily';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(option.label),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: doseController,
                  decoration: const InputDecoration(labelText: 'Dose'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(
                        value: 'Twice daily', child: Text('Twice daily')),
                    DropdownMenuItem(
                        value: 'Three times daily',
                        child: Text('Three times daily')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'As needed', child: Text('As needed')),
                  ],
                  onChanged: (value) => frequency = value ?? frequency,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: adherence,
                  decoration: const InputDecoration(labelText: 'Adherence'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Consistent', child: Text('Consistent')),
                    DropdownMenuItem(
                        value: 'Sometimes', child: Text('Sometimes')),
                    DropdownMenuItem(value: 'Rarely', child: Text('Rarely')),
                  ],
                  onChanged: (value) => adherence = value ?? adherence,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'name': option.label,
                  'code': option.code,
                  'dose': doseController.text.trim(),
                  'frequency': frequency,
                  'adherence': adherence,
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _medications.add(result);
        _takesPrescriptions = true;
      });
    }
  }

  Future<void> _showSupplementDialog() async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    String adherence = 'Consistent';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supplement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: 'Dose'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: adherence,
                decoration: const InputDecoration(labelText: 'Adherence'),
                items: const [
                  DropdownMenuItem(
                      value: 'Consistent', child: Text('Consistent')),
                  DropdownMenuItem(
                      value: 'Sometimes', child: Text('Sometimes')),
                  DropdownMenuItem(value: 'Rarely', child: Text('Rarely')),
                ],
                onChanged: (value) => adherence = value ?? adherence,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.of(context).pop({
                  'name': nameController.text.trim(),
                  'dose': doseController.text.trim(),
                  'adherence': adherence,
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _supplements.add(result));
    }
  }
}
