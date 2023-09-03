import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> ensureMicrophonePermission() async {
    return ensureAudioCapturePermission();
  }

  Future<bool> ensureAudioCapturePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> ensureNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited || status.isProvisional;
  }
}
