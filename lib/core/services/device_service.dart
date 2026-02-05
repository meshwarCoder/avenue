import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/observability.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    String deviceId = 'unknown_device_id';

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'unknown_web_agent';
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
        } else if (Platform.isLinux) {
          final linuxInfo = await _deviceInfo.linuxInfo;
          deviceId = linuxInfo.machineId ?? 'unknown_linux_device';
        } else if (Platform.isMacOS) {
          final macInfo = await _deviceInfo.macOsInfo;
          deviceId = macInfo.systemGUID ?? 'unknown_mac_device';
        } else if (Platform.isWindows) {
          final windowsInfo = await _deviceInfo.windowsInfo;
          deviceId = windowsInfo.deviceId;
        }
      }
    } catch (e) {
      AvenueLogger.log(
        event: 'DEVICE_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: e.toString(),
      );
      // Fallback or rethrow depending on requirements.
      // For now, returning a timestamp based ID as fallback to allow non-blocking flow,
      // though persistent ID is preferred.
      deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    return deviceId;
  }
}
