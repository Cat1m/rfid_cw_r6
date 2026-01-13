import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        GeneratedPluginRegistrant.register(with: self)
        
        // [QUAN TRỌNG] Đăng ký Local Plugin thủ công
        // Vì code này nằm trong thư mục Runner (không phải package riêng), 
        // nên GeneratedPluginRegistrant sẽ không tự tìm thấy nó.
        // Ta phải tự đăng ký nó vào Registry của Flutter.
        
        if let registrar = self.registrar(forPlugin: "RFIDFlutterPlugin") {
            RFIDFlutterPlugin.register(with: registrar)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}