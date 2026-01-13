// lib/core/rfid_cw_r6/impl/rfid_service_ios.dart

import 'dart:async';
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
      // LOG TOÀN BỘ EVENT NHẬN ĐƯỢC ĐỂ DEBUG
      // print("🎯 iOS Stream Event: $event");

      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      final String type = map['type'];

      try {
        switch (type) {
          case 'tag':
            // Xử lý an toàn cho Tag
            return RfidTagDiscovered(_processTagData(map));

          case 'status':
            final isScanning = map['scanning'] as bool? ?? false;
            return RfidScanningStatusChanged(isScanning);

          case 'connection_status':
            return RfidConnectionStatusChanged(map['status'] as String);

          case 'batteryLevel':
            final level = int.tryParse(map['data'].toString()) ?? 0;
            return RfidBatteryEvent(level);

          case 'powerLevel':
            final level = int.tryParse(map['data'].toString()) ?? 0;
            // print("⚡ Power Update: $level");
            return RfidPowerEvent(level);

          case 'trigger': // [MỚI]
            return RfidTriggerEvent();

          default:
            print("⚠️ iOS Unknown Event: $type");
            return RfidErrorEvent('Unknown iOS event: $type');
        }
      } catch (e, stack) {
        print("❌ Error Parsing Event ($type): $e");
        print(stack);
        return RfidErrorEvent("Parse Error: $e");
      }
    });
  }

  RFIDTag _processTagData(Map<dynamic, dynamic> map) {
    String rawEpc = map['epc']?.toString() ?? 'Unknown';
    String rawRssi = map['rssi']?.toString() ?? '-100';

    // Parse RSSI an toàn (vì iOS có thể trả về string lạ)
    int rssi = int.tryParse(rawRssi) ?? -100;

    // Clean EPC (nếu cần thiết)
    // Ví dụ: Loại bỏ ký tự thừa nếu SDK gửi kèm
    final cleanEpc = rawEpc.trim().toUpperCase();

    // Map lại đúng structure cho Model RFIDTag
    return RFIDTag(
      epc: cleanEpc,
      rssi: rssi,
      count: 1, // iOS trả về từng thẻ đơn lẻ nên count là 1
    );
  }

  @override
  Future<bool> connect(String deviceId) async {
    print("🔌 Connecting to iOS UUID: $deviceId");
    final result = await _methodChannel.invokeMethod('connect', {
      'address': deviceId,
    });
    return result ?? false;
  }

  @override
  Future<void> disconnect() async {
    await _methodChannel.invokeMethod('disconnect');
  }

  @override
  Future<void> startScan() async {
    print("📡 Command: startScan");
    await _methodChannel.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() async {
    print("🛑 Command: stopScan");
    await _methodChannel.invokeMethod('stopScan');
  }

  @override
  Future<bool> setPower(int power) async {
    print("⚡ Command: setPower $power");
    final result = await _methodChannel.invokeMethod('setPower', {
      'value': power,
    });
    // Lưu ý: iOS sẽ không trả về giá trị power mới ngay tại đây
    // Nó sẽ trả về qua Stream event 'powerLevel' sau khi SDK confirm (case "11")
    return result == true;
  }

  @override
  Future<void> getPower() async {
    await _methodChannel.invokeMethod('getPower');
  }

  @override
  Future<void> getBattery() async {
    await _methodChannel.invokeMethod('getBattery');
  }

  @override
  Future<bool> setBuzzer(bool enable) async {
    return await _methodChannel.invokeMethod('setBuzzer', {'enable': enable}) ??
        false;
  }
}
