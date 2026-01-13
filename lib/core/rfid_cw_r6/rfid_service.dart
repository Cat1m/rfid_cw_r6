// lib/core/rfid_cw_r6/rfid_service.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'rfid_event.dart';
import 'rfid_tag.dart';

class RFIDService {
  // 1. Dependency Injection
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  // --- CẤU HÌNH CHANNEL (Namespace chuẩn Library) ---
  // Định danh module này là thư viện riêng, không phụ thuộc vào tên App "rfid_demo"
  static const String _channelNamespace = 'com.chien.libs.rfid_r6';

  RFIDService({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel('$_channelNamespace/methods'), // Kênh lệnh
      _eventChannel =
          eventChannel ??
          const EventChannel('$_channelNamespace/events'); // Kênh sự kiện

  // --- CONSTANTS COMMANDS ---
  static const String _cmdConnect = 'connect';
  static const String _cmdDisconnect = 'disconnect';
  static const String _cmdStartScan = 'startScan';
  static const String _cmdStopScan = 'stopScan';
  static const String _cmdSetPower = 'setPower';
  static const String _cmdGetPower = 'getPower';
  static const String _cmdGetBattery = 'getBattery';
  static const String _cmdSetCW = 'setCW';
  static const String _cmdSetBuzzer = 'setBuzzer';

  // --- STREAM TRANSFORMER (Core Logic) ---
  Stream<RfidEvent> get eventStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
          final String type = map['type'];

          switch (type) {
            case 'tag':
              return RfidTagDiscovered(_processTagData(map));
            case 'status':
              return RfidScanningStatusChanged(map['scanning'] as bool);
            case 'connection_status':
              return RfidConnectionStatusChanged(map['status'] as String);
            default:
              return RfidErrorEvent('Unknown event type: $type');
          }
        })
        .handleError((error) {
          return RfidErrorEvent(error.toString());
        });
  }

  // Hàm private để làm sạch dữ liệu Tag trước khi đẩy ra UI
  RFIDTag _processTagData(Map<dynamic, dynamic> map) {
    String rawEpc = map['epc'] ?? 'Unknown';
    String cleanEpc = rawEpc;

    // Logic cắt chuỗi 3000...CRC
    if (rawEpc.length >= 28 && rawEpc.startsWith("3000")) {
      cleanEpc = rawEpc.substring(4, 28);
    }
    cleanEpc = cleanEpc.trim().toUpperCase();

    // Copy map cũ nhưng thay EPC bằng EPC sạch để Model parse
    final cleanMap = Map<dynamic, dynamic>.from(map);
    cleanMap['epc'] = cleanEpc;

    return RFIDTag.fromMap(cleanMap);
  }

  // --- METHODS ---

  // Kết nối thiết bị
  Future<bool> connect(String macAddress) async {
    try {
      final bool? result = await _methodChannel.invokeMethod(_cmdConnect, {
        'mac': macAddress,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception("Lỗi kết nối Native: ${e.message}");
    }
  }

  // Ngắt kết nối
  Future<void> disconnect() async {
    await _methodChannel.invokeMethod(_cmdDisconnect);
  }

  // Bắt đầu quét
  Future<void> startScan() async {
    await _methodChannel.invokeMethod(_cmdStartScan);
  }

  // Dừng quét
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod(_cmdStopScan);
  }

  // Cài đặt công suất (5-30)
  Future<bool> setPower(int power) async {
    try {
      if (power < 0 || power > 30) {
        throw ArgumentError("Power must be between 0 and 30");
      }
      final result = await _methodChannel.invokeMethod(_cmdSetPower, {
        'power': power,
      });
      return result == true;
    } catch (e) {
      // Có thể log error vào Crashlytics tại đây
      return false;
    }
  }

  // Lấy công suất hiện tại
  Future<int> getPower() async {
    try {
      final int power = await _methodChannel.invokeMethod(_cmdGetPower);
      return power;
    } catch (e) {
      return -1;
    }
  }

  // Lấy dung lượng pin
  Future<int> getBattery() async {
    try {
      final int battery = await _methodChannel.invokeMethod(_cmdGetBattery);
      return battery;
    } catch (e) {
      return 0;
    }
  }

  // Cấu hình sóng mang (Test mode)
  Future<bool> setCW(int flag) async {
    try {
      return await _methodChannel.invokeMethod(_cmdSetCW, {'flag': flag}) ==
          true;
    } catch (e) {
      return false;
    }
  }

  // Bật tắt tiếng bíp phần cứng
  Future<bool> setBuzzer(bool enable) async {
    try {
      final bool result = await _methodChannel.invokeMethod(_cmdSetBuzzer, {
        'enable': enable,
      });
      return result;
    } catch (e) {
      return false;
    }
  }
}
