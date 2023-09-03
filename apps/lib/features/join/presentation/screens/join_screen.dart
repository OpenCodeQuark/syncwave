import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../settings/presentation/controllers/remote_server_connection_controller.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/internet_mode_gate.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_settings.dart';

class JoinScreen extends ConsumerWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(streamingSettingsControllerProvider).valueOrNull ??
        const StreamingSettings();
    final remoteStatus =
        ref.watch(remoteServerConnectionControllerProvider).valueOrNull ??
        const RemoteServerStatus();
    final internetEnabled = isInternetBroadcastAvailable(
      settings,
      remoteStatus,
    );

    return PrimaryScaffold(
      title: 'Join Session',
      child: ListView(
        children: [
          const SectionCard(
            title: 'Local Join',
            subtitle:
                'Local rooms are the default. Use the same Wi-Fi or hotspot as the host.',
            child: SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Join Methods',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.joinScan),
                  icon: PhosphorIcon(PhosphorIcons.scan()),
                  label: const Text('Scan QR'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(RoutePaths.joinManual),
                  icon: PhosphorIcon(PhosphorIcons.keyboard()),
                  label: const Text('Manual Join'),
                ),
                if (internetEnabled)
                  OutlinedButton.icon(
                    onPressed: () => context.push(RoutePaths.joinManual),
                    icon: PhosphorIcon(PhosphorIcons.globe()),
                    label: const Text('Join Internet Session'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Platform Note',
            child: Text(
              'iOS supports listener mode. Android supports listener and host modes.',
            ),
          ),
        ],
      ),
    );
  }
}
