import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Training module — Home / Dashboard tab.
///
/// Placeholder for the training dashboard (weekly summary, last workout, etc.)
class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        'Training Home',
        style: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
