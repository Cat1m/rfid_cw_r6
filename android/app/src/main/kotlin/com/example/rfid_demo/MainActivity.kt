// File: MainActivity.kt
package com.example.rfid_demo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.rfid_demo.rfid.RFIDFlutterBridge

class MainActivity : FlutterActivity() {

    private var rfidBridge: RFIDFlutterBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Khởi tạo cầu nối giao tiếp
        // Truyền BinaryMessenger để nó tự setup channel
        rfidBridge = RFIDFlutterBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        rfidBridge?.dispose()
        super.onDestroy()
    }
}