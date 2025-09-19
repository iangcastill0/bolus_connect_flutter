import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nutritional_lookup_page.dart';

class BolusPage extends StatefulWidget {
  final ValueListenable<int>? refreshTick;
  const BolusPage({super.key, this.refreshTick});

  @override
  State<BolusPage> createState() => _BolusPageState();
}

class _BolusPageState extends State<BolusPage> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseController = TextEditingController();
  final _carbsController = TextEditingController();
  final _notesController = TextEditingController();

  String _glucoseUnit = 'mg/dL';
  bool _loading = true;
  bool _paramsAvailable = false;
  String? _cgmManufacturer; // 'Dexcom' | 'Freestyle Libre'
  String? _selectedTrend; // arrow token
  final Map<String, double> _trendOverrides = {};

  // Stored parameters
  double? _icRatio; // grams per unit
  double? _targetMgdl; // canonical mg/dL
  double? _isfMgdl; // mg/dL per unit

  // Result state
  double? _carbBolus;
  double? _corrBolus;
  double? _totalBolus;
  double? _corrTrendComponent;

  void _reset() {
    FocusScope.of(context).unfocus();
    setState(() {
      _carbBolus = null;
      _corrBolus = null;
      _totalBolus = null;
      _glucoseController.clear();
      _carbsController.clear();
      _notesController.clear();
      _selectedTrend = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    widget.refreshTick?.addListener(_loadPrefs);
  }

  @override
  void dispose() {
    widget.refreshTick?.removeListener(_loadPrefs);
    _glucoseController.dispose();
    _carbsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BolusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      oldWidget.refreshTick?.removeListener(_loadPrefs);
      widget.refreshTick?.addListener(_loadPrefs);
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    double? parseNum(String? s) => s == null ? null : double.tryParse(s.trim().replaceAll(',', '.'));
    final ic = parseNum(prefs.getString('icRatio'));
    final target = parseNum(prefs.getString('targetGlucose'));
    final isf = parseNum(prefs.getString('isf'));
    setState(() {
      _glucoseUnit = prefs.getString('glucoseUnit') ?? 'mg/dL';
      _cgmManufacturer = prefs.getString('cgmManufacturer');
      _icRatio = ic;
      _targetMgdl = target;
      _isfMgdl = isf;
      _paramsAvailable = ic != null && ic > 0 && target != null && target > 0 && isf != null && isf > 0;
      _loading = false;
    });
    // Load trend overrides (use defaults if absent)
    _trendOverrides['↑↑'] = prefs.getDouble(_trendPrefKey('↑↑')) ?? _defaultTrendUnits('↑↑');
    _trendOverrides['↑'] = prefs.getDouble(_trendPrefKey('↑')) ?? _defaultTrendUnits('↑');
    _trendOverrides['↗'] = prefs.getDouble(_trendPrefKey('↗')) ?? _defaultTrendUnits('↗');
    _trendOverrides['→'] = prefs.getDouble(_trendPrefKey('→')) ?? _defaultTrendUnits('→');
    _trendOverrides['↘'] = prefs.getDouble(_trendPrefKey('↘')) ?? _defaultTrendUnits('↘');
    _trendOverrides['↓'] = prefs.getDouble(_trendPrefKey('↓')) ?? _defaultTrendUnits('↓');
    _trendOverrides['↓↓'] = prefs.getDouble(_trendPrefKey('↓↓')) ?? _defaultTrendUnits('↓↓');
  }

  String? _validateOptionalPositive(String? v, String field) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return '$field must be a positive number';
    return null;
  }

  void _calculate() {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    double? parseNum(String? s) => s == null ? null : double.tryParse(s.trim().replaceAll(',', '.'));
    final carbs = parseNum(_carbsController.text);
    final gInput = parseNum(_glucoseController.text);

    if (carbs == null && gInput == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter glucose or carbohydrates to calculate.')),
      );
      return;
    }

    double carbBolus = 0.0;
    double corrBolus = 0.0; // display-only: base correction without trend
    double corrTrendComponent = 0.0;

    // Carb bolus (requires I:C ratio)
    if (carbs != null) {
      final ic = _icRatio;
      if (ic == null || ic <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set your I:C ratio in Bolus parameters.')),
        );
        return;
      }
      carbBolus = carbs / ic;
    }

    // Correction bolus (requires glucose, target, ISF)
    if (gInput != null) {
      final currentMgdl = _glucoseUnit == 'mmol/L' ? gInput * 18.0 : gInput;
      final target = _targetMgdl;
      final isf = _isfMgdl;
      if (target == null || target <= 0 || isf == null || isf <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set your Target and ISF in Bolus parameters.')),
        );
        return;
      }
      const toleranceMgdl = 1.0; // treat near-equal as equal due to rounding
      final deltaNo = currentMgdl - target;
      final corrNoTrend = (deltaNo.abs() <= toleranceMgdl) ? 0.0 : (deltaNo / isf);
      final trendAdjUnits = _trendCorrectionUnits(_cgmManufacturer, _selectedTrend);
      corrTrendComponent = trendAdjUnits;
      corrBolus = corrNoTrend; // do not include trend in displayed correction
    }

    double total = carbBolus + corrBolus + corrTrendComponent; // include trend only in total
    if (total < 0) total = 0; // clamp for safety

    double roundTo(double value, double step) => (value / step).round() * step;
    final roundedTotal = roundTo(total, 0.1);

    setState(() {
      _carbBolus = carbBolus;
      _corrBolus = corrBolus;
      _totalBolus = roundedTotal;
      _corrTrendComponent = corrTrendComponent;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bolus calculated')),
    );
  }

  // Trend units helpers
  String _trendPrefKey(String trend) {
    switch (trend) {
      case '↑↑':
        return 'trendUnits_up2';
      case '↑':
        return 'trendUnits_up';
      case '↗':
        return 'trendUnits_upright';
      case '→':
        return 'trendUnits_right';
      case '↘':
        return 'trendUnits_downright';
      case '↓':
        return 'trendUnits_down';
      case '↓↓':
        return 'trendUnits_down2';
      default:
        return 'trendUnits_other';
    }
  }

  double _defaultTrendUnits(String trend) {
    switch (trend) {
      case '↑↑':
      case '↑':
        return 1.0;
      case '↗':
        return 0.5;
      case '→':
        return 0.0;
      case '↘':
        return -0.5;
      case '↓':
      case '↓↓':
        return -1.0;
      default:
        return 0.0;
    }
  }

  double _trendCorrectionUnits(String? cgm, String? trend) {
    if (trend == null) return 0.0;
    return _trendOverrides[trend] ?? _defaultTrendUnits(trend);
  }

  void _showTrendInfoDialog() {
    final tokens = _trendChoices; // show relevant tokens for selected CGM
    final controllers = <String, TextEditingController>{};
    for (final t in tokens) {
      controllers[t] = TextEditingController(
        text: (_trendOverrides[t] ?? _defaultTrendUnits(t)).toStringAsFixed(2),
      );
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Trend Arrow Adjustments'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit the units added to correction for each arrow:'),
                const SizedBox(height: 12),
                ...tokens.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Text(t, style: const TextStyle(fontSize: 16))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: controllers[t],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-.,]'))],
                              decoration: const InputDecoration(suffixText: 'U', hintText: 'e.g. 0.50'),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Reset to defaults
                final navigator = Navigator.of(context);
                final prefs = await SharedPreferences.getInstance();
                for (final t in tokens) {
                  _trendOverrides[t] = _defaultTrendUnits(t);
                  await prefs.setDouble(_trendPrefKey(t), _trendOverrides[t]!);
                }
                if (!mounted || !navigator.mounted) return;
                setState(() {});
                navigator.pop();
              },
              child: const Text('Reset Defaults'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final prefs = await SharedPreferences.getInstance();
                for (final t in tokens) {
                  final raw = controllers[t]?.text.trim().replaceAll(',', '.');
                  final v = double.tryParse(raw ?? '');
                  if (v != null) {
                    _trendOverrides[t] = v;
                    await prefs.setDouble(_trendPrefKey(t), v);
                  }
                }
                if (!mounted || !navigator.mounted) return;
                setState(() {});
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _trendChoices {
    if (_cgmManufacturer == 'Dexcom') {
      return const ['↑↑', '↑', '↗', '→', '↘', '↓', '↓↓'];
    }
    if (_cgmManufacturer == 'Freestyle Libre') {
      return const ['↑', '↗', '→', '↘', '↓'];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bolus')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final isMmol = _glucoseUnit == 'mmol/L';
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_paramsAvailable) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                    title: Text(
                      'Set your Bolus parameters (I:C, Target, ISF) for accurate calculations.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    trailing: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/settings/bolus-parameters')
                          .then((_) => _loadPrefs()),
                      child: const Text('Open'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _glucoseController,
                keyboardType: isMmol
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                inputFormatters: isMmol
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                    : [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Glucose level ($_glucoseUnit)',
                  hintText: isMmol ? 'e.g. 6.1' : 'e.g. 140',
                  prefixIcon: const Icon(Icons.bloodtype_outlined),
                ),
                validator: (v) => _validateOptionalPositive(v, 'Glucose level'),
              ),
              if (_trendChoices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Trend', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'How trend arrows affect dose',
                      onPressed: _showTrendInfoDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _trendChoices.map((t) {
                    final selected = _selectedTrend == t;
                    return ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 16)),
                      selected: selected,
                      onSelected: (v) => setState(() => _selectedTrend = v ? t : null),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _carbsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates (g)',
                  hintText: 'e.g. 45',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                validator: (v) => _validateOptionalPositive(v, 'Carbohydrates'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add meal details, activity, etc.',
                  isDense: true,
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NutritionalLookupPage()),
                    );
                  },
                  child: const Text('Nutritional Lookup'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Calculate'),
                ),
              ),
              if (_totalBolus != null) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Result', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Carb bolus'),
                            Text('${_carbBolus!.toStringAsFixed(2)} U'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Correction bolus'),
                            Text('${_corrBolus!.toStringAsFixed(2)} U'),
                          ],
                        ),
                        if (_selectedTrend != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Trend correction (${_selectedTrend!})'),
                              Text('${(_corrTrendComponent ?? 0).toStringAsFixed(2)} U'),
                            ],
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recommended total', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('${_totalBolus!.toStringAsFixed(1)} U', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rounded to 0.1 U. Educational use only—confirm with your provider.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bolus')),
      body: Stack(
        children: [
          content,
          if (_totalBolus != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _reset,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}
