import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    // Lắng nghe kết quả quét
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });
    // Bắt đầu quét (timeout 5s)
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chọn thiết bị R6")),
      body: ListView.separated(
        itemCount: _scanResults.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          final name = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown Device";
          final id = result.device.remoteId.str; // Đây chính là MAC ADDRESS

          return ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(id),
            trailing: ElevatedButton(
              child: const Text("Chọn"),
              onPressed: () {
                // Dừng quét
                FlutterBluePlus.stopScan();
                // Trả về địa chỉ MAC cho màn hình trước
                Navigator.pop(context, id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
