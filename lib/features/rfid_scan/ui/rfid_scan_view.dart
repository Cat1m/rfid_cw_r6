import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/rfid_scan_controller.dart';
import '../../../scan_screen.dart';

// Import các Widgets con
import 'widgets/rfid_status_bar.dart';
import 'widgets/rfid_control_panel.dart';
import 'widgets/rfid_tag_list.dart';

class RfidScanView extends StatelessWidget {
  const RfidScanView({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch Controller để rebuild khi state thay đổi
    final controller = context.watch<RfidScanController>();
    final isConnected = controller.connectionStatus == 'connected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('R6 Controller'),
        elevation: 2,
        actions: [
          // Nút ngắt kết nối
          if (isConnected)
            IconButton(
              tooltip: "Ngắt kết nối",
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
              onPressed: controller.disconnect,
            ),
          // Nút xóa danh sách
          IconButton(
            tooltip: "Xóa dữ liệu",
            icon: const Icon(Icons.delete_outline),
            onPressed: controller.clearTags,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- PANEL ĐIỀU KHIỂN ---
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. Status Bar (Pin, Kết nối)
                  RfidStatusBar(
                    batteryLevel: controller.batteryLevel,
                    connectionStatus: controller.connectionStatus,
                    onConnectPressed: () async {
                      // Logic điều hướng UI nằm ở View
                      final mac = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                      if (mac != null) {
                        controller.connect(mac);
                      }
                    },
                  ),

                  const Divider(),

                  // 2. Control Panel (Power, RSSI, Buzzer)
                  RfidControlPanel(
                    isConnected: isConnected,
                    currentPower: controller.currentPower,
                    minRssi: controller.minRssiFilter,
                    // Binding Action từ View về Controller
                    onPowerChanged: (val) => controller.setPower(val),
                    onRssiChanged: (val) => controller.setRssiFilter(val),
                    onBuzzerChanged: (enable) =>
                        controller.setHardwareBuzzer(enable),
                  ),
                ],
              ),
            ),
          ),

          // --- DANH SÁCH THẺ ---
          Expanded(child: RfidTagList(tags: controller.tags)),
        ],
      ),

      // --- NÚT QUÉT ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: controller.isScanning ? Colors.red : Colors.blue,
        // Disable nút nếu chưa kết nối
        onPressed: isConnected ? controller.toggleScan : null,
        icon: Icon(controller.isScanning ? Icons.stop : Icons.wifi_tethering),
        label: Text(controller.isScanning ? "DỪNG (STOP)" : "QUÉT (RFID)"),
      ),
    );
  }
}
