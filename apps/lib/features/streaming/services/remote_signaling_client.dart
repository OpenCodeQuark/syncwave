import '../../../core/network/signaling_web_socket_client.dart';

abstract class RemoteSignalingGateway {
  Stream<Map<String, dynamic>> connect(String serverUrl);

  void sendEvent(Map<String, dynamic> event);

  Future<void> disconnect();
}

class RemoteSignalingClient implements RemoteSignalingGateway {
  RemoteSignalingClient(this._client);

  final SignalingWebSocketClient _client;

  @override
  Stream<Map<String, dynamic>> connect(String serverUrl) {
    return _client.connect(serverUrl);
  }

  @override
  void sendEvent(Map<String, dynamic> event) {
    _client.send(event);
  }

  @override
  Future<void> disconnect() {
    return _client.close();
  }
}
