import Foundation

struct Constants {
    static let CHANNEL_NAMESPACE = "com.chien.libs.rfid_r6"
    
    // Channel Names
    static let CHANNEL_COMMAND = "\(CHANNEL_NAMESPACE)/methods"
    static let CHANNEL_EVENT = "\(CHANNEL_NAMESPACE)/events"
    
    // Commands
    static let CMD_CONNECT = "connect"
    static let CMD_DISCONNECT = "disconnect"
    static let CMD_START_SCAN = "startScan"
    static let CMD_STOP_SCAN = "stopScan"
    static let CMD_SET_POWER = "setPower"
    static let CMD_GET_POWER = "getPower"
    static let CMD_GET_BATTERY = "getBattery"
    static let CMD_SET_CW = "setCW"
    static let CMD_SET_BUZZER = "setBuzzer"
    static let CMD_START_DISCOVERY = "startDiscovery"
    static let CMD_STOP_DISCOVERY = "stopDiscovery"
    static let CMD_CLEAR_DATA = "clearData"
}
