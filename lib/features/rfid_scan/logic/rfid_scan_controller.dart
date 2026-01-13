import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/rfid_cw_r6/rfid_cw_r6.dart';

class RfidScanController extends ChangeNotifier {
  final RFIDService _service;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _subscription;

  // --- STATE ---
  List<RFIDTag> tags = [];
  String connectionStatus = "Disconnected";
  bool isScanning = false;
  int batteryLevel = 0;
  int currentPower = 30;

  // Config
  double minRssiFilter = -90.0;
  bool isSoundOn = true;
  DateTime? _lastBeepTime;

  RfidScanController({RFIDService? service})
    : _service = service ?? RFIDService();

  // --- LIFECYCLE ---
  Future<void> init() async {
    await _audioPlayer.setSource(AssetSource('sounds/beep_sound.mp3'));
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Lắng nghe Stream Event từ Core
    _subscription = _service.eventStream.listen(_handleEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- EVENT HANDLING ---
  void _handleEvent(RfidEvent event) {
    // Dùng Pattern Matching của Dart 3 (Rất gọn)
    switch (event) {
      case RfidTagDiscovered e:
        _processTag(e.tag);
        break;
      case RfidConnectionStatusChanged e:
        connectionStatus = e.status;
        if (connectionStatus == 'connected') _syncDeviceStatus();
        notifyListeners();
        break;
      case RfidScanningStatusChanged e:
        isScanning = e.isScanning;
        notifyListeners();
        break;
      case RfidErrorEvent e:
        debugPrint("RFID Error: ${e.message}");
        break;
    }
  }

  void _processTag(RFIDTag newTag) {
    log(newTag.toString());
    if (newTag.rssi < minRssiFilter) return;

    _playBeep();

    final index = tags.indexWhere((t) => t.epc == newTag.epc);
    if (index != -1) {
      tags[index] = tags[index].copyWith(
        count: tags[index].count + 1,
        rssi: newTag.rssi, // Update RSSI mới nhất
      );
      // Đưa lên đầu
      final temp = tags.removeAt(index);
      tags.insert(0, temp);
    } else {
      tags.insert(0, newTag);
    }
    notifyListeners();
  }

  void _playBeep() {
    if (!isSoundOn) return;
    final now = DateTime.now();
    if (_lastBeepTime == null ||
        now.difference(_lastBeepTime!).inMilliseconds > 100) {
      _audioPlayer.play(
        AssetSource('sounds/beep_sound.mp3'),
        mode: PlayerMode.lowLatency,
      );
      _lastBeepTime = now;
    }
  }

  Future<void> _syncDeviceStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    batteryLevel = await _service.getBattery();
    currentPower = await _service.getPower();
    notifyListeners();
  }

  // --- PUBLIC ACTIONS ---
  Future<bool> connect(String mac) async {
    return await _service.connect(mac);
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    tags.clear();
    connectionStatus = "Disconnected";
    notifyListeners();
  }

  void toggleScan() {
    if (isScanning) {
      _service.stopScan();
    } else {
      _service.startScan();
    }
  }

  Future<void> setPower(int power) async {
    if (await _service.setPower(power)) {
      currentPower = power;
      notifyListeners();
    }
  }

  void clearTags() {
    tags.clear();
    notifyListeners();
  }

  void setRssiFilter(double value) {
    minRssiFilter = value;
    notifyListeners();
  }

  Future<void> setHardwareBuzzer(bool enable) async {
    await _service.setBuzzer(enable);
  }
}
