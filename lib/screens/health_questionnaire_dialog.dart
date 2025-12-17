import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/keyboard_dismissible.dart';
import '../services/health_questionnaire_service.dart';

// Helper function to create consistent page transitions for health questionnaire
PageRouteBuilder<T> _buildHealthQuestionnaireRoute<T>({
  required Widget page,
  bool fullscreenDialog = false,
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    fullscreenDialog: fullscreenDialog,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

Future<HealthQuestionnaireResult?> showHealthQuestionnaireDialog(
  BuildContext context, {
  Map<String, dynamic>? initialAnswers,
  bool allowCancel = true,
}) {
  return Navigator.of(context).push<HealthQuestionnaireResult>(
    _buildHealthQuestionnaireRoute(
      page: _HealthQuestionnaireFlow(
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
    required this.conditions,
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
  final List<String> conditions;
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

class _CategoryOption {
  const _CategoryOption(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;
}

class _QuestionnaireProgressIndicator extends StatelessWidget
    implements PreferredSizeWidget {
  const _QuestionnaireProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.sectionName,
  });

  final int currentStep;
  final int totalSteps;
  final String sectionName;

  @override
  Size get preferredSize => const Size.fromHeight(50.0);

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    final theme = Theme.of(context);

    return Container(
      height: 50.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFDDDDDD),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Step $currentStep of $totalSteps — $sectionName',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
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

// Canonical: profile.sex_at_birth (enum: male|female|intersex|other)
const List<_LabeledOption> _sexOptions = [
  _LabeledOption('female', 'Female'),
  _LabeledOption('male', 'Male'),
];

const List<_RegionOption> _regionOptions = [
  // North America
  _RegionOption(code: 'US', label: 'United States', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'CA', label: 'Canada', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'MX', label: 'Mexico', glucoseUnit: 'mg/dL'),

  // Central & South America
  _RegionOption(code: 'AR', label: 'Argentina', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'BR', label: 'Brazil', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'CL', label: 'Chile', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'CO', label: 'Colombia', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'PE', label: 'Peru', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'VE', label: 'Venezuela', glucoseUnit: 'mg/dL'),

  // Europe
  _RegionOption(code: 'GB', label: 'United Kingdom', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'DE', label: 'Germany', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'FR', label: 'France', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'IT', label: 'Italy', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'ES', label: 'Spain', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'NL', label: 'Netherlands', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'BE', label: 'Belgium', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'CH', label: 'Switzerland', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'AT', label: 'Austria', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'SE', label: 'Sweden', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'NO', label: 'Norway', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'DK', label: 'Denmark', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'FI', label: 'Finland', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'IE', label: 'Ireland', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'PT', label: 'Portugal', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'GR', label: 'Greece', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'PL', label: 'Poland', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'CZ', label: 'Czech Republic', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'RO', label: 'Romania', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'HU', label: 'Hungary', glucoseUnit: 'mmol/L'),

  // Asia Pacific
  _RegionOption(code: 'AU', label: 'Australia', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'NZ', label: 'New Zealand', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'JP', label: 'Japan', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'CN', label: 'China', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'IN', label: 'India', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'KR', label: 'South Korea', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'TW', label: 'Taiwan', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'SG', label: 'Singapore', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'MY', label: 'Malaysia', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'TH', label: 'Thailand', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'PH', label: 'Philippines', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'ID', label: 'Indonesia', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'VN', label: 'Vietnam', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'PK', label: 'Pakistan', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'BD', label: 'Bangladesh', glucoseUnit: 'mg/dL'),

  // Middle East & Africa
  _RegionOption(code: 'IL', label: 'Israel', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'AE', label: 'United Arab Emirates', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'SA', label: 'Saudi Arabia', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'TR', label: 'Turkey', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'EG', label: 'Egypt', glucoseUnit: 'mg/dL'),
  _RegionOption(code: 'ZA', label: 'South Africa', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'NG', label: 'Nigeria', glucoseUnit: 'mmol/L'),
  _RegionOption(code: 'KE', label: 'Kenya', glucoseUnit: 'mmol/L'),

  // Other
  _RegionOption(code: 'OTHER', label: 'Other', glucoseUnit: 'mg/dL'),
];

// Canonical: profile.diabetes_type (enum: T1D|T2D|Prediabetes|Monitoring)
const List<_LabeledOption> _diabetesTypeOptions = [
  _LabeledOption('T1D', 'Type 1 Diabetes'),
  _LabeledOption('T2D', 'Type 2 Diabetes'),
  _LabeledOption('Prediabetes', 'Prediabetes'),
  _LabeledOption('Monitoring', 'Monitoring only'),
];

// Canonical: profile.therapy (enum: MDI|Pump|NonInsulin|DietExercise|None)
const List<_LabeledOption> _treatmentOptions = [
  _LabeledOption('MDI', 'Multiple daily injections (MDI)'),
  _LabeledOption('Pump', 'Insulin pump'),
  _LabeledOption('NonInsulin', 'Non-insulin medication'),
  _LabeledOption('DietExercise', 'Diet & exercise'),
  _LabeledOption('None', 'None'),
];

// Canonical: profile.comorbidities[] - organized by semantic categories
// ICD-10 codes included as comments for clinical reference
const Map<String, List<_LabeledOption>> _conditionsByCategory = {
  'cardiometabolic': [
    // I13
    _LabeledOption('combined_htn_heart_kidney', 'Combined heart + kidney disease'),
    // E78.5
    _LabeledOption('dyslipidemia', 'Dyslipidemia'),
    // E78.0
    _LabeledOption('hypercholesterolemia', 'Hypercholesterolemia'),
    // I10
    _LabeledOption('hypertension', 'Hypertension'),
    // I12
    _LabeledOption('htn_ckd', 'Hypertensive chronic kidney disease'),
    // I11
    _LabeledOption('htn_heart', 'Hypertensive heart disease'),
    // E78.1
    _LabeledOption('hypertriglyceridemia', 'Hypertriglyceridemia'),
    // E88.81
    _LabeledOption('insulin_resistance', 'Insulin resistance'),
    // E78.6
    _LabeledOption('low_hdl', 'Low HDL'),
    // E88.81
    _LabeledOption('metabolic_syndrome', 'Metabolic syndrome'),
    // K75.81
    _LabeledOption('nash', 'Non-alcoholic steatohepatitis (NASH)'),
    // K76.0
    _LabeledOption('nafld', 'Non-alcoholic fatty liver disease (NAFLD)'),
    // E66.9
    _LabeledOption('obesity', 'Obesity'),
    // R73.01 / R73.03
    _LabeledOption('prediabetes', 'Prediabetes / Impaired fasting glucose'),
    // E66.01 / E66.02
    _LabeledOption('severe_obesity', 'Severe obesity (BMI ≥35)'),
    // E11
    _LabeledOption('type2_diabetes', 'Type 2 Diabetes'),
  ],
  'endocrine': [
    // E06.3
    _LabeledOption('hashimoto', 'Hashimoto\'s thyroiditis'),
    // E05.90
    _LabeledOption('hyperthyroidism', 'Hyperthyroidism'),
    // E03.9
    _LabeledOption('hypothyroidism', 'Hypothyroidism'),
    // E28.2
    _LabeledOption('pcos', 'Polycystic Ovary Syndrome (PCOS)'),
    // E29.1
    _LabeledOption('testosterone_deficiency', 'Testosterone deficiency'),
    // E10
    _LabeledOption('type1_diabetes', 'Type 1 Diabetes'),
    // E55.9
    _LabeledOption('vitamin_d_deficiency', 'Vitamin D deficiency'),
  ],
  'cardiovascular': [
    // I20.9
    _LabeledOption('angina', 'Angina pectoris'),
    // I25.10
    _LabeledOption('cad', 'Coronary artery disease (CAD)'),
    // I50.9 / I50.2
    _LabeledOption('heart_failure', 'Heart failure'),
    // I25.2
    _LabeledOption('mi_history', 'History of myocardial infarction'),
    // I73.9
    _LabeledOption('pad', 'Peripheral arterial disease (PAD)'),
  ],
  'renal': [
    // N18.1–N18.5
    _LabeledOption('ckd', 'Chronic kidney disease (CKD)'),
    // E11.21
    _LabeledOption('diabetic_nephropathy', 'Diabetic nephropathy'),
    // N18.6
    _LabeledOption('esrd', 'End-stage renal disease'),
  ],
  'respiratory_sleep': [
    // F51.04
    _LabeledOption('insomnia', 'Insomnia (chronic)'),
    // G47.33
    _LabeledOption('osa', 'Obstructive Sleep Apnea (OSA)'),
    // G47.30
    _LabeledOption('sleep_breathing', 'Sleep-related breathing disorders'),
  ],
  'gi_metabolic': [
    // K21.9
    _LabeledOption('gerd', 'GERD'),
    // K58.9
    _LabeledOption('ibs', 'Irritable bowel syndrome'),
  ],
  'autoimmune': [
    // L40.50
    _LabeledOption('psoriatic_arthritis', 'Psoriatic arthritis'),
    // L40.0
    _LabeledOption('psoriasis', 'Psoriasis'),
    // M06.9
    _LabeledOption('rheumatoid_arthritis', 'Rheumatoid arthritis'),
  ],
  'mental_health': [
    // F33.9
    _LabeledOption('depression', 'Depression'),
    // F41.1
    _LabeledOption('anxiety', 'Generalized anxiety disorder'),
  ],
  'other': [
    // D64.9
    _LabeledOption('anemia', 'Anemia'),
    // M10.9 / E79.0
    _LabeledOption('gout', 'Gout / Hyperuricemia'),
    // G43.909
    _LabeledOption('migraine', 'Migraine'),
    _LabeledOption('other_condition', 'Other'),
  ],
};

const List<_CategoryOption> _conditionCategories = [
  _CategoryOption('cardiometabolic', 'Cardiometabolic Disorders', 'Hypertension, cholesterol, diabetes, obesity, metabolic'),
  _CategoryOption('endocrine', 'Endocrine & Hormonal', 'Thyroid, PCOS, diabetes, hormonal'),
  _CategoryOption('cardiovascular', 'Cardiovascular', 'Heart disease, CAD, heart failure'),
  _CategoryOption('renal', 'Renal', 'Kidney disease, CKD, nephropathy'),
  _CategoryOption('respiratory_sleep', 'Respiratory & Sleep', 'Sleep apnea, insomnia'),
  _CategoryOption('gi_metabolic', 'GI / Metabolic', 'GERD, IBS'),
  _CategoryOption('autoimmune', 'Inflammatory & Autoimmune', 'Arthritis, psoriasis'),
  _CategoryOption('mental_health', 'Mental Health', 'Depression, anxiety'),
  _CategoryOption('other', 'Other', 'Gout, migraine, anemia'),
  _CategoryOption('none', 'No diagnoses', 'No known conditions'),
];

// Canonical: profile.meds[] (set: metformin|glp1|sglt2|basal_ins|bolus_ins|other)
const List<_LabeledOption> _medicationOptions = [
  _LabeledOption('metformin', 'Metformin'),
  _LabeledOption('glp1', 'GLP-1 receptor agonist'),
  _LabeledOption('sglt2', 'SGLT2 inhibitor'),
  _LabeledOption('basal_ins', 'Basal insulin'),
  _LabeledOption('bolus_ins', 'Bolus insulin'),
  _LabeledOption('other', 'Other'),
  _LabeledOption('none', 'None'),
];

// Canonical: lifestyle.work_pattern (enum: daytime|shift|irregular|student|retired)
const List<_LabeledOption> _workPatternOptions = [
  _LabeledOption('daytime', 'Daytime'),
  _LabeledOption('shift', 'Shift work'),
  _LabeledOption('irregular', 'Irregular'),
  _LabeledOption('student', 'Student'),
  _LabeledOption('retired', 'Retired'),
];

// Canonical: lifestyle.breakfast_habit (enum: daily|sometimes|never)
const List<_LabeledOption> _breakfastHabitOptions = [
  _LabeledOption('daily', 'Every day'),
  _LabeledOption('sometimes', 'Sometimes'),
  _LabeledOption('never', 'Never'),
];

// Canonical: lifestyle.caffeine_per_day (enum: none|1_2|3_5|gt5)
const List<_LabeledOption> _caffeineOptions = [
  _LabeledOption('none', 'None'),
  _LabeledOption('1_2', '1–2 cups'),
  _LabeledOption('3_5', '3–5 cups'),
  _LabeledOption('gt5', 'More than 5 cups'),
];

// Canonical: lifestyle.alcohol_freq (enum: never|occasional|several_per_week|daily)
const List<_LabeledOption> _alcoholOptions = [
  _LabeledOption('never', 'Never'),
  _LabeledOption('occasional', 'Occasionally'),
  _LabeledOption('several_per_week', 'Several times a week'),
  _LabeledOption('daily', 'Daily'),
];

// Canonical: lifestyle.smoker (bool - converted from yes/no)
const List<_LabeledOption> _smokingOptions = [
  _LabeledOption('yes', 'Yes'),
  _LabeledOption('no', 'No'),
];

// Canonical: lifestyle.perceived_energy (enum: low|moderate|high)
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
  conditions,
}

enum _Section { basic, measurements, management }

class _StepInfo {
  const _StepInfo(this.step, this.sectionName);
  final int step;
  final String sectionName;
}

const Duration _kValidationFadeDuration = Duration(milliseconds: 180);

const Map<_FieldId, _Section> _fieldSection = {
  _FieldId.fullName: _Section.basic,
  _FieldId.dob: _Section.basic,
  _FieldId.gender: _Section.basic,
  _FieldId.height: _Section.measurements,
  _FieldId.weight: _Section.measurements,
  _FieldId.country: _Section.measurements,
  _FieldId.conditions: _Section.management,
};

const Map<_Section, Set<_FieldId>> _sectionFields = {
  _Section.basic: {_FieldId.fullName, _FieldId.dob, _FieldId.gender},
  _Section.measurements: {_FieldId.height, _FieldId.weight, _FieldId.country},
  _Section.management: {
    _FieldId.conditions,
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
  final List<Map<String, dynamic>> _medications = []; // List of {name, dose, frequency, indication}
  double? _bmi;
  bool _showSelectionErrors = false;
  int _currentProfileSection = 0; // 0 or 1 for the two sections

  // New state for search-first collapsible UI
  final TextEditingController _conditionSearchController = TextEditingController();
  String? _expandedConditionGroup; // Only one group expanded at a time
  int _conditionSubPage = 0; // 0=conditions, 1=medications, 2=review

  // Unified page management: 0=Basic Info, 1=Conditions, 2=Lifestyle, 3=Activity, 4=Psych, 5=Nutrition, 6=Stress/Sleep
  int _currentPage = 0;

  // Lifestyle page state
  final TextEditingController _sleepDurationController = TextEditingController();
  TimeOfDay? _wakeUpTime;
  TimeOfDay? _bedtime;
  TimeOfDay? _dinnerTime;
  int? _sleepQuality;
  String? _workPattern;
  String? _breakfastHabit;
  int? _mealsPerDay;
  String? _caffeineIntake;
  String? _alcoholConsumption;
  String? _smokingStatus;
  String? _energyLevel;

  Map<String, dynamic> _draftAnswers = <String, dynamic>{};
  Map<String, dynamic>? _initialLifestyle;
  Map<String, dynamic>? _initialActivity;
  Map<String, dynamic>? _initialStress;
  Map<String, dynamic>? _initialSleep;
  Map<String, dynamic>? _initialNutrition;
  Map<String, dynamic>? _initialPsych;

  // Interaction logging - tracks every user action throughout the questionnaire
  final List<Map<String, dynamic>> _interactionLog = [];

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
    _loadInteractionLog();
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
    // Auto-save draft when field loses focus
    _persistProfileDraft();
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
          'conditions': _conditions.toList(),
          'medications': _medications.map((m) => Map<String, dynamic>.from(m)).toList(),
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
    _fieldValidity[_FieldId.conditions] = _conditions.isNotEmpty;
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
    _conditionSearchController.dispose();
    _sleepDurationController.dispose();
    super.dispose();
  }

  _StepInfo _getStepInfo() {
    // Single continuous flow - calculate completion based on filled fields
    final totalSections = 7;
    int completedSections = 0;

    // Count completed sections
    if (_nameController.text.isNotEmpty && _dob != null && _gender != null) completedSections++;
    if (_conditions.isNotEmpty) completedSections++;
    if (_workPattern != null) completedSections++;
    // Can add more completion checks for other sections

    return _StepInfo(completedSections + 1, 'Health Profile');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = _sectionSaving.values.any((saving) => saving);

    // Determine the leading button
    Widget? leading;
    if (widget.allowCancel) {
      leading = BackButton(
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
      );
    }

    // Map current page to step number and section name
    final stepInfo = _getStepInfo();

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile'),
        leading: leading,
        bottom: _QuestionnaireProgressIndicator(
          currentStep: stepInfo.step,
          totalSteps: 7,
          sectionName: stepInfo.sectionName,
        ),
      ),
      body: _buildCurrentPage(theme),
    );
    if (widget.allowCancel) {
      return scaffold;
    }

    // Handle back navigation between sections, but prevent exit from section 1
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) return;

        // If in section 2, go back to section 1
        if (_currentProfileSection == 1) {
          _goBackToSection2();
        } else if (_currentProfileSection == 0) {
          // In section 1, show error message and prevent exit
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please complete the health profile'),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: scaffold,
    );
  }

  Widget _buildCurrentPage(ThemeData theme) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: KeyboardDismissible(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome header
                  Text(
                    "Let's personalize your health journey.",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your data is encrypted and stored securely.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // All sections in one continuous flow
                  ..._buildAllSections(theme),

                  // Final submit button
                  const SizedBox(height: 24),
                  Text(
                    'This helps us tailor your daily health insights.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: const Text('Complete Profile'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAllSections(ThemeData theme) {
    return [
      // Section 1: Personal Details
      ..._buildSection1(theme),

      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 24),

      // Section 2: Health Conditions
      ..._buildSection3(theme),

      // Additional sections will be added here
    ];
  }

  List<Widget> _buildSection1(ThemeData theme) {
    return [
                  Text(
                    'Personal Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
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
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g., John Smith',
                      ),
                      onTap: () => HapticFeedback.lightImpact(),
                      onChanged: (newValue) {
                        _logInteraction(
                          eventType: 'field_change',
                          field: 'fullName',
                          oldValue: null,
                          newValue: newValue,
                        );
                        _invalidateField(_FieldId.fullName);
                      },
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
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _pickDateOfBirth();
                      },
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
                    const SizedBox(height: 6),
                    Text('Age: ${_calculateAge(_dob!)} years'),
                  ],
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.country,
                    child: DropdownButtonFormField<String>(
                      key: _countryFieldKey,
                      initialValue: _countryCode,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                      ),
                      items: _regionOptions
                          .map(
                            (region) => DropdownMenuItem<String>(
                              value: region.code,
                              child: Text(region.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        _selectCountry(value);
                      },
                      validator: (value) => value == null
                          ? 'Please choose a country or region'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    context: context,
                    fieldId: _FieldId.gender,
                    child: DropdownButtonFormField<String>(
                      key: _genderFieldKey,
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Sex at birth',
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
                        HapticFeedback.lightImpact();
                        final oldGender = _gender;
                        _logInteraction(
                          eventType: 'selection',
                          field: 'gender',
                          oldValue: oldGender,
                          newValue: value,
                        );
                        setState(() => _gender = value);
                        _persistProfileDraft(); // Auto-save on selection change
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
                  const SizedBox(height: 24),
                  Text(
                    'Body Metrics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
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
                              hintText: 'e.g., 176 cm',
                            ),
                            onTap: () => HapticFeedback.lightImpact(),
                            onChanged: (newValue) {
                              _logInteraction(
                                eventType: 'field_change',
                                field: 'height',
                                oldValue: null,
                                newValue: newValue,
                                metadata: {'unit': _heightUnit},
                              );
                              _invalidateField(_FieldId.height);
                            },
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
                              hintText: 'e.g., 68 kg',
                            ),
                            onTap: () => HapticFeedback.lightImpact(),
                            onChanged: (newValue) {
                              _logInteraction(
                                eventType: 'field_change',
                                field: 'weight',
                                oldValue: null,
                                newValue: newValue,
                                metadata: {'unit': _weightUnit},
                              );
                              _invalidateField(_FieldId.weight);
                            },
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
                    const SizedBox(height: 6),
                    Text('BMI: ${_bmi!.toStringAsFixed(1)}'),
                  ],
    ];
  }


  List<Widget> _buildSection3(ThemeData theme) {
    final searchQuery = _conditionSearchController.text.trim().toLowerCase();
    final hasSearch = searchQuery.isNotEmpty;

    return [
      // Section header
      Text(
        'Health Conditions',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Select any health conditions you have been diagnosed with.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      const SizedBox(height: 16),

      // Search bar
      TextField(
        controller: _conditionSearchController,
        decoration: InputDecoration(
          hintText: 'Search conditions (e.g., hypertension, diabetes, PCOS)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasSearch
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _conditionSearchController.clear();
                    });
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (query) {
          _logInteraction(
            eventType: 'search',
            field: 'conditionSearch',
            oldValue: null,
            newValue: query,
          );
          setState(() {});
        },
      ),
      const SizedBox(height: 16),

      // Collapsible category groups
      if (hasSearch)
        ..._buildSearchResults(theme, searchQuery)
      else
        ..._buildCollapsibleGroups(theme),

      if (_showSelectionErrors && _conditions.isEmpty) ...[
        const SizedBox(height: 8),
        Text(
          'Please select at least one condition or choose "No diagnoses".',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }

  List<Widget> _buildCollapsibleGroups(ThemeData theme) {
    final widgets = <Widget>[];

    for (final category in _conditionCategories) {
      final isNone = category.value == 'none';
      final isExpanded = _expandedConditionGroup == category.value;
      final conditions = isNone ? <_LabeledOption>[] : (_conditionsByCategory[category.value] ?? []);
      final selectedCount = conditions.where((c) => _conditions.contains(c.value)).length;
      final hasNone = _conditions.contains('none');
      final isSelected = isNone ? hasNone : selectedCount > 0;

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (isNone) {
                    // Toggle "No diagnoses"
                    final oldHasNone = hasNone;
                    _logInteraction(
                      eventType: 'selection',
                      field: 'condition',
                      oldValue: oldHasNone,
                      newValue: !oldHasNone,
                      metadata: {'condition': 'none', 'action': oldHasNone ? 'remove' : 'add'},
                    );
                    setState(() {
                      if (hasNone) {
                        _conditions.remove('none');
                      } else {
                        _conditions.clear();
                        _conditions.add('none');
                        _expandedConditionGroup = null;
                      }
                      _updateFieldValidity(_FieldId.conditions, _conditions.isNotEmpty);
                    });
                    _persistProfileDraft();
                  } else {
                    // Toggle expansion
                    final oldExpanded = _expandedConditionGroup;
                    final newExpanded = isExpanded ? null : category.value;
                    _logInteraction(
                      eventType: 'navigation',
                      field: 'categoryExpansion',
                      oldValue: oldExpanded,
                      newValue: newExpanded,
                      metadata: {'action': isExpanded ? 'collapse' : 'expand'},
                    );
                    setState(() {
                      _expandedConditionGroup = newExpanded;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.label,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? theme.colorScheme.primary : null,
                                    ),
                                  ),
                                ),
                                if (selectedCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$selectedCount',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isNone)
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),

              // Expanded condition checkboxes
              if (isExpanded && !isNone)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: conditions.map((condition) {
                      final isChecked = _conditions.contains(condition.value);
                      return CheckboxListTile(
                        title: Text(condition.label),
                        value: isChecked,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (checked) {
                          final wasChecked = isChecked;
                          _logInteraction(
                            eventType: 'selection',
                            field: 'condition',
                            oldValue: wasChecked,
                            newValue: checked,
                            metadata: {
                              'condition': condition.value,
                              'conditionLabel': condition.label,
                              'action': checked == true ? 'add' : 'remove',
                            },
                          );
                          setState(() {
                            _conditions.remove('none');
                            if (checked == true) {
                              _conditions.add(condition.value);
                            } else {
                              _conditions.remove(condition.value);
                            }
                            _updateFieldValidity(_FieldId.conditions, _conditions.isNotEmpty);
                          });
                          _persistProfileDraft();
                        },
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildSearchResults(ThemeData theme, String query) {
    // Flatten all conditions with their category
    final allConditions = <Map<String, dynamic>>[];
    for (final category in _conditionCategories) {
      if (category.value == 'none') continue;
      final conditions = _conditionsByCategory[category.value] ?? [];
      for (final condition in conditions) {
        allConditions.add({
          'category': category.label,
          'value': condition.value,
          'label': condition.label,
        });
      }
    }

    // Filter by search query
    final results = allConditions.where((c) {
      return (c['label'] as String).toLowerCase().contains(query);
    }).toList();

    if (results.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No conditions found for "$query"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }

    return results.map((result) {
      final isChecked = _conditions.contains(result['value']);
      return CheckboxListTile(
        title: Text(result['label'] as String),
        subtitle: Text(
          result['category'] as String,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: isChecked,
        onChanged: (checked) {
          setState(() {
            _conditions.remove('none');
            if (checked == true) {
              _conditions.add(result['value'] as String);
            } else {
              _conditions.remove(result['value']);
            }
            _updateFieldValidity(_FieldId.conditions, _conditions.isNotEmpty);
          });
          _persistProfileDraft();
        },
      );
    }).toList();
  }

  // ===== MEDICATIONS PAGE (Stage 2) =====
  List<Widget> _buildMedicationsPage(ThemeData theme) {
    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _conditionSubPage = 0;
              });
            },
          ),
          Expanded(
            child: Text(
              'Current Medications',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Add any medications you\'re currently taking (optional)',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),

      // Medication list
      if (_medications.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No medications added yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        ..._medications.asMap().entries.map((entry) {
          final index = entry.key;
          final med = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(med['name'] ?? ''),
              subtitle: Text(
                '${med['dose'] ?? ''} • ${med['frequency'] ?? ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final removedMed = _medications[index];
                  _logInteraction(
                    eventType: 'selection',
                    field: 'medication',
                    oldValue: removedMed,
                    newValue: null,
                    metadata: {'action': 'remove', 'medicationName': removedMed['name']},
                  );
                  setState(() {
                    _medications.removeAt(index);
                  });
                  _persistProfileDraft();
                },
              ),
            ),
          );
        }).toList(),

      const SizedBox(height: 16),

      // Add medication button
      OutlinedButton.icon(
        onPressed: _showAddMedicationDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add medication'),
      ),

      const SizedBox(height: 24),

      // Continue button
      FilledButton(
        onPressed: _goToReviewPage,
        child: const Text('Review & continue'),
      ),

      // Skip button
      TextButton(
        onPressed: _goToReviewPage,
        child: const Text('Skip medications'),
      ),
    ];
  }

  // ===== REVIEW PAGE (Stage 3) =====
  List<Widget> _buildReviewPage(ThemeData theme) {
    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _conditionSubPage = 1;
              });
            },
          ),
          Expanded(
            child: Text(
              'Review Your Information',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Conditions section
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conditions',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _conditionSubPage = 0;
                      });
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._buildConditionsSummary(theme),
            ],
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Medications section
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medications',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _conditionSubPage = 1;
                      });
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_medications.isEmpty)
                Text(
                  'No medications',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ..._medications.map((med) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${med['name']} - ${med['dose']} (${med['frequency']})',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),

      const SizedBox(height: 24),

      // Final continue button
      FilledButton(
        onPressed: _handleContinueToLifestyle,
        child: const Text('Continue to lifestyle questions'),
      ),
    ];
  }

  List<Widget> _buildConditionsSummary(ThemeData theme) {
    if (_conditions.contains('none')) {
      return [
        Text(
          'No known conditions',
          style: theme.textTheme.bodyMedium,
        ),
      ];
    }

    // Group conditions by category
    final grouped = <String, List<String>>{};
    for (final conditionValue in _conditions) {
      for (final category in _conditionCategories) {
        if (category.value == 'none') continue;
        final conditions = _conditionsByCategory[category.value] ?? [];
        final match = conditions.firstWhere(
          (c) => c.value == conditionValue,
          orElse: () => const _LabeledOption('', ''),
        );
        if (match.value.isNotEmpty) {
          grouped.putIfAbsent(category.label, () => []);
          grouped[category.label]!.add(match.label);
          break;
        }
      }
    }

    final widgets = <Widget>[];
    grouped.forEach((categoryLabel, conditionLabels) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              ...conditionLabels.map((label) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• $label'),
              )),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  // ===== NAVIGATION HELPERS =====
  void _goToMedicationsPage() {
    _logInteraction(
      eventType: 'navigation',
      field: 'conditionSubPage',
      oldValue: _conditionSubPage,
      newValue: 1,
      metadata: {'page': 'medications'},
    );
    setState(() {
      _conditionSubPage = 1;
    });
  }

  void _goToReviewPage() {
    _logInteraction(
      eventType: 'navigation',
      field: 'conditionSubPage',
      oldValue: _conditionSubPage,
      newValue: 2,
      metadata: {'page': 'review'},
    );
    setState(() {
      _conditionSubPage = 2;
    });
  }

  // ===== MEDICATION DIALOG =====
  Future<void> _showAddMedicationDialog() async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    String frequency = 'Daily';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication name',
                        hintText: 'e.g., Metformin',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: doseController,
                      decoration: const InputDecoration(
                        labelText: 'Dose',
                        hintText: 'e.g., 500mg',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'Twice daily', child: Text('Twice daily')),
                        DropdownMenuItem(value: 'Three times daily', child: Text('Three times daily')),
                        DropdownMenuItem(value: 'As needed', child: Text('As needed')),
                        DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            frequency = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final dose = doseController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context, {
                        'name': name,
                        'dose': dose.isEmpty ? 'Not specified' : dose,
                        'frequency': frequency,
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _logInteraction(
        eventType: 'selection',
        field: 'medication',
        oldValue: null,
        newValue: result,
        metadata: {
          'action': 'add',
          'medicationName': result['name'],
          'dose': result['dose'],
          'frequency': result['frequency'],
        },
      );
      setState(() {
        _medications.add(result);
      });
      _persistProfileDraft();
    }
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
      _gender = _migrateGender(gender);
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
      _countryCode = _migrateCountryCode(country);
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
      _diabetesType = _migrateDiabetesType(diabetesType);
    }

    final treatment =
        data['treatment'] as String? ?? data['currentTreatment'] as String?;
    if (treatment != null && treatment.isNotEmpty) {
      _treatment = _migrateTherapy(treatment);
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
      _medications.clear();
      for (final med in medicationsRaw) {
        if (med is Map) {
          // New format: {name, dose, frequency}
          _medications.add(Map<String, dynamic>.from(med));
        } else if (med is String && med.isNotEmpty) {
          // Old format: migrate string to map
          _medications.add({
            'name': _migrateMedication(med),
            'dose': 'Not specified',
            'frequency': 'Not specified',
          });
        }
      }
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

  /// Migrates old gender/sex values to new canonical values
  String _migrateGender(String oldValue) {
    const migration = {
      'non_binary': 'other',
      'prefer_not_to_say': 'other',
    };
    return migration[oldValue] ?? oldValue;
  }

  /// Migrates old diabetes type values to new canonical values
  String _migrateDiabetesType(String oldValue) {
    const migration = {
      'type1': 'T1D',
      'type2': 'T2D',
      'prediabetes': 'Prediabetes',
      'monitoring_only': 'Monitoring',
    };
    return migration[oldValue] ?? oldValue;
  }

  /// Migrates old therapy/treatment values to new canonical values
  String _migrateTherapy(String oldValue) {
    const migration = {
      'mdi': 'MDI',
      'pump': 'Pump',
      'non_insulin_medication': 'NonInsulin',
      'diet_exercise': 'DietExercise',
      'none': 'None',
    };
    return migration[oldValue] ?? oldValue;
  }

  /// Migrates old medication values to new canonical values
  String _migrateMedication(String oldValue) {
    const migration = {
      'basal_insulin': 'basal_ins',
      'bolus_insulin': 'bolus_ins',
    };
    return migration[oldValue] ?? oldValue;
  }

  // ========== INTERACTION LOGGING ==========

  /// Logs a user interaction with timestamp and context
  void _logInteraction({
    required String eventType,
    required String field,
    dynamic oldValue,
    dynamic newValue,
    Map<String, dynamic>? metadata,
  }) {
    _interactionLog.add({
      'timestamp': DateTime.now().toIso8601String(),
      'eventType': eventType, // 'field_change', 'selection', 'navigation', 'search', etc.
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'section': _getSectionName(),
      'subPage': _conditionSubPage,
      ...?metadata,
    });
    _persistInteractionLog();
  }

  /// Gets the current section name for logging context
  String _getSectionName() {
    if (_currentProfileSection == 0) {
      return 'basic_info';
    } else if (_currentProfileSection == 1) {
      if (_conditionSubPage == 0) return 'conditions';
      if (_conditionSubPage == 1) return 'medications';
      if (_conditionSubPage == 2) return 'review';
      return 'health_conditions';
    }
    return 'unknown';
  }

  /// Loads interaction log from SharedPreferences
  Future<void> _loadInteractionLog() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final key = 'health_questionnaire_interaction_log_$userId';
    final jsonString = prefs.getString(key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          _interactionLog.clear();
          _interactionLog.addAll(
            decoded.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      } catch (e) {
        debugPrint('Error loading interaction log: $e');
      }
    }
  }

  /// Persists interaction log to SharedPreferences
  Future<void> _persistInteractionLog() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final key = 'health_questionnaire_interaction_log_$userId';
    try {
      final jsonString = jsonEncode(_interactionLog);
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error persisting interaction log: $e');
    }
  }

  // ========== END INTERACTION LOGGING ==========

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final oldDob = _dob;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      _logInteraction(
        eventType: 'field_change',
        field: 'dateOfBirth',
        oldValue: oldDob?.toIso8601String(),
        newValue: picked.toIso8601String(),
      );
      setState(() {
        _dob = picked;
        _dobController.text = _formatDate(picked);
      });
      _validateFormField(_FieldId.dob, _dobFieldKey);
      _persistProfileDraft(); // Auto-save on date selection
    }
  }

  Future<void> _goToSection3() async {
    // Validate section 1 fields before proceeding
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      return;
    }

    // Save draft before moving to next section
    await _persistProfileDraft();

    if (!mounted) return;

    setState(() {
      _currentProfileSection = 1;
    });
  }

  Future<void> _goBackToSection2() async{
    // Save draft before going back
    await _persistProfileDraft();

    if (!mounted) return;

    setState(() {
      _currentProfileSection = 0;
    });
  }

  Future<void> _handleSubmit() async {
    // Validate all required fields
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    final selectionsValid = _conditions.isNotEmpty;

    if (!selectionsValid) {
      setState(() => _showSelectionErrors = true);
    }

    if (!formValid || !selectionsValid) {
      // Scroll to top to show validation errors
      return;
    }

    if (_dob == null || _gender == null || _countryCode == null) {
      return;
    }

    setState(() => _showSelectionErrors = false);

    // Complete the questionnaire with basic data
    await _finalizeBasicQuestionnaire();
  }

  double? _parseHeightToCm() {
    final parsed = _parsePositiveNumber(_heightController.text);
    if (parsed == null) return null;
    return _heightUnit == 'cm' ? parsed : parsed * 2.54;
  }

  double? _parseWeightToKg() {
    final parsed = _parsePositiveNumber(_weightController.text);
    if (parsed == null) return null;
    return _weightUnit == 'kg' ? parsed : parsed * 0.45359237;
  }

  Future<void> _finalizeBasicQuestionnaire() async {
    // Save all profile data
    final heightCm = _parseHeightToCm();
    final weightKg = _parseWeightToKg();

    if (heightCm == null || weightKg == null) {
      return;
    }

    final result = HealthQuestionnaireResult(
      fullName: _nameController.text.trim(),
      dateOfBirth: _dob!,
      gender: _gender!,
      heightCm: heightCm,
      weightKg: weightKg,
      countryCode: _countryCode!,
      glucoseUnit: _glucoseUnit,
      conditions: _conditions.toList(),
      bmi: _bmi,
      baselineLifestyle: _initialLifestyle ?? {},
      baselineActivity: _initialActivity ?? {},
      baselineStress: _initialStress ?? {},
      baselineSleep: _initialSleep ?? {},
      baselineNutrition: _initialNutrition ?? {},
      baselinePsych: _initialPsych ?? {},
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSyncedAt: null,
      answers: _draftAnswers,
    );

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _handleContinueToLifestyle() async {
    // Validate section 3 before proceeding to next questionnaire
    FocusScope.of(context).unfocus();
    final selectionsValid = _conditions.isNotEmpty;

    if (!selectionsValid) {
      setState(() => _showSelectionErrors = true);
      return;
    }

    setState(() => _showSelectionErrors = false);

    // Now call the original _handleContinue logic
    await _handleContinue();
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    final selectionsValid = _conditions.isNotEmpty;

    if (!selectionsValid) {
      setState(() => _showSelectionErrors = true);
    }

    if (!formValid || !selectionsValid) {
      return;
    }
    if (_dob == null) {
      return;
    }
    if (_gender == null) {
      return;
    }
    if (_countryCode == null) {
      return;
    }
    setState(() => _showSelectionErrors = false);

    final flowResult = await Navigator.of(context).push<_LifestyleFlowResult>(
      _buildHealthQuestionnaireRoute(
        page: _LifestyleQuestionnairePage(
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

  Future<void> _persistProfileDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final heightValue = _parsePositiveNumber(_heightController.text);
    final weightValue = _parsePositiveNumber(_weightController.text);
    final heightCm = heightValue != null && _heightUnit == 'cm'
        ? heightValue
        : heightValue != null
            ? heightValue * 2.54
            : null;
    final weightKg = weightValue != null && _weightUnit == 'kg'
        ? weightValue
        : weightValue != null
            ? weightValue * 0.45359237
            : null;

    final updated = Map<String, dynamic>.from(_draftAnswers);

    // Save all profile fields that have been filled in
    if (_nameController.text.trim().isNotEmpty) {
      updated['fullName'] = _nameController.text.trim();
    }
    if (_dob != null) {
      updated['dateOfBirth'] = _dob!.toIso8601String();
    }
    if (_gender != null) {
      updated['gender'] = _gender;
    }
    if (heightCm != null) {
      updated['heightCm'] = heightCm;
    }
    if (weightKg != null) {
      updated['weightKg'] = weightKg;
    }
    if (_countryCode != null) {
      updated['countryCode'] = _countryCode;
    }
    if (_glucoseUnit.isNotEmpty) {
      updated['glucoseUnit'] = _glucoseUnit;
    }
    if (_conditions.isNotEmpty) {
      updated['conditions'] = _conditions.toList();
    }
    if (_bmi != null) {
      updated['bmi'] = _bmi;
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

    // Calculate age from date of birth
    final today = DateTime.now();
    final age = today.year -
        _dob!.year -
        (today.month > _dob!.month ||
                (today.month == _dob!.month && today.day >= _dob!.day)
            ? 0
            : 1);

    final answers = <String, dynamic>{
      'fullName': _nameController.text.trim(),
      'dateOfBirth': _dob!.toIso8601String(),
      'gender': _gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': bmi,
      'countryCode': _countryCode,
      'glucoseUnit': _glucoseUnit,
      'conditions': _conditions.toList(),
      'medications': _medications.map((m) => Map<String, dynamic>.from(m)).toList(),
      'completedAt': existingCompletedAt ?? nowIso,
      'updatedAt': nowIso,
      // Canonical keys from data dictionary
      'profile': {
        'age_years': age,
        'sex_at_birth': _gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'region': _countryCode,
        'comorbidities': _conditions.toList(),
      },
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
        'conditions': answers['conditions'],
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
      conditions: List<String>.from(answers['conditions'] as List),
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
    final oldCountryCode = _countryCode;
    final oldGlucoseUnit = _glucoseUnit;
    final region = _findRegion(code);
    _logInteraction(
      eventType: 'selection',
      field: 'countryCode',
      oldValue: oldCountryCode,
      newValue: code,
    );
    setState(() {
      _countryCode = code;
      if (region != null) {
        _glucoseUnit = region.glucoseUnit;
      }
    });
    // Log glucose unit change if it changed
    if (_glucoseUnit != oldGlucoseUnit) {
      _logInteraction(
        eventType: 'field_change',
        field: 'glucoseUnit',
        oldValue: oldGlucoseUnit,
        newValue: _glucoseUnit,
        metadata: {'triggeredBy': 'countrySelection'},
      );
    }
    _validateDropdownField(_FieldId.country, _countryFieldKey);
    _persistProfileDraft(); // Auto-save on country selection
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
    // Migrate old country codes to new ones
    final migratedCode = _migrateCountryCode(code);

    for (final region in _regionOptions) {
      if (region.code == migratedCode) {
        return region;
      }
    }
    return null;
  }

  static String _migrateCountryCode(String oldCode) {
    const migration = {
      'UK': 'GB',  // United Kingdom
      'EU': 'DE',  // European Union -> Germany as default
    };
    return migration[oldCode] ?? oldCode;
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
      // Legacy keys (for backward compatibility)
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
      // Canonical keys from data dictionary
      'canonical': {
        'wakeup_time_local': _formatTimeOfDay(wakeUpTime),
        'bedtime_local': _formatTimeOfDay(bedtime),
        'sleep_duration_h': sleepDurationHours,
        'sleep_quality_likert': sleepQuality,
        'work_pattern': workPattern,
        'breakfast_habit': breakfastHabit,
        'meals_per_day': mealsPerDay,
        'dinner_time_local': _formatTimeOfDay(dinnerTime),
        'caffeine_per_day': caffeineIntake,
        'alcohol_freq': alcoholConsumption,
        'smoker': smokingStatus == 'yes',
        'perceived_energy': energyLevel,
      },
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
  int? _sleepQuality;
  String? _workPattern;
  String? _breakfastHabit;
  int? _mealsPerDay;
  String? _caffeineIntake;
  String? _alcoholConsumption;
  String? _smokingStatus;
  String? _energyLevel;
  int _currentLifestyleSection = 0; // 0, 1, or 2 for the three sections
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
    final breakfast = data['breakfastHabit']?.toString();
    _breakfastHabit = breakfast != null ? _migrateBreakfastHabit(breakfast) : null;
    _caffeineIntake = data['caffeineIntake']?.toString();
    final alcohol = data['alcoholConsumption']?.toString();
    _alcoholConsumption = alcohol != null ? _migrateAlcoholFreq(alcohol) : null;
    _smokingStatus = data['smokingStatus']?.toString();
    _energyLevel = data['energyLevel']?.toString();
    _initialActivity = widget.initialActivityAnswers;
    _initialStress = widget.initialStressAnswers;
    _initialSleep = widget.initialSleepAnswers;
    _initialNutrition = widget.initialNutritionAnswers;
    _initialPsych = widget.initialPsychAnswers;
  }

  /// Logs lifestyle questionnaire interactions to SharedPreferences
  void _logLifestyleInteraction({
    required String eventType,
    required String field,
    dynamic oldValue,
    dynamic newValue,
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final key = 'health_questionnaire_interaction_log_$userId';
    final existingJson = prefs.getString(key);
    List<Map<String, dynamic>> log = [];

    if (existingJson != null && existingJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(existingJson);
        if (decoded is List) {
          log = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (e) {
        debugPrint('Error loading interaction log: $e');
      }
    }

    log.add({
      'timestamp': DateTime.now().toIso8601String(),
      'eventType': eventType,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'section': 'lifestyle',
      ...?metadata,
    });

    try {
      await prefs.setString(key, jsonEncode(log));
    } catch (e) {
      debugPrint('Error persisting interaction log: $e');
    }
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
        bottom: const _QuestionnaireProgressIndicator(
          currentStep: 3,
          totalSteps: 7,
          sectionName: 'Lifestyle',
        ),
      ),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Typical Day', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    "Let's talk about your typical day.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._buildCurrentLifestyleSection(theme),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  List<Widget> _buildCurrentLifestyleSection(ThemeData theme) {
    switch (_currentLifestyleSection) {
      case 0:
        return _buildLifestyleSection1(theme);
      case 1:
        return _buildLifestyleSection2(theme);
      case 2:
        return _buildLifestyleSection3(theme);
      default:
        return [];
    }
  }

  List<Widget> _buildLifestyleSection1(ThemeData theme) {
    return [
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
                        setState(() => _sleepQuality = value),
                    validator: (value) => value == null ? 'Please select sleep quality' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _goToLifestyleSection2,
                    child: const Text('Next'),
                  ),
    ];
  }

  List<Widget> _buildLifestyleSection2(ThemeData theme) {
    return [
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
                    onChanged: (value) {
                      final oldPattern = _workPattern;
                      setState(() => _workPattern = value);
                      _logLifestyleInteraction(
                        eventType: 'selection',
                        field: 'workPattern',
                        oldValue: oldPattern,
                        newValue: value,
                      );
                    },
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
                    onChanged: (value) {
                      final oldMeals = _mealsPerDay;
                      setState(() => _mealsPerDay = value);
                      _logLifestyleInteraction(
                        eventType: 'selection',
                        field: 'mealsPerDay',
                        oldValue: oldMeals,
                        newValue: value,
                      );
                    },
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
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _goToLifestyleSection3,
                    child: const Text('Next'),
                  ),
    ];
  }

  List<Widget> _buildLifestyleSection3(ThemeData theme) {
    return [
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
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: const Text('(Next) Physical Health'),
                  ),
    ];
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

  /// Migrates old breakfast habit values to canonical values
  String _migrateBreakfastHabit(String oldValue) {
    const migration = {
      'every_day': 'daily',
    };
    return migration[oldValue] ?? oldValue;
  }

  /// Migrates old alcohol frequency values to canonical values
  String _migrateAlcoholFreq(String oldValue) {
    const migration = {
      'occasionally': 'occasional',
      'several_week': 'several_per_week',
    };
    return migration[oldValue] ?? oldValue;
  }

  void _goToLifestyleSection2() {
    // Validate section 1 fields before proceeding
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      return;
    }
    if (_wakeUpTime == null || _bedtime == null || _sleepQuality == null) {
      return;
    }

    setState(() {
      _currentLifestyleSection = 1;
    });
  }

  void _goToLifestyleSection3() {
    // Validate section 2 fields before proceeding
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      return;
    }
    if (_workPattern == null || _breakfastHabit == null || _mealsPerDay == null || _dinnerTime == null) {
      return;
    }

    setState(() {
      _currentLifestyleSection = 2;
    });
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
      sleepQuality: _sleepQuality!,
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
      _buildHealthQuestionnaireRoute(
        page: _ActivityQuestionnairePage(
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

/// Physical Activity answers based on IPAQ-SF (International Physical Activity Questionnaire - Short Form)
/// Canonical keys: activity.vig_days_per_week, activity.vig_min_per_day, etc.
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

  final int vigorousDays; // activity.vig_days_per_week
  final double vigorousMinutes; // activity.vig_min_per_day
  final int moderateDays; // activity.mod_days_per_week
  final double moderateMinutes; // activity.mod_min_per_day
  final int walkingDays; // activity.walk_days_per_week
  final double walkingMinutes; // activity.walk_min_per_day
  final double sittingHours; // activity.sitting_hours_per_day

  /// Canonical: activity.met_minutes_week
  /// Formula: 8.0*vig_days*vig_min + 4.0*mod_days*mod_min + 3.3*walk_days*walk_min
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
      // Legacy keys (for backward compatibility)
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
      // Canonical keys from data dictionary (IPAQ-SF adapted)
      'canonical': {
        'vig_days_per_week': vigorousDays,
        'vig_min_per_day': vigorousMinutes,
        'mod_days_per_week': moderateDays,
        'mod_min_per_day': moderateMinutes,
        'walk_days_per_week': walkingDays,
        'walk_min_per_day': walkingMinutes,
        'sitting_hours_per_day': sittingHours,
        'met_minutes_week': metMinutesWeek,
      },
    };
  }
}

/// Perceived Stress Scale - 4 item version (PSS-4)
/// Canonical keys: stress.pss4_item1..4, stress.pss4_score
class _StressAnswers {
  const _StressAnswers({required this.responses});

  final List<int> responses; // 4 items, each 0-4 Likert scale

  /// PSS-4 score with reverse-coded items (items 2 and 3)
  /// Items 2 ("confident handling problems") and 3 ("things going your way") are positive
  /// and need to be reverse-coded: reversed = 4 - original
  /// Total score range: 0-16
  int get pss4Score {
    if (responses.length != 4) return 0;
    final item1 = responses[0]; // Felt unable to control (direct)
    final item2 = 4 - responses[1]; // Felt confident (REVERSE)
    final item3 = 4 - responses[2]; // Things going your way (REVERSE)
    final item4 = responses[3]; // Difficulties piling up (direct)
    return item1 + item2 + item3 + item4;
  }

  double get normalizedScore {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    return (total / (responses.length * 4)) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      // Legacy keys
      'items': responses,
      'index': normalizedScore,
      // Canonical keys from data dictionary (PSS-4)
      'canonical': {
        'pss4_item1': responses.isNotEmpty ? responses[0] : 0,
        'pss4_item2': responses.length > 1 ? responses[1] : 0,
        'pss4_item3': responses.length > 2 ? responses[2] : 0,
        'pss4_item4': responses.length > 3 ? responses[3] : 0,
        'pss4_score': pss4Score, // 0-16 with reverse-coded items
      },
    };
  }
}

/// Insomnia Severity Index - 7 item version (ISI-7)
/// Canonical keys: sleep.isi_item1..7, sleep.isi_score
class _SleepAnswers {
  const _SleepAnswers({required this.responses});

  final List<int> responses; // 7 items, each 0-4 Likert scale

  /// ISI-7 total score (sum of all 7 items)
  /// Score range: 0-28
  /// Interpretation: 0-7 = no insomnia, 8-14 = subthreshold, 15-21 = moderate, 22-28 = severe
  int get isiScore {
    if (responses.length != 7) return 0;
    return responses.fold<int>(0, (sum, value) => sum + value);
  }

  double get normalizedScore {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    final maxScore = responses.length * 4;
    if (maxScore == 0) return 0;
    final inverted = 1 - (total / maxScore);
    return inverted * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      // Legacy keys
      'items': responses,
      'index': normalizedScore,
      // Canonical keys from data dictionary (ISI-7)
      'canonical': {
        'isi_item1': responses.isNotEmpty ? responses[0] : 0,
        'isi_item2': responses.length > 1 ? responses[1] : 0,
        'isi_item3': responses.length > 2 ? responses[2] : 0,
        'isi_item4': responses.length > 3 ? responses[3] : 0,
        'isi_item5': responses.length > 4 ? responses[4] : 0,
        'isi_item6': responses.length > 5 ? responses[5] : 0,
        'isi_item7': responses.length > 6 ? responses[6] : 0,
        'isi_score': isiScore, // 0-28 total score
      },
    };
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
  int _currentActivitySection = 0; // 0 or 1 for the two sections
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
          bottom: const _QuestionnaireProgressIndicator(
            currentStep: 4,
            totalSteps: 7,
            sectionName: 'Activity & Movement',
          ),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Activity & Movement',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's capture your weekly activity.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._buildCurrentActivitySection(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCurrentActivitySection(ThemeData theme) {
    switch (_currentActivitySection) {
      case 0:
        return _buildActivitySection1(theme);
      case 1:
        return _buildActivitySection2(theme);
      default:
        return [];
    }
  }

  List<Widget> _buildActivitySection1(ThemeData theme) {
    return [
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
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _goToActivitySection2,
                      child: const Text('Next'),
                    ),
    ];
  }

  List<Widget> _buildActivitySection2(ThemeData theme) {
    return [
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
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('(Next) Stress & Sleep'),
                    ),
    ];
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
          if (parsed == null || parsed < 0) {
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

  void _goToActivitySection2() {
    // Validate section 1 fields before proceeding
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      return;
    }
    if (_vigorousDays == null || _moderateDays == null) {
      return;
    }

    setState(() {
      _currentActivitySection = 1;
    });
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
      _buildHealthQuestionnaireRoute(
        page: _StressSleepQuestionnairePage(
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

/// Nutrition assessment (REAP-S adapted with glycemic add-ons)
/// Canonical keys: nutrition.instrument, nutrition.raw_score, nutrition.sugary_drinks_per_week, etc.
class _NutritionAnswers {
  const _NutritionAnswers({required this.responses});

  final List<int> responses; // 7 items, each 0-4 scale

  /// Raw nutrition score (sum of all responses)
  /// Higher score = better nutrition habits
  int get rawScore {
    return responses.fold<int>(0, (sum, value) => sum + value);
  }

  double get index {
    final total = responses.fold<int>(0, (sum, value) => sum + value);
    return (total / (responses.length * 4)) * 100;
  }

  /// Glycemic-specific extractions from questionnaire items
  /// Item 0: Fruit and vegetable servings (0-4 scale, maps to servings)
  int get vegetablesServingsPerDay {
    if (responses.isEmpty) return 0;
    // Scale: 0=rarely, 1=1-2, 2=3-4, 3=5-6, 4=7+
    // Map to approximate servings: 0→0, 1→2, 2→4, 3→6, 4→8
    return responses[0] * 2;
  }

  /// Item 3: Sugary drinks per week (0-4 scale)
  int get sugaryDrinksPerWeek {
    if (responses.length < 4) return 0;
    // Scale: 0=never, 1=1-2, 2=3-4, 3=5-6, 4=7+
    // Map to approximate count: 0→0, 1→2, 2→4, 3→6, 4→8
    return responses[3] * 2;
  }

  /// Item 2: Frequency of fried/high-fat foods (inverse for refined carbs proxy)
  /// Lower score = better (less fried foods)
  String get refinedCarbsFrequency {
    if (responses.length < 3) return 'rarely';
    final score = responses[2];
    if (score == 0) return 'rarely';
    if (score == 1) return 'sometimes';
    if (score <= 2) return 'often';
    return 'daily';
  }

  Map<String, dynamic> toMap() {
    return {
      // Legacy keys
      'items': responses,
      'index': index,
      // Canonical keys from data dictionary (REAP-S + glycemic add-ons)
      'canonical': {
        'instrument': 'reap_s', // REAP-S adapted
        'raw_score': rawScore,
        // Glycemic add-ons
        'vegetables_servings_per_day': vegetablesServingsPerDay,
        'sugary_drinks_per_week': sugaryDrinksPerWeek,
        'refined_carbs_frequency': refinedCarbsFrequency,
      },
    };
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
  final List<int> _responses = List<int>.filled(5, -1);

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
          bottom: const _QuestionnaireProgressIndicator(
            currentStep: 5,
            totalSteps: 7,
            sectionName: 'Emotional Wellbeing',
          ),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Emotional wellbeing',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How have you felt about diabetes recently?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_responses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildQuestion(index, theme),
                      );
                    }),
                    const SizedBox(height: 12),
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

    // Validate all questions have been answered
    if (_responses.any((r) => r < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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

  /// Canonical: psych.instrument
  /// Determined by number of items: 5 items = PAID-5, 2 items = DDS-2
  String get instrument {
    if (responses.length == 2) return 'dds2';
    if (responses.length == 5) return 'paid5';
    return 'paid5'; // default
  }

  /// Canonical: psych.raw_score
  /// Sum of all responses (0-4 scale each)
  /// PAID-5: 0-20 (5 items × 4 max)
  /// DDS-2: 0-12 (2 items × 6 max for DDS-2, but we use 0-4 scale = 0-8)
  /// Note: Current implementation uses 5 items (PAID-5) with 0-4 scale = 0-20 range
  int get rawScore {
    return responses.fold<int>(0, (sum, value) => sum + value);
  }

  Map<String, dynamic> toMap() {
    return {
      // Legacy keys (for backward compatibility)
      'items': responses,
      'index': distressIndex,
      'supportNeeded': supportNeeded,

      // Canonical keys from data dictionary
      'canonical': {
        'instrument': instrument, // paid5|dds2
        'raw_score': rawScore, // 0-20 for PAID-5; 0-12 for DDS-2
        // Individual items for granular analysis
        'paid5_item1': responses.isNotEmpty ? responses[0] : 0,
        'paid5_item2': responses.length > 1 ? responses[1] : 0,
        'paid5_item3': responses.length > 2 ? responses[2] : 0,
        'paid5_item4': responses.length > 3 ? responses[3] : 0,
        'paid5_item5': responses.length > 4 ? responses[4] : 0,
      },
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
  final List<int> _responses = List<int>.filled(7, -1);
  int _currentNutritionSection = 0; // 0 or 1 for the two sections

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
        if (_currentNutritionSection == 1) {
          _goBackToNutritionSection1();
        } else {
          await _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _currentNutritionSection == 1
              ? BackButton(onPressed: _goBackToNutritionSection1)
              : BackButton(onPressed: () => _handleBack()),
          title: const Text('Health Profile'),
          bottom: const _QuestionnaireProgressIndicator(
            currentStep: 6,
            totalSteps: 7,
            sectionName: 'Nutrition Patterns',
          ),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nutrition patterns',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tell us about your usual food choices.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._buildCurrentNutritionSection(theme),
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

  List<Widget> _buildCurrentNutritionSection(ThemeData theme) {
    switch (_currentNutritionSection) {
      case 0:
        return _buildNutritionSection1(theme);
      case 1:
        return _buildNutritionSection2(theme);
      default:
        return [];
    }
  }

  List<Widget> _buildNutritionSection1(ThemeData theme) {
    return [
      // Questions 1-4
      ...List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNutritionQuestion(index, theme),
        );
      }),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _goToNutritionSection2,
        child: const Text('Next'),
      ),
    ];
  }

  List<Widget> _buildNutritionSection2(ThemeData theme) {
    return [
      // Questions 5-7
      ...List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNutritionQuestion(index + 4, theme),
        );
      }),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _handleSubmit,
        child: const Text('(Next) Emotional health'),
      ),
    ];
  }

  void _goToNutritionSection2() {
    // Validate all questions in section 1 have been answered (first 4 questions)
    if (_responses.take(4).any((r) => r < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _currentNutritionSection = 1;
    });
  }

  void _goBackToNutritionSection1() {
    setState(() {
      _currentNutritionSection = 0;
    });
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    // Validate all questions have been answered
    if (_responses.any((r) => r < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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

  final List<int> _stressResponses = List<int>.filled(4, -1);
  final List<int> _sleepResponses = List<int>.filled(7, -1);
  int _currentStressSleepSection = 0; // 0 or 1 for the two sections
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
          bottom: const _QuestionnaireProgressIndicator(
            currentStep: 7,
            totalSteps: 7,
            sectionName: 'Stress & Sleep',
          ),
        ),
        body: KeyboardDismissible(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Stress & Sleep',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share how stress and sleep feel over the past few weeks.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._buildCurrentStressSleepSection(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCurrentStressSleepSection(ThemeData theme) {
    switch (_currentStressSleepSection) {
      case 0:
        return _buildStressSleepSection1(theme);
      case 1:
        return _buildStressSleepSection2(theme);
      default:
        return [];
    }
  }

  List<Widget> _buildStressSleepSection1(ThemeData theme) {
    return [
                    Text(
                      'Perceived Stress (last month)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(_stressResponses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildStressQuestion(index),
                      );
                    }),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _goToStressSleepSection2,
                      child: const Text('Next'),
                    ),
    ];
  }

  List<Widget> _buildStressSleepSection2(ThemeData theme) {
    return [
                    const SizedBox(height: 12),
                    Text(
                      'Sleep quality (past 2 weeks)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(_sleepResponses.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSleepQuestion(index),
                      );
                    }),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('(Next) Nutritional Health'),
                    ),
    ];
  }

  void _goToStressSleepSection2() {
    // Validate all stress questions have been answered
    if (_stressResponses.any((r) => r < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all stress questions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _currentStressSleepSection = 1;
    });
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

    // Validate all sleep questions have been answered
    if (_sleepResponses.any((r) => r < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all sleep questions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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
          _buildHealthQuestionnaireRoute(
            page: _NutritionQuestionnairePage(
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
        _buildHealthQuestionnaireRoute(
          page: _PsychQuestionnairePage(
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
              _buildHealthQuestionnaireRoute(
                page: _NutritionQuestionnairePage(
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
