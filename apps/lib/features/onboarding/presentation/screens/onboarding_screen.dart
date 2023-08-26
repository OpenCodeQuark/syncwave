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
                    spacing: 12,
                    children: [
                      Text(
                        'Local-first synchronized listening.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Local streaming works over Wi-Fi or hotspot without internet or external server.',
                      ),
                      Text(
                        'Android can host local broadcast. iOS is listener-first due platform system audio restrictions.',
                      ),
                      Text(
                        'Internet streaming is optional and must be configured manually in Settings.',
                      ),
                      Text(
                        'Host and listeners should be on the same Wi-Fi/hotspot in Local Mode.',
                      ),
                      Text(
                        'v1.0.0 includes live Android host broadcasting with local-first networking.',
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
                        'Permissions and upcoming capture modes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Notification permission is requested when starting host broadcast for foreground service status.',
                      ),
                      Text(
                        'System audio and optional microphone capture are available on supported Android hosts.',
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
