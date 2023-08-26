enum LiveBroadcastPhase { idle, blocked, starting, running, stopping, error }

class LiveBroadcastStatus {
  const LiveBroadcastStatus({
    required this.phase,
    this.message,
    this.joinUrl,
    this.listenerCount = 0,
    this.useSystemAudio = true,
    this.useMicrophone = false,
    this.errorCode,
    this.updatedAt,
  });

  const LiveBroadcastStatus.idle()
    : phase = LiveBroadcastPhase.idle,
      message = null,
      joinUrl = null,
      listenerCount = 0,
      useSystemAudio = true,
      useMicrophone = false,
      errorCode = null,
      updatedAt = null;

  final LiveBroadcastPhase phase;
  final String? message;
  final String? joinUrl;
  final int listenerCount;
  final bool useSystemAudio;
  final bool useMicrophone;
  final String? errorCode;
  final DateTime? updatedAt;

  bool get isRunning => phase == LiveBroadcastPhase.running;
  bool get isBusy =>
      phase == LiveBroadcastPhase.starting ||
      phase == LiveBroadcastPhase.stopping;

  LiveBroadcastStatus copyWith({
    LiveBroadcastPhase? phase,
    String? message,
    bool clearMessage = false,
    String? joinUrl,
    bool clearJoinUrl = false,
    int? listenerCount,
    bool? useSystemAudio,
    bool? useMicrophone,
    String? errorCode,
    bool clearErrorCode = false,
    DateTime? updatedAt,
  }) {
    return LiveBroadcastStatus(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      joinUrl: clearJoinUrl ? null : (joinUrl ?? this.joinUrl),
      listenerCount: listenerCount ?? this.listenerCount,
      useSystemAudio: useSystemAudio ?? this.useSystemAudio,
      useMicrophone: useMicrophone ?? this.useMicrophone,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
