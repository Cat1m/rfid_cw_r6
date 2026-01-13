import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../logic/rfid_scan_controller.dart';

// Giả định các widgets này đã tồn tại như bạn yêu cầu
import 'widgets/rfid_status_bar.dart';
import 'widgets/rfid_control_panel.dart';
import 'widgets/rfid_tag_list.dart';

class RfidScanView extends StatelessWidget {
  const RfidScanView({super.key});

  @override
  Widget build(BuildContext context) {
    // Không dùng context.watch ở đây để tránh rebuild toàn bộ Scaffold khi đọc thẻ
    return Scaffold(
      appBar: AppBar(
        title: const Text('R6 Controller'),
        elevation: 2,
        actions: [
          // Selector chỉ rebuild nút ngắt kết nối khi trạng thái thay đổi
          Selector<RfidScanController, String>(
            selector: (_, ctrl) => ctrl.connectionStatus,
            builder: (context, status, _) {
              if (status == 'connected') {
                return IconButton(
                  tooltip: "Ngắt kết nối",
                  icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
                  onPressed: () =>
                      context.read<RfidScanController>().disconnect(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            tooltip: "Xóa dữ liệu",
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<RfidScanController>().clearTags(),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. PANEL ĐIỀU KHIỂN ---
          Consumer<RfidScanController>(
            builder: (context, controller, child) {
              final isConnected = controller.connectionStatus == 'connected';

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      RfidStatusBar(
                        batteryLevel: controller.batteryLevel,
                        connectionStatus: controller.connectionStatus,
                        onConnectPressed: () {
                          _showDeviceListBottomSheet(context, controller);
                        },
                      ),
                      const Divider(),

                      IgnorePointer(
                        ignoring: !isConnected,
                        child: Opacity(
                          opacity: isConnected ? 1.0 : 0.5,
                          child: RfidControlPanel(
                            isConnected: isConnected,
                            currentPower: controller.currentPower,
                            // [FIX] Xóa tham số minRssi và callback
                            onPowerChanged: (val) => controller.setPower(val),
                            onBuzzerChanged: (enable) =>
                                controller.setHardwareBuzzer(enable),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // --- 2. DANH SÁCH THẺ RFID ---
          Expanded(
            child: Consumer<RfidScanController>(
              builder: (context, controller, child) {
                // Khi tags thay đổi, Consumer sẽ vẽ lại ngay lập tức
                return RfidTagList(tags: controller.tags);
              },
            ),
          ),
        ],
      ),

      // --- 3. NÚT QUÉT (INVENTORY) ---
      floatingActionButton: Consumer<RfidScanController>(
        builder: (context, controller, child) {
          final isConnected = controller.connectionStatus == 'connected';
          final isScanning = controller.isInventorying;

          return FloatingActionButton.extended(
            backgroundColor: isScanning ? Colors.red : Colors.blue,
            // Nếu chưa kết nối thì disable nút
            onPressed: isConnected ? controller.toggleInventory : null,
            icon: Icon(
              isScanning ? Icons.stop : Icons.wifi_tethering,
              color: Colors.white,
            ),
            label: Text(
              isScanning ? "DỪNG (STOP)" : "QUÉT (RFID)",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER: HIỆN DANH SÁCH BLUETOOTH ---
  void _showDeviceListBottomSheet(
    BuildContext context,
    RfidScanController controller,
  ) {
    // 1. Start Scan ngay lập tức
    controller.startDeviceScan();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Để bo góc đẹp hơn
      builder: (ctx) {
        // [FIX] Dùng Provider.value để truyền controller vào context của BottomSheet
        return ChangeNotifierProvider.value(
          value: controller,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Consumer<RfidScanController>(
                  builder: (context, ctrl, _) {
                    return Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Chọn thiết bị R6",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (ctrl.isDeviceScanning)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: ctrl.startDeviceScan,
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // List Devices
                        Expanded(
                          child: ctrl.scanResults.isEmpty
                              ? Center(
                                  child: Text(
                                    ctrl.isDeviceScanning
                                        ? "Đang tìm thiết bị..."
                                        : "Không tìm thấy thiết bị nào.",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.separated(
                                  controller:
                                      scrollController, // [QUAN TRỌNG] Để kéo thả
                                  itemCount: ctrl.scanResults.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final result = ctrl.scanResults[index];
                                    final device = result.device;

                                    // [FIX] Xử lý tên thiết bị an toàn hơn
                                    final name = device.platformName.isNotEmpty
                                        ? device.platformName
                                        : "N/A (${device.remoteId.str})";

                                    return ListTile(
                                      leading: const Icon(
                                        Icons.bluetooth_audio,
                                        size: 30,
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${device.remoteId.str}\nRSSI: ${result.rssi} dBm",
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        // 2. Kết nối và đóng sheet
                                        ctrl.connect(result);
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      // 3. Luôn dừng quét Bluetooth khi đóng BottomSheet để tiết kiệm pin
      controller.stopDeviceScan();
    });
  }
}
