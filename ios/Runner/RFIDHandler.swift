import Foundation
import CoreBluetooth
import Flutter

class RFIDHandler: NSObject, FatScaleBluetoothManager {
    
    // MARK: - Properties
    private var eventSink: FlutterEventSink?
    private var scannedPeripherals: [String: CBPeripheral] = [:]
    private var pendingConnectionUUID: String?

    //Cache lưu EPC đã quét (Tương tự HashSet bên Android)
    private var scannedEpcSet = Set<String>()
    
    // Singleton SDK
    private var manager: RFIDBlutoothManager? {
        return RFIDBlutoothManager.share()
    }
    
    // MARK: - Init
    override init() {
        super.init()
        // Đăng ký Delegate
        manager?.setFatScaleBluetoothDelegate(self)
        print("🔵 iOS SDK: Initialized RFIDHandler")
    }
    
    // Thiết lập EventSink từ Plugin truyền sang
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    // MARK: - Logic Methods (Called by Plugin)

    // Hàm xóa Cache
    func clearData() {
        print("🔵 iOS SDK: Clearing EPC Cache")
        scannedEpcSet.removeAll()
    }
    
    func startDiscovery() {
        print("🔵 iOS SDK: Start Discovery")
        scannedPeripherals.removeAll()
        manager?.bleDoScan()
    }
    
    func stopDiscovery() {
        print("🔵 iOS SDK: Stop Discovery")
        manager?.closeBleAndDisconnect()
    }
    
    func connect(address: String) {
        if let peripheral = scannedPeripherals[address] {
            print("🔵 iOS SDK: Connecting to \(address)...")
            manager?.connect(peripheral, macAddress: address)
        } else {
            print("🟠 iOS SDK: Peripheral not found in cache. Rescanning target \(address)...")
            self.pendingConnectionUUID = address
            manager?.bleDoScan()
            
            // Timeout logic
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if self.pendingConnectionUUID == address {
                    print("🔴 iOS SDK: Connection Timeout")
                    self.stopDiscovery()
                    self.pendingConnectionUUID = nil
                    self.sendEvent(["type": "connection_status", "status": "timeout"])
                }
            }
        }
    }
    
    func disconnect() {
        manager?.cancelConnectBLE()
        pendingConnectionUUID = nil
    }
    
    func startInventory() {
        print("🟢 iOS SDK: COMMAND -> Start Inventory")
        manager?.continuitySaveLabel(withCount: "0")
        sendEvent(["type": "status", "scanning": true])
    }
    
    func stopInventory() {
        print("🔴 iOS SDK: COMMAND -> Stop Inventory")
        manager?.stopcontinuitySaveLabel()
        sendEvent(["type": "status", "scanning": false])
    }
    
    func setPower(value: Int) {
        let powerStr = String(value)
        print("🔵 iOS SDK: COMMAND -> Set Power to \(powerStr)")
        manager?.setLaunchPowerWithstatus("1", antenna: "1", readStr: powerStr, writeStr: powerStr)
    }
    
    func getPower() {
        manager?.getLaunchPower()
    }
    
    func getBattery() {
        manager?.getBatteryLevel()
    }
    
    func setBuzzer(enable: Bool) {
        print("🔵 iOS SDK: COMMAND -> Set Buzzer \(enable)")
        if enable {
            manager?.setOpenBuzzer()
        } else {
            manager?.setCloseBuzzer()
        }
    }
    
    // Placeholder cho lệnh CW nếu cần
    func setCW(enable: Bool) {
        // Implement nếu SDK hỗ trợ
        print("⚠️ iOS SDK: setCW not implemented yet")
    }

    // MARK: - Delegate Methods (SDK Callbacks)
    
    // 1. Tìm thấy thiết bị Bluetooth
    func receiveData(withBLEmodel model: BLEModel?, result: String?) {
        guard let device = model, let peripheral = device.peripheral else { return }
        let uuid = peripheral.identifier.uuidString
        scannedPeripherals[uuid] = peripheral
        
        // Logic tự động kết nối lại
        if let targetUUID = pendingConnectionUUID, targetUUID == uuid {
            print("🟢 iOS SDK: Found target \(uuid). Connecting...")
            stopDiscovery()
            pendingConnectionUUID = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.manager?.connect(peripheral, macAddress: uuid)
            }
        }
    }
    
    // 2. Kết nối thành công
    func connectPeripheralSuccess(_ nameStr: String?) {
        print("🟢 iOS SDK: Connected Success")
        sendEvent(["type": "connection_status", "status": "connected"])
        
        // Lấy config mặc định
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.getBattery()
            self.getPower()
        }
    }
    
    // 3. Ngắt kết nối / Lỗi
    func connectBluetoothFail(withMessage msg: String?) {
        print("🔴 iOS SDK: Disconnected/Fail - \(msg ?? "")")
        pendingConnectionUUID = nil
        sendEvent(["type": "connection_status", "status": "disconnected"])
    }
    
    func disConnectPeripheral() {
        print("🔴 iOS SDK: Disconnected (Callback)")
        sendEvent(["type": "connection_status", "status": "disconnected"])
    }
    
    // 4. Nhận dữ liệu thẻ (Main)
    func receiveData(withBLEDataSource dataSource: NSMutableArray?, allCount: Int, countArr: NSMutableArray?, dataSource1: NSMutableArray?, countArr1: NSMutableArray?, dataSource2: NSMutableArray?, countArr2: NSMutableArray?) {
        
        // dataSource chứa danh sách EPC (NSArray)
        // dataSource2 chứa danh sách RSSI (NSArray)
        guard let epcList = dataSource as? [String] else { return }
        let rssiList = dataSource2 as? [String] ?? []
        
        // Mảng chứa các thẻ MỚI và DUY NHẤT trong đợt quét này
        var batchTags = [[String: Any]]()
        
        for (index, rawEpc) in epcList.enumerated() {
            // 1. CLEANING STRING (Giống Android)
            var cleanEpc = rawEpc
            
            // Logic: Nếu bắt đầu bằng "3000" và dài >= 28 ký tự
            if cleanEpc.count >= 28 && cleanEpc.hasPrefix("3000") {
                cleanEpc = String(cleanEpc.dropFirst(4))
            }
            // Chuẩn hóa
            cleanEpc = cleanEpc.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            
            // 2. FILTER UNIQUE (Lọc trùng)
            // .insert trả về (inserted: Bool, memberAfterInsert: String)
            // Nếu inserted == true nghĩa là thẻ này chưa từng có trong Set -> Xử lý
            if !cleanEpc.isEmpty && scannedEpcSet.insert(cleanEpc).inserted {
                
                // Lấy RSSI tương ứng (hoặc mặc định -100)
                var rssi = "-100"
                if index < rssiList.count {
                    rssi = rssiList[index]
                }
                
                // Đóng gói vào Batch
                let tagMap: [String: Any] = [
                    "epc": cleanEpc,
                    "rssi": rssi,
                    "tid": "",  // iOS SDK hiện tại chưa trả TID ở callback này
                    "user": ""
                ]
                batchTags.append(tagMap)
            }
        }
        
        // 3. GỬI BATCH (Nếu có thẻ mới)
        if !batchTags.isEmpty {
            sendEvent([
                "type": "batch_tags",
                "data": batchTags
            ])
        }
    }
    
    // 5. Fallback nhận data
    func receiveData(with parseModel: Any?, dataSource: NSMutableArray?) {
        if let list = dataSource as? [String] {
            var batchTags = [[String: Any]]()
            
            for rawEpc in list {
                var cleanEpc = rawEpc
                if cleanEpc.count >= 28 && cleanEpc.hasPrefix("3000") {
                    cleanEpc = String(cleanEpc.dropFirst(4))
                }
                cleanEpc = cleanEpc.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

                if !cleanEpc.isEmpty && scannedEpcSet.insert(cleanEpc).inserted {
                    batchTags.append(["epc": cleanEpc, "rssi": "-100"])
                }
            }
            
            if !batchTags.isEmpty {
                sendEvent(["type": "batch_tags", "data": batchTags])
            }
        }
    }

    // 6. Nhận tin nhắn hệ thống (Pin, Trigger e6...)
    func receiveMessageWithtype(_ typeStr: String?, dataStr: String?) {
        guard let type = typeStr, let data = dataStr else { return }
        
        switch type {
        case "e5": // Pin
            sendEvent(["type": "batteryLevel", "data": data])
            
        case "13": // Công suất
            sendEvent(["type": "powerLevel", "data": data])
            
        case "11": // Set công suất OK
            print("🔵 iOS SDK: Power Set Success. Refreshing...")
            self.getPower()
            
        case "e6": // [TRIGGER] Bóp cò
            print("🔫 iOS SDK: Trigger Event (e6) -> Data: \(data)")
            sendEvent(["type": "trigger", "data": data])
            
        case "e50": print("🔊 Buzzer ON")
        case "e51": print("🔇 Buzzer OFF")
            
        default: break
        }
    }
    
    // MARK: - Helper
    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(event)
        }
    }
}
