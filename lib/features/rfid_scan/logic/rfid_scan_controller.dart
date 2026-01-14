import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
// [QUAN TRỌNG] Import file chứa RfidBluetoothDevice & Event bạn vừa tạo
import 'package:rfid_demo/core/rfid_cw_r6/rfid_event.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_interface.dart';
import '../../../core/rfid_cw_r6/rfid_cw_r6.dart';

class RfidScanController extends ChangeNotifier {
  final IRfidService _service;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _serviceSubscription;

  // --- STATE RFID ---
  List<RFIDTag> tags = [];
  String connectionStatus = "Disconnected";
  bool isInventorying = false;
  int batteryLevel = 0;
  int currentPower = 30;

  // --- STATE BLUETOOTH SCAN (NATIVE) ---
  // [MỚI] Thay ScanResult của FBP bằng Model riêng
  List<RfidBluetoothDevice> scanResults = [];
  bool isDeviceScanning = false;

  // Config
  bool isSoundOn = true;
  DateTime? _lastBeepTime;
  DateTime? _lastTriggerTime;

  RfidScanController({IRfidService? service})
    : _service = service ?? RFIDService();

  // --- LIFECYCLE ---
  Future<void> init() async {
    await _audioPlayer.setSource(AssetSource('sounds/beep_sound.mp3'));

    // Yêu cầu quyền (Vẫn cần thiết)
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Chỉ lắng nghe 1 Stream duy nhất từ Service
    _serviceSubscription = _service.eventStream.listen(_handleServiceEvent);
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- XỬ LÝ EVENT TỪ SERVICE (NATIVE) ---
  void _handleServiceEvent(RfidEvent event) {
    switch (event) {
      // [MỚI] Xử lý khi Native tìm thấy thiết bị Bluetooth
      case RfidDeviceDiscoveredEvent e:
        _handleDeviceDiscovered(e.device);
        break;

      case RfidBatchTagsDiscovered e:
        if (e.tags.isNotEmpty) {
          tags.insertAll(0, e.tags);
          _playBeep();
          notifyListeners();
        }
        break;

      case RfidConnectionStatusChanged e:
        connectionStatus = e.status;
        if (connectionStatus == 'connected') {
          // Khi kết nối thành công, Native thường tự stop scan,
          // nhưng ta update state UI cho chắc.
          isDeviceScanning = false;
          _syncDeviceStatus();
        }
        notifyListeners();
        break;

      case RfidScanningStatusChanged e:
        isInventorying = e.isScanning;
        notifyListeners();
        break;

      case RfidBatteryEvent e:
        batteryLevel = e.level;
        notifyListeners();
        break;

      case RfidPowerEvent e:
        // [FIX HIỂN THỊ] Nếu giá trị quá lớn (VD: 594), ta chia cho 10 hoặc 20
        // tùy theo quy ước của SDK. Tạm thời hiển thị raw.
        currentPower = e.level;
        notifyListeners();
        break;

      case RfidTriggerEvent _:
        _handleHardwareTrigger();
        break;

      default:
        break;
    }
  }

  // Logic thêm thiết bị vào list (tránh trùng lặp)
  void _handleDeviceDiscovered(RfidBluetoothDevice device) {
    final index = scanResults.indexWhere((d) => d.id == device.id);
    if (index >= 0) {
      // Đã có -> Update (VD: RSSI thay đổi)
      scanResults[index] = device;
    } else {
      // Chưa có -> Thêm mới
      scanResults.add(device);
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

  // --- LOGIC TÌM THIẾT BỊ (Discovery - VIA NATIVE) ---

  Future<void> startDeviceScan() async {
    // Reset list
    scanResults.clear();
    isDeviceScanning = true;
    notifyListeners();

    // Gọi lệnh xuống Native
    try {
      await _service.startDiscovery();
    } catch (e) {
      isDeviceScanning = false;
      notifyListeners();
      debugPrint("Error starting scan: $e");
    }
  }

  Future<void> stopDeviceScan() async {
    try {
      await _service.stopDiscovery();
      isDeviceScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error stopping scan: $e");
    }
  }

  // --- PUBLIC ACTIONS (Kết nối & RFID) ---

  // [SỬA] Tham số đầu vào giờ là Model của ta, không phải ScanResult
  Future<void> connect(RfidBluetoothDevice device) async {
    // Stop scan trước khi connect
    await stopDeviceScan();

    // Gọi connect với ID (iOS là UUID, Android là MAC)
    await _service.connect(device.id);
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    tags.clear();
    scanResults.clear();
    // connectionStatus sẽ được update qua Event Stream
  }

  void toggleInventory() {
    if (isInventorying) {
      _service.stopScan();
    } else {
      _service.startScan();
    }
  }

  Future<void> setPower(int power) async {
    if (await _service.setPower(power)) {
      Future.delayed(
        const Duration(milliseconds: 200),
        () => _service.getPower(),
      );
    }
  }

  Future<void> _syncDeviceStatus() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    // Get Battery
    int? bat = await _service.getBattery();
    if (bat == null || bat == 0) {
      await Future.delayed(const Duration(seconds: 1));
      bat = await _service.getBattery();
    }
    if (bat != null && bat > 0) {
      batteryLevel = bat;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Get Power
    int? pow = await _service.getPower();
    if (pow == null || pow == -1) {
      await Future.delayed(const Duration(seconds: 1));
      pow = await _service.getPower();
    }
    if (pow != null && pow > 0) {
      currentPower = pow;
    }
    notifyListeners();
  }

  void clearTags() {
    _service.clearData();
    tags.clear();
    notifyListeners();
  }

  Future<void> setHardwareBuzzer(bool enable) async {
    await _service.setBuzzer(enable);
  }

  void _handleHardwareTrigger() {
    final now = DateTime.now();
    if (_lastTriggerTime != null &&
        now.difference(_lastTriggerTime!).inMilliseconds < 500) {
      return;
    }
    _lastTriggerTime = now;

    if (isInventorying) {
      _service.stopScan();
      isInventorying = false;
    } else {
      _service.startScan();
      isInventorying = true;
    }
    notifyListeners();
  }
}
