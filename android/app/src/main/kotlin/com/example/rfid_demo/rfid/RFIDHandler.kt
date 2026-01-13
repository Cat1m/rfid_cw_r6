package com.example.rfid_demo.rfid

import android.content.Context
import android.util.Log
import com.rscja.deviceapi.RFIDWithUHFBLE
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.interfaces.ConnectionStatus
import com.rscja.deviceapi.interfaces.ConnectionStatusCallback
import kotlinx.coroutines.* // Cần thêm thư viện coroutines vào build.gradle nếu chưa có

// Interface giữ nguyên
interface RFIDListener {
    fun onEvent(data: Map<String, Any>)
}

class RFIDHandler(private val context: Context, private val listener: RFIDListener) {

    private var rfidSDK: RFIDWithUHFBLE? = null
    private var isScanning = false
    
    // Sử dụng CoroutineScope thay vì Thread truyền thống
    // SupervisorJob giúp crash ở child không làm chết cả scope cha
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var scanJob: Job? = null

    init {
        try {
            rfidSDK = RFIDWithUHFBLE.getInstance()
            rfidSDK?.init(context)
        } catch (e: Exception) {
            Log.e("RFIDHandler", "Init Error: ${e.message}")
        }
    }

    // --- HELPER: HÀM BỌC LOGIC AN TOÀN (DRY) ---
    // Đây là function nhận vào 1 function khác (block) để thực thi
    private fun <T> runSafeCommand(block: () -> T): T {
        val wasScanning = isScanning
        if (wasScanning) {
            stopScan()
            Thread.sleep(200) // Vẫn cần sleep do hạn chế phần cứng SDK, nhưng code gọn hơn
        }

        val result = block()

        if (wasScanning) {
            Thread.sleep(100)
            startScan()
        }
        return result
    }

    // --- CÁC HÀM CHỨC NĂNG (Giờ chỉ còn 1 dòng logic chính) ---

    fun setPower(power: Int): Boolean = runSafeCommand {
        rfidSDK?.setPower(power) ?: false
    }

    fun getPower(): Int = runSafeCommand {
        rfidSDK?.power ?: -1
    }

    fun setBuzzer(enable: Boolean): Boolean = runSafeCommand {
        rfidSDK?.setBeep(enable) ?: false
    }

    fun setCW(flag: Int): Boolean = runSafeCommand {
        try { rfidSDK?.setCW(flag) ?: false } catch (e: Exception) { false }
    }

    // --- LOGIC QUÉT ---

    fun startScan(): Boolean {
        if (rfidSDK?.startInventoryTag() == true) {
            isScanning = true
            sendEvent(mapOf("type" to "status", "scanning" to true))
            startReadingCoroutine() // Chạy Coroutine
            return true
        }
        return false
    }

    fun stopScan(): Boolean {
        isScanning = false
        // Hủy Coroutine ngay lập tức
        scanJob?.cancel()
        val result = rfidSDK?.stopInventory() ?: false
        sendEvent(mapOf("type" to "status", "scanning" to false))
        return result
    }

    // Thay thế Thread bằng Coroutine
    private fun startReadingCoroutine() {
        // Hủy job cũ nếu còn tồn tại
        scanJob?.cancel()
        
        scanJob = scope.launch {
            while (isActive && isScanning) {
                // Đọc dữ liệu (Hàm này blocking nhẹ)
                val listTag = rfidSDK?.readTagFromBufferList()

                if (!listTag.isNullOrEmpty()) {
                    // Xử lý list trả về
                    listTag.forEach { tagInfo ->
                        sendTagToFlutter(tagInfo)
                    }
                }
                // Delay không chặn thread (non-blocking delay)
                delay(50) 
            }
        }
    }

    // --- CONNECTION & EVENTS ---

    private val btStatusCallback = object : ConnectionStatusCallback<Any> {
        override fun getStatus(status: ConnectionStatus, device: Any?) {
            // Dùng Coroutine Dispatchers.Main để post lên UI thread thay vì Handler cũ kỹ
            scope.launch(Dispatchers.Main) {
                val statusStr = if (status == ConnectionStatus.CONNECTED) "connected" else "disconnected"
                sendEvent(mapOf("type" to "connection_status", "status" to statusStr))
                if (status == ConnectionStatus.DISCONNECTED) stopScan()
            }
        }
    }

    fun connect(macAddress: String): Boolean {
        return try {
            rfidSDK?.connect(macAddress, btStatusCallback)
            true
        } catch (e: Exception) {
            Log.e("RFIDHandler", "Connect Error: ${e.message}")
            false
        }
    }
    
    fun disconnect() {
        stopScan()
        rfidSDK?.disconnect()
    }

    fun getBattery(): Int {
        return try {
             val battery = rfidSDK?.battery ?: -1
             if (battery < 0) 0 else battery
        } catch (e: Exception) { 0 }
    }

    private fun sendTagToFlutter(info: UHFTAGInfo) {
        // Map dữ liệu
        val data = mapOf(
            "type" to "tag",
            "epc" to (info.epc ?: "Unknown"),
            "rssi" to (info.rssi ?: "0"),
            "tid" to (info.tid ?: ""),
            "user" to (info.user ?: "")
        )
        // Gửi sang Main Thread
        scope.launch(Dispatchers.Main) {
            listener.onEvent(data)
        }
    }

    fun free() {
        stopScan()
        rfidSDK?.free()
        scope.cancel() // Hủy toàn bộ coroutine khi thoát app để tránh leak memory
    }

    fun setupTriggerListener() {
        rfidSDK?.setKeyEventCallback {
             scope.launch(Dispatchers.Main) {
                if (!isScanning) startScan() else stopScan()
            }
        }
    }
    
    private fun sendEvent(data: Map<String, Any>) {
        listener.onEvent(data)
    }
}