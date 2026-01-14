// lib/core/rfid_cw_r6/rfid_service_interface.dart

import 'rfid_event.dart';

abstract class IRfidService {
  Stream<RfidEvent> get eventStream;

  Future<bool> connect(String deviceId);
  Future<void> disconnect();
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> setPower(int power);
  Future<int?> getPower();
  Future<int?> getBattery();
  Future<bool> setBuzzer(bool enable);
  Future<void> clearData();
}
