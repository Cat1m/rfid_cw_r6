import 'rfid_tag.dart';

// Định nghĩa Sealed Class cho các sự kiện từ Native
sealed class RfidEvent {}

// Sự kiện: Tìm thấy thẻ
class RfidTagDiscovered extends RfidEvent {
  final RFIDTag tag;
  RfidTagDiscovered(this.tag);
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
