import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/remote_server_connection_controller.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/internet_mode_gate.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_mode.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../../../streaming/providers/streaming_providers.dart';

class JoinScanScreen extends ConsumerStatefulWidget {
  const JoinScanScreen({super.key});

  @override
  ConsumerState<JoinScanScreen> createState() => _JoinScanScreenState();
}

class _JoinScanScreenState extends ConsumerState<JoinScanScreen> {
  bool _cameraPermissionGranted = false;
  bool _initializing = true;
  bool _handlingCode = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraPermission();
  }

  Future<void> _initializeCameraPermission() async {
    final granted = await ref
        .read(permissionServiceProvider)
        .ensureCameraPermission();

    if (mounted) {
      setState(() {
        _cameraPermissionGranted = granted;
        _initializing = false;
      });
    }
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
      title: 'Scan QR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Scan a SyncWave join QR or /stream/join URL QR.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Local mode is default. Internet join requires server connection + handshake from Settings.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _initializing
                ? const Center(child: CircularProgressIndicator())
                : _cameraPermissionGranted
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      onDetect: (capture) async {
                        if (_handlingCode) {
                          return;
                        }

                        final codes = capture.barcodes;
                        if (codes.isEmpty) {
                          return;
                        }

                        final rawValue = codes.first.rawValue?.trim();
                        if (rawValue == null || rawValue.isEmpty) {
                          return;
                        }

                        _handlingCode = true;
                        try {
                          final parsedTarget = ref
                              .read(roomDiscoveryServiceProvider)
                              .parseManualJoinInput(rawValue);

                          if (parsedTarget.mode == StreamingMode.internet &&
                              !internetJoinReady) {
                            throw AppException(
                              'Internet mode requires an active server connection in Settings.',
                              code: 'internet_mode_not_connected',
                            );
                          }

                          String? effectivePin = parsedTarget.pin;
                          if (parsedTarget.roomPinProtected &&
                              effectivePin == null) {
                            effectivePin = await _promptRoomPin(context);
                            if (effectivePin == null) {
                              throw AppException(
                                'Room PIN is required to join this room.',
                                code: 'room_pin_required',
                              );
                            }
                          }

                          final target = parsedTarget.copyWith(
                            pin: effectivePin,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          context.push(
                            RoutePaths.roomPath(target.roomId),
                            extra: target,
                          );
                        } on FormatException catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        } on AppException catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        } finally {
                          _handlingCode = false;
                        }
                      },
                    ),
                  )
                : _CameraPermissionCard(
                    onRequestPermission: _initializeCameraPermission,
                  ),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRoomPin(BuildContext context) async {
    final pinController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Room PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Room PIN (6 digits)',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final normalized = ref
                      .read(pinValidationServiceProvider)
                      .normalizeAndValidateOptional(pinController.text);
                  if (normalized == null) {
                    throw const FormatException(
                      'Room PIN must be exactly 6 digits.',
                    );
                  }
                  Navigator.of(context).pop(normalized);
                } on FormatException catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room PIN must be exactly 6 digits.'),
                    ),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    pinController.dispose();
    return result;
  }
}

class _CameraPermissionCard extends StatelessWidget {
  const _CameraPermissionCard({required this.onRequestPermission});

  final Future<void> Function() onRequestPermission;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIcons.camera(), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Camera permission is required to scan SyncWave QR codes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRequestPermission,
              child: const Text('Grant Camera Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
