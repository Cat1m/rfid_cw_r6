// ignore_for_file: public_member_api_docs, sort_constructors_first
// models/rfid_tag.dart
import 'package:equatable/equatable.dart';

class RFIDTag extends Equatable {
  final String epc;
  final int rssi;
  final int count;
  final String? tid;
  final String? userData;

  const RFIDTag({
    required this.epc,
    required this.rssi,
    this.count = 1,
    this.tid,
    this.userData,
  });

  // Factory chuẩn hóa dữ liệu đầu vào
  factory RFIDTag.fromMap(Map<dynamic, dynamic> map) {
    return RFIDTag(
      epc: map['epc'] ?? 'Unknown',
      // Parse RSSI ngay tại cửa ngõ
      rssi: int.tryParse(map['rssi']?.toString() ?? '') ?? -100,
      tid: map['tid'],
      userData: map['user'],
    );
  }

  // Immutable CopyWith
  RFIDTag copyWith({
    String? epc,
    int? rssi,
    int? count,
    String? tid,
    String? userData,
  }) {
    return RFIDTag(
      epc: epc ?? this.epc,
      rssi: rssi ?? this.rssi,
      count: count ?? this.count,
      tid: tid ?? this.tid,
      userData: userData ?? this.userData,
    );
  }

  // Tăng count bằng cách trả về object mới
  RFIDTag increment({int newRssi = -100}) {
    return copyWith(count: count + 1, rssi: newRssi);
  }

  @override
  List<Object?> get props => [epc, rssi, count, tid, userData];

  @override
  bool get stringify => true;
}
