// lib/core/rfid_cw_r6/impl/rfid_service_android.dart

import 'dart:developer';

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
        // [MỚI] Xử lý Batch Tags từ Native
        case 'batch_tags':
          final List<dynamic> rawList = map['data'] as List<dynamic>;

          // Native đã lọc trùng và clean rồi, ta chỉ việc map sang Model
          final List<RFIDTag> tags = rawList.map((item) {
            // Lưu ý: Hàm _processTagData dưới đây có thể cần điều chỉnh
            // nếu Native đã clean chuỗi rồi thì không cần clean lại
            return _mapNativeTagToModel(item as Map<dynamic, dynamic>);
          }).toList();

          return RfidBatchTagsDiscovered(tags);

        case 'tag':
          return RfidTagDiscovered(_processTagData(map)); // Logic cũ fallback
        case 'status':
          return RfidScanningStatusChanged(map['scanning'] as bool);
        case 'connection_status':
          return RfidConnectionStatusChanged(map['status'] as String);
        case 'device_discovered':
          return RfidDeviceDiscoveredEvent(
            RfidBluetoothDevice(
              id: map['id'] ?? '',
              name: map['name'] ?? 'Unknown',
              rssi: map['rssi'] ?? 0,
            ),
          );
        default:
          return RfidErrorEvent('Unknown event type Android: $type');
      }
    });
  }

  RFIDTag _mapNativeTagToModel(Map<dynamic, dynamic> map) {
    return RFIDTag.fromMap(map);
  }

  RFIDTag _processTagData(Map<dynamic, dynamic> map) {
    String rawEpc = map['epc'] ?? 'Unknown';
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
  Future<int?> getPower() async {
    // Sửa thành int?
    try {
      final int result = await _methodChannel.invokeMethod('getPower');
      return result;
    } catch (e) {
      return -1;
    }
  }

  @override
  Future<int?> getBattery() async {
    // Sửa thành int?
    try {
      final int result = await _methodChannel.invokeMethod('getBattery');
      return result;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> setBuzzer(bool enable) async {
    return await _methodChannel.invokeMethod('setBuzzer', {'enable': enable}) ??
        false;
  }

  @override
  Future<void> clearData() async {
    await _methodChannel.invokeMethod('clearData');
  }

  @override
  Future<void> startDiscovery() async {
    // Gọi xuống Native để dùng BluetoothLeScanner
    await _methodChannel.invokeMethod('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    await _methodChannel.invokeMethod('stopDiscovery');
  }
}
