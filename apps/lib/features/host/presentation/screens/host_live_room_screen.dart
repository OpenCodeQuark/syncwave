import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';
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

  HostedSession get _session {
    return widget.hostedSession ??
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
    final service = ref.read(liveAudioBroadcastServiceProvider);
    unawaited(service.stop());
    super.dispose();
  }

  Future<void> _startBroadcast() async {
    if (_starting || _runtimeStatus.isRunning) {
      return;
    }
    _starting = true;

    try {
      await ref
          .read(liveAudioBroadcastServiceProvider)
          .start(
            session: _session,
            useSystemAudio: _session.audioSourceEnabled,
            useMicrophone: _session.microphoneEnabled,
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
    } finally {
      _stopping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.read(streamingCoordinatorProvider);
    final session = _session;

    String? qrPayload;
    String? joinLink;
    try {
      qrPayload = coordinator.buildPrimaryQrPayload(session);
      joinLink = _runtimeStatus.joinUrl ?? coordinator.buildJoinUrl(session);
    } on FormatException {
      qrPayload = null;
      joinLink = null;
    }

    final endpointDescription = session.mode == StreamingMode.local
        ? '${session.hostAddress ?? 'unavailable'}:${session.hostPort}'
        : (session.serverUrl ?? 'Not configured');

    return PrimaryScaffold(
      title: 'Live Broadcast',
      child: ListView(
        children: [
          SyncWaveCard(
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
                Text('Join endpoint: $endpointDescription'),
                Text(
                  session.roomPinProtected
                      ? 'Room PIN protection: enabled'
                      : 'Room PIN protection: disabled',
                ),
                Text(
                  'Audio Source: ${session.audioSourceEnabled ? 'On' : 'Off'}',
                ),
                Text('Microphone: ${session.microphoneEnabled ? 'On' : 'Off'}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  _statusLabel(_runtimeStatus.phase),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Connected listeners: ${_runtimeStatus.listenerCount}'),
                if (_runtimeStatus.message != null)
                  Text(_runtimeStatus.message!),
                if (_runtimeStatus.errorCode != null)
                  Text('Error: ${_runtimeStatus.errorCode}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text(
                  'Join QR',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Scan this SyncWave deep link from another device on the same network.',
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
                      onPressed: joinLink == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: joinLink!),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Join link copied'),
                                ),
                              );
                            },
                      icon: PhosphorIcon(PhosphorIcons.copy()),
                      label: const Text('Copy Join Link'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: session.roomId),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room code copied')),
                        );
                      },
                      icon: PhosphorIcon(PhosphorIcons.tag()),
                      label: const Text('Copy Room Code'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _stopping
                ? null
                : () async {
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

  String _statusLabel(LiveBroadcastPhase phase) {
    switch (phase) {
      case LiveBroadcastPhase.idle:
        return 'Broadcast idle';
      case LiveBroadcastPhase.blocked:
        return 'Broadcast blocked';
      case LiveBroadcastPhase.starting:
        return 'Starting broadcast...';
      case LiveBroadcastPhase.running:
        return 'Broadcast is live';
      case LiveBroadcastPhase.stopping:
        return 'Stopping broadcast...';
      case LiveBroadcastPhase.error:
        return 'Broadcast error';
    }
  }
}
