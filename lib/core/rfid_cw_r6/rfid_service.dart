// lib/core/rfid_cw_r6/rfid_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_android.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_ios.dart';

import 'rfid_event.dart';
import 'rfid_service_interface.dart';

// THAY ĐỔI LỚN: Thêm "implements IRfidService"
class RFIDService implements IRfidService {
  static const String _channelNamespace = 'com.chien.libs.rfid_r6';

  late final IRfidService _impl;

  RFIDService() {
    const methodChannel = MethodChannel('$_channelNamespace/methods');
    const eventChannel = EventChannel('$_channelNamespace/events');

    if (Platform.isIOS) {
      // Giả sử bạn đã tạo class này (sẽ làm ở bước sau)
      _impl = RfidServiceIOS(methodChannel, eventChannel);
    } else {
      _impl = RfidServiceAndroid(methodChannel, eventChannel);
    }
  }

  // --- OVERRIDE CÁC HÀM TỪ INTERFACE ---
  // Việc thêm @override giúp code an toàn hơn, IDE sẽ nhắc lệnh nếu thiếu hàm

  @override
  Stream<RfidEvent> get eventStream => _impl.eventStream;

  @override
  Future<bool> connect(String id) => _impl.connect(id);

  @override
  Future<void> disconnect() => _impl.disconnect();

  @override
  Future<void> startDiscovery() => _impl.startDiscovery();

  @override
  Future<void> stopDiscovery() => _impl.stopDiscovery();

  @override
  Future<void> startScan() => _impl.startScan();

  @override
  Future<void> stopScan() => _impl.stopScan();

  @override
  Future<bool> setPower(int p) => _impl.setPower(p);

  @override
  Future<int?> getPower() => _impl.getPower();

  @override
  Future<int?> getBattery() => _impl.getBattery();

  @override
  Future<bool> setBuzzer(bool e) => _impl.setBuzzer(e);

  @override
  Future<void> clearData() => _impl.clearData();
}
