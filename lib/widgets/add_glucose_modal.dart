import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bolus_log_service.dart';
import '../widgets/keyboard_dismissible.dart';

class AddGlucoseModal extends StatefulWidget {
  const AddGlucoseModal({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<AddGlucoseModal> createState() => _AddGlucoseModalState();
}

class _AddGlucoseModalState extends State<AddGlucoseModal> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  String _glucoseUnit = 'mg/dL';
  String _notes = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glucoseUnit = prefs.getString('glucoseUnit') ?? 'mg/dL';
      _loading = false;
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays == 0 && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $period';
    } else if (difference.inDays == 1) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday at $hour:$minute $period';
    } else {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.month}/${dt.day}/${dt.year} $hour:$minute $period';
    }
  }

  String? _validateGlucose(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Glucose value is required';
    }
    final glucose = double.tryParse(value.trim().replaceAll(',', '.'));
    if (glucose == null || glucose <= 0) {
      return 'Please enter a valid glucose value';
    }
    if (_glucoseUnit == 'mg/dL' && (glucose < 20 || glucose > 600)) {
      return 'Value should be between 20-600 mg/dL';
    }
    if (_glucoseUnit == 'mmol/L' && (glucose < 1.1 || glucose > 33.3)) {
      return 'Value should be between 1.1-33.3 mmol/L';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final glucoseValue = double.parse(
      _glucoseController.text.trim().replaceAll(',', '.'),
    );

    final entry = BolusLogEntry(
      timestamp: _selectedDateTime,
      glucose: glucoseValue,
      glucoseUnit: _glucoseUnit,
      carbs: null,
      carbBolus: 0,
      correctionBolus: 0,
      trendAdjustment: 0,
      totalBolus: 0,
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
    );

    await BolusLogService.addEntry(entry);

    if (mounted) {
      widget.onSaved?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Glucose reading saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return KeyboardDismissible(
      child: Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bloodtype_outlined,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Glucose Reading',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // DateTime picker
                  InkWell(
                    onTap: () => _selectDateTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDateTime(_selectedDateTime),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Glucose input
                  TextFormField(
                    controller: _glucoseController,
                    autofocus: true,
                    keyboardType: _glucoseUnit == 'mmol/L'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: _glucoseUnit == 'mmol/L'
                        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                        : [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Glucose Value',
                      hintText: _glucoseUnit == 'mmol/L' ? 'e.g. 5.5' : 'e.g. 100',
                      suffixText: _glucoseUnit,
                      prefixIcon: const Icon(Icons.trending_up),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validateGlucose,
                  ),
                  const SizedBox(height: 20),
                  // Notes
                  TextFormField(
                    maxLines: 3,
                    onChanged: (value) => _notes = value,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add any relevant notes...',
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
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
}
