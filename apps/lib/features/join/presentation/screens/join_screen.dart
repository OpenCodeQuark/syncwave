import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/streaming_settings.dart';

class JoinScreen extends ConsumerWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(streamingSettingsControllerProvider).valueOrNull ??
        const StreamingSettings();
    final internetEnabled = settings.internetModeReady;

    return PrimaryScaffold(
      title: 'Join Session',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text(
            'Local rooms are the default. Scan or enter local room info to join over Wi-Fi/hotspot.',
          ),
          FilledButton.icon(
            onPressed: () => context.push(RoutePaths.joinScan),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Local QR'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.joinManual),
            icon: const Icon(Icons.keyboard),
            label: const Text('Manual Local Join'),
          ),
          if (internetEnabled)
            OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.joinManual),
              icon: const Icon(Icons.public),
              label: const Text('Join Internet Session'),
            ),
          const Spacer(),
          const Text(
            'iOS supports listener mode. Android supports listener and host modes.',
          ),
        ],
      ),
    );
  }
}
