// File: rfid/RFIDFlutterBridge.kt
package com.example.rfid_demo.rfid

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Class này chịu trách nhiệm giao tiếp giữa Flutter và Native
class RFIDFlutterBridge(
    context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, RFIDListener {

    private val rfidHandler: RFIDHandler = RFIDHandler(context, this)
    private val methodChannel: MethodChannel = MethodChannel(messenger, Constants.CHANNEL_COMMAND)
    private val eventChannel: EventChannel = EventChannel(messenger, Constants.CHANNEL_EVENT)
    
    private var eventSink: EventChannel.EventSink? = null
    private val uiHandler = Handler(Looper.getMainLooper())

    init {
        // Đăng ký lắng nghe
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        
        // Setup nút cứng
        rfidHandler.setupTriggerListener()
    }

    // --- XỬ LÝ LỆNH TỪ FLUTTER (MethodChannel) ---
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Constants.CMD_CONNECT -> {
                val mac = call.argument<String>("mac")
                if (mac != null) {
                    result.success(rfidHandler.connect(mac))
                } else {
                    result.error("ARGS_ERROR", "MAC address required", null)
                }
            }
            Constants.CMD_DISCONNECT -> {
                rfidHandler.disconnect()
                result.success(true)
            }
            Constants.CMD_START_SCAN -> result.success(rfidHandler.startScan())
            Constants.CMD_STOP_SCAN -> result.success(rfidHandler.stopScan())
            
            // Các lệnh cấu hình
            Constants.CMD_SET_POWER -> {
                val power = call.argument<Int>("power") ?: 30
                result.success(rfidHandler.setPower(power))
            }
            Constants.CMD_GET_POWER -> result.success(rfidHandler.getPower())
            Constants.CMD_GET_BATTERY -> result.success(rfidHandler.getBattery())
            
            Constants.CMD_SET_CW -> {
                val flag = call.argument<Int>("flag") ?: 0
                result.success(rfidHandler.setCW(flag))
            }
            Constants.CMD_SET_BUZZER -> {
                val enable = call.argument<Boolean>("enable") ?: true
                result.success(rfidHandler.setBuzzer(enable))
            }

            else -> result.notImplemented()
        }
    }

    // --- XỬ LÝ STREAM SỰ KIỆN (EventChannel) ---
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // --- NHẬN DATA TỪ RFIDHandler -> ĐẨY VỀ FLUTTER ---
    override fun onEvent(data: Map<String, Any>) {
        // Đảm bảo chạy trên Main Thread khi gửi về Flutter
        uiHandler.post {
            eventSink?.success(data)
        }
    }

    // Dọn dẹp khi App đóng
    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        rfidHandler.free()
    }
}