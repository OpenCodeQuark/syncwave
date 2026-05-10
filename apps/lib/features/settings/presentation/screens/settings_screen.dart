import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../streaming/models/remote_server_connection_state.dart';
import '../../../streaming/models/remote_server_status.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../controllers/remote_server_connection_controller.dart';
import '../controllers/streaming_settings_controller.dart';
import '../utils/server_status_copy_formatter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _serverConnectionPinController = TextEditingController();
  final _statusCopyFormatter = ServerStatusCopyFormatter();
  bool _internetEnabled = false;
  bool _initializedFromState = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _serverConnectionPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(streamingSettingsControllerProvider);
    final remoteStatusState = ref.watch(
      remoteServerConnectionControllerProvider,
    );
    final remoteStatus = remoteStatusState.valueOrNull;

    return PrimaryScaffold(
      title: 'Settings',
      child: settingsState.when(
        data: (settings) {
          if (!_initializedFromState) {
            _internetEnabled = settings.internetStreamingEnabled;
            _serverUrlController.text = settings.signalingServerUrl ?? '';
            _initializedFromState = true;
          }

          final urlValue = _serverUrlController.text.trim();
          final serverConnectionPinValue = _serverConnectionPinController.text
              .trim();
          final isUrlValid =
              urlValue.isEmpty ||
              ref
                  .read(streamingSettingsControllerProvider.notifier)
                  .isValidSignalingServerUrl(urlValue);
          final isServerPinValid =
              serverConnectionPinValue.isEmpty ||
              ref
                  .read(streamingSettingsControllerProvider.notifier)
                  .isValidServerConnectionPin(serverConnectionPinValue);

          final connectionStatus = remoteStatusState.isLoading
              ? RemoteServerConnectionState.checking
              : (remoteStatus?.state ??
                    RemoteServerConnectionState.notConfigured);
          String? normalizedWsUrl = remoteStatus?.normalizedWebSocketUrl;
          String? derivedStatusUrl = remoteStatus?.statusUrl;
          if (normalizedWsUrl == null && isUrlValid && urlValue.isNotEmpty) {
            try {
              normalizedWsUrl = ref
                  .read(streamingSettingsControllerProvider.notifier)
                  .normalizeSignalingServerUrl(urlValue);
              derivedStatusUrl = ref
                  .read(streamingSettingsControllerProvider.notifier)
                  .deriveStatusUrl(normalizedWsUrl);
            } on FormatException {
              normalizedWsUrl = null;
              derivedStatusUrl = null;
            }
          }

          return ListView(
            children: [
              const SectionCard(
                title: 'Advanced / Internet Streaming',
                subtitle:
                    'SyncWave is local-first. Local Wi-Fi/hotspot streaming works without an external backend.',
                child: Text(
                  'Internet streaming is optional and disabled by default.',
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Configuration',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    SwitchListTile(
                      value: _internetEnabled,
                      onChanged: (value) {
                        setState(() {
                          _internetEnabled = value;
                        });
                      },
                      title: const Text('Enable Internet Streaming'),
                      subtitle: const Text(
                        'Enable only when you need optional internet signaling.',
                      ),
                    ),
                    TextField(
                      controller: _serverUrlController,
                      enabled: _internetEnabled,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Signaling Server URL',
                        hintText: 'https://your-server.example.com',
                        errorText: _internetEnabled && !isUrlValid
                            ? 'Enter a valid ws://, wss://, http://, or https:// URL'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _serverConnectionPinController,
                      enabled: _internetEnabled,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Server Connection PIN (optional, 8 digits)',
                        helperText: settings.serverConnectionPinConfigured
                            ? 'A Server Connection PIN is currently configured.'
                            : 'Leave blank if server does not require authentication.',
                        counterText: '',
                        errorText: isServerPinValid
                            ? null
                            : 'Server Connection PIN must be exactly 8 digits.',
                      ),
                    ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() {
                                _isSaving = true;
                              });

                              try {
                                await ref
                                    .read(
                                      streamingSettingsControllerProvider
                                          .notifier,
                                    )
                                    .saveInternetStreamingConfig(
                                      internetEnabled: _internetEnabled,
                                      serverUrlInput: _serverUrlController.text,
                                      serverConnectionPinInput:
                                          _serverConnectionPinController.text,
                                    );

                                final savedSettings = ref
                                    .read(streamingSettingsControllerProvider)
                                    .valueOrNull;
                                if (savedSettings != null) {
                                  _serverUrlController.text =
                                      savedSettings.signalingServerUrl ?? '';
                                }

                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Settings saved.'),
                                  ),
                                );
                              } on AppException catch (error) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.message)),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSaving = false;
                                  });
                                }
                              }
                            },
                      child: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              SectionCard(
                title: 'Server Connection Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    StatusBadge(
                      label: connectionStatus.label,
                      tone: switch (connectionStatus) {
                        RemoteServerConnectionState.connected =>
                          StatusBadgeTone.success,
                        RemoteServerConnectionState.serverReachable ||
                        RemoteServerConnectionState.serverOnlineNotConnected =>
                          StatusBadgeTone.info,
                        RemoteServerConnectionState.authenticationFailed ||
                        RemoteServerConnectionState.websocketFailed ||
                        RemoteServerConnectionState.disconnected =>
                          StatusBadgeTone.danger,
                        RemoteServerConnectionState.checking =>
                          StatusBadgeTone.warning,
                        _ => StatusBadgeTone.neutral,
                      },
                    ),
                    if (normalizedWsUrl != null)
                      Text('WebSocket URL: $normalizedWsUrl'),
                    if (derivedStatusUrl != null)
                      Text('Status URL: $derivedStatusUrl'),
                    if (remoteStatus?.checkedAt != null)
                      Text('Last checked: ${remoteStatus!.checkedAt}'),
                    if (remoteStatus?.serverVersion != null)
                      Text('Server version: ${remoteStatus!.serverVersion}'),
                    if (remoteStatus?.protocolVersion != null)
                      Text(
                        'Protocol version: ${remoteStatus!.protocolVersion}',
                      ),
                    if (remoteStatus?.redisConnected != null)
                      Text('Redis connected: ${remoteStatus!.redisConnected}'),
                    if (remoteStatus?.activeRooms != null)
                      Text('Active rooms: ${remoteStatus!.activeRooms}'),
                    if (remoteStatus?.activeConnections != null)
                      Text(
                        'Active connections: ${remoteStatus!.activeConnections}',
                      ),
                    if (remoteStatus?.message != null)
                      Text('Message: ${remoteStatus!.message}'),
                    if (remoteStatus?.errorCode != null)
                      Text('Error code: ${remoteStatus!.errorCode}'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: !_internetEnabled || !isUrlValid
                              ? null
                              : () async {
                                  final savedPin = await ref
                                      .read(
                                        streamingSettingsControllerProvider
                                            .notifier,
                                      )
                                      .readServerConnectionPin();

                                  final pinInput =
                                      _serverConnectionPinController.text
                                          .trim();
                                  final effectivePin = pinInput.isNotEmpty
                                      ? pinInput
                                      : savedPin;

                                  await ref
                                      .read(
                                        remoteServerConnectionControllerProvider
                                            .notifier,
                                      )
                                      .checkConnection(
                                        serverUrlInput:
                                            _serverUrlController.text,
                                        serverConnectionPin: effectivePin,
                                        attemptWebSocket: true,
                                      );
                                },
                          icon: PhosphorIcon(PhosphorIcons.network()),
                          label: Text(
                            remoteStatusState.isLoading
                                ? 'Checking...'
                                : 'Test Connection',
                          ),
                        ),
                        if (remoteStatus?.websocketConnected == true)
                          FilledButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(
                                    remoteServerConnectionControllerProvider
                                        .notifier,
                                  )
                                  .disconnect();
                            },
                            icon: PhosphorIcon(PhosphorIcons.linkBreak()),
                            label: const Text('Disconnect'),
                          )
                        else
                          FilledButton.icon(
                            onPressed:
                                !_internetEnabled ||
                                    !isUrlValid ||
                                    remoteStatus == null ||
                                    !remoteStatus.reachable ||
                                    !remoteStatus.isSyncWaveServer
                                ? null
                                : () async {
                                    final savedPin = await ref
                                        .read(
                                          streamingSettingsControllerProvider
                                              .notifier,
                                        )
                                        .readServerConnectionPin();

                                    final pinInput =
                                        _serverConnectionPinController.text
                                            .trim();
                                    final effectivePin = pinInput.isNotEmpty
                                        ? pinInput
                                        : savedPin;

                                    await ref
                                        .read(
                                          remoteServerConnectionControllerProvider
                                              .notifier,
                                        )
                                        .connect(
                                          serverUrlInput:
                                              _serverUrlController.text,
                                          serverConnectionPin: effectivePin,
                                        );
                                  },
                            icon: PhosphorIcon(PhosphorIcons.link()),
                            label: const Text('Connect'),
                          ),
                        OutlinedButton.icon(
                          onPressed: normalizedWsUrl == null
                              ? null
                              : () async {
                                  final wsUrl = normalizedWsUrl;
                                  if (wsUrl == null) {
                                    return;
                                  }
                                  await Clipboard.setData(
                                    ClipboardData(text: wsUrl),
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('WebSocket URL copied'),
                                    ),
                                  );
                                },
                          icon: PhosphorIcon(PhosphorIcons.copy()),
                          label: const Text('Copy WebSocket URL'),
                        ),
                        OutlinedButton.icon(
                          onPressed: derivedStatusUrl == null
                              ? null
                              : () async {
                                  final statusUrl = derivedStatusUrl;
                                  if (statusUrl == null) {
                                    return;
                                  }
                                  await Clipboard.setData(
                                    ClipboardData(text: statusUrl),
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Status URL copied'),
                                    ),
                                  );
                                },
                          icon: PhosphorIcon(PhosphorIcons.copySimple()),
                          label: const Text('Copy Status URL'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final statusSummary = _statusCopyFormatter.format(
                              connectionState: connectionStatus,
                              status: remoteStatus,
                              normalizedWebSocketUrl: normalizedWsUrl,
                              derivedStatusUrl: derivedStatusUrl,
                            );

                            await Clipboard.setData(
                              ClipboardData(text: statusSummary),
                            );

                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Status details copied'),
                              ),
                            );
                          },
                          icon: PhosphorIcon(PhosphorIcons.clipboardText()),
                          label: const Text('Copy Status Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInternetAvailabilityNote(settings, remoteStatus),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(child: Text('Failed to load settings: $error'));
        },
      ),
    );
  }

  Widget _buildInternetAvailabilityNote(
    StreamingSettings settings,
    RemoteServerStatus? remoteStatus,
  ) {
    if (!settings.internetStreamingEnabled) {
      return const Text(
        'Internet mode is disabled. Local mode remains the default.',
      );
    }

    if (!settings.hasServerUrl) {
      return const Text(
        'Internet mode is enabled, but no signaling server URL is configured.',
      );
    }

    if (remoteStatus == null) {
      return const Text(
        'Internet mode is configured. Test and connect to server to enable internet broadcast.',
      );
    }

    if (remoteStatus.internetBroadcastReady) {
      return const Text(
        'Internet broadcast is available: server reachable, connected, and handshake accepted.',
      );
    }

    return const Text(
      'Internet mode is configured, but broadcast stays unavailable until server connection and handshake succeed.',
    );
  }
}
