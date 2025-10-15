import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bolus_log_service.dart';
import '../widgets/keyboard_dismissible.dart';

class LogMealModal extends StatefulWidget {
  const LogMealModal({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<LogMealModal> createState() => _LogMealModalState();
}

class _LogMealModalState extends State<LogMealModal> {
  final _formKey = GlobalKey<FormState>();
  final _carbsController = TextEditingController();
  final _mealNameController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  String _mealType = 'Breakfast';
  String _notes = '';

  final List<String> _mealTypes = const [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Other',
  ];

  @override
  void dispose() {
    _carbsController.dispose();
    _mealNameController.dispose();
    super.dispose();
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

  String? _validateCarbs(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Carbs value is required';
    }
    final carbs = double.tryParse(value.trim().replaceAll(',', '.'));
    if (carbs == null || carbs < 0) {
      return 'Please enter a valid carbs value';
    }
    if (carbs > 500) {
      return 'Carbs seem too high (max 500g)';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final carbsValue = double.parse(
      _carbsController.text.trim().replaceAll(',', '.'),
    );

    final prefs = await SharedPreferences.getInstance();
    final glucoseUnit = prefs.getString('glucoseUnit') ?? 'mg/dL';

    final mealName = _mealNameController.text.trim();
    final fullNotes = [
      'Meal: $_mealType',
      if (mealName.isNotEmpty) 'Name: $mealName',
      if (_notes.trim().isNotEmpty) _notes.trim(),
    ].join('\n');

    final entry = BolusLogEntry(
      timestamp: _selectedDateTime,
      glucose: null,
      glucoseUnit: glucoseUnit,
      carbs: carbsValue,
      carbBolus: 0,
      correctionBolus: 0,
      trendAdjustment: 0,
      totalBolus: 0,
      notes: fullNotes,
    );

    await BolusLogService.addEntry(entry);

    if (mounted) {
      widget.onSaved?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        Icons.restaurant,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Log Meal',
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
                  // Meal type dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _mealType,
                    decoration: InputDecoration(
                      labelText: 'Meal Type',
                      prefixIcon: const Icon(Icons.fastfood),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _mealTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _mealType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Meal name (optional)
                  TextFormField(
                    controller: _mealNameController,
                    decoration: InputDecoration(
                      labelText: 'Meal Name (optional)',
                      hintText: 'e.g. Spaghetti, Chicken Salad',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Carbs input
                  TextFormField(
                    controller: _carbsController,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Carbohydrates (g)',
                      hintText: 'e.g. 45',
                      suffixText: 'g',
                      prefixIcon: const Icon(Icons.scale_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validateCarbs,
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
