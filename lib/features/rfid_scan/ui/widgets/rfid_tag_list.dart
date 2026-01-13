import 'package:flutter/material.dart';
import '../../../../core/rfid_cw_r6/rfid_cw_r6.dart';

class RfidTagList extends StatelessWidget {
  final List<RFIDTag> tags;

  const RfidTagList({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Center(
        child: Text("Chưa có thẻ nào", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final rssi = tag.rssi;
        final color = rssi > -60
            ? Colors.green
            : (rssi > -80 ? Colors.orange : Colors.grey);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(Icons.nfc, color: color),
            title: Text(
              "EPC: ${tag.epc}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("RSSI: ${tag.rssi} dBm"),
                if (tag.tid != null && tag.tid!.isNotEmpty)
                  Text(
                    "TID: ${tag.tid}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
            trailing: CircleAvatar(
              radius: 15,
              child: Text("${tag.count}", style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}
