import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let reg = engineBridge.pluginRegistry.registrar(forPlugin: "LifecyclePlugin") {
      LifecyclePlugin.register(with: reg)
    }
  }
}

/// Spike T-01 — kênh native iOS.
/// Chỉ dùng sự kiện vòng đời của CHÍNH app + protectedData (khóa màn hình).
/// Không đọc app khác, không cảm biến (BR-34, NFR-P01).
/// Giới hạn: protectedData* chỉ phát khi máy CÓ đặt mã khóa, và có thể đến
/// trễ vài giây sau khi bấm nút nguồn — spike phải đo độ trễ này.
final class LifecyclePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var watching = false
  private var tokens: [NSObjectProtocol] = []

  static func register(with registrar: FlutterPluginRegistrar) {
    let inst = LifecyclePlugin()
    FlutterEventChannel(name: "dropit/lifecycle_events", binaryMessenger: registrar.messenger())
      .setStreamHandler(inst)
    let method = FlutterMethodChannel(name: "dropit/lifecycle", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(inst, channel: method)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startWatching": start(); result(true)
    case "stopWatching": stop(); result(true)
    case "snapshot":
      result(["protectedDataAvailable": UIApplication.shared.isProtectedDataAvailable])
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func send(_ event: String) {
    guard watching else { return }
    let m: [String: Any] = [
      "event": event,
      "nativeUptimeMs": Int(ProcessInfo.processInfo.systemUptime * 1000),
      "nativeWallMs": Int(Date().timeIntervalSince1970 * 1000),
      "protectedDataAvailable": UIApplication.shared.isProtectedDataAvailable,
      "appState": UIApplication.shared.applicationState.rawValue,
    ]
    DispatchQueue.main.async { self.sink?(m) }
  }

  private func observe(_ name: Notification.Name, _ event: String) {
    tokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
      [weak self] _ in self?.send(event)
    })
  }

  // Chỉ lắng nghe khi đang ghi phiên (BR-05, NFR-P02).
  private func start() {
    guard !watching else { return }
    watching = true
    observe(UIApplication.protectedDataWillBecomeUnavailableNotification, "protected_data_unavailable")
    observe(UIApplication.protectedDataDidBecomeAvailableNotification, "protected_data_available")
    observe(UIScene.willDeactivateNotification, "scene_will_resign_active")
    observe(UIScene.didEnterBackgroundNotification, "scene_did_enter_background")
    observe(UIScene.willEnterForegroundNotification, "scene_will_enter_foreground")
    observe(UIScene.didActivateNotification, "scene_did_become_active")
    observe(UIApplication.willTerminateNotification, "will_terminate")
    send("watching_started")
  }

  private func stop() {
    guard watching else { return }
    send("watching_stopped")
    watching = false
    tokens.forEach { NotificationCenter.default.removeObserver($0) }
    tokens.removeAll()
  }
}
