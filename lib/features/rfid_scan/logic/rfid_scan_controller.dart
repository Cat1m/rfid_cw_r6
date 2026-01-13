import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // [MỚI] Dùng để quét thiết bị
import 'package:permission_handler/permission_handler.dart';
import 'package:rfid_demo/core/rfid_cw_r6/rfid_service_interface.dart';
import '../../../core/rfid_cw_r6/rfid_cw_r6.dart';

class RfidScanController extends ChangeNotifier {
  final IRfidService _service;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _serviceSubscription;
  StreamSubscription? _scanDeviceSubscription;

  // --- STATE RFID ---
  List<RFIDTag> tags = []; // List hiển thị UI
  String connectionStatus = "Disconnected";
  bool isInventorying = false;
  int batteryLevel = 0;
  int currentPower = 30;

  // --- STATE BLUETOOTH SCAN ---
  List<ScanResult> scanResults = [];
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
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    _serviceSubscription = _service.eventStream.listen(_handleServiceEvent);
    FlutterBluePlus.isScanning.listen((isScanning) {
      isDeviceScanning = isScanning;
      notifyListeners();
    });
    // Không cần Timer nữa vì Native đã lọc trùng
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    _scanDeviceSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- XỬ LÝ EVENT TỪ SERVICE (NATIVE) ---
  void _handleServiceEvent(RfidEvent event) {
    switch (event) {
      case RfidBatchTagsDiscovered e:
        // Vì Native chỉ gửi thẻ mới tinh, ta chỉ việc thêm vào đầu danh sách
        if (e.tags.isNotEmpty) {
          tags.insertAll(0, e.tags);
          _playBeep();
          notifyListeners(); // Update UI ngay lập tức
        }
        break;

      case RfidTagDiscovered _:
        // Logic cũ nếu cần (nhưng nên bỏ để tránh conflict)
        break;

      // Các case status khác thì notify ngay lập tức vì nó ít xảy ra
      case RfidConnectionStatusChanged e:
        connectionStatus = e.status;
        if (connectionStatus == 'connected') {
          FlutterBluePlus.stopScan();
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

  void _playBeep() {
    if (!isSoundOn) return;
    final now = DateTime.now();
    // Debounce âm thanh 100ms
    if (_lastBeepTime == null ||
        now.difference(_lastBeepTime!).inMilliseconds > 100) {
      _audioPlayer.play(
        AssetSource('sounds/beep_sound.mp3'),
        mode: PlayerMode.lowLatency,
      );
      _lastBeepTime = now;
    }
  }

  // --- LOGIC TÌM THIẾT BỊ (Discovery) ---
  // Dùng FlutterBluePlus để quét vì nó ngon, UI mượt
  Future<void> startDeviceScan() async {
    scanResults.clear();
    notifyListeners();

    // Lắng nghe kết quả
    _scanDeviceSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Filter chỉ lấy thiết bị có tên (Optional)
      scanResults = results
          .where((r) => r.device.platformName.isNotEmpty)
          .toList();
      notifyListeners();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  Future<void> stopDeviceScan() async {
    await FlutterBluePlus.stopScan();
  }

  // --- PUBLIC ACTIONS (Kết nối & RFID) ---

  Future<void> connect(ScanResult scanResult) async {
    // Stop scan trước khi connect cho ổn định
    await stopDeviceScan();

    // Lấy ID: Android là MAC, iOS là UUID (remoteId.str lo việc này)
    String deviceId = scanResult.device.remoteId.str;

    // Gọi xuống Service (Logic Platform Specific sẽ tự xử lý ID này)
    await _service.connect(deviceId);
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    tags.clear();
    scanResults.clear();
    connectionStatus = "Disconnected";
    notifyListeners();
  }

  // Bật/Tắt chế độ đọc thẻ (Inventory)
  void toggleInventory() {
    if (isInventorying) {
      _service.stopScan();
    } else {
      _service.startScan();
    }
  }

  Future<void> setPower(int power) async {
    // Gửi lệnh set
    if (await _service.setPower(power)) {
      // iOS sẽ update qua Stream, Android update luôn ở đây cũng được
      // nhưng để đồng bộ, ta nên gọi getPower() ngay sau đó
      Future.delayed(
        const Duration(milliseconds: 200),
        () => _service.getPower(),
      );
    }
  }

  // Đồng bộ trạng thái Pin/Nguồn
  Future<void> _syncDeviceStatus() async {
    // Tăng delay ban đầu để thiết bị ổn định sau khi kết nối
    await Future.delayed(const Duration(milliseconds: 2500));

    // 1. LẤY PIN (BATTERY)
    int? bat = await _service.getBattery();
    // Retry logic: Nếu thất bại, thử lại sau 1s
    if (bat == null || bat == 0) {
      await Future.delayed(const Duration(seconds: 1));
      bat = await _service.getBattery();
    }

    if (bat != null && bat > 0) {
      batteryLevel = bat;
    }

    // Nghỉ 1 nhịp để tránh nghẽn lệnh Bluetooth
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. LẤY POWER (FIX: Thêm biến hứng giá trị)
    int? pow = await _service.getPower(); // <-- SỬA Ở ĐÂY: Hứng giá trị về

    // Retry logic cho Power
    if (pow == null || pow == -1) {
      await Future.delayed(const Duration(seconds: 1));
      pow = await _service.getPower();
    }

    if (pow != null && pow > 0) {
      currentPower = pow;
      // Cập nhật UI (Text Controller nếu cần)
      // notifyListeners() ở dưới sẽ lo việc hiển thị
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

  // 🔥 Hàm xử lý riêng cho Trigger
  void _handleHardwareTrigger() {
    final now = DateTime.now();

    // 1. Debounce: Nếu event đến quá nhanh (< 500ms) so với lần trước thì bỏ qua
    // Mục đích: Tránh việc bấm 1 cái mà code chạy Toggle 2 lần (thành ra không làm gì)
    if (_lastTriggerTime != null &&
        now.difference(_lastTriggerTime!).inMilliseconds < 500) {
      return;
    }
    _lastTriggerTime = now;

    // 2. Logic Toggle (Đảo trạng thái)
    if (isInventorying) {
      // Nếu đang quét -> Gửi lệnh Dừng
      _service.stopScan();
      // Optimistic update (Cập nhật UI ngay cho mượt, đợi Native confirm sau)
      isInventorying = false;
      notifyListeners();
    } else {
      // Nếu đang dừng -> Gửi lệnh Quét
      _service.startScan();
      isInventorying = true;
      notifyListeners();
    }
  }
}
