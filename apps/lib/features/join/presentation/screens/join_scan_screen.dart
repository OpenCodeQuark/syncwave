import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../../../streaming/providers/streaming_providers.dart';

class JoinScanScreen extends ConsumerWidget {
  const JoinScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinLinkService = ref.read(joinLinkServiceProvider);
    final settings =
        ref.watch(streamingSettingsControllerProvider).valueOrNull ??
        const StreamingSettings();
    final internetEnabled = settings.internetModeReady;

    return PrimaryScaffold(
      title: 'Scan QR',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          const Icon(Icons.qr_code_scanner, size: 96),
          const Text(
            'QR scanning is local-first. Internet QR joins are optional and disabled by default.',
            textAlign: TextAlign.center,
          ),
          FilledButton(
            onPressed: () {
              final localPayload = joinLinkService.localQrPayloadTemplate(
                roomId: 'SW-8FD2-KQ',
                hostAddress: '192.168.1.20',
                hostPort: 9000,
                pinProtected: true,
                pin: '123456',
              );

              final target = joinLinkService.parseQrPayload(
                jsonEncode(localPayload.toJson()),
              );

              context.push('/room/${target.roomId}');
            },
            child: const Text('Simulate Local QR Join'),
          ),
          if (internetEnabled)
            OutlinedButton(
              onPressed: () {
                final internetPayload = joinLinkService
                    .internetQrPayloadTemplate(
                      roomId: 'SW-REMOTE',
                      serverUrl:
                          settings.signalingServerUrl ?? 'wss://example.com/ws',
                      pinProtected: false,
                    );

                final target = joinLinkService.parseQrPayload(
                  jsonEncode(internetPayload.toJson()),
                );

                context.push('/room/${target.roomId}');
              },
              child: const Text('Simulate Internet QR Join'),
            ),
        ],
      ),
    );
  }
}
