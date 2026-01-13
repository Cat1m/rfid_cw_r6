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

          default:
            return RfidErrorEvent('Unknown iOS event: $type');
        }
      } catch (e) {
        return RfidErrorEvent("iOS Parse Error ($type): $e");
      }
    });
  }

  // --- LOGIC XỬ LÝ TAG (Copy chuẩn từ Android qua) ---
  RFIDTag _processTagData(Map<dynamic, dynamic> map) {
    String rawEpc = map['epc']?.toString() ?? 'Unknown';
    String rawRssi = map['rssi']?.toString() ?? '-100';
    log(rawEpc);

    // 1. Logic cắt chuỗi 3000...CRC
    if (rawEpc.length >= 28 && rawEpc.startsWith("3000")) {
      rawEpc = rawEpc.substring(4, 28);
    }

    // 2. Chuẩn hóa EPC
    final cleanEpc = rawEpc.trim().toUpperCase();

    // 3. Parse RSSI sang int (FIX: Sửa ở đây)
    // iOS trả về RSSI dạng String (ví dụ "-65"), cần parse ra int (-65)
    final int rssi = int.tryParse(rawRssi) ?? -100;

    // 4. Map vào Model (Giờ rssi đã là int, khớp với Model Equatable)
    return RFIDTag(
      epc: cleanEpc,
      rssi: rssi, // Truyền int vào
      count: 1, // iOS trả từng thẻ nên count = 1
    );
  }

  // --- METHODS (Standardized Keys) ---

  @override
  Future<bool> connect(String deviceId) async {
    // Dùng key 'mac' hoặc 'uuid' thống nhất để bên Native dễ hiểu
    final result = await _methodChannel.invokeMethod('connect', {
      'mac': deviceId, // iOS Native sẽ nhận key này là UUID string
    });
    return result ?? false;
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

  @override
  Future<void> clearData() {
    // TODO: implement clearData
    throw UnimplementedError();
  }
}
