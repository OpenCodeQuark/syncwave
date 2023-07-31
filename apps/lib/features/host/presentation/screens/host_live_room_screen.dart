import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';
import '../../../streaming/models/hosted_session.dart';
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
    final config = ref.watch(appConfigProvider);
    final session =
        hostedSession ??
        HostedSession(
          roomId: roomId,
          roomName: 'SyncWave Room',
          mode: StreamingMode.local,
          hostAddress: null,
          hostPort: 9000,
          roomPinProtected: false,
        );

    final coordinator = ref.read(streamingCoordinatorProvider);

    String? appQrPayload;
    String? browserQrPayload;
    try {
      appQrPayload = coordinator.buildAppQrPayload(
        session,
        appVersion: config.appVersion,
      );
      browserQrPayload = coordinator.buildBrowserQrPayload(session);
    } on FormatException {
      appQrPayload = null;
      browserQrPayload = null;
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
                  session.roomPinProtected
                      ? 'Room PIN protection: enabled'
                      : 'Room PIN protection: disabled',
                ),
                const SizedBox(height: 8),
                const Text(
                  'App QR (SyncWave app)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (appQrPayload != null)
                  QrImageView(
                    data: appQrPayload,
                    size: 180,
                    version: QrVersions.auto,
                  )
                else
                  const Text('Waiting for a valid local network endpoint...'),
                const Text(
                  'App QR uses structured JSON for SyncWave clients.',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: appQrPayload == null
                          ? null
                          : () async {
                              final payload = appQrPayload!;
                              await Clipboard.setData(
                                ClipboardData(text: payload),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('App QR payload copied'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Copy App QR Data'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Browser URL QR (future browser listener support)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (browserQrPayload != null)
                  QrImageView(
                    data: browserQrPayload,
                    size: 180,
                    version: QrVersions.auto,
                  ),
                const Text(
                  'Room PIN is not embedded in browser URL QR by default.',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: browserQrPayload == null
                          ? null
                          : () async {
                              final shareUri = browserQrPayload!;
                              await Clipboard.setData(
                                ClipboardData(text: shareUri),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Browser URL copied'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Browser URL'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Session status: Ready'),
                Text('Connected listeners: 0'),
                Text(
                  'Live audio capture and broadcasting are planned for v2.0.0.',
                ),
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
