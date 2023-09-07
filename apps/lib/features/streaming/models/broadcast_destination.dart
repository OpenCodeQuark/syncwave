enum BroadcastDestination {
  automatic,
  localOnly,
  internetOnly,
  both;

  bool get includesLocal {
    return this == BroadcastDestination.automatic ||
        this == BroadcastDestination.localOnly ||
        this == BroadcastDestination.both;
  }

  bool get includesInternet {
    return this == BroadcastDestination.automatic ||
        this == BroadcastDestination.internetOnly ||
        this == BroadcastDestination.both;
  }

  String get title {
    switch (this) {
      case BroadcastDestination.automatic:
        return 'Automatic';
      case BroadcastDestination.localOnly:
        return 'LAN only';
      case BroadcastDestination.internetOnly:
        return 'Internet only';
      case BroadcastDestination.both:
        return 'LAN + Internet';
    }
  }

  String get subtitle {
    switch (this) {
      case BroadcastDestination.automatic:
        return 'Use the best available broadcast path.';
      case BroadcastDestination.localOnly:
        return 'Nearby Wi-Fi or hotspot.';
      case BroadcastDestination.internetOnly:
        return 'WebSocket server.';
      case BroadcastDestination.both:
        return 'Nearby listeners and internet listeners.';
    }
  }
}

class BroadcastAvailability {
  const BroadcastAvailability({
    required this.localAvailable,
    required this.internetAvailable,
  });

  final bool localAvailable;
  final bool internetAvailable;

  bool get hasAny => localAvailable || internetAvailable;
  bool get bothAvailable => localAvailable && internetAvailable;

  BroadcastDestination? get defaultDestination {
    if (bothAvailable) {
      return null;
    }
    if (localAvailable) {
      return BroadcastDestination.localOnly;
    }
    if (internetAvailable) {
      return BroadcastDestination.internetOnly;
    }
    return null;
  }
}
