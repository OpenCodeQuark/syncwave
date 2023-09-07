import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../streaming/models/hosted_session.dart';
import '../../../streaming/models/live_broadcast_status.dart';
import '../../../streaming/models/streaming_mode.dart';
import '../../../streaming/providers/streaming_providers.dart';

class HostLiveRoomScreen extends ConsumerStatefulWidget {
  const HostLiveRoomScreen({
    super.key,
    required this.roomId,
    this.hostedSession,
  });

  final String roomId;
  final HostedSession? hostedSession;

  @override
  ConsumerState<HostLiveRoomScreen> createState() => _HostLiveRoomScreenState();
}

class _HostLiveRoomScreenState extends ConsumerState<HostLiveRoomScreen> {
  StreamSubscription<LiveBroadcastStatus>? _statusSubscription;
  LiveBroadcastStatus _runtimeStatus = const LiveBroadcastStatus.idle();
  bool _starting = false;
  bool _stopping = false;
  bool _includePinInQr = false;

  HostedSession get _session {
    return widget.hostedSession ??
        ref.read(liveAudioBroadcastServiceProvider).activeSession ??
        HostedSession(
          roomId: widget.roomId,
          roomName: 'SyncWave Room',
          mode: StreamingMode.local,
          hostAddress: null,
          hostPort: 9000,
          roomPinProtected: false,
          audioSourceEnabled: true,
          microphoneEnabled: false,
        );
  }

  @override
  void initState() {
    super.initState();
    final service = ref.read(liveAudioBroadcastServiceProvider);
    _runtimeStatus = service.status;
    _statusSubscription = service.statusStream.listen((status) {
      if (!mounted) {
        return;
      }
      setState(() {
        _runtimeStatus = status;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBroadcast();
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startBroadcast() async {
    if (_starting || _runtimeStatus.isRunning || _runtimeStatus.isBusy) {
      return;
    }
    _starting = true;

    try {
      final serverConnectionPin = await ref
          .read(streamingSettingsRepositoryProvider)
          .readServerConnectionPin();
      await ref
          .read(liveAudioBroadcastServiceProvider)
          .start(
            session: _session,
            useSystemAudio: _session.audioSourceEnabled,
            useMicrophone: _session.microphoneEnabled,
            serverConnectionPin: serverConnectionPin,
          );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      _starting = false;
    }
  }

  Future<void> _stopBroadcast() async {
    if (_stopping) {
      return;
    }

    _stopping = true;
    try {
      await ref.read(liveAudioBroadcastServiceProvider).stop();
      await ref.read(streamingCoordinatorProvider).stopLocalSession();
    } finally {
      _stopping = false;
    }
  }

  Future<bool> _confirmStopBroadcast() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop Broadcast?'),
          content: const Text(
            'Listeners will be disconnected and this room will close.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Stop Broadcast'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _copyToClipboard(String value, String successText) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successText)));
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.read(streamingCoordinatorProvider);
    final service = ref.read(liveAudioBroadcastServiceProvider);
    final appConfig = ref.read(appConfigProvider);
    final session = _session;

    final localAvailable =
        session.hostAddress != null &&
        session.hostAddress!.trim().isNotEmpty &&
        session.mode == StreamingMode.local;
    final wanAvailable =
        session.serverUrl != null &&
        session.serverUrl!.trim().isNotEmpty &&
        session.wanRoomId != null &&
        session.wanRoomId!.trim().isNotEmpty;

    String? localJoinLink;
    String? localJoinLinkWithPin;
    String? internetJoinLink;
    String? internetJoinLinkWithPin;
    String? qrPayload;
    String? preferredJoinLink;
    String preferredRoomCode = session.roomId;

    try {
      if (localAvailable) {
        localJoinLink = coordinator.buildJoinUrl(
          session,
          includeRoomPin: false,
        );
        if (session.roomPinProtected) {
          localJoinLinkWithPin = coordinator.buildJoinUrl(
            session,
            includeRoomPin: true,
          );
        }
      }
      if (wanAvailable) {
        internetJoinLink = coordinator.buildInternetJoinUrl(
          session,
          includeRoomPin: false,
        );
        if (session.roomPinProtected) {
          internetJoinLinkWithPin = coordinator.buildInternetJoinUrl(
            session,
            includeRoomPin: true,
          );
        }
      }

      preferredJoinLink = localJoinLink ?? internetJoinLink;
      if (localAvailable) {
        qrPayload = coordinator.buildAppQrPayload(
          session,
          appVersion: appConfig.appVersion,
          includeRoomPin: _includePinInQr,
        );
      } else if (wanAvailable) {
        qrPayload = coordinator.buildAppQrPayload(
          session.copyWith(
            mode: StreamingMode.internet,
            roomId: session.wanRoomId!,
            hostAddress: null,
            hostPort: null,
          ),
          appVersion: appConfig.appVersion,
          includeRoomPin: _includePinInQr,
        );
        preferredRoomCode = session.wanRoomId!;
      }
    } on FormatException {
      qrPayload = null;
      localJoinLink = null;
      localJoinLinkWithPin = null;
      internetJoinLink = null;
      internetJoinLinkWithPin = null;
      preferredJoinLink = null;
    }

    final endpointDescription = session.mode == StreamingMode.local
        ? '${session.hostAddress ?? 'unavailable'}:${session.hostPort}'
        : (session.serverUrl ?? 'Not configured');

    return PrimaryScaffold(
      title: 'Live Broadcast',
      child: ListView(
        children: [
          SectionCard(
            title: 'Room',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  session.roomId,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Primary endpoint: $endpointDescription'),
                if (localAvailable)
                  Text('LAN room: ${session.roomId}')
                else
                  const Text('LAN room: unavailable'),
                if (wanAvailable)
                  Text('WAN room: ${session.wanRoomId}')
                else
                  const Text('WAN room: unavailable'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Broadcast Status',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                StatusBadge(
                  label: _statusLabel(_runtimeStatus),
                  tone: switch (_runtimeStatus.phase) {
                    LiveBroadcastPhase.running => StatusBadgeTone.success,
                    LiveBroadcastPhase.starting ||
                    LiveBroadcastPhase.stopping => StatusBadgeTone.warning,
                    LiveBroadcastPhase.error => StatusBadgeTone.danger,
                    _ => StatusBadgeTone.neutral,
                  },
                ),
                Text('Connected listeners: ${_runtimeStatus.listenerCount}'),
                Text(
                  session.roomPinProtected
                      ? 'Room PIN protection: enabled'
                      : 'Room PIN protection: disabled',
                ),
                if (_runtimeStatus.message != null)
                  Text(_runtimeStatus.message!),
                if (_runtimeStatus.errorCode != null)
                  Text('Error: ${_runtimeStatus.errorCode}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Live Controls',
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _runtimeStatus.phase == LiveBroadcastPhase.running
                      ? () async {
                          await service.toggleSystemAudioMute();
                        }
                      : null,
                  icon: PhosphorIcon(
                    _runtimeStatus.systemAudioMuted
                        ? PhosphorIcons.speakerSlash()
                        : PhosphorIcons.speakerHigh(),
                  ),
                  tooltip: _runtimeStatus.systemAudioMuted
                      ? 'Unmute Audio Source'
                      : 'Mute Audio Source',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Microphone support coming soon.'),
                      ),
                    );
                  },
                  icon: PhosphorIcon(PhosphorIcons.microphoneSlash()),
                  tooltip: 'Microphone support coming soon',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Join QR',
            subtitle: 'Scan this QR from another device to join quickly.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _includePinInQr,
                  onChanged: session.roomPinProtected
                      ? (value) {
                          setState(() {
                            _includePinInQr = value;
                          });
                        }
                      : null,
                  title: const Text('Include PIN in QR'),
                  subtitle: Text(
                    session.roomPinProtected
                        ? (_includePinInQr
                              ? 'PIN is included in QR payload.'
                              : 'PIN is hidden. Joiner will be prompted.')
                        : 'Room has no PIN.',
                  ),
                ),
                if (qrPayload != null)
                  Center(
                    child: QrImageView(
                      data: qrPayload,
                      size: 200,
                      version: QrVersions.auto,
                    ),
                  )
                else
                  const Text('Waiting for a valid join endpoint...'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: preferredJoinLink == null
                          ? null
                          : () => _copyToClipboard(
                              preferredJoinLink!,
                              'Join link copied',
                            ),
                      icon: PhosphorIcon(PhosphorIcons.copy()),
                      label: const Text('Copy Join Link'),
                    ),
                    if (session.roomPinProtected &&
                        (localJoinLinkWithPin != null ||
                            internetJoinLinkWithPin != null))
                      OutlinedButton.icon(
                        onPressed: () {
                          final linkWithPin =
                              localJoinLinkWithPin ?? internetJoinLinkWithPin;
                          if (linkWithPin == null) {
                            return;
                          }
                          _copyToClipboard(
                            linkWithPin,
                            'Join link with PIN copied',
                          );
                        },
                        icon: PhosphorIcon(PhosphorIcons.lockKey()),
                        label: const Text('Copy Link + PIN'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(
                        preferredRoomCode,
                        'Room code copied',
                      ),
                      icon: PhosphorIcon(PhosphorIcons.tag()),
                      label: const Text('Copy Room Code'),
                    ),
                  ],
                ),
                if (localJoinLink != null) Text('LAN URL: $localJoinLink'),
                if (internetJoinLink != null)
                  Text('WAN URL: $internetJoinLink'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _stopping
                ? null
                : () async {
                    final shouldStop = await _confirmStopBroadcast();
                    if (!shouldStop) {
                      return;
                    }
                    await _stopBroadcast();
                    if (!context.mounted) {
                      return;
                    }
                    context.pop();
                  },
            icon: PhosphorIcon(PhosphorIcons.stopCircle()),
            label: Text(_stopping ? 'Stopping...' : 'Stop Broadcast'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(LiveBroadcastStatus status) {
    if (status.phase == LiveBroadcastPhase.running && status.systemAudioMuted) {
      return 'Muted';
    }

    switch (status.phase) {
      case LiveBroadcastPhase.idle:
        return 'Stopped';
      case LiveBroadcastPhase.blocked:
        return 'Broadcast blocked';
      case LiveBroadcastPhase.starting:
        return 'Starting';
      case LiveBroadcastPhase.running:
        return 'Broadcasting';
      case LiveBroadcastPhase.stopping:
        return 'Stopping';
      case LiveBroadcastPhase.error:
        return 'Error';
    }
  }
}
