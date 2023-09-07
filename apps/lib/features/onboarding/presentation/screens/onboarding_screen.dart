import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      title: 'Welcome to SyncWave',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const SyncWaveCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        'Local-first synchronized listening',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Local streaming works over Wi-Fi or hotspot without any external server.',
                      ),
                      Text(
                        'Android hosts broadcasts. iOS is listener-first in v1.1.0.',
                      ),
                      Text(
                        'Optional internet signaling can be configured in Settings when needed.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const SyncWaveCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        'Permissions',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Notification permission is requested when hosting so foreground broadcast status remains visible.',
                      ),
                      Text(
                        'Android requires a screen-share style prompt for system audio capture.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go(RoutePaths.home),
            icon: PhosphorIcon(PhosphorIcons.arrowRight()),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
