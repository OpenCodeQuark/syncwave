import '../../../core/network/signaling_web_socket_client.dart';

class RemoteSignalingClient {
  RemoteSignalingClient(this._client);

  final SignalingWebSocketClient _client;

  Stream<Map<String, dynamic>> connect(String serverUrl) {
    return _client.connect(serverUrl);
  }

  void sendEvent(Map<String, dynamic> event) {
    _client.send(event);
  }

  Future<void> disconnect() {
    return _client.close();
  }
}
