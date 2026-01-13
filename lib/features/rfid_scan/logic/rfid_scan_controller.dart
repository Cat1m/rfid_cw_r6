import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // [MỚI] Dùng để quét thiết bị
import 'package:permission_handler/permission_handler.dart';
import '../../../core/rfid_cw_r6/rfid_cw_r6.dart';

class RfidScanController extends ChangeNotifier {
  final RFIDService _service;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _serviceSubscription;
  StreamSubscription? _scanDeviceSubscription;

  // --- STATE RFID ---
  List<RFIDTag> tags = [];
  String connectionStatus = "Disconnected";
  bool isInventorying = false; // Đổi tên cho rõ nghĩa (Đang đọc thẻ)
  int batteryLevel = 0;
  int currentPower = 30;

  // --- STATE BLUETOOTH SCAN ---
  List<ScanResult> scanResults = []; // Danh sách thiết bị tìm thấy
  bool isDeviceScanning = false; // Trạng thái đang tìm thiết bị Bluetooth

  // Config
  double minRssiFilter = -90.0;
  bool isSoundOn = true;
  DateTime? _lastBeepTime;
  DateTime? _lastTriggerTime;

  RfidScanController({RFIDService? service})
    : _service = service ?? RFIDService();

  // --- LIFECYCLE ---
  Future<void> init() async {
    await _audioPlayer.setSource(AssetSource('sounds/beep_sound.mp3'));

    // Yêu cầu quyền
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Lắng nghe Stream Event từ Core Service (Native trả về)
    _serviceSubscription = _service.eventStream.listen(_handleServiceEvent);

    // Lắng nghe trạng thái Scan của FlutterBluePlus
    FlutterBluePlus.isScanning.listen((isScanning) {
      isDeviceScanning = isScanning;
      notifyListeners();
    });
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
      case RfidTagDiscovered e:
        _processTag(e.tag);
        break;

      case RfidConnectionStatusChanged e:
        connectionStatus = e.status;
        if (connectionStatus == 'connected') {
          // Kết nối xong thì dừng quét Bluetooth
          FlutterBluePlus.stopScan();
          _syncDeviceStatus();
        }
        notifyListeners();
        break;

      case RfidScanningStatusChanged e:
        isInventorying = e.isScanning;
        notifyListeners();
        break;

      // [MỚI] Xử lý Pin trả về từ Stream (quan trọng cho iOS)
      case RfidBatteryEvent e:
        batteryLevel = e.level;
        notifyListeners();
        break;

      // [MỚI] Xử lý Power trả về từ Stream (quan trọng cho iOS)
      case RfidPowerEvent e:
        currentPower = e.level;
        notifyListeners();
        break;

      case RfidErrorEvent e:
        debugPrint("RFID Error: ${e.message}");
        break;

      case RfidTriggerEvent e:
        _handleHardwareTrigger();
        break;
    }
  }

  // --- LOGIC XỬ LÝ THẺ ---
  void _processTag(RFIDTag newTag) {
    // log(newTag.toString()); // Comment bớt log cho đỡ lag nếu quét nhiều
    if (newTag.rssi < minRssiFilter) return;

    _playBeep();

    final index = tags.indexWhere((t) => t.epc == newTag.epc);
    if (index != -1) {
      tags[index] = tags[index].copyWith(
        count: tags[index].count + 1,
        rssi: newTag.rssi,
      );
      // Đưa thẻ mới đọc lên đầu danh sách
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
    // Đợi 1 chút để thiết bị ổn định
    await Future.delayed(const Duration(seconds: 1));

    // Gọi lệnh GET, kết quả sẽ trả về qua _handleServiceEvent (Stream)
    // Không dùng await kết quả int ở đây nữa để support iOS Async
    _service.getBattery();
    _service.getPower();
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

    print(
      "🔫 Hardware Trigger Detected! Current State: Scanning=$isInventorying",
    );

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
