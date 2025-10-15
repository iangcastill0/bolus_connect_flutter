import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/keyboard_dismissible.dart';

class BolusParametersPage extends StatefulWidget {
  const BolusParametersPage({super.key});

  @override
  State<BolusParametersPage> createState() => _BolusParametersPageState();
}

class _BolusParametersPageState extends State<BolusParametersPage> {
  final _formKey = GlobalKey<FormState>();

  final _icController = TextEditingController();
  final _targetController = TextEditingController();
  final _isfController = TextEditingController();

  final List<String> _cgmOptions = const ['None', 'Dexcom', 'Freestyle Libre'];
  String _selectedCgm = '';
  String _glucoseUnit = 'mg/dL'; // or 'mmol/L'
  bool _loading = true;

  // Range slider values (stored in mg/dL)
  double _rangeLowMgdl = 70.0;
  double _rangeHighMgdl = 180.0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _icController.dispose();
    _targetController.dispose();
    _isfController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final unit = prefs.getString('glucoseUnit') ?? 'mg/dL';
    final targetMgdl = _parseDouble(prefs.getString('targetGlucose'));
    final isfMgdl = _parseDouble(prefs.getString('isf'));

    // Load glucose range (defaults: 70-180 mg/dL)
    _rangeLowMgdl = _parseDouble(prefs.getString('glucoseRangeLow')) ?? 70.0;
    _rangeHighMgdl = _parseDouble(prefs.getString('glucoseRangeHigh')) ?? 180.0;

    setState(() {
      _selectedCgm = prefs.getString('cgmManufacturer') ?? '';
      _glucoseUnit = unit;
      _icController.text = prefs.getString('icRatio') ?? '';
      _targetController.text = targetMgdl == null
          ? ''
          : (unit == 'mmol/L'
              ? _formatMmol(_mgdlToMmol(targetMgdl))
              : _formatMgdl(targetMgdl));
      _isfController.text = isfMgdl == null
          ? ''
          : (unit == 'mmol/L'
              ? _formatMmol(_mgdlToMmol(isfMgdl))
              : _formatMgdl(isfMgdl));
      _loading = false;
    });
  }

  String? _validatePositive(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return '$field must be a positive number';
    return null;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    // Parse inputs in current unit
    final target = _parseDouble(_targetController.text);
    final isf = _parseDouble(_isfController.text);

    if (target == null || isf == null) {
      return; // safeguard; validators should prevent this
    }

    // Convert to canonical mg/dL for storage
    final targetMgdl = _glucoseUnit == 'mmol/L' ? _mmolToMgdl(target) : target;
    final isfMgdl = _glucoseUnit == 'mmol/L' ? _mmolToMgdl(isf) : isf;

    await prefs.setString('cgmManufacturer', _selectedCgm);
    await prefs.setString('icRatio', _icController.text.trim());
    await prefs.setString('glucoseUnit', _glucoseUnit);
    await prefs.setString('targetGlucose', _formatMgdl(targetMgdl));
    await prefs.setString('isf', _formatMgdl(isfMgdl));
    await prefs.setString('glucoseRangeLow', _formatMgdl(_rangeLowMgdl));
    await prefs.setString('glucoseRangeHigh', _formatMgdl(_rangeHighMgdl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bolus parameters saved')),
    );
    Navigator.of(context).maybePop();
  }

  // Helpers
  double? _parseDouble(String? v) {
    if (v == null) return null;
    final t = v.trim().replaceAll(',', '.');
    return double.tryParse(t);
  }

  double _mgdlToMmol(double mgdl) => mgdl / 18.0;
  double _mmolToMgdl(double mmol) => mmol * 18.0;
  String _formatMmol(double mmol) => mmol.toStringAsFixed(1);
  String _formatMgdl(double mgdl) => mgdl.toStringAsFixed(0);

  void _onUnitChanged(String? unit) {
    if (unit == null || unit == _glucoseUnit) return;
    // Convert currently entered values to the new unit for display
    final target = _parseDouble(_targetController.text);
    final isf = _parseDouble(_isfController.text);

    setState(() {
      if (unit == 'mmol/L') {
        if (target != null) {
          _targetController.text = _formatMmol(_mgdlToMmol(target));
        }
        if (isf != null) {
          _isfController.text = _formatMmol(_mgdlToMmol(isf));
        }
      } else {
        if (target != null) {
          _targetController.text = _formatMgdl(_mmolToMgdl(target));
        }
        if (isf != null) {
          _isfController.text = _formatMgdl(_mmolToMgdl(isf));
        }
      }
      _glucoseUnit = unit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bolus Parameters')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bolus Parameters')),
      body: KeyboardDismissible(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCgm,
                    items: _cgmOptions
                        .map((option) => DropdownMenuItem<String>(
                              value: option == 'None' ? '' : option,
                              child: Text(option),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCgm = v ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'CGM manufacturer',
                      prefixIcon: Icon(Icons.monitor_heart_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _glucoseUnit,
                    items: const [
                      DropdownMenuItem(value: 'mg/dL', child: Text('mg/dL')),
                      DropdownMenuItem(value: 'mmol/L', child: Text('mmol/L')),
                    ],
                    onChanged: _onUnitChanged,
                    decoration: const InputDecoration(
                      labelText: 'Glucose units',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _icController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    ],
                    decoration: const InputDecoration(
                      labelText: 'I:C ratio (g/U)',
                      hintText: 'e.g. 15',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    validator: (v) => _validatePositive(v, 'I:C ratio'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetController,
                    keyboardType: _glucoseUnit == 'mmol/L'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: _glucoseUnit == 'mmol/L'
                        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                        : [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Target glucose ($_glucoseUnit)',
                      hintText:
                          _glucoseUnit == 'mmol/L' ? 'e.g. 6.1' : 'e.g. 110',
                      prefixIcon: const Icon(Icons.bloodtype_outlined),
                    ),
                    validator: (v) => _validatePositive(v, 'Target glucose'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _isfController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'ISF ($_glucoseUnit per U)',
                      hintText:
                          _glucoseUnit == 'mmol/L' ? 'e.g. 2.8' : 'e.g. 50',
                      prefixIcon: const Icon(Icons.local_hospital_outlined),
                    ),
                    validator: (v) => _validatePositive(v, 'ISF'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Glucose Range',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define your target glucose range for tracking and insights.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _glucoseUnit == 'mmol/L'
                                ? _formatMmol(_mgdlToMmol(_rangeLowMgdl))
                                : _formatMgdl(_rangeLowMgdl),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            _glucoseUnit,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'High',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _glucoseUnit == 'mmol/L'
                                ? _formatMmol(_mgdlToMmol(_rangeHighMgdl))
                                : _formatMgdl(_rangeHighMgdl),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            _glucoseUnit,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: RangeValues(_rangeLowMgdl, _rangeHighMgdl),
                    min: 40.0,
                    max: 400.0,
                    divisions: 360,
                    labels: RangeLabels(
                      _glucoseUnit == 'mmol/L'
                          ? _formatMmol(_mgdlToMmol(_rangeLowMgdl))
                          : _formatMgdl(_rangeLowMgdl),
                      _glucoseUnit == 'mmol/L'
                          ? _formatMmol(_mgdlToMmol(_rangeHighMgdl))
                          : _formatMgdl(_rangeHighMgdl),
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _rangeLowMgdl = values.start;
                        _rangeHighMgdl = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag the handles to adjust your target range',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Values are stored on-device. You can update them anytime.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
