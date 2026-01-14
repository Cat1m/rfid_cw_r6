import Flutter
import UIKit

class RFIDFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private let handler = RFIDHandler()
    private var eventChannel: FlutterEventChannel?
    
    // Đăng ký Plugin với Flutter Engine
    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: Constants.CHANNEL_COMMAND, binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: Constants.CHANNEL_EVENT, binaryMessenger: registrar.messenger())
        
        let instance = RFIDFlutterPlugin()
        instance.eventChannel = eventChannel
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    // Handle Method Call
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        
        switch call.method {
        // Discovery
        case Constants.CMD_START_DISCOVERY:
            handler.startDiscovery()
            result(true)
            
        case Constants.CMD_STOP_DISCOVERY:
            handler.stopDiscovery()
            result(true)
            
        // Connection
        case Constants.CMD_CONNECT:
            guard let address = args?["address"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "Address is missing", details: nil))
                return
            }
            handler.connect(address: address)
            result(true)
            
        case Constants.CMD_DISCONNECT:
            handler.disconnect()
            result(true)
            
        // Scanning
        case Constants.CMD_START_SCAN:
            handler.startInventory()
            result(true)
            
        case Constants.CMD_STOP_SCAN:
            handler.stopInventory()
            result(true)
            
            
        case Constants.CMD_CLEAR_DATA:
            handler.clearData()
            result(true)
            
        // Configuration
        case Constants.CMD_GET_BATTERY:
            handler.getBattery()
            result(true)
            
        case Constants.CMD_SET_POWER:
                    // [SỬA] Đổi "value" thành "power" cho khớp với Dart
                    if let power = args?["power"] as? Int {
                        handler.setPower(value: power)
                        result(true)
                    } else {
                        result(FlutterError(code: "INVALID_ARG", message: "Power value (int) required", details: nil))
                    }
            
        case Constants.CMD_GET_POWER:
            handler.getPower()
            result(true)
            
        case Constants.CMD_SET_BUZZER:
            let enable = args?["enable"] as? Bool ?? true
            handler.setBuzzer(enable: enable)
            result(true)
            
        case Constants.CMD_SET_CW:
            let enable = args?["enable"] as? Bool ?? false
            handler.setCW(enable: enable)
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Handle Event Stream
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        handler.setEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handler.setEventSink(nil)
        return nil
    }
}
