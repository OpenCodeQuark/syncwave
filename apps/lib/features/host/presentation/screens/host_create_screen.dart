import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/audio_source_mode.dart';
import '../../../streaming/models/streaming_mode.dart';
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
  String _qualityMode = 'Balanced';
  String _networkMode = 'Wi-Fi';
  StreamingMode _selectedMode = StreamingMode.local;
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
    final internetModeVisible = settings.internetModeReady;

    if (!internetModeVisible && _selectedMode == StreamingMode.internet) {
      _selectedMode = StreamingMode.local;
    }

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
          const SizedBox(height: 16),
          TextField(
            controller: _roomNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Room name'),
          ),
          const SizedBox(height: 16),
          if (internetModeVisible)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Streaming mode'),
                const SizedBox(height: 8),
                SegmentedButton<StreamingMode>(
                  segments: const [
                    ButtonSegment(
                      value: StreamingMode.local,
                      label: Text('Local Mode'),
                    ),
                    ButtonSegment(
                      value: StreamingMode.internet,
                      label: Text('Internet Mode'),
                    ),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedMode = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
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
                  labelText: 'PIN (exactly 6 digits)',
                  counterText: '',
                ),
              ),
            ),
          const Text('Audio Source (upcoming)'),
          const SizedBox(height: 8),
          ...AudioSourceMode.values.map(
            (source) => ListTile(
              leading: const Icon(Icons.upcoming),
              title: Text(source.label),
              subtitle: Text(source.availabilityNote),
              trailing: const Text('Disabled'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Microphone broadcast and system audio capture will be enabled in later phases.',
          ),
          const SizedBox(height: 16),
          const Text('Quality mode'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Low Latency', label: Text('Low Latency')),
              ButtonSegment(value: 'Balanced', label: Text('Balanced')),
              ButtonSegment(
                value: 'High Stability',
                label: Text('High Stability'),
              ),
            ],
            selected: {_qualityMode},
            onSelectionChanged: (selection) {
              setState(() {
                _qualityMode = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _networkMode,
            decoration: const InputDecoration(labelText: 'Network mode'),
            items: const [
              DropdownMenuItem(value: 'Wi-Fi', child: Text('Wi-Fi')),
              DropdownMenuItem(value: 'Hotspot', child: Text('Hotspot')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _networkMode = value;
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isCreatingRoom
                ? null
                : () async {
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
                            'PIN must be exactly 6 digits.',
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

                      final coordinator = ref.read(
                        streamingCoordinatorProvider,
                      );
                      final hostedSession = await coordinator.createHostSession(
                        mode: _selectedMode,
                        roomName: _roomNameController.text.trim().isEmpty
                            ? 'SyncWave Room'
                            : _roomNameController.text.trim(),
                        pinProtected: _pinEnabled,
                        pin: pin,
                        settings: settings,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      await context.push(
                        '/host/live/${hostedSession.roomId}',
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
