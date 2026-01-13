import 'package:flutter/material.dart';

class RfidControlPanel extends StatefulWidget {
  final int currentPower;

  final bool isConnected;
  // Callbacks để báo ngược lại cho Controller
  final Function(int) onPowerChanged;

  final Function(bool) onBuzzerChanged;

  const RfidControlPanel({
    super.key,
    required this.currentPower,

    required this.isConnected,
    required this.onPowerChanged,

    required this.onBuzzerChanged,
  });

  @override
  State<RfidControlPanel> createState() => _RfidControlPanelState();
}

class _RfidControlPanelState extends State<RfidControlPanel> {
  late TextEditingController _powerCtrl;

  @override
  void initState() {
    super.initState();
    _powerCtrl = TextEditingController(text: widget.currentPower.toString());
  }

  // Cập nhật text nếu giá trị từ cha thay đổi (đồng bộ 2 chiều)
  @override
  void didUpdateWidget(covariant RfidControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPower != widget.currentPower) {
      _powerCtrl.text = widget.currentPower.toString();
    }
  }

  @override
  void dispose() {
    _powerCtrl.dispose();
    super.dispose();
  }

  void _handleSetPower() {
    final val = int.tryParse(_powerCtrl.text);
    if (val != null && val >= 5 && val <= 30) {
      widget.onPowerChanged(val);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Power phải từ 5 - 30 dBm")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HARDWARE POWER
        const Text(
          "Hardware Power (5-30 dBm):",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  controller: _powerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "dBm",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: widget.isConnected ? _handleSetPower : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[50],
                foregroundColor: Colors.deepOrange,
              ),
              child: const Text("SET POWER"),
            ),
          ],
        ),

        const Divider(height: 24),

        // 3. HARDWARE BUZZER CONTROL
        const Text(
          "Cấu hình thiết bị (Buzzer):",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.volume_off, size: 18),
                label: const Text("Tắt Tiếng"),
                onPressed: widget.isConnected
                    ? () => widget.onBuzzerChanged(false)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text("Bật Tiếng"),
                onPressed: widget.isConnected
                    ? () => widget.onBuzzerChanged(true)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
