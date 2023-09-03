import 'package:flutter/material.dart';

enum StatusBadgeTone { neutral, success, warning, danger, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusBadgeTone.neutral,
  });

  final String label;
  final StatusBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = switch (tone) {
      StatusBadgeTone.success => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      StatusBadgeTone.warning => (
        const Color(0xFFFFF4CE),
        const Color(0xFF5C3B00),
      ),
      StatusBadgeTone.danger => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      StatusBadgeTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      StatusBadgeTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.$2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
