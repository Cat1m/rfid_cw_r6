// lib/core/rfid_cw_r6/rfid_service_interface.dart

import 'package:flutter/services.dart';
import 'rfid_event.dart';

abstract class IRfidService {
  Stream<RfidEvent> get eventStream;

  Future<bool> connect(String deviceId);
  Future<void> disconnect();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> setPower(int power);
  Future<void> getPower(); // Đổi thành void vì kết quả trả về qua Stream
  Future<void> getBattery(); // Đổi thành void vì kết quả trả về qua Stream
  Future<bool> setBuzzer(bool enable);
}
