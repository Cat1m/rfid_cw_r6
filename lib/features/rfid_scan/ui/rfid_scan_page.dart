import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Cần thêm provider vào pubspec.yaml
import '../logic/rfid_scan_controller.dart';
import 'rfid_scan_view.dart';

class RfidScanPage extends StatelessWidget {
  const RfidScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DI: Cung cấp Controller cho View
    return ChangeNotifierProvider(
      create: (_) => RfidScanController()..init(),
      child: const RfidScanView(),
    );
  }
}
