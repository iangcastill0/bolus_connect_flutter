import 'package:flutter/material.dart';

import '../widgets/selectable_body_diagram.dart';

class PainAreaQuestionnairePage extends StatefulWidget {
  const PainAreaQuestionnairePage({super.key});

  @override
  State<PainAreaQuestionnairePage> createState() => _PainAreaQuestionnairePageState();
}

class _PainAreaQuestionnairePageState extends State<PainAreaQuestionnairePage> {
  final Set<String> _selectedRegions = <String>{};

  late final Map<String, BodyRegion> _regionLookup = {
    for (final region in selectableBodyRegions) region.id: region,
  };

  void _handleToggle(String regionId) {
    setState(() {
      if (_selectedRegions.contains(regionId)) {
        _selectedRegions.remove(regionId);
      } else {
        _selectedRegions.add(regionId);
      }
    });
  }

  void _handleSubmit() {
    if (_selectedRegions.isEmpty) return;
    final count = _selectedRegions.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved $count pain area${count == 1 ? '' : 's'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRegions = _selectedRegions.toList()
      ..sort((a, b) {
        final labelA = _regionLookup[a]?.label ?? a;
        final labelB = _regionLookup[b]?.label ?? b;
        return labelA.compareTo(labelB);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Pain Area Questionnaire')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final diagrams = [
            _DiagramCard(
              title: 'Front view',
              child: SelectableBodyDiagram(
                view: BodyView.front,
                selectedRegions: _selectedRegions,
                onRegionToggle: _handleToggle,
              ),
            ),
            _DiagramCard(
              title: 'Back view',
              child: SelectableBodyDiagram(
                view: BodyView.back,
                selectedRegions: _selectedRegions,
                onRegionToggle: _handleToggle,
              ),
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tap any highlighted muscle group to mark the area where the patient is experiencing pain. '
                  'Tap again to unselect it.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: diagrams
                        .map((card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: card,
                              ),
                            ))
                        .toList(),
                  )
                else
                  Column(
                    children: diagrams
                        .map((card) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: card,
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 24),
                Text('Selected areas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (selectedRegions.isEmpty)
                  Text(
                    'No areas selected yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedRegions
                        .map((id) => InputChip(
                              label: Text(_regionLookup[id]?.label ?? id),
                              onDeleted: () => _handleToggle(id),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: selectedRegions.isEmpty ? null : _handleSubmit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save responses'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiagramCard extends StatelessWidget {
  const _DiagramCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
