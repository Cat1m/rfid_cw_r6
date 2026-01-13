import 'package:flutter/material.dart';

class RfidStatusBar extends StatelessWidget {
  final int batteryLevel;
  final String connectionStatus;
  final VoidCallback onConnectPressed;

  const RfidStatusBar({
    super.key,
    required this.batteryLevel,
    required this.connectionStatus,
    required this.onConnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connectionStatus == 'connected';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 1. Hiển thị Pin
          Icon(
            Icons.battery_std,
            color: batteryLevel > 20 ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            "$batteryLevel%",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          // 2. Trạng thái / Nút kết nối
          if (!isConnected)
            ElevatedButton.icon(
              onPressed: onConnectPressed,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text("KẾT NỐI"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[800],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "CONNECTED",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
