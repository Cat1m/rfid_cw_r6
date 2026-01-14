import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_event.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_interface.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_tag.dart';

class RfidServiceIOS implements IRfidService {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  RfidServiceIOS(this._methodChannel, this._eventChannel);

  @override
  Stream<RfidEvent> get eventStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      final String type = map['type'];

      try {
        switch (type) {
          // Xử lý Batch Tags từ iOS
          case 'batch_tags':
            final List<dynamic> rawList = map['data'] as List<dynamic>;
            final List<RFIDTag> tags = rawList.map((item) {
              // Parse Map thành Model.
              // Lưu ý: iOS Native đã clean chuỗi & lọc trùng rồi.
              return _mapNativeTagToModel(item as Map<dynamic, dynamic>);
            }).toList();
            return RfidBatchTagsDiscovered(tags);

          case 'tag':
            // Xử lý Tag (Đã chuẩn hóa logic cắt chuỗi)
            return RfidTagDiscovered(_processTagData(map));

          case 'status':
            // iOS thường trả về 0/1 hoặc true/false, cần parse cẩn thận
            final isScanning =
                map['scanning'].toString() == 'true' ||
                map['scanning'].toString() == '1';
            return RfidScanningStatusChanged(isScanning);

          case 'connection_status':
            // Map status string cho khớp với Android ("connected", "disconnected")
            return RfidConnectionStatusChanged(map['status'] as String);

          // [QUAN TRỌNG] Nhận dữ liệu Pin từ Stream (Async Response)
          case 'batteryLevel':
            final level = int.tryParse(map['data'].toString()) ?? 0;
            return RfidBatteryEvent(level);

          // [QUAN TRỌNG] Nhận dữ liệu Power từ Stream (Async Response)
          case 'powerLevel':
            final level = int.tryParse(map['data'].toString()) ?? 0;
            return RfidPowerEvent(level);

          case 'trigger':
            return RfidTriggerEvent();

          case 'device_found':
            final data = map['data'];
            // Giả sử data là Map {name: "...", address: "...", rssi: "..."}
            return RfidDeviceDiscoveredEvent(
              RfidBluetoothDevice(
                id: data['address'] ?? 'Unknown',
                name: data['name'] ?? 'Unknown Device',
                rssi: int.tryParse(data['rssi'].toString()) ?? 0,
              ),
            );

          default:
            return RfidErrorEvent('Unknown iOS event: $type');
        }
      } catch (e) {
        return RfidErrorEvent("iOS Parse Error ($type): $e");
      }
    });
  }

  RFIDTag _mapNativeTagToModel(Map<dynamic, dynamic> map) {
    // RSSI từ iOS gửi lên là String, parse an toàn
    int rssi = int.tryParse(map['rssi']?.toString() ?? '') ?? -100;

    // [FIX] Lấy EPC trực tiếp, KHÔNG xử lý logic cắt chuỗi ở đây nữa
    // Vì Native (Swift) đã chịu trách nhiệm làm sạch rồi.
    String epc = map['epc'].toString();

    return RFIDTag(
      epc: epc,
      rssi: rssi,
      count: 1,
      tid: map['tid'],
      userData: map['user'],
    );
  }

  // --- LOGIC XỬ LÝ TAG (Copy chuẩn từ Android qua) ---
  RFIDTag _processTagData(Map<dynamic, dynamic> map) {
    return _mapNativeTagToModel(map);
  }

  // --- METHODS (Standardized Keys) ---

  @override
  Future<bool> connect(String deviceId) async {
    // SỬA LẠI TÊN KEY: 'mac' -> 'address'
    log("Connecting to iOS Device UUID: $deviceId");
    try {
      final result = await _methodChannel.invokeMethod('connect', {
        'address': deviceId,
      });
      return result == true;
    } on PlatformException catch (e) {
      log("iOS Connect Error: ${e.message}");
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _methodChannel.invokeMethod('disconnect');
  }

  @override
  Future<void> startScan() async {
    await _methodChannel.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stopScan');
  }

  @override
  Future<bool> setPower(int power) async {
    // Chuẩn hóa key thành 'power' thay vì 'value'
    final result = await _methodChannel.invokeMethod('setPower', {
      'power': power,
    });
    // iOS trả về true nếu gửi lệnh thành công,
    // còn giá trị power thật sẽ về qua Stream 'powerLevel'
    return result == true;
  }

  // --- ASYNC GETTERS (Trả null ngay, đợi Stream) ---

  @override
  Future<int?> getPower() async {
    // Gửi lệnh đọc -> Native xử lý async
    await _methodChannel.invokeMethod('getPower');
    // Trả về null để Controller biết là "Hãy đợi tin ở Stream"
    return null;
  }

  @override
  Future<int?> getBattery() async {
    await _methodChannel.invokeMethod('getBattery');
    return null;
  }

  @override
  Future<bool> setBuzzer(bool enable) async {
    return await _methodChannel.invokeMethod('setBuzzer', {'enable': enable}) ??
        false;
  }

  // Implement clearData
  @override
  Future<void> clearData() async {
    await _methodChannel.invokeMethod('clearData');
  }

  @override
  Future<void> startDiscovery() async {
    await _methodChannel.invokeMethod('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    await _methodChannel.invokeMethod('stopDiscovery');
  }
}
