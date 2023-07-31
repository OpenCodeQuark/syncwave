import 'remote_server_status.dart';
import 'streaming_settings.dart';

bool isInternetBroadcastAvailable(
  StreamingSettings settings,
  RemoteServerStatus status,
) {
  return settings.internetModeConfigured && status.internetBroadcastReady;
}
