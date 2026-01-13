import Flutter
import UIKit

class RFIDFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var handler: RFIDHandler
    private var eventChannel: FlutterEventChannel
    
    init(messenger: FlutterBinaryMessenger) {
        self.handler = RFIDHandler()
        self.eventChannel = FlutterEventChannel(name: Constants.CHANNEL_EVENT, binaryMessenger: messenger)
        super.init()
        self.eventChannel.setStreamHandler(self)
    }
    
    // Đăng ký Plugin
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Constants.CHANNEL_COMMAND, binaryMessenger: registrar.messenger())
        let instance = RFIDFlutterPlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // Xử lý Method Call từ Flutter
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        
        switch call.method {
        case Constants.CMD_START_DISCOVERY:
            handler.startDiscovery()
            result(true)
            
        case Constants.CMD_STOP_DISCOVERY:
            handler.stopDiscovery()
            result(true)
            
        case Constants.CMD_CONNECT:
            if let address = args?["address"] as? String {
                handler.connect(address: address)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARG", message: "Address required", details: nil))
            }
            
        case Constants.CMD_DISCONNECT:
            handler.disconnect()
            result(true)
            
        case Constants.CMD_START_SCAN:
            handler.startInventory()
            result(true)
            
        case Constants.CMD_STOP_SCAN:
            handler.stopInventory()
            result(true)
            
        case Constants.CMD_GET_BATTERY:
            handler.getBattery()
            result(true)
            
        case Constants.CMD_SET_POWER:
            if let power = args?["value"] as? Int {
                handler.setPower(value: power)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARG", message: "Power value (int) required", details: nil))
            }
            
        case Constants.CMD_GET_POWER:
            handler.getPower()
            result(true)
            
        case Constants.CMD_SET_BUZZER:
            if let enable = args?["enable"] as? Bool {
                handler.setBuzzer(enable: enable)
                result(true)
            } else {
                 result(FlutterError(code: "INVALID_ARG", message: "Enable (bool) required", details: nil))
            }
            
        case Constants.CMD_SET_CW:
            if let enable = args?["enable"] as? Bool {
                handler.setCW(enable: enable)
                result(true)
            } else {
                result(true)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Event Stream Handler: Chuyển Sink cho Handler quản lý
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        handler.setEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handler.setEventSink(nil)
        return nil
    }
}
