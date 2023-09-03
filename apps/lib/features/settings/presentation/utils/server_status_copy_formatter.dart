import '../../../streaming/models/remote_server_connection_state.dart';
import '../../../streaming/models/remote_server_status.dart';

class ServerStatusCopyFormatter {
  String format({
    required RemoteServerConnectionState connectionState,
    required RemoteServerStatus? status,
    String? normalizedWebSocketUrl,
    String? derivedStatusUrl,
  }) {
    final lines = <String>[
      'SyncWave Server Connection Status',
      'Connection state: ${connectionState.label}',
    ];

    final wsUrl = status?.normalizedWebSocketUrl ?? normalizedWebSocketUrl;
    if (wsUrl != null && wsUrl.trim().isNotEmpty) {
      lines.add('WebSocket URL: $wsUrl');
    }

    final statusUrl = status?.statusUrl ?? derivedStatusUrl;
    if (statusUrl != null && statusUrl.trim().isNotEmpty) {
      lines.add('Status URL: $statusUrl');
    }

    final checkedAt = status?.checkedAt;
    if (checkedAt != null) {
      lines.add('Last checked: ${checkedAt.toIso8601String()}');
    }
    if (status?.serverVersion != null) {
      lines.add('Server version: ${status!.serverVersion}');
    }
    if (status?.protocolVersion != null) {
      lines.add('Protocol version: ${status!.protocolVersion}');
    }
    if (status?.redisConnected != null) {
      lines.add('Redis connected: ${status!.redisConnected}');
    }
    if (status?.activeRooms != null) {
      lines.add('Active rooms: ${status!.activeRooms}');
    }
    if (status?.activeConnections != null) {
      lines.add('Active connections: ${status!.activeConnections}');
    }
    if (status?.message != null && status!.message!.trim().isNotEmpty) {
      lines.add('Message: ${status.message}');
    }
    if (status?.errorCode != null && status!.errorCode!.trim().isNotEmpty) {
      lines.add('Error code: ${status.errorCode}');
    }

    return lines.join('\n');
  }
}
