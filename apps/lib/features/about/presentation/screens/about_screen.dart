import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final Uri _creatorUrl = Uri.parse('https://rjrajujha.github.io');
  static final Uri _repoUrl = Uri.parse(
    'https://github.com/rjrajujha/syncwave',
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PrimaryScaffold(
      title: 'About SyncWave',
      child: ListView(
        children: [
          const SectionCard(
            title: 'SyncWave',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'Local-first live audio broadcasting for nearby listeners.',
                ),
                Text(
                  'v1.0.0 supports Android host broadcasting and listener joins using QR, deep links, and browser listener routes.',
                ),
                Text('Internet signaling is optional and disabled by default.'),
                Text(
                  'Android is broadcaster-first. iOS is listener-first in v1.0.0.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'What\'s Next',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'Advanced media transport optimization and adaptive bitrate',
                ),
                Text('Richer sync correction and drift handling'),
                Text('Improved microphone mixing and controls'),
                Text('Expanded desktop host tooling'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Credits',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text('Made with', style: textTheme.bodyMedium),
                    const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Color(0xFFE11D48),
                    ),
                    InkWell(
                      onTap: () => _openUrl(_creatorUrl),
                      child: Text(
                        'by R. Jha',
                        style: textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: () => _openUrl(_repoUrl),
                  icon: PhosphorIcon(PhosphorIcons.githubLogo()),
                  tooltip: 'Source code on GitHub',
                ),
              ],
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
