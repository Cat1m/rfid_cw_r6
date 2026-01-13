import 'package:flutter/material.dart';
import 'features/rfid_scan/ui/rfid_scan_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RFID R6 Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const RfidScanPage(), // Gọi Container
    );
  }
}
