import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/streaming_settings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(streamingSettingsControllerProvider).valueOrNull ??
        const StreamingSettings();

    return PrimaryScaffold(
      title: 'SyncWave',
      actions: [
        IconButton(
          onPressed: () => context.push(RoutePaths.settings),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            settings.internetModeReady
                ? 'Mode: Local-first (Internet optional ready)'
                : 'Mode: Local-first (No external server required)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          FilledButton.icon(
            onPressed: () => context.push(RoutePaths.hostCreate),
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Start Broadcast'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.join),
            icon: const Icon(Icons.headphones),
            label: const Text('Join Session'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.debugNetwork),
            icon: const Icon(Icons.bug_report),
            label: const Text('Open Debug Screen'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Rooms',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Expanded(child: Center(child: Text('No recent rooms yet'))),
        ],
      ),
    );
  }
}
