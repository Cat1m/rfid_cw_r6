// lib/core/rfid_cw_r6/impl/rfid_service_android.dart

import 'package:flutter/services.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_event.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_interface.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_tag.dart';

class RfidServiceAndroid implements IRfidService {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  RfidServiceAndroid(this._methodChannel, this._eventChannel);

  @override
  Stream<RfidEvent> get eventStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      final String type = map['type'];
      switch (type) {
        case 'tag':
          return RfidTagDiscovered(_processTagData(map));
        case 'status':
          return RfidScanningStatusChanged(map['scanning'] as bool);
        case 'connection_status':
          return RfidConnectionStatusChanged(map['status'] as String);
        // Android có thể trả về pin/power trực tiếp hoặc qua event khác
        // Giữ nguyên logic cũ của bạn ở đây
        default:
          return RfidErrorEvent('Unknown event type Android: $type');
      }
    });
  }

  RFIDTag _processTagData(Map<dynamic, dynamic> map) {
    String rawEpc = map['epc'] ?? 'Unknown';
    // ... Logic cắt chuỗi EPC giữ nguyên ...
    if (rawEpc.length >= 28 && rawEpc.startsWith("3000")) {
      rawEpc = rawEpc.substring(4, 28);
    }
    final cleanMap = Map<dynamic, dynamic>.from(map);
    cleanMap['epc'] = rawEpc.trim().toUpperCase();
    return RFIDTag.fromMap(cleanMap);
  }

  @override
  Future<bool> connect(String deviceId) async {
    // Android dùng key 'mac'
    final result = await _methodChannel.invokeMethod('connect', {
      'mac': deviceId,
    });
    return result ?? false;
  }

  @override
  Future<void> disconnect() async =>
      await _methodChannel.invokeMethod('disconnect');

  @override
  Future<void> startScan() async =>
      await _methodChannel.invokeMethod('startScan');

  @override
  Future<void> stopScan() async =>
      await _methodChannel.invokeMethod('stopScan');

  @override
  Future<bool> setPower(int power) async {
    final result = await _methodChannel.invokeMethod('setPower', {
      'power': power,
    });
    return result == true;
  }

  @override
  Future<void> getPower() async =>
      await _methodChannel.invokeMethod('getPower');

  @override
  Future<void> getBattery() async =>
      await _methodChannel.invokeMethod('getBattery');

  @override
  Future<bool> setBuzzer(bool enable) async {
    return await _methodChannel.invokeMethod('setBuzzer', {'enable': enable}) ??
        false;
  }
}
