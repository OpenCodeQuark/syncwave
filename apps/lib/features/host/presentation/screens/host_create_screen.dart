import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/remote_server_connection_controller.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/audio_source_mode.dart';
import '../../../streaming/models/internet_mode_gate.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../../../streaming/providers/streaming_providers.dart';

class HostCreateScreen extends ConsumerStatefulWidget {
  const HostCreateScreen({super.key});

  @override
  ConsumerState<HostCreateScreen> createState() => _HostCreateScreenState();
}

class _HostCreateScreenState extends ConsumerState<HostCreateScreen> {
  final _roomNameController = TextEditingController(text: 'My SyncWave Room');
  final _pinController = TextEditingController();
  bool _pinEnabled = false;
  bool _audioSourceEnabled = true;
  bool _microphoneEnabled = false;
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _roomNameController.dispose();
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
    final internetBroadcastReady = isInternetBroadcastAvailable(
      settings,
      remoteStatus,
    );

    return PrimaryScaffold(
      title: 'Start Broadcast',
      child: ListView(
        children: [
          const Text(
            'Local streaming works over Wi-Fi or hotspot without a server.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect host and listeners to the same Wi-Fi or hotspot in Local Mode.',
          ),
          const SizedBox(height: 8),
          Text(
            internetBroadcastReady
                ? 'Internet signaling connected: internet-assisted sessions are available.'
                : settings.internetModeConfigured
                ? 'Internet signaling configured but not connected. Local broadcast still works.'
                : 'Internet signaling is optional and currently disabled.',
          ),
          const SizedBox(height: 16),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('Audio', style: Theme.of(context).textTheme.titleMedium),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _audioSourceEnabled,
                    onChanged: (value) {
                      setState(() {
                        _audioSourceEnabled = value;
                      });
                    },
                    title: const Text('Audio Source'),
                    subtitle: const Text(
                      'Capture system/device audio (Android host only).',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _microphoneEnabled,
                    onChanged: (value) {
                      setState(() {
                        _microphoneEnabled = value;
                      });
                    },
                    title: const Text('Microphone'),
                    subtitle: const Text(
                      'Overlay microphone input (optional).',
                    ),
                  ),
                  if (!_audioSourceEnabled && !_microphoneEnabled)
                    const Text(
                      'Enable Audio Source or Microphone to continue.',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          if (!internetBroadcastReady && settings.internetModeConfigured)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Internet mode becomes available after Settings > Test Connection and Connect succeed.',
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _roomNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Room name'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _pinEnabled,
            onChanged: (value) {
              setState(() {
                _pinEnabled = value;
              });
            },
            title: const Text('Enable PIN protection'),
          ),
          if (_pinEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Room PIN (exactly 6 digits)',
                  counterText: '',
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'At least one audio option must be enabled before starting broadcast.',
          ),
          const SizedBox(height: 8),
          Text(
            '${AudioSourceMode.systemAudio.label} and microphone can run together on Android host.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isCreatingRoom
                ? null
                : () async {
                    if (!_audioSourceEnabled && !_microphoneEnabled) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enable Audio Source or Microphone before starting broadcast.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _isCreatingRoom = true;
                    });

                    try {
                      String? pin;
                      if (_pinEnabled) {
                        pin = ref
                            .read(pinValidationServiceProvider)
                            .normalizeAndValidateOptional(_pinController.text);
                        if (pin == null) {
                          throw AppException(
                            'Room PIN must be exactly 6 digits.',
                            code: 'invalid_pin',
                          );
                        }
                      }

                      final notificationAllowed =
                          await _ensureNotificationPermissionForBroadcast(
                            context,
                          );
                      if (!notificationAllowed) {
                        throw AppException(
                          'Notification permission is required for foreground broadcast status.',
                          code: 'notification_permission_required',
                        );
                      }

                      if (_microphoneEnabled) {
                        final microphoneGranted = await ref
                            .read(permissionServiceProvider)
                            .ensureMicrophonePermission();
                        if (!microphoneGranted) {
                          throw AppException(
                            'Microphone permission is required when Microphone is enabled.',
                            code: 'microphone_permission_required',
                          );
                        }
                      }

                      final coordinator = ref.read(
                        streamingCoordinatorProvider,
                      );
                      final hostedSession = await coordinator.createHostSession(
                        roomName: _roomNameController.text.trim().isEmpty
                            ? 'SyncWave Room'
                            : _roomNameController.text.trim(),
                        pinProtected: _pinEnabled,
                        pin: pin,
                        settings: settings,
                        remoteServerStatus: remoteStatus,
                        audioSourceEnabled: _audioSourceEnabled,
                        microphoneEnabled: _microphoneEnabled,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      await context.push(
                        RoutePaths.hostLivePath(hostedSession.roomId),
                        extra: hostedSession,
                      );
                    } on FormatException catch (error) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    } on AppException catch (error) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isCreatingRoom = false;
                        });
                      }
                    }
                  },
            child: Text(_isCreatingRoom ? 'Creating...' : 'Create Room'),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureNotificationPermissionForBroadcast(
    BuildContext context,
  ) async {
    final permissionService = ref.read(permissionServiceProvider);
    final isGranted = await permissionService.isNotificationPermissionGranted();
    if (isGranted) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification Permission'),
          content: const Text(
            'SyncWave uses foreground broadcast notifications so listeners know when hosting is active. Allow notification permission to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) {
      return false;
    }

    return permissionService.ensureNotificationPermission();
  }
}
