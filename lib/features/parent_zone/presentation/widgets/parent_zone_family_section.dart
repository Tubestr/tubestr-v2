import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';

class ParentZoneFamilySection extends ConsumerWidget {
  const ParentZoneFamilySection({
    super.key,
    required this.nameController,
    required this.childTheme,
    required this.onThemeSelected,
    required this.onSaveChild,
    required this.onDeleteChild,
  });

  final TextEditingController nameController;
  final ThemeDescriptor childTheme;
  final ValueChanged<ThemeDescriptor> onThemeSelected;
  final VoidCallback onSaveChild;
  final ValueChanged<String> onDeleteChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent Identity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                identity?.npub ?? 'No parent identity',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Children', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final profile in profiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeDescriptorX.fromStorage(
                        profile.theme,
                      ).palette.accent,
                    ),
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    ThemeDescriptorX.fromStorage(profile.theme).label,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => onDeleteChild(profile.id),
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Add Child', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Child name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final descriptor in ThemeDescriptor.values)
                    ChoiceChip(
                      label: Text(descriptor.label),
                      selected: descriptor == childTheme,
                      onSelected: (_) => onThemeSelected(descriptor),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onSaveChild,
                child: const Text('Save child'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
