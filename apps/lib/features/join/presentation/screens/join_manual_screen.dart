import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/remote_server_connection_controller.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/internet_mode_gate.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_mode.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../../../streaming/providers/streaming_providers.dart';

class JoinManualScreen extends ConsumerStatefulWidget {
  const JoinManualScreen({super.key});

  @override
  ConsumerState<JoinManualScreen> createState() => _JoinManualScreenState();
}

class _JoinManualScreenState extends ConsumerState<JoinManualScreen> {
  final _joinInputController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _joinInputController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(streamingSettingsControllerProvider).valueOrNull ??
        const StreamingSettings();
    final remoteStatus =
        ref.watch(remoteServerConnectionControllerProvider).valueOrNull ??
        const RemoteServerStatus();
    final internetJoinReady = isInternetBroadcastAvailable(
      settings,
      remoteStatus,
    );

    return PrimaryScaffold(
      title: 'Manual Join',
      child: ListView(
        children: [
          TextField(
            controller: _joinInputController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Room code, join URL, or QR payload JSON',
              hintText: 'syncwave://join?host=192.168.1.20:9000&room=LAN-R12B9',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Room PIN (exactly 6 digits, if required)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Local mode is preferred. Internet mode only works when enabled and configured in Settings.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final rawValue = _joinInputController.text.trim();

              try {
                final parsedTarget = ref
                    .read(roomDiscoveryServiceProvider)
                    .parseManualJoinInput(rawValue);

                final enteredPin = ref
                    .read(pinValidationServiceProvider)
                    .normalizeAndValidateOptional(_pinController.text);
                final effectivePin = enteredPin ?? parsedTarget.pin;

                if (parsedTarget.roomPinProtected && effectivePin == null) {
                  throw AppException(
                    'This room requires a 6-digit Room PIN.',
                    code: 'pin_required',
                  );
                }

                if (parsedTarget.mode == StreamingMode.internet) {
                  final internetReady = internetJoinReady;
                  if (!internetReady) {
                    throw AppException(
                      'Internet mode requires server connection and successful handshake. Open Settings and connect first.',
                      code: 'internet_mode_not_connected',
                    );
                  }
                }

                final target = parsedTarget.copyWith(pin: effectivePin);

                final endpointSummary = target.mode == StreamingMode.local
                    ? 'Joining local room ${target.roomId} at ${target.hostAddress ?? 'host from QR'}'
                    : 'Joining internet room ${target.roomId}';

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(endpointSummary)));

                context.push(RoutePaths.roomPath(target.roomId), extra: target);
              } on FormatException catch (error) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              } on AppException catch (error) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }
}
