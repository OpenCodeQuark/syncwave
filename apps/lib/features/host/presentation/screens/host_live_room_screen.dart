import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';
import '../../../streaming/models/hosted_session.dart';
import '../../../streaming/models/room_join_target.dart';
import '../../../streaming/models/streaming_mode.dart';
import '../../../streaming/providers/streaming_providers.dart';

class HostLiveRoomScreen extends ConsumerWidget {
  const HostLiveRoomScreen({
    super.key,
    required this.roomId,
    this.hostedSession,
  });

  final String roomId;
  final HostedSession? hostedSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
        hostedSession ??
        HostedSession(
          roomId: roomId,
          roomName: 'SyncWave Room',
          mode: StreamingMode.local,
          hostAddress: null,
          hostPort: 9000,
          pinProtected: false,
        );

    final coordinator = ref.read(streamingCoordinatorProvider);
    final joinLinkService = ref.read(joinLinkServiceProvider);

    String? qrPayload;
    String? joinUri;
    try {
      qrPayload = coordinator.buildQrPayload(session);
      joinUri = joinLinkService.buildJoinUri(
        RoomJoinTarget(
          mode: session.mode,
          roomId: session.roomId,
          hostAddress: session.hostAddress,
          hostPort: session.hostPort,
          serverUrl: session.serverUrl,
          pin: session.pin,
          pinProtected: session.pinProtected,
        ),
      );
    } on FormatException {
      qrPayload = null;
      joinUri = null;
    }

    final endpointDescription = session.mode == StreamingMode.local
        ? '${session.hostAddress ?? 'unavailable'}:${session.hostPort}'
        : (session.serverUrl ?? 'Not configured');

    return PrimaryScaffold(
      title: 'Live Room',
      child: ListView(
        children: [
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text(
                  'Room Code',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  session.roomId,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Mode: ${session.mode.label}'),
                Text('Join endpoint: $endpointDescription'),
                Text(
                  session.pinProtected
                      ? 'PIN protection: enabled'
                      : 'PIN protection: disabled',
                ),
                const SizedBox(height: 8),
                if (qrPayload != null)
                  QrImageView(
                    data: qrPayload,
                    size: 180,
                    version: QrVersions.auto,
                  )
                else
                  const Text('Waiting for a valid local network endpoint...'),
                const Text(
                  'QR payload carries local join info by default. No external backend is required for Local Mode.',
                ),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: qrPayload == null
                          ? null
                          : () async {
                              final payload = qrPayload!;
                              await Clipboard.setData(
                                ClipboardData(text: payload),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('QR payload copied'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Copy QR Data'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: joinUri == null
                          ? null
                          : () async {
                              final shareUri = joinUri!;
                              await Clipboard.setData(
                                ClipboardData(text: shareUri),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Join link copied'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Join Link'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text('Capture status: Idle'),
                const Text('Latency mode: Balanced'),
                const Text('Connected listeners: 0'),
                if (session.mode == StreamingMode.local)
                  const Text('Local Session Server: active'),
                if (session.mode == StreamingMode.internet)
                  const Text('Remote Signaling: configured'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              await coordinator.stopLocalSession();
              if (!context.mounted) {
                return;
              }
              context.pop();
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Stop Broadcast'),
          ),
        ],
      ),
    );
  }
}
