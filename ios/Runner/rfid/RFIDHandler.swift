import Foundation
import CoreBluetooth
import Flutter

// [Lưu ý]: Protocol 'FatScaleBluetoothManager' là tên gốc từ SDK (do NSX đặt nhầm tên),
// KHÔNG ĐƯỢC ĐỔI tên protocol này vì nó map với file Header .h
class RFIDHandler: NSObject, FatScaleBluetoothManager {
    
    // MARK: - Properties
    private var eventSink: FlutterEventSink?
    private var scannedPeripherals: [String: CBPeripheral] = [:]
    private var pendingConnectionUUID: String?
    
    // Cache lưu EPC đã quét (Sử dụng Set để O(1) lookup)
    private var scannedEpcSet = Set<String>()
    
    // Singleton SDK getter
    private var manager: RFIDBlutoothManager? {
        return RFIDBlutoothManager.share()
    }
    
    // MARK: - Init
    override init() {
        super.init()
        // Đăng ký Delegate để nhận callback từ SDK
        manager?.setFatScaleBluetoothDelegate(self)
        print("🔵 iOS RFID: Service Initialized")
    }
    
    
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    
    
    // MARK: - Logic Methods
    
    /// Xóa cache dữ liệu quét
    func clearData() {
            print("🧹 iOS SDK: Manual Clear Data requested")
            scannedEpcSet.removeAll() // Xóa cache của Swift
            manager?.clearAllData()   // Xóa cache của ObjC SDK
        }
    
    /// Bắt đầu tìm kiếm thiết bị Bluetooth
    func startDiscovery() {
        print("ref:StartDiscovery -> iOS RFID: Scanning for devices...")
        scannedPeripherals.removeAll()
        manager?.bleDoScan()
    }
    
    /// Dừng tìm kiếm
    func stopDiscovery() {
        print("ref:StopDiscovery -> iOS RFID: Stop Scanning")
        manager?.closeBleAndDisconnect()
    }
    
    /// Kết nối tới thiết bị theo UUID (Mac Address trên iOS bị ẩn, dùng UUID)
    func connect(address: String) {
        // Case 1: Đã tìm thấy trong lúc scan
        if let peripheral = scannedPeripherals[address] {
            print("ref:Connect -> iOS RFID: Connecting directly to \(address)...")
            manager?.connect(peripheral, macAddress: address)
            return
        }
        
        // Case 2: Chưa thấy (Scan lại để tìm)
        print("ref:Connect -> 🟠 iOS RFID: Device not in cache. Rescanning target \(address)...")
        self.pendingConnectionUUID = address
        manager?.bleDoScan()
        
        // Timeout 10s
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            if self.pendingConnectionUUID == address {
                print("ref:Connect -> 🔴 iOS RFID: Connection Timeout")
                self.stopDiscovery()
                self.pendingConnectionUUID = nil
                self.sendEvent(["type": "connection_status", "status": "timeout"])
            }
        }
    }
    
    func disconnect() {
        manager?.cancelConnectBLE()
        pendingConnectionUUID = nil
    }
    
    /// Bắt đầu đọc thẻ (Inventory)
    func startInventory() {
            print("🟢 iOS SDK: COMMAND -> Start Inventory")
            
            // [QUAN TRỌNG] Gọi lệnh xóa data cũ trước khi quét mới
            // Vì ta đã tách hàm, nên giờ phải gọi thủ công ở đây
            manager?.clearAllData()
            
            // Sau đó mới gửi lệnh quét
            manager?.continuitySaveLabel(withCount: "0")
            
            sendEvent(["type": "status", "scanning": true])
        }
    
    /// Dừng đọc thẻ
    func stopInventory() {
        print("ref:StopScan -> 🔴 iOS RFID: Stop Inventory")
        manager?.stopcontinuitySaveLabel()
        sendEvent(["type": "status", "scanning": false])
    }
    
    func setPower(value: Int) {
        let powerStr = String(value)
        print("ref:SetPower -> 🔵 iOS RFID: Set Power \(powerStr) dBm")
        // SDK yêu cầu cả readStr và writeStr giống nhau để set
        manager?.setLaunchPowerWithstatus("1", antenna: "1", readStr: powerStr, writeStr: powerStr)
    }
    
    func getPower() {
        manager?.getLaunchPower()
    }
    
    func getBattery() {
        manager?.getBatteryLevel()
    }
    
    func setBuzzer(enable: Bool) {
        if enable {
            manager?.setOpenBuzzer()
        } else {
            manager?.setCloseBuzzer()
        }
    }
    
    func setCW(enable: Bool) {
        print("⚠️ iOS RFID: Continuous Wave (CW) not supported directly by this SDK wrapper")
    }

    // MARK: - SDK Delegate Implementation
    
    // 1. Callback khi tìm thấy thiết bị BLE (Scan)
    func receiveData(withBLEmodel model: BLEModel?, result: String?) {
            guard let device = model, let peripheral = device.peripheral else { return }
            
            let uuid = peripheral.identifier.uuidString
            scannedPeripherals[uuid] = peripheral
            
            // Tạo Map để gửi lên Flutter
            let deviceMap: [String: Any] = [
                "name": peripheral.name ?? "Unknown Device",
                "address": uuid, // Flutter dùng cái này làm ID để connect lại
                "rssi": device.rssStr ?? "0"
            ]
            
            // Gửi Event 'device_found' lên Flutter
            sendEvent([
                "type": "device_found",
                "data": deviceMap
            ])
            
            // Logic Auto Connect (Giữ nguyên)
            if let targetUUID = pendingConnectionUUID, targetUUID == uuid {
                print("🟢 iOS RFID: Found target \(uuid). Connecting...")
                stopDiscovery()
                pendingConnectionUUID = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.manager?.connect(peripheral, macAddress: uuid)
                }
            }
        }
    
    // 2. Callback kết nối thành công
    func connectPeripheralSuccess(_ nameStr: String?) {
        print("🟢 iOS RFID: Connection Established")
        sendEvent(["type": "connection_status", "status": "connected"])
        
        // Fetch config sau khi kết nối
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.getBattery()
            self.getPower()
        }
    }
    
    // 3. Callback ngắt kết nối hoặc lỗi
    func connectBluetoothFail(withMessage msg: String?) {
        print("🔴 iOS RFID: Connection Failed/Disconnected - \(msg ?? "Unknown")")
        pendingConnectionUUID = nil
        sendEvent(["type": "connection_status", "status": "disconnected"])
    }
    
    func disConnectPeripheral() {
        print("🔴 iOS RFID: Disconnected")
        sendEvent(["type": "connection_status", "status": "disconnected"])
    }
    
    // 4. Callback nhận dữ liệu thẻ (QUAN TRỌNG NHẤT)
    func receiveData(withBLEDataSource dataSource: NSMutableArray?, allCount: Int, countArr: NSMutableArray?, dataSource1: NSMutableArray?, countArr1: NSMutableArray?, dataSource2: NSMutableArray?, countArr2: NSMutableArray?) {
            
            guard let epcList = dataSource as? [String] else { return }
            let rssiList = dataSource2 as? [String] ?? []
            
            var batchTags = [[String: Any]]()
            
            for (index, rawEpc) in epcList.enumerated() {
                // [LOG DEBUG] In ra chuỗi gốc nhận được
                // print("📥 RAW from SDK: \(rawEpc)")
                
                let cleanEpc = processRawEPC(rawEpc)
                
                // Nếu trả về rỗng (do rác) -> Bỏ qua ngay
                if cleanEpc.isEmpty {
                    // print("🗑️ Ignored Garbage: \(rawEpc)")
                    continue
                }
                
                // Logic Cache: insert trả về (inserted: true) nếu phần tử CHƯA có trong Set
                if scannedEpcSet.insert(cleanEpc).inserted {
                    print("✅ New Tag Found: \(cleanEpc)") // Log này chứng tỏ thẻ được chấp nhận
                    
                    let rssi = index < rssiList.count ? rssiList[index] : "-100"
                    batchTags.append([
                        "epc": cleanEpc,
                        "rssi": rssi,
                        "tid": "",
                        "user": ""
                    ])
                } else {
                    // print("zzz Duplicate ignored: \(cleanEpc)")
                }
            }
            
            if !batchTags.isEmpty {
                sendEvent(["type": "batch_tags", "data": batchTags])
            }
        }
    
    // 5. Callback nhận thông điệp hệ thống (Pin, Trigger, Power...)
    func receiveMessageWithtype(_ typeStr: String?, dataStr: String?) {
        guard let type = typeStr, let data = dataStr else { return }
        
        switch type {
        case "e5": // Battery
            sendEvent(["type": "batteryLevel", "data": data])
        case "13": // Power Get
            sendEvent(["type": "powerLevel", "data": data])
        case "11": // Power Set Success
            print("🔵 iOS RFID: Power Updated Successfully")
            self.getPower() // Refresh UI
        case "e6": // Hardware Trigger (Cò súng)
            sendEvent(["type": "trigger", "data": data])
        default:
            break
        }
    }
    
    // MARK: - Utilities
    
    /// Xử lý chuỗi EPC thô từ SDK
        /// Logic: CHỈ CHẤP NHẬN chuỗi bắt đầu bằng "3000" và đủ độ dài.
        /// Mọi chuỗi khác (như gói tin hệ thống c88c...) sẽ bị coi là rác và loại bỏ.
    private func processRawEPC(_ raw: String) -> String {
            let cleanRaw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // [QUAN TRỌNG] Chỉ chấp nhận chuỗi bắt đầu bằng 3000 VÀ dài trên 24 ký tự
            // Gói tin rác c88c... thường ngắn hoặc không có đầu 3000 -> Sẽ bị loại
            if cleanRaw.count >= 24 && cleanRaw.hasPrefix("3000") {
                
                // Cắt đúng 24 ký tự EPC (bỏ 4 ký tự đầu '3000')
                // Nếu chuỗi dài quá 28, phần đuôi (CRC) sẽ tự động bị bỏ
                let startIndex = cleanRaw.index(cleanRaw.startIndex, offsetBy: 4)
                
                // Đảm bảo không crash nếu chuỗi ngắn hơn dự kiến (Safety Check)
                if let endIndex = cleanRaw.index(startIndex, offsetBy: 24, limitedBy: cleanRaw.endIndex) {
                    let realEPC = String(cleanRaw[startIndex..<endIndex])
                    return realEPC.uppercased()
                }
            }
            
            // Trả về rỗng để báo hiệu đây là RÁC
            return ""
        }
    
    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
}
