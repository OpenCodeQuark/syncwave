import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../settings/presentation/controllers/remote_server_connection_controller.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/internet_mode_gate.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_settings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(streamingSettingsControllerProvider).valueOrNull ??
        const StreamingSettings();
    final remoteStatus =
        ref.watch(remoteServerConnectionControllerProvider).valueOrNull ??
        const RemoteServerStatus();
    final internetBroadcastReady = isInternetBroadcastAvailable(
      settings,
      remoteStatus,
    );

    return PrimaryScaffold(
      title: 'SyncWave',
      actions: [
        IconButton(
          onPressed: () => context.push(RoutePaths.about),
          icon: PhosphorIcon(PhosphorIcons.info()),
          tooltip: 'About',
        ),
        IconButton(
          onPressed: () => context.push(RoutePaths.settings),
          icon: PhosphorIcon(PhosphorIcons.gear()),
          tooltip: 'Settings',
        ),
      ],
      child: ListView(
        children: [
          SectionCard(
            title: 'Local-First Ready',
            subtitle:
                'Host and listeners can run on the same Wi-Fi or hotspot without an external server.',
            child: Row(
              children: [
                StatusBadge(
                  label: internetBroadcastReady
                      ? 'Internet signaling connected'
                      : 'Local network mode',
                  tone: internetBroadcastReady
                      ? StatusBadgeTone.success
                      : StatusBadgeTone.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Start',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.hostCreate),
                  icon: PhosphorIcon(PhosphorIcons.broadcast()),
                  label: const Text('Start Broadcast'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(RoutePaths.join),
                  icon: PhosphorIcon(PhosphorIcons.headphones()),
                  label: const Text('Join Session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Recent Rooms',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No recent rooms yet')),
            ),
          ),
        ],
      ),
    );
  }
}
