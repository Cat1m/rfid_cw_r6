// lib/core/rfid_cw_r6/rfid_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_android.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_ios.dart';
import 'rfid_event.dart';
import 'rfid_service_interface.dart';

class RFIDService {
  static const String _channelNamespace = 'com.chien.libs.rfid_r6';

  late final IRfidService _impl;

  RFIDService() {
    const methodChannel = MethodChannel('$_channelNamespace/methods');
    const eventChannel = EventChannel('$_channelNamespace/events');

    if (Platform.isIOS) {
      _impl = RfidServiceIOS(methodChannel, eventChannel);
    } else {
      _impl = RfidServiceAndroid(methodChannel, eventChannel);
    }
  }

  // Proxy các hàm sang Implementation tương ứng
  Stream<RfidEvent> get eventStream => _impl.eventStream;
  Future<bool> connect(String id) => _impl.connect(id);
  Future<void> disconnect() => _impl.disconnect();
  Future<void> startScan() => _impl.startScan();
  Future<void> stopScan() => _impl.stopScan();
  Future<bool> setPower(int p) => _impl.setPower(p);
  Future<void> getPower() => _impl.getPower();
  Future<void> getBattery() => _impl.getBattery();
  Future<bool> setBuzzer(bool e) => _impl.setBuzzer(e);
}
