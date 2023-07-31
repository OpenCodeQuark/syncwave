enum RemoteServerConnectionState {
  notConfigured,
  invalidUrl,
  checking,
  serverReachable,
  serverOnlineNotConnected,
  connected,
  disconnected,
  authenticationRequired,
  authenticationFailed,
  websocketFailed,
  notSyncWaveServer,
}

extension RemoteServerConnectionStateX on RemoteServerConnectionState {
  String get label {
    switch (this) {
      case RemoteServerConnectionState.notConfigured:
        return 'Not configured';
      case RemoteServerConnectionState.invalidUrl:
        return 'Invalid URL';
      case RemoteServerConnectionState.checking:
        return 'Checking...';
      case RemoteServerConnectionState.serverReachable:
        return 'Server reachable';
      case RemoteServerConnectionState.serverOnlineNotConnected:
        return 'Server online, not connected';
      case RemoteServerConnectionState.connected:
        return 'Connected';
      case RemoteServerConnectionState.disconnected:
        return 'Disconnected';
      case RemoteServerConnectionState.authenticationRequired:
        return 'Authentication required';
      case RemoteServerConnectionState.authenticationFailed:
        return 'Authentication failed';
      case RemoteServerConnectionState.websocketFailed:
        return 'WebSocket failed';
      case RemoteServerConnectionState.notSyncWaveServer:
        return 'Not a SyncWave server';
    }
  }
}
