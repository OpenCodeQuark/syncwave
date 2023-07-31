import 'package:flutter/foundation.dart';

class ServerHelloEvent {
  const ServerHelloEvent({
    required this.appName,
    required this.appVersion,
    required this.protocolVersion,
    required this.clientPlatform,
    this.serverConnectionPin,
    this.requestId = 'server-hello',
  });

  final String appName;
  final String appVersion;
  final String protocolVersion;
  final String clientPlatform;
  final String? serverConnectionPin;
  final String requestId;

  Map<String, dynamic> toJson() {
    return {
      'type': 'server.hello',
      'requestId': requestId,
      'payload': {
        'appName': appName,
        'appVersion': appVersion,
        'protocolVersion': protocolVersion,
        'clientPlatform': clientPlatform,
        if (serverConnectionPin != null) 'serverConnectionPin': serverConnectionPin,
      },
    };
  }
}

@immutable
class ServerHandshakeResponse {
  const ServerHandshakeResponse({
    required this.type,
    required this.accepted,
    this.serverVersion,
    this.protocolVersion,
    this.capabilities = const <String, dynamic>{},
    this.errorCode,
    this.message,
  });

  final String type;
  final bool accepted;
  final String? serverVersion;
  final String? protocolVersion;
  final Map<String, dynamic> capabilities;
  final String? errorCode;
  final String? message;

  static ServerHandshakeResponse fromEvent(Map<String, dynamic> event) {
    final type = (event['type'] as String?)?.trim() ?? 'error';
    final payload = event['payload'];
    final data = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};

    final accepted = type == 'server.ready';
    return ServerHandshakeResponse(
      type: type,
      accepted: accepted,
      serverVersion: data['serverVersion'] as String?,
      protocolVersion: data['protocolVersion'] as String?,
      capabilities: data['capabilities'] is Map<String, dynamic>
          ? data['capabilities'] as Map<String, dynamic>
          : const <String, dynamic>{},
      errorCode: data['code'] as String?,
      message: data['message'] as String?,
    );
  }
}
