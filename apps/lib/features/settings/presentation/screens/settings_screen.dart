import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../streaming/models/streaming_settings.dart';
import '../controllers/streaming_settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  bool _internetEnabled = false;
  bool _initializedFromState = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(streamingSettingsControllerProvider);

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
          final isUrlValid =
              urlValue.isEmpty ||
              ref
                  .read(streamingSettingsControllerProvider.notifier)
                  .isValidSignalingServerUrl(urlValue);

          return ListView(
            children: [
              const Text(
                'Advanced / Internet Streaming',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'SyncWave is local-first. Local Wi-Fi/hotspot streaming works without any external backend.',
              ),
              const SizedBox(height: 8),
              const Text(
                'URL normalization examples: https://example.com -> wss://example.com/ws, http://example.com -> ws://example.com/ws',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _internetEnabled,
                onChanged: (value) {
                  setState(() {
                    _internetEnabled = value;
                  });
                },
                title: const Text('Enable Internet Streaming'),
                subtitle: const Text(
                  'Disabled by default. Enable only if you want custom remote signaling.',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _serverUrlController,
                enabled: _internetEnabled,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Signaling Server URL',
                  hintText: 'wss://example.com/ws',
                  errorText: _internetEnabled && !isUrlValid
                      ? 'Enter a valid ws://, wss://, http://, or https:// URL'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                settings.internetModeReady
                    ? 'Internet mode is available in host/join flows.'
                    : 'Internet mode remains hidden until enabled with a valid server URL.',
              ),
              const SizedBox(height: 24),
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
                                streamingSettingsControllerProvider.notifier,
                              )
                              .saveInternetStreamingConfig(
                                internetEnabled: _internetEnabled,
                                serverUrlInput: _serverUrlController.text,
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
                            const SnackBar(content: Text('Settings saved.')),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(child: Text('Failed to load settings: $error'));
        },
      ),
    );
  }
}
