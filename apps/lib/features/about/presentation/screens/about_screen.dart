import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static final Uri _creatorUrl = Uri.parse('https://rjrajujha.github.io');
  static final Uri _repoUrl = Uri.parse(
    'https://github.com/OpenCodeQuark/syncwave',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final config = ref.watch(appConfigProvider);

    return PrimaryScaffold(
      title: 'Info',
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  Color.alphaBlend(
                    colors.tertiary.withValues(alpha: 0.86),
                    colors.primary,
                  ),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SyncWave',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Local-first live audio for nearby listeners.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Essentials',
            child: Column(
              children: [
                _InfoTile(
                  icon: PhosphorIcons.wifiHigh(),
                  title: 'LAN first',
                  subtitle:
                      'Wi-Fi and hotspot rooms work without a cloud server.',
                ),
                _InfoTile(
                  icon: PhosphorIcons.globeHemisphereWest(),
                  title: 'Optional internet mode',
                  subtitle:
                      'Use your own SyncWave signaling server when needed.',
                ),
                _InfoTile(
                  icon: PhosphorIcons.shieldCheck(),
                  title: 'Private by design',
                  subtitle:
                      'Room PINs protect rooms; Server PINs protect host actions.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Links',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => _openUrl(_repoUrl),
                  icon: PhosphorIcon(PhosphorIcons.githubLogo()),
                  label: const Text('Source'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openUrl(_creatorUrl),
                  icon: PhosphorIcon(PhosphorIcons.userCircle()),
                  label: const Text('Creator'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '${config.appName} ${config.displayVersion}',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(icon, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
