import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bolus_log_service.dart';
import '../widgets/keyboard_dismissible.dart';

class AddMoodModal extends StatefulWidget {
  const AddMoodModal({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<AddMoodModal> createState() => _AddMoodModalState();
}

class _AddMoodModalState extends State<AddMoodModal> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDateTime = DateTime.now();
  String _mood = 'Neutral';
  double _stressLevel = 3.0;
  String _notes = '';

  final List<Map<String, dynamic>> _moodOptions = const [
    {'label': 'Very Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
    {'label': 'Happy', 'icon': Icons.sentiment_satisfied_alt, 'color': Colors.lightGreen},
    {'label': 'Neutral', 'icon': Icons.sentiment_neutral, 'color': Colors.grey},
    {'label': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.orange},
    {'label': 'Very Sad', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
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

  String _getStressLabel(double level) {
    if (level <= 2) return 'Low stress';
    if (level <= 4) return 'Moderate stress';
    return 'High stress';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final glucoseUnit = prefs.getString('glucoseUnit') ?? 'mg/dL';

    final fullNotes = [
      'Mood: $_mood',
      'Stress Level: ${_stressLevel.toInt()}/5 (${_getStressLabel(_stressLevel)})',
      if (_notes.trim().isNotEmpty) _notes.trim(),
    ].join('\n');

    // Create canonical mood log structure
    final moodLog = MoodLog(
      ts: _selectedDateTime,
      stress: _stressLevel.toInt(),
      note: _notes.trim().isNotEmpty ? _notes.trim() : null,
    );

    final entry = BolusLogEntry(
      timestamp: _selectedDateTime,
      glucose: null,
      glucoseUnit: glucoseUnit,
      carbs: null,
      carbBolus: 0,
      correctionBolus: 0,
      trendAdjustment: 0,
      totalBolus: 0,
      notes: fullNotes,
      moodLog: moodLog, // Canonical structure
    );

    await BolusLogService.addEntry(entry);

    if (mounted) {
      widget.onSaved?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood/Stress logged')),
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
                        Icons.mood,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Mood/Stress',
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
                  const SizedBox(height: 24),
                  // Mood selection
                  Text(
                    'How are you feeling?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moodOptions.map((option) {
                      final isSelected = _mood == option['label'];
                      return FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option['icon'] as IconData,
                              size: 18,
                              color: isSelected
                                  ? theme.colorScheme.onSecondaryContainer
                                  : option['color'] as Color,
                            ),
                            const SizedBox(width: 6),
                            Text(option['label'] as String),
                          ],
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _mood = option['label'] as String);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Stress level slider
                  Text(
                    'Stress Level: ${_stressLevel.toInt()}/5',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Low',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _stressLevel,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _stressLevel.toInt().toString(),
                          onChanged: (value) {
                            setState(() => _stressLevel = value);
                          },
                        ),
                      ),
                      Text(
                        'High',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Notes
                  TextFormField(
                    maxLines: 3,
                    onChanged: (value) => _notes = value,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'What contributed to this feeling?',
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
