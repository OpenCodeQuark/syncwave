import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../settings/presentation/controllers/remote_server_connection_controller.dart';
import '../../../settings/presentation/controllers/streaming_settings_controller.dart';
import '../../../streaming/models/internet_mode_gate.dart';
import '../../../streaming/models/broadcast_destination.dart';
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
  final bool _microphoneEnabled = false;
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
          SectionCard(
            title: 'Local Broadcast',
            subtitle:
                'Local streaming works over Wi-Fi or hotspot without a server.',
            child: Text(
              internetBroadcastReady
                  ? 'Internet signaling connected: internet-assisted sessions are available.'
                  : settings.internetModeConfigured
                  ? 'Internet signaling configured but not connected. Local broadcast still works.'
                  : 'Internet signaling is optional and currently disabled.',
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Audio',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
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
                  onChanged: null,
                  title: const Text('Microphone'),
                  subtitle: const Text(
                    'Microphone overlay support is coming soon.',
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

                      final coordinator = ref.read(
                        streamingCoordinatorProvider,
                      );
                      final availability = await coordinator
                          .resolveBroadcastAvailability(
                            settings: settings,
                            remoteServerStatus: remoteStatus,
                          );
                      final destination = await _selectBroadcastDestination(
                        availability,
                      );
                      if (destination == null) {
                        return;
                      }

                      final notificationAllowed =
                          await _ensureNotificationPermissionForBroadcast();
                      if (!notificationAllowed) {
                        throw AppException(
                          'Notification permission is required for foreground broadcast status.',
                          code: 'notification_permission_required',
                        );
                      }

                      if (_audioSourceEnabled) {
                        final shouldContinue =
                            await _confirmSystemAudioPermissionIntro();
                        if (!shouldContinue) {
                          throw AppException(
                            'System audio permission was not approved.',
                            code: 'system_audio_permission_intro_cancelled',
                          );
                        }
                      }

                      final needsAudioPermission =
                          _audioSourceEnabled || _microphoneEnabled;
                      if (needsAudioPermission) {
                        final audioPermissionGranted = await ref
                            .read(permissionServiceProvider)
                            .ensureAudioCapturePermission();
                        if (!audioPermissionGranted) {
                          throw AppException(
                            'Audio capture permission is required for broadcasting.',
                            code: 'audio_capture_permission_required',
                          );
                        }
                      }

                      final hostedSession = await coordinator.createHostSession(
                        roomName: _roomNameController.text.trim().isEmpty
                            ? 'SyncWave Room'
                            : _roomNameController.text.trim(),
                        pinProtected: _pinEnabled,
                        pin: pin,
                        settings: settings,
                        remoteServerStatus: remoteStatus,
                        destination: destination,
                        serverConnectionPin: await ref
                            .read(streamingSettingsRepositoryProvider)
                            .readServerConnectionPin(),
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
            child: Text(_isCreatingRoom ? 'Starting...' : 'Start Broadcast'),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureNotificationPermissionForBroadcast() async {
    final permissionService = ref.read(permissionServiceProvider);
    final isGranted = await permissionService.isNotificationPermissionGranted();
    if (isGranted) {
      return true;
    }

    if (!mounted) {
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

  Future<BroadcastDestination?> _selectBroadcastDestination(
    BroadcastAvailability availability,
  ) async {
    if (!availability.hasAny) {
      throw AppException(
        'Connect to Wi-Fi, enable hotspot, or connect an internet signaling server to start broadcasting.',
        code: 'broadcast_unavailable',
      );
    }

    final defaultDestination = availability.defaultDestination;
    if (defaultDestination != null) {
      return defaultDestination;
    }

    if (!mounted) {
      return null;
    }

    return showModalBottomSheet<BroadcastDestination>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.route_rounded,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Broadcast Destination',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'LAN and internet are both ready.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _DestinationTile(
                  destination: BroadcastDestination.localOnly,
                  icon: Icons.wifi_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(BroadcastDestination.localOnly),
                ),
                _DestinationTile(
                  destination: BroadcastDestination.internetOnly,
                  icon: Icons.public_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(BroadcastDestination.internetOnly),
                ),
                _DestinationTile(
                  destination: BroadcastDestination.both,
                  icon: Icons.hub_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(BroadcastDestination.both),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmSystemAudioPermissionIntro() async {
    if (!mounted) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('System Audio Permission'),
          content: const Text(
            'Android requires a screen-share style permission prompt to capture system audio. SyncWave only captures audio for your broadcast.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.icon,
    required this.onTap,
  });

  final BroadcastDestination destination;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.subtitle,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
