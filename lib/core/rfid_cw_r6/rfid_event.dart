import 'rfid_tag.dart';

// Định nghĩa Sealed Class cho các sự kiện từ Native
sealed class RfidEvent {}

// Sự kiện: Tìm thấy 1 thẻ (Logic cũ - Fallback)
class RfidTagDiscovered extends RfidEvent {
  final RFIDTag tag;
  RfidTagDiscovered(this.tag);
}

// Dùng khi Native gửi lên một mảng các thẻ đã lọc trùng
class RfidBatchTagsDiscovered extends RfidEvent {
  final List<RFIDTag> tags;
  RfidBatchTagsDiscovered(this.tags);
}

// Sự kiện: Thay đổi trạng thái kết nối (connected, disconnected)
class RfidConnectionStatusChanged extends RfidEvent {
  final String status;
  RfidConnectionStatusChanged(this.status);
}

// Sự kiện: Thay đổi trạng thái quét (đang quét hay dừng)
class RfidScanningStatusChanged extends RfidEvent {
  final bool isScanning;
  RfidScanningStatusChanged(this.isScanning);
}

// Sự kiện: Lỗi từ Native (nếu có)
class RfidErrorEvent extends RfidEvent {
  final String message;
  RfidErrorEvent(this.message);
}

// Sự kiện: Pin thay đổi
class RfidBatteryEvent extends RfidEvent {
  final int level;
  RfidBatteryEvent(this.level);
}

// Sự kiện: Công suất thay đổi
class RfidPowerEvent extends RfidEvent {
  final int level;
  RfidPowerEvent(this.level);
}

// Sự kiện: Người dùng bấm nút cứng trên thiết bị
class RfidTriggerEvent extends RfidEvent {
  RfidTriggerEvent();
}
