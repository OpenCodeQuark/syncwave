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
import '../../../streaming/models/live_broadcast_status.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../../../streaming/providers/streaming_providers.dart';

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
    final liveStatus =
        ref.watch(liveBroadcastStatusProvider).valueOrNull ??
        ref.read(liveAudioBroadcastServiceProvider).status;
    final activeSession = ref
        .read(liveAudioBroadcastServiceProvider)
        .activeSession;

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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child:
                activeSession != null &&
                    liveStatus.phase != LiveBroadcastPhase.idle
                ? Padding(
                    key: const ValueKey('active-broadcast'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      title: 'Live Now',
                      subtitle: activeSession.roomName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          Row(
                            children: [
                              StatusBadge(
                                label:
                                    liveStatus.phase ==
                                        LiveBroadcastPhase.running
                                    ? 'Live'
                                    : liveStatus.phase.name,
                                tone:
                                    liveStatus.phase ==
                                        LiveBroadcastPhase.running
                                    ? StatusBadgeTone.success
                                    : StatusBadgeTone.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeSession.wanRoomId == null
                                      ? activeSession.roomId
                                      : '${activeSession.roomId} + ${activeSession.wanRoomId}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => context.push(
                                  RoutePaths.hostLivePath(activeSession.roomId),
                                  extra: activeSession,
                                ),
                                icon: PhosphorIcon(
                                  PhosphorIcons.arrowBendUpLeft(),
                                ),
                                label: const Text('Return'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final shouldStop =
                                      await _confirmStopBroadcast(context);
                                  if (!shouldStop) {
                                    return;
                                  }
                                  await ref
                                      .read(liveAudioBroadcastServiceProvider)
                                      .stop();
                                  await ref
                                      .read(streamingCoordinatorProvider)
                                      .stopLocalSession();
                                },
                                icon: PhosphorIcon(PhosphorIcons.stopCircle()),
                                label: const Text('Stop'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-active-broadcast')),
          ),
          SectionCard(
            title: 'Network',
            subtitle: 'Choose LAN, internet, or both when both are ready.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const StatusBadge(
                  label: 'LAN ready',
                  tone: StatusBadgeTone.info,
                ),
                StatusBadge(
                  label: internetBroadcastReady
                      ? 'Internet connected'
                      : 'Internet optional',
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
            title: 'Recent',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No recent rooms')),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmStopBroadcast(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop Broadcast?'),
          content: const Text(
            'Listeners will be disconnected and this room will close.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Stop Broadcast'),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}
